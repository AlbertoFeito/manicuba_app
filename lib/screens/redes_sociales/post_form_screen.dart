import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/foto_trabajo.dart';
import '../../models/post_redes.dart';
import '../../services/foto_service.dart';
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
  final _fotoService = FotoService();
  final _picker = ImagePicker();

  final _tituloCtrl = TextEditingController();
  final _contenidoCtrl = TextEditingController();
  final _emojisCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();

  late String _tipo;
  late String _plataforma;
  bool _guardando = false;
  List<int> _fotoIds = [];
  List<FotoTrabajo> _fotosSel = [];

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
    _fotoIds = List.of(p?.listaFotoIds ?? const []);
    _cargarFotosSel();
  }

  Future<void> _cargarFotosSel() async {
    final fotos = await _fotoService.obtenerPorIds(_fotoIds);
    if (!mounted) {
      return;
    }
    setState(() => _fotosSel = fotos);
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

  void _quitarFoto(int id) {
    setState(() {
      _fotoIds = _fotoIds.where((i) => i != id).toList();
      _fotosSel = _fotosSel.where((f) => f.id != id).toList();
    });
  }

  void _abrirSelectorFotos() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.of(ctx).pop();
                _agregarFotoDispositivo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería del teléfono'),
              onTap: () {
                Navigator.of(ctx).pop();
                _agregarFotoDispositivo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.collections),
              title: const Text('Elegir de la Galería de trabajos'),
              onTap: () {
                Navigator.of(ctx).pop();
                _elegirDeGaleriaTrabajos();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _agregarFotoDispositivo(ImageSource source) async {
    try {
      final imagen = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (imagen == null) {
        return;
      }
      final foto = await _fotoService.guardarDesdeArchivo(File(imagen.path));
      if (!mounted) {
        return;
      }
      setState(() {
        _fotoIds = [..._fotoIds, foto.id!];
        _fotosSel = [..._fotosSel, foto];
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo agregar la foto')),
        );
      }
    }
  }

  Future<void> _elegirDeGaleriaTrabajos() async {
    final todas = await _fotoService.obtenerTodas();
    if (!mounted) {
      return;
    }
    if (todas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aún no tienes fotos en la Galería de trabajos'),
        ),
      );
      return;
    }
    final resultado = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        var seleccion = List.of(_fotoIds);
        return StatefulBuilder(
          builder: (ctx, setSheetState) => SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Elegir fotos',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: todas.length,
                      itemBuilder: (context, index) {
                        final foto = todas[index];
                        final marcada = seleccion.contains(foto.id);
                        return GestureDetector(
                          key: ValueKey('foto_galeria_${foto.id}'),
                          onTap: () => setSheetState(() {
                            seleccion = marcada
                                ? seleccion.where((i) => i != foto.id).toList()
                                : [...seleccion, foto.id!];
                          }),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _miniaturaFoto(foto),
                              ),
                              if (marcada)
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(seleccion),
                      child: const Text('Listo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (resultado == null) {
      return;
    }
    setState(() => _fotoIds = resultado);
    await _cargarFotosSel();
  }

  Widget _miniaturaFoto(FotoTrabajo foto) {
    return File(foto.rutaFoto).existsSync()
        ? Image.file(File(foto.rutaFoto), fit: BoxFit.cover)
        : Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image),
          );
  }

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
      fotoIds: PostRedes.fotoIdsDesdeLista(_fotoIds),
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
            _buildFotosSection(),
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

  Widget _buildFotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotos del post', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (_fotosSel.isEmpty)
          Text(
            'Sin fotos (opcional)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          )
        else
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fotosSel.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final foto = _fotosSel[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: _miniaturaFoto(foto),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        onTap: () => _quitarFoto(foto.id!),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _abrirSelectorFotos,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Agregar fotos'),
        ),
      ],
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
