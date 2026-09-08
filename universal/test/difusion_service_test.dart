// Pruebas de DifusionService: construcción de enlaces (wa.me / smsto),
// filtrado de clientas (todas / frecuentes / inactivas) y el envío usando un
// lanzador inyectado (sin depender del plugin url_launcher real).

import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/models/cita.dart';
import 'package:multiservicios_app/models/cliente.dart';
import 'package:multiservicios_app/services/difusion_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  final ahora = DateTime(2026, 6, 15);

  group('enlaces', () {
    test('soloDigitos deja solo números', () {
      expect(DifusionService.soloDigitos('+53 5555-1234'), '5355551234');
    });

    test('whatsappUri arma wa.me con el texto codificado', () {
      final uri = DifusionService.whatsappUri('+53 5555 1234', 'Hola & adiós');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/5355551234');
      // El texto viaja codificado en el parámetro text.
      expect(uri.queryParameters['text'], 'Hola & adiós');
    });

    test('smsUri usa el esquema smsto con el cuerpo', () {
      final uri = DifusionService.smsUri('5555 1234', 'Promo');
      expect(uri.scheme, 'smsto');
      expect(uri.path, '55551234');
      expect(uri.queryParameters['body'], 'Promo');
    });
  });

  group('filtrado', () {
    final clientes = [
      Cliente(
        id: 1,
        nombre: 'Inactiva',
        telefono: '111',
        ultimaVisita: ahora.subtract(const Duration(days: 40)),
      ),
      Cliente(
        id: 2,
        nombre: 'Reciente',
        telefono: '222',
        ultimaVisita: ahora.subtract(const Duration(days: 3)),
      ),
      Cliente(id: 3, nombre: 'SinTelefono', telefono: '   '),
    ];
    Cita completada(int clienteId) => Cita(
          clienteId: clienteId,
          servicioId: 1,
          fechaHora: ahora,
          duracionMinutos: 30,
          estado: EstadoCita.completada,
        );

    test('todas: incluye solo a quienes tienen teléfono', () {
      final r = DifusionService.filtrar(
        clientes,
        const [],
        FiltroClientas.todas,
        ahora: ahora,
      );
      expect(r.map((c) => c.id), [1, 2]); // la 3 no tiene teléfono
    });

    test('inactivas: reutiliza el criterio del asistente', () {
      final r = DifusionService.filtrar(
        clientes,
        const [],
        FiltroClientas.inactivas,
        ahora: ahora,
      );
      expect(r.map((c) => c.id), [1]);
    });

    test('frecuentes: clientas con 3+ citas completadas', () {
      final citas = [
        completada(1), completada(1), completada(1), // 3 -> frecuente
        completada(2), completada(2), // 2 -> no
      ];
      final r = DifusionService.filtrar(
        clientes,
        citas,
        FiltroClientas.frecuentes,
        ahora: ahora,
      );
      expect(r.map((c) => c.id), [1]);
    });
  });

  group('envío', () {
    test('enviarWhatsApp abre la wa.me correcta', () async {
      Uri? abierta;
      final servicio = DifusionService(
        abrir: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          abierta = uri;
          return true;
        },
      );
      final cliente = Cliente(id: 1, nombre: 'X', telefono: '5551234');
      final ok = await servicio.enviarWhatsApp(cliente, '¡Promo!');
      expect(ok, isTrue);
      expect(abierta?.host, 'wa.me');
      expect(abierta?.path, '/5551234');
      expect(abierta?.queryParameters['text'], '¡Promo!');
    });

    test('enviarSms propaga false si el lanzador falla', () async {
      final servicio = DifusionService(
        abrir: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async =>
            false,
      );
      final cliente = Cliente(id: 1, nombre: 'X', telefono: '5551234');
      expect(await servicio.enviarSms(cliente, 'Hola'), isFalse);
    });
  });
}
