class Gasto {
  final int? id;
  final String concepto;
  final double monto;
  final String categoria; // productos, servicios, alquiler, otros
  final DateTime fecha;
  final String? notas;

  Gasto({
    this.id,
    required this.concepto,
    required this.monto,
    required this.categoria,
    required this.fecha,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'concepto': concepto,
      'monto': monto,
      'categoria': categoria,
      'fecha': fecha.toIso8601String(),
      'notas': notas,
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'] as int?,
      concepto: map['concepto'] as String,
      monto: (map['monto'] as num).toDouble(),
      categoria: map['categoria'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      notas: map['notas'] as String?,
    );
  }

  Gasto copyWith({
    int? id,
    String? concepto,
    double? monto,
    String? categoria,
    DateTime? fecha,
    String? notas,
  }) {
    return Gasto(
      id: id ?? this.id,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
    );
  }

  @override
  String toString() =>
      'Gasto(id: $id, concepto: $concepto, monto: \$$monto, categoria: $categoria, fecha: $fecha)';
}
