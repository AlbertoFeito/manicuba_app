// Widget test de PerfilScreen: renderiza el formulario, valida el nombre
// obligatorio y guarda los datos en PerfilService.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/config/business_config.dart';
import 'package:multiservicios_app/screens/perfil/perfil_screen.dart';
import 'package:multiservicios_app/services/perfil_service.dart';
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

  testWidgets('renderiza el formulario con el nombre por defecto del rubro',
      (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: PerfilScreen()));
      await bombearHasta(tester, find.byType(TextFormField));

      expect(find.text('Perfil del negocio'), findsOneWidget); // AppBar
      expect(find.byType(TextFormField), findsWidgets);
      // El campo de nombre viene precargado con el appName del rubro activo.
      expect(
        find.text(kBusinessConfigs[BusinessType.manicura]!.appName),
        findsOneWidget,
      );
    });
  });

  testWidgets('guardar persiste el perfil', (tester) async {
    // Superficie alta para que todos los campos y el botón entren sin scroll
    // (el ListView no construye los hijos que quedan bajo el fold).
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: PerfilScreen()));
      await bombearHasta(tester, find.byType(TextFormField));

      // Escribe un teléfono y guarda.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teléfono'),
        '5559999',
      );
      final botonGuardar = find.text('Guardar');
      await tester.ensureVisible(botonGuardar);
      await tester.pump();
      await tester.tap(botonGuardar);
      await tester.pump(const Duration(milliseconds: 200));

      final perfil = await PerfilService.instance.obtener();
      expect(perfil.telefono, '5559999');
    });
  });
}
