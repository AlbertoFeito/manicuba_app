// Pruebas del modelo PerfilNegocio: serialización, copyWith y los helpers
// de presentación (instagramMostrado, pieDePromo).

import 'package:flutter_test/flutter_test.dart';

import 'package:multiservicios_app/models/perfil_negocio.dart';

void main() {
  test('toJson/fromJson es de ida y vuelta', () {
    const perfil = PerfilNegocio(
      nombreNegocio: 'Bella',
      telefono: '5551',
      direccion: 'Centro',
      horario: '9-18',
      instagram: '@bella',
      facebook: 'BellaFB',
      whatsapp: '5552',
    );
    final copia = PerfilNegocio.fromJson(perfil.toJson());
    expect(copia.nombreNegocio, 'Bella');
    expect(copia.telefono, '5551');
    expect(copia.direccion, 'Centro');
    expect(copia.horario, '9-18');
    expect(copia.instagram, '@bella');
    expect(copia.facebook, 'BellaFB');
    expect(copia.whatsapp, '5552');
  });

  test('copyWith cambia solo lo indicado', () {
    const perfil = PerfilNegocio(nombreNegocio: 'A', telefono: '1');
    final b = perfil.copyWith(telefono: '2');
    expect(b.nombreNegocio, 'A');
    expect(b.telefono, '2');
  });

  test('instagramMostrado antepone @ solo si falta', () {
    const sinArroba = PerfilNegocio(nombreNegocio: 'x', instagram: 'uña');
    const conArroba = PerfilNegocio(nombreNegocio: 'x', instagram: '@uña');
    expect(sinArroba.instagramMostrado, '@uña');
    expect(conArroba.instagramMostrado, '@uña');
    expect(
      const PerfilNegocio(nombreNegocio: 'x').instagramMostrado,
      isNull,
    );
  });

  test('pieDePromo arma el bloque de contacto con lo que hay', () {
    const perfil = PerfilNegocio(
      nombreNegocio: 'x',
      telefono: '5551',
      instagram: 'salon',
      direccion: 'Calle 1',
    );
    final pie = perfil.pieDePromo();
    expect(pie, contains('📞 5551'));
    expect(pie, contains('📸 @salon'));
    expect(pie, contains('📍 Calle 1'));
  });

  test('pieDePromo vacío si no hay datos de contacto', () {
    expect(const PerfilNegocio(nombreNegocio: 'x').pieDePromo(), isEmpty);
  });
}
