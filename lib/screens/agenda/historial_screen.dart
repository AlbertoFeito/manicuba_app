import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/ayuda_content.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/cita.dart';
import '../../services/cita_service.dart';
import '../../widgets/ayuda_button.dart';

/// Historial de citas que ya salieron del calendario: completadas y
/// canceladas. Las completadas son solo lectura (protegen el ingreso); las
/// canceladas sí se pueden eliminar. Ambas se pueden "Reabrir".
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _citaService = CitaService();
  final _formatoMoneda = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  List<Cita> _historial = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final todas = await _citaService.obtenerTodas();
    final historial = todas
        .where((c) =>
            c.estado == EstadoCita.completada ||
            c.estado == EstadoCita.cancelada)
        .toList()
      ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
    if (!mounted) {
      return;
    }
    setState(() {
      _historial = historial;
      _cargando = false;
    });
  }

  Future<void> _deshacer(Cita cita) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deshacer'),
        content: Text(
          cita.estado == EstadoCita.completada
              ? 'Se deshará el estado: la cita volverá al calendario como '
                  'Pendiente y se quitará su ingreso de Finanzas. Úsalo si la '
                  'marcaste como completada por error. ¿Continuar?'
              : 'Se deshará el estado: la cita volverá al calendario como '
                  'Pendiente. Úsalo si la cancelaste por error. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Deshacer'),
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
        const SnackBar(content: Text('Cita devuelta a la agenda como Pendiente')),
      );
    }
    await _cargar();
  }

  Future<void> _eliminar(Cita cita) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: const Text(
          '¿Eliminar esta cita cancelada? No se puede deshacer.',
        ),
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
    await _citaService.eliminar(cita.id!);
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
        title: const Text('Historial de citas'),
        actions: const [AyudaButton(info: Ayudas.historial)],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildLista(),
    );
  }

  Widget _buildLista() {
    if (_historial.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Historial vacío',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán las citas completadas y canceladas',
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
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _historial.length,
        itemBuilder: (context, index) => _buildTile(_historial[index]),
      ),
    );
  }

  Widget _buildTile(Cita cita) {
    final completada = cita.estado == EstadoCita.completada;
    final color = completada ? AppTheme.successColor : AppTheme.errorColor;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(
            completada ? Icons.check_circle : Icons.cancel,
            color: color,
          ),
        ),
        title: Text(cita.nombreCliente ?? 'Cliente'),
        subtitle: Text(
          '${completada ? 'Completada' : 'Cancelada'} · '
          '${cita.nombreServicio ?? 'Servicio'}\n'
          '${DateFormat('dd/MM/yyyy · HH:mm').format(cita.fechaHora)}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (completada && cita.monto != null)
              Text(
                _formatoMoneda.format(cita.monto),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'deshacer') {
                  _deshacer(cita);
                } else if (value == 'eliminar') {
                  _eliminar(cita);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'deshacer',
                  child: ListTile(
                    leading: Icon(Icons.undo),
                    title: Text('Deshacer'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                // Solo las canceladas se pueden eliminar; las completadas
                // se protegen para no perder el registro de ingresos.
                if (!completada)
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline,
                          color: AppTheme.errorColor),
                      title: Text('Eliminar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
