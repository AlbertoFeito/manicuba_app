// Parte del Asistente de Promociones (ver docs/ASISTENTE_PROMOCIONES.md).
//
// Pantalla de ajustes del perfil del negocio. Los datos que se guardan aquí
// se usan para autocompletar el pie de los posts y las promociones.

import 'package:flutter/material.dart';

import '../../models/perfil_negocio.dart';
import '../../services/perfil_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _horario = TextEditingController();
  final _instagram = TextEditingController();
  final _facebook = TextEditingController();
  final _whatsapp = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final perfil = await PerfilService.instance.obtener();
    if (!mounted) {
      return;
    }
    _nombre.text = perfil.nombreNegocio;
    _telefono.text = perfil.telefono ?? '';
    _direccion.text = perfil.direccion ?? '';
    _horario.text = perfil.horario ?? '';
    _instagram.text = perfil.instagram ?? '';
    _facebook.text = perfil.facebook ?? '';
    _whatsapp.text = perfil.whatsapp ?? '';
    setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _horario.dispose();
    _instagram.dispose();
    _facebook.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  String? _textoONulo(String v) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _guardando = true);
    final perfil = PerfilNegocio(
      nombreNegocio: _nombre.text.trim(),
      telefono: _textoONulo(_telefono.text),
      direccion: _textoONulo(_direccion.text),
      horario: _textoONulo(_horario.text),
      instagram: _textoONulo(_instagram.text),
      facebook: _textoONulo(_facebook.text),
      whatsapp: _textoONulo(_whatsapp.text),
    );
    await PerfilService.instance.guardar(perfil);
    if (!mounted) {
      return;
    }
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil guardado')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del negocio'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Estos datos se añaden automáticamente a tus promociones.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del negocio *',
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Escribe el nombre del negocio'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefono,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp',
                      prefixIcon: Icon(Icons.chat),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _instagram,
                    decoration: const InputDecoration(
                      labelText: 'Instagram (@usuario)',
                      prefixIcon: Icon(Icons.camera_alt),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _facebook,
                    decoration: const InputDecoration(
                      labelText: 'Facebook',
                      prefixIcon: Icon(Icons.facebook),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _direccion,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _horario,
                    decoration: const InputDecoration(
                      labelText: 'Horario',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
    );
  }
}
