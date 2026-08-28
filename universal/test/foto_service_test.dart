// Pruebas de FotoService que tocan disco (guardar/eliminar), usando el mock
// de path_provider para redirigir el almacenamiento de la app a una carpeta
// temporal real. obtenerPorIds ya está cubierto en redes_fotos_test.dart.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestorpro_app/models/foto_trabajo.dart';
import 'package:gestorpro_app/services/foto_service.dart';

import 'support/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fotos = FotoService();
  late FakePathProvider fake;

  setUp(() {
    fake = FakePathProvider.install();
  });
  tearDown(() => fake.dispose());

  /// Crea un archivo de origen (simula la imagen elegida por la usuaria).
  File crearOrigen(String nombre) =>
      File('${fake.root.path}/$nombre')..writeAsBytesSync([1, 2, 3, 4]);

  test('guardarDesdeArchivo copia la imagen y registra la foto', () async {
    final total0 = await fotos.total();

    final foto = await fotos.guardarDesdeArchivo(
      crearOrigen('elegida.jpg'),
      descripcion: 'trabajo bonito',
    );

    // Registrada en BD con id y descripción.
    expect(foto.id, isNotNull);
    expect(foto.descripcion, 'trabajo bonito');
    // El archivo se copió al almacenamiento interno de la app.
    expect(File(foto.rutaFoto).existsSync(), isTrue);
    expect(foto.rutaFoto, contains('fotos_trabajo'));
    expect(foto.rutaFoto, endsWith('.jpg'));

    // Aparece en la galería y el total sube en uno.
    final todas = await fotos.obtenerTodas();
    expect(todas.any((f) => f.id == foto.id), isTrue);
    expect(await fotos.total() - total0, 1);
  });

  test('eliminar borra el registro y el archivo del disco', () async {
    final foto = await fotos.guardarDesdeArchivo(crearOrigen('borrar.jpg'));
    final ruta = foto.rutaFoto;
    expect(File(ruta).existsSync(), isTrue);

    await fotos.eliminar(foto);

    expect(File(ruta).existsSync(), isFalse);
    expect((await fotos.obtenerTodas()).any((f) => f.id == foto.id), isFalse);
  });

  test('eliminar no falla si la foto no tiene id ni archivo', () async {
    // Registro suelto que apunta a un archivo inexistente y sin id.
    final fantasma = FotoTrabajo(
      rutaFoto: '${fake.root.path}/no-existe.jpg',
      fecha: DateTime.now(),
    );
    await fotos.eliminar(fantasma); // no debe lanzar
  });
}
