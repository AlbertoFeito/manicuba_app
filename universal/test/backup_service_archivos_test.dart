// Pruebas de la gestión de archivos de BackupService, usando el mock de
// path_provider para redirigir los directorios de la app a una carpeta
// temporal real.
//
// Nota: createBackupFile/shareBackup/maybeAutoBackup tienen su ruta principal
// detrás de Platform.isAndroid/isIOS, que en el host de test (Linux) es false
// y no se puede mockear sin tocar el código. Aquí se cubre lo que NO depende
// de esa comprobación (directorio, listar, borrar, leer, importar+copiar) y
// se verifica el comportamiento en la rama no-móvil de las otras tres.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/config/business_config.dart';
import 'package:multiservicios_app/models/cliente.dart';
import 'package:multiservicios_app/services/backup_service.dart';
import 'package:multiservicios_app/services/cliente_service.dart';
import 'package:path_provider/path_provider.dart';

import 'support/fake_path_provider.dart';

// Prefijo real de los nombres de archivo de backup para "Manicura" (rubro
// fijado en cada test): listBackups() solo muestra los del rubro activo,
// así que los archivos de prueba deben empezar igual que los que generaría
// la app de verdad (ver BackupService._backupFilename/_slugify).
const _prefijo = 'multiservicios-manicura';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePathProvider fake;

  setUp(() {
    AppConfig.instance.setBusinessType(BusinessType.manicura);
    fake = FakePathProvider.install();
  });
  tearDown(() => fake.dispose());

  Future<Directory> backupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/Backups');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  test('listBackups lista solo .json, ordenados por fecha (recientes primero)',
      () async {
    // Sin archivos aún: lista vacía.
    expect(await BackupService.listBackups(), isEmpty);

    final dir = await backupDir();
    final viejo = File('${dir.path}/$_prefijo-viejo.json')
      ..writeAsStringSync('{}');
    final nuevo = File('${dir.path}/$_prefijo-nuevo.json')
      ..writeAsStringSync('{}');
    // Un no-json que debe ignorarse.
    File('${dir.path}/notas.txt').writeAsStringSync('hola');
    // Un backup de OTRO rubro: no debe aparecer con Manicura activo.
    File('${dir.path}/multiservicios-spa-ajeno.json').writeAsStringSync('{}');

    viejo.setLastModifiedSync(DateTime(2024, 1, 1));
    nuevo.setLastModifiedSync(DateTime(2025, 1, 1));

    final backups = await BackupService.listBackups();
    final nombres = backups.map((b) => b.name).toList();
    expect(nombres,
        ['$_prefijo-nuevo.json', '$_prefijo-viejo.json']); // más reciente primero
    expect(nombres.contains('notas.txt'), isFalse);
    expect(nombres.contains('multiservicios-spa-ajeno.json'), isFalse);
  });

  test('readBackupContent decodifica el JSON del archivo', () async {
    final dir = await backupDir();
    final file = File('${dir.path}/data.json')
      ..writeAsStringSync(jsonEncode({'clientes': [], 'saludo': 'hola'}));
    final backup = BackupFile(
      name: 'data.json',
      file: file,
      createdAt: DateTime.now(),
      sizeBytes: file.lengthSync(),
    );

    final contenido = await BackupService.readBackupContent(backup);
    expect(contenido['saludo'], 'hola');
    expect(contenido['clientes'], isA<List>());
  });

  test('deleteBackup borra el archivo y no falla si ya no existe', () async {
    final dir = await backupDir();
    final file = File('${dir.path}/borrar.json')..writeAsStringSync('{}');
    final backup = BackupFile(
      name: 'borrar.json',
      file: file,
      createdAt: DateTime.now(),
      sizeBytes: 2,
    );

    await BackupService.deleteBackup(backup);
    expect(file.existsSync(), isFalse);

    // Segunda vez: no debe lanzar (la rama de "no existe").
    await BackupService.deleteBackup(backup);
  });

  test('importDataFromFile válido importa y copia el archivo a Backups',
      () async {
    final clientes = ClienteService();
    final marca = 'BK-${DateTime.now().microsecondsSinceEpoch}';
    await clientes.crearCliente(Cliente(nombre: marca, telefono: '55500000'));

    // Snapshot completo a un archivo fuera de la carpeta de backups. El
    // nombre lleva el prefijo del rubro activo porque exportData() incluye
    // "businessType" en el JSON y listBackups() filtra por rubro.
    final json = await BackupService.exportData();
    final origen = File('${fake.root.path}/$_prefijo-restore-$marca.json')
      ..writeAsStringSync(json);

    await BackupService.importDataFromFile(origen);

    // Los datos se restauraron (la marca sobrevive)...
    expect(
      (await clientes.obtenerTodos()).any((c) => c.nombre == marca),
      isTrue,
    );
    // ...y el archivo quedó copiado en Backups para aparecer en la lista.
    final enLista =
        (await BackupService.listBackups()).map((b) => b.name).toList();
    expect(enLista.contains('$_prefijo-restore-$marca.json'), isTrue);
  });

  test('importDataFromFile rechaza un backup de otro rubro', () async {
    // Con Manicura activo, un JSON marcado como "spa" no debe importarse:
    // mezclaría los datos de un rubro con los del otro.
    final data = jsonDecode(await BackupService.exportData())
        as Map<String, dynamic>;
    data['businessType'] = 'spa';
    final origen = File('${fake.root.path}/de-otro-rubro.json')
      ..writeAsStringSync(jsonEncode(data));

    await expectLater(
      BackupService.importDataFromFile(origen),
      throwsA(isA<Exception>()),
    );
  });

  test('createBackupFile en no-móvil devuelve null (y arma el nombre)',
      () async {
    // En Linux Platform.isAndroid/isIOS es false: la función arma el nombre
    // (ejercita el slug y el padding de fecha) y devuelve null antes de
    // escribir. No debe lanzar.
    final ruta = await BackupService.createBackupFile(
      storeName: 'Mi Salón!! **',
    );
    expect(ruta, isNull);
  });

  test('shareBackup lanza en plataforma no soportada', () async {
    await expectLater(
      BackupService.shareBackup(storeName: 'Tienda'),
      throwsA(isA<Exception>()),
    );
  });

  test('maybeAutoBackup es un no-op en no-móvil (no lanza)', () async {
    await BackupService.maybeAutoBackup();
  });
}
