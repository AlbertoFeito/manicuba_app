// Smoke test para la app ManiCuba.
//
// Verifica que la app arranca en la pantalla de inicio y muestra el
// contenido de bienvenida y la navegación inferior.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manicuba_app/main.dart';

void main() {
  testWidgets('La app arranca en la pantalla de inicio',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Deja que el gate de licencia resuelva su Future (prueba activa) y pase
    // a la pantalla de inicio, sin usar pumpAndSettle (hay animaciones vivas).
    for (var i = 0;
        i < 10 &&
            find.text('¡Bienvenida a ManiCuba! 💅').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // El saludo de bienvenida está presente.
    expect(find.text('¡Bienvenida a ManiCuba! 💅'), findsOneWidget);

    // La sección de resumen del día está presente.
    expect(find.text('Resumen del Día'), findsOneWidget);

    // La barra de navegación inferior tiene las 5 secciones.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Clientes'), findsWidgets);
  });
}
