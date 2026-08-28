// Widget tests de ServiciosScreen: renderiza el catálogo y el botón "Nuevo"
// navega al formulario. La BD es compartida (lista larga), así que no se busca
// un servicio concreto: se comprueba la estructura de la pantalla.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestorpro_app/models/servicio.dart';
import 'package:gestorpro_app/screens/servicios/servicios_screen.dart';
import 'package:gestorpro_app/services/servicio_service.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  final servicioService = ServicioService();

  testWidgets('renderiza el catálogo con la barra, el FAB y tarjetas',
      (tester) async {
    await tester.runAsync(() async {
      // Garantiza al menos un servicio para que salga la lista (no el vacío).
      await servicioService.crearServicio(
        Servicio(
          nombre: 'Svc ${DateTime.now().microsecondsSinceEpoch}',
          precio: 25,
          duracionMinutos: 30,
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: ServiciosScreen()));
      await bombearHasta(tester, find.byType(Card));

      expect(find.text('Servicios'), findsOneWidget); // AppBar
      expect(find.text('Nuevo'), findsOneWidget); // FAB
      expect(find.byType(Card), findsWidgets); // filas del catálogo
    });
  });

  testWidgets('el botón Nuevo abre el formulario de servicio', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: ServiciosScreen()));
      await bombearHasta(tester, find.text('Nuevo'));

      await tester.tap(find.text('Nuevo'));
      await bombearHasta(tester, find.byType(TextFormField));

      // Navegó al formulario: aparecen campos de texto que la lista no tiene.
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
