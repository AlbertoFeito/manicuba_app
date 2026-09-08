// Pruebas de AsistenteService.
//
// La lógica de decisión son métodos estáticos puros: se prueban con datos en
// memoria y un "ahora" fijo, sin base de datos, para que sean deterministas.
// Además, una prueba de integración de generarSugerencias inyecta servicios
// falsos (sin DB) y un reloj fijo.

import 'package:flutter_test/flutter_test.dart';
import 'package:multiservicios_app/config/business_config.dart';
import 'package:multiservicios_app/models/cita.dart';
import 'package:multiservicios_app/models/cliente.dart';
import 'package:multiservicios_app/models/foto_trabajo.dart';
import 'package:multiservicios_app/models/perfil_negocio.dart';
import 'package:multiservicios_app/models/post_redes.dart';
import 'package:multiservicios_app/services/asistente_service.dart';
import 'package:multiservicios_app/services/cita_service.dart';
import 'package:multiservicios_app/services/cliente_service.dart';
import 'package:multiservicios_app/services/foto_service.dart';
import 'package:multiservicios_app/services/perfil_service.dart';
import 'package:multiservicios_app/services/redes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===== Fakes: devuelven listas fijas sin tocar la base de datos =====

class _FakeClientes extends ClienteService {
  _FakeClientes(this.data);
  final List<Cliente> data;
  @override
  Future<List<Cliente>> obtenerTodos() async => data;
}

class _FakeCitas extends CitaService {
  _FakeCitas(this.data);
  final List<Cita> data;
  @override
  Future<List<Cita>> obtenerTodas() async => data;
}

class _FakeFotos extends FotoService {
  _FakeFotos(this.data);
  final List<FotoTrabajo> data;
  @override
  Future<List<FotoTrabajo>> obtenerTodas() async => data;
}

class _FakeRedes extends RedesService {
  _FakeRedes(this.data);
  final List<PostRedes> data;
  @override
  Future<List<PostRedes>> obtenerTodos() async => data;
}

