// Pruebas del ciclo completo de backup: exportar -> importar.
//
// importData() BORRA todas las tablas y reinserta desde el JSON, así que un
// fallo aquí puede costarle al usuario todos sus datos. Estas pruebas verifican
// que un snapshot completo sobrevive al viaje de ida y vuelta, que el borrado
// realmente ocurre, y que un archivo inválido se rechaza ANTES de tocar nada.
//
// Para no destruir los datos de otros tests en la base compartida, cada
// round-trip exporta el estado completo actual y lo vuelve a importar: el neto
// sobre la base es restaurar lo mismo que había.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/cliente.dart';
import 'package:multiservicios_app/models/gasto.dart';
import 'package:multiservicios_app/models/ingreso.dart';
import 'package:multiservicios_app/models/producto.dart';
import 'package:multiservicios_app/services/backup_service.dart';
import 'package:multiservicios_app/services/cliente_service.dart';
import 'package:multiservicios_app/services/finanzas_service.dart';
import 'package:multiservicios_app/services/inventario_service.dart';

void main() {
  final clienteService = ClienteService();
  final finanzasService = FinanzasService();
  final inventarioService = InventarioService();

  test('Round-trip: exportar y volver a importar conserva los datos', () async {
    // Datos con marcas únicas que deben sobrevivir al ciclo.
    final marca = 'RT-${DateTime.now().microsecondsSinceEpoch}';
    final clienteId = await clienteService.crearCliente(
      Cliente(nombre: 'Cliente $marca', telefono: '55511111'),
    );
    final productoId = await inventarioService.crearProducto(
      Producto(
        nombre: 'Producto $marca',
        categoria: 'Esmaltes',
        cantidadStock: 5,
        cantidadMinima: 1,
        costoUnitario: 10,
      ),
      registrarGasto: false,
    );
    await finanzasService.registrarIngreso(
      Ingreso(monto: 42, metodo: 'Efectivo', fecha: DateTime.now(),
          notas: marca),
    );

    // Snapshot completo del estado actual.
    final json = await BackupService.exportData();

    // Se importa el snapshot: borra todo y lo restaura idéntico.
    await BackupService.importData(json);

    // Los registros marcados siguen presentes tras el ciclo.
    final cliente = await clienteService.obtenerPorId(clienteId);
    expect(cliente, isNotNull);
    expect(cliente!.nombre, 'Cliente $marca');

    final producto = await inventarioService.obtenerPorId(productoId);
    expect(producto, isNotNull);
    expect(producto!.cantidadStock, 5);

    final ingresos = await finanzasService.obtenerIngresos();
    expect(ingresos.any((i) => i.notas == marca && i.monto == 42), isTrue);
  });

  test('Importar reemplaza el estado: lo que no está en el snapshot se borra',
      () async {
    final marca = 'WIPE-${DateTime.now().microsecondsSinceEpoch}';

    // Cliente A: dentro del snapshot.
    final idA = await clienteService.crearCliente(
      Cliente(nombre: 'A $marca', telefono: '55522222'),
    );
    final json = await BackupService.exportData();

    // Cliente B: creado DESPUÉS del snapshot, no forma parte de él.
    final idB = await clienteService.crearCliente(
      Cliente(nombre: 'B $marca', telefono: '55533333'),
    );

    await BackupService.importData(json);

    // A se restaura; B, ausente del backup, desaparece con el borrado.
    expect(await clienteService.obtenerPorId(idA), isNotNull);
    expect(await clienteService.obtenerPorId(idB), isNull);
  });

  test('El JSON exportado es un backup válido con todas las tablas', () async {
    final json = await BackupService.exportData();
    final data = jsonDecode(json) as Map<String, dynamic>;

    expect(BackupService.isValidBackup(data), isTrue);
    for (final tabla in const [
      'clientes',
      'citas',
      'productos',
      'gastos',
      'ingresos',
      'posts_redes',
      'fotos_trabajo',
      'movimientos_inventario',
    ]) {
      expect(data[tabla], isA<List>(), reason: 'falta la tabla $tabla');
    }
  });

  test('isValidBackup rechaza estructuras incompletas o mal formadas', () {
    // Falta una tabla obligatoria.
    expect(BackupService.isValidBackup({'clientes': []}), isFalse);
    // Una tabla presente pero que no es lista.
    final conTablaMala = {
      'clientes': [],
      'citas': [],
      'productos': [],
      'gastos': [],
      'ingresos': 'no-soy-una-lista',
      'posts_redes': [],
      'fotos_trabajo': [],
      'movimientos_inventario': [],
    };
    expect(BackupService.isValidBackup(conTablaMala), isFalse);
    // Un mapa vacío tampoco vale.
    expect(BackupService.isValidBackup(const {}), isFalse);
  });

  test('importDataFromFile lanza con un archivo inválido y no borra datos',
      () async {
    // Marca un registro que debe seguir vivo si NO hubo borrado.
    final marca = 'GUARD-${DateTime.now().microsecondsSinceEpoch}';
    final idGuardia = await clienteService.crearCliente(
      Cliente(nombre: 'Guardia $marca', telefono: '55544444'),
    );

    // systemTemp funciona en la VM de test; path_provider no (lanza
    // MissingPluginException bajo `flutter test`).
    final tempDir = Directory.systemTemp.createTempSync('backup_test_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final archivoMalo = File('${tempDir.path}/backup_invalido_$marca.json');
    await archivoMalo.writeAsString('{"clientes": []}'); // faltan tablas

    // La validación falla antes de importData(), así que nada se borra.
    await expectLater(
      BackupService.importDataFromFile(archivoMalo),
      throwsA(isA<Exception>()),
    );

    expect(await clienteService.obtenerPorId(idGuardia), isNotNull);
  });
}
