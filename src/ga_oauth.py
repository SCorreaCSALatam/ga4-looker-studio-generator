"""
OAuth Google y lectura de cuentas/propiedades GA4 vía Analytics Admin API.

Los tokens se guardan por sesión (archivo por ID de sesión) para soportar varios
usuarios en un mismo servidor. Directorio base: GA_LS_DATA_DIR o ~/.ga4-looker-studio-link-tool
"""

from __future__ import annotations

import hashlib
import json
import os
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import Flow

SCOPES = ["https://www.googleapis.com/auth/analytics.readonly"]
ACCOUNT_SUMMARIES_URL = "https://analyticsadmin.googleapis.com/v1beta/accountSummaries"


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def data_root() -> Path:
    """Directorio de datos (tokens por sesión)."""
    raw = os.environ.get("GA_LS_DATA_DIR", "").strip()
    if raw:
        p = Path(raw)
    else:
        p = Path.home() / ".ga4-looker-studio-link-tool"
    p.mkdir(mode=0o700, exist_ok=True)
    return p


def _tokens_dir() -> Path:
    d = data_root() / "tokens"
    d.mkdir(mode=0o700, exist_ok=True)
    return d


def _legacy_token_path() -> Path:
    return data_root() / "oauth-token.json"


def _token_file_for_session(session_id: str) -> Path:
    """Nombre de archivo estable a partir del id de sesión (evita caracteres raros)."""
    h = hashlib.sha256(session_id.encode("utf-8")).hexdigest()[:40]
    return _tokens_dir() / f"{h}.json"


def client_secrets_path() -> Path | None:
    p = _repo_root() / "client_secret.json"
    return p if p.is_file() else None


def load_client_config() -> dict[str, Any] | None:
    """Config para Flow.from_client_config: clave 'web' o 'installed'."""
    path = client_secrets_path()
    if path:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        if "web" in data or "installed" in data:
            return data
    cid = os.environ.get("GOOGLE_OAUTH_CLIENT_ID", "").strip()
    csec = os.environ.get("GOOGLE_OAUTH_CLIENT_SECRET", "").strip()
    if not cid or not csec:
        return None
    redirect = os.environ.get(
        "GOOGLE_OAUTH_REDIRECT_URI",
        "http://127.0.0.1:8765/oauth/callback",
    ).strip()
    return {
        "web": {
            "client_id": cid,
            "client_secret": csec,
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "redirect_uris": [redirect],
        }
    }


def load_credentials(session_id: str) -> Credentials | None:
    p = _token_file_for_session(session_id)
    if p.is_file():
        try:
            info = json.loads(p.read_text(encoding="utf-8"))
            return Credentials.from_authorized_user_info(info, SCOPES)
        except (json.JSONDecodeError, ValueError, OSError):
            return None
    # Migración única desde token monousuario antiguo
    leg = _legacy_token_path()
    if leg.is_file():
        try:
            info = json.loads(leg.read_text(encoding="utf-8"))
            creds = Credentials.from_authorized_user_info(info, SCOPES)
            save_credentials(session_id, creds)
            try:
                leg.unlink()
            except OSError:
                pass
            return creds
        except (json.JSONDecodeError, ValueError, OSError):
            return None
    return None


def save_credentials(session_id: str, creds: Credentials) -> None:
    _token_file_for_session(session_id).write_text(creds.to_json(), encoding="utf-8")


def clear_credentials(session_id: str) -> None:
    p = _token_file_for_session(session_id)
    if p.is_file():
        p.unlink()


def create_flow(redirect_uri: str) -> Flow:
    cfg = load_client_config()
    if not cfg:
        raise RuntimeError(
            "Falta configuración OAuth: coloca client_secret.json en la raíz del proyecto "
            "o define GOOGLE_OAUTH_CLIENT_ID y GOOGLE_OAUTH_CLIENT_SECRET."
        )
    return Flow.from_client_config(cfg, scopes=SCOPES, redirect_uri=redirect_uri)


def ensure_fresh_token(session_id: str, creds: Credentials) -> None:
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
        save_credentials(session_id, creds)


def fetch_property_choices(session_id: str, creds: Credentials) -> list[dict[str, str]]:
    """Lista plana ordenada: account_id, property_id, nombres para UI."""
    ensure_fresh_token(session_id, creds)
    rows: list[dict[str, str]] = []
    page_token: str | None = None
    while True:
        qs: dict[str, str] = {"pageSize": "200"}
        if page_token:
            qs["pageToken"] = page_token
        url = ACCOUNT_SUMMARIES_URL + "?" + urllib.parse.urlencode(qs)
        req = urllib.request.Request(url, headers={"Authorization": f"Bearer {creds.token}"})
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                payload = json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")
            raise RuntimeError(f"Google Analytics Admin API ({e.code}): {body[:800]}") from e

        for block in payload.get("accountSummaries", []):
            acc_resource = block.get("account", "")
            acc_name = block.get("displayName", acc_resource)
            if not acc_resource.startswith("accounts/"):
                continue
            account_id = acc_resource.split("/", 1)[1]
            for ps in block.get("propertySummaries", []):
                prop_res = ps.get("property", "")
                if not prop_res.startswith("properties/"):
                    continue
                prop_id = prop_res.split("/", 1)[1]
                rows.append(
                    {
                        "account_id": account_id,
                        "property_id": prop_id,
                        "account_display_name": acc_name,
                        "property_display_name": ps.get("displayName", prop_id),
                    }
                )
        page_token = payload.get("nextPageToken") or None
        if not page_token:
            break

    rows.sort(
        key=lambda r: (
            r["account_display_name"].lower(),
            r["property_display_name"].lower(),
        )
    )
    return rows


def group_by_account(rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    """Agrupa filas por cuenta para <optgroup>."""
    buckets: dict[str, dict[str, Any]] = {}
    order: list[str] = []
    for r in rows:
        aid = r["account_id"]
        if aid not in buckets:
            buckets[aid] = {
                "account_id": aid,
                "account_display_name": r["account_display_name"],
                "properties": [],
            }
            order.append(aid)
        buckets[aid]["properties"].append(
            {"property_id": r["property_id"], "property_display_name": r["property_display_name"]}
        )
    return [buckets[k] for k in order]
