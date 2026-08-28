// Pruebas de la lógica de compartir un post: qué app abrir según la
// plataforma, y cómo reacciona CompartirService según si esa app abrió.
//
// No se prueban aquí las ramas que copian al portapapeles (Instagram /
// Facebook): un `Clipboard.setData` real dentro de un `testWidgets` hace
// crashear el compilador incremental de `flutter test` en este entorno de
// pruebas (reproducido de forma aislada y determinista, sin relación con
// el código de la app — `flutter build apk` usa otro compilador y no se ve
// afectado). Igual que con los canales de share_plus/url_launcher, esa
// rama queda cubierta por la verificación manual, no por la suite.

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/post_redes.dart';
import 'package:multiservicios_app/services/compartir_nativo.dart';
import 'package:multiservicios_app/services/compartir_service.dart';

/// Simula el canal nativo sin tocar Android de verdad.
class _NativoFalso extends CompartirNativo {
  _NativoFalso({required this.abre});

  final bool abre;

  @override
  Future<bool> compartirEnApp({
    required List<String> rutas,
    required String texto,
    required String paquete,
  }) async {
    return abre;
  }
}

PostRedes _post(String plataforma) => PostRedes(
      titulo: 't',
      contenido: 'c',
      tipo: 'oferta',
      plataforma: plataforma,
      fechaCreacion: DateTime.now(),
    );

void main() {
  test('paqueteParaPlataforma mapea cada red a su paquete de Android', () {
    expect(paqueteParaPlataforma('whatsapp'), 'com.whatsapp');
    expect(paqueteParaPlataforma('WhatsApp'), 'com.whatsapp');
    expect(paqueteParaPlataforma('instagram'), 'com.instagram.android');
    expect(paqueteParaPlataforma('facebook'), 'com.facebook.katana');
    expect(paqueteParaPlataforma('todas'), isNull);
    expect(paqueteParaPlataforma('tiktok'), isNull);
  });

  test('ignoraTextoPrellenado: solo WhatsApp respeta el texto del intent',
      () {
    expect(ignoraTextoPrellenado('whatsapp'), isFalse);
    expect(ignoraTextoPrellenado('instagram'), isTrue);
    expect(ignoraTextoPrellenado('facebook'), isTrue);
  });

  testWidgets('WhatsApp: si la app nativa abre, no hace falta copiar nada',
      (tester) async {
    final servicio = CompartirService(nativo: _NativoFalso(abre: true));
    final modo = await servicio.compartirPost(_post('whatsapp'));
    expect(modo, ModoCompartir.appDirecta);
  });
}
