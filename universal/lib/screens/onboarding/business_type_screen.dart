import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/business_config.dart';
import '../../config/theme.dart';
import '../../services/licencia_service.dart';

/// Primera pantalla que ve una instalación nueva: elegir el tipo de
/// negocio. La elección define colores, textos y catálogo de servicios
/// sugerido para el resto de la app, y también qué licencia/prueba aplica
/// (cada rubro tiene la suya, ver [LicenciaService]).
///
/// Se guarda en `SharedPreferences` para no volver a preguntar en próximos
/// arranques. Cambiar de rubro más adelante (desde un ajuste, no
/// implementado aún) no borra los datos existentes, solo cambia el tema y
/// las sugerencias — pero requiere activar la licencia de ese rubro por
/// separado si no estaba ya licenciado.
class BusinessTypeScreen extends StatefulWidget {
  const BusinessTypeScreen({super.key, required this.onSeleccionado});

  /// Se llama después de guardar la elección, para que el widget raíz
  /// reconstruya el `MaterialApp` con el tema y la pantalla correctos.
  final VoidCallback onSeleccionado;

  @override
  State<BusinessTypeScreen> createState() => _BusinessTypeScreenState();
}

class _BusinessTypeScreenState extends State<BusinessTypeScreen> {
  bool _guardando = false;

  Future<void> _elegir(BusinessType tipo) async {
    if (_guardando) return;
    setState(() => _guardando = true);

    final config = kBusinessConfigs[tipo]!;
    AppConfig.instance.setBusinessType(tipo);
    AppTheme.aplicarConfig(config);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefsKey, tipo.name);

    // Arranca la prueba de 15 días de este rubro específico.
    await LicenciaService.instance.init();

    if (!mounted) return;
    widget.onSeleccionado();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: _guardando
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      '¿A qué te dedicas?',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Elige tu rubro para personalizar la app: colores, '
                      'servicios sugeridos y contenido para redes sociales.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: ListView(
                        children: BusinessType.values
                            .map((tipo) => _TarjetaNegocio(
                                  config: kBusinessConfigs[tipo]!,
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
  const _TarjetaNegocio({required this.config, required this.onTap});

  final BusinessConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: config.primaryColor.withOpacity(0.25)),
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
                      config.subtitulo,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
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
