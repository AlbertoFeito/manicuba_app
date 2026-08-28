// Integración del módulo Redes: crear y editar un post.

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/post_redes.dart';
import 'package:multiservicios_app/services/redes_service.dart';

void main() {
  final redes = RedesService();

  test('Crear y luego editar el título de un post', () async {
    final id = await redes.crearPost(
      PostRedes(
        titulo: 'Oferta original',
        contenido: 'Contenido',
        tipo: 'oferta',
        plataforma: 'instagram',
        fechaCreacion: DateTime.now(),
      ),
    );

    final creado = (await redes.obtenerTodos()).firstWhere((p) => p.id == id);
    expect(creado.titulo, 'Oferta original');
    expect(creado.publicado, isFalse);

    await redes.actualizar(creado.copyWith(titulo: 'Oferta editada'));

    final editado = (await redes.obtenerTodos()).firstWhere((p) => p.id == id);
    expect(editado.titulo, 'Oferta editada');
  });

  test('listaFotoIds interpreta el campo fotoIds', () {
    PostRedes post(String? fotoIds) => PostRedes(
          titulo: 't',
          contenido: 'c',
          tipo: 'oferta',
          plataforma: 'instagram',
          fechaCreacion: DateTime.now(),
          fotoIds: fotoIds,
        );

    expect(post('1,2,3').listaFotoIds, [1, 2, 3]);
    expect(post(' 4 , 5 ').listaFotoIds, [4, 5]);
    expect(post(null).listaFotoIds, isEmpty);
    expect(post('').listaFotoIds, isEmpty);
    expect(post('1,abc,2').listaFotoIds, [1, 2]);
  });

  test('fotoIdsDesdeLista serializa preservando el orden', () {
    expect(PostRedes.fotoIdsDesdeLista([]), isNull);
    expect(PostRedes.fotoIdsDesdeLista([3, 1]), '3,1');
  });
}
