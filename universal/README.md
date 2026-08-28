# GestorPro (nombre de trabajo)

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
  100% compartido y no depende del rubro.

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

- Nombre e ícono definitivos (hoy usa el ícono de ManiCuba como placeholder
  y el nombre de trabajo "GestorPro").
- Generar keystore de producción propio.
- Decidir si se agrega una pantalla de ajustes para cambiar de rubro después
  del onboarding (hoy solo se elige una vez, al primer arranque).
