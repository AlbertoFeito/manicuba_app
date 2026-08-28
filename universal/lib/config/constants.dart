class AppConstants {
  // App Info
  static const String appVersion = '1.0.0';
  static const String appAuthor = 'Alberto Feito';

  // Duración de animaciones
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);

  // Configuración de base de datos (nombre de archivo real en
  // database_helper.dart; dbVersion vive aquí porque no depende del rubro).
  static const int dbVersion = 2;

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
  /// Categoría bajo la que el Inventario registra las compras de producto.
  static const String categoriaGastoProductos = 'Productos';

  static const List<String> categoriasGastos = [
    categoriaGastoProductos,
    'Servicios',
    'Alquiler',
    'Transporte',
    'Otros'
  ];

  // Categorías de productos: ver BusinessConfig.categoriasProductos
  // (config/business_config.dart) — dependen del rubro elegido.

  // Movimientos de inventario
  static const String tipoMovimientoEntrada = 'entrada';
  static const String tipoMovimientoSalida = 'salida';
  static const String tipoMovimientoAjuste = 'ajuste';

  /// Una compra es lo único que genera gasto: el dinero sale cuando compras,
  /// no cuando gastas el producto.
  static const String motivoCompra = 'compra';

  /// Stock que ya se tenía antes de registrarlo en la app. No genera gasto
  /// porque ese dinero salió antes de que la app llevara la cuenta.
  static const String motivoSaldoInicial = 'saldo_inicial';

  static const String motivoConsumo = 'consumo';
  static const String motivoRotura = 'rotura';
  static const String motivoVencido = 'vencido';
  static const String motivoCorreccion = 'correccion';

  /// Motivos que la usuaria elige al descontar stock.
  static const List<String> motivosSalida = [
    motivoConsumo,
    motivoRotura,
    motivoVencido,
  ];

  static const Map<String, String> etiquetasMotivo = {
    motivoCompra: 'Compra',
    motivoSaldoInicial: 'Stock inicial',
    motivoConsumo: 'Consumo',
    motivoRotura: 'Rotura o pérdida',
    motivoVencido: 'Vencido',
    motivoCorreccion: 'Corrección de conteo',
  };

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

  // Emojis populares, hashtags comunes y plantillas de post: ver
  // BusinessConfig (config/business_config.dart) — dependen del rubro
  // elegido.

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
