// Parte del Asistente de Promociones (ver docs/ASISTENTE_PROMOCIONES.md).
//
// Difusión de una promoción directamente a las clientas, una por una, por
// WhatsApp o SMS, reutilizando los deep-links del dispositivo (url_launcher).
// No hay envío masivo oculto: cada mensaje abre el chat de una clienta con el
// texto precargado, y es la dueña quien pulsa enviar (respeta los ToS).

import 'package:url_launcher/url_launcher.dart';

import '../models/cita.dart';
import '../models/cliente.dart';
import 'asistente_service.dart';
import 'cita_service.dart';
import 'cliente_service.dart';

/// A qué clientas dirigir la difusión.
enum FiltroClientas { todas, frecuentes, inactivas }

class DifusionService {
  DifusionService({
    ClienteService? clienteService,
    CitaService? citaService,
    DateTime Function()? ahora,
    Future<bool> Function(Uri, {LaunchMode mode})? abrir,
  })  : _clientes = clienteService ?? ClienteService(),
        _citas = citaService ?? CitaService(),
        _ahora = ahora ?? DateTime.now,
        _abrir = abrir ?? launchUrl;

  final ClienteService _clientes;
  final CitaService _citas;
  final DateTime Function() _ahora;
  final Future<bool> Function(Uri, {LaunchMode mode}) _abrir;

  /// Mínimo de citas completadas para considerar "frecuente" a una clienta.
  static const int minCitasFrecuente = 3;

  // ===== Construcción de enlaces (puro) =====

  static String soloDigitos(String telefono) =>
      telefono.replaceAll(RegExp('[^0-9]'), '');

  static Uri whatsappUri(String telefono, String mensaje) {
    return Uri.parse(
      'https://wa.me/${soloDigitos(telefono)}'
      '?text=${Uri.encodeComponent(mensaje)}',
    );
  }

  static Uri smsUri(String telefono, String mensaje) {
    return Uri(
      scheme: 'smsto',
      path: telefono.replaceAll(' ', ''),
      queryParameters: {'body': mensaje},
    );
  }

  // ===== Filtrado de clientas (puro) =====

  /// Nº de citas completadas por clienta (id -> conteo).
  static Map<int, int> citasCompletadasPorCliente(List<Cita> citas) {
    final conteo = <int, int>{};
    for (final c in citas) {
      if (c.estado == EstadoCita.completada) {
        conteo.update(c.clienteId, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return conteo;
  }

  /// Aplica [filtro] a la lista de clientas. Solo se incluyen clientas con
  /// teléfono (sin teléfono no hay a dónde enviar).
  static List<Cliente> filtrar(
    List<Cliente> clientes,
    List<Cita> citas,
    FiltroClientas filtro, {
    required DateTime ahora,
  }) {
    final conTelefono =
        clientes.where((c) => soloDigitos(c.telefono).isNotEmpty).toList();
    switch (filtro) {
      case FiltroClientas.todas:
        return conTelefono;
      case FiltroClientas.inactivas:
        return AsistenteService.filtrarInactivos(conTelefono, ahora: ahora);
      case FiltroClientas.frecuentes:
        final conteo = citasCompletadasPorCliente(citas);
        return conTelefono
            .where((c) => (conteo[c.id] ?? 0) >= minCitasFrecuente)
            .toList();
    }
  }

  // ===== Orquestación =====

  Future<List<Cliente>> obtenerClientas(FiltroClientas filtro) async {
    final clientes = await _clientes.obtenerTodos();
    final citas = filtro == FiltroClientas.frecuentes
        ? await _citas.obtenerTodas()
        : const <Cita>[];
    return filtrar(clientes, citas, filtro, ahora: _ahora());
  }

  Future<bool> enviarWhatsApp(Cliente cliente, String mensaje) {
    return _abrir(
      whatsappUri(cliente.telefono, mensaje),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<bool> enviarSms(Cliente cliente, String mensaje) {
    return _abrir(
      smsUri(cliente.telefono, mensaje),
      mode: LaunchMode.externalApplication,
    );
  }
}
