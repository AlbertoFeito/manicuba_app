// Widget tests de los formularios de ingreso y gasto: validación, alta con
// éxito (comprobando que persiste) y modo edición.
//
// Los formularios hacen E/S real (sqflite), que el reloj de testWidgets no
// avanza, así que el guardado va dentro de runAsync con un bombeo manual
// (nada de pumpAndSettle: el botón anima un progreso indeterminado).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/models/gasto.dart';
import 'package:multiservicios_app/models/ingreso.dart';
import 'package:multiservicios_app/screens/finanzas/gasto_form_screen.dart';
import 'package:multiservicios_app/screens/finanzas/ingreso_form_screen.dart';
import 'package:multiservicios_app/services/finanzas_service.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 30 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  final finanzas = FinanzasService();

  group('GastoFormScreen', () {
    testWidgets('valida concepto y monto requeridos', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GastoFormScreen()));
      await tester.tap(find.text('Guardar gasto'));
      await tester.pumpAndSettle();

      // Concepto y monto vacíos -> dos "campo requerido".
      expect(find.text('Este campo es requerido'), findsNWidgets(2));
    });

    testWidgets('rechaza un monto inválido (cero)', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: GastoFormScreen()));
      await tester.enterText(find.byType(TextFormField).at(0), 'Esmaltes');
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.tap(find.text('Guardar gasto'));
      await tester.pumpAndSettle();

      expect(find.text('Monto inválido'), findsOneWidget);
    });

    testWidgets('guarda un gasto nuevo y lo persiste', (tester) async {
      final concepto = 'Gasto ${DateTime.now().microsecondsSinceEpoch}';
      var guardado = false;

      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: GastoFormScreen()));
        await tester.enterText(find.byType(TextFormField).at(0), concepto);
        await tester.enterText(find.byType(TextFormField).at(1), '42');
        await tester.pump();

        await tester.tap(find.text('Guardar gasto'));
        await bombearHasta(tester, find.text('Guardado exitosamente'));

        guardado = (await finanzas.obtenerGastos())
            .any((g) => g.concepto == concepto && g.monto == 42);
      });

      expect(guardado, isTrue);
      expect(find.text('Guardado exitosamente'), findsOneWidget);
    });

    testWidgets('en modo edición muestra los datos y el botón de cambios',
        (tester) async {
      final gasto = Gasto(
        id: 1,
        concepto: 'Alquiler',
        monto: 100,
        categoria: 'Otros',
        fecha: DateTime(2026, 1, 1),
      );
      await tester.pumpWidget(MaterialApp(home: GastoFormScreen(gasto: gasto)));

      expect(find.text('Editar gasto'), findsOneWidget);
      expect(find.text('Alquiler'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
    });
  });

  group('IngresoFormScreen', () {
    testWidgets('valida el monto requerido', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: IngresoFormScreen()));
      await tester.tap(find.text('Guardar ingreso'));
      await tester.pumpAndSettle();

      expect(find.text('Este campo es requerido'), findsOneWidget);
    });

    testWidgets('guarda un ingreso nuevo y lo persiste', (tester) async {
      final nota = 'Ingreso ${DateTime.now().microsecondsSinceEpoch}';
      var guardado = false;

      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: IngresoFormScreen()));
        await tester.enterText(find.byType(TextFormField).at(0), '77');
        // La segunda caja de texto son las notas.
        await tester.enterText(find.byType(TextFormField).at(1), nota);
        await tester.pump();

        await tester.tap(find.text('Guardar ingreso'));
        await bombearHasta(tester, find.text('Guardado exitosamente'));

        guardado = (await finanzas.obtenerIngresos())
            .any((i) => i.notas == nota && i.monto == 77);
      });

      expect(guardado, isTrue);
    });

    testWidgets('en modo edición muestra el título y el monto', (tester) async {
      final ingreso = Ingreso(
        id: 1,
        monto: 55,
        metodo: 'Efectivo',
        fecha: DateTime(2026, 1, 1),
      );
      await tester
          .pumpWidget(MaterialApp(home: IngresoFormScreen(ingreso: ingreso)));

      expect(find.text('Editar ingreso'), findsOneWidget);
      expect(find.text('55.00'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
    });
  });
}
