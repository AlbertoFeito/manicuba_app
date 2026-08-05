class Ingreso {
  final int? id;
  final int? citaId;
  final double monto;
  final String metodo; // efectivo, transferencia, tarjeta
  final DateTime fecha;
  final String? notas;

  Ingreso({
    this.id,
    this.citaId,
    required this.monto,
    required this.metodo,
    required this.fecha,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cita_id': citaId,
      'monto': monto,
      'metodo_pago': metodo,
      'fecha': fecha.toIso8601String(),
      'notas': notas,
    };
  }

  factory Ingreso.fromMap(Map<String, dynamic> map) {
    return Ingreso(
      id: map['id'] as int?,
      citaId: map['cita_id'] as int?,
      monto: (map['monto'] as num).toDouble(),
      metodo: map['metodo_pago'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      notas: map['notas'] as String?,
    );
  }

  Ingreso copyWith({
    int? id,
    int? citaId,
    double? monto,
    String? metodo,
    DateTime? fecha,
    String? notas,
  }) {
    return Ingreso(
      id: id ?? this.id,
      citaId: citaId ?? this.citaId,
      monto: monto ?? this.monto,
      metodo: metodo ?? this.metodo,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
    );
  }

  @override
  String toString() => 'Ingreso(id: $id, monto: \$$monto, metodo: $metodo, fecha: $fecha)';
}
