"""
Interfaz web (Bottle) para generar URLs de Looker Studio.
OAuth opcional: listar cuentas y propiedades GA4 (Admin API), un token por sesión (cookie).
"""

from __future__ import annotations

import json
import os
import secrets
import sys
import time
import urllib.parse
from pathlib import Path

import bottle
from bottle import Bottle, request, response, template

_ROOT = Path(__file__).resolve().parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

import ga_oauth  # noqa: E402
from linking_url import build_linking_create_url, build_saved_report_url_with_params  # noqa: E402

_VIEWS = Path(__file__).resolve().parent.parent / "views"
bottle.TEMPLATE_PATH = [str(_VIEWS)]

app = Bottle()

_SID_COOKIE = "ga_ls_sid"
_FLOW_TTL_SEC = 900.0
_pending_flows: dict[str, tuple[object, float]] = {}

_session_secret_cache: str | None = None


def _session_secret() -> str:
    global _session_secret_cache
    if _session_secret_cache is None:
        _session_secret_cache = os.environ.get("GA_LS_SESSION_SECRET", "").strip()
        if not _session_secret_cache:
            _session_secret_cache = secrets.token_hex(32)
            print(
                "AVISO: GA_LS_SESSION_SECRET no definido; las cookies de sesión "
                "dejarán de valer al reiniciar el servidor. Define un secreto fijo en producción.",
                file=sys.stderr,
            )
    return _session_secret_cache


def _session_id() -> str:
    """ID de sesión estable por navegador (cookie firmada)."""
    if "ga_ls_sid" in request.environ:
        return request.environ["ga_ls_sid"]
    existing = request.get_cookie(_SID_COOKIE, secret=_session_secret())
    if existing:
        request.environ["ga_ls_sid"] = existing
        return existing
    sid = secrets.token_urlsafe(24)
    request.environ["ga_ls_sid"] = sid
    request.environ["ga_ls_new_sid"] = True
    return sid


def _attach_session_cookie() -> None:
    if request.environ.pop("ga_ls_new_sid", False):
        response.set_cookie(
            _SID_COOKIE,
            request.environ["ga_ls_sid"],
            secret=_session_secret(),
            max_age=60 * 60 * 24 * 90,
            httponly=True,
            path="/",
            # secure=True en HTTPS; en local http no enviar secure
            secure=os.environ.get("GA_LS_COOKIE_SECURE", "").strip() in ("1", "true", "yes"),
            same_site="Lax",
        )


@app.hook("before_request")
def _hook_before_request() -> None:
    _session_id()


@app.hook("after_request")
def _hook_after_request() -> None:
    _attach_session_cookie()


def _redirect_base() -> str:
    return os.environ.get("GA_LS_BASE_URL", "http://127.0.0.1:8765").rstrip("/")


def _oauth_callback_url() -> str:
    return _redirect_base() + "/oauth/callback"


def _defaults() -> dict:
    return {
        "error": "",
        "url": "",
        "form_mode": "create",
        "create_checked": " checked",
        "saved_checked": "",
        "report_id": "",
        "account_id": "",
        "property_id": "",
        "property_pick_current": "",
        "ga_manual_checked": "",
        "ds_alias": "ds1",
        "report_name": "",
        "datasource_name": "",
        "mode": "",
        "mode_empty": " selected",
        "mode_view": "",
        "mode_edit": "",
        "page_id": "",
        "refresh_checked": "",
        "embed_checked": "",
        "saved_report_id": "",
        "saved_page_id": "",
        "params_json": '{\n  "ds1.Event name": "body_button_menu_click"\n}',
        "saved_embed_checked": "",
        "oauth_configured": False,
        "oauth_connected": False,
        "ga_groups": [],
        "ga_list_error": "",
        "oauth_flash_ok": False,
        "oauth_flash_err": "",
    }


def _ga_ui_context() -> dict:
    sid = _session_id()
    ctx: dict = {
        "oauth_configured": ga_oauth.load_client_config() is not None,
        "oauth_connected": False,
        "ga_groups": [],
        "ga_list_error": "",
    }
    creds = ga_oauth.load_credentials(sid)
    if not creds:
        return ctx
    ctx["oauth_connected"] = True
    try:
        rows = ga_oauth.fetch_property_choices(sid, creds)
        ctx["ga_groups"] = ga_oauth.group_by_account(rows)
    except (RuntimeError, OSError, ValueError) as e:
        ctx["ga_list_error"] = str(e)
    return ctx


