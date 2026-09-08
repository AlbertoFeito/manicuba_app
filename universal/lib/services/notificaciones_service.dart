// Parte del Asistente de Promociones (ver docs/ASISTENTE_PROMOCIONES.md).
//
// Recordatorios por notificaciones locales: avisa cuándo publicar un post
// programado (usa PostRedes.fechaProgramada) y recuerda mantener la
// constancia de publicación. Sin conexión: todo es local al dispositivo.
//
// La decisión de qué/cuándo programar son métodos estáticos puros (probados
// sin plugin). La llamada al plugin real está detrás de un "seam"
// (programarOverride) para poder verificar en tests qué se programa sin
// depender de flutter_local_notifications.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/post_redes.dart';
import '../services/asistente_service.dart';

/// Firma del programador de notificaciones, para poder inyectar un doble en
/// las pruebas en lugar del plugin real.
typedef ProgramarNotificacion = Future<void> Function({
  required int id,
  required String titulo,
  required String cuerpo,
  required DateTime cuando,
});

class NotificacionesService {
  NotificacionesService._();
  static final NotificacionesService instance = NotificacionesService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  /// Si se define (en tests), se usa en lugar del plugin real.
  ProgramarNotificacion? programarOverride;

  static const String _canalId = 'promociones';
  static const String _canalNombre = 'Promociones';
  static const String _canalDescripcion =
      'Recordatorios para publicar y promover el negocio';

  /// Id fijo del recordatorio de constancia (no ligado a un post concreto).
  static const int idConstancia = 999000;

  Future<void> init() async {
    if (_inicializado) {
      return;
    }
    tzdata.initializeTimeZones();
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings);
    _inicializado = true;
  }

  // ===== Lógica pura (determinista) =====

  /// Id de notificación estable para un post (acotado a un entero pequeño).
  static int idParaPost(PostRedes post) => (post.id ?? 0) % 100000;

  /// Solo tiene sentido programar un aviso si el post tiene fecha futura y aún
  /// no se publicó.
  static bool debeProgramar(PostRedes post, {required DateTime ahora}) {
    final f = post.fechaProgramada;
    return f != null && f.isAfter(ahora) && !post.publicado;
  }

  static String cuerpoRecordatorio(PostRedes post) =>
      'Es hora de publicar: ${post.titulo}';

  static String mensajeConstancia(int dias) => dias >= 99999
      ? 'Aún no has publicado ninguna promoción. ¡Anímate a mostrar tu trabajo!'
      : 'Hace $dias días que no publicas. Mantén tu presencia en redes.';

  // ===== Programación =====

  /// Programa (o reprograma) el recordatorio de un post con fecha programada.
  /// No hace nada si el post no debe recordarse (ver [debeProgramar]).
  Future<void> programarRecordatorioPost(
    PostRedes post, {
    DateTime Function()? ahora,
  }) async {
    final now = (ahora ?? DateTime.now)();
    if (!debeProgramar(post, ahora: now)) {
      return;
    }
    await _programar(
      id: idParaPost(post),
      titulo: 'Recordatorio de publicación',
      cuerpo: cuerpoRecordatorio(post),
      cuando: post.fechaProgramada!,
    );
  }

  /// Cancela el recordatorio de un post (p. ej. al publicarlo o borrarlo).
  Future<void> cancelarRecordatorioPost(PostRedes post) async {
    if (programarOverride != null) {
      return;
    }
    await init();
    await _plugin.cancel(idParaPost(post));
  }

  /// Programa el recordatorio de constancia para dentro de [enDias] días, si
  /// hace tiempo que no se publica. Devuelve true si programó algo.
  Future<bool> programarConstanciaSiHaceFalta(
    List<PostRedes> posts, {
    required DateTime ahora,
    int enDias = 1,
  }) async {
    final dias = AsistenteService.diasDesdeUltimoPost(posts, ahora: ahora);
    if (dias < AsistenteService.diasSinPublicar) {
      return false;
    }
    await _programar(
      id: idConstancia,
      titulo: 'Mantén tu presencia en redes',
      cuerpo: mensajeConstancia(dias),
      cuando: ahora.add(Duration(days: enDias)),
    );
    return true;
  }

  Future<void> _programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime cuando,
  }) async {
    final override = programarOverride;
    if (override != null) {
      await override(id: id, titulo: titulo, cuerpo: cuerpo, cuando: cuando);
      return;
    }
    await init();
    const androidDetails = AndroidNotificationDetails(
      _canalId,
      _canalNombre,
      channelDescription: _canalDescripcion,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const detalles = NotificationDetails(android: androidDetails);
    await _plugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      tz.TZDateTime.from(cuando, tz.local),
      detalles,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
