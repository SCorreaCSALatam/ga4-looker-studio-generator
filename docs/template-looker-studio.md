# Plantilla Looker Studio para eventos GA4

Este informe sirve de **plantilla** para la [Looker Studio Linking API](https://developers.google.com/looker-studio/integrate/linking-api). Créalo una vez; la herramienta generará enlaces que duplican el informe apuntando a otra propiedad GA4.

## Requisitos previos

- Cuenta de Google con permiso **Analizar** (o superior) en la propiedad GA4 que usarás al diseñar la plantilla.
- Dimensiones personalizadas ya registradas en GA4 si quieres desgloses por `eventCategory`, `eventAction`, `link_url`, etc.

## Pasos en Looker Studio

1. Abre [Looker Studio](https://lookerstudio.google.com) y crea un **informe en blanco**.
2. **Conectar datos**: elige **Google Analytics** y selecciona la **propiedad GA4** de referencia (puede ser de prueba).
3. Tras añadir el origen, en la barra de direcciones del editor verás una URL similar a:
   `https://lookerstudio.google.com/reporting/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/page/YYYYY`
   - **`XXXXXXXX-...`** es el **Report ID** de la plantilla (guárdalo para `c.reportId` y para la configuración de la herramienta).
4. Identifica el **alias del origen de datos** (`ds0`, `ds1`, …):
   - Looker Studio asigna `ds0`, `ds1`, … **en el orden en que se añadieron** los orígenes al informe. Si hubo otro origen antes (aunque lo borraras después), o copiaste un informe, el GA4 puede ser **`ds1`** u otro — **confírmalo siempre**. El CLI de este repo usa por defecto **`ds1`** (plantilla validada).
   - **Dónde mirarlo:** **Resource → Manage added data sources** (Gestionar fuentes de datos añadidas). Abre el origen **Google Analytics 4** con **Editar** y revisa la **URL del navegador**: suele aparecer un fragmento con el alias (p. ej. `.../datasource/...` o parámetros que incluyen `ds0` / `ds1`).
   - **Qué hacer con la herramienta:** el alias no se “arregla” renombrando a mano en Looker Studio; debes pasar el valor real al generador: **`--ds-alias ds1`** (o el que corresponda). Si usas fase 2 (`?params=`), las claves del JSON deben usar el **mismo** prefijo, p. ej. `ds1.Event name` (véase `examples/params-sample.json`).

## Gráficos recomendados (MVP)

### 1. Tabla: páginas y recuento de eventos

- **Gráfico**: Tabla.
- **Dimensión (página)**: una de:
  - **Page path + query string** (ruta + query; buena agrupación por URL “lógica”), o
  - **Landing page + query string** (si solo te interesa la entrada).
- **Métrica**: **Event count**.
- **Filtro del gráfico** (o filtro a nivel de informe): **Event name** **es igual a** el valor que quieras monitorizar por defecto, o deja el gráfico sin filtro fijo y usa solo el control global (paso siguiente).

### 2. Serie temporal

- **Gráfico**: Serie temporal.
- **Dimensión temporal**: **Date** (o **Date + hour** si necesitas hora).
- **Métrica**: **Event count**.
- Mismo criterio de filtro por **Event name** que en la tabla.

### 3. Filtro para el usuario (opción A del plan)

- Añade un **control de filtro** basado en la dimensión **Event name** (o en el campo que uses como nombre de evento en GA4).
- Así, al abrir un informe generado desde la plantilla, el usuario puede elegir el evento sin volver a editar la plantilla.

## Credenciales del origen de datos

En el panel del origen GA4, revisa **Credenciales de los datos** (propietario vs visor). Detalle en [governance.md](governance.md).

## Comprobar la plantilla antes de automatizar

1. Duplica el informe manualmente (**Archivo → Hacer una copia**) y cambia el origen a otra propiedad GA4 con la misma estructura de dimensiones.
2. Verifica que tabla y serie temporal muestran datos y que el filtro de evento funciona.

## Valores que debes anotar

| Valor | Uso en la herramienta |
|--------|------------------------|
| Report ID (UUID del informe plantilla) | `--report-id` / `LOOKER_TEMPLATE_REPORT_ID` |
| Alias del origen (en este proyecto: `ds1`) | `--ds-alias` / `LOOKER_DS_ALIAS` |
| Account ID numérico GA | `--account-id` |
| Property ID numérico GA4 | `--property-id` |

Los IDs de cuenta y propiedad los encuentras en **Google Analytics → Administrar** (selector de propiedad / detalles de la propiedad).

<a id="error-alias-ds"></a>

## Error: alias de fuente de datos no válido (p. ej. ds1)

Ese mensaje viene de la **Linking API**: en la URL estás declarando parámetros `ds.ds1.*` (o `ds0`, etc.) pero en **esa plantilla** el conector GA4 tiene **otro** alias.

1. Obtén el alias real (paso 4 arriba).
2. Vuelve a generar el enlace con **`--ds-alias`** correcto, por ejemplo si tu plantilla es `ds0`:

   ```bash
   python src/linking_url.py --report-id TU_UUID --account-id ... --property-id ... --ds-alias ds0
   ```

3. Si más adelante usas `--params-json-file`, alinea las claves con ese alias (`ds1.Event name`, `ds0.Event name`, etc.).

**Plantilla nueva solo con GA4:** si quieres que el único origen sea `ds0`, crea un informe en blanco, añade **solo** el conector GA4 como **primer** origen y construye la plantilla ahí (sin otros conectores previos).
