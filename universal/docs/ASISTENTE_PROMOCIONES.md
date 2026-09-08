# Asistente de Promociones

Módulo para ayudar al dueño/a del negocio a **promover su negocio en redes sociales** de forma
semi-automática, sin salir de la app y **sin depender de internet** salvo en el momento de
compartir (igual que el resto de la app).

No hace auto-posteo real a Instagram/Facebook (la app es offline, sin backend, y Meta exige
Graph API + cuentas Business + aprobación). En su lugar **automatiza qué publicar, cuándo y con
un toque**, orquestando piezas que ya existían.

---

## Punto de partida (baseline)

Este módulo se construyó sobre la app multi-negocio (`universal/`). Antes de él, ya existía y se
**reutiliza sin reescribir**:

| Pieza | Archivo | Qué aporta |
|---|---|---|
| Modelo de post | `lib/models/post_redes.dart` | `tipo`, `fechaProgramada`, `plataforma`, `fotoIds`, `publicado` |
| Servicio de redes | `lib/services/redes_service.dart` | CRUD, `estadisticas()`, sugerencias de hashtags/emojis |
| Compartir nativo | `lib/services/compartir_service.dart`, `compartir_nativo.dart`, `android/.../MainActivity.kt` | Compartir texto+fotos a WhatsApp/IG/FB con FileProvider |
| Contenido por rubro | `lib/config/business_config.dart` | `plantillasPost`, `hashtagsComunes`, `emojisPopulares` por rubro (manicura/peluquería/spa) |
| Clientes / citas / fotos | `lib/services/{cliente,cita,foto}_service.dart`, `lib/models/{cliente,foto_trabajo}.dart` | `Cliente.ultimaVisita`, citas, galería de trabajos |
| Deep-links a clientas | `lib/screens/clientes/cliente_detail_screen.dart` | `wa.me` / `smsto:` / `tel:` vía `url_launcher` |
| Base de datos | `lib/database/database_helper.dart` | `dbVersion = 2`, migraciones vía `runMigrations`; tabla `estadisticas_redes` **creada pero sin uso** |

**Gaps que este módulo cubre:** no había notificaciones (ningún paquete), no había perfil/ajustes
de negocio, la tabla `estadisticas_redes` estaba vacía, y `fechaProgramada` existía pero nada la
consumía.

Baseline de tests en el momento de arrancar: **212 tests en verde** (`flutter test`).

---

## Diseño

1. **Perfil del negocio** — datos del negocio (nombre, teléfono, dirección, horario, redes) para
   autocompletar los posts. Persistido en `SharedPreferences` con clave por rubro
   (`perfil_<BusinessType.name>`), como `AppConfig`/`LicenciaService`.
2. **Generación automática de promos** — `AsistenteService` calcula sugerencias desde los propios
   datos: clientas inactivas (win-back), semanas flojas, foto nueva sin post, promo mensual /
   constancia. Cada sugerencia arma un borrador de `PostRedes` con la plantilla del rubro + los
   datos del perfil.
3. **Recordatorios** — `NotificacionesService` (paquetes `flutter_local_notifications` + `timezone`)
   agenda avisos usando `PostRedes.fechaProgramada` y un recordatorio de constancia.
4. **Difusión directa a clientas** — `DifusionService` reutiliza los deep-links `wa.me`/`smsto:`
   para enviar una promo 1-a-1 a clientas seleccionadas.
5. **Analítica** — se activan los contadores de la tabla `estadisticas_redes`.

---

## Archivos nuevos vs. modificados

**Nuevos**
- `lib/models/perfil_negocio.dart`, `lib/models/sugerencia_promo.dart`
- `lib/services/perfil_service.dart`, `lib/services/asistente_service.dart`,
  `lib/services/notificaciones_service.dart`, `lib/services/difusion_service.dart`
- `lib/screens/perfil/perfil_screen.dart`, `lib/screens/asistente/asistente_screen.dart`,
  `lib/screens/difusion/difusion_screen.dart`
- Tests correspondientes en `test/`

**Modificados**
- `lib/screens/home_screen.dart` (entradas de menú/acceso)
- `lib/services/redes_service.dart` (escribir en `estadisticas_redes`, integrar recordatorios)
- `lib/services/cliente_service.dart` (completar `obtenerClientesFrecuentes`)
- `pubspec.yaml` (paquetes de notificaciones)
- `android/app/src/main/AndroidManifest.xml` (permisos de notificaciones)
- `main.dart` (init de notificaciones)

Cada archivo nuevo lleva un comentario de cabecera indicando que pertenece al Asistente de
Promociones.
