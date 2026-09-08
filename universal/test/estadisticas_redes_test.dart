// Pruebas de la analítica de promociones (tabla estadisticas_redes):
// crear un post y publicarlo incrementan los contadores acumulados.
// Se mide por delta porque la base es compartida entre tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/models/post_redes.dart';
import 'package:multiservicios_app/services/redes_service.dart';

void main() {
  final redes = RedesService();

  PostRedes post({required String tipo, String? fotoIds}) => PostRedes(
        titulo: 'T ${DateTime.now().microsecondsSinceEpoch}',
        contenido: 'contenido',
        tipo: tipo,
        plataforma: 'todas',
        fechaCreacion: DateTime.now(),
        fotoIds: fotoIds,
      );

  test('crear una oferta suma posts_creados y ofertas_promocionadas',
      () async {
    final antes = await redes.estadisticasPromocion();
    await redes.crearPost(post(tipo: 'oferta'));
    final despues = await redes.estadisticasPromocion();

    expect(
      despues['posts_creados']! - antes['posts_creados']!,
      1,
    );
    expect(
      despues['ofertas_promocionadas']! - antes['ofertas_promocionadas']!,
      1,
    );
  });

  test('un post educativo no cuenta como oferta', () async {
    final antes = await redes.estadisticasPromocion();
    await redes.crearPost(post(tipo: 'educativo'));
    final despues = await redes.estadisticasPromocion();

    expect(despues['posts_creados']! - antes['posts_creados']!, 1);
    expect(
      despues['ofertas_promocionadas']! - antes['ofertas_promocionadas']!,
      0,
    );
  });

  test('publicar un post suma sus fotos a fotos_compartidas', () async {
    final id = await redes.crearPost(post(tipo: 'trabajo', fotoIds: '3,7'));
    final antes = await redes.estadisticasPromocion();

    await redes.marcarPublicado(id);
    final despues = await redes.estadisticasPromocion();
    expect(
      despues['fotos_compartidas']! - antes['fotos_compartidas']!,
      2,
    );

    // Volver a marcarlo publicado no vuelve a sumar (ya estaba publicado).
    await redes.marcarPublicado(id);
    final tercero = await redes.estadisticasPromocion();
    expect(tercero['fotos_compartidas'], despues['fotos_compartidas']);
  });
}
