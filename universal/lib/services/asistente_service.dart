// Parte del Asistente de Promociones (ver docs/ASISTENTE_PROMOCIONES.md).
//
// Genera sugerencias de promoción a partir de los datos del propio negocio:
// clientas inactivas, semanas flojas, fotos nuevas sin publicar y constancia
// de publicación. La lógica de decisión son métodos estáticos puros (sin
// base de datos ni reloj real) para poder probarla de forma determinista;
// `generarSugerencias` solo orquesta: lee los datos y llama a esos métodos.

import 'package:flutter/material.dart';

import '../config/business_config.dart';
import '../models/cita.dart';
import '../models/cliente.dart';
import '../models/foto_trabajo.dart';
import '../models/perfil_negocio.dart';
import '../models/post_redes.dart';
import '../models/sugerencia_promo.dart';
import 'cita_service.dart';
import 'cliente_service.dart';
import 'foto_service.dart';
import 'perfil_service.dart';
import 'redes_service.dart';

class AsistenteService {
  AsistenteService({
    ClienteService? clienteService,
    CitaService? citaService,
    FotoService? fotoService,
    RedesService? redesService,
    DateTime Function()? ahora,
  })  : _clientes = clienteService ?? ClienteService(),
        _citas = citaService ?? CitaService(),
        _fotos = fotoService ?? FotoService(),
        _redes = redesService ?? RedesService(),
        _ahora = ahora ?? DateTime.now;

  final ClienteService _clientes;
  final CitaService _citas;
  final FotoService _fotos;
  final RedesService _redes;
  final DateTime Function() _ahora;

  // ===== Umbrales (ajustables) =====

  /// Días sin visitar tras los cuales una clienta se considera "inactiva".
  static const int diasInactividad = 30;

  /// Mínimo de citas en los próximos 7 días por debajo del cual la semana se
  /// considera "floja".
  static const int minCitasSemana = 3;

  /// Ventana en la que una foto se considera "reciente" para sugerir mostrarla.
  static const int diasFotoReciente = 14;

  /// Días sin publicar tras los cuales se recuerda mantener la constancia.
  static const int diasSinPublicar = 7;

  // ===== Lógica pura (determinista) =====

  /// Clientas inactivas: visitaron alguna vez pero no vuelven desde hace más
  /// de [dias]. Las que nunca visitaron (ultimaVisita nula) no cuentan aquí.
  static List<Cliente> filtrarInactivos(
    List<Cliente> todos, {
    required DateTime ahora,
    int dias = diasInactividad,
  }) {
    final limite = ahora.subtract(Duration(days: dias));
    return todos
        .where((c) =>
            c.ultimaVisita != null && c.ultimaVisita!.isBefore(limite))
        .toList();
  }

  /// Citas activas (pendientes o confirmadas) dentro de los próximos 7 días.
  static int citasProximaSemana(
    List<Cita> citas, {
    required DateTime ahora,
  }) {
    final fin = ahora.add(const Duration(days: 7));
    return citas
        .where((c) =>
            (c.estado == EstadoCita.pendiente ||
                c.estado == EstadoCita.confirmada) &&
            !c.fechaHora.isBefore(ahora) &&
            !c.fechaHora.isAfter(fin))
        .length;
  }

  static bool esSemanaFloja(
    List<Cita> citas, {
    required DateTime ahora,
    int minimo = minCitasSemana,
  }) {
    return citasProximaSemana(citas, ahora: ahora) < minimo;
  }

  /// Foto más reciente (dentro de [diasRecientes]) que aún no está en ningún
  /// post, o `null` si no hay ninguna que mostrar.
  static FotoTrabajo? fotoRecienteSinPost(
    List<FotoTrabajo> fotos,
    List<PostRedes> posts, {
    required DateTime ahora,
    int diasRecientes = diasFotoReciente,
  }) {
    final usadas = <int>{
      for (final p in posts) ...p.listaFotoIds,
    };
    final limite = ahora.subtract(Duration(days: diasRecientes));
    final candidatas = fotos
        .where((f) =>
            f.id != null &&
            !usadas.contains(f.id) &&
            !f.fecha.isBefore(limite) &&
            !f.fecha.isAfter(ahora))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return candidatas.isEmpty ? null : candidatas.first;
  }

  /// Días desde el último post publicado. Si no hay ninguno publicado,
  /// devuelve un número grande (nunca se publicó nada aún).
  static int diasDesdeUltimoPost(
    List<PostRedes> posts, {
    required DateTime ahora,
  }) {
    final publicados = posts.where((p) => p.publicado).toList();
    if (publicados.isEmpty) {
      return 99999;
    }
    publicados.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    final dias = ahora.difference(publicados.first.fechaCreacion).inDays;
    return dias < 0 ? 0 : dias;
  }

