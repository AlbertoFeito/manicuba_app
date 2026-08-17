// Widget tests de CitaFormScreen: validación de cliente/servicio, carga en
// modo edición y guardado de cambios.
//
// La pantalla carga clientes y servicios de sqflite en initState, así que todo
// va dentro de runAsync con bombeo manual. No se interactúa con los dropdowns
// de cliente/servicio (la BD compartida tiene listas largas y el ítem podría
// no estar visible); el modo edición ya trae ambos seleccionados desde la cita.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manicuba_app/models/cita.dart';
import 'package:manicuba_app/models/cliente.dart';
import 'package:manicuba_app/models/servicio.dart';
import 'package:manicuba_app/screens/agenda/cita_form_screen.dart';
import 'package:manicuba_app/services/cita_service.dart';
import 'package:manicuba_app/services/cliente_service.dart';
import 'package:manicuba_app/services/servicio_service.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

/// Agranda la superficie para que todo el formulario (dropdowns, campos y el
/// botón al final del ListView) quepa sin scroll y sea pulsable.
void agrandarSuperficie(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  final clienteService = ClienteService();
  final servicioService = ServicioService();
  final citaService = CitaService();

  Future<(int, Servicio)> crearClienteYServicio() async {
    final marca = DateTime.now().microsecondsSinceEpoch;
    final clienteId = await clienteService.crearCliente(
      Cliente(nombre: 'Cliente $marca', telefono: '55500000'),
    );
    final servicioId = await servicioService.crearServicio(
      Servicio(nombre: 'Servicio $marca', precio: 35, duracionMinutos: 45),
    );
    final servicio = (await servicioService.obtenerTodos())
        .firstWhere((s) => s.id == servicioId);
    return (clienteId, servicio);
  }

  testWidgets('valida que falta cliente y servicio al crear', (tester) async {
    await tester.runAsync(() async {
      agrandarSuperficie(tester);
      // Necesita al menos un cliente y un servicio para no caer en "faltan
      // datos"; la BD compartida ya los tiene, pero garantizamos uno.
      await crearClienteYServicio();

      await tester.pumpWidget(const MaterialApp(home: CitaFormScreen()));
      await bombearHasta(tester, find.text('Crear cita'));

      await tester.tap(find.text('Crear cita'));
      await tester.pump();

      // Los validadores de los dos dropdowns requeridos.
      expect(find.text('Este campo es requerido'), findsNWidgets(2));
    });
  });

  testWidgets('en modo edición carga la cita y muestra sus datos',
      (tester) async {
    await tester.runAsync(() async {
      agrandarSuperficie(tester);
      final (clienteId, servicio) = await crearClienteYServicio();
      final cita = Cita(
        id: await citaService.crearCita(
          Cita(
            clienteId: clienteId,
            servicioId: servicio.id!,
            fechaHora: DateTime(2099, 5, 5, 10, 0),
            duracionMinutos: servicio.duracionMinutos,
            estado: EstadoCita.confirmada,
            monto: 35,
          ),
        ),
        clienteId: clienteId,
        servicioId: servicio.id!,
        fechaHora: DateTime(2099, 5, 5, 10, 0),
        duracionMinutos: servicio.duracionMinutos,
        estado: EstadoCita.confirmada,
        monto: 35,
      );

      await tester.pumpWidget(MaterialApp(home: CitaFormScreen(cita: cita)));
      await bombearHasta(tester, find.text('Guardar cambios'));

      expect(find.text('Editar cita'), findsOneWidget);
      expect(find.text('35.00'), findsOneWidget); // monto prellenado
      expect(find.text('Guardar cambios'), findsOneWidget);
    });
  });

  testWidgets('guardar cambios en edición persiste la cita', (tester) async {
    await tester.runAsync(() async {
      agrandarSuperficie(tester);
      final (clienteId, servicio) = await crearClienteYServicio();
      final citaId = await citaService.crearCita(
        Cita(
          clienteId: clienteId,
          servicioId: servicio.id!,
          fechaHora: DateTime(2099, 6, 6, 12, 0),
          duracionMinutos: servicio.duracionMinutos,
          estado: EstadoCita.confirmada,
          monto: 35,
        ),
      );
      final cita = Cita(
        id: citaId,
        clienteId: clienteId,
        servicioId: servicio.id!,
        fechaHora: DateTime(2099, 6, 6, 12, 0),
        duracionMinutos: servicio.duracionMinutos,
        estado: EstadoCita.confirmada,
        monto: 35,
      );

      await tester.pumpWidget(MaterialApp(home: CitaFormScreen(cita: cita)));
      await bombearHasta(tester, find.text('Guardar cambios'));

      // Cambia el monto y guarda.
      await tester.enterText(find.byType(TextFormField).at(0), '99');
      await tester.tap(find.text('Guardar cambios'));
      await bombearHasta(tester, find.text('Actualizado exitosamente'));

      final actualizada = (await citaService.obtenerTodas())
          .firstWhere((c) => c.id == citaId);
      expect(actualizada.monto, 99);
    });
  });
}
