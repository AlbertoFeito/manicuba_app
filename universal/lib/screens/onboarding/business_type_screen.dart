import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/business_config.dart';
import '../../config/theme.dart';
import '../../main.dart';
import '../../services/licencia_service.dart';

/// Selector de tipo de negocio. Se usa en dos momentos:
/// - Primera pantalla que ve una instalación nueva (`esCambio: false`,
///   valor por defecto), antes de elegir ningún rubro.
/// - Desde el menú de Inicio, para cambiar de rubro más adelante
///   (`esCambio: true`).
///
/// En ambos casos, la elección define colores, textos y catálogo de
/// servicios sugerido para el resto de la app, y qué licencia/prueba aplica
/// (cada rubro tiene la suya, ver [LicenciaService]). Cambiar de rubro no
/// borra clientes, citas ni finanzas existentes — son compartidos por toda
/// la app — pero si el rubro elegido no tiene licencia activa todavía,
/// arranca su propia prueba de 15 días.
class BusinessTypeScreen extends StatefulWidget {
  const BusinessTypeScreen({super.key, this.esCambio = false});

  final bool esCambio;

  @override
  State<BusinessTypeScreen> createState() => _BusinessTypeScreenState();
}

class _BusinessTypeScreenState extends State<BusinessTypeScreen> {
  bool _guardando = false;

  Future<void> _elegir(BusinessType tipo) async {
    if (_guardando) return;

    if (widget.esCambio && tipo == AppConfig.instance.current.tipo) {
      // Ya es el rubro activo: no hace falta reiniciar nada.
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _guardando = true);

    final config = kBusinessConfigs[tipo]!;
    AppConfig.instance.setBusinessType(tipo);
    AppTheme.aplicarConfig(config);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefsKey, tipo.name);

    // Arranca (o continúa) la prueba/licencia de este rubro específico.
    await LicenciaService.instance.init();

    if (!mounted) return;
    // Reconstruye toda la app desde cero: sirve tanto para pasar del
    // onboarding a Inicio como para aplicar un cambio de rubro hecho desde
    // el menú, sin dejar rastros de la pantalla/navegación anterior.
    Restarter.reiniciar(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: widget.esCambio
          ? AppBar(title: const Text('Cambiar tipo de negocio'))
          : null,
      body: SafeArea(
        child: _guardando
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.esCambio) const SizedBox(height: 24),
                    if (!widget.esCambio)
                      Text(
                        '¿A qué te dedicas?',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      widget.esCambio
                          ? 'Tus clientes, citas y finanzas no se pierden al '
                              'cambiar de rubro. Si eliges uno que no habías '
                              'usado antes, empieza su propia prueba de 15 días.'
                          : 'Elige tu rubro para personalizar la app: colores, '
                              'servicios sugeridos y contenido para redes '
                              'sociales.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: ListView(
                        children: BusinessType.values
                            .map((tipo) => _TarjetaNegocio(
                                  config: kBusinessConfigs[tipo]!,
                                  activo: widget.esCambio &&
                                      tipo == AppConfig.instance.current.tipo,
                                  onTap: () => _elegir(tipo),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TarjetaNegocio extends StatelessWidget {
  const _TarjetaNegocio({
    required this.config,
    required this.onTap,
    this.activo = false,
  });

  final BusinessConfig config;
  final VoidCallback onTap;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: config.primaryColor.withOpacity(activo ? 0.9 : 0.25),
          width: activo ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: config.primaryColor.withOpacity(0.15),
                child: Icon(config.iconoServicios, color: config.primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${config.label} ${config.emoji}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activo ? 'Rubro actual' : config.subtitulo,
                      style: TextStyle(
                        color: activo ? config.primaryColor : Colors.grey,
                        fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: config.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
