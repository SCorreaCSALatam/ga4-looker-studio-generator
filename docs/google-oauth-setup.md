# Configurar Google OAuth para la interfaz web

La interfaz puede **listar cuentas y propiedades GA4** tras iniciar sesión con Google. Usa la [Google Analytics Admin API](https://developers.google.com/analytics/devguides/config/admin/v1) (método `accountSummaries.list`) con permiso de solo lectura.

**Por qué hablamos de «Google Cloud» / consola de desarrolladores:** no es para «configurar GA4» en sí. Google obliga a que **cada aplicación** que llame a sus APIs esté registrada (quién es el programa, qué permisos pide). Ese registro gratuito se hace en la misma consola donde se crean credenciales OAuth. Los datos de GA4 siguen siendo los de siempre; solo añades «esta herramienta puede pedir la lista de propiedades si el usuario inicia sesión y acepta».

## 1. Proyecto en Google Cloud

1. Entra en [Google Cloud Console](https://console.cloud.google.com/) y crea o elige un proyecto.
2. **APIs y servicios → Biblioteca** → busca **Google Analytics Admin API** → **Habilitar**.

## 2. Pantalla de consentimiento OAuth

1. **APIs y servicios → Pantalla de consentimiento de OAuth**.
2. Tipo **Externo** (o Interno si es Workspace y solo usuarios del dominio).
3. Rellena nombre de la app, email de soporte y dominios si te los pide.
4. En **Ámbitos (scopes)** → **Añadir o quitar** → incluye  
   `.../auth/analytics.readonly` (Google Analytics: read-only).

## 3. Credenciales OAuth 2.0 (cliente web)

1. **APIs y servicios → Credenciales → Crear credenciales → ID de cliente OAuth**.
2. Tipo de aplicación: **Aplicación web**.
3. **URI de redirección autorizados**: debe coincidir **exactamente** con la URL de callback de la herramienta, por ejemplo:
   - `http://127.0.0.1:8765/oauth/callback`  
   Si cambias el puerto (`PORT`) o usas otra base, añade también esa URI (y define `GA_LS_BASE_URL` en el entorno, p. ej. `http://127.0.0.1:9000`).
4. **Orígenes JavaScript autorizados** (necesarios para el botón **Iniciar sesión con Google** en la interfaz): añade el **origen** de la app, **sin** ruta ni barra final, por ejemplo `http://127.0.0.1:8765` o `https://tu-servicio.onrender.com`. Sin esto, el popup de Google puede fallar al canjear el código.
5. Descarga el JSON del cliente o copia **ID de cliente** y **Secreto del cliente**.

## 4. Poner el secreto en el proyecto

**Opción A — asistente en la interfaz (recomendado para usuarios finales)**  
Si OAuth aún no está configurado, en la página principal aparece un formulario **Guardar credenciales**. Pega el **Client ID**, el **Client secret** y la **URI de redirección** (la misma que añadiste en Google Cloud, p. ej. `http://127.0.0.1:8765/oauth/callback`).  
Se guarda en tu carpeta de usuario, **no** en el repo: `%USERPROFILE%\.ga4-looker-studio-link-tool\client_secret.json` (Windows) o `~/.ga4-looker-studio-link-tool/client_secret.json`. Luego usa **Iniciar sesión con Google** (y configura también los **orígenes JavaScript** en Google Cloud, sección 3).

**Opción B — archivo en la raíz del repo (desarrollo)**  
Renombra el JSON descargado a `client_secret.json` y colócalo en la **raíz del repositorio** (junto a `README.md`). Tiene prioridad sobre el archivo del asistente si ambos existen.  
No subas ese archivo a Git: está en `.gitignore`.

**Opción C — variables de entorno**

```text
GOOGLE_OAUTH_CLIENT_ID=....apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_SECRET=...
GOOGLE_OAUTH_REDIRECT_URI=http://127.0.0.1:8765/oauth/callback
```

## 5. Arrancar la app

```bash
pip install -r requirements.txt
python src/web_app.py
```

Abre la URL indicada en consola, pulsa **Iniciar sesión con Google** (o el enlace de redirección si el popup falla) y acepta los permisos.

## Dónde se guardan los tokens

Cada **navegador** recibe una cookie de sesión; el token OAuth de ese usuario se guarda en:

- Por defecto: `%USERPROFILE%\.ga4-looker-studio-link-tool\tokens\` (Windows), un archivo por sesión.
- Si defines **`GA_LS_DATA_DIR`**, bajo esa carpeta en `tokens/`.

**Desconectar** borra solo el token de **esa** sesión. En servidor compartido, cada visitante tiene su propio archivo (misma lógica).

### Producción

- Define **`GA_LS_SESSION_SECRET`** (cadena larga aleatoria) para que las cookies sigan siendo válidas tras reinicios.
- Con HTTPS, define **`GA_LS_COOKIE_SECURE=1`**.
- Guía de despliegue: [deploy.md](deploy.md).

## Permisos en GA4

La cuenta con la que inicias sesión debe poder **ver** las propiedades en la interfaz de Analytics (p. ej. rol Lector o superior). Si no ves una propiedad, revisa permisos en **Administrador de Google Analytics**.

## Solución de problemas

| Problema | Qué revisar |
|----------|-------------|
| `redirect_uri_mismatch` | La URI en Cloud Console debe ser **idéntica** a la del formulario / `client_secret.json` / `GOOGLE_OAUTH_REDIRECT_URI` y a la URL real del navegador al volver de Google. |
| Error 403 en la Admin API | API habilitada y scope `analytics.readonly` en el consentimiento. |
| Lista vacía | Cuenta sin propiedades GA4, o sin acceso a ninguna. |
| Popup / «Iniciar sesión con Google» falla al canjear | En el cliente OAuth, **Orígenes JavaScript autorizados** deben incluir el origen exacto de la app (p. ej. `https://tu-app.onrender.com`). |
