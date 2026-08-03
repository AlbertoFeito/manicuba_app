import '../config/constants.dart';
import '../database/database_helper.dart';
import '../models/cita.dart';
import '../models/ingreso.dart';
import 'cliente_service.dart';
import 'finanzas_service.dart';

class CitaService {
  final DatabaseHelper _db = DatabaseHelper();
  final FinanzasService _finanzas = FinanzasService();
  final ClienteService _clientes = ClienteService();

  // Crear cita
  Future<int> crearCita(Cita cita) async {
    final citaConFecha = cita.copyWith(
      fechaCreacion: cita.fechaCreacion ?? DateTime.now(),
    );
    final id = await _db.insertCita(citaConFecha.toMap());
    await sincronizarIngreso(citaConFecha.copyWith(id: id));
    return id;
  }

  /// Mantiene el ingreso en sincronía con el estado de la cita:
  /// - Si la cita queda *completada* y tiene monto, registra (o actualiza) un
  ///   ingreso enlazado a la cita.
  /// - Si la cita deja de estar completada, elimina el ingreso asociado.
  /// Es idempotente: no crea ingresos duplicados para la misma cita.
  Future<void> sincronizarIngreso(Cita cita) async {
    if (cita.id == null) {
      return;
    }
    final existentes = await _finanzas.obtenerIngresosPorCita(cita.id!);
    final debeTenerIngreso =
        cita.estado == EstadoCita.completada && (cita.monto ?? 0) > 0;

    // Al completar una cita, registra la visita en la ficha del cliente
    // (sirva de donde sirva la acción: formulario o agenda).
    if (cita.estado == EstadoCita.completada) {
      await _clientes.marcarUltimaVisita(cita.clienteId, cita.fechaHora);
    }

    if (!debeTenerIngreso) {
      if (existentes.isNotEmpty) {
        await _finanzas.eliminarIngresosPorCita(cita.id!);
      }
      return;
    }

    // Debe existir un ingreso que refleje el monto y la fecha actuales.
    final yaCorrecto = existentes.length == 1 &&
        existentes.first.monto == cita.monto &&
        existentes.first.fecha == cita.fechaHora;
    if (yaCorrecto) {
      return;
    }
    if (existentes.isNotEmpty) {
      await _finanzas.eliminarIngresosPorCita(cita.id!);
    }
    await _finanzas.registrarIngreso(
      Ingreso(
        citaId: cita.id,
        monto: cita.monto!,
        metodo: AppConstants.metodosPago.first,
        fecha: cita.fechaHora,
        notas: 'Generado automáticamente por cita completada',
      ),
    );
  }

  // Obtener todas las citas
  Future<List<Cita>> obtenerTodas() async {
    final mapList = await _db.getAllCitas();
    return mapList.map((map) => Cita.fromMap(map)).toList();
  }

  // Obtener citas por fecha
  Future<List<Cita>> obtenerPorFecha(DateTime fecha) async {
    final mapList = await _db.getCitasByFecha(fecha);
    return mapList.map((map) => Cita.fromMap(map)).toList();
  }

  // Obtener citas por cliente
  Future<List<Cita>> obtenerPorCliente(int clienteId) async {
    final mapList = await _db.getCitasByCliente(clienteId);
    return mapList.map((map) => Cita.fromMap(map)).toList();
  }

  // Obtener citas de hoy
  Future<List<Cita>> obtenerHoy() async {
    return await obtenerPorFecha(DateTime.now());
  }

  // Obtener citas de la semana
  Future<List<Cita>> obtenerSemana() async {
    final hoy = DateTime.now();
    final citas = await obtenerTodas();
    return citas
        .where((c) =>
            c.fechaHora.isAfter(hoy.subtract(const Duration(days: 1))) &&
            c.fechaHora.isBefore(hoy.add(const Duration(days: 8))))
        .toList();
  }

  // Actualizar cita
  Future<int> actualizar(Cita cita) async {
    final resultado = await _db.updateCita(cita.toMap());
    await sincronizarIngreso(cita);
    return resultado;
  }

  // Eliminar cita (elimina también el ingreso asociado, si lo hubiera)
  Future<int> eliminar(int id) async {
    await _finanzas.eliminarIngresosPorCita(id);
    return await _db.deleteCita(id);
  }

  // Eliminar todas las citas de un cliente (con sus ingresos). Se usa al
  // borrar un cliente que no tiene citas completadas.
  Future<void> eliminarPorCliente(int clienteId) async {
    final citas = await obtenerPorCliente(clienteId);
    for (final cita in citas) {
      if (cita.id != null) {
        await eliminar(cita.id!);
      }
    }
  }

  // Cambiar estado de cita
  Future<int> cambiarEstado(int id, EstadoCita nuevoEstado) async {
    final citas = await obtenerTodas();
    final cita = citas.firstWhere((c) => c.id == id);
    final citaActualizada = cita.copyWith(estado: nuevoEstado);
    return await actualizar(citaActualizada);
  }

  // Obtener citas pendientes
  Future<List<Cita>> obtenerPendientes() async {
    final citas = await obtenerTodas();
    return citas
        .where((c) => c.estado == EstadoCita.pendiente)
        .toList();
  }

  // Obtener citas confirmadas
  Future<List<Cita>> obtenerConfirmadas() async {
    final citas = await obtenerTodas();
    return citas
        .where((c) => c.estado == EstadoCita.confirmada)
        .toList();
  }

  // Obtener citas completadas
  Future<List<Cita>> obtenerCompletadas() async {
    final citas = await obtenerTodas();
    return citas
        .where((c) => c.estado == EstadoCita.completada)
        .toList();
  }

  // Obtener total de citas hoy
  Future<int> totalHoy() async {
    final hoy = await obtenerHoy();
    return hoy.length;
  }

  // Obtener total de ingresos hoy
  Future<double> ingresosHoy() async {
    final hoy = await obtenerHoy();
    return hoy
        .where((c) => c.estado == EstadoCita.completada)
        .fold<double>(0, (sum, c) => sum + (c.monto ?? 0));
  }

  // Verificar disponibilidad en horario
  Future<bool> estaDisponible(DateTime fechaHora, int duracionMinutos) async {
    final citasDelDia = await obtenerPorFecha(fechaHora);
    final citasConfirmadas = citasDelDia
        .where((c) => c.estado == EstadoCita.confirmada)
        .toList();

    for (var cita in citasConfirmadas) {
      final inicio = cita.fechaHora;
      final fin = inicio.add(Duration(minutes: cita.duracionMinutos));

      if (fechaHora.isBefore(fin) &&
          fechaHora.add(Duration(minutes: duracionMinutos)).isAfter(inicio)) {
        return false;
      }
    }
    return true;
  }

  // Exportar citas a mapas
  Future<List<Map<String, dynamic>>> exportarTodas() async {
    final citas = await obtenerTodas();
    return citas.map((c) => c.toMap()).toList();
  }
}
