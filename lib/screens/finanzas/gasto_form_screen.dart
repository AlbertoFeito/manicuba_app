import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../models/gasto.dart';
import '../../services/finanzas_service.dart';

/// Formulario para registrar un gasto.
class GastoFormScreen extends StatefulWidget {
  const GastoFormScreen({super.key});

  @override
  State<GastoFormScreen> createState() => _GastoFormScreenState();
}

class _GastoFormScreenState extends State<GastoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _finanzasService = FinanzasService();

  final _conceptoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  String _categoria = AppConstants.categoriasGastos.first;
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  @override
  void dispose() {
    _conceptoCtrl.dispose();
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

    final gasto = Gasto(
      concepto: _conceptoCtrl.text.trim(),
      monto: double.parse(_montoCtrl.text.replaceAll(',', '.')),
      categoria: _categoria,
      fecha: _fecha,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );

    try {
      await _finanzasService.registrarGasto(gasto);
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

  String? _validarRequerido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.msgCampoRequerido;
    }
    return null;
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
      appBar: AppBar(title: const Text('Registrar gasto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _conceptoCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Concepto *',
                prefixIcon: Icon(Icons.description),
              ),
              validator: _validarRequerido,
            ),
            const SizedBox(height: 16),
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
              value: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category),
              ),
              items: AppConstants.categoriasGastos
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(
                () => _categoria = value ?? AppConstants.categoriasGastos.first,
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
              label: const Text('Guardar gasto'),
            ),
          ],
        ),
      ),
    );
  }
}
