class AppConstants {
  // App Info
  static const String appName = 'ManiCuba';
  static const String appVersion = '1.0.0';
  static const String appAuthor = 'Alberto Feito';

  // Duración de animaciones
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);

  // Configuración de base de datos
  static const String dbName = 'manicuba.db';
  static const int dbVersion = 1;

  // Mensajes
  static const String msgErrorGeneral = 'Algo salió mal. Por favor intenta de nuevo.';
  static const String msgSucessoGuardar = 'Guardado exitosamente';
  static const String msgSucessoActualizar = 'Actualizado exitosamente';
  static const String msgSucessoEliminar = 'Eliminado exitosamente';
  static const String msgSucessoExportar = 'Exportado exitosamente';
  static const String msgConfirmarEliminar = '¿Estás seguro de que deseas eliminar?';

  // Validación
  static const String msgCampoRequerido = 'Este campo es requerido';
  static const String msgTelefonoInvalido = 'Teléfono inválido';
  static const String msgEmailInvalido = 'Email inválido';

  // Categorías de gastos
  static const List<String> categoriasGastos = [
    'Productos',
    'Servicios',
    'Alquiler',
    'Transporte',
    'Otros'
  ];

  // Categorías de productos
  static const List<String> categoriasProductos = [
    'Esmaltes',
    'Geles',
    'Acrílicos',
    'Decoraciones',
    'Herramientas',
    'Limpiadores',
    'Otros'
  ];

  // Métodos de pago
  static const List<String> metodosPago = [
    'Efectivo',
    'Transferencia',
    'Tarjeta',
  ];

  // Tipos de posts
  static const List<String> tiposPost = [
    'Oferta',
    'Promoción',
    'Trabajo',
    'Testimonio',
    'Educativo'
  ];

  // Plataformas sociales
  static const List<String> plataformasSociales = [
    'Instagram',
    'Facebook',
    'WhatsApp',
    'Todas'
  ];

  // Emojis populares para posts
  static const List<String> emojisPopulares = [
    '💅',
    '✨',
    '🌹',
    '💖',
    '🎀',
    '👑',
    '💄',
    '🌸',
    '🦋',
    '💫',
    '🔥',
    '😍',
    '🤩',
    '😊',
    '👌',
  ];

  // Hashtags comunes
  static const List<String> hashtagsComunes = [
    '#manicura',
    '#uñas',
    '#nails',
    '#beauty',
    '#diseño',
    '#gelmanicure',
    '#acrylicnails',
    '#nailart',
    '#belleza',
    '#esmalte'
  ];

  // Plantillas de posts
  static const Map<String, String> plantillasPost = {
    'oferta': '🎉 ¡OFERTA ESPECIAL! 🎉\n\n✨ Manicura completa\n\n¡No te la pierdas! 💅\n\n📞 Reserva ya',
    'promocion': '💖 PROMOCIÓN DE HOY 💖\n\n🌹 Lleva 2 servicios\ny obtén 20% de descuento\n\n✨ ¡Válido solo hoy!',
    'trabajo': '✨ Nuestro trabajo del día ✨\n\n💅 Diseño único\n💖 Acabado perfecto\n\n¿Te gustaría? 📞',
    'testimonio': '💬 Lo que dicen nuestras clientes 💬\n\n"¡El mejor servicio!"\n⭐⭐⭐⭐⭐\n\n¡Visítanos! 💅',
    'educativo': '📚 CONSEJO DE BELLEZA 📚\n\n💡 Para que tus uñas duren más:\n• Hidratación diaria\n• Evitar químicos fuertes\n• Descansar cada mes',
  };

  // Rangos de tiempo para reportes
  static const List<String> rangosTiempo = [
    'Hoy',
    'Esta semana',
    'Este mes',
    'Este año',
    'Personalizado'
  ];

  // Formatos
  static const String formatoFecha = 'dd/MM/yyyy';
  static const String formatoHora = 'HH:mm';
  static const String formatoFechaHora = 'dd/MM/yyyy HH:mm';
  static const String formatoMoneda = '\$#,##0.00';

  // Límites
  static const int maxLongitudNombre = 100;
  static const int maxLongitudTelefono = 20;
  static const int maxLongitudNotas = 500;
  static const int maxLongitudTitulo = 100;
  static const int maxLongitudContenido = 2200;
  static const int maxLongitudHashtags = 300;

  // Tamaños
  static const double paddingDefault = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;
  static const double radiusSmall = 8.0;
  static const double radiusDefault = 12.0;
  static const double radiusLarge = 16.0;

  // Valores por defecto
  static const int horaAbiertoDefault = 9;
  static const int horaCierreDefault = 18;
  static const int duracionCitaDefault = 30;
  static const double montoDefaultGasto = 0.0;
}
