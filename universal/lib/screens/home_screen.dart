import 'package:flutter/material.dart';
import '../config/business_config.dart';
import '../config/theme.dart';
import 'agenda/agenda_screen.dart';
import 'agenda/cita_form_screen.dart';
import 'agenda/historial_screen.dart';
import 'clientes/clientes_screen.dart';
import 'clientes/cliente_form_screen.dart';
import 'finanzas/finanzas_screen.dart';
import 'finanzas/gasto_form_screen.dart';
import 'galeria/galeria_screen.dart';
import 'inventario/inventario_screen.dart';
import 'licencia/licencia_screen.dart';
import 'redes_sociales/redes_screen.dart';
import 'redes_sociales/post_form_screen.dart';
import 'servicios/servicios_screen.dart';
import 'backup_screen.dart';
import '../services/cita_service.dart';
import '../services/finanzas_service.dart';
import '../config/ayuda_content.dart';
import '../widgets/ayuda_button.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final _citaService = CitaService();
  final _finanzasService = FinanzasService();
  final _formatoMoneda = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  // Resumen del día (datos reales).
  int _citasHoy = 0;
  double _ingresosHoy = 0;
  double _gastosHoy = 0;
  double _balanceHoy = 0;

  // Cambia para forzar la recarga de la pestaña de Clientes tras un alta.
  int _clientesReload = 0;

  // Cambia para forzar la recarga de la pestaña de Agenda tras un alta.
  int _agendaReload = 0;

  // Cambia para forzar la recarga de la pestaña de Finanzas tras un registro.
  int _finanzasReload = 0;

  // Cambia para forzar la recarga de la pestaña de Redes tras un alta.
  int _redesReload = 0;

  // Control del botón atrás: detecta doble toque para cerrar desde inicio
  DateTime? _ultimaTocada;

  final List<String> _titles = [
    'Inicio',
    'Agenda',
    'Clientes',
    'Finanzas',
    'Redes Sociales',
  ];

  AyudaInfo get _ayudaActual {
    switch (_selectedIndex) {
      case 1:
        return Ayudas.agenda;
      case 2:
        return Ayudas.clientes;
      case 3:
        return Ayudas.finanzas;
      case 4:
        return Ayudas.redes;
      case 0:
      default:
        return Ayudas.inicio;
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    final citas = await _citaService.totalHoy();
    final ingresos = await _finanzasService.ingresoHoy();
    final gastos = await _finanzasService.gastoHoy();
    final balance = await _finanzasService.balanceHoy();
    if (!mounted) {
      return;
    }
    setState(() {
      _citasHoy = citas;
      _ingresosHoy = ingresos;
      _gastosHoy = gastos;
      _balanceHoy = balance;
    });
  }

  /// Maneja el boton atras del dispositivo:
  /// - Si esta en pantalla inicial, requiere doble toque para cerrar
  /// - Si esta en otra pestana, navega a la anterior
  Future<bool> _alPresionarAtras() async {
    if (_selectedIndex == 0) {
      // En pantalla inicial: requiere doble toque para cerrar
      final ahora = DateTime.now();
      if (_ultimaTocada != null &&
          ahora.difference(_ultimaTocada!).inSeconds < 2) {
        // Doble toque en menos de 2 segundos: cierra la app
        return true;
      }
      // Primer toque: muestra mensaje y registra tiempo
      _ultimaTocada = ahora;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toca atrás otra vez para salir'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false; // No cierra aún
    } else {
      // En otra pestaña: navega a la anterior
      setState(() => _selectedIndex--);
      return false; // No cierra
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final debeCerrar = await _alPresionarAtras();
        if (debeCerrar && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 2,
        actions: [
          AyudaButton(info: _ayudaActual),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Más',
            onSelected: (value) {
              if (value == 'servicios') {
                _abrirServicios();
              } else if (value == 'inventario') {
                _abrirInventario();
              } else if (value == 'galeria') {
                _abrirGaleria();
              } else if (value == 'historial') {
                _abrirHistorial();
              } else if (value == 'backup') {
                _abrirBackup();
              } else if (value == 'licencia') {
                _abrirLicencia();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'historial',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Historial de citas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'servicios',
                child: ListTile(
                  leading: Icon(AppConfig.instance.current.iconoServicios),
                  title: const Text('Servicios'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'inventario',
                child: ListTile(
                  leading: Icon(Icons.inventory_2),
                  title: Text('Inventario'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'galeria',
                child: ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Galería de trabajos'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: Icon(Icons.backup),
                  title: Text('Backup de datos'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'licencia',
                child: ListTile(
                  leading: Icon(Icons.workspace_premium),
                  title: Text('Licencia'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Pantalla de inicio
          _buildHomeTab(),
          // Agenda
          AgendaScreen(key: ValueKey(_agendaReload)),
          // Clientes
          ClientesScreen(key: ValueKey(_clientesReload)),
          // Finanzas
          FinanzasScreen(key: ValueKey(_finanzasReload)),
          // Redes Sociales
          RedesScreen(key: ValueKey(_redesReload)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: _titles[0],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: _titles[1],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: _titles[2],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: _titles[3],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.share),
            label: _titles[4],
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            // Recarga automáticamente Finanzas al abrir su pestaña, para que
            // refleja al instante los ingresos de citas recién completadas.
            if (index == 3) {
              _finanzasReload++;
            }
          });
          if (index == 0) {
            _cargarResumen();
          }
        },
      ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de bienvenida
            Text(
              AppConfig.instance.current.saludo,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppConfig.instance.current.subtitulo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),

            // Resumen rápido (será actualizado con datos reales)
            Text(
              'Resumen del Día',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildResumenCard(
                    title: 'Citas',
                    value: '$_citasHoy',
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResumenCard(
                    title: 'Ingresos',
                    value: _formatoMoneda.format(_ingresosHoy),
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildResumenCard(
                    title: 'Gastos',
                    value: _formatoMoneda.format(_gastosHoy),
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResumenCard(
                    title: 'Balance',
                    value: _formatoMoneda.format(_balanceHoy),
                    icon: Icons.trending_up,
                    color: _balanceHoy >= 0
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Acciones rápidas
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionButton(
                  icon: Icons.add_circle,
                  label: 'Nueva Cita',
                  onTap: _nuevaCita,
                ),
                _buildActionButton(
                  icon: Icons.add_box,
                  label: 'Nuevo Cliente',
                  onTap: _nuevoCliente,
                ),
                _buildActionButton(
                  icon: Icons.add_shopping_cart,
                  label: 'Registrar Gasto',
                  onTap: _registrarGasto,
                ),
                _buildActionButton(
                  icon: Icons.add_a_photo,
                  label: 'Post Redes',
                  onTap: _nuevoPost,
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'En Desarrollo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sección de $title\nProximamente disponible',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _nuevaCita() async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CitaFormScreen(),
      ),
    );
    if (guardado == true && mounted) {
      // Cambia a la pestaña de Agenda (recargándola) para ver la cita.
      setState(() {
        _selectedIndex = 1;
        _agendaReload++;
      });
    }
  }

  Future<void> _registrarGasto() async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const GastoFormScreen(),
      ),
    );
    if (guardado == true && mounted) {
      // Cambia a la pestaña de Finanzas (recargándola) para ver el registro.
      setState(() {
        _selectedIndex = 3;
        _finanzasReload++;
      });
    }
  }

  Future<void> _abrirServicios() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const ServiciosScreen(),
      ),
    );
  }

  Future<void> _nuevoPost() async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PostFormScreen(),
      ),
    );
    if (guardado == true && mounted) {
      // Cambia a la pestaña de Redes (recargándola) para ver el post.
      setState(() {
        _selectedIndex = 4;
        _redesReload++;
      });
    }
  }

  Future<void> _abrirInventario() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const InventarioScreen(),
      ),
    );
    if (!mounted) {
      return;
    }
    // Registrar una compra en Inventario crea un gasto, así que al volver hay
    // que refrescar el resumen de hoy y forzar la recarga de Finanzas; si no,
    // el gasto ya está en la base pero la pantalla sigue mostrando lo viejo.
    setState(() => _finanzasReload++);
    await _cargarResumen();
  }

  Future<void> _abrirGaleria() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const GaleriaScreen(),
      ),
    );
  }

  Future<void> _abrirLicencia() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const LicenciaScreen(),
      ),
    );
  }

  Future<void> _abrirHistorial() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const HistorialScreen(),
      ),
    );
    // Al volver, refresca la agenda por si se reabrió alguna cita.
    if (mounted) {
      setState(() => _agendaReload++);
    }
  }

  Future<void> _nuevoCliente() async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ClienteFormScreen(),
      ),
    );
    if (guardado == true && mounted) {
      // Cambia a la pestaña de Clientes (recargándola) para ver el registro.
      setState(() {
        _selectedIndex = 2;
        _clientesReload++;
      });
    }
  }

  Future<void> _abrirBackup() async {
    final restaured = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const BackupScreen(),
      ),
    );
    if (restaured == true) {
      setState(() {
        _clientesReload++;
        _agendaReload++;
        _finanzasReload++;
        _redesReload++;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message - Próximamente disponible'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
