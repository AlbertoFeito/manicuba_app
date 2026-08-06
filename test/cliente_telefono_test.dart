// Verifica que el teléfono de un cliente se guarda con el prefijo +53.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manicuba_app/models/cliente.dart';
import 'package:manicuba_app/screens/clientes/cliente_form_screen.dart';
import 'package:manicuba_app/services/cliente_service.dart';

/// Al guardar con éxito, el formulario muestra un SnackBar y hace
/// Navigator.pop(); como en este test se pumpea como ruta única (sin nada
/// debajo que "popear"), `pumpAndSettle()` nunca asienta del todo. Un número
/// acotado de `pump()` es suficiente para que termine el `await` del guardado.
Future<void> _pumpsAcotados(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('Un cliente nuevo se guarda con el prefijo +53',
      (WidgetTester tester) async {
    late List<Cliente> clientes;
    // Guardar dispara E/S real (sqflite) desde el formulario, y la lectura
    // final también. Todo debe ir dentro de runAsync (ver nota arriba).
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(home: ClienteFormScreen()),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
      await tester.enterText(find.byType(TextFormField).at(1), '55551234');
      await tester.tap(find.text('Crear cliente'));
      await _pumpsAcotados(tester);

      clientes = await ClienteService().obtenerTodos();
    });

    final creado = clientes.firstWhere((c) => c.nombre == 'Ana Pérez');
    expect(creado.telefono, '+53 55551234');
  });

  testWidgets('Al editar un cliente, el campo no repite el prefijo +53',
      (WidgetTester tester) async {
    late Cliente? actualizado;
    // crearCliente()/guardar/obtenerPorId son E/S real (sqflite); todo debe
    // ir dentro de runAsync (ver nota arriba).
    await tester.runAsync(() async {
      final id = await ClienteService().crearCliente(
        Cliente(nombre: 'Luis Gómez', telefono: '+53 55559999'),
      );
      final cliente = await ClienteService().obtenerPorId(id);

      await tester.pumpWidget(
        MaterialApp(home: ClienteFormScreen(cliente: cliente)),
      );
      await tester.pump();

      // El campo editable solo debe mostrar el número local, sin "+53".
      expect(find.text('55559999'), findsOneWidget);
      expect(find.text('+53 55559999'), findsNothing);

      // Guardar sin cambios no debe duplicar el prefijo.
      await tester.tap(find.text('Guardar cambios'));
      await _pumpsAcotados(tester);

      actualizado = await ClienteService().obtenerPorId(id);
    });

    expect(actualizado!.telefono, '+53 55559999');
  });
}
