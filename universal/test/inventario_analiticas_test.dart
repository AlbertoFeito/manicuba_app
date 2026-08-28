// Pruebas de la capa de consulta/analítica de InventarioService: filtros,
// totales, resúmenes y las ramas de deshacer que faltaban por cubrir.
//
// El core de compra/venta/deshacer ya está en inventario_test.dart. Aquí se
// cubren los reportes. La base es compartida: se usan categorías/nombres
// únicos y medición por diferencia para no depender de totales globales.

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/producto.dart';
import 'package:multiservicios_app/services/inventario_service.dart';

void main() {
  final inventario = InventarioService();

  String unico(String p) => '$p-${DateTime.now().microsecondsSinceEpoch}';

  Future<int> crear({
    required String nombre,
    required String categoria,
    int stock = 0,
    int minima = 2,
    double costo = 0,
    bool registrarGasto = false,
  }) {
    return inventario.crearProducto(
      Producto(
        nombre: nombre,
        categoria: categoria,
        cantidadStock: stock,
        cantidadMinima: minima,
        costoUnitario: costo,
      ),
      registrarGasto: registrarGasto,
    );
  }

  test('obtenerPorCategoria filtra por categoría', () async {
    final cat = unico('CAT');
    await crear(nombre: unico('a'), categoria: cat, stock: 1);
    await crear(nombre: unico('b'), categoria: cat, stock: 1);

    final enCat = await inventario.obtenerPorCategoria(cat);
    expect(enCat, hasLength(2));
    expect(enCat.every((p) => p.categoria == cat), isTrue);
  });

  test('obtenerBajoStock y alertasInventario listan lo que está por debajo',
      () async {
    final bajo = unico('bajo');
    final alto = unico('alto');
    await crear(nombre: bajo, categoria: unico('c'), stock: 0, minima: 5);
    await crear(nombre: alto, categoria: unico('c'), stock: 100, minima: 1);

    final nombresBajo =
        (await inventario.obtenerBajoStock()).map((p) => p.nombre).toSet();
    expect(nombresBajo.contains(bajo), isTrue);
    expect(nombresBajo.contains(alto), isFalse);

    // alertasInventario es el mismo criterio.
    final alertas =
        (await inventario.alertasInventario()).map((p) => p.nombre).toSet();
    expect(alertas.contains(bajo), isTrue);
  });

  test('actualizar cambia la ficha del producto', () async {
    final id = await crear(nombre: unico('ficha'), categoria: unico('c'));
    final producto = (await inventario.obtenerPorId(id))!;

    final nuevoNombre = unico('renombrado');
    await inventario.actualizar(
      producto.copyWith(nombre: nuevoNombre, proveedor: 'Proveedor X'),
    );

    final actualizado = (await inventario.obtenerPorId(id))!;
    expect(actualizado.nombre, nuevoNombre);
    expect(actualizado.proveedor, 'Proveedor X');
  });

  test('valorTotalInventario y cantidadTotalProductos suman (delta)', () async {
    final valorBase = await inventario.valorTotalInventario();
    final cantidadBase = await inventario.cantidadTotalProductos();

    // 4 unidades × costo 25 = 100 de valor añadido.
    await crear(nombre: unico('v'), categoria: unico('c'), stock: 4, costo: 25);

    expect(await inventario.valorTotalInventario() - valorBase,
        closeTo(100, 0.001));
    expect(await inventario.cantidadTotalProductos() - cantidadBase, 4);
  });

  test('ordenarPorStock deja el de menos stock antes que el de más', () async {
    final pocos = unico('pocos');
    final muchos = unico('muchos');
    await crear(nombre: pocos, categoria: unico('c'), stock: 1);
    await crear(nombre: muchos, categoria: unico('c'), stock: 500);

    final orden = (await inventario.ordenarPorStock()).map((p) => p.nombre).toList();
    expect(orden.indexOf(pocos), lessThan(orden.indexOf(muchos)));
  });

  test('obtenerMasUsados ordena por lo más consumido', () async {
    final usado = unico('usado');
    final intacto = unico('intacto');
    final idUsado = await crear(nombre: usado, categoria: unico('c'), stock: 20);
    await crear(nombre: intacto, categoria: unico('c'), stock: 20);

    await inventario.registrarSalida(productoId: idUsado, cantidad: 15);

    final orden =
        (await inventario.obtenerMasUsados()).map((p) => p.nombre).toList();
    expect(orden.indexOf(usado), lessThan(orden.indexOf(intacto)));
  });

  test('resumenPorCategoria agrega cantidad, costo y nº de productos', () async {
    final cat = unico('RES');
    // 3×10 = 30 y 2×20 = 40 -> cantidad 5, costo 70, productos 2.
    await crear(nombre: unico('a'), categoria: cat, stock: 3, costo: 10);
    await crear(nombre: unico('b'), categoria: cat, stock: 2, costo: 20);

    final resumen = await inventario.resumenPorCategoria();
    final delCat = resumen[cat] as Map<String, dynamic>;
    expect(delCat['cantidad'], 5);
    expect(delCat['costo'], closeTo(70, 0.001));
    expect(delCat['productos'], 2);
  });

  test('exportarTodos incluye el producto como mapa', () async {
    final nombre = unico('exp');
    await crear(nombre: nombre, categoria: unico('c'), stock: 1);

    final mapas = await inventario.exportarTodos();
    expect(mapas.any((m) => m['nombre'] == nombre), isTrue);
  });

  test('estadisticas trae las claves esperadas y es consistente', () async {
    final stats = await inventario.estadisticas();
    expect(stats['totalProductos'], isA<int>());
    expect(stats['cantidadTotal'], isA<int>());
    expect(stats['valorTotal'], isA<double>());
    expect(stats['compradoUltimoMes'], isA<double>());
    expect(stats['productosBajoStock'], isA<int>());
    expect(stats['resumenCategoria'], isA<Map>());

    // Consistencia interna con las consultas de las que se deriva.
    expect(stats['totalProductos'], (await inventario.obtenerTodos()).length);
    expect(stats['cantidadTotal'], await inventario.cantidadTotalProductos());
  });

  test('compradoUltimoMes suma la compra reciente (delta)', () async {
    final base = await inventario.compradoUltimoMes();
    final id = await crear(nombre: unico('compra'), categoria: unico('c'));

    // Compra pagada de hoy: 5 × 50 = 250.
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 5,
      totalPagado: 250,
    );

    expect(await inventario.compradoUltimoMes() - base, closeTo(250, 0.001));
  });

  test('registrarCompra guarda el proveedor indicado', () async {
    final id = await crear(nombre: unico('prov'), categoria: unico('c'));
    await inventario.registrarCompra(
      productoId: id,
      cantidad: 2,
      totalPagado: 40,
      proveedor: 'Distribuidora Sur',
    );

    final producto = (await inventario.obtenerPorId(id))!;
    expect(producto.proveedor, 'Distribuidora Sur');
  });

  test('registrarCompra sin pago no crea gasto (stock que ya se tenía)',
      () async {
    final id = await crear(nombre: unico('saldo'), categoria: unico('c'));

    final gasto = await inventario.registrarCompra(
      productoId: id,
      cantidad: 3,
      totalPagado: 0,
    );

    expect(gasto, isNull); // entrada sin dinero -> saldo inicial
    expect((await inventario.obtenerPorId(id))!.cantidadStock, 3);
  });

  test('Deshacer una salida devuelve el stock', () async {
    final id = await crear(nombre: unico('sal'), categoria: unico('c'), stock: 10);
    await inventario.registrarSalida(productoId: id, cantidad: 4);
    expect((await inventario.obtenerPorId(id))!.cantidadStock, 6);

    final salida =
        (await inventario.movimientosDe(id)).firstWhere((m) => m.esSalida);
    final resultado = await inventario.deshacerMovimiento(salida.id!);

    expect(resultado, InventarioService.deshacerOk);
    expect((await inventario.obtenerPorId(id))!.cantidadStock, 10);
  });

  test('Deshacer una compra con stock restante recalcula el costo promedio',
      () async {
    // Saldo inicial: 5 unidades a 10 (sin gasto).
    final id = await crear(
        nombre: unico('mix'), categoria: unico('c'), stock: 5, costo: 10);
    // Compra: 5 unidades por 100 -> el promedio sube a (50+100)/10 = 15.
    await inventario.registrarCompra(
        productoId: id, cantidad: 5, totalPagado: 100);
    expect((await inventario.obtenerPorId(id))!.costoUnitario, closeTo(15, 0.001));

    // Deshacer la compra: quedan 5 unidades y el costo vuelve a 10.
    final compra = (await inventario.movimientosDe(id))
        .firstWhere((m) => m.esEntrada && m.generoGasto);
    final resultado = await inventario.deshacerMovimiento(compra.id!);

    expect(resultado, InventarioService.deshacerOk);
    final producto = (await inventario.obtenerPorId(id))!;
    expect(producto.cantidadStock, 5);
    expect(producto.costoUnitario, closeTo(10, 0.001));
  });
}
