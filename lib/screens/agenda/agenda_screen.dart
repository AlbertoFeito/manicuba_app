import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/cita.dart';
import '../../services/cita_service.dart';
import 'cita_form_screen.dart';

/// Agenda con calendario mensual y la lista de citas del día seleccionado.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _citaService = CitaService();

  final Map<DateTime, List<Cita>> _citasPorDia = {};
  CalendarFormat _formato = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final citas = await _citaService.obtenerTodas();
    if (!mounted) {
      return;
    }
    _citasPorDia.clear();
    for (final cita in citas) {
      // Las citas completadas salen del calendario y pasan al Historial.
      if (cita.estado == EstadoCita.completada) {
        continue;
      }
      final dia = _norm(cita.fechaHora);
      _citasPorDia.putIfAbsent(dia, () => []).add(cita);
    }
    for (final lista in _citasPorDia.values) {
      lista.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    }
    setState(() => _cargando = false);
  }

  List<Cita> _citasDe(DateTime dia) => _citasPorDia[_norm(dia)] ?? const [];

  Future<void> _nuevaCita() async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CitaFormScreen(fechaInicial: _selectedDay),
      ),
    );
    if (guardado == true) {
      await _cargar();
    }
  }

  Future<void> _editarCita(Cita cita) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CitaFormScreen(cita: cita),
      ),
    );
    if (guardado == true) {
      await _cargar();
    }
  }

  void _abrirAcciones(Cita cita) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  cita.nombreCliente ?? 'Cliente',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${cita.nombreServicio ?? 'Servicio'} · '
                  '${DateFormat('dd/MM HH:mm').format(cita.fechaHora)}',
                ),
              ),
              const Divider(height: 1),
              ...EstadoCita.values.map(
                (estado) => ListTile(
                  leading: Icon(Icons.circle, color: _colorEstado(estado)),
                  title: Text('Marcar como ${_estadoTexto(estado)}'),
                  trailing: cita.estado == estado
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _cambiarEstado(cita, estado);
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar cita'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _editarCita(cita);
                },
              ),
              // Las citas completadas no se pueden eliminar (protegen el
              // registro contable); solo se pueden reabrir desde el Historial.
              if (cita.estado != EstadoCita.completada)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppTheme.errorColor),
                  title: const Text('Eliminar cita'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _eliminarCita(cita);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cambiarEstado(Cita cita, EstadoCita estado) async {
    await _citaService.cambiarEstado(cita.id!, estado);
    await _cargar();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cita ${_estadoTexto(estado).toLowerCase()}')),
      );
    }
  }

  Future<void> _eliminarCita(Cita cita) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: const Text('¿Eliminar esta cita? No se puede deshacer.'),
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
    await _citaService.eliminar(cita.id!);
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendario(),
                const Divider(height: 1),
                Expanded(child: _buildListaDelDia()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaCita,
        icon: const Icon(Icons.add),
        label: const Text('Nueva cita'),
      ),
    );
  }

  Widget _buildCalendario() {
    return TableCalendar<Cita>(
      firstDay: DateTime.utc(2020),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _formato,
      locale: 'es_ES',
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Mes',
        CalendarFormat.week: 'Semana',
      },
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: _citasDe,
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected;
          _focusedDay = focused;
        });
      },
      onFormatChanged: (formato) => setState(() => _formato = formato),
      onPageChanged: (focused) => _focusedDay = focused,
      calendarStyle: const CalendarStyle(
        markerDecoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppTheme.primaryLight,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildListaDelDia() {
    final citas = _citasDe(_selectedDay);
    if (citas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Sin citas el '
              '${DateFormat('dd/MM/yyyy').format(_selectedDay)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88, top: 8),
      itemCount: citas.length,
      itemBuilder: (context, index) {
        final cita = citas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('HH:mm').format(cita.fechaHora),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${cita.duracionMinutos}m',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            title: Text(cita.nombreCliente ?? 'Cliente'),
            subtitle: Text(cita.nombreServicio ?? 'Servicio'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _chipEstado(cita.estado),
                if (cita.monto != null)
                  Text(
                    '\$${cita.monto!.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            onTap: () => _abrirAcciones(cita),
          ),
        );
      },
    );
  }

  Widget _chipEstado(EstadoCita estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _colorEstado(estado).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _estadoTexto(estado),
        style: TextStyle(
          fontSize: 11,
          color: _colorEstado(estado),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _colorEstado(EstadoCita estado) {
    switch (estado) {
      case EstadoCita.confirmada:
        return Colors.blue;
      case EstadoCita.completada:
        return AppTheme.successColor;
      case EstadoCita.cancelada:
        return AppTheme.errorColor;
      case EstadoCita.pendiente:
        return Colors.orange;
    }
  }

  String _estadoTexto(EstadoCita estado) {
    switch (estado) {
      case EstadoCita.pendiente:
        return 'Pendiente';
      case EstadoCita.confirmada:
        return 'Confirmada';
      case EstadoCita.completada:
        return 'Completada';
      case EstadoCita.cancelada:
        return 'Cancelada';
    }
  }
}
