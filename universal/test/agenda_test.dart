// Test de integración de la capa de citas usando la base de datos en memoria.

import 'package:flutter_test/flutter_test.dart';

import 'package:gestorpro_app/models/cita.dart';
import 'package:gestorpro_app/models/cliente.dart';
import 'package:gestorpro_app/models/servicio.dart';
import 'package:gestorpro_app/services/cita_service.dart';
import 'package:gestorpro_app/services/cliente_service.dart';
import 'package:gestorpro_app/services/servicio_service.dart';

void main() {
  test('Crear una cita la asocia al cliente y aparece por fecha', () async {
    final clienteService = ClienteService();
    final servicioService = ServicioService();
    final citaService = CitaService();

    final clienteId = await clienteService.crearCliente(
      Cliente(nombre: 'Cliente Test', telefono: '55512345'),
    );
    final servicioId = await servicioService.crearServicio(
      Servicio(nombre: 'Servicio Test', precio: 15, duracionMinutos: 30),
    );

    final fecha = DateTime.now();
    await citaService.crearCita(
      Cita(
        clienteId: clienteId,
        servicioId: servicioId,
        fechaHora: fecha,
        duracionMinutos: 30,
        estado: EstadoCita.confirmada,
        monto: 15,
      ),
    );

    final delCliente = await citaService.obtenerPorCliente(clienteId);
    expect(delCliente, isNotEmpty);
    expect(delCliente.first.nombreServicio, 'Servicio Test');

    final delDia = await citaService.obtenerPorFecha(fecha);
    expect(delDia.any((c) => c.clienteId == clienteId), isTrue);
  });
}
