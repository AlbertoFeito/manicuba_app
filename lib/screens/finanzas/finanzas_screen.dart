import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../services/finanzas_service.dart';
import 'gasto_form_screen.dart';
import 'ingreso_form_screen.dart';

/// Panel de finanzas: balance del periodo, gráfico de gastos por categoría y
/// últimos movimientos. Permite registrar ingresos y gastos.
class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _Movimiento {
  _Movimiento({
    required this.id,
    required this.esIngreso,
    required this.etiqueta,
    required this.monto,
    required this.fecha,
    this.automatico = false,
  });

  final int? id;
  final bool esIngreso;
  final String etiqueta;
  final double monto;
  final DateTime fecha;
  // true si es un ingreso generado por una cita completada (no editable aquí).
  final bool automatico;
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  final _finanzasService = FinanzasService();
  final _formatoMoneda = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  bool _cargando = true;
  Map<String, dynamic> _progresoMes = const {};
  double _balanceHoy = 0;
  double _balanceSemana = 0;
  Map<String, double> _gastosCategoria = const {};
  List<_Movimiento> _movimientos = const [];

  static const List<Color> _paleta = [
    Color(0xFFE91E63),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFF795548),
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final progreso = await _finanzasService.progresoMes();
    final balanceHoy = await _finanzasService.balanceHoy();
    final balanceSemana = await _finanzasService.balanceSemana();
    final gastosCategoria = await _finanzasService.gastosPorCategoria();
    final ingresos = await _finanzasService.obtenerIngresos();
    final gastos = await _finanzasService.obtenerGastos();

    if (!mounted) {
      return;
    }

    final movimientos = <_Movimiento>[
      ...ingresos.map(
        (i) => _Movimiento(
          id: i.id,
          esIngreso: true,
          etiqueta: i.citaId != null
              ? 'Ingreso por cita · ${i.metodo}'
              : 'Ingreso · ${i.metodo}',
          monto: i.monto,
          fecha: i.fecha,
          automatico: i.citaId != null,
        ),
      ),
      ...gastos.map(
        (g) => _Movimiento(
          id: g.id,
          esIngreso: false,
          etiqueta: '${g.concepto} · ${g.categoria}',
          monto: g.monto,
          fecha: g.fecha,
        ),
      ),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));

    setState(() {
      _progresoMes = progreso;
      _balanceHoy = balanceHoy;
      _balanceSemana = balanceSemana;
      _gastosCategoria = gastosCategoria;
      _movimientos = movimientos.take(15).toList();
      _cargando = false;
    });
  }

  Future<void> _registrarIngreso() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const IngresoFormScreen()),
    );
    if (ok == true) {
      await _cargar();
    }
  }

  Future<void> _registrarGasto() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const GastoFormScreen()),
    );
    if (ok == true) {
      await _cargar();
    }
  }

  Future<void> _accionMovimiento(_Movimiento m) async {
    if (m.automatico) {
      // Los ingresos de citas se gestionan desde el Historial, no aquí.
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ingreso de una cita'),
          content: const Text(
            'Este ingreso se generó al completar una cita. Para quitarlo, ve '
            'al Historial de citas (menú ⋮) y usa "Deshacer" en esa cita.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }
    if (m.id == null) {
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar ${m.esIngreso ? 'ingreso' : 'gasto'}'),
        content: Text(
          '¿Eliminar "${m.etiqueta}" por ${_formatoMoneda.format(m.monto)}? '
          'No se puede deshacer.',
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
    if (m.esIngreso) {
      await _finanzasService.eliminarIngreso(m.id!);
    } else {
      await _finanzasService.eliminarGasto(m.id!);
    }
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalanceMes(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniBalance('Hoy', _balanceHoy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniBalance('Semana', _balanceSemana),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _registrarIngreso,
                  icon: const Icon(Icons.add),
                  label: const Text('Ingreso'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _registrarGasto,
                  icon: const Icon(Icons.remove),
                  label: const Text('Gasto'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_gastosCategoria.isNotEmpty) ...[
            Text(
              'Gastos por categoría',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildPieChart(),
            const SizedBox(height: 24),
          ],
          Text(
            'Últimos movimientos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildMovimientos(),
        ],
      ),
    );
  }

  Widget _buildBalanceMes() {
    final ingresos = (_progresoMes['ingresos'] as double?) ?? 0;
    final gastos = (_progresoMes['gastos'] as double?) ?? 0;
    final balance = (_progresoMes['balance'] as double?) ?? 0;
    return Card(
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Balance del mes',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _formatoMoneda.format(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pill('Ingresos', ingresos, Icons.arrow_upward),
                _pill('Gastos', gastos, Icons.arrow_downward),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, double valor, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              _formatoMoneda.format(valor),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniBalance(String label, double valor) {
    final positivo = valor >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              _formatoMoneda.format(valor),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: positivo
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final total = _gastosCategoria.values.fold<double>(0, (a, b) => a + b);
    final entradas = _gastosCategoria.entries.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    for (var i = 0; i < entradas.length; i++)
                      PieChartSectionData(
                        value: entradas[i].value,
                        color: _paleta[i % _paleta.length],
                        title: total > 0
                            ? '${(entradas[i].value / total * 100).round()}%'
                            : '',
                        radius: 55,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (var i = 0; i < entradas.length; i++)
                  _leyenda(
                    _paleta[i % _paleta.length],
                    entradas[i].key,
                    entradas[i].value,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _leyenda(Color color, String texto, double valor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '$texto (${_formatoMoneda.format(valor)})',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMovimientos() {
    if (_movimientos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Aún no hay movimientos registrados')),
      );
    }
    return Column(
      children: _movimientos.map((m) {
        final color =
            m.esIngreso ? AppTheme.successColor : AppTheme.errorColor;
        return Card(
          child: ListTile(
            onTap: () => _accionMovimiento(m),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                m.esIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
              ),
            ),
            title: Text(m.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy').format(m.fecha)}'
              '${m.automatico ? ' · automático' : ''}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${m.esIngreso ? '+' : '-'}${_formatoMoneda.format(m.monto)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                Icon(
                  m.automatico ? Icons.lock_outline : Icons.chevron_right,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
