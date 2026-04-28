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
    input[type="text"], textarea, select { width: 100%; box-sizing: border-box; padding: 0.35rem 0.5rem; border: 1px solid #bbb; border-radius: 4px; font-size: 0.95rem; }
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
  </style>
</head>
<body>
  <h1>Generador de enlaces Looker Studio</h1>
  <p class="hint">La app corre solo en tu equipo; las URLs se generan aquí. Conectar Google sirve para listar propiedades GA4 (Analytics Admin API).</p>

  % if oauth_flash_ok:
  <div class="ok">Cuenta de Google vinculada correctamente. Ya puedes elegir una propiedad en la lista.</div>
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
        <a class="btnlink" href="/connect" style="margin-top:0">Conectar con Google</a>
        <span class="hint"> (permite elegir cuenta y propiedad GA4 sin teclear IDs)</span>
      % end
    % else:
      <span class="hint">OAuth no configurado. Crea <code>client_secret.json</code> o variables <code>GOOGLE_OAUTH_*</code>; guía en <code>docs/google-oauth-setup.md</code>.</span>
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
