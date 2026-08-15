// Tests de widget para el formulario de clientes (validación).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pelucuba_app/screens/clientes/cliente_form_screen.dart';

void main() {
  testWidgets('El formulario valida nombre y teléfono requeridos',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ClienteFormScreen()),
    );

    // Intentar crear sin rellenar nada.
    await tester.tap(find.text('Crear cliente'));
    await tester.pumpAndSettle();

    // Deben aparecer mensajes de campo requerido (nombre y teléfono).
    expect(find.text('Este campo es requerido'), findsNWidgets(2));
  });

  testWidgets('El formulario rechaza un teléfono inválido',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ClienteFormScreen()),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Crear cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Teléfono inválido'), findsOneWidget);
  });
}
