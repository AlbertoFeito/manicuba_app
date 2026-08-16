// Pruebas de la capa de análisis de FinanzasService.
//
// La base de datos es compartida entre tests, así que aquí se mide por
// diferencias (delta antes/después) o con marcas únicas (métodos/categorías
// que ningún otro test usa), nunca sobre totales absolutos.

import 'package:flutter_test/flutter_test.dart';

import 'package:manicuba_app/models/gasto.dart';
import 'package:manicuba_app/models/ingreso.dart';
import 'package:manicuba_app/services/finanzas_service.dart';

void main() {
  final finanzas = FinanzasService();

  String unico(String prefijo) =>
      '$prefijo-${DateTime.now().microsecondsSinceEpoch}';

  test('ingresoMes/gastoMes cuentan lo reciente y excluyen lo viejo', () async {
    final baseIngreso = await finanzas.ingresoMes();
    final baseGasto = await finanzas.gastoMes();

    final ahora = DateTime.now();
    final hace40dias = ahora.subtract(const Duration(days: 40));

    // Reciente: entra en la ventana de 30 días.
    await finanzas.registrarIngreso(
      Ingreso(monto: 100, metodo: 'Efectivo', fecha: ahora),
    );
    await finanzas.registrarGasto(
      Gasto(concepto: unico('g'), monto: 30, categoria: 'Otros', fecha: ahora),
    );
    // Viejo: fuera de la ventana, no debe sumar.
    await finanzas.registrarIngreso(
      Ingreso(monto: 999, metodo: 'Efectivo', fecha: hace40dias),
    );
    await finanzas.registrarGasto(
      Gasto(
          concepto: unico('g'),
          monto: 999,
          categoria: 'Otros',
          fecha: hace40dias),
    );

    expect(await finanzas.ingresoMes() - baseIngreso, closeTo(100, 0.001));
    expect(await finanzas.gastoMes() - baseGasto, closeTo(30, 0.001));
  });

  test('balanceMes es ingresos menos gastos del mes', () async {
    final base = await finanzas.balanceMes();
    final ahora = DateTime.now();

    await finanzas.registrarIngreso(
      Ingreso(monto: 200, metodo: 'Efectivo', fecha: ahora),
    );
    await finanzas.registrarGasto(
      Gasto(concepto: unico('g'), monto: 50, categoria: 'Otros', fecha: ahora),
    );

    expect(await finanzas.balanceMes() - base, closeTo(150, 0.001));
  });

  test('ingresosPorMetodo agrupa y suma por método de pago', () async {
    final metodo = unico('MET');
    await finanzas.registrarIngreso(
      Ingreso(monto: 30, metodo: metodo, fecha: DateTime.now()),
    );
    await finanzas.registrarIngreso(
      Ingreso(monto: 20, metodo: metodo, fecha: DateTime.now()),
    );

    final porMetodo = await finanzas.ingresosPorMetodo();
    expect(porMetodo[metodo], closeTo(50, 0.001));
  });

  test('gastosPorCategoria agrupa y suma por categoría', () async {
    final categoria = unico('CAT');
    await finanzas.registrarGasto(
      Gasto(
          concepto: 'a', monto: 10, categoria: categoria, fecha: DateTime.now()),
    );
    await finanzas.registrarGasto(
      Gasto(
          concepto: 'b', monto: 15, categoria: categoria, fecha: DateTime.now()),
    );

    final porCategoria = await finanzas.gastosPorCategoria();
    expect(porCategoria[categoria], closeTo(25, 0.001));
  });

  test('progresoMes es internamente consistente (balance y margen)', () async {
    // Aseguramos ingresos > 0 en el mes para ejercitar el cálculo del margen.
    await finanzas.registrarIngreso(
      Ingreso(monto: 120, metodo: 'Efectivo', fecha: DateTime.now()),
    );

    final p = await finanzas.progresoMes();
    final ingresos = p['ingresos'] as double;
    final gastos = p['gastos'] as double;
    final balance = p['balance'] as double;
    final margen = p['margen'] as num;

    expect(balance, closeTo(ingresos - gastos, 0.001));
    expect(ingresos, greaterThan(0));
    expect(margen, closeTo(balance / ingresos * 100, 0.001));
  });

  test('totalTransacciones cuenta ingresos y gastos', () async {
    final base = await finanzas.totalTransacciones();

    await finanzas.registrarIngreso(
      Ingreso(monto: 10, metodo: 'Efectivo', fecha: DateTime.now()),
    );
    await finanzas.registrarGasto(
      Gasto(concepto: unico('g'), monto: 5, categoria: 'Otros',
          fecha: DateTime.now()),
    );

    expect(await finanzas.totalTransacciones() - base, 2);
  });

  test('actualizarIngreso cambia el monto guardado', () async {
    final nota = unico('upd');
    final id = await finanzas.registrarIngreso(
      Ingreso(monto: 40, metodo: 'Efectivo', fecha: DateTime.now(), notas: nota),
    );

    await finanzas.actualizarIngreso(
      Ingreso(
          id: id,
          monto: 55,
          metodo: 'Efectivo',
          fecha: DateTime.now(),
          notas: nota),
    );

    final ingreso =
        (await finanzas.obtenerIngresos()).firstWhere((i) => i.id == id);
    expect(ingreso.monto, closeTo(55, 0.001));
  });

  test('desvincularGastosDeProducto suelta el gasto sin borrarlo', () async {
    // productoId único que ningún otro test usa.
    final productoId = DateTime.now().microsecondsSinceEpoch % 1000000 + 700000;
    final concepto = unico('compra');
    await finanzas.registrarGasto(
      Gasto(
        concepto: concepto,
        monto: 80,
        categoria: 'Productos',
        fecha: DateTime.now(),
        productoId: productoId,
      ),
    );

    expect(await finanzas.obtenerGastosPorProducto(productoId), hasLength(1));

    await finanzas.desvincularGastosDeProducto(productoId);

    // Ya no aparece vinculado al producto, pero el gasto sigue existiendo.
    expect(await finanzas.obtenerGastosPorProducto(productoId), isEmpty);
    expect(
      (await finanzas.obtenerGastos()).any((g) => g.concepto == concepto),
      isTrue,
    );
  });

  test('exportarDatos incluye todas las secciones esperadas', () async {
    final datos = await finanzas.exportarDatos();
    for (final clave in const [
      'ingresos',
      'gastos',
      'ingresoHoy',
      'gastoHoy',
      'balanceHoy',
      'ingresoMes',
      'gastoMes',
      'balanceMes',
      'gastosPorCategoria',
      'ingresosPorMetodo',
    ]) {
      expect(datos.containsKey(clave), isTrue, reason: 'falta $clave');
    }
    expect(datos['ingresos'], isA<List<Ingreso>>());
    expect(datos['gastos'], isA<List<Gasto>>());
  });
}
