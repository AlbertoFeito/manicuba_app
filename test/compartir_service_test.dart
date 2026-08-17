// Pruebas de CompartirService.compartirPost cubriendo sus caminos: app nativa
// directa, copia al portapapeles, caída al selector del sistema (con y sin
// fotos), la copia a caché de las fotos y el fallo por PlatformException.
//
// Se inyecta un CompartirNativo falso y se sustituye SharePlatform por un fake
// que registra la llamada; path_provider se redirige a una carpeta temporal.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manicuba_app/models/post_redes.dart';
import 'package:manicuba_app/services/compartir_nativo.dart';
import 'package:manicuba_app/services/compartir_service.dart';
import 'package:manicuba_app/services/foto_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'support/fake_path_provider.dart';

class FakeShare extends SharePlatform with MockPlatformInterfaceMixin {
  bool lanzar = false;
  String? textoCompartido;
  List<XFile>? archivosCompartidos;

  @override
  Future<ShareResult> share(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    if (lanzar) {
      throw PlatformException(code: 'ERROR');
    }
    textoCompartido = text;
    return const ShareResult('ok', ShareResultStatus.success);
  }

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
    List<String>? fileNameOverrides,
  }) async {
    if (lanzar) {
      throw PlatformException(code: 'ERROR');
    }
    archivosCompartidos = files;
    return const ShareResult('ok', ShareResultStatus.success);
  }
}

/// CompartirNativo falso: simula si la app se abrió y guarda las rutas.
class FakeNativo implements CompartirNativo {
  FakeNativo(this.abrio);
  final bool abrio;
  List<String>? rutas;

  @override
  Future<bool> compartirEnApp({
    required List<String> rutas,
    required String texto,
    required String paquete,
  }) async {
    this.rutas = rutas;
    return abrio;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePathProvider fake;
  late FakeShare share;

  setUp(() {
    fake = FakePathProvider.install();
    share = FakeShare();
    SharePlatform.instance = share;
  });
  tearDown(() => fake.dispose());

  PostRedes post({required String plataforma, String? fotoIds}) => PostRedes(
        titulo: 'Título',
        contenido: 'Contenido a compartir',
        tipo: 'oferta',
        plataforma: plataforma,
        fotoIds: fotoIds,
        fechaCreacion: DateTime.now(),
      );

  /// Guarda [n] fotos reales y devuelve sus ids como cadena "1,2,...".
  Future<String> fotosGuardadas(int n) async {
    final servicio = FotoService();
    final ids = <int>[];
    for (var i = 0; i < n; i++) {
      final origen = File('${fake.root.path}/src_$i.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final foto = await servicio.guardarDesdeArchivo(origen);
      ids.add(foto.id!);
    }
    return ids.join(',');
  }

  test('WhatsApp abre la app directa (no copia texto)', () async {
    final svc = CompartirService(nativo: FakeNativo(true));
    final modo = await svc.compartirPost(post(plataforma: 'whatsapp'));
    expect(modo, ModoCompartir.appDirecta);
  });

  test('Instagram abre la app pero copia el texto al portapapeles', () async {
    final svc = CompartirService(nativo: FakeNativo(true));
    final modo = await svc.compartirPost(post(plataforma: 'instagram'));

    // Instagram ignora el texto del intent, así que se copia al portapapeles
    // y el modo resultante es "texto para pegar".
    expect(modo, ModoCompartir.textoPegar);
  });

  test('Si la app no está instalada, cae al selector y copia texto', () async {
    final svc = CompartirService(nativo: FakeNativo(false));
    final modo = await svc.compartirPost(post(plataforma: 'whatsapp'));

    expect(modo, ModoCompartir.textoPegar);
    expect(share.textoCompartido, contains('Contenido a compartir'));
  });

  test('Plataforma "todas" sin fotos usa el selector del sistema', () async {
    final svc = CompartirService(nativo: FakeNativo(false));
    final modo = await svc.compartirPost(post(plataforma: 'todas'));

    expect(modo, ModoCompartir.hojaSistema);
    expect(share.textoCompartido, isNotNull);
  });

  test('Plataforma "todas" con fotos comparte los archivos', () async {
    final ids = await fotosGuardadas(2);
    final svc = CompartirService(nativo: FakeNativo(false));

    final modo =
        await svc.compartirPost(post(plataforma: 'todas', fotoIds: ids));

    expect(modo, ModoCompartir.hojaSistema);
    expect(share.archivosCompartidos, hasLength(2));
  });

  test('WhatsApp con fotos copia a caché y las pasa al canal nativo', () async {
    final ids = await fotosGuardadas(2);
    final nativo = FakeNativo(true);
    final svc = CompartirService(nativo: nativo);

    final modo =
        await svc.compartirPost(post(plataforma: 'whatsapp', fotoIds: ids));

    expect(modo, ModoCompartir.appDirecta);
    // Las rutas que recibió el canal son copias en la carpeta de caché.
    expect(nativo.rutas, hasLength(2));
    expect(nativo.rutas!.every((r) => r.contains('compartir')), isTrue);
    expect(nativo.rutas!.every((r) => File(r).existsSync()), isTrue);
  });

  test('Un fallo de Share (PlatformException) devuelve modo fallo', () async {
    share.lanzar = true;
    final svc = CompartirService(nativo: FakeNativo(false));

    final modo = await svc.compartirPost(post(plataforma: 'todas'));
    expect(modo, ModoCompartir.fallo);
  });
}
