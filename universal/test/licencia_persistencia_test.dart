// Pruebas del flujo con persistencia de LicenciaService (sobre el
// SharedPreferences simulado del harness), además de los helpers de formato.
//
// Las pruebas de la lógica pura (computeLicence/verify/calcularEstado) están
// en licencia_test.dart; aquí se cubre init/deviceId/activar/estaLicenciado/
// estado, que leen y escriben en almacenamiento.
//
// Los tests comparten el singleton LicenciaService.instance y corren en orden
// de declaración: primero los que asumen "sin licencia", y al final la
// activación (que deja el estado como licenciado).

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/config/business_config.dart';
import 'package:multiservicios_app/services/licencia_service.dart';

// Debe coincidir con el defaultValue de _secret cuando no se compila con
// --dart-define=LICENSE_SECRET (el caso de los tests).
const _secretoDev = 'multiservicios-dev-secret';

// AppConfig.instance.current empieza en "manicura" por defecto (ver
// business_config.dart) hasta que algo llame a setBusinessType.
const _tipo = BusinessType.manicura;

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

  test('activar rechaza un código inválido y no licencia', () async {
    final ok = await servicio.activar('CODIGO-INVALIDO-0000');
    expect(ok, isFalse);
    expect(await servicio.estaLicenciado(), isFalse);

    // Sin licencia, el estado no es "activa".
    final estado = await servicio.estado();
    expect(estado.tipo, isNot(LicenciaTipo.activa));
  });

  test('activar acepta el código correcto y queda licenciado', () async {
    final id = await servicio.deviceId();
    final codigo = LicenciaService.computeLicence(id, _secretoDev, _tipo);

    final ok = await servicio.activar(codigo);
    expect(ok, isTrue);
    expect(await servicio.estaLicenciado(), isTrue);

    // Ya licenciado, el estado es activa (leído desde persistencia).
    final estado = await servicio.estado();
    expect(estado.tipo, LicenciaTipo.activa);
  });
}
