import 'package:flutter/services.dart';

/// Puente al canal nativo de Android (ver MainActivity.kt) que abre
/// WhatsApp/Instagram/Facebook directo con texto y fotos adjuntas — algo
/// que ningún paquete de pub.dev permite hacer hoy (el selector genérico
/// de `share_plus` no puede apuntar a una app específica).
class CompartirNativo {
  static const _canal = MethodChannel('pelucuba/compartir');

  /// Intenta abrir [paquete] (p. ej. "com.whatsapp") con [texto] y las
  /// fotos en [rutas]. Devuelve `false` si la app no está instalada, el
  /// canal no existe (plataformas que no sean Android) o algo falla.
  Future<bool> compartirEnApp({
    required List<String> rutas,
    required String texto,
    required String paquete,
  }) async {
    try {
      final ok = await _canal.invokeMethod<bool>('compartirEnApp', {
        'rutas': rutas,
        'texto': texto,
        'paquete': paquete,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
