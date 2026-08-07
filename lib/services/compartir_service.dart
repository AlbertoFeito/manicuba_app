import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/post_redes.dart';
import 'foto_service.dart';

/// Cómo terminó un intento de compartir un post.
enum ModoCompartir { appDirecta, hojaSistema, textoPegar, fallo }

/// Decide, según la plataforma del post, si conviene abrir WhatsApp
/// directo y/o copiar el texto al portapapeles antes de compartir.
class PlanCompartir {
  const PlanCompartir({
    required this.intentarWhatsApp,
    required this.copiarTexto,
  });

  final bool intentarWhatsApp;
  final bool copiarTexto;
}

/// Instagram y Facebook ignoran por política propia el texto pre-rellenado
/// de sus intents de compartir; solo WhatsApp lo respeta. Para esas dos (y
/// para WhatsApp cuando hay fotos, que no se pueden adjuntar al deep link)
/// se copia el texto al portapapeles para que la usuaria lo pegue.
PlanCompartir planificarCompartir(
  String plataforma, {
  required bool conFotos,
}) {
  final p = plataforma.toLowerCase();
  if (p == 'whatsapp' && !conFotos) {
    return const PlanCompartir(intentarWhatsApp: true, copiarTexto: false);
  }
  if (p == 'whatsapp' || p == 'instagram' || p == 'facebook') {
    return const PlanCompartir(intentarWhatsApp: false, copiarTexto: true);
  }
  return const PlanCompartir(intentarWhatsApp: false, copiarTexto: false);
}

/// Comparte un post de Redes Sociales, intentando abrir la app de su
/// plataforma directamente cuando es posible.
class CompartirService {
  CompartirService({FotoService? fotoService})
      : _fotos = fotoService ?? FotoService();

  final FotoService _fotos;

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
    final plan = planificarCompartir(
      post.plataforma,
      conFotos: archivos.isNotEmpty,
    );

    if (plan.intentarWhatsApp && await _abrirWhatsApp(texto)) {
      return ModoCompartir.appDirecta;
    }

    if (plan.copiarTexto) {
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

    return plan.copiarTexto
        ? ModoCompartir.textoPegar
        : ModoCompartir.hojaSistema;
  }

  Future<bool> _abrirWhatsApp(String texto) async {
    try {
      final uri = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(texto)}',
      );
      if (!await canLaunchUrl(uri)) {
        return false;
      }
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }
}
