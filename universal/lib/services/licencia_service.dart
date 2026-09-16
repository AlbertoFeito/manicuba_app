import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/business_config.dart';

/// Planes comerciales de Multiservicios. El plan contratado determina
/// cuántos rubros de negocio (de los que existen en [BusinessType]) puede
/// tener habilitados el mismo dispositivo al mismo tiempo — no cuáles, sino
/// cuántos: el dueño elige libremente qué rubros usar dentro de ese cupo.
enum PlanLicencia { basico, pro, premium }

extension PlanLicenciaInfo on PlanLicencia {
  String get label {
    switch (this) {
      case PlanLicencia.basico:
        return 'Básico';
      case PlanLicencia.pro:
        return 'Pro';
      case PlanLicencia.premium:
        return 'Premium';
    }
  }

  /// Cantidad máxima de rubros que puede tener habilitados a la vez un
  /// dispositivo con este plan. Premium no tiene límite real: se expresa
  /// como "todos los rubros que existan hoy".
  int get maxServicios {
    switch (this) {
      case PlanLicencia.basico:
        return 1;
      case PlanLicencia.pro:
        return 2;
      case PlanLicencia.premium:
        return BusinessType.values.length;
    }
  }
}

/// Licencia por dispositivo, verificada 100% sin conexión.
///
/// Cada instalación muestra un "código de equipo" único. El vendedor lo
/// convierte en una licencia con el generador (que guarda el secreto y el
/// plan elegido) y se la envía; la app la comprueba localmente, sin red. Una
/// sola licencia desbloquea toda la app: lo que varía según el plan
/// contratado ([PlanLicencia]) es cuántos rubros de negocio puede tener
/// habilitados el dispositivo a la vez (ver [rubrosHabilitados]). No
/// pretende resistir que alguien desempaquete el APK: es fricción contra la
/// copia casual.
class LicenciaService {
  LicenciaService._();
  static final LicenciaService instance = LicenciaService._();

  /// Alfabeto base32 legible (sin I, L, O, U) para leer códigos en voz alta.
  static const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static const int trialDays = 15;
  static const int _deviceChars = 10;
  static const int _licenceChars = 16;

  static const String _kDeviceId = 'lic_device_id';
  static const String _kTrialStart = 'lic_trial_started_at';
  static const String _kLicenseKey = 'lic_license_key';
  static const String _kLicensePlan = 'lic_license_plan';
  static const String _kRubrosHabilitados = 'lic_rubros_habilitados';

  /// Secreto de firma, inyectado al compilar con
  /// `--dart-define=LICENSE_SECRET=...`. El valor por defecto solo permite
  /// desarrollar; si se publica así, todas las instalaciones comparten
  /// códigos conocidos. Es un único secreto de compilación para toda la
  /// app — lo que diferencia una licencia de otra es el plan incluido en el
  /// mensaje firmado (ver [computeLicence]), no el secreto.
  static const String _secret = String.fromEnvironment(
    'LICENSE_SECRET',
    defaultValue: 'multiservicios-dev-secret',
  );

  bool get usandoSecretoDev => _secret == 'multiservicios-dev-secret';

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

