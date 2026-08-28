// Pruebas de las consultas de ClienteService que faltaban por cubrir:
// búsqueda por nombre/teléfono, total, frecuentes, última visita y export.
//
// Base compartida: marcas únicas por nombre/teléfono y medición por delta.

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/cliente.dart';
import 'package:multiservicios_app/services/cliente_service.dart';

void main() {
  final clientes = ClienteService();

  String unico(String p) => '$p-${DateTime.now().microsecondsSinceEpoch}';

  test('buscarPorNombre encuentra por subcadena, sin distinguir mayúsculas',
      () async {
    final nombre = unico('Rosalía');
    await clientes.crearCliente(Cliente(nombre: nombre, telefono: '55510000'));

    // Búsqueda parcial y en minúscula.
    final fragmento = nombre.substring(0, 6).toLowerCase();
    final encontrados = await clientes.buscarPorNombre(fragmento);
    expect(encontrados.any((c) => c.nombre == nombre), isTrue);
  });

  test('buscarPorTelefono devuelve el cliente o null', () async {
    final telefono = 'T${DateTime.now().microsecondsSinceEpoch}';
    final nombre = unico('Tel');
    await clientes.crearCliente(Cliente(nombre: nombre, telefono: telefono));

    final encontrado = await clientes.buscarPorTelefono(telefono);
    expect(encontrado, isNotNull);
    expect(encontrado!.nombre, nombre);

    // Un teléfono inexistente -> null (rama del catch).
    expect(await clientes.buscarPorTelefono('no-existe-jamas'), isNull);
  });

  test('obtenerTotal sube en uno al crear un cliente', () async {
    final base = await clientes.obtenerTotal();
    await clientes.crearCliente(
      Cliente(nombre: unico('Cnt'), telefono: '55520000'),
    );
    expect(await clientes.obtenerTotal() - base, 1);
  });

  test('obtenerClientesFrecuentes incluye a los clientes existentes', () async {
    final nombre = unico('Frec');
    await clientes.crearCliente(Cliente(nombre: nombre, telefono: '55530000'));

    final frecuentes = await clientes.obtenerClientesFrecuentes();
    expect(frecuentes.any((c) => c.nombre == nombre), isTrue);
  });

  test('actualizarUltimaVisita fija la última visita a ahora', () async {
    final id = await clientes.crearCliente(
      Cliente(nombre: unico('Vis'), telefono: '55540000'),
    );
    expect((await clientes.obtenerPorId(id))!.ultimaVisita, isNull);

    final antes = DateTime.now().subtract(const Duration(seconds: 1));
    await clientes.actualizarUltimaVisita(id);

    final visita = (await clientes.obtenerPorId(id))!.ultimaVisita;
    expect(visita, isNotNull);
    expect(visita!.isAfter(antes), isTrue);
  });

  test('exportarTodos incluye al cliente como mapa', () async {
    final nombre = unico('Exp');
    await clientes.crearCliente(Cliente(nombre: nombre, telefono: '55550000'));

    final mapas = await clientes.exportarTodos();
    expect(mapas.any((m) => m['nombre'] == nombre), isTrue);
  });
}
