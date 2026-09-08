// Parte del Asistente de Promociones (ver docs/ASISTENTE_PROMOCIONES.md).
//
// Muestra las sugerencias de promoción generadas por AsistenteService. Cada
// tarjeta abre el formulario de post precargado con el borrador de la
// sugerencia; también se puede descartar.

import 'package:flutter/material.dart';

import '../../models/sugerencia_promo.dart';
import '../../services/asistente_service.dart';
import '../../services/difusion_service.dart';
import '../../services/redes_service.dart';
import '../difusion/difusion_screen.dart';
import '../redes_sociales/post_form_screen.dart';

class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final _asistente = AsistenteService();
  final _redes = RedesService();

  bool _cargando = true;
  List<SugerenciaPromo> _sugerencias = [];
  Map<String, int> _stats = const {};

  // Sugerencias descartadas en esta sesión (por id), para no volver a
  // mostrarlas tras recargar.
  final Set<String> _descartadas = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final todas = await _asistente.generarSugerencias();
    final stats = await _redes.estadisticasPromocion();
    if (!mounted) {
      return;
    }
    setState(() {
      _sugerencias =
          todas.where((s) => !_descartadas.contains(s.id)).toList();
      _stats = stats;
      _cargando = false;
    });
  }

  Future<void> _crearDesde(SugerenciaPromo s) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostFormScreen(plantilla: s.borrador),
      ),
    );
    if (guardado == true && mounted) {
      // Publicado/guardado: la sugerencia ya se atendió, se retira.
      setState(() {
        _descartadas.add(s.id);
        _sugerencias = _sugerencias.where((x) => x.id != s.id).toList();
      });
    }
  }

  Future<void> _difundir(SugerenciaPromo s) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DifusionScreen(
          mensaje: s.borrador.getContenidoFormateado(),
          filtroInicial: FiltroClientas.inactivas,
        ),
      ),
    );
  }

  void _descartar(SugerenciaPromo s) {
    setState(() {
      _descartadas.add(s.id);
      _sugerencias = _sugerencias.where((x) => x.id != s.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de promociones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _resumen(),
                const SizedBox(height: 8),
                if (_sugerencias.isEmpty)
                  _vacio()
                else
                  ..._sugerencias.map(_tarjeta),
              ],
            ),
    );
  }

  Widget _resumen() {
    final posts = _stats['posts_creados'] ?? 0;
    final ofertas = _stats['ofertas_promocionadas'] ?? 0;
    final compartidas = _stats['fotos_compartidas'] ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('$posts', 'Posts'),
            _stat('$ofertas', 'Ofertas'),
            _stat('$compartidas', 'Fotos'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String valor, String etiqueta) {
    return Column(
      children: [
        Text(valor, style: Theme.of(context).textTheme.titleLarge),
        Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _vacio() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '¡Todo al día!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'No hay sugerencias de promoción por ahora. '
            'Vuelve más tarde o crea un post desde la pestaña de Redes.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(SugerenciaPromo s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(s.icono)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.motivo,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _descartar(s),
                  child: const Text('Descartar'),
                ),
                if (s.clienteIds.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _difundir(s),
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar a clientas'),
                  ),
                FilledButton.icon(
                  onPressed: () => _crearDesde(s),
                  icon: const Icon(Icons.edit),
                  label: const Text('Crear post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
