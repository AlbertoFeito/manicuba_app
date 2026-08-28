import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/business_config.dart';

/// Licencia por dispositivo y por rubro, verificada 100% sin conexión.
///
/// Cada instalación muestra un "código de equipo" (uno solo, compartido por
/// todos los rubros del dispositivo). El vendedor lo convierte en una
/// licencia con el generador (que guarda el secreto y el rubro elegido) y se
/// la envía; la app la comprueba localmente, sin red. Una licencia solo
/// activa el rubro para el que se generó: activar "Manicura" no da acceso a
/// "Spa" en el mismo equipo — cada rubro es un producto con su propio pago y
/// su propia prueba gratuita de 15 días. No pretende resistir que alguien
/// desempaquete el APK: es fricción contra la copia casual.
class LicenciaService {
  LicenciaService._();
  static final LicenciaService instance = LicenciaService._();

  /// Alfabeto base32 legible (sin I, L, O, U) para leer códigos en voz alta.
  static const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static const int trialDays = 15;
  static const int _deviceChars = 10;
  static const int _licenceChars = 16;

  static const String _kDeviceId = 'lic_device_id';

  /// El estado de prueba/licencia se guarda por rubro: cada [BusinessType]
  /// tiene su propia key de `SharedPreferences`.
  static String _kTrialStart(BusinessType tipo) => 'lic_trial_started_at_${tipo.name}';
  static String _kLicenseKey(BusinessType tipo) => 'lic_license_key_${tipo.name}';

  /// Secreto de firma, inyectado al compilar con
  /// `--dart-define=LICENSE_SECRET=...`. El valor por defecto solo permite
  /// desarrollar; si se publica así, todas las instalaciones comparten códigos
  /// conocidos. Es un único secreto de compilación para toda la app — lo que
  /// diferencia una licencia de otra es el rubro incluido en el mensaje
  /// firmado (ver [computeLicence]), no el secreto.
  static const String _secret = String.fromEnvironment(
    'LICENSE_SECRET',
    defaultValue: 'gestorpro-dev-secret',
  );

  bool get usandoSecretoDev => _secret == 'gestorpro-dev-secret';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ===== Codificación =====

  static String _toBase32(List<int> bytes, int length) {
    var bits = 0;
    var value = 0;
    final out = StringBuffer();
    for (final byte in bytes) {
      value = ((value << 8) | byte) & 0xFFFFFFFF;
      bits += 8;
      while (bits >= 5) {
        out.write(_alphabet[(value >> (bits - 5)) & 31]);
        bits -= 5;
        value = value & ((1 << bits) - 1);
        if (out.length == length) {
          return out.toString();
        }
      }
    }
    var result = out.toString();
    while (result.length < length) {
      result += _alphabet[0];
    }
    return result;
  }

  /// Separa el código en grupos para leerlo y escribirlo más fácil.
  static String group(String code, int size) {
    final matches = RegExp('.{1,$size}').allMatches(code);
    return matches.map((m) => m.group(0)).join('-');
  }

  /// Quita el formato y corrige sustituciones al copiar a mano: I/L→1, O→0.
  static String normalizeCode(String raw) {
    return raw
        .toUpperCase()
        .replaceAll(RegExp('[^0-9A-Z]'), '')
        .replaceAll(RegExp('[IL]'), '1')
        .replaceAll('O', '0');
  }

