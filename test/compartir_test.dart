// Pruebas de la lógica de ruteo al compartir un post (sin plugins ni DB).

import 'package:flutter_test/flutter_test.dart';

import 'package:manicuba_app/services/compartir_service.dart';

void main() {
  test('WhatsApp sin fotos: abre la app directo, sin copiar', () {
    final plan = planificarCompartir('whatsapp', conFotos: false);
    expect(plan.intentarWhatsApp, isTrue);
    expect(plan.copiarTexto, isFalse);
  });

  test('WhatsApp con fotos: hoja del sistema, copia el texto', () {
    final plan = planificarCompartir('whatsapp', conFotos: true);
    expect(plan.intentarWhatsApp, isFalse);
    expect(plan.copiarTexto, isTrue);
  });

  test('Instagram: hoja del sistema, copia el texto (con o sin fotos)', () {
    expect(
      planificarCompartir('instagram', conFotos: false).copiarTexto,
      isTrue,
    );
    expect(
      planificarCompartir('instagram', conFotos: true).copiarTexto,
      isTrue,
    );
    expect(
      planificarCompartir('Instagram', conFotos: true).intentarWhatsApp,
      isFalse,
    );
  });

  test('Facebook: hoja del sistema, copia el texto (con o sin fotos)', () {
    expect(
      planificarCompartir('facebook', conFotos: false).copiarTexto,
      isTrue,
    );
    expect(
      planificarCompartir('facebook', conFotos: true).copiarTexto,
      isTrue,
    );
  });

  test('Todas (o cualquier otra): hoja del sistema, sin copiar', () {
    final todas = planificarCompartir('todas', conFotos: true);
    expect(todas.intentarWhatsApp, isFalse);
    expect(todas.copiarTexto, isFalse);

    final desconocida = planificarCompartir('tiktok', conFotos: false);
    expect(desconocida.intentarWhatsApp, isFalse);
    expect(desconocida.copiarTexto, isFalse);
  });
}
