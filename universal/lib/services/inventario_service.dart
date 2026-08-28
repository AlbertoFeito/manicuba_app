import '../config/constants.dart';
import '../database/database_helper.dart';
import '../models/gasto.dart';
import '../models/movimiento_inventario.dart';
import '../models/producto.dart';

/// Inventario de productos.
///
/// Modelo de costo: **el gasto ocurre cuando compras**, por el total pagado y
/// en la fecha de la compra. Descontar stock después no genera gasto —ese
/// dinero ya salió—; el stock solo dice cuánto queda. Por eso toda entrada
/// pagada crea un [Gasto] automático en Finanzas y toda salida no toca nada
/// de dinero.
class InventarioService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Marca de los gastos creados por el inventario, para distinguirlos de los
  /// que la usuaria escribe a mano.
  static const String notaAutomatica =
      'Generado automáticamente desde Inventario';

  /// Id provisional: la transacción lo reemplaza por el del producto recién
  /// insertado, que todavía no existe cuando se arma el movimiento.
  static const int _productoPendiente = 0;

  // ===== ALTA Y CONSULTA =====

  /// Da de alta un producto.
  ///
  /// Si viene con stock inicial, eso es una entrada. [registrarGasto] decide
  /// si además salió dinero ahora: en `true` crea el gasto en Finanzas; en
  /// `false` lo registra como stock que ya se tenía (no infla el mes con una
  /// compra vieja). Devuelve el id del producto.
  Future<int> crearProducto(
    Producto producto, {
    bool registrarGasto = true,
  }) async {
    final ahora = DateTime.now();
    final conFechas = producto.copyWith(
      fechaCreacion: producto.fechaCreacion ?? ahora,
    );

    // Sin stock inicial no hay movimiento que registrar: solo la ficha.
    if (conFechas.cantidadStock <= 0) {
      return await _db.insertProducto(conFechas.toMap());
    }

    final total = conFechas.cantidadStock * conFechas.costoUnitario;
    final esCompra = registrarGasto && total > 0;
    final fechaEntrada = conFechas.fechaCompra ?? ahora;

    return await _db.guardarMovimientoInventario(
      producto: conFechas.copyWith(fechaCompra: fechaEntrada).toMap(),
      gasto: esCompra
          ? _gastoDeCompra(
              nombre: conFechas.nombre,
              monto: total,
              fecha: fechaEntrada,
            ).toMap()
          : null,
      movimiento: MovimientoInventario(
        productoId: _productoPendiente,
        tipo: AppConstants.tipoMovimientoEntrada,
        cantidad: conFechas.cantidadStock,
        costoUnitario: conFechas.costoUnitario,
        motivo: esCompra
            ? AppConstants.motivoCompra
            : AppConstants.motivoSaldoInicial,
        fecha: fechaEntrada,
      ).toMap(),
    );
  }

  Future<List<Producto>> obtenerTodos() async {
    final mapList = await _db.getAllProductos();
    return mapList.map((map) => Producto.fromMap(map)).toList();
  }

  Future<Producto?> obtenerPorId(int id) async {
    final map = await _db.getProductoById(id);
    return map != null ? Producto.fromMap(map) : null;
  }

  /// Busca un producto con el mismo nombre y categoría, ignorando mayúsculas
  /// y espacios sobrantes.
  ///
  /// Dos fichas del mismo producto parten el stock en dos y ninguna refleja
  /// lo que hay de verdad, así que el formulario las rechaza. [exceptoId]
  /// deja fuera el propio producto al editarlo.
  Future<Producto?> buscarPorNombreYCategoria(
    String nombre,
    String categoria, {
    int? exceptoId,
  }) async {
    final buscadoNombre = nombre.trim().toLowerCase();
    final buscadaCategoria = categoria.trim().toLowerCase();
    final todos = await obtenerTodos();
    for (final producto in todos) {
      if (producto.id == exceptoId) {
        continue;
      }
      if (producto.nombre.trim().toLowerCase() == buscadoNombre &&
          producto.categoria.trim().toLowerCase() == buscadaCategoria) {
        return producto;
      }
    }
    return null;
  }

  Future<List<Producto>> obtenerPorCategoria(String categoria) async {
    final todos = await obtenerTodos();
    return todos.where((p) => p.categoria == categoria).toList();
  }

  Future<List<Producto>> obtenerBajoStock() async {
    final todos = await obtenerTodos();
    return todos.where((p) => p.bajoStock).toList();
  }

  /// Actualiza la ficha del producto (nombre, categoría, mínimo, proveedor).
  /// El stock y el costo unitario no se tocan por aquí: se mueven con
  /// [registrarCompra], [registrarSalida] y [registrarCorreccion], que dejan
  /// rastro. Cambiarlos a mano descuadraría el historial.
  Future<int> actualizar(Producto producto) async {
    return await _db.updateProducto(producto.toMap());
  }

  /// Elimina el producto y su historial. Los gastos se conservan —ese dinero
  /// salió de verdad— y quedan como gastos manuales en Finanzas.
  Future<int> eliminar(int id) async {
    await _db.desvincularGastosDeProducto(id);
    await _db.deleteMovimientosByProducto(id);
    return await _db.deleteProducto(id);
  }

  // ===== MOVIMIENTOS DE STOCK =====

  /// Registra una compra: sube el stock, recalcula el costo y crea el gasto
  /// en Finanzas. Es el único movimiento que mueve dinero.
  ///
  /// Devuelve el gasto creado, o `null` si no se pagó nada (entonces la
  /// entrada se guarda como stock que ya se tenía).
  Future<Gasto?> registrarCompra({
    required int productoId,
    required int cantidad,
    required double totalPagado,
    DateTime? fecha,
    String? proveedor,
    String? notas,
  }) async {
    if (cantidad <= 0) {
      return null;
    }
    final producto = await obtenerPorId(productoId);
    if (producto == null) {
      return null;
    }

    final momento = fecha ?? DateTime.now();
    final nuevoStock = producto.cantidadStock + cantidad;

    // Costo promedio ponderado: mezcla lo que ya había con lo que entra, para
    // que comprar más caro esta vez no reescriba el valor del stock viejo.
    final valorPrevio = producto.cantidadStock * producto.costoUnitario;
    final nuevoCosto = (valorPrevio + totalPagado) / nuevoStock;

    final esCompra = totalPagado > 0;
    final proveedorLimpio = proveedor?.trim();

    final gasto = esCompra
        ? _gastoDeCompra(
            nombre: producto.nombre,
            monto: totalPagado,
            fecha: momento,
          )
        : null;

    await _db.guardarMovimientoInventario(
      producto: producto
          .copyWith(
            cantidadStock: nuevoStock,
            costoUnitario: nuevoCosto,
            fechaCompra: momento,
            proveedor: (proveedorLimpio != null && proveedorLimpio.isNotEmpty)
                ? proveedorLimpio
                : producto.proveedor,
          )
          .toMap(),
      gasto: gasto?.toMap(),
      movimiento: MovimientoInventario(
        productoId: productoId,
        tipo: AppConstants.tipoMovimientoEntrada,
        cantidad: cantidad,
        costoUnitario: totalPagado / cantidad,
        motivo: esCompra
            ? AppConstants.motivoCompra
            : AppConstants.motivoSaldoInicial,
        fecha: momento,
        notas: notas,
      ).toMap(),
    );

    return gasto;
  }

  /// Descuenta stock por consumo, rotura o vencimiento.
  ///
  /// **No crea gasto**: el dinero salió cuando se compró el producto.
  /// Devuelve cuántas unidades se descontaron realmente (el stock nunca baja
  /// de cero, así que puede ser menos de lo pedido).
  Future<int> registrarSalida({
    required int productoId,
    required int cantidad,
    String motivo = AppConstants.motivoConsumo,
    String? notas,
  }) async {
    if (cantidad <= 0) {
      return 0;
    }
    final producto = await obtenerPorId(productoId);
    if (producto == null) {
      return 0;
    }

    final descontado = cantidad.clamp(0, producto.cantidadStock);
    if (descontado == 0) {
      return 0;
    }

    await _db.guardarMovimientoInventario(
      producto: producto
          .copyWith(cantidadStock: producto.cantidadStock - descontado)
          .toMap(),
      movimiento: MovimientoInventario(
        productoId: productoId,
        tipo: AppConstants.tipoMovimientoSalida,
        cantidad: descontado,
        motivo: motivo,
        fecha: DateTime.now(),
        notas: notas,
      ).toMap(),
    );

    return descontado;
  }

  /// Cuadra el stock con lo que hay de verdad después de un conteo físico, y
  /// de paso permite arreglar el costo unitario si se tecleó mal.
  ///
  /// No toca Finanzas: es una corrección de la cuenta, no dinero que se movió.
  /// Si el gasto también quedó mal, hay que deshacer la compra en el historial
  /// y volver a registrarla.
  ///
  /// Devuelve `true` si se aplicó algún cambio.
  Future<bool> registrarCorreccion({
    required int productoId,
    required int nuevoStock,
    double? nuevoCosto,
    String? notas,
  }) async {
    final producto = await obtenerPorId(productoId);
    if (producto == null) {
      return false;
    }

    final objetivo = nuevoStock < 0 ? 0 : nuevoStock;
    final diferencia = objetivo - producto.cantidadStock;

    final costo = (nuevoCosto != null && nuevoCosto >= 0)
        ? nuevoCosto
        : producto.costoUnitario;
    // Comparación con tolerancia: son céntimos, no enteros.
    final cambiaCosto = (costo - producto.costoUnitario).abs() > 0.001;

    if (diferencia == 0 && !cambiaCosto) {
      return false;
    }

    await _db.guardarMovimientoInventario(
      producto: producto
          .copyWith(cantidadStock: objetivo, costoUnitario: costo)
          .toMap(),
      movimiento: MovimientoInventario(
        productoId: productoId,
        tipo: AppConstants.tipoMovimientoAjuste,
        cantidad: diferencia.abs(),
        motivo: AppConstants.motivoCorreccion,
        fecha: DateTime.now(),
        notas: notas ?? _notaCorreccion(diferencia, cambiaCosto, costo),
      ).toMap(),
    );

    return true;
  }

  String _notaCorreccion(int diferencia, bool cambiaCosto, double costo) {
    final partes = <String>[
      if (diferencia > 0)
        'Había $diferencia de más'
      else if (diferencia < 0)
        'Faltaban ${-diferencia}',
      if (cambiaCosto) 'Costo corregido a ${costo.toStringAsFixed(2)}',
    ];
    return partes.join(' · ');
  }

  /// Resultado de intentar deshacer un movimiento.
  ///
  /// Deshacer una compra cuyas unidades ya se gastaron dejaría el stock en
  /// negativo, así que en ese caso no se toca nada y se avisa.
  static const String deshacerOk = 'ok';
  static const String deshacerNoExiste = 'no_existe';
  static const String deshacerNoSePuede = 'no_se_puede';
  static const String deshacerNoAplica = 'no_aplica';

  /// Deshace una compra o una salida: devuelve el stock a como estaba y, si
  /// era una compra, borra también su gasto de Finanzas. Es la forma de
  /// corregir un error de tecleo sin dejar un apunte falso.
  ///
  /// Las correcciones de conteo no se deshacen: se vuelven a corregir.
  Future<String> deshacerMovimiento(int movimientoId) async {
    final mapa = await _db.getMovimientoById(movimientoId);
    if (mapa == null) {
      return deshacerNoExiste;
    }
    final movimiento = MovimientoInventario.fromMap(mapa);
    if (!movimiento.esEntrada && !movimiento.esSalida) {
      return deshacerNoAplica;
    }

    final producto = await obtenerPorId(movimiento.productoId);
    if (producto == null) {
      return deshacerNoExiste;
    }

    final Producto revertido;
    if (movimiento.esEntrada) {
      final nuevoStock = producto.cantidadStock - movimiento.cantidad;
      if (nuevoStock < 0) {
        return deshacerNoSePuede;
      }
      // Se le quita al valor del inventario lo que costó este lote y se
      // reparte de nuevo entre lo que queda.
      final valorRestante = (producto.cantidadStock * producto.costoUnitario) -
          (movimiento.importe ?? 0);
      revertido = producto.copyWith(
        cantidadStock: nuevoStock,
        costoUnitario: nuevoStock > 0 && valorRestante > 0
            ? valorRestante / nuevoStock
            : producto.costoUnitario,
      );
    } else {
      revertido = producto.copyWith(
        cantidadStock: producto.cantidadStock + movimiento.cantidad,
      );
    }

    await _db.deshacerMovimientoInventario(
      producto: revertido.toMap(),
      movimientoId: movimientoId,
      gastoId: movimiento.gastoId,
    );
    return deshacerOk;
  }

  // ===== HISTORIAL =====

  Future<List<MovimientoInventario>> obtenerMovimientos() async {
    final mapList = await _db.getAllMovimientos();
    return mapList.map((map) => MovimientoInventario.fromMap(map)).toList();
  }

  Future<List<MovimientoInventario>> movimientosDe(int productoId) async {
    final mapList = await _db.getMovimientosByProducto(productoId);
    return mapList.map((map) => MovimientoInventario.fromMap(map)).toList();
  }

  /// Dinero gastado en compras de productos dentro del periodo.
  Future<double> compradoEnPeriodo(DateTime desde, DateTime hasta) async {
    final movimientos = await obtenerMovimientos();
    return movimientos
        .where((m) =>
            m.esEntrada && m.generoGasto && _enRango(m.fecha, desde, hasta))
        .fold<double>(0, (sum, m) => sum + (m.importe ?? 0));
  }

  /// Unidades descontadas del inventario dentro del periodo.
  Future<int> consumidoEnPeriodo(DateTime desde, DateTime hasta) async {
    final movimientos = await obtenerMovimientos();
    return movimientos
        .where((m) => m.esSalida && _enRango(m.fecha, desde, hasta))
        .fold<int>(0, (sum, m) => sum + m.cantidad);
  }

  /// Comprado en los últimos 30 días, la misma ventana que usa Finanzas para
  /// "mes", para que los dos números se puedan comparar.
  Future<double> compradoUltimoMes() async {
    final hoy = DateTime.now();
    return compradoEnPeriodo(hoy.subtract(const Duration(days: 30)), hoy);
  }

  bool _enRango(DateTime fecha, DateTime desde, DateTime hasta) {
    return !fecha.isBefore(desde) && !fecha.isAfter(hasta);
  }

  // ===== TOTALES =====

  /// Cuánto dinero tienes inmovilizado en producto: stock × costo unitario.
  Future<double> valorTotalInventario() async {
    final todos = await obtenerTodos();
    return todos.fold<double>(
        0, (sum, p) => sum + (p.cantidadStock * p.costoUnitario));
  }

  Future<int> cantidadTotalProductos() async {
    final todos = await obtenerTodos();
    return todos.fold<int>(0, (sum, p) => sum + p.cantidadStock);
  }

  Future<List<Producto>> ordenarPorStock() async {
    final todos = await obtenerTodos();
    todos.sort((a, b) => a.cantidadStock.compareTo(b.cantidadStock));
    return todos;
  }

  /// Productos ordenados por cuánto has descontado de ellos: lo que más se
  /// gasta, primero.
  Future<List<Producto>> obtenerMasUsados() async {
    final movimientos = await obtenerMovimientos();
    final consumo = <int, int>{};
    for (final m in movimientos.where((m) => m.esSalida)) {
      consumo.update(
        m.productoId,
        (valor) => valor + m.cantidad,
        ifAbsent: () => m.cantidad,
      );
    }
    final productos = await obtenerTodos();
    productos.sort(
      (a, b) => (consumo[b.id] ?? 0).compareTo(consumo[a.id] ?? 0),
    );
    return productos;
  }

  Future<Map<String, dynamic>> resumenPorCategoria() async {
    final todos = await obtenerTodos();
    final resumen = <String, dynamic>{};

    final categorias = todos.map((p) => p.categoria).toSet();

    for (var categoria in categorias) {
      final productosCat = todos.where((p) => p.categoria == categoria).toList();
      final cantidad =
          productosCat.fold<int>(0, (sum, p) => sum + p.cantidadStock);
      final costo = productosCat.fold<double>(
          0, (sum, p) => sum + (p.cantidadStock * p.costoUnitario));

      resumen[categoria] = {
        'cantidad': cantidad,
        'costo': costo,
        'productos': productosCat.length,
      };
    }

    return resumen;
  }

  Future<List<Producto>> alertasInventario() async {
    return await obtenerBajoStock();
  }

  Future<List<Map<String, dynamic>>> exportarTodos() async {
    final productos = await obtenerTodos();
    return productos.map((p) => p.toMap()).toList();
  }

  Future<Map<String, dynamic>> estadisticas() async {
    final todos = await obtenerTodos();
    final bajoStock = await obtenerBajoStock();

    return {
      'totalProductos': todos.length,
      'cantidadTotal': await cantidadTotalProductos(),
      'valorTotal': await valorTotalInventario(),
      'compradoUltimoMes': await compradoUltimoMes(),
      'productosBajoStock': bajoStock.length,
      'resumenCategoria': await resumenPorCategoria(),
    };
  }

  Gasto _gastoDeCompra({
    required String nombre,
    required double monto,
    required DateTime fecha,
  }) {
    return Gasto(
      concepto: 'Compra: $nombre',
      monto: monto,
      categoria: AppConstants.categoriaGastoProductos,
      fecha: fecha,
      notas: notaAutomatica,
    );
  }
}
