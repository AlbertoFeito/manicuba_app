// Verifica que completar una cita genera el ingreso y que revertirla lo quita.

import 'package:flutter_test/flutter_test.dart';

import 'package:gestorpro_app/models/cita.dart';
import 'package:gestorpro_app/models/cliente.dart';
import 'package:gestorpro_app/models/servicio.dart';
import 'package:gestorpro_app/services/cita_service.dart';
import 'package:gestorpro_app/services/cliente_service.dart';
import 'package:gestorpro_app/services/finanzas_service.dart';
import 'package:gestorpro_app/services/servicio_service.dart';

void main() {
  final clienteService = ClienteService();
  final servicioService = ServicioService();
  final citaService = CitaService();
  final finanzasService = FinanzasService();

  test('Completar una cita registra el ingreso (sin duplicar)', () async {
    final clienteId = await clienteService.crearCliente(
      Cliente(nombre: 'Ingreso Test', telefono: '55599999'),
    );
    final servicioId = await servicioService.crearServicio(
      Servicio(nombre: 'Servicio Ingreso', precio: 25, duracionMinutos: 30),
    );

    // Cita creada como completada -> debe generar 1 ingreso.
    final citaId = await citaService.crearCita(
      Cita(
        clienteId: clienteId,
        servicioId: servicioId,
        fechaHora: DateTime.now(),
        duracionMinutos: 30,
        estado: EstadoCita.completada,
        monto: 25,
      ),
    );

    var ingresos = await finanzasService.obtenerIngresosPorCita(citaId);
    expect(ingresos.length, 1);
    expect(ingresos.first.monto, 25);

    // Re-guardar la misma cita completada no debe duplicar el ingreso.
    await citaService.actualizar(
      Cita(
        id: citaId,
        clienteId: clienteId,
        servicioId: servicioId,
        fechaHora: ingresos.first.fecha,
        duracionMinutos: 30,
        estado: EstadoCita.completada,
        monto: 25,
      ),
    );
    ingresos = await finanzasService.obtenerIngresosPorCita(citaId);
    expect(ingresos.length, 1);

    // Cambiar a pendiente elimina el ingreso asociado.
    await citaService.cambiarEstado(citaId, EstadoCita.pendiente);
    ingresos = await finanzasService.obtenerIngresosPorCita(citaId);
    expect(ingresos, isEmpty);
  });
}
