// Smoke test para la app (motor multi-negocio).
//
// Verifica que, con un rubro ya elegido, la app arranca en la pantalla de
// inicio y muestra el contenido de bienvenida y la navegación inferior.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/config/business_config.dart';
import 'package:multiservicios_app/config/theme.dart';
import 'package:multiservicios_app/main.dart';

void main() {
  setUp(() {
    AppConfig.instance.setBusinessType(BusinessType.manicura);
    AppTheme.aplicarConfig(kBusinessConfigs[BusinessType.manicura]!);
  });

  testWidgets('La app arranca en la pantalla de inicio',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Deja que el gate de licencia resuelva su Future (prueba activa) y pase
    // a la pantalla de inicio, sin usar pumpAndSettle (hay animaciones vivas).
    final saludo = kBusinessConfigs[BusinessType.manicura]!.saludo;
    for (var i = 0;
        i < 10 && find.text(saludo).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // El saludo de bienvenida está presente.
    expect(find.text(saludo), findsOneWidget);

    // La sección de resumen del día está presente.
    expect(find.text('Resumen del Día'), findsOneWidget);

    // La barra de navegación inferior tiene las 5 secciones.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Clientes'), findsWidgets);
  });
}
