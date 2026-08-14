import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../models/cliente.dart';
import '../../services/cliente_service.dart';

/// Formulario para crear o editar un cliente.
///
/// Si [cliente] es `null` se crea uno nuevo; en caso contrario se edita.
class ClienteFormScreen extends StatefulWidget {
  const ClienteFormScreen({super.key, this.cliente});

  final Cliente? cliente;

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  static const _prefijoPais = '+53';

  final _formKey = GlobalKey<FormState>();
  final _clienteService = ClienteService();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _notasCtrl;

  bool _guardando = false;

  bool get _esEdicion => widget.cliente != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: _soloLocal(c?.telefono));
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    _notasCtrl = TextEditingController(text: c?.notas ?? '');
  }

  /// Quita el prefijo "+53" (si ya lo tenía) para mostrar solo el número
  /// local en el campo editable; el prefijo se muestra aparte y se vuelve
  /// a anteponer al guardar.
  String _soloLocal(String? telefono) {
    if (telefono == null) {
      return '';
    }
    final t = telefono.trim();
    if (t.startsWith(_prefijoPais)) {
      return t.substring(_prefijoPais.length).trim();
    }
    return t;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _guardando = true);

    final cliente = Cliente(
      id: widget.cliente?.id,
      nombre: _nombreCtrl.text.trim(),
      telefono: '$_prefijoPais ${_telefonoCtrl.text.trim()}',
      email: _textoONull(_emailCtrl.text),
      direccion: _textoONull(_direccionCtrl.text),
      notas: _textoONull(_notasCtrl.text),
      fechaCreacion: widget.cliente?.fechaCreacion,
      ultimaVisita: widget.cliente?.ultimaVisita,
    );

    try {
      if (_esEdicion) {
        await _clienteService.actualizar(cliente);
      } else {
        await _clienteService.crearCliente(cliente);
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

  String? _textoONull(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.msgCampoRequerido;
    }
    return null;
  }

  String? _validarTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.msgCampoRequerido;
    }
    final soloDigitos = value.replaceAll(RegExp(r'[\s\-()+]'), '');
    if (soloDigitos.length < 6 || !RegExp(r'^\d+$').hasMatch(soloDigitos)) {
      return AppConstants.msgTelefonoInvalido;
    }
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opcional
    }
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    return ok ? null : AppConstants.msgEmailInvalido;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar cliente' : 'Nuevo cliente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: _validarNombre,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono *',
                prefixIcon: Icon(Icons.phone),
                prefixText: '$_prefijoPais  ',
                helperText: 'Escribe solo el número, sin el +53',
              ),
              validator: _validarTelefono,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              validator: _validarEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _direccionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notasCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notas (preferencias, alergias...)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
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
              label: Text(_esEdicion ? 'Guardar cambios' : 'Crear cliente'),
            ),
          ],
        ),
      ),
    );
  }
}
