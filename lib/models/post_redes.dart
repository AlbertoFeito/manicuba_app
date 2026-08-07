class PostRedes {
  final int? id;
  final String titulo;
  final String contenido;
  final String? emojis;
  final String? hashtags;
  final String tipo; // oferta, promocion, trabajo, testimonio, educativo
  final String? fotoIds; // IDs de fotos separadas por coma
  final DateTime fechaCreacion;
  final DateTime? fechaProgramada;
  final bool publicado;
  final String plataforma; // instagram, facebook, whatsapp, todas
  final int visualizaciones;
  final String? notas;

  PostRedes({
    this.id,
    required this.titulo,
    required this.contenido,
    this.emojis,
    this.hashtags,
    required this.tipo,
    this.fotoIds,
    required this.fechaCreacion,
    this.fechaProgramada,
    this.publicado = false,
    required this.plataforma,
    this.visualizaciones = 0,
    this.notas,
  });

  // Obtener contenido formateado
  String getContenidoFormateado() {
    String formatted = contenido;
    if (emojis != null && emojis!.isNotEmpty) {
      formatted += '\n\n$emojis';
    }
    if (hashtags != null && hashtags!.isNotEmpty) {
      formatted += '\n\n$hashtags';
    }
    return formatted;
  }

  /// IDs de las fotos asociadas al post, en el orden guardado.
  List<int> get listaFotoIds {
    if (fotoIds == null || fotoIds!.trim().isEmpty) {
      return [];
    }
    return fotoIds!
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
  }

  /// Serializa [ids] para guardarlos en [fotoIds]. Devuelve `null` (no
  /// cadena vacía) cuando no hay fotos, para que el campo quede NULL.
  static String? fotoIdsDesdeLista(List<int> ids) {
    return ids.isEmpty ? null : ids.join(',');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
      'emojis': emojis,
      'hashtags': hashtags,
      'tipo': tipo,
      'foto_ids': fotoIds,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_programada': fechaProgramada?.toIso8601String(),
      'publicado': publicado ? 1 : 0,
      'plataforma': plataforma,
      'visualizaciones': visualizaciones,
      'notas': notas,
    };
  }

  factory PostRedes.fromMap(Map<String, dynamic> map) {
    return PostRedes(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      contenido: map['contenido'] as String,
      emojis: map['emojis'] as String?,
      hashtags: map['hashtags'] as String?,
      tipo: map['tipo'] as String,
      fotoIds: map['foto_ids'] as String?,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
      fechaProgramada: map['fecha_programada'] != null
          ? DateTime.parse(map['fecha_programada'] as String)
          : null,
      publicado: (map['publicado'] as int) == 1,
      plataforma: map['plataforma'] as String,
      visualizaciones: map['visualizaciones'] as int? ?? 0,
      notas: map['notas'] as String?,
    );
  }

  PostRedes copyWith({
    int? id,
    String? titulo,
    String? contenido,
    String? emojis,
    String? hashtags,
    String? tipo,
    String? fotoIds,
    DateTime? fechaCreacion,
    DateTime? fechaProgramada,
    bool? publicado,
    String? plataforma,
    int? visualizaciones,
    String? notas,
  }) {
    return PostRedes(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      emojis: emojis ?? this.emojis,
      hashtags: hashtags ?? this.hashtags,
      tipo: tipo ?? this.tipo,
      fotoIds: fotoIds ?? this.fotoIds,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      publicado: publicado ?? this.publicado,
      plataforma: plataforma ?? this.plataforma,
      visualizaciones: visualizaciones ?? this.visualizaciones,
      notas: notas ?? this.notas,
    );
  }

  @override
  String toString() =>
      'PostRedes(id: $id, titulo: $titulo, tipo: $tipo, publicado: $publicado)';
}
