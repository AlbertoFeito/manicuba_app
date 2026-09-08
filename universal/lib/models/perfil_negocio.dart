// Parte del Asistente de Promociones (ver docs/ASISTENTE_PROMOCIONES.md).
//
// Datos del negocio que se usan para autocompletar los posts de redes
// (nombre, teléfono, redes...). Se persisten con [PerfilService] en
// SharedPreferences, con una clave por rubro.

/// Ficha del negocio para las promociones. Todos los campos salvo el nombre
/// son opcionales: un perfil recién creado solo trae el nombre por defecto
/// del rubro y la usuaria va completando lo demás.
class PerfilNegocio {
  const PerfilNegocio({
    required this.nombreNegocio,
    this.telefono,
    this.direccion,
    this.horario,
    this.instagram,
    this.facebook,
    this.whatsapp,
  });

  final String nombreNegocio;
  final String? telefono;
  final String? direccion;
  final String? horario;

  /// Handle de Instagram, con o sin '@' (se normaliza al mostrar).
  final String? instagram;
  final String? facebook;

  /// Número de WhatsApp para contacto (puede diferir del teléfono principal).
  final String? whatsapp;

  /// Normaliza un handle de Instagram a la forma `@usuario` para mostrarlo en
  /// los posts. Devuelve `null` si no hay handle.
  String? get instagramMostrado {
    final h = instagram?.trim();
    if (h == null || h.isEmpty) {
      return null;
    }
    return h.startsWith('@') ? h : '@$h';
  }

  /// Pie de promoción: bloque de contacto que se añade al final de un post,
  /// con las líneas que el perfil tenga rellenas. Vacío si no hay ningún dato
  /// de contacto configurado.
  String pieDePromo() {
    final lineas = <String>[];
    if (telefono != null && telefono!.trim().isNotEmpty) {
      lineas.add('📞 ${telefono!.trim()}');
    }
    final ig = instagramMostrado;
    if (ig != null) {
      lineas.add('📸 $ig');
    }
    if (direccion != null && direccion!.trim().isNotEmpty) {
      lineas.add('📍 ${direccion!.trim()}');
    }
    return lineas.join('\n');
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreNegocio': nombreNegocio,
      'telefono': telefono,
      'direccion': direccion,
      'horario': horario,
      'instagram': instagram,
      'facebook': facebook,
      'whatsapp': whatsapp,
    };
  }

  factory PerfilNegocio.fromJson(Map<String, dynamic> json) {
    return PerfilNegocio(
      nombreNegocio: (json['nombreNegocio'] as String?) ?? '',
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      horario: json['horario'] as String?,
      instagram: json['instagram'] as String?,
      facebook: json['facebook'] as String?,
      whatsapp: json['whatsapp'] as String?,
    );
  }

  PerfilNegocio copyWith({
    String? nombreNegocio,
    String? telefono,
    String? direccion,
    String? horario,
    String? instagram,
    String? facebook,
    String? whatsapp,
  }) {
    return PerfilNegocio(
      nombreNegocio: nombreNegocio ?? this.nombreNegocio,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      horario: horario ?? this.horario,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }
}
