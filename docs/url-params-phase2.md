# Fase 2: parámetros `?params=` en informes ya guardados

## Objetivo

Prefiltrar un informe **existente** (ya tiene `reportId` y `pageId`) pasando un JSON en la query string, por ejemplo para fijar **Event name** sin que el usuario toque el control.

## Pasos en Looker Studio

1. Abre el informe guardado (plantilla publicada o copia de trabajo).
2. Menú **Resource → Manage report URL parameters** (o equivalente en tu idioma).
3. Marca **Allow to be modified in report URL** para el parámetro que deba controlar el filtro (debe estar ligado a un control de filtro o a la lógica del informe según la guía de Looker Studio).
4. Anota el **nombre exacto** del parámetro (p. ej. `ds1.Event name`); distingue mayúsculas y espacios.

## Formato de la URL

Tras guardar y publicar:

```text
https://lookerstudio.google.com/reporting/<REPORT_ID>/page/<PAGE_ID>?params=<JSON_URL_ENCODED>
```

El valor de `params` es un **único** objeto JSON serializado y luego codificado para URL. Ejemplo de JSON antes de codificar:

```json
{"ds1.Event name":"body_button_menu_click"}
```

Para **embed**:

```text
https://lookerstudio.google.com/embed/reporting/<REPORT_ID>/page/<PAGE_ID>?params=...
```

## Uso desde la herramienta (CLI)

Ejemplo en PowerShell (escapa las comillas según tu shell):

```powershell
python src\linking_url.py `
  --saved-report-id "TU_REPORT_ID" `
  --saved-page-id "TU_PAGE_ID" `
  --params-json "{\"ds1.Event name\":\"body_button_menu_click\"}"
```

Para iframe, añade `--saved-embed`.

En **PowerShell**, las comillas del JSON suelen dar problemas; usa un archivo:

```powershell
python src\linking_url.py `
  --saved-report-id "TU_REPORT_ID" `
  --saved-page-id "TU_PAGE_ID" `
  --params-json-file examples\params-sample.json
```

También puedes importar la función en Python:

```python
from linking_url import build_saved_report_url_with_params

url = build_saved_report_url_with_params(
    report_id="...",
    page_id="...",
    params={"ds1.Event name": "body_button_menu_click"},
)
```

## Limitaciones y comprobaciones

- Los nombres de clave (`ds1.*`, `ds0.*`, …) dependen del **índice del origen** y del campo en Looker Studio; si añades un segundo origen, los prefijos pueden cambiar.
- No sustituye al flujo **Linking API** para la **primera** copia desde plantilla: ahí siguen siendo necesarios `accountId` y `propertyId`.
- Si el parámetro no está habilitado para URL o el nombre no coincide, el informe abrirá **sin** el filtro esperado; siempre conviene probar en el navegador.
- Los filtros por URL no son un control de seguridad: un usuario avanzado podría modificar la query; para datos sensibles usa permisos de GA4 e informe compartido acorde.

## Evaluación

| Criterio | Resultado |
|----------|-----------|
| ¿Soportado para GA4 nativo? | Sí, si el parámetro del informe está correctamente enlazado a dimensiones/filtros (comportamiento de producto; validar en tu plantilla). |
| ¿Reemplaza a la Linking API? | No: sirve para **refinar** un informe ya creado. |
| Implementación en repo | Función `build_saved_report_url_with_params` en `src/linking_url.py` + esta guía. |
