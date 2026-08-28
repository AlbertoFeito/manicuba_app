import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/cita.dart';
import '../../models/gasto.dart';
import '../../models/ingreso.dart';
import '../../services/cita_service.dart';
import '../../services/finanzas_service.dart';
import 'gasto_form_screen.dart';
import 'ingreso_form_screen.dart';

/// Periodo por el que se filtran los movimientos, el gráfico y las
/// analíticas.
enum _Periodo { hoy, semana, mes, todo }

extension _PeriodoLabel on _Periodo {
  String get label {
    switch (this) {
      case _Periodo.hoy:
        return 'Hoy';
      case _Periodo.semana:
        return 'Semana';
      case _Periodo.mes:
        return 'Mes';
      case _Periodo.todo:
        return 'Todo';
    }
  }
}

/// Qué sección del panel se muestra bajo el filtro de periodo.
enum _Vista { resumen, analiticas }

class _Movimiento {
  _Movimiento({
    required this.esIngreso,
    required this.etiqueta,
    required this.monto,
    required this.fecha,
    this.ingreso,
    this.gasto,
  });

  final bool esIngreso;
  final String etiqueta;
  final double monto;
  final DateTime fecha;
  final Ingreso? ingreso;
  final Gasto? gasto;

  /// true si lo generó la app sola —un ingreso de cita completada o un gasto
  /// de compra de inventario— y por tanto no se toca desde aquí: hay que
  /// corregirlo donde se originó, o los dos módulos dejarían de cuadrar.
  bool get automatico => ingreso?.citaId != null || gasto?.productoId != null;

  /// true si el gasto lo creó una compra registrada en Inventario.
  bool get esCompraInventario => gasto?.productoId != null;

  int? get id => ingreso?.id ?? gasto?.id;
}

/// Resumen de indicadores (KPIs) financieros para un periodo.
class _Kpis {
  const _Kpis({
    required this.ingresos,
    required this.gastos,
    required this.balance,
    required this.ticketPromedio,
    required this.transacciones,
    required this.margen,
  });

  final double ingresos;
  final double gastos;
  final double balance;
  final double ticketPromedio;
  final int transacciones;
  final double margen;
}

/// Un punto de la serie diaria (para el gráfico de tendencia).
class _PuntoDia {
  _PuntoDia(this.fecha, this.ingresos, this.gastos);
  final DateTime fecha;
  final double ingresos;
  final double gastos;
}

/// Un elemento de un ranking (servicio o cliente) con su total acumulado.
class _TopItem {
  _TopItem(this.nombre);
  final String nombre;
  double total = 0;
  int veces = 0;
}

