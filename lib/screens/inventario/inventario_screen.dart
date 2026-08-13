import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/ayuda_content.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/producto.dart';
import '../../services/inventario_service.dart';
import '../../widgets/ayuda_button.dart';
import 'dialogos_stock.dart';
import 'movimientos_screen.dart';
import 'producto_form_screen.dart';

/// Inventario de productos: stock, alertas de bajo stock y valor total.
///
/// Las entradas de stock son compras y generan el gasto en Finanzas; las
/// salidas solo descuentan, porque ese dinero ya salió al comprar.
class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _inventarioService = InventarioService();
  final _formatoMoneda = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  final _busquedaCtrl = TextEditingController();

  List<Producto> _productos = [];
  double _valorTotal = 0;
  double _compradoMes = 0;
  int _bajoStock = 0;
  bool _cargando = true;
  bool _soloBajoStock = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final productos = await _inventarioService.obtenerTodos();
    final valor = await _inventarioService.valorTotalInventario();
    final comprado = await _inventarioService.compradoUltimoMes();
    if (!mounted) {
      return;
    }
    setState(() {
      _productos = productos;
      _valorTotal = valor;
      _compradoMes = comprado;
      _bajoStock = productos.where((p) => p.bajoStock).length;
      _cargando = false;
    });
  }

  List<Producto> get _filtrados {
    final q = _busquedaCtrl.text.trim().toLowerCase();
    return _productos.where((p) {
      final coincide = q.isEmpty ||
          p.nombre.toLowerCase().contains(q) ||
          p.categoria.toLowerCase().contains(q);
      final pasaBajoStock = !_soloBajoStock || p.bajoStock;
      return coincide && pasaBajoStock;
    }).toList();
  }

  Future<void> _abrirFormulario({Producto? producto}) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductoFormScreen(producto: producto),
      ),
    );
    if (guardado == true) {
      await _cargar();
    }
  }

  Future<void> _verHistorial(Producto producto) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovimientosScreen(producto: producto),
      ),
    );
    await _cargar();
  }

  /// Entrada de stock: sube el stock y registra el gasto en Finanzas.
  Future<void> _registrarCompra(Producto producto) async {
    final datos = await mostrarDialogoCompra(context, producto);
    if (datos == null) {
      return;
    }
    final gasto = await _inventarioService.registrarCompra(
      productoId: producto.id!,
      cantidad: datos.cantidad,
      totalPagado: datos.totalPagado,
      fecha: datos.fecha,
      proveedor: datos.proveedor,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gasto != null
                ? 'Entraron ${datos.cantidad}. Gasto de '
                    '${_formatoMoneda.format(gasto.monto)} registrado en Finanzas'
                : 'Entraron ${datos.cantidad} sin costo',
          ),
        ),
      );
    }
    await _cargar();
  }

  /// Salida de stock: no toca Finanzas, el gasto se hizo al comprar.
  Future<void> _registrarSalida(Producto producto) async {
    final datos = await mostrarDialogoSalida(context, producto);
    if (datos == null) {
      return;
    }
    final descontado = await _inventarioService.registrarSalida(
      productoId: producto.id!,
      cantidad: datos.cantidad,
      motivo: datos.motivo,
    );
    if (mounted && descontado > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Descontaste $descontado de ${producto.nombre}')),
      );
    }
    await _cargar();
  }

  Future<void> _corregirStock(Producto producto) async {
    final datos = await mostrarDialogoCorreccion(context, producto);
    if (datos == null) {
      return;
    }
    final cambio = await _inventarioService.registrarCorreccion(
      productoId: producto.id!,
      nuevoStock: datos.stock,
      nuevoCosto: datos.costoUnitario,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cambio
                ? '${producto.nombre} corregido'
                : 'Ya estaba correcto, no cambió nada',
          ),
        ),
      );
    }
    await _cargar();
  }

  Future<void> _eliminar(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${producto.nombre}" del inventario?\n\n'
          'Se borra el producto y su historial. Los gastos de sus compras se '
          'quedan en Finanzas, porque ese dinero salió de verdad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) {
      return;
    }
    await _inventarioService.eliminar(producto.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppConstants.msgSucessoEliminar)),
      );
    }
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: const [AyudaButton(info: Ayudas.inventario)],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildResumen(),
                _buildBusqueda(),
                Expanded(child: _buildLista()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildResumen() {
    return Padding(
      padding: const EdgeInsets.all(12),
      // Los títulos tienen distinto largo y uno ocupa dos líneas: sin esto
      // las tarjetas quedarían de alturas distintas.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _tarjetaResumen(
                icon: Icons.account_balance_wallet,
                titulo: 'Valor total',
                valor: _formatoMoneda.format(_valorTotal),
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _tarjetaResumen(
                icon: Icons.shopping_cart,
                titulo: 'Comprado (30 días)',
                valor: _formatoMoneda.format(_compradoMes),
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _tarjetaResumen(
                icon: Icons.warning_amber,
                titulo: _soloBajoStock ? 'Bajo stock (activo)' : 'Bajo stock',
                valor: '$_bajoStock',
                color: _bajoStock > 0
                    ? AppTheme.errorColor
                    : AppTheme.successColor,
                onTap: _bajoStock > 0
                    ? () => setState(() => _soloBajoStock = !_soloBajoStock)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusqueda() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: _busquedaCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Buscar por nombre o categoría',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _busquedaCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _busquedaCtrl.clear()),
                ),
        ),
      ),
    );
  }

  Widget _tarjetaResumen({
    required IconData icon,
    required String titulo,
    required String valor,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              // El valor puede ser largo ($1,234.56) y la tarjeta es estrecha:
              // se encoge en vez de desbordar.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  valor,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Inventario vacío',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pulsa "Nuevo" para agregar un producto',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }
    final lista = _filtrados;
    if (lista.isEmpty) {
      return Center(
        child: Text(
          _soloBajoStock
              ? 'No hay productos con bajo stock'
              : 'Sin resultados para tu búsqueda',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: lista.length,
        itemBuilder: (context, index) {
          final producto = lista[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              onTap: () => _verHistorial(producto),
              leading: CircleAvatar(
                backgroundColor: producto.bajoStock
                    ? AppTheme.errorColor.withOpacity(0.15)
                    : AppTheme.primaryColor.withOpacity(0.15),
                child: Icon(
                  Icons.inventory_2,
                  color: producto.bajoStock
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      producto.nombre,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (producto.bajoStock)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Bajo',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                '${producto.categoria} · '
                '${_formatoMoneda.format(producto.costoUnitario)} c/u',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Descontar stock',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: producto.cantidadStock > 0
                        ? () => _registrarSalida(producto)
                        : null,
                  ),
                  Text(
                    '${producto.cantidadStock}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Registrar compra',
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _registrarCompra(producto),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'historial':
                          _verHistorial(producto);
                        case 'corregir':
                          _corregirStock(producto);
                        case 'editar':
                          _abrirFormulario(producto: producto);
                        case 'eliminar':
                          _eliminar(producto);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'historial',
                        child: Text('Ver historial'),
                      ),
                      PopupMenuItem(
                        value: 'corregir',
                        child: Text('Corregir stock'),
                      ),
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
