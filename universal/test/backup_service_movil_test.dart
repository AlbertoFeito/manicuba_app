// Pruebas de las rutas "móviles" de BackupService (guardar, auto-backup y
// compartir), habilitadas con BackupService.debugIsMobileOverride = true.
//
// path_provider se redirige a una carpeta temporal real y share_plus se
// sustituye por un fake que registra la llamada, para no depender de los
// plugins nativos.

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestorpro_app/services/backup_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'support/fake_path_provider.dart';

/// Fake de SharePlatform que guarda los argumentos de la última llamada.
class FakeShare extends SharePlatform with MockPlatformInterfaceMixin {
  List<XFile>? lastFiles;
  String? lastSubject;
  String? lastText;

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
    List<String>? fileNameOverrides,
  }) async {
    lastFiles = files;
    lastSubject = subject;
    lastText = text;
    return const ShareResult('ok', ShareResultStatus.success);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePathProvider fake;
  late FakeShare share;

  setUp(() {
    BackupService.debugIsMobileOverride = true;
    fake = FakePathProvider.install();
    share = FakeShare();
    SharePlatform.instance = share;
  });

  tearDown(() {
    BackupService.debugIsMobileOverride = null;
    fake.dispose();
  });

  test('createBackupFile escribe el archivo y devuelve su ruta', () async {
    final ruta = await BackupService.createBackupFile(storeName: 'Mi Salón');

    expect(ruta, isNotNull);
    expect(ruta, endsWith('.json'));

    final file = File(ruta!);
    expect(file.existsSync(), isTrue);
    expect(file.path, contains('/Backups/'));

    // El contenido es un backup válido.
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(BackupService.isValidBackup(data), isTrue);
  });

  test('maybeAutoBackup crea un backup del día y no duplica', () async {
    expect(await BackupService.listBackups(), isEmpty);

    await BackupService.maybeAutoBackup();

    final tras1 = await BackupService.listBackups();
    expect(tras1, hasLength(1));

    // El nombre incluye la fecha de hoy.
    final hoy = DateTime.now();
    String dos(int n) => n.toString().padLeft(2, '0');
    final hoyStr = '${hoy.year}-${dos(hoy.month)}-${dos(hoy.day)}';
    expect(tras1.first.name, contains(hoyStr));

    // Segunda llamada el mismo día: no debe crear otro.
    await BackupService.maybeAutoBackup();
    expect(await BackupService.listBackups(), hasLength(1));
  });

  test('shareBackup guarda un archivo temporal y lo pasa a Share', () async {
    await BackupService.shareBackup(storeName: 'Tienda');

    expect(share.lastFiles, isNotNull);
    expect(share.lastFiles, hasLength(1));
    expect(File(share.lastFiles!.first.path).existsSync(), isTrue);
    expect(share.lastFiles!.first.path, endsWith('.json'));
    expect(share.lastSubject, contains('Tienda'));
  });
}
