class Gasto {
  final int? id;
  final String concepto;
  final double monto;
  final String categoria; // productos, servicios, alquiler, otros
  final DateTime fecha;
  final String? notas;

  /// Producto cuya compra generó este gasto. Si viene relleno, el gasto lo
  /// creó el Inventario y se corrige desde ahí, no desde Finanzas.
  final int? productoId;

  Gasto({
    this.id,
    required this.concepto,
    required this.monto,
    required this.categoria,
    required this.fecha,
    this.notas,
    this.productoId,
  });

  /// Los gastos automáticos no se editan a mano: cambiarlos sin tocar el
  /// stock descuadraría el inventario.
  bool get esAutomatico => productoId != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'concepto': concepto,
      'monto': monto,
      'categoria': categoria,
      'fecha': fecha.toIso8601String(),
      'notas': notas,
      'producto_id': productoId,
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
      productoId: map['producto_id'] as int?,
    );
  }

  Gasto copyWith({
    int? id,
    String? concepto,
    double? monto,
    String? categoria,
    DateTime? fecha,
    String? notas,
    int? productoId,
  }) {
    return Gasto(
      id: id ?? this.id,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
      productoId: productoId ?? this.productoId,
    );
  }

  @override
  String toString() =>
      'Gasto(id: $id, concepto: $concepto, monto: \$$monto, categoria: $categoria, fecha: $fecha)';
}