  static String _newDeviceId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return _toBase32(bytes, _deviceChars);
  }

  /// El mensaje firmado incluye el rubro: una licencia generada para
  /// [BusinessType.manicura] no sirve para activar [BusinessType.spa] en el
  /// mismo dispositivo, aunque ambas usen el mismo [secret] de compilación.
  static String computeLicence(String deviceId, String secret, BusinessType tipo) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(
      utf8.encode('app:v1:${tipo.name}:${normalizeCode(deviceId)}'),
    );
    return _toBase32(digest.bytes, _licenceChars);
  }

  /// Comprueba si [licence] es el código correcto para [deviceId] y [tipo].
  static bool verifyLicence(String deviceId, String licence, String secret, BusinessType tipo) {
    final expected = computeLicence(deviceId, secret, tipo);
    final given = normalizeCode(licence);
    if (given.length != expected.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ given.codeUnitAt(i);
    }
    return diff == 0;
  }

  // ===== Estado / persistencia =====

  BusinessType get _tipoActivo => AppConfig.instance.current.tipo;

  /// Asegura que exista el código de equipo (global) y la fecha de inicio
  /// de prueba del rubro activo.
  Future<void> init() async {
    final sp = await _sp;
    if (sp.getString(_kDeviceId) == null) {
      await sp.setString(_kDeviceId, _newDeviceId());
    }
    final trialKey = _kTrialStart(_tipoActivo);
    if (sp.getString(trialKey) == null) {
      await sp.setString(trialKey, DateTime.now().toIso8601String());
    }
  }

  Future<String> deviceId() async {
    await init();
    return (await _sp).getString(_kDeviceId)!;
  }

  Future<bool> estaLicenciado({BusinessType? tipo}) async {
    final key = (await _sp).getString(_kLicenseKey(tipo ?? _tipoActivo));
    return key != null && key.isNotEmpty;
  }

  /// Intenta activar [codigo] para [tipo] (por defecto, el rubro activo); si
  /// es válido, lo guarda y devuelve true. Un código válido para otro rubro
  /// no activa este.
  Future<bool> activar(String codigo, {BusinessType? tipo}) async {
    final t = tipo ?? _tipoActivo;
    final id = await deviceId();
    if (!verifyLicence(id, codigo, _secret, t)) {
      return false;
    }
    await (await _sp).setString(_kLicenseKey(t), normalizeCode(codigo));
    return true;
  }

  /// Estado de licencia/prueba del rubro [tipo] (por defecto, el activo).
  /// Cada rubro tiene su propio ciclo de prueba de 15 días, independiente
  /// de si otros rubros ya están licenciados en este mismo dispositivo.
  Future<LicenciaEstado> estado({BusinessType? tipo, DateTime? ahora}) async {
    await init();
    final t = tipo ?? _tipoActivo;
    final sp = await _sp;
    final licenciado = await estaLicenciado(tipo: t);
    return calcularEstado(
      licenciado: licenciado,
      trialStartedAt: sp.getString(_kTrialStart(t)),
      ahora: ahora ?? DateTime.now(),
    );
  }

  /// Estado de la instalación para un rubro. Una licencia activa nunca
  /// caduca; si no, la prueba dura [trialDays] desde el primer arranque de
  /// ese rubro.
  static LicenciaEstado calcularEstado({
    required bool licenciado,
    String? trialStartedAt,
    required DateTime ahora,
  }) {
    if (licenciado) {
      return const LicenciaEstado(LicenciaTipo.activa, 0);
    }
    if (trialStartedAt == null) {
      return const LicenciaEstado(LicenciaTipo.prueba, trialDays);
    }
    final inicio = DateTime.tryParse(trialStartedAt);
    if (inicio == null) {
      return const LicenciaEstado(LicenciaTipo.prueba, trialDays);
    }
    final diasPasados = ahora.difference(inicio).inDays;
    final diasRestantes = trialDays - diasPasados;
    // Un reloj atrasado no debe alargar la prueba más allá de su duración.
    if (diasRestantes > trialDays) {
      return const LicenciaEstado(LicenciaTipo.prueba, trialDays);
    }
    if (diasRestantes <= 0) {
      return const LicenciaEstado(LicenciaTipo.vencida, 0);
    }
    return LicenciaEstado(LicenciaTipo.prueba, diasRestantes);
  }

  static String formatDeviceId(String id) => group(id, 5);
  static String formatLicence(String code) => group(code, 4);
}

enum LicenciaTipo { activa, prueba, vencida }

class LicenciaEstado {
  const LicenciaEstado(this.tipo, this.diasRestantes);
  final LicenciaTipo tipo;
  final int diasRestantes;
}
