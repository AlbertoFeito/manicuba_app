import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import 'agenda/agenda_screen.dart';
import 'agenda/cita_form_screen.dart';
import 'clientes/clientes_screen.dart';
import 'clientes/cliente_form_screen.dart';
import 'servicios/servicios_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Cambia para forzar la recarga de la pestaña de Clientes tras un alta.
  int _clientesReload = 0;

  // Cambia para forzar la recarga de la pestaña de Agenda tras un alta.
  int _agendaReload = 0;

  final List<String> _titles = [
    'Inicio',
    'Agenda',
    'Clientes',
    'Finanzas',
    'Redes Sociales',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Más',
            onSelected: (value) {
              if (value == 'servicios') {
                _abrirServicios();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'servicios',
                child: ListTile(
                  leading: Icon(Icons.spa),
                  title: Text('Servicios'),
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
          // Finanzas (placeholder)
          _buildPlaceholder('Finanzas'),
          // Redes Sociales (placeholder)
          _buildPlaceholder('Redes Sociales'),
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
          });
        },
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
              '¡Bienvenida a ManiCuba! 💅',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu asistente personal para gestionar tu negocio de manicura',
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
                    value: '0',
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResumenCard(
                    title: 'Ingresos',
                    value: '\$0.00',
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
                    value: '\$0.00',
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResumenCard(
                    title: 'Balance',
                    value: '\$0.00',
                    icon: Icons.trending_up,
                    color: AppTheme.successColor,
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
                  onTap: () => _showMessage('Registrar gasto'),
                ),
                _buildActionButton(
                  icon: Icons.add_a_photo,
                  label: 'Post Redes',
                  onTap: () => _showMessage('Crear post'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Información de desarrollo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 Estado de Desarrollo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Versión: ${AppConstants.appVersion}\n'
                    'Base de datos: Inicializada\n'
                    'Modo: Offline-First\n'
                    'Autor: ${AppConstants.appAuthor}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
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

  Future<void> _abrirServicios() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const ServiciosScreen(),
      ),
    );
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message - Próximamente disponible'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
