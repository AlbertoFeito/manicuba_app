import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../models/producto.dart';
import '../../services/categoria_service.dart';
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
  final _categoriaService = CategoriaService();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minimoCtrl;
  late final TextEditingController _costoCtrl;
  late final TextEditingController _proveedorCtrl;
  final _nuevaCategoriaCtrl = TextEditingController();

  late String _categoria;
  List<String> _categorias = AppConstants.categoriasProductos;
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
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final categorias = await _categoriaService.obtenerCategorias();
    // Si el producto tiene una categoría "legado" que ya no está en la
    // lista (de fábrica ni personalizada), se agrega igual para no romper
    // el selector.
    final lista = List<String>.from(categorias);
    if (_categoria.isNotEmpty && !lista.contains(_categoria)) {
      lista.insert(lista.length - 1, _categoria);
    }
    if (!mounted) {
      return;
    }
    setState(() => _categorias = lista);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _stockCtrl.dispose();
    _minimoCtrl.dispose();
    _costoCtrl.dispose();
    _proveedorCtrl.dispose();
    _nuevaCategoriaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _guardando = true);

    var categoriaFinal = _categoria;
    if (_categoria == 'Otros') {
      categoriaFinal = _nuevaCategoriaCtrl.text.trim();
      await _categoriaService.agregarCategoria(categoriaFinal);
    }

    final producto = Producto(
      id: widget.producto?.id,
      nombre: _nombreCtrl.text.trim(),
      categoria: categoriaFinal,
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
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() {
                _categoria = value ?? _categorias.first;
                if (_categoria != 'Otros') {
                  _nuevaCategoriaCtrl.clear();
                }
              }),
            ),
            if (_categoria == 'Otros') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _nuevaCategoriaCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nueva categoría *',
                  prefixIcon: Icon(Icons.add_circle_outline),
                  helperText: 'Quedará guardada para tus próximos productos',
                ),
                validator: (value) {
                  if (_categoria == 'Otros' &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Escribe el nombre de la nueva categoría';
                  }
                  return null;
                },
              ),
            ],
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
