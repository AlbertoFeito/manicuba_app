import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../models/producto.dart';
import '../../services/inventario_service.dart';

/// Formulario para crear o editar un producto del inventario.
class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({super.key, this.producto});

  final Producto? producto;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inventarioService = InventarioService();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minimoCtrl;
  late final TextEditingController _costoCtrl;
  late final TextEditingController _proveedorCtrl;

  late String _categoria;
  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _stockCtrl = TextEditingController(
      text: p != null ? p.cantidadStock.toString() : '',
    );
    _minimoCtrl = TextEditingController(
      text: p != null ? p.cantidadMinima.toString() : '',
    );
    _costoCtrl = TextEditingController(
      text: p != null ? p.costoUnitario.toStringAsFixed(2) : '',
    );
    _proveedorCtrl = TextEditingController(text: p?.proveedor ?? '');
    _categoria = p?.categoria ?? AppConstants.categoriasProductos.first;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _stockCtrl.dispose();
    _minimoCtrl.dispose();
    _costoCtrl.dispose();
    _proveedorCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _guardando = true);

    final producto = Producto(
      id: widget.producto?.id,
      nombre: _nombreCtrl.text.trim(),
      categoria: _categoria,
      cantidadStock: int.parse(_stockCtrl.text.trim()),
      cantidadMinima: int.parse(_minimoCtrl.text.trim()),
      costoUnitario: double.parse(_costoCtrl.text.replaceAll(',', '.')),
      proveedor:
          _proveedorCtrl.text.trim().isEmpty ? null : _proveedorCtrl.text.trim(),
      fechaCompra: widget.producto?.fechaCompra,
      fechaCreacion: widget.producto?.fechaCreacion,
    );

    try {
      if (_esEdicion) {
        await _inventarioService.actualizar(producto);
      } else {
        await _inventarioService.crearProducto(producto);
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

  String? _validarEntero(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.msgCampoRequerido;
    }
    final n = int.tryParse(value.trim());
    if (n == null || n < 0) {
      return 'Cantidad inválida';
    }
    return null;
  }

  String? _validarCosto(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.msgCampoRequerido;
    }
    final n = double.tryParse(value.replaceAll(',', '.'));
    if (n == null || n < 0) {
      return 'Costo inválido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
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
                prefixIcon: Icon(Icons.inventory_2),
              ),
              validator: _validarRequerido,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category),
              ),
              items: AppConstants.categoriasProductos
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(
                () =>
                    _categoria = value ?? AppConstants.categoriasProductos.first,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock *',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: _validarEntero,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minimoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mínimo *',
                      prefixIcon: Icon(Icons.warning_amber),
                    ),
                    validator: _validarEntero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Costo unitario *',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: _validarCosto,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _proveedorCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Proveedor',
                prefixIcon: Icon(Icons.store),
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
              label: Text(_esEdicion ? 'Guardar cambios' : 'Crear producto'),
            ),
          ],
        ),
      ),
    );
  }
}
