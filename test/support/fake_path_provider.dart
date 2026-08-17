// Mock de path_provider para tests: redirige los directorios "de la app" a
// una carpeta temporal real en disco, para poder ejercitar el código que
// escribe y lee archivos (backups, fotos) sin el plugin nativo de Android.
//
// Uso:
//   late FakePathProvider fake;
//   setUp(() { fake = FakePathProvider.install(); });
//   tearDown(() => fake.dispose());

import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  FakePathProvider(this.root);

  /// Carpeta temporal que hace de raíz para todos los directorios simulados.
  final Directory root;

  /// Instala el mock y devuelve la instancia (recuerda llamar a [dispose]).
  static FakePathProvider install() {
    final root = Directory.systemTemp.createTempSync('manicuba_pp_');
    final fake = FakePathProvider(root);
    PathProviderPlatform.instance = fake;
    return fake;
  }

  void dispose() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }

  Directory _sub(String name) {
    final dir = Directory('${root.path}/$name');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async => _sub('documents').path;

  @override
  Future<String?> getTemporaryPath() async => _sub('temp').path;

  @override
  Future<String?> getApplicationSupportPath() async => _sub('support').path;

  @override
  Future<String?> getApplicationCachePath() async => _sub('cache').path;

  @override
  Future<String?> getDownloadsPath() async => _sub('downloads').path;
}
