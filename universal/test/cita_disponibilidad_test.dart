// Pruebas de detección de solapamiento de citas (CitaService.estaDisponible).
//
// La disponibilidad se calcula solo contra citas *confirmadas* del mismo día.
// Dos citas se solapan si el nuevo hueco empieza antes de que termine una
// confirmada y termina después de que esa confirmada empiece. Tocarse por el
// borde (una empieza justo cuando la otra acaba) NO es solapamiento.
//
// Se usan fechas del año 2099 para aislar estos casos de las citas que otros
// tests crean sobre la fecha de hoy en la base de datos compartida.

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/cita.dart';
import 'package:multiservicios_app/models/cliente.dart';
import 'package:multiservicios_app/models/servicio.dart';
import 'package:multiservicios_app/services/cita_service.dart';
import 'package:multiservicios_app/services/cliente_service.dart';
import 'package:multiservicios_app/services/servicio_service.dart';

void main() {
  final clienteService = ClienteService();
  final servicioService = ServicioService();
  final citaService = CitaService();

  late int clienteId;
  late int servicioId;

  setUp(() async {
    clienteId = await clienteService.crearCliente(
      Cliente(nombre: 'Disponibilidad Test', telefono: '55500000'),
    );
    servicioId = await servicioService.crearServicio(
      Servicio(nombre: 'Servicio Disp', precio: 20, duracionMinutos: 30),
    );
  });

  Future<int> crearConfirmada(DateTime inicio, int duracion) {
    return citaService.crearCita(
      Cita(
        clienteId: clienteId,
        servicioId: servicioId,
        fechaHora: inicio,
        duracionMinutos: duracion,
        estado: EstadoCita.confirmada,
        monto: 20,
      ),
    );
  }

  test('Un día sin citas confirmadas está siempre disponible', () async {
    // Día completamente vacío (año lejano, sin datos de otros tests).
    final hueco = DateTime(2099, 1, 5, 10, 0);
    expect(await citaService.estaDisponible(hueco, 30), isTrue);
  });

  test('Se solapa con una cita confirmada existente', () async {
    await crearConfirmada(DateTime(2099, 2, 10, 10, 0), 30); // 10:00–10:30

    // Empieza a las 10:15, dentro de la cita anterior -> no disponible.
    expect(
      await citaService.estaDisponible(DateTime(2099, 2, 10, 10, 15), 30),
      isFalse,
    );
    // Empieza antes y entra en el hueco (09:45–10:15) -> no disponible.
    expect(
      await citaService.estaDisponible(DateTime(2099, 2, 10, 9, 45), 30),
      isFalse,
    );
  });

  test('Citas pegadas por el borde no cuentan como solapamiento', () async {
    await crearConfirmada(DateTime(2099, 3, 15, 10, 0), 30); // 10:00–10:30

    // Justo después: empieza a las 10:30 cuando la anterior acaba.
    expect(
      await citaService.estaDisponible(DateTime(2099, 3, 15, 10, 30), 30),
      isTrue,
    );
    // Justo antes: 09:30–10:00, termina cuando la otra empieza.
    expect(
      await citaService.estaDisponible(DateTime(2099, 3, 15, 9, 30), 30),
      isTrue,
    );
  });

  test('Una cita pendiente no bloquea el hueco', () async {
    // Misma franja, pero la cita ocupante está solo pendiente (sin confirmar).
    await citaService.crearCita(
      Cita(
        clienteId: clienteId,
        servicioId: servicioId,
        fechaHora: DateTime(2099, 4, 20, 10, 0),
        duracionMinutos: 30,
        estado: EstadoCita.pendiente,
      ),
    );

    expect(
      await citaService.estaDisponible(DateTime(2099, 4, 20, 10, 15), 30),
      isTrue,
    );
  });

  test('El solapamiento respeta la duración de la cita nueva', () async {
    await crearConfirmada(DateTime(2099, 5, 25, 11, 0), 30); // 11:00–11:30

    // Cita corta que acaba antes de empezar la confirmada: 10:30–10:45 libre.
    expect(
      await citaService.estaDisponible(DateTime(2099, 5, 25, 10, 30), 15),
      isTrue,
    );
    // Cita larga desde las 10:45 (90 min) invade las 11:00 -> ocupado.
    expect(
      await citaService.estaDisponible(DateTime(2099, 5, 25, 10, 45), 90),
      isFalse,
    );
  });
}
