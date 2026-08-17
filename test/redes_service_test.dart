// Pruebas de RedesService: CRUD por tipo/plataforma, contadores, ventanas de
// tiempo, estadísticas y sugerencias.
//
// La tabla posts_redes es compartida entre tests, así que se usan marcas
// únicas (tipo/plataforma que nadie más usa) y medición por diferencias para
// no depender de totales globales.

import 'package:flutter_test/flutter_test.dart';

import 'package:manicuba_app/models/post_redes.dart';
import 'package:manicuba_app/services/redes_service.dart';

void main() {
  final redes = RedesService();

  String unico(String prefijo) =>
      '$prefijo${DateTime.now().microsecondsSinceEpoch}';

  Future<int> crearPost({
    required String tipo,
    required String plataforma,
    bool publicado = false,
    int visualizaciones = 0,
    DateTime? fecha,
    String titulo = 'Post',
  }) {
    return redes.crearPost(
      PostRedes(
        titulo: titulo,
        contenido: 'contenido',
        tipo: tipo,
        plataforma: plataforma,
        publicado: publicado,
        visualizaciones: visualizaciones,
        fechaCreacion: fecha ?? DateTime.now(),
      ),
    );
  }

  test('obtenerPorTipo y obtenerPorPlataforma filtran por su campo', () async {
    final tipo = unico('tipo');
    final plataforma = unico('plat');
    await crearPost(tipo: tipo, plataforma: plataforma);

    final porTipo = await redes.obtenerPorTipo(tipo);
    expect(porTipo, hasLength(1));
    expect(porTipo.first.plataforma, plataforma);

    final porPlataforma = await redes.obtenerPorPlataforma(plataforma);
    expect(porPlataforma, hasLength(1));
    expect(porPlataforma.first.tipo, tipo);
  });

  test('marcarPublicado marca el post como publicado', () async {
    final id = await crearPost(tipo: unico('t'), plataforma: 'todas');

    await redes.marcarPublicado(id);

    final post = (await redes.obtenerTodos()).firstWhere((p) => p.id == id);
    expect(post.publicado, isTrue);
  });

  test('aumentarVisualizaciones suma de una en una', () async {
    final id = await crearPost(tipo: unico('t'), plataforma: 'todas');

    await redes.aumentarVisualizaciones(id);
    await redes.aumentarVisualizaciones(id);

    final post = (await redes.obtenerTodos()).firstWhere((p) => p.id == id);
    expect(post.visualizaciones, 2);
  });

  test('totalPosts y totalPublicados cuentan por diferencia', () async {
    final totalBase = await redes.totalPosts();
    final publicadosBase = await redes.totalPublicados();

    await crearPost(tipo: unico('t'), plataforma: 'todas', publicado: true);
    await crearPost(tipo: unico('t'), plataforma: 'todas', publicado: false);

    expect(await redes.totalPosts() - totalBase, 2);
    expect(await redes.totalPublicados() - publicadosBase, 1);
  });

  test('obtenerSemana/obtenerMes respetan la ventana de tiempo', () async {
    final reciente = unico('reciente');
    final medio = unico('medio');
    final viejo = unico('viejo');
    final ahora = DateTime.now();

    await crearPost(
        tipo: unico('t'), plataforma: 'todas', titulo: reciente, fecha: ahora);
    await crearPost(
        tipo: unico('t'),
        plataforma: 'todas',
        titulo: medio,
        fecha: ahora.subtract(const Duration(days: 10)));
    await crearPost(
        tipo: unico('t'),
        plataforma: 'todas',
        titulo: viejo,
        fecha: ahora.subtract(const Duration(days: 40)));

    final semana = (await redes.obtenerSemana()).map((p) => p.titulo).toSet();
    expect(semana.contains(reciente), isTrue);
    expect(semana.contains(medio), isFalse); // 10 días: fuera de la semana
    expect(semana.contains(viejo), isFalse);

    final mes = (await redes.obtenerMes()).map((p) => p.titulo).toSet();
    expect(mes.contains(reciente), isTrue);
    expect(mes.contains(medio), isTrue); // 10 días: dentro del mes
    expect(mes.contains(viejo), isFalse); // 40 días: fuera del mes
  });

  test('estadisticas cuenta por tipo, plataforma y totales', () async {
    final tipo = unico('t');
    final plataforma = unico('p');

    await crearPost(
        tipo: tipo, plataforma: plataforma, publicado: true, visualizaciones: 5);
    await crearPost(
        tipo: tipo, plataforma: plataforma, publicado: false, visualizaciones: 3);

    final stats = await redes.estadisticas();
    // Los conteos por tipo/plataforma únicos son exactos (nadie más los usa).
    expect((stats['porTipo'] as Map)[tipo], 2);
    expect((stats['porPlataforma'] as Map)[plataforma], 2);
    // Las claves globales existen y tienen el tipo correcto.
    expect(stats['totalPosts'], isA<int>());
    expect(stats['totalVisualizaciones'], isA<int>());
    expect(stats['semana'], isA<int>());
    expect(stats['mes'], isA<int>());
  });

  test('exportarTodos devuelve los posts como mapas', () async {
    final titulo = unico('exp');
    await crearPost(tipo: unico('t'), plataforma: 'todas', titulo: titulo);

    final mapas = await redes.exportarTodos();
    expect(mapas.any((m) => m['titulo'] == titulo), isTrue);
  });

  test('generarDesdeProctilla arma un post con tipo en minúscula', () {
    final post = redes.generarDesdeProctilla('Oferta', 'detalle extra');
    expect(post.tipo, 'oferta');
    expect(post.plataforma, 'todas');
    expect(post.contenido, contains('detalle extra'));
  });

  test('exportarParaCopiar formatea contenido, emojis y hashtags', () {
    final post = PostRedes(
      titulo: 'T',
      contenido: 'Texto base',
      emojis: '✨💅',
      hashtags: '#manicura',
      tipo: 'oferta',
      plataforma: 'todas',
      fechaCreacion: DateTime.now(),
    );

    final texto = redes.exportarParaCopiar(post);
    expect(texto, contains('Texto base'));
    expect(texto, contains('✨💅'));
    expect(texto, contains('#manicura'));
  });

  test('sugerenciasHashtags añade tags temáticos y no duplica', () {
    final ofertas = redes.sugerenciasHashtags('Gran oferta de hoy');
    expect(ofertas, contains('#oferta'));
    expect(ofertas, contains('#manicura')); // base siempre presente

    final trabajo = redes.sugerenciasHashtags('nuevo diseño de uñas');
    expect(trabajo, contains('#diseño'));

    // Un contenido genérico solo trae las base, sin repetidos.
    final base = redes.sugerenciasHashtags('hola');
    expect(base.toSet().length, base.length);
    expect(base, contains('#nails'));
  });

  test('sugerenciasEmojis devuelve el set del tipo o el genérico', () {
    expect(redes.sugerenciasEmojis('oferta'), contains('🎉'));
    expect(redes.sugerenciasEmojis('educativo'), contains('📚'));
    // Tipo desconocido -> lista por defecto.
    expect(redes.sugerenciasEmojis('inexistente'), ['✨', '💅', '💖']);
  });
}
