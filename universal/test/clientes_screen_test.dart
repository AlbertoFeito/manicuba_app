// Widget tests de ClientesScreen: render, filtro de búsqueda y navegación al
// formulario. El filtro es client-side, así que buscar un nombre único deja
// solo esa tarjeta (robusto pese a la BD compartida).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestorpro_app/models/cliente.dart';
import 'package:gestorpro_app/screens/clientes/clientes_screen.dart';
import 'package:gestorpro_app/services/cliente_service.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  final clienteService = ClienteService();

  testWidgets('renderiza la búsqueda, el FAB y la lista', (tester) async {
    await tester.runAsync(() async {
      await clienteService.crearCliente(
        Cliente(
          nombre: 'Cli ${DateTime.now().microsecondsSinceEpoch}',
          telefono: '55500000',
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: ClientesScreen()));
      await bombearHasta(tester, find.byType(Card));

      expect(find.widgetWithText(TextField, ''), findsWidgets); // buscador
      expect(find.text('Nuevo'), findsOneWidget); // FAB
      expect(find.byType(Card), findsWidgets);
    });
  });

  testWidgets('la búsqueda filtra por nombre', (tester) async {
    await tester.runAsync(() async {
      final nombre = 'Zoraida ${DateTime.now().microsecondsSinceEpoch}';
      await clienteService.crearCliente(
        Cliente(nombre: nombre, telefono: '55511111'),
      );

      await tester.pumpWidget(const MaterialApp(home: ClientesScreen()));
      await bombearHasta(tester, find.byType(Card));

      await tester.enterText(find.byType(TextField), nombre);
      await tester.pump();

      // Solo queda la tarjeta del cliente buscado (el nombre también está en
      // el propio buscador, por eso se acota a la Card).
      expect(find.byType(Card), findsOneWidget);
      expect(find.widgetWithText(Card, nombre), findsOneWidget);
    });
  });

  testWidgets('el FAB abre el formulario de cliente', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: ClientesScreen()));
      await bombearHasta(tester, find.text('Nuevo'));

      await tester.tap(find.text('Nuevo'));
      await bombearHasta(tester, find.byType(TextFormField));

      // El formulario tiene TextFormField; la lista solo un TextField.
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
