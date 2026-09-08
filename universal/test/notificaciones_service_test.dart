// Pruebas de NotificacionesService.
//
// La lógica de decisión (qué/cuándo recordar) son métodos estáticos puros.
// La programación se prueba con un doble inyectado (programarOverride), sin
// tocar el plugin real flutter_local_notifications.

import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/models/post_redes.dart';
import 'package:multiservicios_app/services/notificaciones_service.dart';

void main() {
  final ahora = DateTime(2026, 6, 15, 10);

  PostRedes post({
    int? id,
    DateTime? fechaProgramada,
    bool publicado = false,
    String titulo = 'Mi promo',
  }) =>
      PostRedes(
        id: id,
        titulo: titulo,
        contenido: 'c',
        tipo: 'promocion',
        plataforma: 'todas',
        fechaCreacion: ahora,
        fechaProgramada: fechaProgramada,
        publicado: publicado,
      );

  group('lógica pura', () {
    test('debeProgramar: solo futuro y no publicado', () {
      expect(
        NotificacionesService.debeProgramar(
          post(fechaProgramada: ahora.add(const Duration(hours: 2))),
          ahora: ahora,
        ),
        isTrue,
      );
      // Pasado -> no.
      expect(
        NotificacionesService.debeProgramar(
          post(fechaProgramada: ahora.subtract(const Duration(hours: 2))),
          ahora: ahora,
        ),
        isFalse,
      );
      // Sin fecha -> no.
      expect(
        NotificacionesService.debeProgramar(post(), ahora: ahora),
        isFalse,
      );
      // Ya publicado -> no.
      expect(
        NotificacionesService.debeProgramar(
          post(
            fechaProgramada: ahora.add(const Duration(hours: 2)),
            publicado: true,
          ),
          ahora: ahora,
        ),
        isFalse,
      );
    });

    test('idParaPost acota el id', () {
      expect(NotificacionesService.idParaPost(post(id: 123)), 123);
      expect(NotificacionesService.idParaPost(post()), 0);
    });

    test('mensajeConstancia distingue "nunca" de "hace X días"', () {
      expect(
        NotificacionesService.mensajeConstancia(99999),
        contains('Aún no'),
      );
      expect(
        NotificacionesService.mensajeConstancia(12),
        contains('12 días'),
      );
    });
  });

  group('programación (con doble inyectado)', () {
    final servicio = NotificacionesService.instance;

    tearDown(() => servicio.programarOverride = null);

    test('programarRecordatorioPost usa la fecha e id del post', () async {
      final capturas = <Map<String, Object>>[];
      servicio.programarOverride = ({
        required int id,
        required String titulo,
        required String cuerpo,
        required DateTime cuando,
      }) async {
        capturas.add({
          'id': id,
          'titulo': titulo,
          'cuerpo': cuerpo,
          'cuando': cuando,
        });
      };

      final cuando = ahora.add(const Duration(days: 2));
      await servicio.programarRecordatorioPost(
        post(id: 42, fechaProgramada: cuando, titulo: 'Oferta 2x1'),
        ahora: () => ahora,
      );

      expect(capturas, hasLength(1));
      expect(capturas.first['id'], 42);
      expect(capturas.first['cuando'], cuando);
      expect(capturas.first['cuerpo'], contains('Oferta 2x1'));
    });

    test('no programa nada si la fecha es pasada', () async {
      var llamado = false;
      servicio.programarOverride = ({
        required int id,
        required String titulo,
        required String cuerpo,
        required DateTime cuando,
      }) async {
        llamado = true;
      };

      await servicio.programarRecordatorioPost(
        post(id: 1, fechaProgramada: ahora.subtract(const Duration(days: 1))),
        ahora: () => ahora,
      );
      expect(llamado, isFalse);
    });

    test('programarConstanciaSiHaceFalta programa cuando hace mucho', () async {
      Map<String, Object>? captura;
      servicio.programarOverride = ({
        required int id,
        required String titulo,
        required String cuerpo,
        required DateTime cuando,
      }) async {
        captura = {'id': id, 'cuando': cuando};
      };

      // Sin posts publicados -> hace mucho -> programa.
      final programo = await servicio.programarConstanciaSiHaceFalta(
        const [],
        ahora: ahora,
      );
      expect(programo, isTrue);
      expect(captura?['id'], NotificacionesService.idConstancia);

      // Con un post publicado hoy -> no programa.
      captura = null;
      final programo2 = await servicio.programarConstanciaSiHaceFalta(
        [post(id: 9, publicado: true)],
        ahora: ahora,
      );
      expect(programo2, isFalse);
      expect(captura, isNull);
    });
  });
}