void main() {
  final ahora = DateTime(2026, 6, 15, 10);
  final config = kBusinessConfigs[BusinessType.manicura]!;

  group('lógica pura', () {
    test('filtrarInactivos: solo quienes visitaron y no vuelven', () {
      final clientes = [
        Cliente(
          nombre: 'Inactiva',
          telefono: '1',
          ultimaVisita: ahora.subtract(const Duration(days: 40)),
        ),
        Cliente(
          nombre: 'Reciente',
          telefono: '2',
          ultimaVisita: ahora.subtract(const Duration(days: 5)),
        ),
        Cliente(nombre: 'NuncaVino', telefono: '3'),
      ];
      final inactivas =
          AsistenteService.filtrarInactivos(clientes, ahora: ahora);
      expect(inactivas.map((c) => c.nombre), ['Inactiva']);
    });

    test('citasProximaSemana / esSemanaFloja', () {
      Cita cita(int dias, EstadoCita estado) => Cita(
            clienteId: 1,
            servicioId: 1,
            fechaHora: ahora.add(Duration(days: dias)),
            duracionMinutos: 30,
            estado: estado,
          );
      // 2 citas activas dentro de 7 días, 1 fuera de rango, 1 cancelada.
      final citas = [
        cita(1, EstadoCita.pendiente),
        cita(3, EstadoCita.confirmada),
        cita(10, EstadoCita.confirmada), // fuera de la ventana
        cita(2, EstadoCita.cancelada), // no cuenta
      ];
      expect(AsistenteService.citasProximaSemana(citas, ahora: ahora), 2);
      // 2 < 3 -> semana floja.
      expect(AsistenteService.esSemanaFloja(citas, ahora: ahora), isTrue);
      // Con el mínimo en 2 ya no es floja.
      expect(
        AsistenteService.esSemanaFloja(citas, ahora: ahora, minimo: 2),
        isFalse,
      );
    });

    test('fotoRecienteSinPost: reciente, sin post y la más nueva', () {
      final fotos = [
        FotoTrabajo(
          id: 1,
          rutaFoto: 'a.jpg',
          fecha: ahora.subtract(const Duration(days: 2)),
        ),
        FotoTrabajo(
          id: 2,
          rutaFoto: 'b.jpg',
          fecha: ahora.subtract(const Duration(days: 1)),
        ),
        FotoTrabajo(
          id: 3,
          rutaFoto: 'c.jpg',
          fecha: ahora.subtract(const Duration(days: 100)), // vieja
        ),
      ];
      final posts = [
        PostRedes(
          titulo: 't',
          contenido: 'c',
          tipo: 'trabajo',
          plataforma: 'todas',
          fechaCreacion: ahora,
          fotoIds: '2', // la foto 2 ya está publicada
        ),
      ];
      final foto =
          AsistenteService.fotoRecienteSinPost(fotos, posts, ahora: ahora);
      // La 2 está usada, la 3 es vieja -> queda la 1.
      expect(foto?.id, 1);

      // Sin fotos candidatas -> null.
      expect(
        AsistenteService.fotoRecienteSinPost(
          [fotos[2]],
          const [],
          ahora: ahora,
        ),
        isNull,
      );
    });

    test('diasDesdeUltimoPost', () {
      expect(
        AsistenteService.diasDesdeUltimoPost(const [], ahora: ahora),
        greaterThan(1000),
      );
      final posts = [
        PostRedes(
          titulo: 't',
          contenido: 'c',
          tipo: 'promocion',
          plataforma: 'todas',
          publicado: true,
          fechaCreacion: ahora.subtract(const Duration(days: 10)),
        ),
        PostRedes(
          titulo: 't',
          contenido: 'c',
          tipo: 'promocion',
          plataforma: 'todas',
          publicado: false, // no publicado, no cuenta
          fechaCreacion: ahora.subtract(const Duration(days: 1)),
        ),
      ];
      expect(AsistenteService.diasDesdeUltimoPost(posts, ahora: ahora), 10);
    });

    test('construirBorrador usa plantilla del rubro y pie del perfil', () {
      const perfil = PerfilNegocio(nombreNegocio: 'Salón', telefono: '5551');
      final borrador = AsistenteService.construirBorrador(
        tipo: 'oferta',
        config: config,
        perfil: perfil,
        ahora: ahora,
      );
      expect(borrador.tipo, 'oferta');
      expect(borrador.plataforma, 'todas');
      // Trae el texto de la plantilla de oferta del rubro manicura.
      expect(borrador.contenido, contains('OFERTA'));
      // Y el pie de contacto del perfil.
      expect(borrador.contenido, contains('📞 5551'));
      expect(borrador.hashtags, isNotNull);
    });
  });

  group('generarSugerencias (integración con fakes)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AppConfig.instance.reset(); // rubro por defecto: manicura
    });

    test('agrega win-back, semana floja, foto y constancia', () async {
      await PerfilService.instance.guardar(
        const PerfilNegocio(nombreNegocio: 'Salón', telefono: '5551'),
        tipo: BusinessType.manicura,
      );

      final servicio = AsistenteService(
        clienteService: _FakeClientes([
          Cliente(
            nombre: 'Inactiva',
            telefono: '1',
            ultimaVisita: ahora.subtract(const Duration(days: 40)),
          ),
        ]),
        citaService: _FakeCitas(const []), // sin citas -> semana floja
        fotoService: _FakeFotos([
          FotoTrabajo(
            id: 7,
            rutaFoto: 'x.jpg',
            fecha: ahora.subtract(const Duration(days: 1)),
          ),
        ]),
        redesService: _FakeRedes(const []), // sin posts -> constancia
        ahora: () => ahora,
      );

      final sugerencias = await servicio.generarSugerencias();
      final ids = sugerencias.map((s) => s.id).toList();
      expect(
        ids,
        containsAll(['inactivas', 'semana_floja', 'foto_7', 'constancia']),
      );

      // El win-back apunta a la clienta inactiva.
      final winback = sugerencias.firstWhere((s) => s.id == 'inactivas');
      expect(winback.borrador.contenido, contains('📞 5551'));

      // La sugerencia de foto trae el id de la foto en su borrador.
      final foto = sugerencias.firstWhere((s) => s.id == 'foto_7');
      expect(foto.borrador.listaFotoIds, [7]);
    });

    test('sin datos que lo ameriten, no salen win-back ni foto', () async {
      final servicio = AsistenteService(
        clienteService: _FakeClientes([
          Cliente(
            nombre: 'Reciente',
            telefono: '1',
            ultimaVisita: ahora.subtract(const Duration(days: 2)),
          ),
        ]),
        citaService: _FakeCitas([
          for (var i = 1; i <= 5; i++)
            Cita(
              clienteId: 1,
              servicioId: 1,
              fechaHora: ahora.add(Duration(days: i)),
              duracionMinutos: 30,
              estado: EstadoCita.confirmada,
            ),
        ]),
        fotoService: _FakeFotos(const []),
        redesService: _FakeRedes([
          PostRedes(
            titulo: 't',
            contenido: 'c',
            tipo: 'promocion',
            plataforma: 'todas',
            publicado: true,
            fechaCreacion: ahora.subtract(const Duration(days: 1)),
          ),
        ]),
        ahora: () => ahora,
      );

      final ids = (await servicio.generarSugerencias()).map((s) => s.id);
      expect(ids, isNot(contains('inactivas')));
      expect(ids, isNot(contains('semana_floja')));
      expect(ids.where((id) => id.startsWith('foto_')), isEmpty);
      expect(ids, isNot(contains('constancia')));
    });
  });
}