def _merge_query_flashes(ctx: dict) -> None:
    if request.query.get("oauth_ok"):
        ctx["oauth_flash_ok"] = True
    err = request.query.get("oauth_err", "").strip()
    if err:
        ctx["oauth_flash_err"] = urllib.parse.unquote(err)


def _mode_select(mode: str) -> dict[str, str]:
    m = (mode or "").strip().lower()
    return {
        "mode_empty": " selected" if m == "" else "",
        "mode_view": " selected" if m == "view" else "",
        "mode_edit": " selected" if m == "edit" else "",
    }


def _apply_property_pick(ctx: dict) -> None:
    manual = request.forms.get("ga_manual_ids") == "1"
    if manual:
        return
    pick = request.forms.get("ga_property_pick", "").strip()
    if "|" not in pick:
        return
    acc, _, prop = pick.partition("|")
    if acc.isdigit() and prop.isdigit():
        ctx["account_id"] = acc
        ctx["property_id"] = prop
        ctx["property_pick_current"] = pick


def _fill_create_from_form(ctx: dict) -> None:
    ctx["report_id"] = request.forms.get("report_id", ctx.get("report_id", "")).strip()
    ctx["account_id"] = request.forms.get("account_id", ctx.get("account_id", "")).strip()
    ctx["property_id"] = request.forms.get("property_id", ctx.get("property_id", "")).strip()
    ctx["ds_alias"] = request.forms.get("ds_alias", ctx.get("ds_alias", "ds1")).strip() or "ds1"
    ctx["report_name"] = request.forms.get("report_name", ctx.get("report_name", "")).strip()
    ctx["datasource_name"] = request.forms.get(
        "datasource_name", ctx.get("datasource_name", "")
    ).strip()
    ctx["mode"] = request.forms.get("mode", ctx.get("mode", "")).strip()
    ms = _mode_select(ctx["mode"])
    ctx["mode_empty"] = ms["mode_empty"]
    ctx["mode_view"] = ms["mode_view"]
    ctx["mode_edit"] = ms["mode_edit"]
    ctx["page_id"] = request.forms.get("page_id", ctx.get("page_id", "")).strip()
    ctx["refresh_checked"] = " checked" if request.forms.get("refresh_fields") == "1" else ""
    ctx["embed_checked"] = " checked" if request.forms.get("embed") == "1" else ""
    ctx["ga_manual_checked"] = " checked" if request.forms.get("ga_manual_ids") == "1" else ""
    _apply_property_pick(ctx)
    if (ctx.get("account_id") or "") and (ctx.get("property_id") or "") and not ctx.get(
        "property_pick_current"
    ):
        ctx["property_pick_current"] = f'{ctx["account_id"]}|{ctx["property_id"]}'


def _fill_saved_from_form(ctx: dict) -> None:
    ctx["saved_report_id"] = request.forms.get(
        "saved_report_id", ctx.get("saved_report_id", "")
    ).strip()
    ctx["saved_page_id"] = request.forms.get("saved_page_id", ctx.get("saved_page_id", "")).strip()
    raw_params = request.forms.get("params_json")
    if raw_params is not None:
        ctx["params_json"] = raw_params.strip()
    ctx["saved_embed_checked"] = " checked" if request.forms.get("saved_embed") == "1" else ""


def _render_index(ctx: dict) -> str:
    _merge_query_flashes(ctx)
    g = _ga_ui_context()
    ctx.update(g)
    if ctx.get("oauth_connected") and ctx.get("ga_groups") and not ctx.get("ga_manual_checked"):
        ctx["ga_manual_inputs_disabled"] = "disabled"
    else:
        ctx["ga_manual_inputs_disabled"] = ""
    return template("index", **ctx)


@app.route("/")
def index():
    ctx = _defaults()
    return _render_index(ctx)


@app.route("/connect")
def connect():
    sid = _session_id()
    try:
        flow = ga_oauth.create_flow(_oauth_callback_url())
    except RuntimeError as e:
        bottle.redirect("/?oauth_err=" + urllib.parse.quote(str(e)))
    res = flow.authorization_url(
        access_type="offline",
        prompt="consent",
        state=secrets.token_urlsafe(16),
    )
    auth_url = res[0] if isinstance(res, tuple) else res
    _pending_flows[sid] = (flow, time.time())
    _prune_pending_flows()
    bottle.redirect(auth_url)


