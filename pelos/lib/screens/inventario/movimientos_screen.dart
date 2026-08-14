import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/movimiento_inventario.dart';
import '../../models/producto.dart';
import '../../services/inventario_service.dart';

/// Historial de entradas y salidas de un producto.
///
/// Responde las dos preguntas que antes la app no podía contestar, porque el
/// stock era un número que se sobreescribía: cuánto compraste y cuánto
/// consumiste.
class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key, required this.producto});

  final Producto producto;

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final _inventarioService = InventarioService();
  final _formatoMoneda = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  final _formatoFecha = DateFormat(AppConstants.formatoFecha);

  List<MovimientoInventario> _movimientos = [];
  Producto? _producto;
  double _compradoMes = 0;
  int _consumidoMes = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final id = widget.producto.id!;
    final movimientos = await _inventarioService.movimientosDe(id);
    final producto = await _inventarioService.obtenerPorId(id);

    // Últimos 30 días, la misma ventana que usa Finanzas para "mes".
    final hoy = DateTime.now();
    final desde = hoy.subtract(const Duration(days: 30));
    final delMes = movimientos
        .where((m) => !m.fecha.isBefore(desde) && !m.fecha.isAfter(hoy));

    if (!mounted) {
      return;
    }
    setState(() {
      _movimientos = movimientos;
      _producto = producto;
      _compradoMes = delMes
          .where((m) => m.esEntrada && m.generoGasto)
          .fold<double>(0, (sum, m) => sum + (m.importe ?? 0));
      _consumidoMes = delMes
          .where((m) => m.esSalida)
          .fold<int>(0, (sum, m) => sum + m.cantidad);
      _cargando = false;
    });
  }

  /// Deshacer una compra borra también su gasto en Finanzas; deshacer una
  /// salida solo devuelve el stock. Es la vía para arreglar un error de
  /// tecleo sin dejar un apunte que no ocurrió.
  Future<void> _deshacer(MovimientoInventario movimiento) async {
    final esCompra = movimiento.generoGasto;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deshacer movimiento'),
        content: Text(
          esCompra
              ? '¿Deshacer esta compra de ${movimiento.cantidad}? Se '
                  'descuenta del stock y se borra su gasto de '
                  '${_formatoMoneda.format(movimiento.importe)} en Finanzas.'
              : '¿Deshacer esta salida de ${movimiento.cantidad}? Las '
                  'unidades vuelven al stock.',
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
            child: const Text('Deshacer'),
          ),
        ],
      ),
    );
    if (confirmar != true) {
      return;
    }

    final resultado =
        await _inventarioService.deshacerMovimiento(movimiento.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            switch (resultado) {
              InventarioService.deshacerOk => 'Movimiento deshecho',
              InventarioService.deshacerNoSePuede =>
                'No se puede: ya gastaste parte de esas unidades. Corrige el '
                    'stock y borra el gasto a mano.',
              _ => AppConstants.msgErrorGeneral,
            },
          ),
        ),
      );
    }
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.producto.nombre)),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildResumen(),
                Expanded(child: _buildLista()),
              ],
            ),
    );
  }

  Widget _buildResumen() {
    final stock = _producto?.cantidadStock ?? widget.producto.cantidadStock;
    return Padding(
      padding: const EdgeInsets.all(12),
      // Igual que en la lista: los títulos son de distinto largo.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _tarjeta(
                icon: Icons.inventory_2,
                titulo: 'En stock',
                valor: '$stock',
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _tarjeta(
                icon: Icons.shopping_cart,
                titulo: 'Comprado (30 días)',
                valor: _formatoMoneda.format(_compradoMes),
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _tarjeta(
                icon: Icons.trending_down,
                titulo: 'Usado (30 días)',
                valor: '$_consumidoMes',
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta({
    required IconData icon,
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
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
    );
  }

  Widget _buildLista() {
    if (_movimientos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Sin movimientos todavía',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí aparecerán las compras y las salidas de este producto.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _movimientos.length,
        itemBuilder: (context, index) {
          final movimiento = _movimientos[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              // Los ajustes no se deshacen: se vuelven a corregir.
              onTap: movimiento.esEntrada || movimiento.esSalida
                  ? () => _deshacer(movimiento)
                  : null,
              leading: CircleAvatar(
                backgroundColor: _colorDe(movimiento).withOpacity(0.15),
                child: Icon(_iconoDe(movimiento), color: _colorDe(movimiento)),
              ),
              title: Text(
                '${movimiento.esSalida ? '−' : '+'}${movimiento.cantidad} · '
                '${movimiento.etiquetaMotivo}',
              ),
              subtitle: Text(
                [
                  _formatoFecha.format(movimiento.fecha),
                  if (movimiento.notas != null &&
                      movimiento.notas!.trim().isNotEmpty)
                    movimiento.notas!,
                ].join(' · '),
              ),
              trailing: movimiento.importe != null && movimiento.generoGasto
                  ? Text(
                      _formatoMoneda.format(movimiento.importe),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  IconData _iconoDe(MovimientoInventario movimiento) {
    if (movimiento.esEntrada) {
      return movimiento.generoGasto ? Icons.shopping_cart : Icons.inventory;
    }
    if (movimiento.esSalida) {
      return Icons.trending_down;
    }
    return Icons.fact_check;
  }

  Color _colorDe(MovimientoInventario movimiento) {
    if (movimiento.esEntrada) {
      return AppTheme.primaryColor;
    }
    if (movimiento.esSalida) {
      return AppTheme.successColor;
    }
    return AppTheme.errorColor;
  }
}
