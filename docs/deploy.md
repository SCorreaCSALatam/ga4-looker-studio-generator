# Git y despliegue en servidor

No tengo acceso a tu cuenta de GitHub ni a tus credenciales: los pasos de **push** los haces tú en tu máquina (o en CI). Aquí va lo habitual y lo específico de esta app.

## 1. Subir el código a GitHub

En la carpeta del proyecto (con Git instalado):

```bash
git init
git add .
git commit -m "Initial commit: herramienta GA4 → Looker Studio"
```

Crea un repositorio **vacío** en GitHub (sin README si ya tienes uno local) y enlázalo:

```bash
git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
git branch -M main
git push -u origin main
```

**No subas secretos:** `client_secret.json` está en `.gitignore`. En el servidor usa **variables de entorno** (`GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`, `GOOGLE_OAUTH_REDIRECT_URI`).

## 2. Qué cambia al ser “público”

| Local (`127.0.0.1`) | Servidor (varios usuarios) |
|---------------------|----------------------------|
| Un navegador | Cada visitante tiene **cookie de sesión** y su **propio token OAuth** en disco (`GA_LS_DATA_DIR/tokens/`). |
| `GA_LS_BASE_URL` implícito | Debe ser la **URL pública HTTPS** del sitio, p. ej. `https://informes.ejemplo.com`. |
| OAuth redirect `http://127.0.0.1:.../oauth/callback` | Misma ruta pero con **tu dominio**; añádela en Google Cloud Console. |
| `127.0.0.1` | Escucha `0.0.0.0` con **`GA_LS_HOST=0.0.0.0`** para que el hosting enrute tráfico. |

## 3. Variables de entorno recomendadas en producción

| Variable | Uso |
|----------|-----|
| `GA_LS_BASE_URL` | URL pública sin barra final, p. ej. `https://tu-dominio.com` (debe coincidir con OAuth). |
| `GOOGLE_OAUTH_REDIRECT_URI` | `https://tu-dominio.com/oauth/callback` |
| `GOOGLE_OAUTH_CLIENT_ID` / `GOOGLE_OAUTH_CLIENT_SECRET` | Credenciales OAuth (no commitear). |
| `GA_LS_SESSION_SECRET` | Secreto largo y aleatorio para **firmar cookies**; sin él, al reiniciar el proceso las sesiones caducan. |
| `GA_LS_HOST` | `0.0.0.0` para aceptar conexiones externas. |
| `PORT` | Puerto que expone el proceso (muchas plataformas lo inyectan solas). |
| `GA_LS_DATA_DIR` | Carpeta **persistente** en el servidor para tokens por usuario (p. ej. volumen montado). |
| `GA_LS_COOKIE_SECURE` | `1` si el sitio solo se sirve por **HTTPS** (cookies `Secure`). |

## 4. HTTPS y cookies

Tras un proxy TLS (Nginx, Caddy, Cloudflare, Render, etc.), activa `GA_LS_COOKIE_SECURE=1` para que la cookie de sesión solo vaya por HTTPS.

## 5. Plataformas típicas

- **VPS + systemd**: servicio que ejecute `python src/web_app.py` con `Environment=` en el unit, detrás de Nginx con `proxy_pass` al `PORT`.
- **Railway / Render / Fly.io**: “Web service”, comando de arranque similar, variables en el panel, volumen opcional para `GA_LS_DATA_DIR`.

El proceso es **un solo worker** de Bottle; para mucho tráfico valorar **Gunicorn + workers** y una app WSGI (refactor menor) más adelante.

## 6. Seguridad breve

- Esta herramienta **no sustituye** a un producto enterprise: revisa quién puede acceder a la URL pública.
- Los tokens OAuth en disco son sensibles: permisos del directorio `GA_LS_DATA_DIR` y copias de seguridad acordes a tu política.
