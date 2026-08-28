// Widget tests de los diálogos de stock (compra, salida y corrección).
// Son UI pura sin E/S: devuelven datos tipados por Navigator.pop, así que se
// abren desde un host mínimo y se comprueba el resultado capturado.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/models/producto.dart';
import 'package:multiservicios_app/screens/inventario/dialogos_stock.dart';

Producto producto({int stock = 10, double costo = 0, String? proveedor}) =>
    Producto(
      id: 1,
      nombre: 'Base coat',
      categoria: 'Esmaltes',
      cantidadStock: stock,
      cantidadMinima: 2,
      costoUnitario: costo,
      proveedor: proveedor,
    );

/// Monta un host con un botón que abre [abrir] y guarda su resultado.
Future<Object?> Function() _abridor(
  WidgetTester tester,
  Future<Object?> Function(BuildContext) abrir,
) {
  Object? capturado;
  return () async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => capturado = await abrir(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return capturado;
  };
}

void main() {
  group('Diálogo de compra', () {
    testWidgets('devuelve los datos de la compra al confirmar', (tester) async {
      Object? resultado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    resultado = await mostrarDialogoCompra(context, producto()),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '3'); // unidades
      await tester.enterText(find.byType(TextFormField).at(1), '150'); // total
      await tester.pump();

      // Precio unitario calculado a la vista (150 / 3 = 50).
      expect(find.textContaining('cada una'), findsOneWidget);

      await tester.tap(find.text('Registrar compra'));
      await tester.pumpAndSettle();

      expect(resultado, isA<DatosCompra>());
      final datos = resultado! as DatosCompra;
      expect(datos.cantidad, 3);
      expect(datos.totalPagado, 150);
    });

    testWidgets('sugiere el total según el costo cuando no se edita a mano',
        (tester) async {
      await _abridor(
        tester,
        (ctx) => mostrarDialogoCompra(ctx, producto(costo: 20)),
      )();

      // Al cambiar la cantidad, el total se autocompleta a 5 × 20 = 100.
      await tester.enterText(find.byType(TextFormField).at(0), '5');
      await tester.pump();

      expect(find.text('100.00'), findsOneWidget);
    });

    testWidgets('valida cantidad y no cierra con cero', (tester) async {
      await _abridor(
        tester,
        (ctx) => mostrarDialogoCompra(ctx, producto()),
      )();

      await tester.enterText(find.byType(TextFormField).at(0), '0');
      await tester.enterText(find.byType(TextFormField).at(1), '10');
      await tester.tap(find.text('Registrar compra'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe cuántas entraron'), findsOneWidget);
      // El diálogo sigue abierto.
      expect(find.text('Registrar compra'), findsOneWidget);
    });
  });

  group('Diálogo de salida', () {
    testWidgets('rechaza descontar más de lo que hay', (tester) async {
      await _abridor(
        tester,
        (ctx) => mostrarDialogoSalida(ctx, producto(stock: 4)),
      )();

      await tester.enterText(find.byType(TextFormField).at(0), '9');
      await tester.tap(find.text('Descontar'));
      await tester.pumpAndSettle();

      expect(find.text('Solo tienes 4'), findsOneWidget);
    });

    testWidgets('confirma una salida válida', (tester) async {
      Object? resultado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    resultado = await mostrarDialogoSalida(context, producto()),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '2');
      await tester.tap(find.text('Descontar'));
      await tester.pumpAndSettle();

      expect(resultado, isA<DatosSalida>());
      expect((resultado! as DatosSalida).cantidad, 2);
    });
  });

  group('Diálogo de corrección', () {
    testWidgets('viene relleno con el stock actual y confirma el nuevo',
        (tester) async {
      Object? resultado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => resultado =
                    await mostrarDialogoCorreccion(context, producto(stock: 7)),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Prellenado con el stock apuntado (el texto de ayuda lo confirma).
      expect(find.textContaining('apuntadas 7'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), '5');
      await tester.tap(find.text('Corregir'));
      await tester.pumpAndSettle();

      expect(resultado, isA<DatosCorreccion>());
      expect((resultado! as DatosCorreccion).stock, 5);
    });

    testWidgets('rechaza una cantidad negativa', (tester) async {
      await _abridor(
        tester,
        (ctx) => mostrarDialogoCorreccion(ctx, producto()),
      )();

      await tester.enterText(find.byType(TextFormField).at(0), '-3');
      await tester.tap(find.text('Corregir'));
      await tester.pumpAndSettle();

      expect(find.text('Cantidad inválida'), findsOneWidget);
    });
  });
}
