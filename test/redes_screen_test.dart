// Widget tests de RedesScreen: render de la lista de posts y navegación al
// formulario de nuevo post.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manicuba_app/models/post_redes.dart';
import 'package:manicuba_app/screens/redes_sociales/redes_screen.dart';
import 'package:manicuba_app/services/redes_service.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

/// Agranda la superficie: el formulario de post es alto y su primer campo debe
/// quedar montado al navegar.
void agrandarSuperficie(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  final redesService = RedesService();

  testWidgets('renderiza la lista con el FAB de nuevo post', (tester) async {
    await tester.runAsync(() async {
      await redesService.crearPost(
        PostRedes(
          titulo: 'Post ${DateTime.now().microsecondsSinceEpoch}',
          contenido: 'contenido',
          tipo: 'oferta',
          plataforma: 'todas',
          fechaCreacion: DateTime.now(),
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: RedesScreen()));
      await bombearHasta(tester, find.byType(Card));

      expect(find.text('Nuevo post'), findsOneWidget); // FAB
      expect(find.byType(Card), findsWidgets);
    });
  });

  testWidgets('el FAB abre el formulario de nuevo post', (tester) async {
    await tester.runAsync(() async {
      agrandarSuperficie(tester);
      await tester.pumpWidget(const MaterialApp(home: RedesScreen()));
      await bombearHasta(tester, find.text('Nuevo post'));

      await tester.tap(find.text('Nuevo post'));
      await bombearHasta(tester, find.byType(TextFormField));

      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
