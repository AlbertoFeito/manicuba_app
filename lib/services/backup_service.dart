import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// Información de un archivo de backup.
class BackupFile {
  final String name;
  final File file;
  final DateTime createdAt;
  final int sizeBytes;

  BackupFile({
    required this.name,
    required this.file,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get dateFormatted => '${createdAt.day}/${createdAt.month}/${createdAt.year} '
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
}

/// Servicio de backup y restauración de datos.
///
/// Permite exportar toda la base de datos a JSON, importarla desde JSON,
/// y crear backups automáticos diarios. Los backups se pueden compartir
/// por WhatsApp, email, Google Drive, etc.
class BackupService {
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;
  BackupService._();

  /// Sobrescribe la detección de plataforma "móvil" (Android/iOS) en tests.
  /// En producción queda en `null` y se usa el sistema operativo real. Guardar
  /// y compartir archivos solo tiene sentido en móvil; en escritorio/web las
  /// operaciones correspondientes se saltan o lanzan.
  @visibleForTesting
  static bool? debugIsMobileOverride;

  static bool get _esMovil =>
      debugIsMobileOverride ?? (Platform.isAndroid || Platform.isIOS);

  /// Exporta toda la base de datos a JSON.
  static Future<String> exportData() async {
    final db = await DatabaseHelper().database;

    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'dbVersion': DatabaseHelper.dbVersion,
      'clientes': await db.query('clientes'),
      'citas': await db.query('citas'),
      'productos': await db.query('productos'),
      'gastos': await db.query('gastos'),
      'ingresos': await db.query('ingresos'),
      'posts_redes': await db.query('posts_redes'),
      'fotos_trabajo': await db.query('fotos_trabajo'),
      'movimientos_inventario': await db.query('movimientos_inventario'),
    };

    return jsonEncode(data);
  }

  /// Importa datos desde JSON y reemplaza la base de datos.
  ///
  /// ⚠️ CUIDADO: Esto borra TODOS los datos actuales e importa los del JSON.
  static Future<void> importData(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final db = await DatabaseHelper().database;

    await db.transaction((txn) async {
      // Borrar todas las tablas
      await txn.delete('fotos_trabajo');
      await txn.delete('posts_redes');
      await txn.delete('ingresos');
      await txn.delete('gastos');
      await txn.delete('movimientos_inventario');
      await txn.delete('citas');
      await txn.delete('productos');
      await txn.delete('clientes');

      // Importar datos
      if (data['clientes'] != null) {
        for (final row in data['clientes']) {
          await txn.insert('clientes', row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['citas'] != null) {
        for (final row in data['citas']) {
          await txn.insert('citas', row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['productos'] != null) {
        for (final row in data['productos']) {
          await txn.insert('productos', row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['gastos'] != null) {
        for (final row in data['gastos']) {
          await txn.insert('gastos', row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['ingresos'] != null) {
        for (final row in data['ingresos']) {
          await txn.insert('ingresos', row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['posts_redes'] != null) {
        for (final row in data['posts_redes']) {
          await txn.insert('posts_redes', row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['fotos_trabajo'] != null) {
        for (final row in data['fotos_trabajo']) {
          await txn.insert('fotos_trabajo', row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['movimientos_inventario'] != null) {
        for (final row in data['movimientos_inventario']) {
          await txn.insert('movimientos_inventario', row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  /// Crea un archivo de backup en el directorio Documents del dispositivo.
  ///
  /// Retorna la ruta del archivo si tiene éxito, null en web.
  static Future<String?> createBackupFile({String? storeName}) async {
    try {
      final json = await exportData();
      final filename = _backupFilename(storeName ?? 'ManiCuba');

      // En web/escritorio, descargar directamente
      if (!_esMovil) {
        return null; // Web requiere otra implementación
      }

      final documentsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${documentsDir.path}/Backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final file = File('${backupDir.path}/$filename');
      await file.writeAsString(json);

      return file.path;
    } catch (e) {
      rethrow;
    }
  }

  /// Comparte un backup de datos por WhatsApp, email, etc.
  static Future<void> shareBackup({String? storeName}) async {
    try {
      final json = await exportData();
      final filename = _backupFilename(storeName ?? 'ManiCuba');

      // En dispositivos, guardar temporalmente y compartir
      if (_esMovil) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$filename');
        await file.writeAsString(json);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Copia de seguridad de $storeName',
          text: 'Copia de seguridad de $storeName - ManiCuba',
        );
      } else {
        // Web: mostrar el JSON para copiar
        // Esto debería manejarse en la UI
        throw Exception('Compartir no soportado en web');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Crea un backup automático solo si no existe uno del día actual.
  static Future<void> maybeAutoBackup() async {
    try {
      if (!_esMovil) {
        return; // No auto-backup en web
      }

      final backupDir = await _getBackupDirectory();
      final files = backupDir.listSync().whereType<File>().toList();

      // Verificar si existe un backup de hoy
      final today = DateTime.now();
      final todayStr = '${today.year}-${_pad(today.month)}-${_pad(today.day)}';

      final existsBackupToday = files.any((file) => file.path.contains(todayStr));

      if (!existsBackupToday) {
        await createBackupFile();
      }
    } catch (e) {
      // No fallar si el backup automático falla
      print('Auto backup error: $e');
    }
  }

  /// Obtiene la carpeta de backups, creándola si no existe.
  static Future<Directory> _getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${documentsDir.path}/Backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Lista todos los archivos de backup disponibles, ordenados por fecha (más recientes primero).
  static Future<List<BackupFile>> listBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      final files = backupDir.listSync().whereType<File>().toList();

      final backups = <BackupFile>[];
      for (final file in files) {
        if (file.path.endsWith('.json')) {
          final stat = await file.stat();
          final createdAt = stat.modified;
          backups.add(BackupFile(
            name: file.path.split('/').last,
            file: file,
            createdAt: createdAt,
            sizeBytes: stat.size,
          ));
        }
      }

      // Ordenar por fecha, más recientes primero
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      print('Error listing backups: $e');
      return [];
    }
  }

  /// Elimina un archivo de backup.
  static Future<void> deleteBackup(BackupFile backup) async {
    try {
      if (await backup.file.exists()) {
        await backup.file.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lee el contenido de un backup y lo retorna como Map.
  static Future<Map<String, dynamic>> readBackupContent(BackupFile backup) async {
    try {
      final json = await backup.file.readAsString();
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Valida que un JSON sea un backup válido de ManiCuba/PeluCuba.
  static bool isValidBackup(Map<String, dynamic> data) {
    // Campos tabla que deben existir y ser listas
    final tablesToCheck = [
      'clientes',
      'citas',
      'productos',
      'gastos',
      'ingresos',
      'posts_redes',
      'fotos_trabajo',
      'movimientos_inventario',
    ];

    for (final table in tablesToCheck) {
      if (!data.containsKey(table)) {
        return false;
      }
      // Verificar que sean listas
      if (data[table] is! List) {
        return false;
      }
    }

    return true;
  }

  /// Restaura desde un archivo JSON en cualquier ruta.
  /// Después de restaurar, copia el archivo a la carpeta de backups.
  static Future<void> importDataFromFile(File file) async {
    try {
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!isValidBackup(data)) {
        throw Exception(
          'El archivo no es un backup válido de ManiCuba/PeluCuba. '
          'Verifica que sea un archivo JSON generado por la app.',
        );
      }

      await importData(jsonString);

      // Copiar archivo a la carpeta de backups para que aparezca en la lista
      try {
        final backupDir = await _getBackupDirectory();
        final filename = file.path.split('/').last;
        final destFile = File('${backupDir.path}/$filename');
        await file.copy(destFile.path);
      } catch (e) {
        // Si falla la copia, no interrumpir - la restauración ya funcionó
        print('Advertencia: No se pudo copiar backup a carpeta: $e');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Genera un nombre de archivo para el backup con fecha, hora y nombre de tienda.
  static String _backupFilename(String storeName) {
    final now = DateTime.now();
    final date = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
    final time = '${_pad(now.hour)}-${_pad(now.minute)}-${_pad(now.second)}';
    final slug = _slugify(storeName);
    return '$slug-copia-$date-$time.json';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Convierte un nombre en un slug seguro para nombres de archivo.
  static String _slugify(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .toLowerCase()
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
