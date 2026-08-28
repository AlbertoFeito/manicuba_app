// Widget tests de ClienteDetailScreen: datos de contacto y notas, historial de
// citas (con y sin), la hoja de acciones de teléfono (copiar número) y los dos
// caminos de borrado (bloqueado por citas completadas, y confirmación).
//
// La pantalla lee citas de sqflite (FutureBuilder), así que se usa runAsync con
// bombeo manual.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/models/cita.dart';
import 'package:multiservicios_app/models/cliente.dart';
import 'package:multiservicios_app/models/servicio.dart';
import 'package:multiservicios_app/screens/clientes/cliente_detail_screen.dart';
import 'package:multiservicios_app/services/cita_service.dart';
import 'package:multiservicios_app/services/cliente_service.dart';
import 'package:multiservicios_app/services/servicio_service.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  final clienteService = ClienteService();
  final servicioService = ServicioService();
  final citaService = CitaService();

  Future<Cliente> crearCliente({String? notas}) async {
    final marca = DateTime.now().microsecondsSinceEpoch;
    final id = await clienteService.crearCliente(
      Cliente(nombre: 'Cli $marca', telefono: '+53 55501234', notas: notas),
    );
    return (await clienteService.obtenerPorId(id))!;
  }

  Future<void> crearCita(int clienteId, EstadoCita estado, String svc) async {
    final servicioId = await servicioService.crearServicio(
      Servicio(nombre: svc, precio: 30, duracionMinutos: 30),
    );
    await citaService.crearCita(
      Cita(
        clienteId: clienteId,
        servicioId: servicioId,
        fechaHora: DateTime(2099, 3, 3, 10, 0),
        duracionMinutos: 30,
        estado: estado,
        monto: 30,
      ),
    );
  }

  testWidgets('muestra contacto, notas e historial con la cita',
      (tester) async {
    await tester.runAsync(() async {
      final cliente = await crearCliente(notas: 'Prefiere tonos nude');
      final svc = 'Manicura ${DateTime.now().microsecondsSinceEpoch}';
      await crearCita(cliente.id!, EstadoCita.completada, svc);

      await tester.pumpWidget(
        MaterialApp(home: ClienteDetailScreen(cliente: cliente)),
      );
      await bombearHasta(tester, find.text(svc));

      expect(find.text(cliente.nombre), findsWidgets); // en el AppBar
      expect(find.text('+53 55501234'), findsOneWidget);
      expect(find.text('Prefiere tonos nude'), findsOneWidget);
      expect(find.text(svc), findsOneWidget); // tile del historial
    });
  });

  testWidgets('sin citas muestra el aviso de historial vacío', (tester) async {
    await tester.runAsync(() async {
      final cliente = await crearCliente();

      await tester.pumpWidget(
        MaterialApp(home: ClienteDetailScreen(cliente: cliente)),
      );
      await bombearHasta(tester, find.text('Aún no hay citas registradas'));

      expect(find.text('Aún no hay citas registradas'), findsOneWidget);
    });
  });

  testWidgets('la hoja de teléfono permite copiar el número', (tester) async {
    await tester.runAsync(() async {
      final cliente = await crearCliente();

      await tester.pumpWidget(
        MaterialApp(home: ClienteDetailScreen(cliente: cliente)),
      );
      await bombearHasta(tester, find.text('Aún no hay citas registradas'));

      // Toca el número para abrir la hoja de acciones.
      await tester.tap(find.text('+53 55501234'));
      await tester.pumpAndSettle();

      expect(find.text('Llamar'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Copiar número'), findsOneWidget);

      await tester.tap(find.text('Copiar número'));
      await bombearHasta(tester, find.text('Número copiado'));
      expect(find.text('Número copiado'), findsOneWidget);
    });
  });

  testWidgets('no deja borrar un cliente con citas completadas',
      (tester) async {
    await tester.runAsync(() async {
      final cliente = await crearCliente();
      await crearCita(
        cliente.id!,
        EstadoCita.completada,
        'Svc ${DateTime.now().microsecondsSinceEpoch}',
      );

      await tester.pumpWidget(
        MaterialApp(home: ClienteDetailScreen(cliente: cliente)),
      );
      await bombearHasta(tester, find.byTooltip('Eliminar'));

      await tester.tap(find.byTooltip('Eliminar'));
      await bombearHasta(tester, find.text('No se puede eliminar'));

      expect(find.text('No se puede eliminar'), findsOneWidget);
      expect(find.textContaining('historial contable'), findsOneWidget);
    });
  });

  testWidgets('borra un cliente sin citas completadas tras confirmar',
      (tester) async {
    await tester.runAsync(() async {
      final cliente = await crearCliente();
      await crearCita(
        cliente.id!,
        EstadoCita.pendiente,
        'Svc ${DateTime.now().microsecondsSinceEpoch}',
      );

      // Se monta en una ruta empujable para que el pop(true) final funcione.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ClienteDetailScreen(cliente: cliente),
                  ),
                ),
                child: const Text('ir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ir'));
      await bombearHasta(tester, find.byTooltip('Eliminar'));

      await tester.tap(find.byTooltip('Eliminar'));
      await bombearHasta(tester, find.text('Eliminar cliente'));
      // Asienta el diálogo antes de pulsar el botón de confirmar.
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));

      // Sondea la BD hasta que el borrado se complete (evita depender del pop).
      Cliente? aun = cliente;
      for (var i = 0; i < 40 && aun != null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        aun = await clienteService.obtenerPorId(cliente.id!);
      }
      expect(aun, isNull);
    });
  });
}