def _prune_pending_flows() -> None:
    now = time.time()
    dead = [k for k, (_, t) in _pending_flows.items() if now - t > _FLOW_TTL_SEC]
    for k in dead:
        del _pending_flows[k]


@app.route("/oauth/callback")
def oauth_callback():
    sid = _session_id()
    err = request.query.get("error")
    if err:
        bottle.redirect(
            "/?oauth_err=" + urllib.parse.quote(request.query.get("error_description", err))
        )
    _prune_pending_flows()
    tup = _pending_flows.pop(sid, None)
    if not tup or (time.time() - tup[1]) > _FLOW_TTL_SEC:
        bottle.redirect(
            "/?oauth_err=" + urllib.parse.quote("Sesión de conexión caducada. Pulsa Conectar de nuevo.")
        )
    flow = tup[0]
    try:
        flow.fetch_token(authorization_response=request.url)
    except Exception as e:  # noqa: BLE001
        bottle.redirect("/?oauth_err=" + urllib.parse.quote(str(e)))
    ga_oauth.save_credentials(sid, flow.credentials)
    bottle.redirect("/?oauth_ok=1")


@app.post("/disconnect")
def disconnect():
    ga_oauth.clear_credentials(_session_id())
    bottle.redirect("/")


@app.post("/generate")
def generate():
    ctx = _defaults()
    _fill_create_from_form(ctx)
    _fill_saved_from_form(ctx)
    form_mode = request.forms.get("form_mode", "create").strip()

    if form_mode == "saved":
        ctx["create_checked"] = ""
        ctx["saved_checked"] = " checked"

        if not ctx["saved_report_id"] or not ctx["saved_page_id"]:
            ctx["error"] = "Informe guardado: hacen falta Report ID y Page ID."
            return _render_index(ctx)

        try:
            params_obj = json.loads(ctx["params_json"] or "{}")
        except json.JSONDecodeError as e:
            ctx["error"] = f"JSON no válido: {e}"
            return _render_index(ctx)

        if not isinstance(params_obj, dict):
            ctx["error"] = "El JSON de parámetros debe ser un objeto { ... }."
            return _render_index(ctx)

        params = {str(k): str(v) for k, v in params_obj.items()}
        try:
            ctx["url"] = build_saved_report_url_with_params(
                report_id=ctx["saved_report_id"],
                page_id=ctx["saved_page_id"],
                params=params,
                embed=request.forms.get("saved_embed") == "1",
            )
        except (TypeError, ValueError) as e:
            ctx["error"] = str(e)
        return _render_index(ctx)

    ctx["create_checked"] = " checked"
    ctx["saved_checked"] = ""

    rid, aid, pid = ctx["report_id"], ctx["account_id"], ctx["property_id"]
    if not rid or not aid or not pid:
        ctx["error"] = (
            "Plantilla: son obligatorios Report ID (plantilla), Account ID y Property ID. "
            "Elige una propiedad en la lista o marca «Introducir IDs manualmente»."
        )
        return _render_index(ctx)

    mode_val = ctx["mode"] or None
    if mode_val not in ("view", "edit"):
        mode_val = None

    try:
        ctx["url"] = build_linking_create_url(
            template_report_id=rid,
            account_id=aid,
            property_id=pid,
            ds_alias=ctx["ds_alias"] or "ds1",
            report_name=ctx["report_name"] or None,
            refresh_fields=request.forms.get("refresh_fields") == "1",
            mode=mode_val,
            page_id=ctx["page_id"] or None,
            datasource_name=ctx["datasource_name"] or None,
            embed=request.forms.get("embed") == "1",
        )
    except (TypeError, ValueError) as e:
        ctx["error"] = str(e)

    return _render_index(ctx)


def main() -> None:
    port = int(os.environ.get("PORT", "8765"))
    if "GA_LS_BASE_URL" not in os.environ:
        os.environ["GA_LS_BASE_URL"] = f"http://127.0.0.1:{port}"
    host = os.environ.get("GA_LS_HOST", "127.0.0.1").strip() or "127.0.0.1"
    app.run(host=host, port=port, quiet=False)


if __name__ == "__main__":
    main()
