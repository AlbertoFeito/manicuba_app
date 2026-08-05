import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/post_redes.dart';
import '../../services/redes_service.dart';

/// Formulario para crear o editar un post de redes sociales con ayudas de
/// emojis y hashtags sugeridos.
class PostFormScreen extends StatefulWidget {
  const PostFormScreen({super.key, this.post});

  final PostRedes? post;

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _redesService = RedesService();

  final _tituloCtrl = TextEditingController();
  final _contenidoCtrl = TextEditingController();
  final _emojisCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();

  late String _tipo;
  late String _plataforma;
  bool _guardando = false;

  bool get _esEdicion => widget.post != null;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _tituloCtrl.text = p?.titulo ?? '';
    _contenidoCtrl.text = p?.contenido ?? '';
    _emojisCtrl.text = p?.emojis ?? '';
    _hashtagsCtrl.text = p?.hashtags ?? '';
    _tipo = _coincidir(AppConstants.tiposPost, p?.tipo);
    _plataforma = _coincidir(AppConstants.plataformasSociales, p?.plataforma);
  }

  // Devuelve el valor de [opciones] que coincide (sin distinguir mayúsculas)
  // con [valor]; si no hay coincidencia, el primero de la lista.
  String _coincidir(List<String> opciones, String? valor) {
    if (valor == null) {
      return opciones.first;
    }
    return opciones.firstWhere(
      (o) => o.toLowerCase() == valor.toLowerCase(),
      orElse: () => opciones.first,
    );
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _contenidoCtrl.dispose();
    _emojisCtrl.dispose();
    _hashtagsCtrl.dispose();
    super.dispose();
  }

  void _agregarEmoji(String emoji) {
    setState(() => _emojisCtrl.text += emoji);
  }

  void _agregarHashtag(String hashtag) {
    final actual = _hashtagsCtrl.text.trim();
    if (actual.contains(hashtag)) {
      return;
    }
    setState(() {
      _hashtagsCtrl.text = actual.isEmpty ? hashtag : '$actual $hashtag';
    });
  }

  List<String> get _emojisSugeridos =>
      _redesService.sugerenciasEmojis(_tipo.toLowerCase());

  List<String> get _hashtagsSugeridos =>
      _redesService.sugerenciasHashtags(_contenidoCtrl.text);

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _guardando = true);

    final anterior = widget.post;
    final post = PostRedes(
      id: anterior?.id,
      titulo: _tituloCtrl.text.trim(),
      contenido: _contenidoCtrl.text.trim(),
      emojis: _emojisCtrl.text.trim().isEmpty ? null : _emojisCtrl.text.trim(),
      hashtags:
          _hashtagsCtrl.text.trim().isEmpty ? null : _hashtagsCtrl.text.trim(),
      tipo: _tipo.toLowerCase(),
      plataforma: _plataforma.toLowerCase(),
      fechaCreacion: anterior?.fechaCreacion ?? DateTime.now(),
      fechaProgramada: anterior?.fechaProgramada,
      publicado: anterior?.publicado ?? false,
      visualizaciones: anterior?.visualizaciones ?? 0,
      notas: anterior?.notas,
    );

    try {
      if (_esEdicion) {
        await _redesService.actualizar(post);
      } else {
        await _redesService.crearPost(post);
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? AppConstants.msgSucessoActualizar
                : AppConstants.msgSucessoGuardar,
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgErrorGeneral)),
      );
    }
  }

  String? _validarRequerido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.msgCampoRequerido;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar post' : 'Nuevo post'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _tituloCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: _validarRequerido,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _tipo,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: AppConstants.tiposPost
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (value) => setState(
                      () => _tipo = value ?? AppConstants.tiposPost.first,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _plataforma,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Plataforma'),
                    items: AppConstants.plataformasSociales
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) => setState(
                      () => _plataforma =
                          value ?? AppConstants.plataformasSociales.first,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contenidoCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Contenido *',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.edit_note),
              ),
              validator: _validarRequerido,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emojisCtrl,
              decoration: const InputDecoration(
                labelText: 'Emojis',
                prefixIcon: Icon(Icons.emoji_emotions),
              ),
            ),
            const SizedBox(height: 8),
            _buildChips(
              'Sugeridos',
              _emojisSugeridos,
              _agregarEmoji,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hashtagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Hashtags',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 8),
            _buildChips(
              'Sugeridos',
              _hashtagsSugeridos,
              _agregarHashtag,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_esEdicion ? 'Guardar cambios' : 'Guardar post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChips(
    String label,
    List<String> valores,
    void Function(String) onTap,
  ) {
    if (valores.isEmpty) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: valores
            .map(
              (v) => ActionChip(
                label: Text(v),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                onPressed: () => onTap(v),
              ),
            )
            .toList(),
      ),
    );
  }
}
