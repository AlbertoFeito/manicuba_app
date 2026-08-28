// Widget tests de InventarioScreen: render del inventario y navegación al
// formulario de nuevo producto.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestorpro_app/models/producto.dart';
import 'package:gestorpro_app/screens/inventario/inventario_screen.dart';
import 'package:gestorpro_app/services/inventario_service.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  final inventario = InventarioService();

  testWidgets('renderiza el inventario con barra, FAB y tarjetas',
      (tester) async {
    await tester.runAsync(() async {
      await inventario.crearProducto(
        Producto(
          nombre: 'Prod ${DateTime.now().microsecondsSinceEpoch}',
          categoria: 'Esmaltes',
          cantidadStock: 5,
          cantidadMinima: 1,
          costoUnitario: 10,
        ),
        registrarGasto: false,
      );

      await tester.pumpWidget(const MaterialApp(home: InventarioScreen()));
      await bombearHasta(tester, find.byType(Card));

      expect(find.text('Inventario'), findsOneWidget); // AppBar
      expect(find.text('Nuevo'), findsOneWidget); // FAB
      expect(find.byType(Card), findsWidgets);
    });
  });

  testWidgets('el FAB abre el formulario de producto', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: InventarioScreen()));
      await bombearHasta(tester, find.text('Nuevo'));

      await tester.tap(find.text('Nuevo'));
      await bombearHasta(tester, find.byType(TextFormField));

      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
