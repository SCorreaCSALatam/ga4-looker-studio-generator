<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>GA4 → Looker Studio</title>
  <style>
    :root { font-family: system-ui, Segoe UI, sans-serif; color: #1a1a1a; }
    body { max-width: 42rem; margin: 2rem auto; padding: 0 1rem; }
    h1 { font-size: 1.25rem; font-weight: 600; }
    fieldset { border: 1px solid #ccc; border-radius: 6px; margin: 0 0 1rem; padding: 0.75rem 1rem; }
    legend { font-weight: 600; padding: 0 0.35rem; }
    label { display: block; margin: 0.5rem 0 0.15rem; font-size: 0.85rem; }
    input[type="text"], input[type="password"], textarea, select { width: 100%; box-sizing: border-box; padding: 0.35rem 0.5rem; border: 1px solid #bbb; border-radius: 4px; font-size: 0.95rem; }
    textarea { min-height: 4rem; font-family: ui-monospace, monospace; }
    .row { display: flex; gap: 1rem; flex-wrap: wrap; }
    .row label { flex: 1 1 8rem; }
    .checks { margin-top: 0.75rem; }
    .checks label { display: inline; font-weight: normal; margin-right: 1rem; }
    button, .btnlink { margin-top: 0.5rem; padding: 0.45rem 1rem; border-radius: 6px; border: 0; background: #1a73e8; color: #fff; font-size: 1rem; cursor: pointer; text-decoration: none; display: inline-block; }
    button:hover, .btnlink:hover { background: #1557b0; color: #fff; }
    button.secondary { background: #5f6368; }
    button.secondary:hover { background: #3c4043; }
    .err { background: #fce8e6; color: #c5221f; padding: 0.75rem 1rem; border-radius: 6px; margin-bottom: 1rem; font-size: 0.9rem; }
    .ok { background: #e6f4ea; color: #137333; padding: 0.75rem 1rem; border-radius: 6px; margin-bottom: 1rem; font-size: 0.9rem; }
    .out { margin-top: 1.25rem; padding: 1rem; background: #f8f9fa; border-radius: 6px; border: 1px solid #e0e0e0; }
    .out label { margin-top: 0; }
    .hint { font-size: 0.8rem; color: #5f6368; margin-top: 0.2rem; }
    a { color: #1a73e8; }
    .oauth-bar { padding: 0.75rem 1rem; background: #f1f3f4; border-radius: 6px; margin-bottom: 1rem; font-size: 0.9rem; }
    .oauth-bar form { display: inline; margin-left: 0.5rem; }
    #ga_ids_manual { margin-top: 0.5rem; }
    .oauth-setup { background: #e8f0fe; border: 1px solid #aecbfa; border-radius: 6px; padding: 0.75rem 1rem; margin-bottom: 1rem; font-size: 0.9rem; }
    .oauth-setup button { margin-top: 0.75rem; }
    .gsi-google-btn {
      display: inline-flex; align-items: center; justify-content: center; gap: 0.5rem;
      padding: 0.55rem 1.1rem; border: 1px solid #747775; border-radius: 4px;
      background: #fff; color: #1f1f1f; font-size: 0.95rem; font-weight: 500;
      cursor: pointer; font-family: Roboto, system-ui, sans-serif; margin-top: 0.25rem;
      box-shadow: 0 1px 2px rgba(0,0,0,0.08);
    }
    .gsi-google-btn:hover { background: #f8f9fa; border-color: #5f6368; }
    .gsi-google-btn .gsi-logo { width: 18px; height: 18px; flex-shrink: 0; }
    .oauth-alt { margin-top: 0.65rem; font-size: 0.85rem; }
    .oauth-step1 { background: #e8f0fe; border: 1px solid #aecbfa; border-radius: 6px; padding: 0.85rem 1rem; margin-bottom: 0.75rem; font-size: 0.92rem; line-height: 1.45; }
    .oauth-step1 h2 { font-size: 1rem; margin: 0 0 0.5rem 0; font-weight: 600; }
    .oauth-details { margin-top: 0.65rem; font-size: 0.85rem; color: #3c4043; }
    .oauth-details summary { cursor: pointer; color: #1a73e8; font-weight: 500; }
    .oauth-details[open] summary { margin-bottom: 0.35rem; }
  </style>
</head>
<body>
  <h1>Generador de enlaces Looker Studio</h1>
  <p class="hint">La app genera enlaces de Looker Studio. Para <strong>elegir propiedad GA4 en un menú</strong> hace falta que una persona inicie sesión con Google; antes, alguien de tu equipo debe registrar <strong>esta aplicación</strong> ante Google (una vez) — no es lo mismo que entrar a GA4.</p>

  % if oauth_flash_ok:
  <div class="ok">Cuenta de Google vinculada correctamente. Ya puedes elegir una propiedad en la lista.</div>
  % end
  % if oauth_flash_cfg_ok:
  <div class="ok">Paso 1 listo. Usa el botón <strong>Iniciar sesión con Google</strong> que aparece arriba (o el enlace de redirección) y acepta los permisos.</div>
  % end
  % if oauth_flash_err:
  <div class="err">{{oauth_flash_err}}</div>
  % end
  % if error:
  <div class="err">{{error}}</div>
  % end

  <div class="oauth-bar">
    % if oauth_configured:
      % if oauth_connected:
        <strong>Google:</strong> conectado.
        <form method="post" action="/disconnect" onsubmit="return confirm('¿Desconectar y borrar el token guardado en este equipo?');">
          <button type="submit" class="secondary">Desconectar</button>
        </form>
      % else:
        <p class="hint" style="margin:0 0 0.35rem 0">Inicia sesión con la cuenta Google que tenga acceso a GA4 para rellenar la lista de propiedades.</p>
        <button type="button" class="gsi-google-btn" id="btn-gis-google" onclick="requestGoogleGISLogin(); return false;" title="Abre el consentimiento de Google en una ventana emergente">
          <svg class="gsi-logo" viewBox="0 0 48 48" aria-hidden="true"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6C44.21 39.92 48 32.83 48 24c0-1.64-.15-3.19-.43-4.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg>
          Iniciar sesión con Google
        </button>
        <p class="oauth-alt"><a href="/connect">Si falla la ventana emergente, abrir conexión por redirección</a> (misma cuenta, otra forma de flujo).</p>
        <script>window.GIS_CLIENT_ID = {{!gis_client_id_json}};</script>
        <script src="https://accounts.google.com/gsi/client" async defer onload="initGisCodeClient()"></script>
        <script>
        var __gisCodeClient = null;
        function initGisCodeClient() {
          if (!window.google || !window.GIS_CLIENT_ID) return;
          __gisCodeClient = google.accounts.oauth2.initCodeClient({
            client_id: window.GIS_CLIENT_ID,
            scope: 'https://www.googleapis.com/auth/analytics.readonly',
            ux_mode: 'popup',
            callback: function (resp) {
              if (resp.error) { alert(resp.error + (resp.error_description ? ': ' + resp.error_description : '')); return; }
              if (!resp.code) return;
              var xhr = new XMLHttpRequest();
              xhr.open('POST', '/oauth/gis-code', true);
              xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
              xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
              xhr.onload = function () {
                try {
                  var j = JSON.parse(xhr.responseText || '{}');
                  if (xhr.status === 200 && j.ok) { window.location.href = '/?oauth_ok=1'; return; }
                  alert(j.error || 'No se pudo completar el inicio de sesión.');
                } catch (e) {
                  alert(xhr.responseText || 'Error de red');
                }
              };
              xhr.onerror = function () { alert('Error de red al contactar el servidor.'); };
              xhr.send('code=' + encodeURIComponent(resp.code));
            }
          });
        }
        function requestGoogleGISLogin() {
          if (!__gisCodeClient) {
            alert('Cliente Google no cargado. Comprueba la consola del navegador y que exista Client ID.');
            return;
          }
          __gisCodeClient.requestCode({ prompt: 'consent' });
        }
        </script>
      % end
    % else:
      <div class="oauth-step1">
        <h2>Paso 1 — Registrar esta aplicación (una vez)</h2>
        <p style="margin:0 0 0.5rem 0">Google <strong>no permite</strong> que cualquier página llame a sus APIs (p. ej. listar propiedades de GA4) sin antes registrar <strong>qué programa eres</strong>. Eso se hace gratis en la consola de desarrolladores de Google (a veces llamada «Google Cloud»): obtienes un <strong>ID de cliente</strong> y un <strong>secreto</strong> que identifican <em>esta herramienta</em>, no tu usuario de Analytics.</p>
        <p style="margin:0 0 0.5rem 0"><strong>Después de guardar</strong> aparecerá aquí el <strong>Paso 2: botón «Iniciar sesión con Google»</strong> para que cada quien entre con su Gmail y se rellenen las listas.</p>
        <details class="oauth-details">
          <summary>¿Por qué no basta con «loguearme en GA4»?</summary>
          <p style="margin:0">GA4 es una web aparte. Para que <em>otra</em> app (esta) pida datos en nombre de quien usa el navegador, Google exige el registro de la app + pantalla de consentimiento. Los datos de GA4 siguen siendo los de siempre; solo añades permiso de «esta herramienta puede listar propiedades si el usuario acepta».</p>
        </details>
      </div>
      <div class="oauth-setup">
        <p class="hint" style="margin-top:0">Pega los valores de la consola de Google (cliente tipo <strong>aplicación web</strong>) o usa el archivo <code>client_secret.json</code> en la raíz del proyecto. Guía paso a paso: <code>docs/google-oauth-setup.md</code>.</p>
        <form method="post" action="/oauth/setup-credentials">
          <label for="setup_client_id">ID de cliente (Client ID)</label>
          <input type="text" id="setup_client_id" name="setup_client_id" autocomplete="off" placeholder="xxxxx.apps.googleusercontent.com" required />
          <label for="setup_client_secret">Secreto de cliente (Client secret)</label>
          <input type="password" id="setup_client_secret" name="setup_client_secret" autocomplete="new-password" required />
          <label for="setup_redirect_uri">URI de redirección (la misma que en la consola)</label>
          <input type="text" id="setup_redirect_uri" name="setup_redirect_uri" value="{{oauth_setup_redirect_hint}}" required />
          <p class="hint">En la consola del cliente OAuth, en <strong>URI de redirección autorizados</strong>, debe existir exactamente esta ruta (p. ej. <code>http://127.0.0.1:8765/oauth/callback</code>). Para el botón de Google también hace falta <strong>Origen JavaScript autorizado</strong> = solo el origen sin ruta (p. ej. <code>http://127.0.0.1:8765</code>).</p>
          <button type="submit">Guardar y activar «Iniciar sesión con Google»</button>
        </form>
      </div>
    % end
  </div>

  % if oauth_connected and ga_list_error:
  <div class="err">No se pudo cargar la lista de propiedades: {{ga_list_error}}</div>
  % end

  <form method="post" action="/generate">
    <fieldset>
      <legend>Modo</legend>
      <label><input type="radio" name="form_mode" value="create" {{create_checked}} /> Crear informe desde plantilla (Linking API)</label>
      <label><input type="radio" name="form_mode" value="saved" {{saved_checked}} /> Informe ya guardado con <code>?params=</code></label>
    </fieldset>

    <div id="block-create">
      <fieldset>
        <legend>Plantilla → nueva copia</legend>
        <label for="report_id">Report ID (plantilla)</label>
        <input type="text" id="report_id" name="report_id" value="{{report_id}}" autocomplete="off" />

        % if oauth_connected and ga_groups:
        <label for="ga_property_pick">Propiedad GA4</label>
        <select id="ga_property_pick" name="ga_property_pick" data-current="{{property_pick_current}}">
          <option value="">— Elegir cuenta / propiedad —</option>
          % for g in ga_groups:
          <optgroup label="{{g['account_display_name']}} (cuenta {{g['account_id']}})">
            % for p in g['properties']:
            <option value="{{g['account_id']}}|{{p['property_id']}}">{{p['property_display_name']}} — {{p['property_id']}}</option>
            % end
          </optgroup>
          % end
        </select>
        <div class="checks" style="margin-top:0.5rem">
          <label><input type="checkbox" id="ga_manual_ids" name="ga_manual_ids" value="1" {{ga_manual_checked}} /> Introducir Account ID y Property ID manualmente</label>
        </div>
        % end

        <div id="ga_ids_manual" class="row" style="display:none">
          <label>Account ID <input type="text" id="account_id" name="account_id" value="{{account_id}}" autocomplete="off" {{ga_manual_inputs_disabled}} /></label>
          <label>Property ID <input type="text" id="property_id" name="property_id" value="{{property_id}}" autocomplete="off" {{ga_manual_inputs_disabled}} /></label>
        </div>
        % if not oauth_connected or not ga_groups:
        <div class="row" id="ga_ids_fallback">
          <label>Account ID <input type="text" name="account_id" value="{{account_id}}" autocomplete="off" /></label>
          <label>Property ID <input type="text" name="property_id" value="{{property_id}}" autocomplete="off" /></label>
        </div>
        % end

        <div class="row">
          <label>Alias origen <input type="text" name="ds_alias" value="{{ds_alias}}" placeholder="ds1" autocomplete="off" /></label>
          <label>Nombre del informe (opcional) <input type="text" name="report_name" value="{{report_name}}" autocomplete="off" /></label>
        </div>
        <label for="datasource_name">Nombre del origen (opcional)</label>
        <input type="text" id="datasource_name" name="datasource_name" value="{{datasource_name}}" autocomplete="off" />
        <div class="row">
          <label>Modo apertura
            <select name="mode">
              <option value="" {{mode_empty}}>Predeterminado</option>
              <option value="view" {{mode_view}}>view</option>
              <option value="edit" {{mode_edit}}>edit</option>
            </select>
          </label>
          <label>Page ID (opcional) <input type="text" name="page_id" value="{{page_id}}" autocomplete="off" /></label>
        </div>
        <div class="checks">
          <label><input type="checkbox" name="refresh_fields" value="1" {{refresh_checked}} /> refreshFields</label>
          <label><input type="checkbox" name="embed" value="1" {{embed_checked}} /> Ruta /embed/…</label>
        </div>
      </fieldset>
    </div>

    <div id="block-saved">
      <fieldset>
        <legend>Informe guardado</legend>
        <div class="row">
          <label>Report ID <input type="text" name="saved_report_id" value="{{saved_report_id}}" autocomplete="off" /></label>
          <label>Page ID <input type="text" name="saved_page_id" value="{{saved_page_id}}" autocomplete="off" /></label>
        </div>
        <label for="params_json">JSON de parámetros</label>
        <textarea id="params_json" name="params_json" placeholder='{"ds1.Event name": "body_button_menu_click"}'>{{params_json}}</textarea>
        <div class="checks">
          <label><input type="checkbox" name="saved_embed" value="1" {{saved_embed_checked}} /> Embed</label>
        </div>
      </fieldset>
    </div>

    <button type="submit">Generar URL</button>
  </form>

  % if url:
  <div class="out">
    <label for="out_url">URL generada</label>
    <textarea id="out_url" readonly rows="4">{{url}}</textarea>
    <p class="hint">Copia y abre en el navegador (sesión Google con acceso a esa propiedad GA4).</p>
  </div>
  % end

  <script>
    (function () {
      function syncMode() {
        var saved = document.querySelector('input[name="form_mode"][value="saved"]').checked;
        document.getElementById('block-create').style.display = saved ? 'none' : 'block';
        document.getElementById('block-saved').style.display = saved ? 'block' : 'none';
      }
      document.querySelectorAll('input[name="form_mode"]').forEach(function (el) {
        el.addEventListener('change', syncMode);
      });
      syncMode();

      var pick = document.getElementById('ga_property_pick');
      var manual = document.getElementById('ga_manual_ids');
      var rowManual = document.getElementById('ga_ids_manual');
      var fallback = document.getElementById('ga_ids_fallback');

      function syncGaInputs() {
        if (!pick || !manual || !rowManual) return;
        var m = manual.checked;
        rowManual.style.display = m ? 'flex' : 'none';
        pick.disabled = m;
        var a = document.getElementById('account_id');
        var p = document.getElementById('property_id');
        if (a) a.disabled = !m;
        if (p) p.disabled = !m;
        if (m && pick) pick.selectedIndex = 0;
      }
      if (manual) {
        manual.addEventListener('change', syncGaInputs);
        syncGaInputs();
      }

      if (pick && pick.dataset.current) {
        var v = pick.dataset.current;
        for (var i = 0; i < pick.options.length; i++) {
          if (pick.options[i].value === v) { pick.selectedIndex = i; break; }
        }
      }

      if (pick && rowManual) {
        pick.addEventListener('change', function () {
          var opt = pick.options[pick.selectedIndex];
          if (!opt || !opt.value) return;
          var parts = opt.value.split('|');
          if (parts.length === 2) {
            var a = document.getElementById('account_id');
            var p = document.getElementById('property_id');
            if (a) a.value = parts[0];
            if (p) p.value = parts[1];
          }
        });
      }
    })();
  </script>
</body>
</html>
