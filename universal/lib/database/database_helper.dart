import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../config/business_config.dart';

class DatabaseHelper {
  static const String dbName = 'app.db';
  static const int dbVersion = 2;

  static Database? _db;

  // Singleton
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: runMigrations,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await crearEsquema(db);
  }

  /// Migraciones incrementales del esquema. Se aplican en cadena, así que una
  /// instalación vieja de cualquier versión llega al día sin perder datos.
  /// Es público para poder probarlo con una base de prueba.
  static Future<void> runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _migrarAV2(db);
    }
  }

  /// v1 → v2: conecta el inventario con las finanzas.
  /// Añade el enlace `gastos.producto_id`, crea el historial de movimientos
  /// (que antes no existía: el stock era un número que se sobreescribía) y
  /// da a cada producto ya existente su movimiento de saldo inicial.
  ///
  /// Es idempotente: se puede correr dos veces sin duplicar nada.
  static Future<void> _migrarAV2(Database db) async {
    final columnas = await db.rawQuery('PRAGMA table_info(gastos)');
    final tieneProductoId = columnas.any((c) => c['name'] == 'producto_id');
    if (!tieneProductoId) {
      await db.execute('ALTER TABLE gastos ADD COLUMN producto_id INTEGER');
    }

    await db.execute(_sqlMovimientosInventario);

    // Los productos que ya estaban en la app no tienen historial. Se les crea
    // una entrada con el stock que traen para que el historial arranque de
    // algún lado. NO genera gasto: ese dinero salió antes de esta versión y
    // puede que ya esté anotado a mano; crearlo ahora le inflaría el mes.
    final movimientos = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM movimientos_inventario'),
        ) ??
        0;
    if (movimientos > 0) {
      return;
    }

    // Los literales van a propósito sin pasar por AppConstants: una migración
    // es una foto fija del pasado y no debe cambiar si mañana se renombra una
    // constante, o dejaría de reproducir lo que realmente se escribió.
    final productos = await db.query('productos');
    for (final producto in productos) {
      final stock = (producto['cantidad_stock'] as int?) ?? 0;
      if (stock <= 0) {
        continue;
      }
      final fecha = (producto['fecha_compra'] as String?) ??
          (producto['fecha_creacion'] as String?) ??
          DateTime.now().toIso8601String();
      await db.insert('movimientos_inventario', {
        'producto_id': producto['id'],
        'tipo': 'entrada',
        'cantidad': stock,
        'costo_unitario': producto['costo_unitario'],
        'motivo': 'saldo_inicial',
        'gasto_id': null,
        'fecha': fecha,
        'notas': 'Stock que ya tenías al actualizar la app',
      });
    }
  }

  /// Historial de entradas y salidas de inventario. Definido una sola vez
  /// para que la creación desde cero y la migración no se desincronicen.
  static const String _sqlMovimientosInventario = '''
      CREATE TABLE IF NOT EXISTS movimientos_inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    ''';

  /// Crea el esquema completo de la versión actual. Es público para poder
  /// comprobar en los tests que una instalación nueva y una migrada quedan
  /// igual.
  Future<void> crearEsquema(Database db) async {
    // Tabla Clientes
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

    // Tabla Servicios
    await db.execute('''
      CREATE TABLE servicios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precio REAL NOT NULL,
        duracion_minutos INTEGER NOT NULL,
        descripcion TEXT
      )
    ''');

    // Tabla Citas
    await db.execute('''
      CREATE TABLE citas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        servicio_id INTEGER NOT NULL,
        fecha_hora TEXT NOT NULL,
        duracion_minutos INTEGER NOT NULL,
        estado TEXT DEFAULT 'pendiente',
        monto REAL,
        notas TEXT,
        fecha_creacion TEXT,
        FOREIGN KEY(cliente_id) REFERENCES clientes(id),
        FOREIGN KEY(servicio_id) REFERENCES servicios(id)
      )
    ''');

    // Tabla Ingresos
    await db.execute('''
      CREATE TABLE ingresos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cita_id INTEGER,
        monto REAL NOT NULL,
        metodo_pago TEXT NOT NULL,
        fecha TEXT NOT NULL,
        notas TEXT,
        FOREIGN KEY(cita_id) REFERENCES citas(id)
      )
    ''');

    // Tabla Gastos
    // producto_id marca los gastos generados automáticamente por una compra
    // de inventario, igual que ingresos.cita_id marca los de una cita.
    await db.execute('''
      CREATE TABLE gastos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        concepto TEXT NOT NULL,
        monto REAL NOT NULL,
        categoria TEXT NOT NULL,
        fecha TEXT NOT NULL,
        notas TEXT,
        producto_id INTEGER,
        FOREIGN KEY(producto_id) REFERENCES productos(id)
      )
    ''');

    // Tabla Productos (Inventario)
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

    // Tabla Movimientos de Inventario (historial de entradas y salidas)
    await db.execute(_sqlMovimientosInventario);

    // Tabla Posts Redes Sociales
    await db.execute('''
      CREATE TABLE posts_redes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    ''');

    // Tabla Fotos de Trabajo
    await db.execute('''
      CREATE TABLE fotos_trabajo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cita_id INTEGER,
        ruta_foto TEXT NOT NULL,
        fecha TEXT NOT NULL,
        descripcion TEXT,
        compartida INTEGER DEFAULT 0,
        FOREIGN KEY(cita_id) REFERENCES citas(id)
      )
    ''');

    // Tabla Estadísticas Redes
    await db.execute('''
      CREATE TABLE estadisticas_redes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        posts_creados INTEGER DEFAULT 0,
        fotos_compartidas INTEGER DEFAULT 0,
        ofertas_promocionadas INTEGER DEFAULT 0,
        clientes_nuevos INTEGER DEFAULT 0
      )
    ''');

    // Crear servicios por defecto
    await _insertDefaultServicios(db);
  }

  /// Siembra el catálogo de servicios sugerido para el rubro elegido (ver
  /// [AppConfig.current]). Si la base se crea antes de que la usuaria elija
  /// un rubro (no debería pasar en el flujo normal, ver `main.dart`), usa el
  /// rubro por defecto de [AppConfig] como respaldo.
  Future<void> _insertDefaultServicios(Database db) async {
    final servicios = AppConfig.instance.current.serviciosPorDefecto;

    for (final servicio in servicios) {
      await db.insert('servicios', {
        'nombre': servicio.nombre,
        'precio': servicio.precio,
        'duracion_minutos': servicio.duracionMinutos,
        'descripcion': servicio.descripcion,
      });
    }
  }

  // ===== MÉTODOS CRUD =====

  // CLIENTES
  Future<int> insertCliente(Map<String, dynamic> cliente) async {
    final db = await database;
    return await db.insert('clientes', cliente);
  }

  Future<List<Map<String, dynamic>>> getAllClientes() async {
    final db = await database;
    return await db.query('clientes', orderBy: 'nombre');
  }

  Future<Map<String, dynamic>?> getClienteById(int id) async {
    final db = await database;
    final result = await db.query('clientes', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateCliente(Map<String, dynamic> cliente) async {
    final db = await database;
    return await db.update(
      'clientes',
      cliente,
      where: 'id = ?',
      whereArgs: [cliente['id']],
    );
  }

  Future<int> deleteCliente(int id) async {
    final db = await database;
    return await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  // SERVICIOS
  Future<List<Map<String, dynamic>>> getAllServicios() async {
    final db = await database;
    return await db.query('servicios', orderBy: 'nombre');
  }

  Future<int> insertServicio(Map<String, dynamic> servicio) async {
    final db = await database;
    return await db.insert('servicios', servicio);
  }

  Future<int> updateServicio(Map<String, dynamic> servicio) async {
    final db = await database;
    return await db.update(
      'servicios',
      servicio,
      where: 'id = ?',
      whereArgs: [servicio['id']],
    );
  }

  Future<int> deleteServicio(int id) async {
    final db = await database;
    return await db.delete('servicios', where: 'id = ?', whereArgs: [id]);
  }

  // CITAS
  Future<int> insertCita(Map<String, dynamic> cita) async {
    final db = await database;
    return await db.insert('citas', cita);
  }

  Future<List<Map<String, dynamic>>> getAllCitas() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*, cl.nombre as nombre_cliente, s.nombre as nombre_servicio
      FROM citas c
      LEFT JOIN clientes cl ON c.cliente_id = cl.id
      LEFT JOIN servicios s ON c.servicio_id = s.id
      ORDER BY c.fecha_hora DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getCitasByFecha(DateTime fecha) async {
    final db = await database;
    final fechaStr = fecha.toIso8601String().split('T')[0];
    return await db.rawQuery('''
      SELECT c.*, cl.nombre as nombre_cliente, s.nombre as nombre_servicio
      FROM citas c
      LEFT JOIN clientes cl ON c.cliente_id = cl.id
      LEFT JOIN servicios s ON c.servicio_id = s.id
      WHERE DATE(c.fecha_hora) = ?
      ORDER BY c.fecha_hora
    ''', [fechaStr]);
  }

  Future<List<Map<String, dynamic>>> getCitasByCliente(int clienteId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*, cl.nombre as nombre_cliente, s.nombre as nombre_servicio
      FROM citas c
      LEFT JOIN clientes cl ON c.cliente_id = cl.id
      LEFT JOIN servicios s ON c.servicio_id = s.id
      WHERE c.cliente_id = ?
      ORDER BY c.fecha_hora DESC
    ''', [clienteId]);
  }

  Future<int> updateCita(Map<String, dynamic> cita) async {
    final db = await database;
    return await db.update(
      'citas',
      cita,
      where: 'id = ?',
      whereArgs: [cita['id']],
    );
  }

  Future<int> deleteCita(int id) async {
    final db = await database;
    return await db.delete('citas', where: 'id = ?', whereArgs: [id]);
  }

  // INGRESOS
  Future<int> insertIngreso(Map<String, dynamic> ingreso) async {
    final db = await database;
    return await db.insert('ingresos', ingreso);
  }

  Future<List<Map<String, dynamic>>> getAllIngresos() async {
    final db = await database;
    return await db.query('ingresos', orderBy: 'fecha DESC');
  }

  Future<List<Map<String, dynamic>>> getIngresosByFecha(DateTime fecha) async {
    final db = await database;
    final fechaStr = fecha.toIso8601String().split('T')[0];
    return await db.query(
      'ingresos',
      where: "DATE(fecha) = ?",
      whereArgs: [fechaStr],
      orderBy: 'fecha DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getIngresosByCita(int citaId) async {
    final db = await database;
    return await db.query(
      'ingresos',
      where: 'cita_id = ?',
      whereArgs: [citaId],
    );
  }

  Future<int> updateIngreso(Map<String, dynamic> ingreso) async {
    final db = await database;
    return await db.update(
      'ingresos',
      ingreso,
      where: 'id = ?',
      whereArgs: [ingreso['id']],
    );
  }

  Future<int> deleteIngreso(int id) async {
    final db = await database;
    return await db.delete('ingresos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteIngresosByCita(int citaId) async {
    final db = await database;
    return await db.delete(
      'ingresos',
      where: 'cita_id = ?',
      whereArgs: [citaId],
    );
  }

  // GASTOS
  Future<int> insertGasto(Map<String, dynamic> gasto) async {
    final db = await database;
    return await db.insert('gastos', gasto);
  }

  Future<List<Map<String, dynamic>>> getAllGastos() async {
    final db = await database;
    return await db.query('gastos', orderBy: 'fecha DESC');
  }

  Future<List<Map<String, dynamic>>> getGastosByFecha(DateTime fecha) async {
    final db = await database;
    final fechaStr = fecha.toIso8601String().split('T')[0];
    return await db.query(
      'gastos',
      where: "DATE(fecha) = ?",
      whereArgs: [fechaStr],
      orderBy: 'fecha DESC',
    );
  }

  Future<int> updateGasto(Map<String, dynamic> gasto) async {
    final db = await database;
    return await db.update(
      'gastos',
      gasto,
      where: 'id = ?',
      whereArgs: [gasto['id']],
    );
  }

  Future<int> deleteGasto(int id) async {
    final db = await database;
    return await db.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getGastosByProducto(int productoId) async {
    final db = await database;
    return await db.query(
      'gastos',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'fecha DESC',
    );
  }

  /// Corta el enlace de los gastos con un producto sin borrarlos: ese dinero
  /// salió de verdad y debe seguir contando en las finanzas aunque el
  /// producto ya no esté. Al quedar sueltos vuelven a ser gastos manuales.
  Future<int> desvincularGastosDeProducto(int productoId) async {
    final db = await database;
    return await db.update(
      'gastos',
      {'producto_id': null},
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );
  }

  // PRODUCTOS
  Future<int> insertProducto(Map<String, dynamic> producto) async {
    final db = await database;
    return await db.insert('productos', producto);
  }

  Future<List<Map<String, dynamic>>> getAllProductos() async {
    final db = await database;
    return await db.query('productos', orderBy: 'nombre');
  }

  Future<Map<String, dynamic>?> getProductoById(int id) async {
    final db = await database;
    final result = await db.query('productos', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateProducto(Map<String, dynamic> producto) async {
    final db = await database;
    return await db.update(
      'productos',
      producto,
      where: 'id = ?',
      whereArgs: [producto['id']],
    );
  }

  Future<int> deleteProducto(int id) async {
    final db = await database;
    return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  // MOVIMIENTOS DE INVENTARIO

  /// Guarda una entrada, salida o ajuste de inventario en una sola
  /// transacción: el producto (nuevo o actualizado), el gasto que pagó la
  /// compra —si lo hubo— y el movimiento que deja el rastro. Así nunca queda
  /// un gasto sin su movimiento, ni un movimiento sin su gasto.
  ///
  /// Devuelve el id del producto afectado.
  Future<int> guardarMovimientoInventario({
    required Map<String, dynamic> producto,
    required Map<String, dynamic> movimiento,
    Map<String, dynamic>? gasto,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final idExistente = producto['id'] as int?;
      final productoId = idExistente ?? await txn.insert('productos', producto);
      if (idExistente != null) {
        await txn.update(
          'productos',
          producto,
          where: 'id = ?',
          whereArgs: [idExistente],
        );
      }

      int? gastoId;
      if (gasto != null) {
        gastoId = await txn.insert('gastos', {
          ...gasto,
          'producto_id': productoId,
        });
      }

      await txn.insert('movimientos_inventario', {
        ...movimiento,
        'producto_id': productoId,
        'gasto_id': gastoId,
      });

      return productoId;
    });
  }

  /// Deshace un movimiento en una sola transacción: deja el producto como
  /// estaba, borra el gasto que lo acompañaba —si lo hubo— y elimina el
  /// rastro.
  Future<void> deshacerMovimientoInventario({
    required Map<String, dynamic> producto,
    required int movimientoId,
    int? gastoId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'productos',
        producto,
        where: 'id = ?',
        whereArgs: [producto['id']],
      );
      if (gastoId != null) {
        await txn.delete('gastos', where: 'id = ?', whereArgs: [gastoId]);
      }
      await txn.delete(
        'movimientos_inventario',
        where: 'id = ?',
        whereArgs: [movimientoId],
      );
    });
  }

  Future<Map<String, dynamic>?> getMovimientoById(int id) async {
    final db = await database;
    final result = await db.query(
      'movimientos_inventario',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllMovimientos() async {
    final db = await database;
    return await db.query('movimientos_inventario', orderBy: 'fecha DESC');
  }

  Future<List<Map<String, dynamic>>> getMovimientosByProducto(
    int productoId,
  ) async {
    final db = await database;
    return await db.query(
      'movimientos_inventario',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'fecha DESC, id DESC',
    );
  }

  Future<int> deleteMovimientosByProducto(int productoId) async {
    final db = await database;
    return await db.delete(
      'movimientos_inventario',
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );
  }

  // POSTS REDES
  Future<int> insertPostRedes(Map<String, dynamic> post) async {
    final db = await database;
    return await db.insert('posts_redes', post);
  }

  Future<List<Map<String, dynamic>>> getAllPostsRedes() async {
    final db = await database;
    return await db.query('posts_redes', orderBy: 'fecha_creacion DESC');
  }

  Future<List<Map<String, dynamic>>> getPostsRedesNoPublicados() async {
    final db = await database;
    return await db.query(
      'posts_redes',
      where: 'publicado = 0',
      orderBy: 'fecha_creacion DESC',
    );
  }

  Future<int> updatePostRedes(Map<String, dynamic> post) async {
    final db = await database;
    return await db.update(
      'posts_redes',
      post,
      where: 'id = ?',
      whereArgs: [post['id']],
    );
  }

  Future<int> deletePostRedes(int id) async {
    final db = await database;
    return await db.delete('posts_redes', where: 'id = ?', whereArgs: [id]);
  }

  // FOTOS DE TRABAJO
  Future<int> insertFotoTrabajo(Map<String, dynamic> foto) async {
    final db = await database;
    return await db.insert('fotos_trabajo', foto);
  }

  Future<List<Map<String, dynamic>>> getAllFotosTrabajo() async {
    final db = await database;
    return await db.query('fotos_trabajo', orderBy: 'fecha DESC');
  }

  Future<int> deleteFotoTrabajo(int id) async {
    final db = await database;
    return await db.delete('fotos_trabajo', where: 'id = ?', whereArgs: [id]);
  }

  // UTILIDADES
  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    await databaseFactory.deleteDatabase(path);
    _db = null;
  }
}
