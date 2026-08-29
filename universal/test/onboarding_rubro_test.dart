// Prueba de extremo a extremo del onboarding: para cada BusinessType,
// simula lo que haría una instalación nueva de verdad (sin emulador
// Android disponible en este entorno) — arrancar la app, ver el selector
// de rubro, tocar una tarjeta, y comprobar que la app entra a Inicio con
// el tema y el saludo correctos, la elección queda persistida, y el
// catálogo de servicios semilla sembrado es el de ESE rubro.
//
// Nota: toda interacción que dependa de una lectura/escritura real de la
// base de datos (sqflite_common_ffi) — incluida la que hace la propia app
// en su flujo normal, como HomeScreen/ServiciosScreen cargando datos en
// initState — necesita correr dentro de `tester.runAsync`, igual que ya
// hacen servicios_screen_test.dart y el resto de tests de pantallas de
// este proyecto: fuera de una zona asíncrona real, el binding de test
// nunca deja completar la comunicación por isolate que usa
// sqflite_common_ffi.
//
// El catálogo de Servicios se verifica montando `ServiciosScreen` directo
// (igual que servicios_screen_test.dart), no navegando desde Inicio por el
// menú "⋮": esa navegación real dispara una transición de `Hero` para el
// FloatingActionButton (tag por defecto) que ya existe en la app tal cual
// está hoy, y no tiene relación con la configuración por rubro que esta
// prueba busca verificar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:multiservicios_app/config/business_config.dart';
import 'package:multiservicios_app/config/theme.dart';
import 'package:multiservicios_app/database/database_helper.dart';
import 'package:multiservicios_app/main.dart';
import 'package:multiservicios_app/models/cliente.dart';
import 'package:multiservicios_app/screens/servicios/servicios_screen.dart';
import 'package:multiservicios_app/services/cliente_service.dart';

const _paso = Duration(milliseconds: 100);

Future<void> _bombearHasta(WidgetTester tester, Finder buscado,
    {int intentos = 40}) async {
  for (var i = 0; i < intentos && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(_paso);
    await tester.pump();
  }
}

/// Borra la base de datos de CADA rubro (cada uno tiene su propio archivo,
/// ver DatabaseHelper.dbName) y deja AppConfig reiniciado a "sin rubro
/// elegido". Hace falta recorrer los tres explícitamente: borrar solo la
/// del rubro activo en un momento dado dejaría rastros de los otros de una
/// corrida anterior de este mismo archivo de test.
Future<void> _borrarBasesDeTodosLosRubros() async {
  for (final t in BusinessType.values) {
    AppConfig.instance.setBusinessType(t);
    await DatabaseHelper().closeConnection();
    await DatabaseHelper().deleteDatabase();
  }
  AppConfig.instance.reset();
}

void main() {
  // Los catálogos semilla de cada rubro no deben compartir nombres de
  // servicio — chequeo de datos simple y rápido.
  test('los catálogos semilla de cada rubro no se superponen', () {
    final porRubro = {
      for (final tipo in BusinessType.values)
        tipo: kBusinessConfigs[tipo]!.serviciosPorDefecto
            .map((s) => s.nombre)
            .toSet(),
    };
    for (final a in BusinessType.values) {
      for (final b in BusinessType.values) {
        if (a == b) continue;
        expect(porRubro[a]!.intersection(porRubro[b]!), isEmpty,
            reason: '${a.name} y ${b.name} comparten nombres de servicio');
      }
    }
  });

  for (final tipo in BusinessType.values) {
    final config = kBusinessConfigs[tipo]!;

    testWidgets(
        'Elegir "${config.label}" en el onboarding deja la app en Inicio '
        'con su tema y su preferencia guardados', (tester) async {
      await tester.runAsync(() async {
        // Instalación nueva: sin rubro elegido (el singleton AppConfig vive
        // todo el proceso de test, hay que reiniciarlo a mano), sin
        // preferencia guardada y sin base de datos previa de NINGÚN rubro
        // (cada uno tiene su propio archivo).
        SharedPreferences.setMockInitialValues({});
        await _borrarBasesDeTodosLosRubros();

        await tester.pumpWidget(const Restarter(child: MyApp()));
        await _bombearHasta(tester, find.text('¿A qué te dedicas?'));
        expect(find.text('${config.label} ${config.emoji}'), findsOneWidget);

        await tester.tap(find.text('${config.label} ${config.emoji}'));
        await _bombearHasta(tester, find.text(config.saludo));

        // Pantalla de Inicio con el saludo y subtítulo del rubro elegido.
        expect(find.text(config.saludo), findsOneWidget,
            reason: 'No llegó a Inicio con el saludo de ${config.label}');
        expect(find.text(config.subtitulo), findsOneWidget);

        // La elección quedó persistida para el próximo arranque.
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(AppConfig.prefsKey), tipo.name);

        // El tema activo (color de marca) corresponde al rubro elegido.
        expect(AppTheme.primaryColor, config.primaryColor);

        // Deja asentar la carga del resumen de Inicio (_cargarResumen)
        // antes de que el próximo test borre esta base de datos: si no,
        // esa consulta pendiente falla contra una conexión ya cerrada y el
        // error queda mal atribuido al siguiente test.
        for (var i = 0; i < 10; i++) {
          await Future<void>.delayed(_paso);
          await tester.pump();
        }
      });
    });

    testWidgets(
        'Con "${config.label}" activo, Servicios muestra su catálogo '
        'semilla y no el de otro rubro', (tester) async {
      await tester.runAsync(() async {
        await _borrarBasesDeTodosLosRubros();
        AppConfig.instance.setBusinessType(tipo);
        AppTheme.aplicarConfig(config);
        await DatabaseHelper().closeConnection();
        await DatabaseHelper().deleteDatabase();

        await tester.pumpWidget(MaterialApp(home: ServiciosScreen()));
        await _bombearHasta(
            tester, find.text(config.serviciosPorDefecto.first.nombre));

        for (final servicio in config.serviciosPorDefecto) {
          expect(find.text(servicio.nombre), findsOneWidget,
              reason: '"${servicio.nombre}" no aparece en Servicios para '
                  '${config.label}');
        }

        // Ningún servicio de otro rubro debe colarse en este catálogo.
        for (final otro in BusinessType.values) {
          if (otro == tipo) continue;
          for (final servicio in kBusinessConfigs[otro]!.serviciosPorDefecto) {
            expect(find.text(servicio.nombre), findsNothing,
                reason: '"${servicio.nombre}" (de ${otro.name}) no debería '
                    'aparecer con ${config.label} activo');
          }
        }
      });
    });
  }

  test('un cliente creado en un rubro no aparece al cambiar a otro', () async {
    await _borrarBasesDeTodosLosRubros();

    AppConfig.instance.setBusinessType(BusinessType.manicura);
    await ClienteService().crearCliente(
      Cliente(nombre: 'Clienta de Manicura', telefono: '555-0001'),
    );
    final clientesManicura = await ClienteService().obtenerTodos();
    expect(clientesManicura.length, 1);

    // Cambiar de rubro cierra la conexión abierta, igual que hace
    // BusinessTypeScreen antes de reiniciar la app.
    await DatabaseHelper().closeConnection();
    AppConfig.instance.setBusinessType(BusinessType.spa);

    final clientesSpa = await ClienteService().obtenerTodos();
    expect(clientesSpa, isEmpty,
        reason: 'Spa no debería ver clientes creados en Manicura: cada '
            'rubro tiene su propia base de datos');

    await DatabaseHelper().closeConnection();
    await _borrarBasesDeTodosLosRubros();
  });
}
