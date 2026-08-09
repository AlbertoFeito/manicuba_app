# ManiCuba — versión Qt (QML + C++)

Reescritura de la app ManiCuba con **Qt 6 (Qt Quick / QML + C++)**, pensada para
correr en **escritorio y móvil** con la misma base de código. La app Flutter
original se conserva en la raíz del repositorio como referencia.

Incluye:

- Base de datos SQLite con las **9 tablas** del esquema original y los servicios
  sembrados por defecto (compatible con los datos de la app Flutter).
- **Licencia por dispositivo** con prueba de 15 días, portada 1:1 (mismo
  HMAC-SHA256 y mismo alfabeto base32 → las licencias emitidas siguen siendo válidas).
- Navegación responsiva (barra inferior en móvil, panel lateral en escritorio).
- **Modo claro/oscuro** con interruptor (☀️/🌙) y persistencia.
- Los 8 módulos: **Inicio, Agenda, Clientes, Servicios, Finanzas** (con gráficos
  dibujados en Canvas), **Inventario, Redes Sociales y Galería**.

Pendiente: el empaquetado para **Android** (SDK/NDK).

## Arquitectura

- **C++ (`src/`)** — lógica de negocio y datos, expuesta a QML:
  - `db/Database` — conexión SQLite, creación de tablas y semillas.
  - `services/*` — `ClienteService`, `ServicioService`, `CitaService`,
    `FinanzasService`, `LicenciaService`, `CategoriaService`. Reflejan los
    servicios de `lib/services/*.dart`. Los datos viajan a QML como
    `QVariantMap`/`QVariantList` con claves camelCase.
  - `config/AppConfig` — constantes globales (categorías, métodos, límites).
- **QML (`qml/`)** — interfaz:
  - `Theme.qml` (singleton) — paleta y medidas de `lib/config/theme.dart`.
  - `Main.qml` — ventana y navegación adaptativa.
  - `LicenciaGate.qml` — bloquea la app cuando la prueba vence.
  - `screens/` — Inicio, Clientes, Servicios y Agenda.
  - `components/` — tarjetas y piezas reutilizables.

La regla de negocio clave (`CitaService::sincronizarIngreso`) se conserva: al
completar una cita con monto se crea/actualiza un ingreso enlazado y se marca la
última visita del cliente; al descompletarla o borrarla, el ingreso se elimina.

## Requisitos

- Qt 6.2+ con los módulos Quick, Quick Controls 2 y Sql (driver SQLite).
- CMake 3.21+ y un compilador C++17.

En Debian/Ubuntu:

```bash
sudo apt-get install qt6-base-dev qt6-declarative-dev \
  qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
  qml6-module-qtquick-templates qml6-module-qtquick-window \
  qml6-module-qtquick-dialogs qml6-module-qtcore \
  libqt6sql6-sqlite qt6-declarative-dev-tools
```

## Compilar y ejecutar

```bash
cmake -S qt -B qt/build
cmake --build qt/build -j
./qt/build/manicuba
```

### Secreto de licencias

En producción, pasa el secreto de firma al configurar (debe coincidir con el del
generador de licencias):

```bash
cmake -S qt -B qt/build -DLICENSE_SECRET="tu-secreto-real"
```

Si no se define, se usa `manicuba-dev-secret` (solo para desarrollo; la app lo
advierte en la pantalla de licencia).

## Datos

La base de datos se crea en la carpeta de datos de la app
(`QStandardPaths::AppDataLocation`, p. ej.
`~/.local/share/AlbertoFeito/ManiCuba/manicuba.db` en Linux). La licencia y las
categorías personalizadas se guardan con `QSettings`.
