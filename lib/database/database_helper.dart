import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String dbName = 'manicuba.db';
  static const int dbVersion = 1;

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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _createTables(Database db) async {
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

  Future<void> _insertDefaultServicios(Database db) async {
    final servicios = [
      {
        'nombre': 'Manicura Básica',
        'precio': 10.0,
        'duracion_minutos': 30,
        'descripcion': 'Corte, lima y esmalte básico'
      },
      {
        'nombre': 'Manicura con Gel',
        'precio': 20.0,
        'duracion_minutos': 45,
        'descripcion': 'Gel UV resistente y duradero'
      },
      {
        'nombre': 'Acrílicas',
        'precio': 25.0,
        'duracion_minutos': 60,
        'descripcion': 'Uñas acrílicas con acabado'
      },
      {
        'nombre': 'Manicura Decorada',
        'precio': 15.0,
        'duracion_minutos': 40,
        'descripcion': 'Con decoraciones y diseños'
      },
      {
        'nombre': 'Esmaltado Francés',
        'precio': 12.0,
        'duracion_minutos': 35,
        'descripcion': 'Clásico francés elegante'
      },
    ];

    for (var servicio in servicios) {
      await db.insert('servicios', servicio);
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

  // PRODUCTOS
  Future<int> insertProducto(Map<String, dynamic> producto) async {
    final db = await database;
    return await db.insert('productos', producto);
  }

  Future<List<Map<String, dynamic>>> getAllProductos() async {
    final db = await database;
    return await db.query('productos', orderBy: 'nombre');
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
