import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/ayuda_content.dart';
import '../../config/theme.dart';
import '../../models/cita.dart';
import '../../services/cita_service.dart';
import '../../widgets/ayuda_button.dart';

/// Historial de citas completadas (solo lectura). No permite eliminar para
/// proteger el registro; solo se puede "Reabrir" una cita si fue un error.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _citaService = CitaService();
  final _formatoMoneda = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  List<Cita> _completadas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final citas = await _citaService.obtenerCompletadas();
    citas.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    if (!mounted) {
      return;
    }
    setState(() {
      _completadas = citas;
      _cargando = false;
    });
  }

  Future<void> _reabrir(Cita cita) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reabrir cita'),
        content: const Text(
          'La cita volverá al calendario como Pendiente y se quitará su '
          'ingreso automático de Finanzas. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );
    if (confirmar != true) {
      return;
    }
    await _citaService.cambiarEstado(cita.id!, EstadoCita.pendiente);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita reabierta y devuelta a la agenda')),
      );
    }
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de citas'),
        actions: const [AyudaButton(info: Ayudas.historial)],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildLista(),
    );
  }

  Widget _buildLista() {
    if (_completadas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Sin citas completadas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando completes citas aparecerán aquí',
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _completadas.length,
        itemBuilder: (context, index) {
          final cita = _completadas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1A4CAF50),
                child: Icon(Icons.check_circle, color: AppTheme.successColor),
              ),
              title: Text(cita.nombreCliente ?? 'Cliente'),
              subtitle: Text(
                '${cita.nombreServicio ?? 'Servicio'} · '
                '${DateFormat('dd/MM/yyyy · HH:mm').format(cita.fechaHora)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cita.monto != null)
                    Text(
                      _formatoMoneda.format(cita.monto),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'reabrir') {
                        _reabrir(cita);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'reabrir',
                        child: ListTile(
                          leading: Icon(Icons.undo),
                          title: Text('Reabrir'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
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
