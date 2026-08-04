// Verifica el borrado de movimientos manuales en Finanzas.

import 'package:flutter_test/flutter_test.dart';

import 'package:manicuba_app/models/gasto.dart';
import 'package:manicuba_app/models/ingreso.dart';
import 'package:manicuba_app/services/finanzas_service.dart';

void main() {
  final finanzas = FinanzasService();

  test('Eliminar un gasto manual lo quita de la lista', () async {
    final id = await finanzas.registrarGasto(
      Gasto(
        concepto: 'Gasto Borrable',
        monto: 12,
        categoria: 'Otros',
        fecha: DateTime.now(),
      ),
    );
    expect((await finanzas.obtenerGastos()).any((g) => g.id == id), isTrue);

    await finanzas.eliminarGasto(id);
    expect((await finanzas.obtenerGastos()).any((g) => g.id == id), isFalse);
  });

  test('Eliminar un ingreso manual lo quita de la lista', () async {
    final id = await finanzas.registrarIngreso(
      Ingreso(monto: 40, metodo: 'Efectivo', fecha: DateTime.now()),
    );
    expect((await finanzas.obtenerIngresos()).any((i) => i.id == id), isTrue);

    await finanzas.eliminarIngreso(id);
    expect((await finanzas.obtenerIngresos()).any((i) => i.id == id), isFalse);
  });
}
