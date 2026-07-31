import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../models/ingreso.dart';
import '../../services/finanzas_service.dart';

/// Formulario para registrar un ingreso.
class IngresoFormScreen extends StatefulWidget {
  const IngresoFormScreen({super.key});

  @override
  State<IngresoFormScreen> createState() => _IngresoFormScreenState();
}

class _IngresoFormScreenState extends State<IngresoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _finanzasService = FinanzasService();

  final _montoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  String _metodo = AppConstants.metodosPago.first;
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null && mounted) {
      setState(() => _fecha = fecha);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _guardando = true);

    final ingreso = Ingreso(
      monto: double.parse(_montoCtrl.text.replaceAll(',', '.')),
      metodo: _metodo,
      fecha: _fecha,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );

    try {
      await _finanzasService.registrarIngreso(ingreso);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgSucessoGuardar)),
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

  String? _validarMonto(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.msgCampoRequerido;
    }
    final monto = double.tryParse(value.replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      return 'Monto inválido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ingreso')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monto *',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: _validarMonto,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _metodo,
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                prefixIcon: Icon(Icons.payment),
              ),
              items: AppConstants.metodosPago
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (value) => setState(
                () => _metodo = value ?? AppConstants.metodosPago.first,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _seleccionarFecha,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_fecha)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notasCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notas',
                prefixIcon: Icon(Icons.notes),
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
              label: const Text('Guardar ingreso'),
            ),
          ],
        ),
      ),
    );
  }
}
