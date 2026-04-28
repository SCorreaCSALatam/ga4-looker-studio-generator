"""
Generador de URLs para la Looker Studio Linking API (conector googleAnalytics / GA4).
Solo usa la biblioteca estándar.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from urllib.parse import urlencode, quote


LINKING_CREATE_BASE = "https://lookerstudio.google.com/reporting/create"
LINKING_EMBED_CREATE_BASE = "https://lookerstudio.google.com/embed/reporting/create"
REPORTING_VIEW_BASE = "https://lookerstudio.google.com/reporting"
EMBED_VIEW_BASE = "https://lookerstudio.google.com/embed/reporting"


def build_linking_create_url(
    *,
    template_report_id: str,
    account_id: str,
    property_id: str,
    ds_alias: str = "ds1",
    report_name: str | None = None,
    refresh_fields: bool = False,
    mode: str | None = None,
    page_id: str | None = None,
    datasource_name: str | None = None,
    embed: bool = False,
) -> str:
    """
    Construye la URL que abre Looker Studio en flujo "crear desde plantilla" con GA4.

    Parámetros alineados con la documentación oficial del conector Google Analytics
    (GA4: accountId y propertyId obligatorios; no usar viewId).
    """
    base = LINKING_EMBED_CREATE_BASE if embed else LINKING_CREATE_BASE
    pairs: list[tuple[str, str]] = [
        ("c.reportId", template_report_id.strip()),
        (f"ds.{ds_alias}.connector", "googleAnalytics"),
        (f"ds.{ds_alias}.accountId", str(account_id).strip()),
        (f"ds.{ds_alias}.propertyId", str(property_id).strip()),
        (f"ds.{ds_alias}.refreshFields", "true" if refresh_fields else "false"),
    ]
    if report_name is not None and report_name.strip():
        pairs.append(("r.reportName", report_name.strip()))
    if datasource_name is not None and datasource_name.strip():
        pairs.append((f"ds.{ds_alias}.datasourceName", datasource_name.strip()))
    if mode in ("view", "edit"):
        pairs.append(("c.mode", mode))
    if page_id is not None and page_id.strip():
        pairs.append(("c.pageId", page_id.strip()))

    # safe='' para codificar también paréntesis y otros caracteres en nombres de informe
    query = urlencode(pairs, quote_via=quote)
    return f"{base}?{query}"


def build_saved_report_url_with_params(
    *,
    report_id: str,
    page_id: str,
    params: dict[str, str],
    embed: bool = False,
) -> str:
    """
    Fase 2: URL de un informe ya guardado con ?params=<JSON URL-encoded>.

    Las claves de `params` deben coincidir con los nombres definidos en Looker Studio
    (Resource → Manage report URL parameters), p. ej. {"ds1.Event name": "purchase"}.
    """
    base = EMBED_VIEW_BASE if embed else REPORTING_VIEW_BASE
    path = f"{report_id}/page/{page_id}"
    encoded = quote(json.dumps(params, separators=(",", ":")), safe="")
    return f"{base}/{path}?params={encoded}"


def _cli() -> None:
    parser = argparse.ArgumentParser(
        description="Genera URL de Looker Studio Linking API para plantilla GA4."
    )
    parser.add_argument("--report-id", default=None, help="ID del informe plantilla (UUID)")
    parser.add_argument("--account-id", default=None, help="ID numérico de cuenta de Google Analytics")
    parser.add_argument("--property-id", default=None, help="ID numérico de propiedad GA4")
    parser.add_argument(
        "--ds-alias",
        default="ds1",
        help="Alias del origen de datos en la plantilla (por defecto ds1)",
    )
    parser.add_argument("--report-name", default=None, help="Nombre del nuevo informe (opcional)")
    parser.add_argument(
        "--refresh-fields",
        action="store_true",
        help="ds.*.refreshFields=true (útil si cambian campos entre propiedades)",
    )
    parser.add_argument("--mode", choices=("view", "edit"), default=None)
    parser.add_argument("--page-id", default=None)
    parser.add_argument("--embed", action="store_true", help="Usar ruta /embed/reporting/create")
    parser.add_argument(
        "--saved-report-id",
        default=None,
        help="Si se indica junto con --saved-page-id y --params-json, genera URL de informe guardado",
    )
    parser.add_argument("--saved-page-id", default=None)
    parser.add_argument(
        "--params-json",
        default=None,
        help='JSON de parámetros de URL, p. ej. {"ds1.Event name":"body_button_menu_click"}',
    )
    parser.add_argument(
        "--params-json-file",
        default=None,
        metavar="PATH",
        help="Ruta a un archivo UTF-8 con el mismo JSON que --params-json (útil en PowerShell)",
    )
    parser.add_argument("--saved-embed", action="store_true")

    args = parser.parse_args()

    saved_mode = bool(
        args.saved_report_id
        or args.saved_page_id
        or args.params_json
        or args.params_json_file
    )
    if saved_mode:
        if not (args.saved_report_id and args.saved_page_id):
            parser.error(
                "Para URL con params hacen falta --saved-report-id y --saved-page-id"
            )
        if (args.params_json is None) == (args.params_json_file is None):
            parser.error(
                "Indica exactamente uno de: --params-json o --params-json-file"
            )
        raw_json = (
            args.params_json
            if args.params_json is not None
            else Path(args.params_json_file).read_text(encoding="utf-8")
        )
        try:
            params = json.loads(raw_json)
        except json.JSONDecodeError as e:
            parser.error(f"JSON de params no válido: {e}")
        if not isinstance(params, dict):
            parser.error("--params-json debe ser un objeto JSON")
        url = build_saved_report_url_with_params(
            report_id=args.saved_report_id,
            page_id=args.saved_page_id,
            params={str(k): str(v) for k, v in params.items()},
            embed=args.saved_embed,
        )
    else:
        if not args.report_id or not args.account_id or not args.property_id:
            parser.error(
                "Modo creación: son obligatorios --report-id, --account-id y --property-id"
            )
        url = build_linking_create_url(
            template_report_id=args.report_id,
            account_id=args.account_id,
            property_id=args.property_id,
            ds_alias=args.ds_alias,
            report_name=args.report_name,
            refresh_fields=args.refresh_fields,
            mode=args.mode,
            page_id=args.page_id,
            embed=args.embed,
        )
    print(url)


if __name__ == "__main__":
    _cli()
