import 'package:flutter/material.dart';

import '../../services/licencia_service.dart';
import 'licencia_screen.dart';

/// Envuelve la app: arranca la prueba en el primer uso. Después de 15 días
/// bloquea la app y muestra solo la pantalla de licencia hasta que se active.
class LicenciaGate extends StatefulWidget {
  const LicenciaGate({super.key, required this.child});

  final Widget child;

  @override
  State<LicenciaGate> createState() => _LicenciaGateState();
}

class _LicenciaGateState extends State<LicenciaGate> {
  final _lic = LicenciaService.instance;
  LicenciaEstado? _estado;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    await _lic.init();
    final est = await _lic.estado();
    if (!mounted) {
      return;
    }
    setState(() {
      _estado = est;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_estado?.tipo == LicenciaTipo.vencida) {
      return LicenciaScreen(
        bloqueante: true,
        onActivada: _cargar,
      );
    }
    return widget.child;
  }
}
