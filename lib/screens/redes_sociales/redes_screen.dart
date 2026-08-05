import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/post_redes.dart';
import '../../services/redes_service.dart';
import 'post_form_screen.dart';

/// Gestor de posts para redes sociales: crear, copiar, compartir y publicar.
class RedesScreen extends StatefulWidget {
  const RedesScreen({super.key});

  @override
  State<RedesScreen> createState() => _RedesScreenState();
}

class _RedesScreenState extends State<RedesScreen> {
  final _redesService = RedesService();

  List<PostRedes> _posts = [];
  bool _cargando = true;
  // 0 = Todos, 1 = Pendientes, 2 = Publicados
  int _filtro = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final posts = await _redesService.obtenerTodos();
    if (!mounted) {
      return;
    }
    setState(() {
      _posts = posts;
      _cargando = false;
    });
  }

  List<PostRedes> get _filtrados {
    switch (_filtro) {
      case 1:
        return _posts.where((p) => !p.publicado).toList();
      case 2:
        return _posts.where((p) => p.publicado).toList();
      default:
        return _posts;
    }
  }

  Future<void> _nuevoPost() async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PostFormScreen()),
    );
    if (guardado == true) {
      await _cargar();
    }
  }

  Future<void> _editar(PostRedes post) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PostFormScreen(post: post)),
    );
    if (guardado == true) {
      await _cargar();
    }
  }

  Future<void> _copiar(PostRedes post) async {
    await Clipboard.setData(
      ClipboardData(text: post.getContenidoFormateado()),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contenido copiado al portapapeles')),
      );
    }
  }

  Future<void> _compartir(PostRedes post) async {
    await Share.share(
      post.getContenidoFormateado(),
      subject: post.titulo,
    );
  }

  Future<void> _alternarPublicado(PostRedes post) async {
    if (!post.publicado) {
      await _redesService.marcarPublicado(post.id!);
    } else {
      await _redesService.actualizar(post.copyWith(publicado: false));
    }
    await _cargar();
  }

  Future<void> _eliminar(PostRedes post) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar post'),
        content: Text('¿Eliminar "${post.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) {
      return;
    }
    await _redesService.eliminar(post.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgSucessoEliminar)),
      );
    }
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoPost,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo post'),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Sin posts todavía',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer post para redes sociales',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }
    final lista = _filtrados;
    return Column(
      children: [
        _buildFiltro(),
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Text(
                    'No hay posts en este filtro',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88, top: 4),
                    itemCount: lista.length,
                    itemBuilder: (context, index) =>
                        _buildPostCard(lista[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFiltro() {
    const etiquetas = ['Todos', 'Pendientes', 'Publicados'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          for (var i = 0; i < etiquetas.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(etiquetas[i]),
                selected: _filtro == i,
                onSelected: (_) => setState(() => _filtro = i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostRedes post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: post.publicado
                        ? AppTheme.successColor.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.publicado ? 'Publicado' : 'Pendiente',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: post.publicado
                          ? AppTheme.successColor
                          : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              post.getContenidoFormateado(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Wrap(
              children: [
                _metaChip(Icons.category, _capitalizar(post.tipo)),
                _metaChip(Icons.public, _capitalizar(post.plataforma)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _accion(Icons.copy, 'Copiar', () => _copiar(post)),
                _accion(Icons.share, 'Compartir', () => _compartir(post)),
                _accion(Icons.edit, 'Editar', () => _editar(post)),
                _accion(
                  post.publicado ? Icons.undo : Icons.check_circle,
                  post.publicado ? 'Pendiente' : 'Publicar',
                  () => _alternarPublicado(post),
                ),
                _accion(
                  Icons.delete_outline,
                  'Eliminar',
                  () => _eliminar(post),
                  color: AppTheme.errorColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizar(String texto) {
    if (texto.isEmpty) {
      return texto;
    }
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Widget _metaChip(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accion(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? AppTheme.primaryColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color ?? AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
