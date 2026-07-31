import '../database/database_helper.dart';
import '../models/cita.dart';

class CitaService {
  final DatabaseHelper _db = DatabaseHelper();

  // Crear cita
  Future<int> crearCita(Cita cita) async {
    final citaConFecha = cita.copyWith(
      fechaCreacion: cita.fechaCreacion ?? DateTime.now(),
    );
    return await _db.insertCita(citaConFecha.toMap());
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
    return await _db.updateCita(cita.toMap());
  }

  // Eliminar cita
  Future<int> eliminar(int id) async {
    return await _db.deleteCita(id);
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
