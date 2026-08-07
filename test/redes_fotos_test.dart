// Fotos en posts de Redes Sociales: resolución de fotoIds y regresión del
// bug que borraba las fotos de un post al editarlo.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manicuba_app/database/database_helper.dart';
import 'package:manicuba_app/models/foto_trabajo.dart';
import 'package:manicuba_app/models/post_redes.dart';
import 'package:manicuba_app/screens/redes_sociales/post_form_screen.dart';
import 'package:manicuba_app/services/compartir_service.dart';
import 'package:manicuba_app/services/foto_service.dart';
import 'package:manicuba_app/services/redes_service.dart';

/// Igual que en cliente_telefono_test.dart: el formulario hace
/// Navigator.pop() al guardar y aquí no hay nada debajo, así que
/// `pumpAndSettle()` nunca asienta. Un número acotado de `pump()` alcanza.
Future<void> _pumpsAcotados(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// El formulario de post es largo (título, tipo/plataforma, contenido,
/// emojis, hashtags, fotos, guardar); en el tamaño de superficie por
/// defecto de los tests, los botones de más abajo no quedan montados
/// dentro de un ListView no perezoso. Se agranda la superficie para que
/// todo el formulario quepa sin tener que hacer scroll manual.
void _agrandarSuperficie(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Inserta una fila de foto directo por DatabaseHelper (sin pasar por
/// FotoService.guardarDesdeArchivo, que usa path_provider y falla bajo
/// `flutter test` con MissingPluginException).
Future<int> _insertarFoto(String rutaFoto) {
  return DatabaseHelper().insertFotoTrabajo(
    FotoTrabajo(rutaFoto: rutaFoto, fecha: DateTime.now()).toMap(),
  );
}

void main() {
  test('FotoService.obtenerPorIds respeta el orden y descarta ids sin foto',
      () async {
    final id1 = await _insertarFoto('/tmp/foto1.jpg');
    final id2 = await _insertarFoto('/tmp/foto2.jpg');

    final fotos = await FotoService().obtenerPorIds([id2, 999999, id1]);

    expect(fotos.map((f) => f.id).toList(), [id2, id1]);
  });

  test('CompartirService.archivosDePost descarta fotos borradas del disco',
      () async {
    final archivo = File(
      '${Directory.systemTemp.path}/manicuba_test_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    archivo.writeAsBytesSync([0, 1, 2]);
    final id = await _insertarFoto(archivo.path);

    final post = PostRedes(
      titulo: 't',
      contenido: 'c',
      tipo: 'oferta',
      plataforma: 'todas',
      fechaCreacion: DateTime.now(),
      fotoIds: PostRedes.fotoIdsDesdeLista([id]),
    );

    final antes = await CompartirService().archivosDePost(post);
    expect(antes.length, 1);

    archivo.deleteSync();
    final despues = await CompartirService().archivosDePost(post);
    expect(despues, isEmpty);
  });

  testWidgets('Editar un post conserva sus fotoIds (regresión del bug)',
      (WidgetTester tester) async {
    _agrandarSuperficie(tester);
    late PostRedes editado;

    await tester.runAsync(() async {
      final fotoId = await _insertarFoto('/tmp/foto_post.jpg');
      final redes = RedesService();
      final id = await redes.crearPost(
        PostRedes(
          titulo: 'Original',
          contenido: 'Contenido',
          tipo: 'oferta',
          plataforma: 'instagram',
          fechaCreacion: DateTime.now(),
          fotoIds: PostRedes.fotoIdsDesdeLista([fotoId]),
        ),
      );
      final creado =
          (await redes.obtenerTodos()).firstWhere((p) => p.id == id);

      await tester.pumpWidget(
        MaterialApp(home: PostFormScreen(post: creado)),
      );
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }

      await tester.enterText(find.byType(TextFormField).first, 'Editado');
      await tester.tap(find.text('Guardar cambios'));
      await _pumpsAcotados(tester);

      editado = (await redes.obtenerTodos()).firstWhere((p) => p.id == id);
    });

    expect(editado.titulo, 'Editado');
    expect(editado.fotoIds, isNotNull);
    expect(editado.listaFotoIds, isNotEmpty);
  });

  testWidgets('Elegir una foto de la Galería de trabajos la asocia al post',
      (WidgetTester tester) async {
    _agrandarSuperficie(tester);

    await tester.runAsync(() async {
      final fotoId = await _insertarFoto('/tmp/foto_galeria.jpg');

      await tester.pumpWidget(const MaterialApp(home: PostFormScreen()));
      await tester.pump();

      await tester.tap(find.text('Agregar fotos'));
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('Elegir de la Galería de trabajos'));
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byKey(ValueKey('foto_galeria_$fotoId')));
      await tester.pump();
      await tester.tap(find.text('Listo'));
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Post con foto',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Contenido');
      await tester.tap(find.text('Guardar post'));
      await _pumpsAcotados(tester);

      final guardado = (await RedesService().obtenerTodos())
          .firstWhere((p) => p.titulo == 'Post con foto');
      expect(guardado.listaFotoIds, contains(fotoId));
    });
  });
}
