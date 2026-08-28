// Test de integración de la capa de finanzas usando la DB en memoria.

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/gasto.dart';
import 'package:multiservicios_app/models/ingreso.dart';
import 'package:multiservicios_app/services/finanzas_service.dart';

void main() {
  test('El balance del día refleja ingresos menos gastos', () async {
    final finanzas = FinanzasService();

    final balanceInicial = await finanzas.balanceHoy();

    await finanzas.registrarIngreso(
      Ingreso(monto: 100, metodo: 'Efectivo', fecha: DateTime.now()),
    );
    await finanzas.registrarGasto(
      Gasto(
        concepto: 'Esmaltes',
        monto: 30,
        categoria: 'Productos',
        fecha: DateTime.now(),
      ),
    );

    final balanceFinal = await finanzas.balanceHoy();
    expect(balanceFinal - balanceInicial, closeTo(70, 0.001));

    final porCategoria = await finanzas.gastosPorCategoria();
    expect(porCategoria.containsKey('Productos'), isTrue);
  });
}
