import '../database/database_helper.dart';
import '../models/cliente.dart';

class ClienteService {
  final DatabaseHelper _db = DatabaseHelper();

  // Crear cliente
  Future<int> crearCliente(Cliente cliente) async {
    final clienteConFecha = cliente.copyWith(
      fechaCreacion: cliente.fechaCreacion ?? DateTime.now(),
    );
    return await _db.insertCliente(clienteConFecha.toMap());
  }

  // Obtener todos los clientes
  Future<List<Cliente>> obtenerTodos() async {
    final mapList = await _db.getAllClientes();
    return mapList.map((map) => Cliente.fromMap(map)).toList();
  }

  // Obtener cliente por ID
  Future<Cliente?> obtenerPorId(int id) async {
    final map = await _db.getClienteById(id);
    return map != null ? Cliente.fromMap(map) : null;
  }

  // Actualizar cliente
  Future<int> actualizar(Cliente cliente) async {
    return await _db.updateCliente(cliente.toMap());
  }

  // Eliminar cliente
  Future<int> eliminar(int id) async {
    return await _db.deleteCliente(id);
  }

  // Buscar cliente por nombre
  Future<List<Cliente>> buscarPorNombre(String nombre) async {
    final todos = await obtenerTodos();
    return todos
        .where((c) => c.nombre.toLowerCase().contains(nombre.toLowerCase()))
        .toList();
  }

  // Buscar cliente por teléfono
  Future<Cliente?> buscarPorTelefono(String telefono) async {
    final todos = await obtenerTodos();
    try {
      return todos.firstWhere((c) => c.telefono == telefono);
    } catch (e) {
      return null;
    }
  }

  // Obtener total de clientes
  Future<int> obtenerTotal() async {
    final clientes = await obtenerTodos();
    return clientes.length;
  }

  // Obtener clientes frecuentes (más de 3 citas)
  Future<List<Cliente>> obtenerClientesFrecuentes() async {
    // Esta función se integrará con CitaService después
    final clientes = await obtenerTodos();
    return clientes;
  }

  // Actualizar última visita
  Future<int> actualizarUltimaVisita(int id) async {
    final cliente = await obtenerPorId(id);
    if (cliente != null) {
      final clienteActualizado =
          cliente.copyWith(ultimaVisita: DateTime.now());
      return await actualizar(clienteActualizado);
    }
    return 0;
  }

  // Exportar clientes a lista de mapas
  Future<List<Map<String, dynamic>>> exportarTodos() async {
    final clientes = await obtenerTodos();
    return clientes.map((c) => c.toMap()).toList();
  }
}
