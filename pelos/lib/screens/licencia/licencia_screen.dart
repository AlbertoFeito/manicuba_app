import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/theme.dart';
import '../../services/licencia_service.dart';

/// Pantalla de licencia: muestra el código de equipo y permite activar con el
/// código que envía el vendedor. También se usa como "muro" cuando la prueba
/// vence (parámetro [bloqueante]).
class LicenciaScreen extends StatefulWidget {
  const LicenciaScreen({super.key, this.bloqueante = false, this.onActivada});

  /// Si es true, no se puede volver atrás hasta activar (prueba vencida).
  final bool bloqueante;
  final VoidCallback? onActivada;

  @override
  State<LicenciaScreen> createState() => _LicenciaScreenState();
}

class _LicenciaScreenState extends State<LicenciaScreen> {
  final _lic = LicenciaService.instance;
  final _codigoCtrl = TextEditingController();

  String _deviceId = '';
  LicenciaEstado? _estado;
  bool _cargando = true;
  bool _activando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final id = await _lic.deviceId();
    final est = await _lic.estado();
    if (!mounted) {
      return;
    }
    setState(() {
      _deviceId = id;
      _estado = est;
      _cargando = false;
    });
  }

  Future<void> _activar() async {
    setState(() {
      _activando = true;
      _error = null;
    });
    final ok = await _lic.activar(_codigoCtrl.text);
    if (!mounted) {
      return;
    }
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Licencia activada! Gracias 💇')),
      );
      widget.onActivada?.call();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        await _cargar();
      }
    } else {
      setState(() {
        _activando = false;
        _error = 'Código incorrecto para este equipo. Revísalo e intenta de '
            'nuevo.';
      });
    }
  }

  String get _codigoFmt => LicenciaService.formatDeviceId(_deviceId);

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: _codigoFmt));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de equipo copiado')),
      );
    }
  }

  Future<void> _compartir() async {
    await Share.share(
      'Hola, quiero activar PeluCuba 💇. Mi código de equipo es: $_codigoFmt',
      subject: 'Licencia PeluCuba',
    );
  }

  @override
  Widget build(BuildContext context) {
    final activa = _estado?.tipo == LicenciaTipo.activa;
    return PopScope(
      canPop: !widget.bloqueante || activa,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Licencia'),
          automaticallyImplyLeading: !widget.bloqueante || activa,
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildEstado(),
                  const SizedBox(height: 24),
                  if (!activa) ...[
                    _buildCodigoEquipo(),
                    const SizedBox(height: 24),
                    _buildActivacion(),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildEstado() {
    final estado = _estado!;
    late final Color color;
    late final IconData icon;
    late final String titulo;
    late final String detalle;

    switch (estado.tipo) {
      case LicenciaTipo.activa:
        color = AppTheme.successColor;
        icon = Icons.verified;
        titulo = 'Licencia activa';
        detalle = '¡Gracias! Tienes acceso completo, sin vencimiento.';
        break;
      case LicenciaTipo.prueba:
        color = AppTheme.infoColor;
        icon = Icons.hourglass_bottom;
        titulo = 'Prueba gratis';
        detalle = 'Te quedan ${estado.diasRestantes} día(s) de prueba. '
            'Actívala cuando quieras para no perder el acceso.';
        break;
      case LicenciaTipo.vencida:
        color = AppTheme.errorColor;
        icon = Icons.lock;
        titulo = 'Prueba vencida';
        detalle = 'Tu prueba de ${LicenciaService.trialDays} días terminó. '
            'Activa una licencia para seguir usando la app.';
        break;
    }

    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: color,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(detalle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodigoEquipo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu código de equipo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Envíaselo al vendedor para recibir tu licencia. Es único de '
              'este teléfono.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            SelectableText(
              _codigoFmt,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copiar,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _compartir,
                    icon: const Icon(Icons.share),
                    label: const Text('Enviar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivacion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activar licencia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codigoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Código de licencia',
                prefixIcon: const Icon(Icons.vpn_key),
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _activando ? null : _activar,
                icon: _activando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: const Text('Activar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
