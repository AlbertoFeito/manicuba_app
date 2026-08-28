// Test de widget del formulario de productos.
//
// Comprueba el rechazo de duplicados: dos fichas del mismo producto parten el
// stock en dos y ninguna refleja lo que hay de verdad.
//
// El formulario hace E/S real (sqflite) y el reloj de testWidgets no la hace
// avanzar, así que todo va dentro de runAsync, igual que en
// finanzas_analiticas_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/producto.dart';
import 'package:multiservicios_app/screens/inventario/producto_form_screen.dart';
import 'package:multiservicios_app/services/inventario_service.dart';

/// Bombea hasta que [buscado] aparezca, sin usar `pumpAndSettle`: mientras
/// guarda, el botón muestra un indicador de progreso indeterminado que nunca
/// deja de animar y `pumpAndSettle` no terminaría jamás.
Future<void> _bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 30 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  testWidgets('No deja crear un producto repetido en la misma categoría',
      (WidgetTester tester) async {
    // La base de test se comparte entre corridas: nombre único para que el
    // choque sea el que provoca este test y no uno anterior.
    final nombre = 'Baba ${DateTime.now().microsecondsSinceEpoch}';
    var fichas = 0;

    await tester.runAsync(() async {
      final inventario = InventarioService();
      await inventario.crearProducto(
        Producto(
          nombre: nombre,
          categoria: 'Esmaltes',
          cantidadStock: 0,
          cantidadMinima: 1,
          costoUnitario: 0,
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: ProductoFormScreen()));
      await _bombearHasta(tester, find.text('Crear producto'));

      await tester.enterText(find.byType(TextFormField).at(0), nombre);
      await tester.enterText(find.byType(TextFormField).at(1), '0'); // stock
      await tester.enterText(find.byType(TextFormField).at(2), '1'); // mínimo
      await tester.enterText(find.byType(TextFormField).at(3), '0'); // costo
      await tester.pump();

      await tester.tap(find.text('Crear producto'));
      await _bombearHasta(tester, find.textContaining('Ya tienes'));

      fichas = (await inventario.obtenerTodos())
          .where((p) => p.nombre == nombre && p.categoria == 'Esmaltes')
          .length;
    });

    expect(find.textContaining('Ya tienes "$nombre"'), findsOneWidget);
    expect(fichas, 1, reason: 'no debe haberse creado una segunda ficha');
  });
}
