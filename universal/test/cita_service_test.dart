// Pruebas de las consultas y agregados de CitaService que faltaban por cubrir:
// filtros por estado, ventana de la semana, totales de hoy y exportación.
//
// La base es compartida, así que se identifica cada cita por una marca única
// en el campo `notas`, y los totales de hoy se miden por diferencia.

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/cita.dart';
import 'package:multiservicios_app/models/cliente.dart';
import 'package:multiservicios_app/models/servicio.dart';
import 'package:multiservicios_app/services/cita_service.dart';
import 'package:multiservicios_app/services/cliente_service.dart';
import 'package:multiservicios_app/services/finanzas_service.dart';
import 'package:multiservicios_app/services/servicio_service.dart';

void main() {
  final clienteService = ClienteService();
  final servicioService = ServicioService();
  final citaService = CitaService();
  final finanzasService = FinanzasService();

  late int clienteId;
  late int servicioId;

  setUp(() async {
    clienteId = await clienteService.crearCliente(
      Cliente(nombre: 'Cita Svc Test', telefono: '55501111'),
    );
    servicioId = await servicioService.crearServicio(
      Servicio(nombre: 'Servicio Svc', precio: 20, duracionMinutos: 30),
    );
  });

  String marca(String p) => '$p-${DateTime.now().microsecondsSinceEpoch}';

  Future<int> crear({
    required EstadoCita estado,
    required String notas,
    DateTime? fecha,
    double? monto,
  }) {
    return citaService.crearCita(
      Cita(
        clienteId: clienteId,
        servicioId: servicioId,
        fechaHora: fecha ?? DateTime.now(),
        duracionMinutos: 30,
        estado: estado,
        monto: monto,
        notas: notas,
      ),
    );
  }

  test('Los filtros por estado devuelven solo las citas de ese estado',
      () async {
    final nPend = marca('pend');
    final nConf = marca('conf');
    final nComp = marca('comp');

    await crear(estado: EstadoCita.pendiente, notas: nPend);
    await crear(estado: EstadoCita.confirmada, notas: nConf);
    await crear(estado: EstadoCita.completada, notas: nComp, monto: 20);

    final pendientes =
        (await citaService.obtenerPendientes()).map((c) => c.notas).toSet();
    final confirmadas =
        (await citaService.obtenerConfirmadas()).map((c) => c.notas).toSet();
    final completadas =
        (await citaService.obtenerCompletadas()).map((c) => c.notas).toSet();

    expect(pendientes.contains(nPend), isTrue);
    expect(pendientes.contains(nConf), isFalse);

    expect(confirmadas.contains(nConf), isTrue);
    expect(confirmadas.contains(nComp), isFalse);

    expect(completadas.contains(nComp), isTrue);
    expect(completadas.contains(nPend), isFalse);
  });

  test('obtenerSemana incluye lo de esta semana y excluye lo lejano', () async {
    final enSemana = marca('semana');
    final lejana = marca('lejana');

    await crear(
      estado: EstadoCita.confirmada,
      notas: enSemana,
      fecha: DateTime.now().add(const Duration(days: 1)),
    );
    await crear(
      estado: EstadoCita.confirmada,
      notas: lejana,
      fecha: DateTime(2099, 6, 1),
    );

    final semana =
        (await citaService.obtenerSemana()).map((c) => c.notas).toSet();
    expect(semana.contains(enSemana), isTrue);
    expect(semana.contains(lejana), isFalse);
  });

  test('totalHoy e ingresosHoy miden las citas de hoy (delta)', () async {
    final totalBase = await citaService.totalHoy();
    final ingresosBase = await citaService.ingresosHoy();

    // Dos citas de hoy: una completada con monto, otra pendiente sin monto.
    await crear(estado: EstadoCita.completada, notas: marca('h'), monto: 30);
    await crear(estado: EstadoCita.pendiente, notas: marca('h'));

    expect(await citaService.totalHoy() - totalBase, 2);
    // Solo la completada aporta ingresos.
    expect(await citaService.ingresosHoy() - ingresosBase, closeTo(30, 0.001));
  });

  test('exportarTodas incluye la cita como mapa', () async {
    final nota = marca('exp');
    await crear(estado: EstadoCita.pendiente, notas: nota);

    final mapas = await citaService.exportarTodas();
    expect(mapas.any((m) => m['notas'] == nota), isTrue);
  });

  test('Cambiar el monto de una cita completada reescribe su ingreso',
      () async {
    // Cubre la rama de sincronizarIngreso que borra el ingreso previo y crea
    // uno nuevo cuando el monto ya no coincide.
    final citaId = await crear(
      estado: EstadoCita.completada,
      notas: marca('sync'),
      monto: 25,
    );

    var ingresos = await finanzasService.obtenerIngresosPorCita(citaId);
    expect(ingresos, hasLength(1));
    expect(ingresos.first.monto, closeTo(25, 0.001));

    // Se vuelve a guardar completada pero con otro monto.
    await citaService.actualizar(
      Cita(
        id: citaId,
        clienteId: clienteId,
        servicioId: servicioId,
        fechaHora: DateTime.now(),
        duracionMinutos: 30,
        estado: EstadoCita.completada,
        monto: 40,
      ),
    );

    ingresos = await finanzasService.obtenerIngresosPorCita(citaId);
    expect(ingresos, hasLength(1)); // sigue habiendo uno solo
    expect(ingresos.first.monto, closeTo(40, 0.001)); // con el monto nuevo
  });
}