  /// El mensaje firmado incluye el plan: una licencia generada para
  /// [PlanLicencia.basico] no sirve para activar [PlanLicencia.premium] en
  /// el mismo dispositivo, aunque ambas usen el mismo [secret] de
  /// compilación.
  static String computeLicence(String deviceId, String secret, PlanLicencia plan) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(
      utf8.encode('app:v2:plan:${plan.name}:${normalizeCode(deviceId)}'),
    );
    return _toBase32(digest.bytes, _licenceChars);
  }

  /// Comprueba si [licence] es el código correcto para [deviceId] y [plan].
  static bool verifyLicence(String deviceId, String licence, String secret, PlanLicencia plan) {
    final expected = computeLicence(deviceId, secret, plan);
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

  /// Asegura que exista el código de equipo y la fecha de inicio de la
  /// prueba (ambos globales, no dependen del rubro activo).
  Future<void> init() async {
    final sp = await _sp;
    if (sp.getString(_kDeviceId) == null) {
      await sp.setString(_kDeviceId, _newDeviceId());
    }
    if (sp.getString(_kTrialStart) == null) {
      await sp.setString(_kTrialStart, DateTime.now().toIso8601String());
    }
  }

  Future<String> deviceId() async {
    await init();
    return (await _sp).getString(_kDeviceId)!;
  }

  Future<bool> estaLicenciado() async {
    final key = (await _sp).getString(_kLicenseKey);
    return key != null && key.isNotEmpty;
  }

  /// Plan activo, si ya hay una licencia comprada. `null` durante la prueba
  /// o si la prueba venció sin activar nada.
  Future<PlanLicencia?> planActivo() async {
    final nombre = (await _sp).getString(_kLicensePlan);
    if (nombre == null) return null;
    for (final p in PlanLicencia.values) {
      if (p.name == nombre) return p;
    }
    return null;
  }

  /// Rubros que el dispositivo ya tiene habilitados (ver clase). Vacío en
  /// una instalación nueva; se va llenando con [habilitarRubro].
  Future<Set<BusinessType>> rubrosHabilitados() async {
    final raw = (await _sp).getString(_kRubrosHabilitados);
    if (raw == null || raw.isEmpty) return {};
    final nombres = raw.split(',').toSet();
    return BusinessType.values.where((t) => nombres.contains(t.name)).toSet();
  }

  Future<void> _guardarHabilitados(Set<BusinessType> rubros) async {
    await (await _sp).setString(
      _kRubrosHabilitados,
      rubros.map((t) => t.name).join(','),
    );
  }

  /// Indica si [tipo] puede usarse en este dispositivo: ya habilitado, en
  /// prueba (acceso libre a todo mientras dura), o si todavía hay cupo
  /// libre en el plan activo.
  Future<bool> puedeHabilitar(BusinessType tipo) async {
    final habilitados = await rubrosHabilitados();
    if (habilitados.contains(tipo)) return true;

    final est = await estado();
    if (est.tipo == LicenciaTipo.prueba) return true;
    if (est.tipo == LicenciaTipo.vencida) return false;

    final plan = await planActivo();
    if (plan == null) return false;
    return habilitados.length < plan.maxServicios;
  }

  /// Marca [tipo] como habilitado en este dispositivo. Llamar solo después
  /// de confirmar [puedeHabilitar].
  Future<void> habilitarRubro(BusinessType tipo) async {
    final habilitados = await rubrosHabilitados();
    if (habilitados.contains(tipo)) return;
    await _guardarHabilitados({...habilitados, tipo});
  }

  /// Intenta activar [codigo] para este dispositivo. El código lleva
  /// implícito el plan (se prueba contra cada uno); si coincide con
  /// alguno, se guarda como licencia activa y devuelve true. Si el plan
  /// comprado tiene menos cupo que rubros ya habilitados (p. ej. se
  /// probaron los 3 en la prueba gratis y se compra Básico), se conserva
  /// solo [rubroPreferido] (o el primero que hubiera, si no se indica) y
  /// se sueltan los demás — sus datos no se borran, solo dejan de ser
  /// accesibles hasta subir de plan.
  Future<bool> activar(String codigo, {BusinessType? rubroPreferido}) async {
    final id = await deviceId();
    for (final plan in PlanLicencia.values) {
      if (verifyLicence(id, codigo, _secret, plan)) {
        final sp = await _sp;
        await sp.setString(_kLicenseKey, normalizeCode(codigo));
        await sp.setString(_kLicensePlan, plan.name);

        final habilitados = await rubrosHabilitados();
        if (habilitados.length > plan.maxServicios) {
          final conservar = (rubroPreferido != null && habilitados.contains(rubroPreferido))
              ? rubroPreferido
              : habilitados.first;
          await _guardarHabilitados({conservar});
        }
        return true;
      }
    }
    return false;
  }

  /// Estado global de la instalación (prueba/activa/vencida). Ya no depende
  /// del rubro: una sola licencia cubre todo el dispositivo.
  Future<LicenciaEstado> estado({DateTime? ahora}) async {
    await init();
    final sp = await _sp;
    final licenciado = await estaLicenciado();
    return calcularEstado(
      licenciado: licenciado,
      trialStartedAt: sp.getString(_kTrialStart),
      ahora: ahora ?? DateTime.now(),
    );
  }

  /// Estado de la instalación. Una licencia activa nunca caduca; si no, la
  /// prueba dura [trialDays] desde el primer arranque de la app.
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
