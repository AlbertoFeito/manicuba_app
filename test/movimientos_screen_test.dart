// Widget tests de MovimientosScreen: resumen, lista de movimientos, deshacer
// una salida y el estado vacío. La pantalla es de un solo producto, así que su
// lista es corta y controlable.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manicuba_app/models/producto.dart';
import 'package:manicuba_app/screens/inventario/movimientos_screen.dart';
import 'package:manicuba_app/services/inventario_service.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  final inventario = InventarioService();

  Future<Producto> crearProducto({String? nombre}) async {
    final id = await inventario.crearProducto(
      Producto(
        nombre: nombre ?? 'Prod ${DateTime.now().microsecondsSinceEpoch}',
        categoria: 'Esmaltes',
        cantidadStock: 0,
        cantidadMinima: 1,
        costoUnitario: 0,
      ),
      registrarGasto: false,
    );
    return (await inventario.obtenerPorId(id))!;
  }

  testWidgets('muestra el resumen y los movimientos del producto',
      (tester) async {
    await tester.runAsync(() async {
      final producto = await crearProducto();
      await inventario.registrarCompra(
        productoId: producto.id!,
        cantidad: 5,
        totalPagado: 100,
      );
      await inventario.registrarSalida(productoId: producto.id!, cantidad: 2);

      await tester.pumpWidget(
        MaterialApp(home: MovimientosScreen(producto: producto)),
      );
      await bombearHasta(tester, find.text('En stock'));

      // Tarjetas de resumen.
      expect(find.text('En stock'), findsOneWidget);
      expect(find.text('Comprado (30 días)'), findsOneWidget);
      expect(find.text('Usado (30 días)'), findsOneWidget);

      // Dos movimientos: una compra (+5) y una salida (−2).
      expect(find.textContaining('+5'), findsOneWidget);
      expect(find.textContaining('−2'), findsOneWidget);
    });
  });

  testWidgets('deshacer una salida la revierte', (tester) async {
    await tester.runAsync(() async {
      final producto = await crearProducto();
      await inventario.registrarCompra(
        productoId: producto.id!,
        cantidad: 10,
        totalPagado: 100,
      );
      await inventario.registrarSalida(productoId: producto.id!, cantidad: 3);
      // Stock ahora: 10 − 3 = 7.

      await tester.pumpWidget(
        MaterialApp(home: MovimientosScreen(producto: producto)),
      );
      await bombearHasta(tester, find.textContaining('−3'));

      // Toca la salida para deshacerla.
      await tester.tap(find.textContaining('−3'));
      await bombearHasta(tester, find.text('Deshacer movimiento'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(FilledButton, 'Deshacer'));
      await bombearHasta(tester, find.text('Movimiento deshecho'));

      expect(find.text('Movimiento deshecho'), findsOneWidget);
      // El stock volvió a 10.
      expect((await inventario.obtenerPorId(producto.id!))!.cantidadStock, 10);
    });
  });

  testWidgets('sin movimientos muestra el estado vacío', (tester) async {
    await tester.runAsync(() async {
      final producto = await crearProducto();

      await tester.pumpWidget(
        MaterialApp(home: MovimientosScreen(producto: producto)),
      );
      await bombearHasta(tester, find.text('Sin movimientos todavía'));

      expect(find.text('Sin movimientos todavía'), findsOneWidget);
    });
  });
}
