# GA4 → Looker Studio — Generador de enlaces

Herramienta en **Python** para generar URLs de la [Looker Studio Linking API](https://developers.google.com/looker-studio/integrate/linking-api): crea **nuevas copias** de un informe plantilla apuntando a otra propiedad **GA4**, sin exponer gráficos por API. Incluye **CLI** (solo biblioteca estándar) e **interfaz web** opcional ([Bottle](https://bottlepy.org/) + OAuth).

---

## Objetivo

| Qué hace | Qué no hace |
|----------|----------------|
| Construye la URL oficial `https://lookerstudio.google.com/reporting/create?...` con `c.reportId` (plantilla) y parámetros del conector GA4 (`accountId`, `propertyId`, etc.). | No crea ni edita gráficos por API. Los datos siguen viniendo del **conector nativo GA4** en Looker Studio. |
| Opcionalmente genera enlaces con `?params=` para informes **ya guardados** (fase 2). | No sustituye permisos de GA4 ni la configuración de la plantilla en Looker Studio. |

**Caso de uso típico:** una plantilla de informe en Looker Studio + esta herramienta → enlaces por propiedad GA4 para que cada quien abra el enlace en el navegador (con una cuenta Google con acceso a esa propiedad).

---

## Requisitos

- **Python 3.10+**
- **CLI:** solo la biblioteca estándar.
- **Web:** dependencias en [`requirements.txt`](requirements.txt) (`bottle`, `google-auth`, `google-auth-oauthlib`, `requests`).

---

## Instalación

```bash
git clone https://github.com/SCorreaCSALatam/ga4-looker-studio-generator.git
cd ga4-looker-studio-generator
pip install -r requirements.txt
```

> El nombre del repositorio en GitHub puede ser `ga4-looker-studio-generator`; la carpeta local puede tener otro nombre.

---

## Uso rápido

### Interfaz web

```bash
python src/web_app.py
```

Abre en el navegador la URL que muestra la consola (por defecto **http://127.0.0.1:8765**). Desde ahí puedes:

1. **Paso 1 (una vez):** registrar la app ante Google — formulario con Client ID / secret o archivo `client_secret.json` (ver [docs/google-oauth-setup.md](docs/google-oauth-setup.md)).
2. **Paso 2:** **Iniciar sesión con Google** (o conexión por redirección) para rellenar cuentas y propiedades GA4.
3. Rellenar **Report ID** de la plantilla y generar la URL (modo plantilla o informe guardado con `params`).

**Local:** por defecto escucha en `127.0.0.1`. **Servidor (p. ej. Render):** define `GA_LS_HOST=0.0.0.0`, `GA_LS_BASE_URL` con tu URL pública HTTPS, `GA_LS_SESSION_SECRET`, credenciales OAuth por variables de entorno y, si aplica, `GA_LS_DATA_DIR` persistente. Detalle en [docs/deploy.md](docs/deploy.md).

### CLI — crear informe desde plantilla

```bash
python src/linking_url.py --report-id TU_UUID_PLANTILLA --account-id CUENTA_GA --property-id PROPIEDAD_GA4 --report-name "Nombre del informe"
```

Opciones frecuentes: `--ds-alias ds1`, `--refresh-fields`, `--mode edit`, `--embed`. Ver `python src/linking_url.py --help`.

### CLI — informe guardado con `?params=` (fase 2)

```bash
python src/linking_url.py --saved-report-id ... --saved-page-id ... --params-json-file examples/params-sample.json
```

Documentación: [docs/url-params-phase2.md](docs/url-params-phase2.md).

---

## Variables de entorno (resumen)

| Ámbito | Variables |
|--------|-----------|
| Web local | `PORT`, `GA_LS_BASE_URL` (alineada con OAuth en Google Cloud). |
| Web en servidor | Además: `GA_LS_HOST`, `GA_LS_SESSION_SECRET`, `GA_LS_DATA_DIR`, `GA_LS_COOKIE_SECURE`, `GOOGLE_OAUTH_*`. |
| OAuth | `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`, `GOOGLE_OAUTH_REDIRECT_URI` o `client_secret.json` / formulario en la UI. |

---

## Documentación del repositorio

| Documento | Contenido |
|-----------|-------------|
| [docs/template-looker-studio.md](docs/template-looker-studio.md) | Plantilla en Looker Studio, `reportId`, alias del origen (`ds1`, …). |
| [docs/google-oauth-setup.md](docs/google-oauth-setup.md) | Google Cloud: API, consentimiento, cliente web, orígenes JS, primer login. |
| [docs/deploy.md](docs/deploy.md) | Git, Render/servidor, variables de producción. |
| [docs/governance.md](docs/governance.md) | Credenciales del origen en Looker Studio y permisos GA4. |
| [docs/url-params-phase2.md](docs/url-params-phase2.md) | Enlaces con `params` en informes ya guardados. |

---

## Retomar el trabajo o el contexto (Cursor / IA)

- El **estado del chat** lo gestiona Cursor; no vive en el repo.
- Para que un asistente (o tú más adelante) retome **el mismo contexto técnico**, abre esta carpeta como proyecto y revisa este **README** y la carpeta **`docs/`**: ahí está el comportamiento acordado (plantilla, OAuth, despliegue).
- Si añades funcionalidad, actualiza **README** o la doc enlazada en la misma PR/commit para mantener una sola fuente de verdad.

---

## Licencia

Sin licencia explícita en el repositorio: uso interno o elige una licencia (MIT, etc.) y añade un archivo `LICENSE` cuando lo definas.
