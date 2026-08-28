import 'package:flutter/material.dart';

/// Rubros de negocio soportados por la app. Cada valor tiene su propia
/// [BusinessConfig] (colores, textos, catálogo sugerido) y su propia
/// licencia — ver [LicenciaService], que guarda el estado de prueba/pago
/// por separado para cada [BusinessType].
enum BusinessType { manicura, peluqueria, spa }

/// Un servicio de ejemplo con el que se siembra la tabla `servicios` la
/// primera vez que se crea la base de datos para un rubro.
class ServicioSemilla {
  const ServicioSemilla({
    required this.nombre,
    required this.precio,
    required this.duracionMinutos,
    required this.descripcion,
  });

  final String nombre;
  final double precio;
  final int duracionMinutos;
  final String descripcion;
}

/// Toda la configuración específica de un rubro de negocio: lo único que
/// cambia entre "Manicura", "Peluquería" y "Spa" dentro de la misma app.
/// El resto de la lógica (agenda, clientes, finanzas, inventario, backup,
/// licencia) es 100% compartido y no depende de este objeto.
class BusinessConfig {
  const BusinessConfig({
    required this.tipo,
    required this.label,
    required this.appName,
    required this.emoji,
    required this.iconoServicios,
    required this.primaryColor,
    required this.primaryLight,
    required this.primaryDark,
    required this.saludo,
    required this.subtitulo,
    required this.categoriasProductos,
    required this.emojisPopulares,
    required this.hashtagsComunes,
    required this.plantillasPost,
    required this.serviciosPorDefecto,
  });

  /// Identificador del rubro.
  final BusinessType tipo;

  /// Nombre corto para mostrar en el selector de rubro (p. ej. "Manicura").
  final String label;

  /// Nombre completo usado en saludos, mensajes de licencia y nombres de
  /// archivo de backup (p. ej. "Multiservicios Manicura").
  final String appName;

  final String emoji;
  final IconData iconoServicios;

  final Color primaryColor;
  final Color primaryLight;
  final Color primaryDark;

  final String saludo;
  final String subtitulo;

  final List<String> categoriasProductos;
  final List<String> emojisPopulares;
  final List<String> hashtagsComunes;

  /// Plantillas de post por tipo: 'oferta', 'promocion', 'trabajo',
  /// 'testimonio', 'educativo'.
  final Map<String, String> plantillasPost;

  final List<ServicioSemilla> serviciosPorDefecto;
}

