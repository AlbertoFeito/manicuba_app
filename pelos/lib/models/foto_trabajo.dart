class FotoTrabajo {
  final int? id;
  final int? citaId;
  final String rutaFoto;
  final DateTime fecha;
  final String? descripcion;
  final bool compartida;

  FotoTrabajo({
    this.id,
    this.citaId,
    required this.rutaFoto,
    required this.fecha,
    this.descripcion,
    this.compartida = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cita_id': citaId,
      'ruta_foto': rutaFoto,
      'fecha': fecha.toIso8601String(),
      'descripcion': descripcion,
      'compartida': compartida ? 1 : 0,
    };
  }

  factory FotoTrabajo.fromMap(Map<String, dynamic> map) {
    return FotoTrabajo(
      id: map['id'] as int?,
      citaId: map['cita_id'] as int?,
      rutaFoto: map['ruta_foto'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      descripcion: map['descripcion'] as String?,
      compartida: (map['compartida'] as int? ?? 0) == 1,
    );
  }

  FotoTrabajo copyWith({
    int? id,
    int? citaId,
    String? rutaFoto,
    DateTime? fecha,
    String? descripcion,
    bool? compartida,
  }) {
    return FotoTrabajo(
      id: id ?? this.id,
      citaId: citaId ?? this.citaId,
      rutaFoto: rutaFoto ?? this.rutaFoto,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      compartida: compartida ?? this.compartida,
    );
  }
}
