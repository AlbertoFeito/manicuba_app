import '../database/database_helper.dart';
import '../models/producto.dart';

class InventarioService {
  final DatabaseHelper _db = DatabaseHelper();

  // Crear producto
  Future<int> crearProducto(Producto producto) async {
    final productoConFecha = producto.copyWith(
      fechaCreacion: producto.fechaCreacion ?? DateTime.now(),
    );
    return await _db.insertProducto(productoConFecha.toMap());
  }

  // Obtener todos los productos
  Future<List<Producto>> obtenerTodos() async {
    final mapList = await _db.getAllProductos();
    return mapList.map((map) => Producto.fromMap(map)).toList();
  }

  // Obtener productos por categoría
  Future<List<Producto>> obtenerPorCategoria(String categoria) async {
    final todos = await obtenerTodos();
    return todos.where((p) => p.categoria == categoria).toList();
  }

  // Obtener productos con bajo stock
  Future<List<Producto>> obtenerBajoStock() async {
    final todos = await obtenerTodos();
    return todos.where((p) => p.bajoStock).toList();
  }

  // Actualizar producto
  Future<int> actualizar(Producto producto) async {
    return await _db.updateProducto(producto.toMap());
  }

  // Aumentar stock
  Future<int> aumentarStock(int id, int cantidad) async {
    final todos = await obtenerTodos();
    final producto = todos.firstWhere((p) => p.id == id);
    final productoActualizado = producto.copyWith(
      cantidadStock: producto.cantidadStock + cantidad,
      fechaCompra: DateTime.now(),
    );
    return await actualizar(productoActualizado);
  }

  // Disminuir stock
  Future<int> disminuirStock(int id, int cantidad) async {
    final todos = await obtenerTodos();
    final producto = todos.firstWhere((p) => p.id == id);
    final nuevoStock = (producto.cantidadStock - cantidad).clamp(0, 999999);
    final productoActualizado = producto.copyWith(
      cantidadStock: nuevoStock,
    );
    return await actualizar(productoActualizado);
  }

  // Obtener valor total del inventario
  Future<double> valorTotalInventario() async {
    final todos = await obtenerTodos();
    return todos.fold<double>(
        0, (sum, p) => sum + (p.cantidadStock * p.costoUnitario));
  }

  // Obtener cantidad total de productos
  Future<int> cantidadTotalProductos() async {
    final todos = await obtenerTodos();
    return todos.fold<int>(0, (sum, p) => sum + p.cantidadStock);
  }

  // Obtener productos por cantidad de stock
  Future<List<Producto>> ordenarPorStock() async {
    final todos = await obtenerTodos();
    todos.sort((a, b) => a.cantidadStock.compareTo(b.cantidadStock));
    return todos;
  }

  // Obtener costo total de inventario
  Future<double> costoTotalInventario() async {
    final todos = await obtenerTodos();
    return todos.fold<double>(
        0, (sum, p) => sum + (p.cantidadStock * p.costoUnitario));
  }

  // Obtener productos más usados (ficción - se integrará con CitaService)
  Future<List<Producto>> obtenerMasUsados() async {
    // Esta función se integrará con CitaService después
    return await obtenerTodos();
  }

  // Resumen por categoría
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

  // Alerta de inventario bajo
  Future<List<Producto>> alertasInventario() async {
    return await obtenerBajoStock();
  }

  // Exportar inventario
  Future<List<Map<String, dynamic>>> exportarTodos() async {
    final productos = await obtenerTodos();
    return productos.map((p) => p.toMap()).toList();
  }

  // Obtener estadísticas
  Future<Map<String, dynamic>> estadisticas() async {
    final todos = await obtenerTodos();
    final bajoStock = await obtenerBajoStock();

    return {
      'totalProductos': todos.length,
      'cantidadTotal': await cantidadTotalProductos(),
      'valorTotal': await valorTotalInventario(),
      'costoTotal': await costoTotalInventario(),
      'productosBajoStock': bajoStock.length,
      'resumenCategoria': await resumenPorCategoria(),
    };
  }
}
