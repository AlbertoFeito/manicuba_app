// Parte del Asistente de Promociones (ver docs/ASISTENTE_PROMOCIONES.md).
//
// Persistencia del perfil del negocio en SharedPreferences, con una clave por
// rubro (igual que AppConfig/LicenciaService): el perfil de "Manicura" es
// independiente del de "Spa" en el mismo dispositivo.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/business_config.dart';
import '../models/perfil_negocio.dart';

class PerfilService {
  PerfilService._();
  static final PerfilService instance = PerfilService._();

  static String _key(BusinessType tipo) => 'perfil_negocio_${tipo.name}';

  BusinessType get _tipoActivo => AppConfig.instance.current.tipo;

  /// Perfil por defecto de un rubro que aún no ha guardado nada: solo el
  /// nombre del negocio, tomado del [BusinessConfig] del rubro.
  static PerfilNegocio porDefecto(BusinessType tipo) =>
      PerfilNegocio(nombreNegocio: kBusinessConfigs[tipo]!.appName);

  /// Devuelve el perfil guardado del rubro [tipo] (por defecto, el activo), o
  /// el perfil por defecto del rubro si nunca se guardó ninguno.
  Future<PerfilNegocio> obtener({BusinessType? tipo}) async {
    final t = tipo ?? _tipoActivo;
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key(t));
    if (raw == null || raw.isEmpty) {
      return porDefecto(t);
    }
    try {
      return PerfilNegocio.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      // Un valor corrupto no debe romper la app: se vuelve al perfil base.
      return porDefecto(t);
    }
  }

  /// Guarda el perfil del rubro [tipo] (por defecto, el activo).
  Future<void> guardar(PerfilNegocio perfil, {BusinessType? tipo}) async {
    final t = tipo ?? _tipoActivo;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key(t), jsonEncode(perfil.toJson()));
  }

  /// ¿Hay un perfil guardado para el rubro [tipo]? Útil para invitar a
  /// completarlo la primera vez.
  Future<bool> existe({BusinessType? tipo}) async {
    final t = tipo ?? _tipoActivo;
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key(t));
    return raw != null && raw.isNotEmpty;
  }
}
