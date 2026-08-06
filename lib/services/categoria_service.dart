import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';

/// Categorías de productos personalizadas por la usuaria, además de las que
/// trae la app de fábrica. Se guardan en el dispositivo (persisten entre
/// arranques) y se combinan con [AppConstants.categoriasProductos] al leer.
class CategoriaService {
  static const _kCustom = 'categorias_productos_custom';

  /// Todas las categorías disponibles para el selector: las de fábrica
  /// (sin "Otros"), luego las personalizadas, y "Otros" siempre al final.
  Future<List<String>> obtenerCategorias() async {
    final sp = await SharedPreferences.getInstance();
    final custom = sp.getStringList(_kCustom) ?? [];
    final base =
        AppConstants.categoriasProductos.where((c) => c != 'Otros').toList();

    final vistos = <String>{};
    final combinado = <String>[];
    for (final c in [...base, ...custom]) {
      if (vistos.add(c.toLowerCase())) {
        combinado.add(c);
      }
    }
    combinado.add('Otros');
    return combinado;
  }

  /// Guarda [nombre] como nueva categoría personalizada, si no existe ya
  /// (comparación sin distinguir mayúsculas/minúsculas). No hace nada si
  /// [nombre] está vacío.
  Future<void> agregarCategoria(String nombre) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) {
      return;
    }
    final sp = await SharedPreferences.getInstance();
    final custom = sp.getStringList(_kCustom) ?? [];
    final yaExiste = custom.any((c) => c.toLowerCase() == limpio.toLowerCase()) ||
        AppConstants.categoriasProductos
            .any((c) => c.toLowerCase() == limpio.toLowerCase());
    if (!yaExiste) {
      await sp.setStringList(_kCustom, [...custom, limpio]);
    }
  }
}
