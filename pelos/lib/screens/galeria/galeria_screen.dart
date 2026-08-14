import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/ayuda_content.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/foto_trabajo.dart';
import '../../services/foto_service.dart';
import '../../widgets/ayuda_button.dart';

/// Galería de fotos de trabajo. Permite añadir fotos desde la cámara o la
/// galería del teléfono, verlas, compartirlas y eliminarlas.
class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({super.key});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  final _fotoService = FotoService();
  final _picker = ImagePicker();

  List<FotoTrabajo> _fotos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final fotos = await _fotoService.obtenerTodas();
    if (!mounted) {
      return;
    }
    setState(() {
      _fotos = fotos;
      _cargando = false;
    });
  }

  Future<void> _agregarFoto(ImageSource source) async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (imagen == null) {
        return;
      }
      await _fotoService.guardarDesdeArchivo(File(imagen.path));
      await _cargar();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo agregar la foto')),
        );
      }
    }
  }

  void _mostrarOpcionesAgregar() {
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
                _agregarFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.of(ctx).pop();
                _agregarFoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verFoto(FotoTrabajo foto) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              child: Image.file(File(foto.rutaFoto), fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _compartir(foto);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.errorColor),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _eliminar(foto);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _compartir(FotoTrabajo foto) async {
    await Share.shareXFiles(
      [XFile(foto.rutaFoto)],
      text: foto.descripcion ?? '¡Mira este trabajo! 💇',
    );
  }

  Future<void> _eliminar(FotoTrabajo foto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Eliminar esta foto? No se puede deshacer.'),
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
    await _fotoService.eliminar(foto);
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
      appBar: AppBar(
        title: const Text('Galería de trabajos'),
        actions: const [AyudaButton(info: Ayudas.galeria)],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildGaleria(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarOpcionesAgregar,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _buildGaleria() {
    if (_fotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Sin fotos todavía',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega fotos de tus trabajos para compartirlas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _fotos.length,
        itemBuilder: (context, index) {
          final foto = _fotos[index];
          return GestureDetector(
            onTap: () => _verFoto(foto),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(foto.rutaFoto), fit: BoxFit.cover),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black45,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        DateFormat('dd/MM/yy').format(foto.fecha),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
