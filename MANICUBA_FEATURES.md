# ManiCuba - Feature Documentation

**Version:** 1.3.2+19  
**Platform:** Flutter (iOS/Android)  
**Architecture:** Offline-first with SQLite database  
**Language:** Spanish (es_ES)

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Database Schema](#database-schema)
3. [Data Models](#data-models)
4. [Core Services](#core-services)
5. [User Interface Screens](#user-interface-screens)
6. [Business Logic & Rules](#business-logic--rules)
7. [Test Coverage](#test-coverage)

---

## Architecture Overview

### Core Principles

- **Offline-First**: All data is stored locally in SQLite. The app works without internet connection.
- **Data-Driven UI**: Services manage business logic; UI screens call services and rebuild on state changes.
- **Automatic Synchronization**: Financial data updates automatically when related operations complete (e.g., when an appointment is marked complete, income is auto-created in Finanzas).
- **Migration Support**: Database schema versioning (v1 → v2) with idempotent migrations that preserve user data.

### Key Technical Stack

| Component | Library | Version |
|---|---|---|
| Database | sqflite | ^2.4.1 |
| UI Framework | Flutter | >=3.19.0 |
| Date/Time | intl | ^0.19.0 |
| Charts | fl_chart | ^0.69.2 |
| Calendar | table_calendar | ^3.1.2 |
| File Operations | path_provider, file_picker | ^2.1.5, ^8.1.6 |
| Sharing | share_plus | ^10.1.4 |
| Images | image_picker | ^1.1.2 |
| Local Storage | shared_preferences | ^2.3.2 |
| Connectivity | connectivity_plus | ^6.1.0 |

---

## Database Schema

### Version History

**Current:** v2  
**Migration Path:** v1 → v2 runs automatically on app launch if needed

### Tables (SQLite)

#### 1. `clientes` - Customer Records

```sql
CREATE TABLE clientes (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  telefono TEXT NOT NULL,
  email TEXT,
  direccion TEXT,
  notas TEXT,
  fecha_creacion TEXT,
  ultima_visita TEXT
)
```

**Purpose:** Store all customer information. Required for creating appointments.

#### 2. `servicios` - Service Catalog

```sql
CREATE TABLE servicios (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  precio REAL NOT NULL,
  duracion_minutos INTEGER NOT NULL,
  descripcion TEXT
)
```

**Purpose:** Define available nail services with pricing and duration. Used when creating appointments.

#### 3. `citas` - Appointments

```sql
CREATE TABLE citas (
  id INTEGER PRIMARY KEY,
  cliente_id INTEGER NOT NULL,
  servicio_id INTEGER NOT NULL,
  fecha_hora TEXT NOT NULL,
  duracion_minutos INTEGER NOT NULL,
  estado TEXT NOT NULL DEFAULT 'pendiente',
  monto REAL,
  notas TEXT,
  fecha_creacion TEXT,
  FOREIGN KEY(cliente_id) REFERENCES clientes(id),
  FOREIGN KEY(servicio_id) REFERENCES servicios(id)
)
```

**Purpose:** Appointment scheduling with status tracking (pendiente, confirmada, completada, cancelada).

**States & Transitions:**
- **pendiente** → confirmada/completada/cancelada
- **confirmada** → completada/cancelada
- **completada** → (terminal, can undo to pendiente)
- **cancelada** → (terminal, can undo to pendiente)

#### 4. `ingresos` - Income Records

```sql
CREATE TABLE ingresos (
  id INTEGER PRIMARY KEY,
  cita_id INTEGER,
  monto REAL NOT NULL,
  metodo_pago TEXT NOT NULL,
  fecha TEXT NOT NULL,
  notas TEXT,
  FOREIGN KEY(cita_id) REFERENCES citas(id)
)
```

**Purpose:** Track all income. Auto-created when appointment marked complete; can also be manually created.

#### 5. `gastos` - Expense Records

```sql
CREATE TABLE gastos (
  id INTEGER PRIMARY KEY,
  concepto TEXT NOT NULL,
  monto REAL NOT NULL,
  categoria TEXT NOT NULL,
  fecha TEXT NOT NULL,
  notas TEXT,
  producto_id INTEGER,
  FOREIGN KEY(producto_id) REFERENCES productos(id)
)
```

**Purpose:** Track all expenses. Gastos with `producto_id` are auto-created by inventory purchases (immutable); manual gastos are editable.

#### 6. `productos` - Inventory Items

```sql
CREATE TABLE productos (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  categoria TEXT NOT NULL,
  cantidad_stock INTEGER NOT NULL DEFAULT 0,
  cantidad_minima INTEGER NOT NULL DEFAULT 1,
  costo_unitario REAL NOT NULL DEFAULT 0.0,
  fecha_compra TEXT,
  proveedor TEXT,
  fecha_creacion TEXT
)
```

**Constraints:**
- Product names must be unique per category (case-insensitive, ignoring whitespace).
- Stock is tracked separately from financial transactions.

#### 7. `movimientos_inventario` - Inventory Movement History (v2+)

```sql
CREATE TABLE movimientos_inventario (
  id INTEGER PRIMARY KEY,
  producto_id INTEGER NOT NULL,
  tipo TEXT NOT NULL,
  cantidad INTEGER NOT NULL,
  costo_unitario REAL,
  motivo TEXT NOT NULL,
  gasto_id INTEGER,
  fecha TEXT NOT NULL,
  notas TEXT,
  FOREIGN KEY(producto_id) REFERENCES productos(id),
  FOREIGN KEY(gasto_id) REFERENCES gastos(id)
)
```

**Purpose:** Audit trail for all inventory changes. Enables "comprado vs. consumido" reporting.

**Movement Types & Motivos:**
- **entrada (compra)**: Stock purchase with payment. Creates gasto record.
- **entrada (saldo_inicial)**: Pre-existing stock imported on v2 migration. No gasto created (was already paid).
- **salida (consumo)**: Stock used in daily work.
- **salida (rotura)**: Breakage or loss.
- **salida (vencido)**: Expired product removed.
- **ajuste (correccion)**: Manual correction after physical count.

#### 8. `posts_redes` - Social Media Posts

```sql
CREATE TABLE posts_redes (
  id INTEGER PRIMARY KEY,
  titulo TEXT NOT NULL,
  contenido TEXT NOT NULL,
  emojis TEXT,
  hashtags TEXT,
  tipo TEXT NOT NULL,
  foto_ids TEXT,
  fecha_creacion TEXT NOT NULL,
  fecha_programada TEXT,
  publicado INTEGER DEFAULT 0,
  plataforma TEXT NOT NULL,
  visualizaciones INTEGER DEFAULT 0,
  notas TEXT
)
```

**Purpose:** Draft and track social media content (Instagram, Facebook, WhatsApp).

#### 9. `fotos_trabajo` - Photo Gallery

```sql
CREATE TABLE fotos_trabajo (
  id INTEGER PRIMARY KEY,
  cita_id INTEGER,
  ruta_foto TEXT NOT NULL,
  fecha TEXT NOT NULL,
  descripcion TEXT,
  compartida INTEGER DEFAULT 0,
  FOREIGN KEY(cita_id) REFERENCES citas(id)
)
```

**Purpose:** Store offline copies of nail work photos for marketing and portfolio use.

#### 10. `estadisticas_redes` - Social Media Analytics (Reserved)

```sql
CREATE TABLE estadisticas_redes (
  id INTEGER PRIMARY KEY,
  post_id INTEGER NOT NULL,
  visualizaciones INTEGER DEFAULT 0,
  compartidas INTEGER DEFAULT 0,
  fecha_estadistica TEXT NOT NULL,
  FOREIGN KEY(post_id) REFERENCES posts_redes(id)
)
```

**Purpose:** Track engagement metrics over time.

---

## Data Models

### Cliente

Represents a customer.

```dart
class Cliente {
  final int? id;
  final String nombre;              // Required
  final String telefono;            // Required
  final String? email;
  final String? direccion;
  final String? notas;
  final DateTime? fechaCreacion;
  final DateTime? ultimaVisita;
}
```

**Key Methods:**
- `toMap()`: Convert to database record
- `fromMap()`: Load from database
- `copyWith()`: Create modified copy

### Servicio

Service offering with pricing and duration.

```dart
class Servicio {
  final int? id;
  final String nombre;              // Required
  final double precio;              // Required
  final int duracionMinutos;        // Required (default: 30)
  final String? descripcion;
}
```

**Usage:** Selected when creating appointments; price auto-fills in cita.monto.

### Cita (Appointment)

Appointment with client, service, and status tracking.

```dart
enum EstadoCita { pendiente, confirmada, completada, cancelada }

class Cita {
  final int? id;
  final int clienteId;              // Required
  final int servicioId;             // Required
  final DateTime fechaHora;         // Required
  final int duracionMinutos;        // Required
  final EstadoCita estado;          // Default: pendiente
  final double? monto;              // Auto-filled from service price
  final String? notas;
  final DateTime? fechaCreacion;
  final String? nombreCliente;      // Denormalized for UI
  final String? nombreServicio;     // Denormalized for UI
}
```

**Business Rules:**
- When marked **completada**: Auto-creates `Ingreso` record with monto.
- When marked **cancelada** or back to **pendiente**: Removes associated `Ingreso`.
- Completed appointments cannot be deleted (protects income records); can only undo state.
- Calendar only shows pendiente + confirmada; completada/cancelada go to Historial.

### Ingreso (Income)

Income from appointments or manual entry.

```dart
class Ingreso {
  final int? id;
  final int? citaId;               // Null if manually created
  final double monto;              // Required
  final String metodo;             // efectivo, transferencia, tarjeta
  final DateTime fecha;            // Required
  final String? notas;
}
```

**Creation Patterns:**
1. **Automatic:** When appointment completes (citaId is set)
2. **Manual:** User manually enters income in Finanzas tab (citaId is null)

### Gasto (Expense)

Expense with automatic/manual tracking.

```dart
class Gasto {
  final int? id;
  final String concepto;           // Required
  final double monto;              // Required
  final String categoria;          // See categories below
  final DateTime fecha;            // Required
  final String? notas;
  final int? productoId;           // Non-null = auto-created by inventory

  bool get esAutomatico => productoId != null;
}
```

**Categories:**
- `Productos` (auto: inventory purchases)
- `Servicios`
- `Alquiler`
- `Transporte`
- `Otros`

**Rules:**
- **Automatic gastos** (productoId != null): Created by inventory purchases; cannot edit from Finanzas (edit via inventory undo).
- **Manual gastos**: Created by user; fully editable and deletable.

### Producto (Inventory Item)

Consumable inventory with cost tracking.

```dart
class Producto {
  final int? id;
  final String nombre;             // Required
  final String categoria;          // Required
  final int cantidadStock;         // Current quantity
  final int cantidadMinima;        // Low-stock threshold
  final double costoUnitario;      // Weighted average cost
  final DateTime? fechaCompra;
  final String? proveedor;
  final DateTime? fechaCreacion;

  bool get bajoStock => cantidadStock <= cantidadMinima;
}
```

**Uniqueness Constraint:** (nombre, categoria) must be unique, case-insensitive, ignoring extra whitespace.

**Cost Calculation (Weighted Average):**
```
New Cost = (oldStock × oldCost + totalPaid) / newStock
```

Example:
- Have: 10 units @ $5 = $50 total
- Buy: 5 units for $30 (total $30 paid)
- Result: 15 units @ $4 = $60 total

### MovimientoInventario (Inventory Movement)

Historical record of every inventory transaction.

```dart
class MovimientoInventario {
  final int? id;
  final int productoId;            // Required
  final String tipo;               // entrada, salida, ajuste
  final int cantidad;              // Always positive
  final double? costoUnitario;     // Only for entradas
  final String motivo;             // See motivos below
  final int? gastoId;              // Non-null if purchase paid for
  final DateTime fecha;            // Required
  final String? notas;

  bool get esEntrada => tipo == 'entrada';
  bool get esSalida => tipo == 'salida';
  bool get generoGasto => gastoId != null;
  double? get importe => costoUnitario != null ? costoUnitario! * cantidad : null;
}
```

**Motivos (Reasons):**
- **entrada → compra**: Purchase with payment (creates gasto)
- **entrada → saldo_inicial**: Pre-existing stock (no gasto)
- **salida → consumo**: Used in service
- **salida → rotura**: Broken or lost
- **salida → vencido**: Expired
- **ajuste → correccion**: Manual correction after physical count

### PostRedes (Social Media Post)

Social media content with draft/published tracking.

```dart
class PostRedes {
  final int? id;
  final String titulo;             // Required
  final String contenido;          // Required
  final String? emojis;
  final String? hashtags;
  final String tipo;               // oferta, promocion, trabajo, testimonio, educativo
  final String? fotoIds;           // CSV of photo IDs
  final DateTime fechaCreacion;    // Required
  final DateTime? fechaProgramada;
  final bool publicado;            // Default: false
  final String plataforma;         // instagram, facebook, whatsapp, todas
  final int visualizaciones;       // Default: 0
  final String? notas;

  String getContenidoFormateado();  // Concat content + emojis + hashtags
  List<int> get listaFotoIds;       // Parse CSV
}
```

**Platforms:**
- Instagram: App doesn't fill text (Instagram policy); copies to clipboard
- Facebook: App doesn't fill text (Facebook policy); copies to clipboard
- WhatsApp: App opens WhatsApp with text and media attached
- Todas: Post created for all platforms

### FotoTrabajo (Work Photo)

Photo stored offline for portfolio and marketing.

```dart
class FotoTrabajo {
  final int? id;
  final int? citaId;              // Can be unassociated
  final String rutaFoto;          // Local file path
  final DateTime fecha;           // Required
  final String? descripcion;
  final bool compartida;          // Default: false
}
```

**Purpose:** Store high-quality photos of completed nails for:
- Portfolio display (Galería tab)
- Adding to social media posts
- Future marketing

---

## Core Services

### InventarioService

Manages all inventory operations with transactional integrity.

#### Key Methods

**`registrarCompra(cantidad, monto, fechaCompra, proveedor, productoId, notas)`**
- Registers a purchase transaction
- **Updates:** producto.cantidadStock (+=), producto.costoUnitario (weighted avg)
- **Creates:** movimiento (tipo='entrada', motivo='compra', gastoId set)
- **Creates:** gasto (categoria='Productos', producto_id set, immutable)
- **Atomic:** All three operations succeed or all fail; guardarMovimientoInventario handles ordering

Example:
```
producto: nombre="Gel Rojo", stock=10, costo=5
Purchase: quantity=5, paid=$30

Result:
  stock = 15
  costo = (10×5 + 30) / 15 = 4.0
  movimiento created
  gasto created for $30 (Productos category)
```

**`registrarSalida(cantidad, motivo, productoId, notas)`**
- Decrements stock without financial impact
- **Updates:** producto.cantidadStock (-=)
- **Creates:** movimiento (tipo='salida', no gasto created)
- **motivo** must be one of: consumo, rotura, vencido

**`registrarCorreccion(productoId, nuevoStock, nuevoCosto, notas)`**
- Adjusts stock and/or unit cost after physical count
- **Updates:** producto.cantidadStock, producto.costoUnitario
- **Creates:** movimiento (tipo='ajuste', motivo='correccion')
- **No gasto created:** This is a correction, not a purchase

**`buscarPorNombreYCategoria(nombre, categoria, exceptoId?)`**
- Case-insensitive search; ignores whitespace
- Used for duplicate detection before create/update
- Returns existing product id or null

**`crearProducto(producto, registrarGasto=true)`**
- Creates new product
- **registrarGasto:** If true, auto-creates saldo_inicial movimiento + gasto record
- **registrarGasto:** If false, skips gasto (for products already paid for)

**`obtenerTodos()`** → List<Producto>
- All products, sorted by category

**`obtenerPorId(id)`** → Producto?

**`actualizarProducto(producto)`**
- Updates name, category, min stock
- Does NOT update stock or cost (use registrar methods)

**`eliminarProducto(id)`**
- Only if product has never had stock (protects history)

#### Inventory Movement History

**`obtenerMovimientos(productoId, fechaDesde?, fechaHasta?)`** → List<MovimientoInventario>
- Sorted by date descending (newest first)

**`obtenerResumenProducto(productoId, diasUltimos=30)`**
```
{
  comprado: X unidades,
  consumido: Y unidades,
  enStock: Z unidades,
  costoTotal: $valor
}
```

**`deshacerMovimiento(movimientoId)`**
- Reverses a purchase or stock adjustment
- If was a purchase (generoGasto=true), also deletes associated gasto and income

---

### CitaService

Appointment management with automatic financial sync.

#### Key Methods

**`crearCita(cita)`** → Cita
- Creates appointment
- Default duration from service
- Default monto from service price

**`obtenerPorFecha(fecha)`** → List<Cita>
- All appointments for a day
- Sorted by time
- Includes only pendiente + confirmada (not completed/canceled)

**`obtenerHistorial(estado, fechaDesde?, fechaHasta?)`** → List<Cita>
- Completed and canceled appointments
- Sorted by date descending

**`cambiarEstado(citaId, nuevoEstado)`**
- Updates appointment state
- **pendiente → confirmada/completada/cancelada**
- **confirmada → completada/cancelada**
- **completada/cancelada → pendiente (undo)**

**State Change Side Effects:**

| From | To | Action |
|---|---|---|
| pendiente/confirmada | completada | Call `sincronizarIngreso()` to create Ingreso |
| completada/cancelada | pendiente | Delete associated Ingreso (if exists) |
| pendiente/confirmada | cancelada | Delete associated Ingreso (if exists) |

**`sincronizarIngreso(citaId, marcar=true)`**
- **marcar=true:** Creates Ingreso if not exists, marks cita completada
- **marcar=false:** Deletes Ingreso if exists, marks cita pendiente
- Handles monto from cita.monto

**`editarCita(cita)`**
- Update date, time, duration, service, amount, notes
- Does NOT update state or income (use cambiarEstado)

**`eliminarCita(id)`**
- Only if state is pendiente/confirmada
- Completed appointments protected (have associated income)
- Canceling first allows deletion

---

### FinanzasService

Financial tracking and reporting with period filtering.

#### Key Methods

**`registrarIngreso(ingreso)`** → Ingreso
- Manual income entry
- No citaId (auto-created ingresos have citaId set)

**`registrarGasto(gasto)`** → Gasto
- Manual expense entry
- No productoId (auto-created gastos have productoId set)

**`obtenerIngresos(periodo='mes')`** → List<Ingreso>
- periodo: 'hoy', 'semana', 'mes', 'todo'
- Sorted by date descending

**`obtenerGastos(periodo='mes')`** → List<Gasto>
- periodo: 'hoy', 'semana', 'mes', 'todo'
- Sorted by date descending

**`obtenerBalance(periodo='mes')`** → double
- Sum of ingresos minus sum of gastos

**`gastosPorCategoria(periodo='mes')`** → Map<String, double>
- Breakdown of expenses by category
- Used for pie chart in Finanzas

**`obtenerTendencia(diasAtras=30)`** → Map<DateTime, Map>
```
{
  DateTime(2024, 1, 1): {
    ingresos: 150.0,
    gastos: 45.0,
    balance: 105.0
  },
  ...
}
```

**`editarGasto(gasto)`**
- Only manual gastos (productoId == null)
- Auto-gastos edited via inventory undo

**`eliminarGasto(id)`**
- Only manual gastos (productoId == null)

**`deshacerMovimiento(citaId)`**
- Deletes Ingreso associated with completed cita
- Called by CitaService.cambiarEstado when marking undo

---

### ClienteService

Customer management with contact methods.

#### Key Methods

**`crearCliente(cliente)`** → Cliente
- Creates new customer
- nombre + telefono required

**`obtenerTodos()`** → List<Cliente>
- All customers, sorted by name

**`buscar(query)`** → List<Cliente>
- Search by name or phone number
- Case-insensitive partial match

**`obtenerPorId(id)`** → Cliente?

**`editarCliente(cliente)`**
- Update any field

**`eliminarCliente(id)`**
- Only if client has no completed appointments
- Protects appointment history (which shows completed work)

**`obtenerHistorialCliente(clienteId)`** → List<Cita>
- All appointments for a client, newest first
- Includes all states

**`actualizarUltimaVisita(clienteId)`**
- Sets ultimaVisita to now
- Called when appointment marked complete

---

### RedeSocialesService

Social media post management.

#### Key Methods

**`crearPost(post)`** → PostRedes
- Creates draft post

**`obtenerTodos(filtro='todos')`** → List<PostRedes>
- filtro: 'todos', 'pendientes', 'publicados'
- Sorted by date descending

**`editarPost(post)`**
- Update content, hashtags, emojis, photos

**`marcarPublicado(id, publicado)`**
- Toggle published status

**`eliminarPost(id)`**

**`obtenerFotos(listaFotoIds)`** → List<FotoTrabajo>
- Load photo objects from CSV ID list

---

### FotoService

Photo gallery and attachment management.

#### Key Methods

**`guardarFoto(archivoRuta, descripcion?, citaId?)`** → FotoTrabajo
- Copy file to app storage directory
- Returns FotoTrabajo object with local path

**`obtenerTodas()`** → List<FotoTrabajo>
- All gallery photos, sorted by date descending

**`obtenerFotosCita(citaId)`** → List<FotoTrabajo>
- Photos associated with appointment

**`compartir(fotoId, plataforma)`**
- Open native share sheet or platform app

**`eliminarFoto(id)`**

---

### LicenciaService

License/trial management (single instance).

#### Key Methods

**`init()`** → Future<void>
- Loads license state from shared_preferences
- Starts trial if first launch (30 days)

**`get diasRestantes()`** → int
- Days left in trial

**`get esPrueba()`** → bool
- true if in trial period

**`get diasTranscurridos()`** → int
- Days since trial started

---

## User Interface Screens

### HomeScreen (Inicio)

Dashboard with daily summary and quick actions.

**Sections:**
1. **Daily Summary Card**
   - Appointments today (pending/confirmed)
   - Income today
   - Expenses today
   - Net balance today

2. **Quick Actions** (4 large buttons)
   - Nueva Cita → CitaFormScreen
   - Nuevo Cliente → ClienteFormScreen
   - Registrar Gasto → GastoFormScreen
   - Post Redes → PostFormScreen

3. **Menu (⋮)**
   - Servicios → ServiciosScreen
   - Inventario → InventarioScreen
   - Galería → GaleriaScreen

**State Management:**
- `_finanzasReload` counter increments when returning from Inventario
- `_cargarResumen()` refreshes daily summary on tab enter

---

### Agenda (Schedule)

Calendar-based appointment management.

**Sections:**
1. **Calendar Widget** (table_calendar)
   - Select date to view appointments for that day
   - Only shows pendiente + confirmada
   - Blue highlight for dates with appointments

2. **Appointments List for Selected Date**
   - Tap appointment to view/edit state
   - Delete button (only if pendiente/confirmada)

3. **Buttons**
   - "Nueva cita" → CitaFormScreen
   - "Historial" (menu) → HistorialScreen

**Features:**
- Default duration from service (30 min default)
- Tapping cita opens dialog to change state, edit, or delete
- Completing cita auto-creates Ingreso in Finanzas

---

### CitaFormScreen (Create/Edit Appointment)

Form to create or edit appointment.

**Fields:**
- Cliente (dropdown, searchable)
- Servicio (dropdown)
- Fecha y Hora (date + time picker)
- Duración (minutes, default from service)
- Monto (pre-filled from service price)
- Notas (optional)

**On Save:**
- Creates/updates Cita
- Returns to Agenda

---

### HistorialScreen (Appointment History)

View completed and canceled appointments.

**Display:**
- All completada + cancelada citas
- Color coded: green (completada), red (cancelada)
- Sorted newest first

**Actions per Appointment:**
- "Deshacer" button
  - Returns completada → pendiente
  - Returns cancelada → pendiente
  - Deletes associated Ingreso if exists
  - Re-adds to calendar
- Delete button (only for cancelada)

---

### Clientes (Customers)

Customer list and detail management.

**Main Screen:**
- Search bar (name + phone)
- List of all customers
- Tap to open detail, or menu for edit/delete

**ClienteDetailScreen:**
- Name, phone, email, address, notes
- Last visit date
- Contact action buttons: Call, WhatsApp, SMS, Copy
- Appointment history (all states)
- Edit/Delete buttons

**ClienteFormScreen:**
- Create/edit customer
- nombre + telefono required

**Rules:**
- Cannot delete if has completada appointments (protects history)
- Can edit data even if has completed work

---

### Servicios (Services)

Service catalog management.

**Main Screen:**
- List of services with price + duration
- Menu option per service (edit/delete)
- "Nuevo" button → ServicioFormScreen

**ServicioFormScreen:**
- nombre, precio, duracionMinutos, descripcion
- All except descripcion required

**Usage:**
- Selected when creating appointments
- Price auto-fills in cita.monto
- Duration is default for cita.duracionMinutos

---

### Finanzas (Finances)

Income/expense tracking and reporting.

**Main Screen:**

1. **Balance Cards (Top)**
   - Balance del Mes
   - Balance de Hoy (mini card)
   - Balance de Esta Semana (mini card)

2. **Buttons**
   - "Ingreso" → IngresoFormScreen
   - "Gasto" → GastoFormScreen

3. **Period Filters** (tabs)
   - Hoy
   - Semana
   - Mes
   - Todo

4. **Transactions List**
   - Ingresos (green) + Gastos (red)
   - Sorted by date descending
   - Auto-gastos show "🔒 automático" label
   - Tap transaction to edit/delete (only manual)

5. **Analytics (Swipe Left)**
   - Pie chart: Gastos por categoría
   - Trend line chart: Daily balance over 30 days
   - Touch behavior: Tap point to fix day, shows ingresos/gastos/balance below

**IngresoFormScreen:**
- monto, metodo (efectivo/transferencia/tarjeta), fecha, notas
- All except notas required

**GastoFormScreen:**
- concepto, monto, categoria, fecha, notas
- All except notas required

---

### Inventario (Inventory)

Stock management with cost tracking.

**Main Screen:**

1. **Header Cards**
   - Total value of inventory
   - Purchased in last 30 days (cost)

2. **Filters**
   - All
   - Low Stock (marca "Bajo")

3. **Products List**
   - Name, category, current stock
   - Low stock: red label "Bajo stock"
   - Plus/Minus buttons for quick actions
   - Tap product for history/correction

4. **Dialogs (Plus/Minus Buttons)**

   **Registrar Compra (Plus button)**
   - Cantidad (units purchased)
   - Total Pagado (total cost)
   - Fecha (date of purchase)
   - Proveedor (optional)
   - Creates movimiento + gasto + updates stock
   - Recalculates weighted average cost

   **Registrar Salida (Minus button)**
   - Cantidad (units consumed)
   - Motivo (consumo/rotura/vencido)
   - Creates movimiento; NO gasto
   - Stock decreases only

   **Corregir Stock (via menu)**
   - Nuevo Stock (adjust after physical count)
   - Nuevo Costo (correct cost if entered wrong)
   - Creates ajuste movimiento
   - No financial impact

5. **Menu Options**
   - Ver Historial → MovimientosScreen
   - Corregir Stock → Dialog

**MovimientosScreen (Product History)**
- Shows all movimientos for a product
- Daily summaries: Comprado, Consumido, En Stock
- Last 30 days by default
- "Deshacer" button per movimiento
  - Reverses the transaction
  - If was a purchase with gasto, deletes gasto too

**ProductoFormScreen (Create/Edit)**
- nombre, categoria, cantidadMinima (required)
- On create: Switch "Registrar el gasto" (default on)
  - If on: Creates saldo_inicial movimiento + gasto
  - If off: Just creates producto (for pre-existing stock)
- On edit: All fields writable (stock/cost still writable via dialogs)

---

### Redes Sociales (Social Media)

Draft and publish social content.

**Main Screen:**
- Filters: Todos, Pendientes, Publicados
- List of posts
- Tap post for detail/edit
- Menu options: Copiar, Compartir, Editar, Marcar Publicado/Pendiente, Eliminar

**PostFormScreen (Create/Edit):**
- titulo, contenido (required)
- tipo (oferta/promocion/trabajo/testimonio/educativo)
- plataforma (instagram/facebook/whatsapp/todas)
- Emoji chips (click to add from preset list)
- Hashtag chips (click to add from preset list)
- Photo picker (camera/gallery/galería de trabajos)
- Notas (internal)

**Share Behavior:**
- Instagram/Facebook: Opens app directly (policies don't allow pre-fill); copies content to clipboard
- WhatsApp: Opens WhatsApp with text and media attached
- Todas: Creates same post for all platforms

---

### Galería (Photo Gallery)

Offline portfolio of completed work.

**Main Screen:**
- Grid of photos
- Tap photo for full-screen view
- Menu: Compartir, Eliminar

**Add Photo:**
- Camera (take photo)
- Galería (choose from phone)
- Photos stored locally (offline access)

**Usage:**
- Add photos to social media posts
- Portfolio review
- Marketing material

---

### Licencia (Trial/License Gate)

Trial period enforcement.

**LicenciaGate:**
- Shows on first launch
- Explains trial (30 days)
- Shows days remaining

**LicenciaScreen:**
- Displays trial status
- Shows days used / days remaining
- When trial expires: App becomes read-only or restricted

---

## Business Logic & Rules

### Automatic Financial Synchronization

**Principle:** Finanzas updates automatically without user navigation.

#### When Appointment Completes

```
User marks Cita → completada
CitaService.cambiarEstado() called
  → Calls sincronizarIngreso(citaId, marcar=true)
    → Creates Ingreso with cita.monto
    → Ingreso.citaId = citaId (links back to appointment)
  → Updates Cita.estado = completada
HomeScreen._finanzasReload++
  (on return to home, finanzas refresh called)
FinanzasService notified
  (subscribers refresh if watching)
```

#### When Inventory Purchase Registered

```
User clicks Plus (Inventario) → Registrar Compra dialog
Dialog calls InventarioService.registrarCompra()
  → Updates Producto stock + cost
  → Creates MovimientoInventario (entrada, compra)
  → Creates Gasto (categoria=Productos, producto_id=set)
  → All atomic via guardarMovimientoInventario()
HomeScreen._finanzasReload++
  (on return to home, finanzas refresh called)
FinanzasService.obtenerGastos() includes new gasto
```

#### When Appointment Marked Undo

```
User taps "Deshacer" in Historial
CitaService.cambiarEstado(citaId, EstadoCita.pendiente)
  → Calls sincronizarIngreso(citaId, marcar=false)
    → Deletes associated Ingreso (citaId match)
  → Updates Cita.estado = pendiente
Cita reappears in calendar
Ingreso disappears from Finanzas
HomeScreen._finanzasReload++ (triggers refresh)
```

### Weighted Average Cost Calculation

When purchasing inventory with existing stock:

```
oldStock = 10, oldCost = $5 (total = $50)
Purchase = 5 units for $30
newStock = 10 + 5 = 15
newCost = (50 + 30) / 15 = $5.33
```

This ensures accurate valuation of inventory regardless of purchase order.

### Duplicate Product Prevention

Products identified by (nombre, categoria):
- Case-insensitive: "Gel Rojo" == "gel rojo"
- Whitespace-normalized: " Gel  Rojo " == "Gel Rojo"
- Unique per category: "Gel Rojo" in "Geles" is different from "Gel Rojo" in "Decoraciones"

**InventarioService.buscarPorNombreYCategoria()** checks on:
- Create (reject if exists)
- Update (allow self, reject if different product exists)

**Error Message:** "Ya tienes 'Gel Rojo' en categoría 'Geles'"

### Inventory Movement Audit Trail

Every stock change creates a `MovimientoInventario` record:
- Entrada (compra): Creates gasto
- Entrada (saldo_inicial): No gasto (pre-existing stock on v2 migration)
- Salida (consumo/rotura/vencido): No gasto (consumption, not purchase)
- Ajuste (correccion): No gasto (corrections don't move money)

Enables reporting:
- "Comprado in last 30 days"
- "Consumido in last 30 days"
- Stock value = sum of (remaining quantity × weighted avg cost)

### V1 → V2 Migration

**Trigger:** App detects `dbVersion` mismatch on startup

**Schema Changes:**
1. Add `producto_id` column to gastos table
2. Create movimientos_inventario table
3. Create estadisticas_redes table

**Data Preservation:**
- All existing citas, clientes, servicios preserved
- All existing gastos preserved
- All existing ingresos preserved
- Products preserved with stock intact

**New Records Created:**
- For each existing Producto:
  - Create saldo_inicial MovimientoInventario
  - Mark as motivo='saldo_inicial' (no gasto)
  - Reason: Stock existed before app tracked it (money already spent)

**Idempotent:** Migration checks for existing columns; safe to re-run.

---

## Test Coverage

### Inventory Tests (`test/inventario_test.dart`)

**17 tests** covering:
- Purchase registration with stock/cost updates
- Weighted average cost calculation
- No gasto created on salida (stock decrease)
- Duplicate product detection (case-insensitive, whitespace-normalized)
- Saldo inicial without gasto creation
- Cost correction
- Undo (reversal) of purchases and corrections

**Example:**
```
Test: Weighted Average Cost
Given: 10 units @ $5 (total $50)
When: Buy 5 units for $30
Then: 15 units @ $4 (total $80)
```

### Migration Tests (`test/migracion_test.dart`)

**5 tests** covering:
- v1 → v2 upgrade detection
- Schema changes (tables + columns)
- Data preservation (citas, gastos, ingresos, productos)
- Saldo inicial creation for existing products
- Idempotency (migration safe to re-run)

### Widget Tests

**`test/producto_form_test.dart`**
- Duplicate product rejection via form
- Uses `runAsync()` for database I/O (testWidgets doesn't auto-advance time for async DB)

**`test/finanzas_tendencia_test.dart`**
- Chart interaction: Tap to fix day, tap again to release
- Day stays fixed across frames (not lost when lifting finger)
- Shows/hides instruction text based on fixed state

**Testing Pattern for Database I/O:**
```dart
await tester.runAsync(() async {
  // Perform database operations
  // tester.pump() calls do NOT auto-advance time here
  // Use Future.delayed() explicitly
  await Future<void>.delayed(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
});
```

---

## Configuration & Constants

All constants defined in `lib/config/constants.dart`:

### Database
- `dbName` = 'manicuba.db'
- `dbVersion` = 2

### Movement Types
- `tipoMovimientoEntrada` = 'entrada'
- `tipoMovimientoSalida` = 'salida'
- `tipoMovimientoAjuste` = 'ajuste'

### Movement Reasons (Motivos)

**Entradas (Stock In):**
- `motivoCompra` = 'compra'
- `motivoSaldoInicial` = 'saldo_inicial'

**Salidas (Stock Out):**
- `motivoConsumo` = 'consumo'
- `motivoRotura` = 'rotura'
- `motivoVencido` = 'vencido'

**Ajustes (Corrections):**
- `motivoCorreccion` = 'correccion'

**Etiquetas (Display Labels):**
- Mapa `etiquetasMotivo` provides human-readable labels in Spanish

### Expense Categories

```
Productos (auto)
Servicios
Alquiler
Transporte
Otros
```

### Product Categories

```
Esmaltes
Geles
Acrílicos
Decoraciones
Herramientas
Limpiadores
Otros
```

### Payment Methods

```
Efectivo
Transferencia
Tarjeta
```

### Post Types

```
Oferta
Promoción
Trabajo
Testimonio
Educativo
```

### Social Platforms

```
Instagram
Facebook
WhatsApp
Todas
```

### Formatting

```
formatoFecha = 'dd/MM/yyyy'
formatoHora = 'HH:mm'
formatoFechaHora = 'dd/MM/yyyy HH:mm'
formatoMoneda = '$#,##0.00'
```

---

## Localization & Internationalization

- **Locale:** Spanish (es_ES)
- **Date Formatting:** Uses intl package with Spanish month/day names
- **Currency:** Dollar sign ($); numbers formatted with 2 decimals

---

## Key Design Patterns

### Service Pattern
- Business logic isolated in services
- UI screens call services, receive data
- Services handle database I/O and calculations

### Transactional Integrity
- Inventory purchases atomic: stock + cost + movement + gasto all succeed or all fail
- Prevents partial updates that would desynchronize inventory and finances

### State Refresh via Counter Increment
- `HomeScreen._finanzasReload++` signals FinanzasService to refresh
- Prevents excessive rebuilds while ensuring eventual consistency

### Denormalization for Performance
- Cita includes `nombreCliente` + `nombreServicio` (duplicated from Cliente/Servicio tables)
- Reduces JOINs needed in UI queries
- Maintained by services on create/update

### Offline-First Philosophy
- All data stored locally; no cloud sync
- Suitable for professional working offline
- Simplifies architecture; no conflict resolution needed

---

## Future Considerations for Qt Port

### Critical to Preserve
1. **Weighted Average Cost Calculation:** Exact formula and rounding
2. **Transactional Atomicity:** Stock/cost/movement/gasto all succeed together
3. **Audit Trail:** Every inventory change recorded immutably
4. **Automatic Financial Sync:** Completing appointment creates income
5. **Duplicate Prevention:** (nombre, categoria) uniqueness per product
6. **Cost Correction:** Ability to fix cost after physical count

### Migration Strategy
1. SQLite remains database (C++ bindings available)
2. Models translate directly to C++ classes
3. Services become C++ business logic classes
4. UI framework differs (Qt Widgets or QML) but logic unchanged
5. Test coverage carries over to C++ unit tests

### Platform Differences to Address
- File I/O (photos) uses different paths
- Photo gallery access via Qt native dialogs
- Social media sharing via Qt native intent/protocol handlers
- Localization via Qt .ts files instead of intl package

---

**Document Version:** 1.0  
**Last Updated:** 2026-08-13  
**ManiCuba Version:** 1.3.2+19
