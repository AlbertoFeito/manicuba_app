// Tests de la capa de inventario y su conexión con las finanzas.
//
// Regla que se está verificando: el gasto ocurre cuando COMPRAS. Descontar
// stock después no genera gasto, porque ese dinero ya salió.

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/config/constants.dart';
import 'package:multiservicios_app/models/producto.dart';
import 'package:multiservicios_app/services/finanzas_service.dart';
import 'package:multiservicios_app/services/inventario_service.dart';

/// La base de datos de test se comparte entre archivos, así que cada test
/// crea su propio producto y mide sobre él, no sobre totales globales.
Future<int> _crearProducto(
  InventarioService inventario, {
  required String nombre,
  int stock = 0,
  double costo = 0,
  bool registrarGasto = true,
}) {
  return inventario.crearProducto(
    Producto(
      nombre: nombre,
      categoria: 'Esmaltes',
      cantidadStock: stock,
      cantidadMinima: 2,
      costoUnitario: costo,
    ),
    registrarGasto: registrarGasto,
  );
}

void main() {
  final inventario = InventarioService();
  final finanzas = FinanzasService();

  test('Registrar una compra crea el gasto en Finanzas', () async {
    final id = await _crearProducto(inventario, nombre: 'Base coat');

    final gasto = await inventario.registrarCompra(
      productoId: id,
      cantidad: 10,
      totalPagado: 500,
    );

    expect(gasto, isNotNull);
    expect(gasto!.monto, closeTo(500, 0.001));

    final producto = await inventario.obtenerPorId(id);
    expect(producto!.cantidadStock, 10);
    expect(producto.costoUnitario, closeTo(50, 0.001));

    final gastos = await finanzas.obtenerGastosPorProducto(id);
    expect(gastos.length, 1);
    expect(gastos.first.monto, closeTo(500, 0.001));
    expect(gastos.first.categoria, AppConstants.categoriaGastoProductos);
    expect(gastos.first.concepto, contains('Base coat'));
    expect(gastos.first.esAutomatico, isTrue);

    final movimientos = await inventario.movimientosDe(id);
    expect(movimientos.length, 1);
    expect(movimientos.first.motivo, AppConstants.motivoCompra);
    expect(movimientos.first.generoGasto, isTrue);
  });

  test('Comprar más caro promedia el costo, no reescribe el stock viejo',
      () async {
    final id = await _crearProducto(inventario, nombre: 'Top coat');

    await inventario.registrarCompra(
      productoId: id,
      cantidad: 10,
      totalPagado: 500, // $50 cada uno
    );
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 10,
      totalPagado: 800, // $80 cada uno
    );

    final producto = await inventario.obtenerPorId(id);
    expect(producto!.cantidadStock, 20);
    // (500 + 800) / 20 = 65, no 80.
    expect(producto.costoUnitario, closeTo(65, 0.001));

    // El valor del inventario coincide con lo que realmente se pagó.
    expect(
      producto.cantidadStock * producto.costoUnitario,
      closeTo(1300, 0.001),
    );
  });

  test('Descontar stock NO genera ningún gasto', () async {
    final id = await _crearProducto(inventario, nombre: 'Removedor');
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 10,
      totalPagado: 300,
    );

    final balanceAntes = await finanzas.balanceHoy();

    final descontado = await inventario.registrarSalida(
      productoId: id,
      cantidad: 4,
    );

    expect(descontado, 4);
    final producto = await inventario.obtenerPorId(id);
    expect(producto!.cantidadStock, 6);
    // El costo unitario no cambia al consumir: ya estaba pagado.
    expect(producto.costoUnitario, closeTo(30, 0.001));

    // Un solo gasto: el de la compra. La salida no añadió ninguno.
    final gastos = await finanzas.obtenerGastosPorProducto(id);
    expect(gastos.length, 1);
    expect(await finanzas.balanceHoy(), closeTo(balanceAntes, 0.001));
  });

  test('No se puede descontar más de lo que hay', () async {
    final id = await _crearProducto(inventario, nombre: 'Lima');
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 3,
      totalPagado: 60,
    );

    final descontado =
        await inventario.registrarSalida(productoId: id, cantidad: 10);

    expect(descontado, 3);
    final producto = await inventario.obtenerPorId(id);
    expect(producto!.cantidadStock, 0);
  });

  test('Producto que ya tenías: se registra sin crear gasto', () async {
    final id = await _crearProducto(
      inventario,
      nombre: 'Alicate viejo',
      stock: 5,
      costo: 100,
      registrarGasto: false,
    );

    final gastos = await finanzas.obtenerGastosPorProducto(id);
    expect(gastos, isEmpty);

    final movimientos = await inventario.movimientosDe(id);
    expect(movimientos.length, 1);
    expect(movimientos.first.motivo, AppConstants.motivoSaldoInicial);
    expect(movimientos.first.generoGasto, isFalse);

    final producto = await inventario.obtenerPorId(id);
    expect(producto!.cantidadStock, 5);
  });

  test('Producto nuevo comprado ahora: sí crea el gasto del stock inicial',
      () async {
    final id = await _crearProducto(
      inventario,
      nombre: 'Gel nuevo',
      stock: 4,
      costo: 25,
    );

    final gastos = await finanzas.obtenerGastosPorProducto(id);
    expect(gastos.length, 1);
    expect(gastos.first.monto, closeTo(100, 0.001)); // 4 × 25

    final movimientos = await inventario.movimientosDe(id);
    expect(movimientos.first.motivo, AppConstants.motivoCompra);
  });

  test('Corregir el stock no toca las finanzas', () async {
    final id = await _crearProducto(inventario, nombre: 'Algodón');
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 20,
      totalPagado: 200,
    );

    final balanceAntes = await finanzas.balanceHoy();
    final cambio =
        await inventario.registrarCorreccion(productoId: id, nuevoStock: 17);

    expect(cambio, isTrue);
    final producto = await inventario.obtenerPorId(id);
    expect(producto!.cantidadStock, 17);
    expect(await finanzas.balanceHoy(), closeTo(balanceAntes, 0.001));

    final gastos = await finanzas.obtenerGastosPorProducto(id);
    expect(gastos.length, 1); // sigue siendo solo el de la compra

    // Sin cambios reales no se registra nada.
    expect(
      await inventario.registrarCorreccion(productoId: id, nuevoStock: 17),
      isFalse,
    );
  });

  test('Corregir el costo unitario mal tecleado no toca las finanzas',
      () async {
    final id = await _crearProducto(inventario, nombre: 'Cinta');
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 5,
      totalPagado: 500, // se tecleó 500 en vez de 50: $100 c/u
    );

    final balanceAntes = await finanzas.balanceHoy();
    final cambio = await inventario.registrarCorreccion(
      productoId: id,
      nuevoStock: 5,
      nuevoCosto: 10,
    );

    expect(cambio, isTrue);
    final producto = await inventario.obtenerPorId(id);
    expect(producto!.costoUnitario, closeTo(10, 0.001));
    expect(producto.cantidadStock, 5);
    // El gasto queda como estaba: corregir el conteo no reescribe el dinero.
    expect(await finanzas.balanceHoy(), closeTo(balanceAntes, 0.001));
    expect((await finanzas.obtenerGastosPorProducto(id)).first.monto,
        closeTo(500, 0.001));
  });

  test('Deshacer una compra borra su gasto y devuelve el stock', () async {
    final id = await _crearProducto(inventario, nombre: 'Pinceles');
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 5,
      totalPagado: 250,
    );

    final movimientos = await inventario.movimientosDe(id);
    final resultado =
        await inventario.deshacerMovimiento(movimientos.first.id!);

    expect(resultado, InventarioService.deshacerOk);
    final producto = await inventario.obtenerPorId(id);
    expect(producto!.cantidadStock, 0);
    expect(await finanzas.obtenerGastosPorProducto(id), isEmpty);
    expect(await inventario.movimientosDe(id), isEmpty);
  });

  test('No se deshace una compra cuyas unidades ya se gastaron', () async {
    final id = await _crearProducto(inventario, nombre: 'Discos');
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 5,
      totalPagado: 100,
    );
    await inventario.registrarSalida(productoId: id, cantidad: 3);

    final compra = (await inventario.movimientosDe(id))
        .firstWhere((m) => m.motivo == AppConstants.motivoCompra);
    final resultado = await inventario.deshacerMovimiento(compra.id!);

    expect(resultado, InventarioService.deshacerNoSePuede);
    // Nada cambió: el stock y el gasto siguen donde estaban.
    final producto = await inventario.obtenerPorId(id);
    expect(producto!.cantidadStock, 2);
    expect((await finanzas.obtenerGastosPorProducto(id)).length, 1);
  });

  test('Comprado y consumido en el periodo suman lo esperado', () async {
    final desde = DateTime.now().subtract(const Duration(minutes: 1));
    final compradoAntes =
        await inventario.compradoEnPeriodo(desde, DateTime.now());
    final consumidoAntes =
        await inventario.consumidoEnPeriodo(desde, DateTime.now());

    final id = await _crearProducto(inventario, nombre: 'Glitter');
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 6,
      totalPagado: 180,
    );
    await inventario.registrarSalida(productoId: id, cantidad: 2);

    final hasta = DateTime.now();
    expect(
      await inventario.compradoEnPeriodo(desde, hasta) - compradoAntes,
      closeTo(180, 0.001),
    );
    expect(
      await inventario.consumidoEnPeriodo(desde, hasta) - consumidoAntes,
      2,
    );
  });

  test('Detecta productos repetidos por nombre y categoría', () async {
    // La base de test se comparte entre corridas: nombre único para que el
    // choque sea el que provoca este test y no uno anterior.
    final nombre = 'Baba ${DateTime.now().microsecondsSinceEpoch}';
    final id = await _crearProducto(inventario, nombre: nombre);

    // Mismo producto aunque cambien mayúsculas y sobren espacios.
    final encontrado = await inventario.buscarPorNombreYCategoria(
      '  ${nombre.toUpperCase()} ',
      'esmaltes',
    );
    expect(encontrado?.id, id);

    // Al editar, un producto no es duplicado de sí mismo.
    expect(
      await inventario.buscarPorNombreYCategoria(
        nombre,
        'Esmaltes',
        exceptoId: id,
      ),
      isNull,
    );

    // El mismo nombre en otra categoría sí se permite.
    expect(
      await inventario.buscarPorNombreYCategoria(nombre, 'Geles'),
      isNull,
    );
  });

  test('Eliminar un producto conserva sus gastos, ya sueltos', () async {
    final id = await _crearProducto(inventario, nombre: 'Esmalte a borrar');
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 2,
      totalPagado: 90,
    );

    final gastosTotalesAntes = (await finanzas.obtenerGastos()).length;

    await inventario.eliminar(id);

    expect(await inventario.obtenerPorId(id), isNull);
    expect(await inventario.movimientosDe(id), isEmpty);
    // El gasto sigue existiendo (el dinero salió de verdad), pero ya no
    // apunta al producto, así que vuelve a ser editable a mano.
    expect((await finanzas.obtenerGastos()).length, gastosTotalesAntes);
    expect(await finanzas.obtenerGastosPorProducto(id), isEmpty);
  });
}
