import '../config/business_config.dart';
import '../database/database_helper.dart';
import '../models/post_redes.dart';

class RedesService {
  final DatabaseHelper _db = DatabaseHelper();

  // Crear post
  Future<int> crearPost(PostRedes post) async {
    return await _db.insertPostRedes(post.toMap());
  }

  // Obtener todos los posts
  Future<List<PostRedes>> obtenerTodos() async {
    final mapList = await _db.getAllPostsRedes();
    return mapList.map((map) => PostRedes.fromMap(map)).toList();
  }

  // Obtener posts no publicados
  Future<List<PostRedes>> obtenerNoPublicados() async {
    final mapList = await _db.getPostsRedesNoPublicados();
    return mapList.map((map) => PostRedes.fromMap(map)).toList();
  }

  // Obtener posts por tipo
  Future<List<PostRedes>> obtenerPorTipo(String tipo) async {
    final todos = await obtenerTodos();
    return todos.where((p) => p.tipo == tipo).toList();
  }

  // Obtener posts por plataforma
  Future<List<PostRedes>> obtenerPorPlataforma(String plataforma) async {
    final todos = await obtenerTodos();
    return todos.where((p) => p.plataforma == plataforma).toList();
  }

  // Actualizar post
  Future<int> actualizar(PostRedes post) async {
    return await _db.updatePostRedes(post.toMap());
  }

  // Eliminar post
  Future<int> eliminar(int id) async {
    return _db.deletePostRedes(id);
  }

  // Marcar como publicado
  Future<int> marcarPublicado(int id) async {
    final posts = await obtenerTodos();
    final post = posts.firstWhere((p) => p.id == id);
    final postActualizado = post.copyWith(publicado: true);
    return await actualizar(postActualizado);
  }

  // Aumentar visualizaciones
  Future<int> aumentarVisualizaciones(int id) async {
    final posts = await obtenerTodos();
    final post = posts.firstWhere((p) => p.id == id);
    final postActualizado =
        post.copyWith(visualizaciones: post.visualizaciones + 1);
    return await actualizar(postActualizado);
  }

  // Obtener total de posts
  Future<int> totalPosts() async {
    final posts = await obtenerTodos();
    return posts.length;
  }

  // Obtener total de posts publicados
  Future<int> totalPublicados() async {
    final posts = await obtenerTodos();
    return posts.where((p) => p.publicado).length;
  }

  // Obtener posts de esta semana
  Future<List<PostRedes>> obtenerSemana() async {
    final hoy = DateTime.now();
    final hace7dias = hoy.subtract(const Duration(days: 7));
    final posts = await obtenerTodos();

    return posts
        .where((p) => p.fechaCreacion.isAfter(hace7dias))
        .toList();
  }

  // Obtener posts de este mes
  Future<List<PostRedes>> obtenerMes() async {
    final hoy = DateTime.now();
    final hace30dias = hoy.subtract(const Duration(days: 30));
    final posts = await obtenerTodos();

    return posts
        .where((p) => p.fechaCreacion.isAfter(hace30dias))
        .toList();
  }

  // Estadísticas de redes
  Future<Map<String, dynamic>> estadisticas() async {
    final todos = await obtenerTodos();
    final publicados = todos.where((p) => p.publicado).toList();
    final noPublicados = todos.where((p) => !p.publicado).toList();

    // Contar por tipo
    final porTipo = <String, int>{};
    for (var post in todos) {
      porTipo.update(
        post.tipo,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    // Contar por plataforma
    final porPlataforma = <String, int>{};
    for (var post in todos) {
      porPlataforma.update(
        post.plataforma,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    // Total de visualizaciones
    final totalVisualizaciones =
        todos.fold<int>(0, (sum, p) => sum + p.visualizaciones);

    return {
      'totalPosts': todos.length,
      'publicados': publicados.length,
      'noPublicados': noPublicados.length,
      'porTipo': porTipo,
      'porPlataforma': porPlataforma,
      'totalVisualizaciones': totalVisualizaciones,
      'semana': await obtenerSemana().then((l) => l.length),
      'mes': await obtenerMes().then((l) => l.length),
    };
  }

  // Exportar contenido para copiar
  String exportarParaCopiar(PostRedes post) {
    return post.getContenidoFormateado();
  }

  // Exportar lista de posts
  Future<List<Map<String, dynamic>>> exportarTodos() async {
    final posts = await obtenerTodos();
    return posts.map((p) => p.toMap()).toList();
  }

  // Generar post desde plantilla
  PostRedes generarDesdeProctilla(String tipo, String contenidoExtra) {
    final contenido = '$tipo\n\n$contenidoExtra';

    return PostRedes(
      titulo: tipo,
      contenido: contenido,
      tipo: tipo.toLowerCase(),
      plataforma: 'todas',
      fechaCreacion: DateTime.now(),
    );
  }

  // Obtener sugerencias de hashtags (según el rubro elegido)
  List<String> sugerenciasHashtags(String contenido) {
    final config = AppConfig.instance.current;
    List<String> sugerencias = [];

    if (contenido.toLowerCase().contains('descuento') ||
        contenido.toLowerCase().contains('oferta')) {
      sugerencias.addAll(['#oferta', '#descuento', '#promocion']);
    }

    if (contenido.toLowerCase().contains('trabajo') ||
        contenido.toLowerCase().contains('diseño')) {
      sugerencias.addAll(config.hashtagsComunes.take(3));
    }

    sugerencias.addAll(config.hashtagsComunes);

    return sugerencias.toSet().toList();
  }

  // Obtener sugerencias de emojis (según el rubro elegido)
  List<String> sugerenciasEmojis(String tipo) {
    final emoji = AppConfig.instance.current.emoji;
    final sugerencias = {
      'oferta': ['🎉', '💰', '✨', '🎁'],
      'promocion': ['💖', '🌹', '👑', emoji],
      'trabajo': ['✨', '💫', '🌟', '👌'],
      'testimonio': ['💬', '⭐', '😍', '👍'],
      'educativo': ['📚', '💡', '📖', '✏️'],
    };

    return sugerencias[tipo] ?? ['✨', emoji, '💖'];
  }
}
