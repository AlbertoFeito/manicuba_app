import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../models/servicio.dart';
import '../../services/servicio_service.dart';

/// Formulario para crear o editar un servicio del catálogo.
class ServicioFormScreen extends StatefulWidget {
  const ServicioFormScreen({super.key, this.servicio});

  final Servicio? servicio;

  @override
  State<ServicioFormScreen> createState() => _ServicioFormScreenState();
}

class _ServicioFormScreenState extends State<ServicioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _servicioService = ServicioService();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _duracionCtrl;
  late final TextEditingController _descripcionCtrl;

  bool _guardando = false;

  bool get _esEdicion => widget.servicio != null;

  @override
  void initState() {
    super.initState();
    final s = widget.servicio;
    _nombreCtrl = TextEditingController(text: s?.nombre ?? '');
    _precioCtrl = TextEditingController(
      text: s != null ? s.precio.toStringAsFixed(2) : '',
    );
    _duracionCtrl = TextEditingController(
      text: s != null ? s.duracionMinutos.toString() : '',
    );
    _descripcionCtrl = TextEditingController(text: s?.descripcion ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _duracionCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _guardando = true);

    final servicio = Servicio(
      id: widget.servicio?.id,
      nombre: _nombreCtrl.text.trim(),
      precio: double.parse(_precioCtrl.text.replaceAll(',', '.')),
      duracionMinutos: int.parse(_duracionCtrl.text.trim()),
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
    );

    try {
      if (_esEdicion) {
        await _servicioService.actualizar(servicio);
      } else {
        await _servicioService.crearServicio(servicio);
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

  String? _validarPrecio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.msgCampoRequerido;
    }
    final precio = double.tryParse(value.replaceAll(',', '.'));
    if (precio == null || precio < 0) {
      return 'Precio inválido';
    }
    return null;
  }

  String? _validarDuracion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.msgCampoRequerido;
    }
    final min = int.tryParse(value.trim());
    if (min == null || min <= 0) {
      return 'Duración inválida';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar servicio' : 'Nuevo servicio'),
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
                prefixIcon: Icon(Icons.spa),
              ),
              validator: _validarRequerido,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio *',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: _validarPrecio,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _duracionCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duración (minutos) *',
                prefixIcon: Icon(Icons.schedule),
              ),
              validator: _validarDuracion,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción',
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
              label: Text(_esEdicion ? 'Guardar cambios' : 'Crear servicio'),
            ),
          ],
        ),
      ),
    );
  }
}
