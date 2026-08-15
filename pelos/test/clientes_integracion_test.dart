// Integración del módulo Clientes: cascada al eliminar y última visita.

import 'package:flutter_test/flutter_test.dart';

import 'package:pelucuba_app/models/cita.dart';
import 'package:pelucuba_app/models/cliente.dart';
import 'package:pelucuba_app/models/servicio.dart';
import 'package:pelucuba_app/services/cita_service.dart';
import 'package:pelucuba_app/services/cliente_service.dart';
import 'package:pelucuba_app/services/servicio_service.dart';

void main() {
  final clienteService = ClienteService();
  final servicioService = ServicioService();
  final citaService = CitaService();

  test('Completar una cita fija la última visita del cliente', () async {
    final clienteId = await clienteService.crearCliente(
      Cliente(nombre: 'Visita Test', telefono: '55511111'),
    );
    final servicioId = await servicioService.crearServicio(
      Servicio(nombre: 'Serv Visita', precio: 10, duracionMinutos: 30),
    );
    final fecha = DateTime(2026, 5, 10, 12);

    // Completada desde el "flujo agenda" (crear ya completada).
    await citaService.crearCita(
      Cita(
        clienteId: clienteId,
        servicioId: servicioId,
        fechaHora: fecha,
        duracionMinutos: 30,
        estado: EstadoCita.completada,
        monto: 10,
      ),
    );

    final cliente = await clienteService.obtenerPorId(clienteId);
    expect(cliente!.ultimaVisita, fecha);
  });

  test('Eliminar cliente sin citas completadas borra sus citas', () async {
    final clienteId = await clienteService.crearCliente(
      Cliente(nombre: 'Cascada Test', telefono: '55522222'),
    );
    final servicioId = await servicioService.crearServicio(
      Servicio(nombre: 'Serv Cascada', precio: 10, duracionMinutos: 30),
    );
    await citaService.crearCita(
      Cita(
        clienteId: clienteId,
        servicioId: servicioId,
        fechaHora: DateTime.now(),
        duracionMinutos: 30,
        estado: EstadoCita.pendiente,
      ),
    );

    await citaService.eliminarPorCliente(clienteId);
    await clienteService.eliminar(clienteId);

    final citas = await citaService.obtenerPorCliente(clienteId);
    expect(citas, isEmpty);
    expect(await clienteService.obtenerPorId(clienteId), isNull);
  });
}
