import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/producto.dart';

final _formatoMoneda = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _formatoFecha = DateFormat(AppConstants.formatoFecha);

/// Datos de una compra confirmada por la usuaria.
class DatosCompra {
  const DatosCompra({
    required this.cantidad,
    required this.totalPagado,
    required this.fecha,
    this.proveedor,
  });

  final int cantidad;
  final double totalPagado;
  final DateTime fecha;
  final String? proveedor;
}

/// Datos de una salida de stock confirmada por la usuaria.
class DatosSalida {
  const DatosSalida({required this.cantidad, required this.motivo});

  final int cantidad;
  final String motivo;
}

/// Pregunta cuántas unidades entraron y cuánto se pagó. El total es lo que
/// se registra como gasto en Finanzas, así que se pide explícitamente en vez
/// de deducirlo del costo guardado, que puede haber cambiado de precio.
Future<DatosCompra?> mostrarDialogoCompra(
  BuildContext context,
  Producto producto,
) {
  return showDialog<DatosCompra>(
    context: context,
    builder: (_) => _DialogoCompra(producto: producto),
  );
}

/// Pregunta cuántas unidades salieron y por qué. No mueve dinero: el gasto
/// se registró al comprar.
Future<DatosSalida?> mostrarDialogoSalida(
  BuildContext context,
  Producto producto,
) {
  return showDialog<DatosSalida>(
    context: context,
    builder: (_) => _DialogoSalida(producto: producto),
  );
}

/// Pregunta cuánto hay de verdad tras un conteo físico.
Future<int?> mostrarDialogoCorreccion(
  BuildContext context,
  Producto producto,
) {
  return showDialog<int>(
    context: context,
    builder: (_) => _DialogoCorreccion(producto: producto),
  );
}

class _DialogoCompra extends StatefulWidget {
  const _DialogoCompra({required this.producto});

  final Producto producto;

  @override
  State<_DialogoCompra> createState() => _DialogoCompraState();
}

class _DialogoCompraState extends State<_DialogoCompra> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController(text: '1');
  late final TextEditingController _totalCtrl;
  late final TextEditingController _proveedorCtrl;

  DateTime _fecha = DateTime.now();

  /// Mientras la usuaria no toque el total, se recalcula solo al cambiar la
  /// cantidad. En cuanto lo escribe a mano, mandan sus números.
  bool _totalEditadoAMano = false;

  @override
  void initState() {
    super.initState();
    _totalCtrl = TextEditingController(
      text: widget.producto.costoUnitario > 0
          ? widget.producto.costoUnitario.toStringAsFixed(2)
          : '',
    );
    _proveedorCtrl = TextEditingController(text: widget.producto.proveedor ?? '');
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _totalCtrl.dispose();
    _proveedorCtrl.dispose();
    super.dispose();
  }

  int get _cantidad => int.tryParse(_cantidadCtrl.text.trim()) ?? 0;

  double get _total =>
      double.tryParse(_totalCtrl.text.trim().replaceAll(',', '.')) ?? 0;

  void _alCambiarCantidad() {
    if (!_totalEditadoAMano && widget.producto.costoUnitario > 0) {
      final sugerido = _cantidad * widget.producto.costoUnitario;
      _totalCtrl.text = sugerido > 0 ? sugerido.toStringAsFixed(2) : '';
    }
    setState(() {});
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (elegida != null) {
      setState(() => _fecha = elegida);
    }
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      DatosCompra(
        cantidad: _cantidad,
        totalPagado: _total,
        fecha: _fecha,
        proveedor: _proveedorCtrl.text.trim().isEmpty
            ? null
            : _proveedorCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitario = _cantidad > 0 ? _total / _cantidad : 0.0;

    return AlertDialog(
      title: Text('Comprar ${widget.producto.nombre}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _cantidadCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Unidades que entran *',
                  prefixIcon: Icon(Icons.add_box),
                ),
                onChanged: (_) => _alCambiarCantidad(),
                validator: (value) {
                  final n = int.tryParse((value ?? '').trim());
                  if (n == null || n <= 0) {
                    return 'Escribe cuántas entraron';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Total que pagaste *',
                  prefixIcon: Icon(Icons.payments),
                  helperText: 'Esto es lo que se registra como gasto',
                ),
                onChanged: (_) => setState(() => _totalEditadoAMano = true),
                validator: (value) {
                  final n = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );
                  if (n == null || n < 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              if (_cantidad > 0 && _total > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Te sale a ${_formatoMoneda.format(unitario)} cada una',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _proveedorCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Proveedor',
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Fecha de la compra'),
                subtitle: Text(_formatoFecha.format(_fecha)),
                trailing: TextButton(
                  onPressed: _elegirFecha,
                  child: const Text('Cambiar'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Registrar compra'),
        ),
      ],
    );
  }
}

class _DialogoSalida extends StatefulWidget {
  const _DialogoSalida({required this.producto});

  final Producto producto;

  @override
  State<_DialogoSalida> createState() => _DialogoSalidaState();
}

class _DialogoSalidaState extends State<_DialogoSalida> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController(text: '1');
  String _motivo = AppConstants.motivoConsumo;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      DatosSalida(
        cantidad: int.parse(_cantidadCtrl.text.trim()),
        motivo: _motivo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Descontar ${widget.producto.nombre}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _cantidadCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Unidades que salen *',
                prefixIcon: const Icon(Icons.remove_circle_outline),
                helperText: 'Tienes ${widget.producto.cantidadStock}',
              ),
              validator: (value) {
                final n = int.tryParse((value ?? '').trim());
                if (n == null || n <= 0) {
                  return 'Escribe cuántas salieron';
                }
                if (n > widget.producto.cantidadStock) {
                  return 'Solo tienes ${widget.producto.cantidadStock}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _motivo,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                prefixIcon: Icon(Icons.help_outline),
              ),
              items: AppConstants.motivosSalida
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(AppConstants.etiquetasMotivo[m] ?? m),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(
                () => _motivo = value ?? AppConstants.motivoConsumo,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esto no genera ningún gasto: ese dinero salió cuando compraste '
              'el producto.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Descontar'),
        ),
      ],
    );
  }
}

class _DialogoCorreccion extends StatefulWidget {
  const _DialogoCorreccion({required this.producto});

  final Producto producto;

  @override
  State<_DialogoCorreccion> createState() => _DialogoCorreccionState();
}

class _DialogoCorreccionState extends State<_DialogoCorreccion> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stockCtrl;

  @override
  void initState() {
    super.initState();
    _stockCtrl = TextEditingController(
      text: widget.producto.cantidadStock.toString(),
    );
  }

  @override
  void dispose() {
    _stockCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(int.parse(_stockCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Corregir stock'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cuenta lo que tienes de verdad y escríbelo aquí. Se usa para '
              'cuadrar el inventario, no cambia tus finanzas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Unidades reales *',
                prefixIcon: const Icon(Icons.fact_check),
                helperText: 'La app tiene apuntadas '
                    '${widget.producto.cantidadStock}',
              ),
              validator: (value) {
                final n = int.tryParse((value ?? '').trim());
                if (n == null || n < 0) {
                  return 'Cantidad inválida';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          onPressed: _confirmar,
          child: const Text('Corregir'),
        ),
      ],
    );
  }
}
