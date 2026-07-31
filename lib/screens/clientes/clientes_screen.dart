import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/cliente.dart';
import '../../services/cliente_service.dart';
import 'cliente_detail_screen.dart';
import 'cliente_form_screen.dart';

/// Listado de clientes con búsqueda en vivo.
class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _clienteService = ClienteService();
  final _busquedaCtrl = TextEditingController();

  List<Cliente> _todos = [];
  List<Cliente> _filtrados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final clientes = await _clienteService.obtenerTodos();
    if (!mounted) {
      return;
    }
    setState(() {
      _todos = clientes;
      _aplicarFiltro(_busquedaCtrl.text);
      _cargando = false;
    });
  }

  void _aplicarFiltro(String query) {
    final q = query.trim().toLowerCase();
    _filtrados = q.isEmpty
        ? List<Cliente>.from(_todos)
        : _todos
            .where((c) =>
                c.nombre.toLowerCase().contains(q) ||
                c.telefono.contains(q))
            .toList();
  }

  Future<void> _abrirFormulario({Cliente? cliente}) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClienteFormScreen(cliente: cliente),
      ),
    );
    if (guardado == true) {
      await _cargar();
    }
  }

  Future<void> _abrirFicha(Cliente cliente) async {
    final cambios = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClienteDetailScreen(cliente: cliente),
      ),
    );
    if (cambios == true) {
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busquedaCtrl,
              onChanged: (value) => setState(() => _aplicarFiltro(value)),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busquedaCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaCtrl.clear();
                          setState(() => _aplicarFiltro(''));
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _buildLista()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildLista() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_todos.isEmpty) {
      return _buildVacio(
        icon: Icons.people_outline,
        titulo: 'Sin clientes todavía',
        subtitulo: 'Pulsa "Nuevo" para agregar tu primer cliente',
      );
    }
    if (_filtrados.isEmpty) {
      return _buildVacio(
        icon: Icons.search_off,
        titulo: 'Sin resultados',
        subtitulo: 'Prueba con otro nombre o teléfono',
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: _filtrados.length,
        itemBuilder: (context, index) {
          final cliente = _filtrados[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                child: Text(
                  cliente.nombre.isNotEmpty
                      ? cliente.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(cliente.nombre),
              subtitle: Text(cliente.telefono),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _abrirFicha(cliente),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVacio({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}
