// La gráfica de tendencia fija el día que se toca, en vez de perder la
// marca al levantar el dedo.
//
// FinanzasScreen hace E/S real (sqflite), que el reloj de testWidgets no hace
// avanzar: todo va dentro de runAsync, como en finanzas_analiticas_test.dart.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pelucuba_app/models/ingreso.dart';
import 'package:pelucuba_app/screens/finanzas/finanzas_screen.dart';
import 'package:pelucuba_app/services/finanzas_service.dart';

Future<void> _asentar(WidgetTester tester, {int veces = 10}) async {
  for (var i = 0; i < veces; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('Tocar un punto de la tendencia lo deja fijado',
      (WidgetTester tester) async {
    final pista = find.textContaining('Toca un punto para fijarlo');
    final soltar = find.byTooltip('Soltar');

    await tester.runAsync(() async {
      await FinanzasService().registrarIngreso(
        Ingreso(monto: 80, metodo: 'Efectivo', fecha: DateTime.now()),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FinanzasScreen())),
      );
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
          break;
        }
      }

      await tester.tap(find.text('Analíticas'));
      await _asentar(tester);

      await tester.scrollUntilVisible(
        find.byType(LineChart),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await _asentar(tester);

      // Sin nada fijado se ve la pista y no hay nada que soltar.
      expect(pista, findsOneWidget);
      expect(soltar, findsNothing);

      // Un toque en la gráfica fija el día más cercano.
      await tester.tap(find.byType(LineChart));
      await _asentar(tester);
      expect(pista, findsNothing, reason: 'la pista se sustituye por el día');
      expect(soltar, findsOneWidget, reason: 'el día queda fijado');

      // Y sigue fijado tras más fotogramas: no se borra al soltar el dedo.
      await _asentar(tester, veces: 20);
      expect(soltar, findsOneWidget);

      // Tocar el mismo punto otra vez lo suelta.
      await tester.tap(find.byType(LineChart));
      await _asentar(tester);
      expect(soltar, findsNothing);
      expect(pista, findsOneWidget);
    });
  });
}
