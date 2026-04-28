# GA4 → Looker Studio: generador de enlaces (Linking API)

Herramienta mínima alineada con el plan: **no crea gráficos por API**; construye la URL oficial para crear un informe en Looker Studio a partir de una **plantilla** y una propiedad GA4 (`accountId`, `propertyId`).

## Documentación

| Documento | Contenido |
|-------------|-------------|
| [docs/template-looker-studio.md](docs/template-looker-studio.md) | Cómo crear la plantilla (tabla, serie temporal, filtro por evento) y dónde leer `reportId` y alias del origen (p. ej. `ds1`). |
| [docs/governance.md](docs/governance.md) | Credenciales del origen (propietario vs visor) y permisos GA4. |
| [docs/url-params-phase2.md](docs/url-params-phase2.md) | Enlaces con `?params=` para informes ya guardados. |
| [docs/google-oauth-setup.md](docs/google-oauth-setup.md) | OAuth + Admin API para elegir cuenta y propiedad GA4 en la interfaz web. |
| [docs/deploy.md](docs/deploy.md) | Subir el proyecto a Git y desplegarlo en un servidor (varios usuarios). |

## Requisitos

- Python 3.10+.
- **CLI** (`linking_url.py`): solo biblioteca estándar.
- **Interfaz web**: [Bottle](https://bottlepy.org/), Google OAuth y cliente HTTP (`pip install -r requirements.txt`).

## Interfaz web (Bottle)

Formulario local en el navegador (plantilla, informe guardado con `params`, opciones avanzadas).

Tras configurar OAuth (ver [docs/google-oauth-setup.md](docs/google-oauth-setup.md)), puedes **Conectar con Google** y elegir **cuenta y propiedad GA4** en un desplegable sin teclear los IDs (sigue existiendo la opción manual).

```bash
pip install -r requirements.txt
python src/web_app.py
```

Abre **http://127.0.0.1:8765** (o el puerto que definas). Solo escucha en `127.0.0.1`. Detén con `Ctrl+C`.

Variables útiles en local: **`PORT`**, **`GA_LS_BASE_URL`** (debe coincidir con la URI de redirección OAuth). Para **varios usuarios en Internet**: **`GA_LS_HOST=0.0.0.0`**, HTTPS, **`GA_LS_SESSION_SECRET`**, **`GA_LS_DATA_DIR`** persistente y variables OAuth públicas; detalle en [docs/deploy.md](docs/deploy.md).

### Subir a Git (GitHub)

No puedo usar tu cuenta desde aquí. Pasos resumidos: `git init`, `git add`, `git commit`, crear repo vacío en GitHub, `git remote add origin …`, `git push`. Instrucciones completas en [docs/deploy.md](docs/deploy.md).

## Uso rápido (CLI)

Desde la carpeta del proyecto:

```bash
python src/linking_url.py --report-id TU_PLANTILLA_UUID --account-id 12345678 --property-id 87654321 --report-name "Eventos body menu"
```

Opciones útiles:

- `--refresh-fields` — `refreshFields=true` al cambiar de propiedad con campos distintos.
- `--ds-alias ds1` — alias del origen en la plantilla (por defecto `ds1` en este repo). Si tu plantilla usa otro (`ds0`, `ds2`, …), pásalo explícito; véase [docs/template-looker-studio.md](docs/template-looker-studio.md#error-alias-ds).
- `--mode edit` — abrir en modo edición.
- `--embed` — URL con `/embed/reporting/create` (para iframes).

Para un informe **ya guardado** con filtros por URL (fase 2), usa `--saved-report-id`, `--saved-page-id` y **uno** de `--params-json` o `--params-json-file` (recomendado en Windows); ver [docs/url-params-phase2.md](docs/url-params-phase2.md).

La salida es una sola línea: **cópiala y ábrela en el navegador** con sesión Google que tenga acceso a esa propiedad GA4.

## Variables de entorno (opcional)

- **CLI**: puedes envolver el script en un alias que lea `LOOKER_TEMPLATE_REPORT_ID`, etc.; el CLI no las lee por defecto.
- **Web + OAuth**: `GOOGLE_OAUTH_*`, `PORT`, `GA_LS_BASE_URL`, y en servidor `GA_LS_HOST`, `GA_LS_SESSION_SECRET`, `GA_LS_DATA_DIR`, `GA_LS_COOKIE_SECURE` (ver [docs/deploy.md](docs/deploy.md)).

## Licencia

Uso interno / dominio público según prefieras; el repositorio no incluye licencia explícita.
