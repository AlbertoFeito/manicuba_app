import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/ayuda_content.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/producto.dart';
import '../../services/inventario_service.dart';
import '../../widgets/ayuda_button.dart';
import 'producto_form_screen.dart';

/// Inventario de productos: stock, alertas de bajo stock y valor total.
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
    if (!mounted) {
      return;
    }
    setState(() {
      _productos = productos;
      _valorTotal = valor;
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

  Future<void> _ajustarStock(Producto producto, int delta) async {
    if (delta > 0) {
      await _inventarioService.aumentarStock(producto.id!, delta);
    } else {
      await _inventarioService.disminuirStock(producto.id!, -delta);
    }
    await _cargar();
  }

  Future<void> _eliminar(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${producto.nombre}" del inventario?'),
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
    // InventarioService no expone delete; usamos el helper de la DB vía servicio.
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
      child: Row(
        children: [
          Expanded(
            child: _tarjetaResumen(
              icon: Icons.account_balance_wallet,
              titulo: 'Valor total',
              valor: _formatoMoneda.format(_valorTotal),
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _tarjetaResumen(
              icon: Icons.warning_amber,
              titulo: _soloBajoStock ? 'Bajo stock (activo)' : 'Bajo stock',
              valor: '$_bajoStock',
              color:
                  _bajoStock > 0 ? AppTheme.errorColor : AppTheme.successColor,
              onTap: _bajoStock > 0
                  ? () => setState(() => _soloBajoStock = !_soloBajoStock)
                  : null,
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(titulo, style: Theme.of(context).textTheme.bodySmall),
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
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: producto.cantidadStock > 0
                        ? () => _ajustarStock(producto, -1)
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
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _ajustarStock(producto, 1),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') {
                        _abrirFormulario(producto: producto);
                      } else if (value == 'eliminar') {
                        _eliminar(producto);
                      }
                    },
                    itemBuilder: (_) => const [
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
