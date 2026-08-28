// Verifica que la vista "Analíticas" de Finanzas muestra los KPIs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/gasto.dart';
import 'package:multiservicios_app/models/ingreso.dart';
import 'package:multiservicios_app/screens/finanzas/finanzas_screen.dart';
import 'package:multiservicios_app/services/finanzas_service.dart';

void main() {
  testWidgets('La vista Analíticas muestra los KPIs y la comparación',
      (WidgetTester tester) async {
    // FinanzasScreen hace E/S real (sqflite) desde initState, y el registro
    // de datos de prueba también es E/S real. El binding de testWidgets
    // pumpea con un reloj simulado que no hace avanzar E/S real, así que
    // todo (registro de datos + pumpWidget + pumps) debe ir dentro de
    // runAsync para que se complete de verdad.
    await tester.runAsync(() async {
      final finanzas = FinanzasService();
      await finanzas.registrarIngreso(
        Ingreso(monto: 50, metodo: 'Efectivo', fecha: DateTime.now()),
      );
      await finanzas.registrarGasto(
        Gasto(
          concepto: 'Compra de esmaltes',
          monto: 10,
          categoria: 'Productos',
          fecha: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FinanzasScreen())),
      );

      // Espera a que desaparezca el indicador de carga inicial.
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
          break;
        }
      }

      // Por defecto arranca en "Resumen"; cambiar a "Analíticas".
      await tester.tap(find.text('Analíticas'));
      await tester.pump();
      // Deja que terminen las animaciones cortas de los gráficos.
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }

      // La tarjeta de comparación está más abajo en el ListView y puede no
      // estar montada todavía en el viewport de prueba; hay que desplazarse.
      await tester.scrollUntilVisible(
        find.text('Comparado con el periodo anterior'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    });

    expect(find.text('Ticket promedio'), findsOneWidget);
    expect(find.text('Transacciones'), findsOneWidget);
    expect(find.text('Margen'), findsOneWidget);
    expect(find.text('Comparado con el periodo anterior'), findsOneWidget);
  });
}
