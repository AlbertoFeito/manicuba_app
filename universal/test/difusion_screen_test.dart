// Widget test de DifusionScreen: renderiza el mensaje precargado, los chips
// de filtro y lista una clienta con teléfono.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/models/cliente.dart';
import 'package:multiservicios_app/screens/difusion/difusion_screen.dart';
import 'package:multiservicios_app/services/cliente_service.dart';
import 'package:multiservicios_app/services/difusion_service.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  testWidgets('muestra mensaje, filtros y una clienta con teléfono',
      (tester) async {
    await tester.runAsync(() async {
      final nombre = 'Dif ${DateTime.now().microsecondsSinceEpoch}';
      await ClienteService().crearCliente(
        Cliente(nombre: nombre, telefono: '5551234'),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DifusionScreen(
            mensaje: '¡Promo de prueba!',
            filtroInicial: FiltroClientas.todas,
          ),
        ),
      );
      // Espera a que resuelva la carga y aparezcan filas de clientas.
      await bombearHasta(tester, find.byType(ListTile));

      expect(find.text('Enviar a clientas'), findsOneWidget); // AppBar
      expect(find.text('¡Promo de prueba!'), findsOneWidget); // mensaje
      expect(find.text('Todas'), findsOneWidget); // chip
      expect(find.text('Frecuentes'), findsOneWidget);
      expect(find.text('Inactivas'), findsOneWidget);
      // Lista al menos una clienta (la creada arriba u otras con teléfono).
      expect(find.byType(ListTile), findsWidgets);
    });
  });
}
