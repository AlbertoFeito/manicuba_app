import '../database/database_helper.dart';
import '../models/ingreso.dart';
import '../models/gasto.dart';

class FinanzasService {
  final DatabaseHelper _db = DatabaseHelper();

  // ===== INGRESOS =====

  Future<int> registrarIngreso(Ingreso ingreso) async {
    return await _db.insertIngreso(ingreso.toMap());
  }

  Future<List<Ingreso>> obtenerIngresos() async {
    final mapList = await _db.getAllIngresos();
    return mapList.map((map) => Ingreso.fromMap(map)).toList();
  }

  Future<List<Ingreso>> obtenerIngresosPorFecha(DateTime fecha) async {
    final mapList = await _db.getIngresosByFecha(fecha);
    return mapList.map((map) => Ingreso.fromMap(map)).toList();
  }

  Future<List<Ingreso>> obtenerIngresosPorCita(int citaId) async {
    final mapList = await _db.getIngresosByCita(citaId);
    return mapList.map((map) => Ingreso.fromMap(map)).toList();
  }

  Future<int> eliminarIngresosPorCita(int citaId) async {
    return _db.deleteIngresosByCita(citaId);
  }

  Future<int> actualizarIngreso(Ingreso ingreso) async {
    return _db.updateIngreso(ingreso.toMap());
  }

  Future<int> eliminarIngreso(int id) async {
    return _db.deleteIngreso(id);
  }

  // ===== GASTOS =====

  Future<int> registrarGasto(Gasto gasto) async {
    return await _db.insertGasto(gasto.toMap());
  }

  Future<int> actualizarGasto(Gasto gasto) async {
    return _db.updateGasto(gasto.toMap());
  }

  Future<int> eliminarGasto(int id) async {
    return _db.deleteGasto(id);
  }

  Future<List<Gasto>> obtenerGastos() async {
    final mapList = await _db.getAllGastos();
    return mapList.map((map) => Gasto.fromMap(map)).toList();
  }

  Future<List<Gasto>> obtenerGastosPorFecha(DateTime fecha) async {
    final mapList = await _db.getGastosByFecha(fecha);
    return mapList.map((map) => Gasto.fromMap(map)).toList();
  }

  /// Gastos generados automáticamente por las compras de un producto.
  Future<List<Gasto>> obtenerGastosPorProducto(int productoId) async {
    final mapList = await _db.getGastosByProducto(productoId);
    return mapList.map((map) => Gasto.fromMap(map)).toList();
  }

  Future<int> desvincularGastosDeProducto(int productoId) async {
    return _db.desvincularGastosDeProducto(productoId);
  }

  // ===== ANÁLISIS =====

  // Ingreso total hoy
  Future<double> ingresoHoy() async {
    final ingresos = await obtenerIngresosPorFecha(DateTime.now());
    return ingresos.fold<double>(0, (sum, i) => sum + i.monto);
  }

  // Ingreso total semana
  Future<double> ingresoSemana() async {
    final hoy = DateTime.now();
    final hace7dias = hoy.subtract(const Duration(days: 7));
    final ingresos = await obtenerIngresos();
    return ingresos
        .where((i) => i.fecha.isAfter(hace7dias))
        .fold<double>(0, (sum, i) => sum + i.monto);
  }

  // Ingreso total mes
  Future<double> ingresoMes() async {
    final hoy = DateTime.now();
    final hace30dias = hoy.subtract(const Duration(days: 30));
    final ingresos = await obtenerIngresos();
    return ingresos
        .where((i) => i.fecha.isAfter(hace30dias))
        .fold<double>(0, (sum, i) => sum + i.monto);
  }

  // Gasto total hoy
  Future<double> gastoHoy() async {
    final gastos = await obtenerGastosPorFecha(DateTime.now());
    return gastos.fold<double>(0, (sum, g) => sum + g.monto);
  }

  // Gasto total semana
  Future<double> gastoSemana() async {
    final hoy = DateTime.now();
    final hace7dias = hoy.subtract(const Duration(days: 7));
    final gastos = await obtenerGastos();
    return gastos
        .where((g) => g.fecha.isAfter(hace7dias))
        .fold<double>(0, (sum, g) => sum + g.monto);
  }

  // Gasto total mes
  Future<double> gastoMes() async {
    final hoy = DateTime.now();
    final hace30dias = hoy.subtract(const Duration(days: 30));
    final gastos = await obtenerGastos();
    return gastos
        .where((g) => g.fecha.isAfter(hace30dias))
        .fold<double>(0, (sum, g) => sum + g.monto);
  }

  // Balance hoy
  Future<double> balanceHoy() async {
    final ingresos = await ingresoHoy();
    final gastos = await gastoHoy();
    return ingresos - gastos;
  }

  // Balance semana
  Future<double> balanceSemana() async {
    final ingresos = await ingresoSemana();
    final gastos = await gastoSemana();
    return ingresos - gastos;
  }

  // Balance mes
  Future<double> balanceMes() async {
    final ingresos = await ingresoMes();
    final gastos = await gastoMes();
    return ingresos - gastos;
  }

  // Gastos por categoría
  Future<Map<String, double>> gastosPorCategoria() async {
    final gastos = await obtenerGastos();
    final mapa = <String, double>{};

    for (var gasto in gastos) {
      mapa.update(
        gasto.categoria,
        (value) => value + gasto.monto,
        ifAbsent: () => gasto.monto,
      );
    }

    return mapa;
  }

  // Ingresos por método de pago
  Future<Map<String, double>> ingresosPorMetodo() async {
    final ingresos = await obtenerIngresos();
    final mapa = <String, double>{};

    for (var ingreso in ingresos) {
      mapa.update(
        ingreso.metodo,
        (value) => value + ingreso.monto,
        ifAbsent: () => ingreso.monto,
      );
    }

    return mapa;
  }

  // Obtener progreso del mes
  Future<Map<String, dynamic>> progresoMes() async {
    final ingresos = await ingresoMes();
    final gastos = await gastoMes();
    final balance = ingresos - gastos;
    final margen = ingresos > 0 ? (balance / ingresos) * 100 : 0;

    return {
      'ingresos': ingresos,
      'gastos': gastos,
      'balance': balance,
      'margen': margen,
    };
  }

  // Total de transacciones
  Future<int> totalTransacciones() async {
    final ingresos = await obtenerIngresos();
    final gastos = await obtenerGastos();
    return ingresos.length + gastos.length;
  }

  // Exportar datos financieros
  Future<Map<String, dynamic>> exportarDatos() async {
    return {
      'ingresos': await obtenerIngresos(),
      'gastos': await obtenerGastos(),
      'ingresoHoy': await ingresoHoy(),
      'gastoHoy': await gastoHoy(),
      'balanceHoy': await balanceHoy(),
      'ingresoMes': await ingresoMes(),
      'gastoMes': await gastoMes(),
      'balanceMes': await balanceMes(),
      'gastosPorCategoria': await gastosPorCategoria(),
      'ingresosPorMetodo': await ingresosPorMetodo(),
    };
  }
}
