import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/post_redes.dart';
import 'compartir_nativo.dart';
import 'foto_service.dart';

/// Cómo terminó un intento de compartir un post.
enum ModoCompartir { appDirecta, hojaSistema, textoPegar, fallo }

/// Paquete Android de la app a abrir directo según la plataforma del post,
/// o `null` si no hay una app específica que abrir (p. ej. "Todas").
String? paqueteParaPlataforma(String plataforma) {
  switch (plataforma.toLowerCase()) {
    case 'whatsapp':
      return 'com.whatsapp';
    case 'instagram':
      return 'com.instagram.android';
    case 'facebook':
      return 'com.facebook.katana';
    default:
      return null;
  }
}

/// Instagram y Facebook ignoran, por política propia, el texto que llega
/// en el intent para compartir (a diferencia de WhatsApp, que sí lo usa),
/// así que además hay que copiarlo al portapapeles para que se pueda pegar.
bool ignoraTextoPrellenado(String plataforma) =>
    plataforma.toLowerCase() != 'whatsapp';

/// Comparte un post de Redes Sociales, abriendo la app de su plataforma
/// directo cuando es posible (WhatsApp/Instagram/Facebook), con las fotos
/// adjuntas. Si la app no está instalada o algo falla, cae al selector del
/// sistema.
class CompartirService {
  CompartirService({FotoService? fotoService, CompartirNativo? nativo})
      : _fotos = fotoService ?? FotoService(),
        _nativo = nativo ?? CompartirNativo();

  final FotoService _fotos;
  final CompartirNativo _nativo;

  /// Rutas reales de las fotos del post que todavía existen en disco.
  Future<List<XFile>> archivosDePost(PostRedes post) async {
    final fotos = await _fotos.obtenerPorIds(post.listaFotoIds);
    return fotos
        .where((f) => File(f.rutaFoto).existsSync())
        .map((f) => XFile(f.rutaFoto))
        .toList();
  }

  Future<ModoCompartir> compartirPost(PostRedes post) async {
    final texto = post.getContenidoFormateado();
    final archivos = await archivosDePost(post);
    final paquete = paqueteParaPlataforma(post.plataforma);

    if (paquete != null) {
      final rutas = await _copiarACache(archivos);
      final abierta = await _nativo.compartirEnApp(
        rutas: rutas,
        texto: texto,
        paquete: paquete,
      );
      if (abierta) {
        if (ignoraTextoPrellenado(post.plataforma)) {
          await Clipboard.setData(ClipboardData(text: texto));
          return ModoCompartir.textoPegar;
        }
        return ModoCompartir.appDirecta;
      }
      // La app no está instalada o falló: se copia el texto igual, porque
      // el selector genérico que sigue no sabe a qué app apuntaba.
      await Clipboard.setData(ClipboardData(text: texto));
    }

    try {
      if (archivos.isEmpty) {
        await Share.share(texto, subject: post.titulo);
      } else {
        await Share.shareXFiles(archivos, subject: post.titulo, text: texto);
      }
    } on PlatformException {
      return ModoCompartir.fallo;
    }

    return paquete != null
        ? ModoCompartir.textoPegar
        : ModoCompartir.hojaSistema;
  }

  /// Copia las fotos a compartir a la carpeta de caché servida por el
  /// FileProvider nativo (ver MainActivity.kt y res/xml/file_paths.xml) —
  /// el intent nativo solo puede adjuntar archivos desde ahí.
  Future<List<String>> _copiarACache(List<XFile> archivos) async {
    if (archivos.isEmpty) {
      return [];
    }
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'compartir'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final rutas = <String>[];
    for (var i = 0; i < archivos.length; i++) {
      final origen = File(archivos[i].path);
      final destino = p.join(
        dir.path,
        'foto_${DateTime.now().microsecondsSinceEpoch}_$i'
        '${p.extension(origen.path)}',
      );
      await origen.copy(destino);
      rutas.add(destino);
    }
    return rutas;
  }
}
