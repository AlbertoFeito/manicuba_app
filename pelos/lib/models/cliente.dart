class Cliente {
  final int? id;
  final String nombre;
  final String telefono;
  final String? email;
  final String? direccion;
  final String? notas;
  final DateTime? fechaCreacion;
  final DateTime? ultimaVisita;

  Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    this.direccion,
    this.notas,
    this.fechaCreacion,
    this.ultimaVisita,
  });

  // Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'notas': notas,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
      'ultima_visita': ultimaVisita?.toIso8601String(),
    };
  }

  // Crear desde Map (SQLite)
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String,
      email: map['email'] as String?,
      direccion: map['direccion'] as String?,
      notas: map['notas'] as String?,
      fechaCreacion: map['fecha_creacion'] != null
          ? DateTime.parse(map['fecha_creacion'] as String)
          : null,
      ultimaVisita: map['ultima_visita'] != null
          ? DateTime.parse(map['ultima_visita'] as String)
          : null,
    );
  }

  // Copiar con cambios
  Cliente copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? email,
    String? direccion,
    String? notas,
    DateTime? fechaCreacion,
    DateTime? ultimaVisita,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      notas: notas ?? this.notas,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      ultimaVisita: ultimaVisita ?? this.ultimaVisita,
    );
  }

  @override
  String toString() => 'Cliente(id: $id, nombre: $nombre, telefono: $telefono)';
}
