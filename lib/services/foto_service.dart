import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/foto_trabajo.dart';

/// Lógica de negocio para la galería de fotos de trabajo. Copia las imágenes
/// seleccionadas al almacenamiento interno de la app (offline) y las registra
/// en la base de datos.
class FotoService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<Directory> _directorioFotos() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'fotos_trabajo'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copia [origen] al almacenamiento de la app y registra la foto.
  Future<FotoTrabajo> guardarDesdeArchivo(
    File origen, {
    String? descripcion,
    int? citaId,
  }) async {
    final dir = await _directorioFotos();
    final nombre = 'foto_${DateTime.now().millisecondsSinceEpoch}'
        '${p.extension(origen.path)}';
    final destino = p.join(dir.path, nombre);
    await origen.copy(destino);

    final foto = FotoTrabajo(
      rutaFoto: destino,
      fecha: DateTime.now(),
      descripcion: descripcion,
      citaId: citaId,
    );
    final id = await _db.insertFotoTrabajo(foto.toMap());
    return foto.copyWith(id: id);
  }

  Future<List<FotoTrabajo>> obtenerTodas() async {
    final mapList = await _db.getAllFotosTrabajo();
    return mapList.map(FotoTrabajo.fromMap).toList();
  }

  /// Devuelve las fotos con esos [ids], en el mismo orden pedido. Ids sin
  /// foto correspondiente (p. ej. borrada de la Galería) se descartan.
  Future<List<FotoTrabajo>> obtenerPorIds(List<int> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    final porId = {for (final f in await obtenerTodas()) f.id: f};
    return ids.map((id) => porId[id]).whereType<FotoTrabajo>().toList();
  }

  /// Elimina el registro y, si existe, el archivo en disco.
  Future<void> eliminar(FotoTrabajo foto) async {
    if (foto.id != null) {
      await _db.deleteFotoTrabajo(foto.id!);
    }
    final archivo = File(foto.rutaFoto);
    if (await archivo.exists()) {
      await archivo.delete();
    }
  }

  Future<int> total() async {
    final fotos = await obtenerTodas();
    return fotos.length;
  }
}
