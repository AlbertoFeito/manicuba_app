// Pruebas de PerfilService: ida y vuelta en SharedPreferences, aislamiento
// por rubro y perfil por defecto desde business_config.

import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/config/business_config.dart';
import 'package:multiservicios_app/models/perfil_negocio.dart';
import 'package:multiservicios_app/services/perfil_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final servicio = PerfilService.instance;

  setUp(() {
    // Cada test arranca con almacenamiento limpio.
    SharedPreferences.setMockInitialValues({});
    AppConfig.instance.reset();
  });

  test('sin nada guardado devuelve el perfil por defecto del rubro', () async {
    final perfil = await servicio.obtener(tipo: BusinessType.manicura);
    expect(
      perfil.nombreNegocio,
      kBusinessConfigs[BusinessType.manicura]!.appName,
    );
    expect(perfil.telefono, isNull);
    expect(await servicio.existe(tipo: BusinessType.manicura), isFalse);
  });

  test('guardar y obtener conserva todos los campos', () async {
    const perfil = PerfilNegocio(
      nombreNegocio: 'Uñas de Rosa',
      telefono: '+53 5555 1234',
      direccion: 'Calle 23',
      horario: 'L-V 9 a 18',
      instagram: 'unasderosa',
      facebook: 'UnasDeRosa',
      whatsapp: '+53 5555 1234',
    );
    await servicio.guardar(perfil, tipo: BusinessType.manicura);

    final leido = await servicio.obtener(tipo: BusinessType.manicura);
    expect(leido.nombreNegocio, 'Uñas de Rosa');
    expect(leido.telefono, '+53 5555 1234');
    expect(leido.direccion, 'Calle 23');
    expect(leido.horario, 'L-V 9 a 18');
    expect(leido.instagram, 'unasderosa');
    expect(leido.facebook, 'UnasDeRosa');
    expect(leido.whatsapp, '+53 5555 1234');
    expect(await servicio.existe(tipo: BusinessType.manicura), isTrue);
  });

  test('el perfil de un rubro no se mezcla con el de otro', () async {
    await servicio.guardar(
      const PerfilNegocio(nombreNegocio: 'Salón Manicura'),
      tipo: BusinessType.manicura,
    );
    await servicio.guardar(
      const PerfilNegocio(nombreNegocio: 'Salón Peluquería'),
      tipo: BusinessType.peluqueria,
    );

    expect(
      (await servicio.obtener(tipo: BusinessType.manicura)).nombreNegocio,
      'Salón Manicura',
    );
    expect(
      (await servicio.obtener(tipo: BusinessType.peluqueria)).nombreNegocio,
      'Salón Peluquería',
    );
    // El rubro spa, sin guardar, sigue con su valor por defecto.
    expect(
      (await servicio.obtener(tipo: BusinessType.spa)).nombreNegocio,
      kBusinessConfigs[BusinessType.spa]!.appName,
    );
  });

  test('usa el rubro activo cuando no se pasa tipo', () async {
    AppConfig.instance.setBusinessType(BusinessType.spa);
    await servicio.guardar(const PerfilNegocio(nombreNegocio: 'Spa Zen'));
    expect((await servicio.obtener()).nombreNegocio, 'Spa Zen');
    // Y quedó guardado bajo la clave del rubro spa.
    expect(
      (await servicio.obtener(tipo: BusinessType.spa)).nombreNegocio,
      'Spa Zen',
    );
  });
}
