# Multiservicios

App de gestión para salones de servicios (manicura, peluquería, spa y los que
se agreguen), construida sobre el mismo motor que ManiCuba y PeluCuba pero
como **una sola app configurable por rubro**, en vez de un proyecto Flutter
separado por negocio.

Este proyecto es **independiente**: no comparte código en tiempo de
compilación con `../lib` (ManiCuba) ni con `../pelos` (PeluCuba). Se
bootstrapeó copiando ManiCuba como punto de partida y adaptando los puntos
que antes eran específicos de cada app.

## Cómo funciona la configuración por rubro

- `lib/config/business_config.dart` define `BusinessType` (manicura,
  peluqueria, spa) y `BusinessConfig` (colores, textos, catálogo de
  servicios sugerido, hashtags/emojis para redes). Agregar un rubro nuevo es
  agregar una entrada a `kBusinessConfigs`.
- En el primer arranque, `BusinessTypeScreen`
  (`lib/screens/onboarding/business_type_screen.dart`) pregunta el rubro,
  lo guarda en `SharedPreferences` y aplica el tema (`AppTheme.aplicarConfig`).
  En arranques siguientes, `main.dart` carga el rubro guardado antes de
  `runApp()`.
- El resto de la app (agenda, clientes, finanzas, inventario, backup) es
  100% compartido a nivel de código y no depende del rubro — pero cada
  rubro guarda sus datos en su propia base de datos (ver siguiente
  sección), así que en la práctica son negocios completamente separados.
- Desde el menú de Inicio ("⋮" → "Cambiar tipo de negocio") se puede
  volver a `BusinessTypeScreen` (con `esCambio: true`) para cambiar de
  rubro después del onboarding. `main.dart` expone un `Restarter` que
  reconstruye toda la app en caliente al aplicar el cambio, sin reiniciar
  el proceso.

## Datos independientes por rubro

Clientes, citas, servicios, finanzas e inventario de "Manicura" son
completamente independientes de los de "Spa", como si fueran negocios
separados — no solo la licencia. Esto se implementa en
`lib/database/database_helper.dart`: `dbName` es un getter que depende del
rubro activo (`app_<rubro>.db`), así que cada rubro abre su propio archivo
SQLite. Al cambiar de rubro, `BusinessTypeScreen` cierra la conexión
abierta (`DatabaseHelper().closeConnection()`) antes de reiniciar la app,
para que la próxima consulta abra la base correcta.

Los backups siguen la misma separación: `BackupService.listBackups()` solo
muestra los del rubro activo, `maybeAutoBackup()` solo cuenta los backups
de hoy de ese rubro, y restaurar un archivo de otro rubro con el selector
de archivos se rechaza con un aviso (el JSON exportado incluye
`businessType` para poder detectarlo).

## Licenciamiento: por rubro, no por dispositivo

Cada rubro es un producto con su propio pago. Activar "Manicura" no da
acceso a "Spa" en el mismo equipo — ver `lib/services/licencia_service.dart`:
el estado de prueba/licencia se guarda con una key de `SharedPreferences`
distinta por `BusinessType`, y el código de licencia incluye el rubro en el
mensaje firmado (`app:v1:<rubro>:<deviceId>`). Un dispositivo puede tener
varios rubros licenciados a la vez; cada uno se activa y paga por separado.

El generador de licencias para esta app está en
`herramientas/generador-licencias.html` (no uses el de `../herramientas/`,
ese es para ManiCuba/PeluCuba y usa un esquema de firma distinto).

## Compilar

```bash
flutter pub get
flutter build apk --release --dart-define=LICENSE_SECRET=<secreto-de-produccion>
```

Necesita su propia keystore de producción (`android/key.properties` +
`.jks`, no versionados) — no reutilices la de ManiCuba ni la de PeluCuba.

## Pendiente antes de publicar

- Ícono definitivo (hoy usa el ícono de ManiCuba como placeholder; el nombre
  "Multiservicios" ya es definitivo).

## Releases

Los APK firmados con la keystore de producción se publican en `release/`
dentro de esta carpeta (ver ahí el más reciente). El keystore y
`key.properties` en sí NO se versionan (ver `.gitignore`); guárdalos aparte.
