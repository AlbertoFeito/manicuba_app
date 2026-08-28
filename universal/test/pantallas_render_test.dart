// Tests de render de pantallas standalone: BackupScreen, LicenciaScreen e
// HistorialScreen. Comprueban que la pantalla carga y muestra su estructura
// (cubre el build y la carga inicial de datos).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestorpro_app/models/cita.dart';
import 'package:gestorpro_app/models/cliente.dart';
import 'package:gestorpro_app/models/servicio.dart';
import 'package:gestorpro_app/screens/agenda/historial_screen.dart';
import 'package:gestorpro_app/screens/backup_screen.dart';
import 'package:gestorpro_app/screens/licencia/licencia_screen.dart';
import 'package:gestorpro_app/services/cita_service.dart';
import 'package:gestorpro_app/services/cliente_service.dart';
import 'package:gestorpro_app/services/servicio_service.dart';

import 'support/fake_path_provider.dart';

Future<void> bombearHasta(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BackupScreen muestra la cabecera y los botones', (tester) async {
    final fake = FakePathProvider.install();
    addTearDown(fake.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: BackupScreen()));
      await bombearHasta(tester, find.text('Crear Backup'));

      expect(find.text('💾 Backup de Datos'), findsOneWidget); // AppBar
      expect(find.text('Protege tus datos'), findsOneWidget);
      expect(find.text('Crear Backup'), findsOneWidget);
      expect(find.text('Cargar Archivo'), findsOneWidget);
    });
  });

  testWidgets('LicenciaScreen carga y muestra el estado', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: LicenciaScreen()));
      // Espera a que termine la carga (el botón Copiar del código de equipo).
      await bombearHasta(tester, find.text('Copiar'));

      expect(find.text('Licencia'), findsOneWidget); // AppBar
      expect(find.text('Copiar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  testWidgets('HistorialScreen lista una cita completada', (tester) async {
    await tester.runAsync(() async {
      // Una cita completada, que es lo que muestra el historial.
      final clienteId = await ClienteService().crearCliente(
        Cliente(nombre: 'Hist ${DateTime.now().microsecondsSinceEpoch}',
            telefono: '55500000'),
      );
      final svc = 'HSvc ${DateTime.now().microsecondsSinceEpoch}';
      final servicioId = await ServicioService().crearServicio(
        Servicio(nombre: svc, precio: 20, duracionMinutos: 30),
      );
      await CitaService().crearCita(
        Cita(
          clienteId: clienteId,
          servicioId: servicioId,
          fechaHora: DateTime(2020, 1, 1, 10, 0),
          duracionMinutos: 30,
          estado: EstadoCita.completada,
          monto: 20,
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: HistorialScreen()));
      await bombearHasta(tester, find.text('Historial de citas'));

      expect(find.text('Historial de citas'), findsOneWidget); // AppBar
      // Con al menos una completada, se muestran tarjetas (no el vacío).
      await bombearHasta(tester, find.byType(Card));
      expect(find.byType(Card), findsWidgets);
    });
  });
}
