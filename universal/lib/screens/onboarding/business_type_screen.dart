import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/business_config.dart';
import '../../config/theme.dart';
import '../../database/database_helper.dart';
import '../../main.dart';
import '../../services/licencia_service.dart';

/// Selector de tipo de negocio. Se usa en dos momentos:
/// - Primera pantalla que ve una instalación nueva (`esCambio: false`,
///   valor por defecto), antes de elegir ningún rubro.
/// - Desde el menú de Inicio, para gestionar los rubros habilitados más
///   adelante (`esCambio: true`).
///
/// La elección define colores, textos y catálogo de servicios sugerido
/// para el resto de la app. Cada rubro tiene además su propia base de datos
/// (ver [DatabaseHelper.dbName]): clientes, citas, servicios y finanzas de
/// "Manicura" son completamente independientes de los de "Spa", como si
/// fueran negocios separados.
///
/// La licencia es única por dispositivo ([LicenciaService]), pero el plan
/// contratado limita cuántos rubros pueden estar habilitados a la vez
/// (Básico: 1, Pro: 2, Premium: todos). Durante la prueba gratis de 15 días
/// el acceso es libre a los 3, para poder evaluarlos antes de pagar.
class BusinessTypeScreen extends StatefulWidget {
  const BusinessTypeScreen({super.key, this.esCambio = false});

  final bool esCambio;

  @override
  State<BusinessTypeScreen> createState() => _BusinessTypeScreenState();
}

class _BusinessTypeScreenState extends State<BusinessTypeScreen> {
  final _lic = LicenciaService.instance;

  bool _guardando = true;
  Set<BusinessType> _habilitados = {};
  PlanLicencia? _plan;
  // Si hay cupo libre para habilitar un rubro más (además de los que ya
  // están en [_habilitados]). Es el mismo valor para cualquier rubro
  // pendiente: no depende de cuál sea, solo de cuántos caben en el plan.
  bool _hayCupoParaMas = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadoLicencia();
  }

  Future<void> _cargarEstadoLicencia() async {
    await _lic.init();
    final habilitados = await _lic.rubrosHabilitados();
    final plan = await _lic.planActivo();
    var hayCupo = true;
    final pendientes = BusinessType.values.where((t) => !habilitados.contains(t));
    if (pendientes.isNotEmpty) {
      hayCupo = await _lic.puedeHabilitar(pendientes.first);
    }
    if (!mounted) return;
    setState(() {
      _habilitados = habilitados;
      _plan = plan;
      _hayCupoParaMas = hayCupo;
      _guardando = false;
    });
  }

  Future<void> _elegir(BusinessType tipo) async {
    if (_guardando) return;

    if (widget.esCambio && tipo == AppConfig.instance.current.tipo) {
      // Ya es el rubro activo: no hace falta reiniciar nada.
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (!_habilitados.contains(tipo)) {
      final puede = await _lic.puedeHabilitar(tipo);
      if (!puede) {
        if (mounted) await _mostrarLimitePlan();
        return;
      }
      await _lic.habilitarRubro(tipo);
    }

    setState(() => _guardando = true);

    // Cierra la conexión a la base del rubro anterior (si había una
    // abierta): dbName depende del rubro activo, así que sin esto la app
    // seguiría leyendo/escribiendo en la base vieja hasta reiniciar el
    // proceso de verdad.
    await DatabaseHelper().closeConnection();

    final config = kBusinessConfigs[tipo]!;
    AppConfig.instance.setBusinessType(tipo);
    AppTheme.aplicarConfig(config);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefsKey, tipo.name);

    if (!mounted) return;
    // Reconstruye toda la app desde cero: sirve tanto para pasar del
    // onboarding a Inicio como para aplicar un cambio de rubro hecho desde
    // el menú, sin dejar rastros de la pantalla/navegación anterior.
    Restarter.reiniciar(context);
  }

  Future<void> _mostrarLimitePlan() async {
    final planLabel = _plan?.label ?? 'actual';
    final cupo = _plan?.maxServicios;
    final detalle = _plan == null
        ? 'Tu prueba gratis ya venció. Activa una licencia para seguir '
            'usando la app.'
        : 'Tu plan $planLabel permite hasta $cupo servicio'
            '${cupo == 1 ? '' : 's'} habilitado${cupo == 1 ? '' : 's'} a la '
            'vez. Para agregar este también, mejora de plan.';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Límite de tu plan'),
        content: Text(detalle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _contactarWhatsApp();
            },
            icon: const Icon(Icons.chat),
            label: const Text('Hablar por WhatsApp'),
          ),
        ],
      ),
    );
  }

  Future<void> _contactarWhatsApp() async {
    final mensaje = Uri.encodeComponent(
      'Hola, quiero mejorar mi plan de Multiservicios para habilitar más '
      'servicios.',
    );
    final uri = Uri.parse('https://wa.me/5353498305?text=$mensaje');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: widget.esCambio
          ? AppBar(title: const Text('Gestionar mis servicios'))
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
                              'cambiar de servicio. Cuántos puedes tener '
                              'habilitados a la vez depende de tu plan.'
                          : 'Elige tu rubro para personalizar la app: colores, '
                              'servicios sugeridos y contenido para redes '
                              'sociales. Tienes 15 días de prueba con acceso '
                              'libre a todos.',
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
                                  disponible: _habilitados.contains(tipo) ||
                                      _hayCupoParaMas,
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
    this.disponible = true,
  });

  final BusinessConfig config;
  final VoidCallback onTap;
  final bool activo;
  final bool disponible;

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
                      _subtitulo,
                      style: TextStyle(
                        color: activo ? config.primaryColor : Colors.grey,
                        fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                disponible ? Icons.chevron_right : Icons.lock_outline,
                color: disponible ? config.primaryColor : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitulo {
    if (activo) return 'Servicio actual';
    if (!disponible) return 'Requiere mejorar de plan';
    return config.subtitulo;
  }
}
