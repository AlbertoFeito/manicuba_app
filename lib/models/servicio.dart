class Servicio {
  final int? id;
  final String nombre;
  final double precio;
  final int duracionMinutos;
  final String? descripcion;

  Servicio({
    this.id,
    required this.nombre,
    required this.precio,
    required this.duracionMinutos,
    this.descripcion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'duracion_minutos': duracionMinutos,
      'descripcion': descripcion,
    };
  }

  factory Servicio.fromMap(Map<String, dynamic> map) {
    return Servicio(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      precio: (map['precio'] as num).toDouble(),
      duracionMinutos: map['duracion_minutos'] as int,
      descripcion: map['descripcion'] as String?,
    );
  }

  Servicio copyWith({
    int? id,
    String? nombre,
    double? precio,
    int? duracionMinutos,
    String? descripcion,
  }) {
    return Servicio(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  @override
  String toString() =>
      'Servicio(id: $id, nombre: $nombre, precio: \$$precio, duracion: ${duracionMinutos}min)';
}
