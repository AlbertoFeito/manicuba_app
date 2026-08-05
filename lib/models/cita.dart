enum EstadoCita { pendiente, confirmada, completada, cancelada }

class Cita {
  final int? id;
  final int clienteId;
  final int servicioId;
  final DateTime fechaHora;
  final int duracionMinutos;
  final EstadoCita estado;
  final double? monto;
  final String? notas;
  final DateTime? fechaCreacion;

  // Referencias (para no necesitar JOIN)
  final String? nombreCliente;
  final String? nombreServicio;

  Cita({
    this.id,
    required this.clienteId,
    required this.servicioId,
    required this.fechaHora,
    required this.duracionMinutos,
    this.estado = EstadoCita.pendiente,
    this.monto,
    this.notas,
    this.fechaCreacion,
    this.nombreCliente,
    this.nombreServicio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'servicio_id': servicioId,
      'fecha_hora': fechaHora.toIso8601String(),
      'duracion_minutos': duracionMinutos,
      'estado': estado.toString().split('.').last,
      'monto': monto,
      'notas': notas,
      'fecha_creacion': fechaCreacion?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory Cita.fromMap(Map<String, dynamic> map) {
    return Cita(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      servicioId: map['servicio_id'] as int,
      fechaHora: DateTime.parse(map['fecha_hora'] as String),
      duracionMinutos: map['duracion_minutos'] as int,
      estado: _parseEstado(map['estado'] as String),
      monto: map['monto'] as double?,
      notas: map['notas'] as String?,
      fechaCreacion: map['fecha_creacion'] != null
          ? DateTime.parse(map['fecha_creacion'] as String)
          : null,
      nombreCliente: map['nombre_cliente'] as String?,
      nombreServicio: map['nombre_servicio'] as String?,
    );
  }

  static EstadoCita _parseEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return EstadoCita.confirmada;
      case 'completada':
        return EstadoCita.completada;
      case 'cancelada':
        return EstadoCita.cancelada;
      default:
        return EstadoCita.pendiente;
    }
  }

  Cita copyWith({
    int? id,
    int? clienteId,
    int? servicioId,
    DateTime? fechaHora,
    int? duracionMinutos,
    EstadoCita? estado,
    double? monto,
    String? notas,
    DateTime? fechaCreacion,
    String? nombreCliente,
    String? nombreServicio,
  }) {
    return Cita(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      servicioId: servicioId ?? this.servicioId,
      fechaHora: fechaHora ?? this.fechaHora,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      estado: estado ?? this.estado,
      monto: monto ?? this.monto,
      notas: notas ?? this.notas,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      nombreServicio: nombreServicio ?? this.nombreServicio,
    );
  }

  @override
  String toString() =>
      'Cita(id: $id, cliente: $nombreCliente, servicio: $nombreServicio, fecha: $fechaHora, estado: ${estado.toString().split('.').last})';
}
