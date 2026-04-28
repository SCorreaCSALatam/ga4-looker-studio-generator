# Gobernanza: credenciales del origen y permisos GA4

## Permisos mínimos en Google Analytics 4

Para **conectar** la propiedad GA4 a Looker Studio y que los gráficos carguen datos:

- Rol recomendado como mínimo: **Analizar** (en inglés a veces *Analyst* / *Read & Analyze* según la interfaz).
- Quien **primero autoriza** el conector al crear o editar el origen de datos debe tener ese acceso (o superior, p. ej. **Editor**).

Sin acceso a la propiedad, Looker Studio mostrará errores de permisos o datos vacíos al consultar GA4.

## Credenciales del origen de datos en Looker Studio

Al editar el origen conector **Google Analytics**, en la parte superior del panel de campos puedes elegir cómo se accede a los datos:

### Credenciales del propietario (Owner's credentials)

- Las peticiones a GA4 se hacen **en nombre de la cuenta que configuró el origen**.
- **Ventaja**: quien abra el informe no necesita ser usuario de GA4 para ver números agregados (útil para stakeholders internos).
- **Riesgo**: el alcance de lo que ven coincide con lo que puede ver esa cuenta en GA4; si compartes el informe ampliamente, revisa qué datos expone.

### Credenciales del visor (Viewer's credentials)

- Cada persona que abre el informe debe **autenticarse** y GA4 comprueba su acceso a la propiedad.
- **Ventaja**: el control de acceso queda alineado con GA4 (menos fugas si alguien reenvía el enlace sin permiso en GA4).
- **Inconveniente**: cada visor necesita cuenta Google y permiso en la propiedad.

### Cuentas de servicio (Service accounts)

- En Looker Studio, el uso documentado de **credenciales de cuenta de servicio** para orígenes está pensado sobre todo para **BigQuery**, no como reemplazo estándar del conector GA4 para todos los equipos.
- Para el flujo de esta herramienta (plantilla + Linking API + conector GA4), lo habitual es **propietario** o **visor** con cuentas de usuario.

## Recomendaciones prácticas

1. **Equipos internos de marketing/analytics**: suele funcionar bien **credenciales del propietario** con una cuenta de servicio *humana* (cuenta técnica de equipo) que solo tenga acceso a propiedades permitidas.
2. **Informes para clientes externos**: valorar **credenciales del visor** para que cada cliente vea solo sus propiedades con su propia sesión.
3. Documentar en tu wiki **qué cuenta** es la propietaria del origen en la plantilla y el proceso para rotar accesos si alguien deja la empresa.

## Enlace con la herramienta de URLs

La herramienta solo genera la URL de creación; **no elige** el tipo de credenciales. Eso queda fijado en la **plantilla** (o lo reconfigura quien edita el nuevo informe tras crearlo). Tras generar el informe desde el enlace, revisa el origen de datos si necesitas cambiar de propietario a visor o al revés.