/// Panel de finanzas: balance del periodo elegido, movimientos y una vista de
/// Analíticas con más estadísticas (comparación con el periodo anterior,
/// tendencia diaria, métodos de pago, servicios y clientes más rentables).
class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  final _finanzasService = FinanzasService();
  final _citaService = CitaService();
  final _formatoMoneda = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  final _formatoFechaCorta = DateFormat('d/M');

  bool _cargando = true;

  // Balances fijos "de un vistazo" (independientes del filtro de periodo).
  double _balanceHoyFijo = 0;
  double _balanceSemanaFijo = 0;

  // Datos crudos; las vistas filtradas se calculan según el periodo.
  List<Ingreso> _ingresos = const [];
  List<Gasto> _gastos = const [];
  List<Cita> _citasCompletadas = const [];

  _Periodo _periodo = _Periodo.mes;

  /// Día fijado en la gráfica de tendencia (índice dentro de la serie).
  /// Se queda marcado hasta que se toque otro punto o el mismo otra vez.
  int? _diaFijado;
  _Vista _vista = _Vista.resumen;

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
    final balanceHoy = await _finanzasService.balanceHoy();
    final balanceSemana = await _finanzasService.balanceSemana();
    final ingresos = await _finanzasService.obtenerIngresos();
    final gastos = await _finanzasService.obtenerGastos();
    final citas = await _citaService.obtenerCompletadas();

    if (!mounted) {
      return;
    }

    setState(() {
      _balanceHoyFijo = balanceHoy;
      _balanceSemanaFijo = balanceSemana;
      _ingresos = ingresos;
      _gastos = gastos;
      _citasCompletadas = citas;
      _cargando = false;
    });
  }

  // ===== Filtros de periodo =====

  bool _enPeriodo(DateTime fecha) {
    final ahora = DateTime.now();
    switch (_periodo) {
      case _Periodo.hoy:
        return fecha.year == ahora.year &&
            fecha.month == ahora.month &&
            fecha.day == ahora.day;
      case _Periodo.semana:
        return fecha.isAfter(ahora.subtract(const Duration(days: 7)));
      case _Periodo.mes:
        return fecha.isAfter(ahora.subtract(const Duration(days: 30)));
      case _Periodo.todo:
        return true;
    }
  }

  /// El mismo largo de ventana que [_enPeriodo], pero desplazada al bloque
  /// anterior (para comparar). No aplica a "Todo".
  bool _enPeriodoAnterior(DateTime fecha) {
    final ahora = DateTime.now();
    switch (_periodo) {
      case _Periodo.hoy:
        final ayer = DateTime(ahora.year, ahora.month, ahora.day)
            .subtract(const Duration(days: 1));
        return fecha.year == ayer.year &&
            fecha.month == ayer.month &&
            fecha.day == ayer.day;
      case _Periodo.semana:
        final inicioActual = ahora.subtract(const Duration(days: 7));
        final inicioAnterior = ahora.subtract(const Duration(days: 14));
        return fecha.isAfter(inicioAnterior) && fecha.isBefore(inicioActual);
      case _Periodo.mes:
        final inicioActual = ahora.subtract(const Duration(days: 30));
        final inicioAnterior = ahora.subtract(const Duration(days: 60));
        return fecha.isAfter(inicioAnterior) && fecha.isBefore(inicioActual);
      case _Periodo.todo:
        return false;
    }
  }

  List<_Movimiento> get _movimientos {
    final lista = <_Movimiento>[
      for (final i in _ingresos)
        if (_enPeriodo(i.fecha))
          _Movimiento(
            esIngreso: true,
            etiqueta: i.citaId != null
                ? 'Ingreso por cita · ${i.metodo}'
                : 'Ingreso · ${i.metodo}',
            monto: i.monto,
            fecha: i.fecha,
            ingreso: i,
          ),
      for (final g in _gastos)
        if (_enPeriodo(g.fecha))
          _Movimiento(
            esIngreso: false,
            etiqueta: '${g.concepto} · ${g.categoria}',
            monto: g.monto,
            fecha: g.fecha,
            gasto: g,
          ),
    ]..sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  Map<String, double> get _gastosCategoria {
    final mapa = <String, double>{};
    for (final g in _gastos) {
      if (_enPeriodo(g.fecha)) {
        mapa.update(g.categoria, (v) => v + g.monto, ifAbsent: () => g.monto);
      }
    }
    return mapa;
  }

  // ===== Analíticas =====

  _Kpis _calcularKpis(bool Function(DateTime) filtro) {
    final ingresosF = _ingresos.where((i) => filtro(i.fecha)).toList();
    final gastosF = _gastos.where((g) => filtro(g.fecha)).toList();
    final totalIngresos = ingresosF.fold<double>(0, (s, i) => s + i.monto);
    final totalGastos = gastosF.fold<double>(0, (s, g) => s + g.monto);
    final balance = totalIngresos - totalGastos;
    final ticket = ingresosF.isEmpty ? 0.0 : totalIngresos / ingresosF.length;
    final margen = totalIngresos > 0 ? (balance / totalIngresos * 100) : 0.0;
    return _Kpis(
      ingresos: totalIngresos,
      gastos: totalGastos,
      balance: balance,
      ticketPromedio: ticket,
      transacciones: ingresosF.length + gastosF.length,
      margen: margen,
    );
  }

  _Kpis get _kpisActual => _calcularKpis(_enPeriodo);
  _Kpis get _kpisAnterior => _calcularKpis(_enPeriodoAnterior);

  Map<String, double> get _metodoPagoPeriodo {
    final mapa = <String, double>{};
    for (final i in _ingresos) {
      if (_enPeriodo(i.fecha)) {
        mapa.update(i.metodo, (v) => v + i.monto, ifAbsent: () => i.monto);
      }
    }
    return mapa;
  }

  List<_TopItem> _construirTop(String Function(Cita) claveDe) {
    final mapa = <String, _TopItem>{};
    for (final c in _citasCompletadas) {
      if (!_enPeriodo(c.fechaHora)) {
        continue;
      }
      final clave = claveDe(c);
      final item = mapa.putIfAbsent(clave, () => _TopItem(clave));
      item.total += c.monto ?? 0;
      item.veces += 1;
    }
    final lista = mapa.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return lista.take(5).toList();
  }

  List<_TopItem> get _topServicios =>
      _construirTop((c) => c.nombreServicio ?? 'Servicio');

  List<_TopItem> get _topClientes =>
      _construirTop((c) => c.nombreCliente ?? 'Cliente');

  /// Días de la serie diaria para el gráfico de tendencia; null si el
  /// periodo elegido es demasiado corto para que un gráfico diario aporte
  /// algo (p. ej. "Hoy").
  int? get _diasTendencia {
    switch (_periodo) {
      case _Periodo.hoy:
        return null;
      case _Periodo.semana:
        return 7;
      case _Periodo.mes:
      case _Periodo.todo:
        return 30;
    }
  }

  List<_PuntoDia> _serieDiaria(int dias) {
    final hoy = DateTime.now();
    final inicio =
        DateTime(hoy.year, hoy.month, hoy.day).subtract(Duration(days: dias - 1));
    return [
      for (var i = 0; i < dias; i++) _puntoDelDia(inicio.add(Duration(days: i))),
    ];
  }

  _PuntoDia _puntoDelDia(DateTime dia) {
    final fin = dia.add(const Duration(days: 1));
    final ingresosDia = _ingresos
        .where((i) => !i.fecha.isBefore(dia) && i.fecha.isBefore(fin))
        .fold<double>(0, (s, i) => s + i.monto);
    final gastosDia = _gastos
        .where((g) => !g.fecha.isBefore(dia) && g.fecha.isBefore(fin))
        .fold<double>(0, (s, g) => s + g.monto);
    return _PuntoDia(dia, ingresosDia, gastosDia);
  }

  // ===== Acciones =====

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
      // Los movimientos automáticos se corrigen donde se originaron: los
      // ingresos en el Historial de citas, los gastos en Inventario.
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            m.esCompraInventario
                ? 'Gasto de una compra'
                : 'Ingreso de una cita',
          ),
          content: Text(
            m.esCompraInventario
                ? 'Este gasto se generó al registrar una compra en '
                    'Inventario. Para quitarlo, ve a Inventario, abre el '
                    'producto y usa "Deshacer" en esa compra: se borra el '
                    'gasto y el stock vuelve a como estaba.'
                : 'Este ingreso se generó al completar una cita. Para '
                    'quitarlo, ve al Historial de citas (menú ⋮) y usa '
                    '"Deshacer" en esa cita.',
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
    final accion = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                m.etiqueta,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${m.esIngreso ? '+' : '-'}${_formatoMoneda.format(m.monto)}',
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () => Navigator.of(ctx).pop('editar'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: const Text('Eliminar'),
              onTap: () => Navigator.of(ctx).pop('eliminar'),
            ),
          ],
        ),
      ),
    );
    if (accion == 'editar') {
      await _editarMovimiento(m);
    } else if (accion == 'eliminar') {
      await _eliminarMovimiento(m);
    }
  }

  Future<void> _editarMovimiento(_Movimiento m) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => m.esIngreso
            ? IngresoFormScreen(ingreso: m.ingreso)
            : GastoFormScreen(gasto: m.gasto),
      ),
    );
    if (ok == true) {
      await _cargar();
    }
  }

  Future<void> _eliminarMovimiento(_Movimiento m) async {
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

  // ===== UI =====

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
          _buildHero(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniBalance('Hoy', _balanceHoyFijo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniBalance('Semana', _balanceSemanaFijo),
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
          const SizedBox(height: 20),
          _buildSelectorVista(),
          const SizedBox(height: 12),
          _buildFiltroPeriodo(),
          const SizedBox(height: 16),
          ...(_vista == _Vista.resumen
              ? _buildResumenBody()
              : _buildAnaliticasBody()),
        ],
      ),
    );
  }

  Widget _buildSelectorVista() {
    return SegmentedButton<_Vista>(
      segments: const [
        ButtonSegment(
          value: _Vista.resumen,
          label: Text('Resumen'),
          icon: Icon(Icons.dashboard_outlined),
        ),
        ButtonSegment(
          value: _Vista.analiticas,
          label: Text('Analíticas'),
          icon: Icon(Icons.insights),
        ),
      ],
      selected: {_vista},
      onSelectionChanged: (seleccion) =>
          setState(() => _vista = seleccion.first),
    );
  }

  Widget _buildFiltroPeriodo() {
    return Row(
      children: [
        for (final p in _Periodo.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p.label),
              selected: _periodo == p,
              onSelected: (_) => setState(() {
                _periodo = p;
                // Otro periodo es otra serie: el índice fijado ya no señala
                // al mismo día.
                _diaFijado = null;
              }),
            ),
          ),
      ],
    );
  }

  // --- Resumen ---

  List<Widget> _buildResumenBody() {
    return [
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
        'Movimientos · ${_periodo.label}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      _buildMovimientos(),
    ];
  }

  Widget _buildHero() {
    final k = _kpisActual;
    return Card(
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance · ${_periodo.label}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _formatoMoneda.format(k.balance),
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
                _pill('Ingresos', k.ingresos, Icons.arrow_upward),
                _pill('Gastos', k.gastos, Icons.arrow_downward),
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
                color:
                    positivo ? AppTheme.successColor : AppTheme.errorColor,
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
        child: Center(child: Text('No hay movimientos en este periodo')),
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
            title:
                Text(m.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
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

  // --- Analíticas ---

  List<Widget> _buildAnaliticasBody() {
    final comparacion = _buildComparacion();
    return [
      _buildKpis(),
      if (comparacion != null) ...[
        const SizedBox(height: 16),
        comparacion,
      ],
      const SizedBox(height: 16),
      _buildTendencia(),
      const SizedBox(height: 16),
      _buildMetodoPago(),
      const SizedBox(height: 16),
      _buildTopLista(
        'Servicios más vendidos',
        Icons.spa,
        _topServicios,
      ),
      const SizedBox(height: 16),
      _buildTopLista(
        'Mejores clientes',
        Icons.people,
        _topClientes,
      ),
    ];
  }

  Widget _buildKpis() {
    final k = _kpisActual;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _statCard(
          'Ingresos',
          _formatoMoneda.format(k.ingresos),
          Icons.arrow_upward,
          AppTheme.successColor,
        ),
        _statCard(
          'Gastos',
          _formatoMoneda.format(k.gastos),
          Icons.arrow_downward,
          AppTheme.errorColor,
        ),
        _statCard(
          'Balance',
          _formatoMoneda.format(k.balance),
          Icons.account_balance_wallet,
          k.balance >= 0 ? AppTheme.successColor : AppTheme.errorColor,
        ),
        _statCard(
          'Ticket promedio',
          _formatoMoneda.format(k.ticketPromedio),
          Icons.receipt_long,
          AppTheme.primaryColor,
        ),
        _statCard(
          'Transacciones',
          '${k.transacciones}',
          Icons.swap_horiz,
          AppTheme.infoColor,
        ),
        _statCard(
          'Margen',
          '${k.margen.toStringAsFixed(0)}%',
          Icons.trending_up,
          AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildComparacion() {
    if (_periodo == _Periodo.todo) {
      // "Todo" no tiene un periodo anterior con el que comparar.
      return null;
    }
    final actual = _kpisActual;
    final anterior = _kpisAnterior;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparado con el periodo anterior',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _filaComparacionPorcentaje(
              'Ingresos',
              actual.ingresos,
              anterior.ingresos,
            ),
            _filaComparacionPorcentaje(
              'Gastos',
              actual.gastos,
              anterior.gastos,
              subirEsBueno: false,
            ),
            _filaComparacionMonto('Balance', actual.balance, anterior.balance),
          ],
        ),
      ),
    );
  }

  Widget _filaComparacionPorcentaje(
    String label,
    double actual,
    double anterior, {
    bool subirEsBueno = true,
  }) {
    String textoDelta;
    Color color;
    IconData icon;
    if (anterior == 0) {
      if (actual == 0) {
        textoDelta = 'Sin cambios';
        color = Colors.grey;
        icon = Icons.remove;
      } else {
        textoDelta = 'Nuevo';
        color = subirEsBueno ? AppTheme.successColor : AppTheme.errorColor;
        icon = Icons.fiber_new;
      }
    } else {
      final delta = ((actual - anterior) / anterior) * 100;
      final subio = delta >= 0;
      textoDelta = '${subio ? '+' : ''}${delta.toStringAsFixed(0)}%';
      final esBueno = subio == subirEsBueno;
      color = esBueno ? AppTheme.successColor : AppTheme.errorColor;
      icon = subio ? Icons.trending_up : Icons.trending_down;
    }
    return _filaComparacionBase(label, actual, textoDelta, color, icon);
  }

  Widget _filaComparacionMonto(String label, double actual, double anterior) {
    final delta = actual - anterior;
    final mejoro = delta >= 0;
    final color = mejoro ? AppTheme.successColor : AppTheme.errorColor;
    final texto = '${mejoro ? '+' : ''}${_formatoMoneda.format(delta)}';
    return _filaComparacionBase(
      label,
      actual,
      texto,
      color,
      mejoro ? Icons.trending_up : Icons.trending_down,
    );
  }

  Widget _filaComparacionBase(
    String label,
    double actual,
    String textoDelta,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            _formatoMoneda.format(actual),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 2),
              Text(
                textoDelta,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTendencia() {
    final dias = _diasTendencia;
    if (dias == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Elige "Semana" o "Mes" para ver la tendencia diaria.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final serie = _serieDiaria(dias);
    var maxY = 0.0;
    for (final p in serie) {
      if (p.ingresos > maxY) maxY = p.ingresos;
      if (p.gastos > maxY) maxY = p.gastos;
    }
    final intervaloEtiqueta = (dias / 5).ceil().clamp(1, dias).toDouble();

    // Al cambiar de periodo la serie cambia de tamaño; si el índice fijado
    // quedó fuera, se ignora en vez de reventar.
    final fijado =
        (_diaFijado != null && _diaFijado! < serie.length) ? _diaFijado : null;

    final lineaIngresos = _lineaSerie(
      serie.map((p) => p.ingresos).toList(),
      AppTheme.successColor,
      fijado,
    );
    final lineaGastos = _lineaSerie(
      serie.map((p) => p.gastos).toList(),
      AppTheme.errorColor,
      fijado,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _periodo == _Periodo.todo
                    ? 'Tendencia · últimos 30 días'
                    : 'Tendencia diaria',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY <= 0 ? 10 : maxY * 1.2,
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: intervaloEtiqueta,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= serie.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _formatoFechaCorta.format(serie[i].fecha),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    // Sin gestión automática: así el punto no se borra al
                    // levantar el dedo, se queda fijado.
                    handleBuiltInTouches: false,
                    // Por defecto solo detecta el toque a menos de 10 px del
                    // punto; con pocos días quedan muy separados y la mayoría
                    // de los toques no hacían nada. Sin límite, un toque en
                    // cualquier parte de la gráfica fija el día más cercano.
                    touchSpotThreshold: double.infinity,
                    touchCallback: (evento, respuesta) {
                      if (evento is! FlTapUpEvent) {
                        return;
                      }
                      final tocados = respuesta?.lineBarSpots;
                      if (tocados == null || tocados.isEmpty) {
                        return;
                      }
                      final indice = tocados.first.spotIndex;
                      setState(() {
                        // Tocar el mismo punto otra vez lo suelta.
                        _diaFijado = _diaFijado == indice ? null : indice;
                      });
                    },
                    getTouchedSpotIndicator: (barra, indices) {
                      final color = barra.color ?? AppTheme.primaryColor;
                      return indices
                          .map(
                            (_) => TouchedSpotIndicatorData(
                              FlLine(color: color, strokeWidth: 2),
                              FlDotData(
                                getDotPainter: (spot, porcentaje, datos, i) =>
                                    FlDotCirclePainter(
                                  radius: 5,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                  strokeColor: color,
                                ),
                              ),
                            ),
                          )
                          .toList();
                    },
                  ),
                  lineBarsData: [lineaIngresos, lineaGastos],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dotLeyenda('Ingresos', AppTheme.successColor),
                const SizedBox(width: 16),
                _dotLeyenda('Gastos', AppTheme.errorColor),
              ],
            ),
            const SizedBox(height: 10),
            _detalleDiaFijado(fijado, serie),
          ],
        ),
      ),
    );
  }

  LineChartBarData _lineaSerie(
    List<double> valores,
    Color color,
    int? fijado,
  ) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < valores.length; i++)
          FlSpot(i.toDouble(), valores[i]),
      ],
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
      // Marca el día fijado en las dos series a la vez, para poder comparar
      // ingresos y gastos del mismo día.
      showingIndicators: fijado == null ? const [] : [fijado],
    );
  }

  /// Cifras del día fijado en la tendencia. Se muestran bajo la gráfica en
  /// vez de en un globo flotante: en una pantalla de móvil el globo se queda
  /// sin sitio y tapa los propios puntos.
  Widget _detalleDiaFijado(int? fijado, List<_PuntoDia> serie) {
    if (fijado == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          'Toca un punto para fijarlo y ver las cifras de ese día.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final punto = serie[fijado];
    final balance = punto.ingresos - punto.gastos;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE d MMM', 'es_ES').format(punto.fecha),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Soltar',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _diaFijado = null),
              ),
            ],
          ),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _cifraDia('Ingresos', punto.ingresos, AppTheme.successColor),
              _cifraDia('Gastos', punto.gastos, AppTheme.errorColor),
              _cifraDia(
                'Balance',
                balance,
                balance >= 0 ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cifraDia(String etiqueta, double monto, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$etiqueta ', style: const TextStyle(fontSize: 12)),
        Text(
          _formatoMoneda.format(monto),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _dotLeyenda(String texto, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMetodoPago() {
    final mapa = _metodoPagoPeriodo;
    if (mapa.isEmpty) {
      return const SizedBox.shrink();
    }
    final total = mapa.values.fold<double>(0, (a, b) => a + b);
    final entradas = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos por método de pago',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final e in entradas) _barraMetodo(e.key, e.value, total),
          ],
        ),
      ),
    );
  }

  Widget _barraMetodo(String metodo, double valor, double total) {
    final pct = total > 0 ? valor / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(metodo, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${_formatoMoneda.format(valor)} · ${(pct * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLista(String titulo, IconData icon, List<_TopItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(titulo, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin citas completadas en este periodo',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              for (var i = 0; i < items.length; i++) _filaTop(i + 1, items[i]),
          ],
        ),
      ),
    );
  }

  Widget _filaTop(int rango, _TopItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
            child: Text(
              '$rango',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.nombre, overflow: TextOverflow.ellipsis),
          ),
          Text(
            '${item.veces}x',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Text(
            _formatoMoneda.format(item.total),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
