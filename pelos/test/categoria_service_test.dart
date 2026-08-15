// Pruebas de las categorías de productos personalizadas.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pelucuba_app/services/categoria_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final categoriaService = CategoriaService();

  test('Las categorías de fábrica se listan con "Otros" al final', () async {
    final categorias = await categoriaService.obtenerCategorias();
    expect(categorias.last, 'Otros');
    expect(categorias.contains('Tintes'), isTrue);
  });

  test('Agregar una categoría nueva la deja disponible y persiste', () async {
    await categoriaService.agregarCategoria('Pestañas');
    final categorias = await categoriaService.obtenerCategorias();
    expect(categorias.contains('Pestañas'), isTrue);
    // "Otros" se mantiene siempre al final del selector.
    expect(categorias.last, 'Otros');
  });

  test('No duplica una categoría ya existente (sin distinguir mayúsculas)',
      () async {
    await categoriaService.agregarCategoria('Tintes'); // ya es de fábrica
    await categoriaService.agregarCategoria('champús'); // ya es de fábrica
    final categorias = await categoriaService.obtenerCategorias();
    expect(categorias.where((c) => c.toLowerCase() == 'tintes').length, 1);
    expect(categorias.where((c) => c.toLowerCase() == 'champús').length, 1);
  });

  test('Ignora nombres vacíos', () async {
    await categoriaService.agregarCategoria('   ');
    final categorias = await categoriaService.obtenerCategorias();
    expect(categorias.contains(''), isFalse);
  });
}
