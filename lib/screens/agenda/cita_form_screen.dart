import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../models/cita.dart';
import '../../models/cliente.dart';
import '../../models/servicio.dart';
import '../../services/cita_service.dart';
import '../../services/cliente_service.dart';
import '../../services/servicio_service.dart';

/// Formulario para crear o editar una cita.
class CitaFormScreen extends StatefulWidget {
  const CitaFormScreen({super.key, this.cita, this.fechaInicial});

  final Cita? cita;
  final DateTime? fechaInicial;

  @override
  State<CitaFormScreen> createState() => _CitaFormScreenState();
}

class _CitaFormScreenState extends State<CitaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _citaService = CitaService();
  final _clienteService = ClienteService();
  final _servicioService = ServicioService();

  final _montoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  List<Cliente> _clientes = [];
  List<Servicio> _servicios = [];

  int? _clienteId;
  Servicio? _servicio;
  late DateTime _fechaHora;
  EstadoCita _estado = EstadoCita.pendiente;

  bool _cargando = true;
  bool _guardando = false;

  bool get _esEdicion => widget.cita != null;

  @override
  void initState() {
    super.initState();
    final c = widget.cita;
    _fechaHora = c?.fechaHora ?? _fechaPorDefecto();
    _estado = c?.estado ?? EstadoCita.pendiente;
    _clienteId = c?.clienteId;
    _montoCtrl.text = c?.monto != null ? c!.monto!.toStringAsFixed(2) : '';
    _notasCtrl.text = c?.notas ?? '';
    _cargarDatos();
  }

  DateTime _fechaPorDefecto() {
    final base = widget.fechaInicial ?? DateTime.now();
    return DateTime(base.year, base.month, base.day, 10, 0);
  }

  Future<void> _cargarDatos() async {
    final clientes = await _clienteService.obtenerTodos();
    final servicios = await _servicioService.obtenerTodos();
    if (!mounted) {
      return;
    }
    setState(() {
      _clientes = clientes;
      _servicios = servicios;
      if (_esEdicion) {
        _servicio = servicios.firstWhere(
          (s) => s.id == widget.cita!.servicioId,
          orElse: () => servicios.isNotEmpty
              ? servicios.first
              : Servicio(nombre: '—', precio: 0, duracionMinutos: 30),
        );
      }
      _cargando = false;
    });
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  void _onServicioSeleccionado(Servicio? servicio) {
    if (servicio == null) {
      return;
    }
    setState(() {
      _servicio = servicio;
      // Rellena el monto con el precio del servicio si está vacío.
      if (_montoCtrl.text.trim().isEmpty) {
        _montoCtrl.text = servicio.precio.toStringAsFixed(2);
      }
    });
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaHora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha == null || !mounted) {
      return;
    }
    setState(() {
      _fechaHora = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        _fechaHora.hour,
        _fechaHora.minute,
      );
    });
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaHora),
    );
    if (hora == null || !mounted) {
      return;
    }
    setState(() {
      _fechaHora = DateTime(
        _fechaHora.year,
        _fechaHora.month,
        _fechaHora.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_clienteId == null || _servicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un cliente y un servicio'),
        ),
      );
      return;
    }
    setState(() => _guardando = true);

    final montoTexto = _montoCtrl.text.trim().replaceAll(',', '.');
    final cita = Cita(
      id: widget.cita?.id,
      clienteId: _clienteId!,
      servicioId: _servicio!.id!,
      fechaHora: _fechaHora,
      duracionMinutos: _servicio!.duracionMinutos,
      estado: _estado,
      monto: montoTexto.isEmpty ? null : double.tryParse(montoTexto),
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      fechaCreacion: widget.cita?.fechaCreacion,
    );

    try {
      if (_esEdicion) {
        await _citaService.actualizar(cita);
      } else {
        await _citaService.crearCita(cita);
      }
      // Actualiza la última visita del cliente si la cita queda completada.
      if (_estado == EstadoCita.completada) {
        await _clienteService.actualizarUltimaVisita(_clienteId!);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar cita' : 'Nueva cita'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    if (_clientes.isEmpty || _servicios.isEmpty) {
      return _buildFaltanDatos();
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            value: _clienteId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Cliente *',
              prefixIcon: Icon(Icons.person),
            ),
            items: _clientes
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.nombre, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _clienteId = value),
            validator: (value) =>
                value == null ? AppConstants.msgCampoRequerido : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Servicio>(
            value: _servicio,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Servicio *',
              prefixIcon: Icon(Icons.spa),
            ),
            items: _servicios
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      '${s.nombre} (${s.duracionMinutos} min)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _onServicioSeleccionado,
            validator: (value) =>
                value == null ? AppConstants.msgCampoRequerido : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSelector(
                  icon: Icons.calendar_today,
                  label: 'Fecha',
                  valor: DateFormat('dd/MM/yyyy').format(_fechaHora),
                  onTap: _seleccionarFecha,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelector(
                  icon: Icons.access_time,
                  label: 'Hora',
                  valor: DateFormat('HH:mm').format(_fechaHora),
                  onTap: _seleccionarHora,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<EstadoCita>(
            value: _estado,
            decoration: const InputDecoration(
              labelText: 'Estado',
              prefixIcon: Icon(Icons.flag),
            ),
            items: EstadoCita.values
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(_estadoTexto(e)),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _estado = value ?? EstadoCita.pendiente),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixIcon: Icon(Icons.attach_money),
              helperText: 'Se rellena con el precio del servicio',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notasCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notas',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
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
            label: Text(_esEdicion ? 'Guardar cambios' : 'Crear cita'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaltanDatos() {
    final falta = _clientes.isEmpty ? 'clientes' : 'servicios';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Faltan $falta',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Necesitas al menos un cliente y un servicio '
              'para crear una cita.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelector({
    required IconData icon,
    required String label,
    required String valor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        child: Text(valor),
      ),
    );
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
