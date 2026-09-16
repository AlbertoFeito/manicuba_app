// Pruebas del flujo con persistencia de LicenciaService (sobre el
// SharedPreferences simulado del harness), además de los helpers de formato.
//
// Las pruebas de la lógica pura (computeLicence/verify/calcularEstado) están
// en licencia_test.dart; aquí se cubre init/deviceId/activar/estaLicenciado/
// estado/rubrosHabilitados, que leen y escriben en almacenamiento.
//
// Los tests comparten el singleton LicenciaService.instance y corren en orden
// de declaración: primero los que asumen "sin licencia" (prueba gratis, con
// acceso libre a todos los rubros), y al final la activación de un plan
// (que deja el estado como licenciado y aplica el cupo de servicios).

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/config/business_config.dart';
import 'package:multiservicios_app/services/licencia_service.dart';

// Debe coincidir con el defaultValue de _secret cuando no se compila con
// --dart-define=LICENSE_SECRET (el caso de los tests).
const _secretoDev = 'multiservicios-dev-secret';

void main() {
  final servicio = LicenciaService.instance;

  test('En tests se usa el secreto de desarrollo', () {
    expect(servicio.usandoSecretoDev, isTrue);
  });

  test('group y los formateadores agrupan el código', () {
    expect(LicenciaService.group('ABCDEFGH', 4), 'ABCD-EFGH');
    expect(LicenciaService.formatDeviceId('ABCDEFGHIJ'), 'ABCDE-FGHIJ');
    expect(LicenciaService.formatLicence('ABCDEFGH'), 'ABCD-EFGH');
  });

  test('deviceId es estable, no vacío y con longitud fija', () async {
    final id1 = await servicio.deviceId();
    final id2 = await servicio.deviceId();
    expect(id1, isNotEmpty);
    expect(id1, id2); // init() es idempotente: no regenera el id
    expect(id1.length, 10);
  });

  test('Sin licencia, empieza sin ningún rubro habilitado', () async {
    expect(await servicio.rubrosHabilitados(), isEmpty);
    expect(await servicio.planActivo(), isNull);
  });

  test('Durante la prueba gratis, cualquier rubro se puede habilitar',
      () async {
    for (final tipo in BusinessType.values) {
      expect(await servicio.puedeHabilitar(tipo), isTrue);
    }
  });

  test('habilitarRubro agrega al conjunto sin duplicar', () async {
    await servicio.habilitarRubro(BusinessType.manicura);
    await servicio.habilitarRubro(BusinessType.spa);
    await servicio.habilitarRubro(BusinessType.manicura); // repetido

    final habilitados = await servicio.rubrosHabilitados();
    expect(habilitados, {BusinessType.manicura, BusinessType.spa});
  });

  test('activar rechaza un código inválido y no licencia', () async {
    final ok = await servicio.activar('CODIGO-INVALIDO-0000');
    expect(ok, isFalse);
    expect(await servicio.estaLicenciado(), isFalse);
    expect(await servicio.planActivo(), isNull);

    // Sin licencia, el estado no es "activa".
    final estado = await servicio.estado();
    expect(estado.tipo, isNot(LicenciaTipo.activa));
  });

  test(
      'activar con un código de plan Básico aplica el cupo de 1 servicio '
      'y conserva el rubro preferido', () async {
    final id = await servicio.deviceId();
    final codigo = LicenciaService.computeLicence(
      id,
      _secretoDev,
      PlanLicencia.basico,
    );

    // Antes de activar, la prueba habilitó "manicura" y "spa" (2 rubros).
    expect(await servicio.rubrosHabilitados(), hasLength(2));

    final ok = await servicio.activar(
      codigo,
      rubroPreferido: BusinessType.spa,
    );
    expect(ok, isTrue);
    expect(await servicio.estaLicenciado(), isTrue);
    expect(await servicio.planActivo(), PlanLicencia.basico);

    // Ya licenciado, el estado es activa (leído desde persistencia).
    final estado = await servicio.estado();
    expect(estado.tipo, LicenciaTipo.activa);

    // El plan Básico solo permite 1: se conservó el preferido y se soltó
    // el resto.
    expect(await servicio.rubrosHabilitados(), {BusinessType.spa});

    // Ya no hay cupo para habilitar un rubro nuevo, pero el que ya está
    // habilitado se puede seguir usando.
    expect(await servicio.puedeHabilitar(BusinessType.spa), isTrue);
    expect(await servicio.puedeHabilitar(BusinessType.peluqueria), isFalse);
  });
}
