import '../config/constants.dart';

/// Una entrada, salida o ajuste de stock de un producto.
///
/// Es el historial que permite responder "¿cuánto compré este mes?" y
/// "¿cuánto consumí?", que antes se perdía porque el stock era un número
/// que se sobreescribía.
class MovimientoInventario {
  final int? id;
  final int productoId;
  final String tipo; // entrada, salida, ajuste
  final int cantidad; // siempre positivo
  final double? costoUnitario; // solo entradas: a qué precio entró el lote
  final String motivo;
  final int? gastoId; // gasto que pagó esta entrada, si lo hubo
  final DateTime fecha;
  final String? notas;

  MovimientoInventario({
    this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    this.costoUnitario,
    required this.motivo,
    this.gastoId,
    required this.fecha,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'tipo': tipo,
      'cantidad': cantidad,
      'costo_unitario': costoUnitario,
      'motivo': motivo,
      'gasto_id': gastoId,
      'fecha': fecha.toIso8601String(),
      'notas': notas,
    };
  }

  factory MovimientoInventario.fromMap(Map<String, dynamic> map) {
    return MovimientoInventario(
      id: map['id'] as int?,
      productoId: map['producto_id'] as int,
      tipo: map['tipo'] as String,
      cantidad: map['cantidad'] as int,
      costoUnitario: map['costo_unitario'] != null
          ? (map['costo_unitario'] as num).toDouble()
          : null,
      motivo: map['motivo'] as String,
      gastoId: map['gasto_id'] as int?,
      fecha: DateTime.parse(map['fecha'] as String),
      notas: map['notas'] as String?,
    );
  }

  bool get esEntrada => tipo == AppConstants.tipoMovimientoEntrada;

  bool get esSalida => tipo == AppConstants.tipoMovimientoSalida;

  /// Solo las compras movieron dinero. El stock inicial no: ya estaba pagado.
  bool get generoGasto => gastoId != null;

  /// Lo que costó este lote. Nulo en salidas y ajustes, que no tienen precio.
  double? get importe =>
      costoUnitario != null ? costoUnitario! * cantidad : null;

  String get etiquetaMotivo =>
      AppConstants.etiquetasMotivo[motivo] ?? motivo;

  MovimientoInventario copyWith({
    int? id,
    int? productoId,
    String? tipo,
    int? cantidad,
    double? costoUnitario,
    String? motivo,
    int? gastoId,
    DateTime? fecha,
    String? notas,
  }) {
    return MovimientoInventario(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      motivo: motivo ?? this.motivo,
      gastoId: gastoId ?? this.gastoId,
      fecha: fecha ?? this.fecha,
      notas: notas ?? this.notas,
    );
  }

  @override
  String toString() =>
      'MovimientoInventario(id: $id, producto: $productoId, tipo: $tipo, '
      'cantidad: $cantidad, motivo: $motivo)';
}
