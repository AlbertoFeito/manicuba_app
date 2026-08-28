import 'package:flutter/material.dart';

import '../../config/ayuda_content.dart';
import '../../config/business_config.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/servicio.dart';
import '../../services/servicio_service.dart';
import '../../widgets/ayuda_button.dart';
import 'servicio_form_screen.dart';

/// Catálogo de servicios ofrecidos (precio y duración).
class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  final _servicioService = ServicioService();

  List<Servicio> _servicios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final servicios = await _servicioService.obtenerTodos();
    if (!mounted) {
      return;
    }
    setState(() {
      _servicios = servicios;
      _cargando = false;
    });
  }

  Future<void> _abrirFormulario({Servicio? servicio}) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServicioFormScreen(servicio: servicio),
      ),
    );
    if (guardado == true) {
      await _cargar();
    }
  }

  Future<void> _eliminar(Servicio servicio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: Text('¿Eliminar "${servicio.nombre}" del catálogo?'),
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
    await _servicioService.eliminar(servicio.id!);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppConstants.msgSucessoEliminar)),
    );
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios'),
        actions: const [AyudaButton(info: Ayudas.servicios)],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_servicios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spa_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Sin servicios en el catálogo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pulsa "Nuevo" para agregar un servicio',
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
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88, top: 8),
        itemCount: _servicios.length,
        itemBuilder: (context, index) {
          final servicio = _servicios[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                child: Icon(AppConfig.instance.current.iconoServicios, color: AppTheme.primaryColor),
              ),
              title: Text(servicio.nombre),
              subtitle: Text(
                '${servicio.duracionMinutos} min'
                '${servicio.descripcion != null ? ' · ${servicio.descripcion}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${servicio.precio.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') {
                        _abrirFormulario(servicio: servicio);
                      } else if (value == 'eliminar') {
                        _eliminar(servicio);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () => _abrirFormulario(servicio: servicio),
            ),
          );
        },
      ),
    );
  }
}
