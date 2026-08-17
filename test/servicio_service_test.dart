// Pruebas de ServicioService y del modelo Servicio (round-trip y helpers).
//
// La base es compartida: se usan nombres únicos y, para el promedio global,
// se comprueba la consistencia interna en vez de un valor absoluto.

import 'package:flutter_test/flutter_test.dart';

import 'package:manicuba_app/models/servicio.dart';
import 'package:manicuba_app/services/servicio_service.dart';

void main() {
  final servicios = ServicioService();

  String unico(String p) => '$p-${DateTime.now().microsecondsSinceEpoch}';

  test('crearServicio guarda y obtenerTodos lo devuelve', () async {
    final nombre = unico('svc');
    await servicios.crearServicio(
      Servicio(nombre: nombre, precio: 15, duracionMinutos: 30),
    );

    final todos = await servicios.obtenerTodos();
    expect(todos.any((s) => s.nombre == nombre), isTrue);
  });

  test('actualizar cambia el precio guardado', () async {
    final nombre = unico('svc');
    final id = await servicios.crearServicio(
      Servicio(nombre: nombre, precio: 10, duracionMinutos: 20),
    );

    await servicios.actualizar(
      Servicio(id: id, nombre: nombre, precio: 45, duracionMinutos: 20),
    );

    final servicio =
        (await servicios.obtenerTodos()).firstWhere((s) => s.id == id);
    expect(servicio.precio, closeTo(45, 0.001));
  });

  test('eliminar quita el servicio del catálogo', () async {
    final nombre = unico('svc');
    final id = await servicios.crearServicio(
      Servicio(nombre: nombre, precio: 10, duracionMinutos: 20),
    );

    await servicios.eliminar(id);

    final todos = await servicios.obtenerTodos();
    expect(todos.any((s) => s.id == id), isFalse);
  });

  test('precioPromedio es la media de los precios del catálogo', () async {
    // Aseguramos que hay al menos un servicio y comprobamos consistencia
    // interna con obtenerTodos (media = suma / número).
    await servicios.crearServicio(
      Servicio(nombre: unico('svc'), precio: 33, duracionMinutos: 15),
    );

    final todos = await servicios.obtenerTodos();
    final esperado =
        todos.fold<double>(0, (s, x) => s + x.precio) / todos.length;

    expect(await servicios.precioPromedio(), closeTo(esperado, 0.001));
  });

  group('Modelo Servicio', () {
    test('toMap/fromMap conservan los campos', () {
      final original = Servicio(
        id: 7,
        nombre: 'Manicura',
        precio: 12.5,
        duracionMinutos: 40,
        descripcion: 'con esmaltado',
      );

      final copia = Servicio.fromMap(original.toMap());
      expect(copia.id, 7);
      expect(copia.nombre, 'Manicura');
      expect(copia.precio, closeTo(12.5, 0.001));
      expect(copia.duracionMinutos, 40);
      expect(copia.descripcion, 'con esmaltado');
    });

    test('fromMap acepta precio entero (int) y lo pasa a double', () {
      final servicio = Servicio.fromMap({
        'id': 1,
        'nombre': 'Pedicura',
        'precio': 20, // entero, como puede venir de SQLite
        'duracion_minutos': 30,
        'descripcion': null,
      });
      expect(servicio.precio, isA<double>());
      expect(servicio.precio, closeTo(20, 0.001));
      expect(servicio.descripcion, isNull);
    });

    test('copyWith cambia solo lo indicado', () {
      final base = Servicio(nombre: 'A', precio: 10, duracionMinutos: 20);
      final modificado = base.copyWith(precio: 99);
      expect(modificado.nombre, 'A');
      expect(modificado.precio, closeTo(99, 0.001));
      expect(modificado.duracionMinutos, 20);
    });

    test('toString incluye nombre y precio', () {
      final s = Servicio(nombre: 'Uñas', precio: 25, duracionMinutos: 30);
      expect(s.toString(), contains('Uñas'));
      expect(s.toString(), contains('25'));
    });
  });
}
