// Widget test de AsistenteScreen: renderiza, resuelve la carga y muestra la
// estructura (barra + estado vacío o tarjetas de sugerencia). No se afirma un
// contenido concreto porque las sugerencias dependen de la base compartida.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/config/business_config.dart';
import 'package:multiservicios_app/screens/asistente/asistente_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.instance.reset();
  });

  testWidgets('renderiza la barra y resuelve la carga', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: AsistenteScreen()));
      await bombearHasta(tester, find.text('Asistente de promociones'));

      expect(find.text('Asistente de promociones'), findsOneWidget); // AppBar
      // Deja que termine generarSugerencias y desaparezca el spinner.
      await bombearHasta(tester, find.byIcon(Icons.refresh));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
