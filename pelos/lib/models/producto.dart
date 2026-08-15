class Producto {
  final int? id;
  final String nombre;
  final String categoria; // tintes, champús, tratamientos, etc.
  final int cantidadStock;
  final int cantidadMinima;
  final double costoUnitario;
  final DateTime? fechaCompra;
  final String? proveedor;
  final DateTime? fechaCreacion;

  Producto({
    this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidadStock,
    required this.cantidadMinima,
    required this.costoUnitario,
    this.fechaCompra,
    this.proveedor,
    this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'cantidad_stock': cantidadStock,
      'cantidad_minima': cantidadMinima,
      'costo_unitario': costoUnitario,
      'fecha_compra': fechaCompra?.toIso8601String(),
      'proveedor': proveedor,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      categoria: map['categoria'] as String,
      cantidadStock: map['cantidad_stock'] as int,
      cantidadMinima: map['cantidad_minima'] as int,
      costoUnitario: (map['costo_unitario'] as num).toDouble(),
      fechaCompra: map['fecha_compra'] != null
          ? DateTime.parse(map['fecha_compra'] as String)
          : null,
      proveedor: map['proveedor'] as String?,
      fechaCreacion: map['fecha_creacion'] != null
          ? DateTime.parse(map['fecha_creacion'] as String)
          : null,
    );
  }

  bool get bajoStock => cantidadStock <= cantidadMinima;

  Producto copyWith({
    int? id,
    String? nombre,
    String? categoria,
    int? cantidadStock,
    int? cantidadMinima,
    double? costoUnitario,
    DateTime? fechaCompra,
    String? proveedor,
    DateTime? fechaCreacion,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      cantidadStock: cantidadStock ?? this.cantidadStock,
      cantidadMinima: cantidadMinima ?? this.cantidadMinima,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      proveedor: proveedor ?? this.proveedor,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  String toString() =>
      'Producto(id: $id, nombre: $nombre, stock: $cantidadStock, bajoStock: $bajoStock)';
}
