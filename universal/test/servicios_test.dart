// Tests de widget para el formulario de servicios (validación).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/screens/servicios/servicio_form_screen.dart';

void main() {
  testWidgets('El formulario de servicio exige nombre, precio y duración',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ServicioFormScreen()),
    );

    await tester.tap(find.text('Crear servicio'));
    await tester.pumpAndSettle();

    // Nombre, precio y duración requeridos -> 3 mensajes.
    expect(find.text('Este campo es requerido'), findsNWidgets(3));
  });

  testWidgets('El formulario de servicio rechaza precio y duración inválidos',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ServicioFormScreen()),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Manicura');
    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    await tester.enterText(find.byType(TextFormField).at(2), '0');
    await tester.tap(find.text('Crear servicio'));
    await tester.pumpAndSettle();

    expect(find.text('Precio inválido'), findsOneWidget);
    expect(find.text('Duración inválida'), findsOneWidget);
  });
}
