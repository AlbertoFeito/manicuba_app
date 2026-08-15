// Test de la migración v1 → v2 del esquema.
//
// Es el más importante del lote: la app ya está instalada con datos reales,
// y antes de esta versión no existía ningún `onUpgrade`. Si la migración
// pierde algo, se pierde el trabajo de verdad de la usuaria.

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pelucuba_app/config/constants.dart';
import 'package:pelucuba_app/database/database_helper.dart';

/// Esquema tal y como era en la versión 1, antes de conectar el inventario
/// con las finanzas: sin `gastos.producto_id` y sin tabla de movimientos.
Future<void> _crearEsquemaV1(Database db, int version) async {
  await db.execute('''
    CREATE TABLE clientes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      telefono TEXT NOT NULL,
      email TEXT,
      direccion TEXT,
      notas TEXT,
      fecha_creacion TEXT,
      ultima_visita TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE ingresos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cita_id INTEGER,
      monto REAL NOT NULL,
      metodo_pago TEXT NOT NULL,
      fecha TEXT NOT NULL,
      notas TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE gastos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      concepto TEXT NOT NULL,
      monto REAL NOT NULL,
      categoria TEXT NOT NULL,
      fecha TEXT NOT NULL,
      notas TEXT
    )
  ''');
  await db.execute('''
    CREATE TABLE productos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      categoria TEXT NOT NULL,
      cantidad_stock INTEGER NOT NULL,
      cantidad_minima INTEGER NOT NULL,
      costo_unitario REAL NOT NULL,
      fecha_compra TEXT,
      proveedor TEXT,
      fecha_creacion TEXT
    )
  ''');
}

Future<String> _rutaTemporal(String nombre) async {
  final dir = await databaseFactoryFfi.getDatabasesPath();
  return join(dir, '${nombre}_${DateTime.now().microsecondsSinceEpoch}.db');
}

/// Crea una base v1 con datos y la deja cerrada, lista para migrar.
Future<String> _baseV1ConDatos() async {
  final ruta = await _rutaTemporal('migracion');
  final db = await databaseFactoryFfi.openDatabase(
    ruta,
    options: OpenDatabaseOptions(version: 1, onCreate: _crearEsquemaV1),
  );

  await db.insert('clientes', {
    'nombre': 'Yoana',
    'telefono': '55512345',
    'fecha_creacion': DateTime.now().toIso8601String(),
  });
  await db.insert('ingresos', {
    'monto': 200.0,
    'metodo_pago': 'Efectivo',
    'fecha': DateTime.now().toIso8601String(),
  });
  await db.insert('gastos', {
    'concepto': 'Esmaltes de enero',
    'monto': 350.0,
    'categoria': 'Productos',
    'fecha': DateTime.now().toIso8601String(),
  });
  await db.insert('productos', {
    'nombre': 'Esmalte rojo',
    'categoria': 'Esmaltes',
    'cantidad_stock': 8,
    'cantidad_minima': 2,
    'costo_unitario': 45.0,
    'fecha_compra': '2026-01-15T10:00:00.000',
    'proveedor': 'Tienda del barrio',
    'fecha_creacion': '2026-01-15T10:00:00.000',
  });
  await db.insert('productos', {
    'nombre': 'Gel agotado',
    'categoria': 'Geles',
    'cantidad_stock': 0,
    'cantidad_minima': 1,
    'costo_unitario': 90.0,
    'fecha_creacion': '2026-02-01T10:00:00.000',
  });

  await db.close();
  return ruta;
}

Future<Database> _abrirComoV2(String ruta) {
  return databaseFactoryFfi.openDatabase(
    ruta,
    options: OpenDatabaseOptions(
      version: 2,
      onUpgrade: DatabaseHelper.runMigrations,
    ),
  );
}

void main() {
  test('Migrar de v1 a v2 no pierde ningún dato anterior', () async {
    final ruta = await _baseV1ConDatos();
    final db = await _abrirComoV2(ruta);

    expect(await db.query('clientes'), hasLength(1));
    expect(await db.query('ingresos'), hasLength(1));
    expect(await db.query('productos'), hasLength(2));

    final gastos = await db.query('gastos');
    expect(gastos, hasLength(1));
    expect(gastos.first['concepto'], 'Esmaltes de enero');
    expect(gastos.first['monto'], 350.0);
    // Los gastos que ya existían quedan sueltos: se escribieron a mano y
    // se siguen editando a mano.
    expect(gastos.first['producto_id'], isNull);

    await db.close();
  });

  test('Migrar crea la columna y la tabla nuevas', () async {
    final ruta = await _baseV1ConDatos();
    final db = await _abrirComoV2(ruta);

    final columnas = await db.rawQuery('PRAGMA table_info(gastos)');
    expect(
      columnas.any((c) => c['name'] == 'producto_id'),
      isTrue,
      reason: 'gastos debe quedar enlazable con productos',
    );

    final tablas = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      ['movimientos_inventario'],
    );
    expect(tablas, hasLength(1));

    await db.close();
  });

  test('Cada producto con stock arranca con su movimiento de saldo inicial',
      () async {
    final ruta = await _baseV1ConDatos();
    final db = await _abrirComoV2(ruta);

    final movimientos = await db.query('movimientos_inventario');
    // Solo el producto con stock: el agotado no necesita saldo inicial.
    expect(movimientos, hasLength(1));

    final saldo = movimientos.first;
    expect(saldo['tipo'], AppConstants.tipoMovimientoEntrada);
    expect(saldo['cantidad'], 8);
    expect(saldo['costo_unitario'], 45.0);
    expect(saldo['motivo'], AppConstants.motivoSaldoInicial);
    // Sin gasto: ese dinero salió antes de que la app llevara la cuenta, y
    // puede que ya esté anotado a mano.
    expect(saldo['gasto_id'], isNull);
    expect(saldo['fecha'], '2026-01-15T10:00:00.000');

    await db.close();
  });

  test('Repetir la migración no duplica nada', () async {
    final ruta = await _baseV1ConDatos();
    final db = await _abrirComoV2(ruta);

    await DatabaseHelper.runMigrations(db, 1, 2);

    expect(await db.query('movimientos_inventario'), hasLength(1));
    expect(await db.query('gastos'), hasLength(1));
    expect(await db.query('productos'), hasLength(2));

    await db.close();
  });

  test('Una instalación nueva crea el esquema v2 completo', () async {
    // No pasa por onUpgrade: verifica que _createTables y la migración
    // dejan la base en el mismo estado.
    final ruta = await _rutaTemporal('nueva');
    final db = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onCreate: (db, version) async {
          // Reutiliza el mismo camino que la app en un teléfono nuevo.
          await DatabaseHelper().crearEsquema(db);
        },
      ),
    );

    final columnas = await db.rawQuery('PRAGMA table_info(gastos)');
    expect(columnas.any((c) => c['name'] == 'producto_id'), isTrue);

    final tablas = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      ['movimientos_inventario'],
    );
    expect(tablas, hasLength(1));

    await db.close();
  });
}
