// Integración del módulo Redes: crear y editar un post.

import 'package:flutter_test/flutter_test.dart';

import 'package:manicuba_app/models/post_redes.dart';
import 'package:manicuba_app/services/redes_service.dart';

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
}
