// Pruebas de la lógica de licencia (offline).

import 'package:flutter_test/flutter_test.dart';

import 'package:gestorpro_app/config/business_config.dart';
import 'package:gestorpro_app/services/licencia_service.dart';

void main() {
  const secret = 'secreto-de-prueba';
  const tipo = BusinessType.manicura;

  test('La licencia calculada verifica para su dispositivo', () {
    const device = '7K3M92QXBD';
    final lic = LicenciaService.computeLicence(device, secret, tipo);
    expect(LicenciaService.verifyLicence(device, lic, secret, tipo), isTrue);
    // Un código incorrecto no valida.
    expect(
        LicenciaService.verifyLicence(
            device, 'AAAA1111BBBB2222', secret, tipo),
        isFalse);
    // El mismo código con secreto distinto tampoco.
    expect(LicenciaService.verifyLicence(device, lic, 'otro-secreto', tipo),
        isFalse);
  });

  test('La misma licencia no verifica para otro rubro', () {
    const device = '7K3M92QXBD';
    final lic = LicenciaService.computeLicence(device, secret, tipo);
    expect(
        LicenciaService.verifyLicence(
            device, lic, secret, BusinessType.spa),
        isFalse);
  });

  test('normalizeCode corrige I/L/O y quita formato', () {
    // I y L -> 1, O -> 0, se ignoran guiones y minúsculas.
    expect(LicenciaService.normalizeCode('il-o0-1'), '11001');
  });

  test('Estado de prueba: cuenta los días restantes', () {
    final ahora = DateTime(2026, 1, 20);
    final estado = LicenciaService.calcularEstado(
      licenciado: false,
      trialStartedAt: DateTime(2026, 1, 15).toIso8601String(),
      ahora: ahora,
    );
    expect(estado.tipo, LicenciaTipo.prueba);
    expect(estado.diasRestantes, LicenciaService.trialDays - 5);
  });

  test('Estado vencido cuando pasan los 15 días', () {
    final estado = LicenciaService.calcularEstado(
      licenciado: false,
      trialStartedAt: DateTime(2026, 1, 1).toIso8601String(),
      ahora: DateTime(2026, 1, 20),
    );
    expect(estado.tipo, LicenciaTipo.vencida);
    expect(estado.diasRestantes, 0);
  });

  test('Con licencia el estado es activa y no vence', () {
    final estado = LicenciaService.calcularEstado(
      licenciado: true,
      trialStartedAt: DateTime(2020, 1, 1).toIso8601String(),
      ahora: DateTime(2026, 1, 20),
    );
    expect(estado.tipo, LicenciaTipo.activa);
  });

  test('Un reloj atrasado no alarga la prueba', () {
    final estado = LicenciaService.calcularEstado(
      licenciado: false,
      trialStartedAt: DateTime(2026, 6, 1).toIso8601String(),
      ahora: DateTime(2026, 1, 1), // "antes" de empezar
    );
    expect(estado.tipo, LicenciaTipo.prueba);
    expect(estado.diasRestantes, LicenciaService.trialDays);
  });
}
