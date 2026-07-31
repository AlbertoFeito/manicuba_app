import '../database/database_helper.dart';
import '../models/servicio.dart';

/// Lógica de negocio para el catálogo de servicios.
class ServicioService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> crearServicio(Servicio servicio) async {
    return _db.insertServicio(servicio.toMap());
  }

  Future<List<Servicio>> obtenerTodos() async {
    final mapList = await _db.getAllServicios();
    return mapList.map(Servicio.fromMap).toList();
  }

  Future<int> actualizar(Servicio servicio) async {
    return _db.updateServicio(servicio.toMap());
  }

  Future<int> eliminar(int id) async {
    return _db.deleteServicio(id);
  }

  /// Precio promedio del catálogo (0 si no hay servicios).
  Future<double> precioPromedio() async {
    final servicios = await obtenerTodos();
    if (servicios.isEmpty) {
      return 0;
    }
    final total = servicios.fold<double>(0, (sum, s) => sum + s.precio);
    return total / servicios.length;
  }
}