const Map<BusinessType, BusinessConfig> kBusinessConfigs = {
  BusinessType.manicura: BusinessConfig(
    tipo: BusinessType.manicura,
    label: 'Manicura',
    appName: 'Multiservicios Manicura',
    emoji: '💅',
    iconoServicios: Icons.spa,
    primaryColor: Color(0xFFE91E63),
    primaryLight: Color(0xFFF48FB1),
    primaryDark: Color(0xFFC2185B),
    saludo: '¡Bienvenida a Multiservicios Manicura! 💅',
    subtitulo: 'Tu asistente personal para gestionar tu negocio de manicura',
    categoriasProductos: [
      'Esmaltes',
      'Geles',
      'Acrílicos',
      'Decoraciones',
      'Herramientas',
      'Limpiadores',
      'Otros',
    ],
    emojisPopulares: [
      '💅', '✨', '🌹', '💖', '🎀', '👑', '💄', '🌸', '🦋', '💫',
      '🔥', '😍', '🤩', '😊', '👌',
    ],
    hashtagsComunes: [
      '#manicura', '#uñas', '#nails', '#beauty', '#diseño',
      '#gelmanicure', '#acrylicnails', '#nailart', '#belleza', '#esmalte',
    ],
    plantillasPost: {
      'oferta': '🎉 ¡OFERTA ESPECIAL! 🎉\n\n✨ Manicura completa\n\n¡No te la pierdas! 💅\n\n📞 Reserva ya',
      'promocion': '💖 PROMOCIÓN DE HOY 💖\n\n🌹 Lleva 2 servicios\ny obtén 20% de descuento\n\n✨ ¡Válido solo hoy!',
      'trabajo': '✨ Nuestro trabajo del día ✨\n\n💅 Diseño único\n💖 Acabado perfecto\n\n¿Te gustaría? 📞',
      'testimonio': '💬 Lo que dicen nuestras clientas 💬\n\n"¡El mejor servicio!"\n⭐⭐⭐⭐⭐\n\n¡Visítanos! 💅',
      'educativo': '📚 CONSEJO DE BELLEZA 📚\n\n💡 Para que tus uñas duren más:\n• Hidratación diaria\n• Evitar químicos fuertes\n• Descansar cada mes',
    },
    serviciosPorDefecto: [
      ServicioSemilla(nombre: 'Manicura Básica', precio: 10.0, duracionMinutos: 30, descripcion: 'Corte, lima y esmalte básico'),
      ServicioSemilla(nombre: 'Manicura con Gel', precio: 20.0, duracionMinutos: 45, descripcion: 'Gel UV resistente y duradero'),
      ServicioSemilla(nombre: 'Acrílicas', precio: 25.0, duracionMinutos: 60, descripcion: 'Uñas acrílicas con acabado'),
      ServicioSemilla(nombre: 'Manicura Decorada', precio: 15.0, duracionMinutos: 40, descripcion: 'Con decoraciones y diseños'),
      ServicioSemilla(nombre: 'Esmaltado Francés', precio: 12.0, duracionMinutos: 35, descripcion: 'Clásico francés elegante'),
    ],
  ),

  BusinessType.peluqueria: BusinessConfig(
    tipo: BusinessType.peluqueria,
    label: 'Peluquería',
    appName: 'Multiservicios Peluquería',
    emoji: '💇',
    iconoServicios: Icons.content_cut,
    primaryColor: Color(0xFF6A1B9A),
    primaryLight: Color(0xFFBA68C8),
    primaryDark: Color(0xFF4A148C),
    saludo: '¡Bienvenida a Multiservicios Peluquería! 💇',
    subtitulo: 'Tu asistente personal para gestionar tu negocio de peluquería',
    categoriasProductos: [
      'Tintes',
      'Decolorantes',
      'Champús',
      'Acondicionadores',
      'Tratamientos',
      'Herramientas',
      'Otros',
    ],
    emojisPopulares: [
      '💇', '✂️', '💈', '🧴', '✨', '💖', '👑', '🌟', '💫', '🔥',
      '😍', '🤩', '😊', '👌', '💛',
    ],
    hashtagsComunes: [
      '#peluqueria', '#peluquería', '#peinado', '#corte', '#color',
      '#balayage', '#mechas', '#estilismo', '#hair', '#belleza',
    ],
    plantillasPost: {
      'oferta': '🎉 ¡OFERTA ESPECIAL! 🎉\n\n✂️ Corte + peinado\n\n¡No te la pierdas! 💇\n\n📞 Reserva ya',
      'promocion': '💖 PROMOCIÓN DE HOY 💖\n\n✨ Lleva 2 servicios\ny obtén 20% de descuento\n\n✨ ¡Válido solo hoy!',
      'trabajo': '✨ Nuestro trabajo del día ✨\n\n💇 Cambio de look\n💖 Acabado perfecto\n\n¿Te gustaría? 📞',
      'testimonio': '💬 Lo que dicen nuestras clientas 💬\n\n"¡El mejor servicio!"\n⭐⭐⭐⭐⭐\n\n¡Visítanos! 💇',
      'educativo': '📚 CONSEJO DE BELLEZA 📚\n\n💡 Para cuidar tu cabello:\n• Hidratación semanal\n• Protector térmico antes del calor\n• Corta las puntas cada 2-3 meses',
    },
    serviciosPorDefecto: [
      ServicioSemilla(nombre: 'Corte de pelo', precio: 10.0, duracionMinutos: 30, descripcion: 'Corte y acabado a tu estilo'),
      ServicioSemilla(nombre: 'Peinado', precio: 15.0, duracionMinutos: 45, descripcion: 'Peinado para eventos y ocasiones'),
      ServicioSemilla(nombre: 'Tinte / Color', precio: 25.0, duracionMinutos: 90, descripcion: 'Coloración completa del cabello'),
      ServicioSemilla(nombre: 'Mechas / Balayage', precio: 40.0, duracionMinutos: 150, descripcion: 'Mechas, balayage y matiz'),
      ServicioSemilla(nombre: 'Tratamiento / Hidratación', precio: 18.0, duracionMinutos: 45, descripcion: 'Hidratación y nutrición capilar'),
      ServicioSemilla(nombre: 'Alisado / Keratina', precio: 50.0, duracionMinutos: 180, descripcion: 'Alisado y tratamiento de keratina'),
    ],
  ),

  BusinessType.spa: BusinessConfig(
    tipo: BusinessType.spa,
    label: 'Spa / Estética',
    appName: 'Multiservicios Spa',
    emoji: '🧖',
    iconoServicios: Icons.self_improvement,
    primaryColor: Color(0xFF00897B),
    primaryLight: Color(0xFF4DB6AC),
    primaryDark: Color(0xFF00695C),
    saludo: '¡Bienvenida a Multiservicios Spa! 🧖',
    subtitulo: 'Tu asistente personal para gestionar tu spa o centro de estética',
    categoriasProductos: [
      'Aceites y esencias',
      'Cremas y mascarillas',
      'Cera',
      'Sábanas y toallas',
      'Aromaterapia',
      'Herramientas',
      'Otros',
    ],
    emojisPopulares: [
      '🧖', '🌿', '💆', '✨', '🕯️', '🌸', '💧', '😌', '🤍', '🌺',
      '🔥', '😍', '🤩', '😊', '👌',
    ],
    hashtagsComunes: [
      '#spa', '#estetica', '#bienestar', '#relax', '#masajes',
      '#skincare', '#facial', '#autocuidado', '#belleza', '#wellness',
    ],
    plantillasPost: {
      'oferta': '🎉 ¡OFERTA ESPECIAL! 🎉\n\n🧖 Masaje relajante + facial\n\n¡No te la pierdas! ✨\n\n📞 Reserva ya',
      'promocion': '💖 PROMOCIÓN DE HOY 💖\n\n🌿 Lleva 2 servicios\ny obtén 20% de descuento\n\n✨ ¡Válido solo hoy!',
      'trabajo': '✨ Nuestro trabajo del día ✨\n\n🧖 Sesión de bienestar\n💖 Resultados visibles\n\n¿Te gustaría? 📞',
      'testimonio': '💬 Lo que dicen nuestras clientas 💬\n\n"¡El mejor servicio!"\n⭐⭐⭐⭐⭐\n\n¡Visítanos! 🧖',
      'educativo': '📚 CONSEJO DE BIENESTAR 📚\n\n💡 Para relajarte mejor:\n• Hidratación antes y después\n• Respira profundo durante la sesión\n• Descansa el resto del día',
    },
    serviciosPorDefecto: [
      ServicioSemilla(nombre: 'Masaje Relajante', precio: 25.0, duracionMinutos: 60, descripcion: 'Masaje corporal para aliviar tensión'),
      ServicioSemilla(nombre: 'Limpieza Facial', precio: 20.0, duracionMinutos: 45, descripcion: 'Limpieza profunda con extracción'),
      ServicioSemilla(nombre: 'Exfoliación Corporal', precio: 18.0, duracionMinutos: 40, descripcion: 'Exfoliación con productos naturales'),
      ServicioSemilla(nombre: 'Depilación con Cera', precio: 15.0, duracionMinutos: 30, descripcion: 'Depilación de zonas a elección'),
      ServicioSemilla(nombre: 'Tratamiento Antiedad', precio: 35.0, duracionMinutos: 60, descripcion: 'Tratamiento facial con activos antiedad'),
    ],
  ),
};

/// Punto de acceso global a la configuración del rubro activo. Se carga una
/// vez en `main.dart` (desde la elección guardada en `SharedPreferences`)
/// antes de `runApp()`.
class AppConfig {
  AppConfig._();
  static final AppConfig instance = AppConfig._();

  static const String prefsKey = 'app_business_type';

  BusinessConfig _current = kBusinessConfigs[BusinessType.manicura]!;
  BusinessConfig get current => _current;

  bool _cargado = false;
  bool get cargado => _cargado;

  void setBusinessType(BusinessType tipo) {
    _current = kBusinessConfigs[tipo]!;
    _cargado = true;
  }
}
