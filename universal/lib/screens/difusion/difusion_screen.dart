// Parte del Asistente de Promociones (ver docs/ASISTENTE_PROMOCIONES.md).
//
// Envía una promoción a las clientas una por una (WhatsApp/SMS). Se elige el
// grupo (todas / frecuentes / inactivas), se edita el mensaje y se abre el
// chat de cada clienta con el texto precargado.

import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../services/difusion_service.dart';

class DifusionScreen extends StatefulWidget {
  const DifusionScreen({
    super.key,
    required this.mensaje,
    this.filtroInicial = FiltroClientas.todas,
  });

  final String mensaje;
  final FiltroClientas filtroInicial;

  @override
  State<DifusionScreen> createState() => _DifusionScreenState();
}

class _DifusionScreenState extends State<DifusionScreen> {
  final _difusion = DifusionService();
  late final TextEditingController _mensajeCtrl;

  late FiltroClientas _filtro;
  bool _cargando = true;
  List<Cliente> _clientas = [];

  // Clientas a las que ya se abrió el mensaje en esta sesión.
  final Set<int> _enviadas = {};

  @override
  void initState() {
    super.initState();
    _mensajeCtrl = TextEditingController(text: widget.mensaje);
    _filtro = widget.filtroInicial;
    _cargar();
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final clientas = await _difusion.obtenerClientas(_filtro);
    if (!mounted) {
      return;
    }
    setState(() {
      _clientas = clientas;
      _cargando = false;
    });
  }

  void _cambiarFiltro(FiltroClientas filtro) {
    if (filtro == _filtro) {
      return;
    }
    setState(() => _filtro = filtro);
    _cargar();
  }

  Future<void> _enviarWhatsApp(Cliente c) async {
    final ok = await _difusion.enviarWhatsApp(c, _mensajeCtrl.text);
    if (!mounted) {
      return;
    }
    if (ok && c.id != null) {
      setState(() => _enviadas.add(c.id!));
    } else if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  Future<void> _enviarSms(Cliente c) async {
    final ok = await _difusion.enviarSms(c, _mensajeCtrl.text);
    if (!mounted) {
      return;
    }
    if (ok && c.id != null) {
      setState(() => _enviadas.add(c.id!));
    } else if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir SMS')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar a clientas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _mensajeCtrl,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: 'Mensaje',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _chip('Todas', FiltroClientas.todas),
                const SizedBox(width: 8),
                _chip('Frecuentes', FiltroClientas.frecuentes),
                const SizedBox(width: 8),
                _chip('Inactivas', FiltroClientas.inactivas),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _clientas.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No hay clientas en este grupo.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _clientas.length,
                        itemBuilder: (_, i) => _fila(_clientas[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, FiltroClientas filtro) {
    return ChoiceChip(
      label: Text(label),
      selected: _filtro == filtro,
      onSelected: (_) => _cambiarFiltro(filtro),
    );
  }

  Widget _fila(Cliente c) {
    final enviada = c.id != null && _enviadas.contains(c.id);
    return ListTile(
      leading: enviada
          ? const Icon(Icons.check_circle, color: Color(0xFF25D366))
          : const Icon(Icons.person_outline),
      title: Text(c.nombre),
      subtitle: Text(c.telefono),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
            tooltip: 'WhatsApp',
            onPressed: () => _enviarWhatsApp(c),
          ),
          IconButton(
            icon: const Icon(Icons.sms),
            tooltip: 'SMS',
            onPressed: () => _enviarSms(c),
          ),
        ],
      ),
    );
  }
}