  static String _tituloPorTipo(String tipo) {
    switch (tipo) {
      case 'oferta':
        return 'Oferta especial';
      case 'trabajo':
        return 'Trabajo del día';
      case 'testimonio':
        return 'Testimonio de clienta';
      case 'educativo':
        return 'Consejo del día';
      case 'promocion':
      default:
        return 'Promoción';
    }
  }

  /// Construye un borrador de post desde la plantilla del rubro más el pie de
  /// contacto del perfil. Método puro: no toca la base de datos.
  static PostRedes construirBorrador({
    required String tipo,
    required BusinessConfig config,
    required PerfilNegocio perfil,
    required DateTime ahora,
    String? titulo,
    String? fotoIds,
  }) {
    final plantilla = config.plantillasPost[tipo] ?? '';
    final pie = perfil.pieDePromo();
    final contenido =
        pie.isEmpty ? plantilla : '$plantilla\n\n$pie';
    return PostRedes(
      titulo: titulo ?? _tituloPorTipo(tipo),
      contenido: contenido,
      tipo: tipo,
      plataforma: 'todas',
      hashtags: config.hashtagsComunes.join(' '),
      fechaCreacion: ahora,
      fotoIds: fotoIds,
    );
  }

  // ===== Orquestación =====

  /// Lee los datos del negocio y arma la lista de sugerencias del momento.
  Future<List<SugerenciaPromo>> generarSugerencias() async {
    final ahora = _ahora();
    final config = AppConfig.instance.current;
    final perfil = await PerfilService.instance.obtener();

    final clientes = await _clientes.obtenerTodos();
    final citas = await _citas.obtenerTodas();
    final posts = await _redes.obtenerTodos();
    final fotos = await _fotos.obtenerTodas();

    final sugerencias = <SugerenciaPromo>[];

    // 1. Win-back de clientas inactivas.
    final inactivas = filtrarInactivos(clientes, ahora: ahora);
    if (inactivas.isNotEmpty) {
      sugerencias.add(SugerenciaPromo(
        id: 'inactivas',
        titulo: 'Reconecta con ${inactivas.length} clienta(s)',
        motivo: 'No te visitan desde hace más de $diasInactividad días.',
        tipo: 'promocion',
        icono: Icons.favorite,
        clienteIds:
            inactivas.map((c) => c.id).whereType<int>().toList(),
        borrador: construirBorrador(
          tipo: 'promocion',
          config: config,
          perfil: perfil,
          ahora: ahora,
          titulo: 'Te extrañamos',
        ),
      ));
    }

    // 2. Semana floja -> oferta relámpago.
    if (esSemanaFloja(citas, ahora: ahora)) {
      final n = citasProximaSemana(citas, ahora: ahora);
      sugerencias.add(SugerenciaPromo(
        id: 'semana_floja',
        titulo: 'Llena tu semana',
        motivo: 'Tienes solo $n cita(s) en los próximos 7 días.',
        tipo: 'oferta',
        icono: Icons.bolt,
        borrador: construirBorrador(
          tipo: 'oferta',
          config: config,
          perfil: perfil,
          ahora: ahora,
        ),
      ));
    }

    // 3. Foto nueva sin publicar -> mostrar el trabajo.
    final foto = fotoRecienteSinPost(fotos, posts, ahora: ahora);
    if (foto != null) {
      sugerencias.add(SugerenciaPromo(
        id: 'foto_${foto.id}',
        titulo: 'Muestra tu último trabajo',
        motivo: 'Tienes una foto nueva que aún no has publicado.',
        tipo: 'trabajo',
        icono: Icons.photo_camera,
        borrador: construirBorrador(
          tipo: 'trabajo',
          config: config,
          perfil: perfil,
          ahora: ahora,
          fotoIds: PostRedes.fotoIdsDesdeLista([foto.id!]),
        ),
      ));
    }

    // 4. Constancia: hace mucho que no se publica.
    final dias = diasDesdeUltimoPost(posts, ahora: ahora);
    if (dias >= diasSinPublicar) {
      final nunca = dias >= 99999;
      sugerencias.add(SugerenciaPromo(
        id: 'constancia',
        titulo: 'Mantén tu presencia en redes',
        motivo: nunca
            ? 'Aún no has publicado ninguna promoción.'
            : 'Hace $dias días que no publicas nada.',
        tipo: 'promocion',
        icono: Icons.calendar_month,
        borrador: construirBorrador(
          tipo: 'promocion',
          config: config,
          perfil: perfil,
          ahora: ahora,
        ),
      ));
    }

    return sugerencias;
  }
}
