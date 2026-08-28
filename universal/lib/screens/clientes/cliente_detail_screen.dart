import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/cita.dart';
import '../../models/cliente.dart';
import '../../services/cita_service.dart';
import '../../services/cliente_service.dart';
import 'cliente_form_screen.dart';

/// Ficha de un cliente: datos de contacto, notas e historial de citas.
class ClienteDetailScreen extends StatefulWidget {
  const ClienteDetailScreen({super.key, required this.cliente});

  final Cliente cliente;

  @override
  State<ClienteDetailScreen> createState() => _ClienteDetailScreenState();
}

class _ClienteDetailScreenState extends State<ClienteDetailScreen> {
  final _clienteService = ClienteService();
  final _citaService = CitaService();

  late Cliente _cliente;
  late Future<List<Cita>> _citasFuture;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
    _recargarCitas();
  }

  void _recargarCitas() {
    _citasFuture = _citaService.obtenerPorCliente(_cliente.id!);
  }

  Future<void> _editar() async {
    final actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClienteFormScreen(cliente: _cliente),
      ),
    );
    if (actualizado == true) {
      final recargado = await _clienteService.obtenerPorId(_cliente.id!);
      if (recargado != null && mounted) {
        setState(() => _cliente = recargado);
      }
    }
  }

  Future<void> _eliminar() async {
    final citas = await _citaService.obtenerPorCliente(_cliente.id!);
    if (!mounted) {
      return;
    }
    final completadas =
        citas.where((c) => c.estado == EstadoCita.completada).length;

    // Protección: no se borra un cliente con citas completadas (afectaría el
    // historial de ingresos).
    if (completadas > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No se puede eliminar'),
          content: Text(
            '${_cliente.nombre} tiene $completadas cita(s) completada(s) en su '
            'historial contable. Para conservar tus ingresos, este cliente no '
            'se puede eliminar. Puedes editar sus datos.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final otras = citas.length;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text(
          otras > 0
              ? '¿Eliminar a ${_cliente.nombre}? Se eliminarán también sus '
                  '$otras cita(s) pendientes/canceladas. No se puede deshacer.'
              : '¿Eliminar a ${_cliente.nombre}? Esta acción no se puede '
                  'deshacer.',
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
    await _citaService.eliminarPorCliente(_cliente.id!);
    await _clienteService.eliminar(_cliente.id!);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppConstants.msgSucessoEliminar)),
    );
    Navigator.of(context).pop(true);
  }

  String get _telefonoDigitos =>
      _cliente.telefono.replaceAll(RegExp(r'[^0-9]'), '');

  // Para tel:/smsto: se usa el número sin espacios (con el + inicial), ya
  // que algunos marcadores no interpretan bien los espacios en la URI.
  String get _telefonoUri => _cliente.telefono.replaceAll(' ', '');

  Future<void> _lanzar(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la aplicación')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la aplicación')),
        );
      }
    }
  }

  void _accionesTelefono() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                _cliente.telefono,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_cliente.nombre),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.call, color: AppTheme.successColor),
              title: const Text('Llamar'),
              onTap: () {
                Navigator.of(ctx).pop();
                _lanzar(Uri(scheme: 'tel', path: _telefonoUri));
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
              title: const Text('WhatsApp'),
              onTap: () {
                Navigator.of(ctx).pop();
                _lanzar(Uri.parse('https://wa.me/$_telefonoDigitos'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.sms, color: AppTheme.infoColor),
              title: const Text('Enviar SMS'),
              onTap: () {
                Navigator.of(ctx).pop();
                _lanzar(Uri(scheme: 'smsto', path: _telefonoUri));
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar número'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await Clipboard.setData(
                  ClipboardData(text: _cliente.telefono),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Número copiado')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_cliente.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
            onPressed: _editar,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
            onPressed: _eliminar,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildContacto(),
          if (_cliente.notas != null && _cliente.notas!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNotas(),
          ],
          const SizedBox(height: 24),
          Text(
            'Historial de citas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildHistorial(),
        ],
      ),
    );
  }

  Widget _buildContacto() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _lineaTelefono(),
            if (_cliente.email != null && _cliente.email!.isNotEmpty)
              _linea(Icons.email, _cliente.email!),
            if (_cliente.direccion != null && _cliente.direccion!.isNotEmpty)
              _linea(Icons.home, _cliente.direccion!),
            if (_cliente.ultimaVisita != null)
              _linea(
                Icons.event_available,
                'Última visita: '
                '${DateFormat('dd/MM/yyyy').format(_cliente.ultimaVisita!)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotas() {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Notas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_cliente.notas!),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorial() {
    return FutureBuilder<List<Cita>>(
      future: _citasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final citas = snapshot.data ?? const [];
        if (citas.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Aún no hay citas registradas'),
            ),
          );
        }
        return Column(
          children: citas.map(_buildCitaTile).toList(),
        );
      },
    );
  }

  Widget _buildCitaTile(Cita cita) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _colorEstado(cita.estado).withOpacity(0.15),
          child: Icon(Icons.event, color: _colorEstado(cita.estado)),
        ),
        title: Text(cita.nombreServicio ?? 'Servicio'),
        subtitle: Text(
          DateFormat('dd/MM/yyyy · HH:mm').format(cita.fechaHora),
        ),
        trailing: Text(
          cita.monto != null ? '\$${cita.monto!.toStringAsFixed(2)}' : '—',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Color _colorEstado(EstadoCita estado) {
    switch (estado) {
      case EstadoCita.confirmada:
        return Colors.blue;
      case EstadoCita.completada:
        return AppTheme.successColor;
      case EstadoCita.cancelada:
        return AppTheme.errorColor;
      case EstadoCita.pendiente:
        return Colors.orange;
    }
  }

  Widget _linea(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }

  Widget _lineaTelefono() {
    return InkWell(
      onTap: _accionesTelefono,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.phone, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _cliente.telefono,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call, color: AppTheme.successColor),
              tooltip: 'Llamar',
              onPressed: () =>
                  _lanzar(Uri(scheme: 'tel', path: _telefonoUri)),
            ),
            IconButton(
              icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
              tooltip: 'WhatsApp',
              onPressed: () =>
                  _lanzar(Uri.parse('https://wa.me/$_telefonoDigitos')),
            ),
            IconButton(
              icon: const Icon(Icons.sms, color: AppTheme.infoColor),
              tooltip: 'SMS',
              onPressed: () =>
                  _lanzar(Uri(scheme: 'smsto', path: _telefonoUri)),
            ),
          ],
        ),
      ),
    );
  }
}
