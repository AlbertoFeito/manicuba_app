import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configuración global para los tests: inicializa sqflite con el motor FFI
/// (SQLite embebido) para que la base de datos funcione en la VM de pruebas,
/// donde no existe el plugin nativo de Android, y carga los datos de formato
/// de fecha en español que usan el calendario y las pantallas.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await initializeDateFormatting('es_ES', null);
  // Almacenamiento simulado para la licencia (prueba activa por defecto).
  SharedPreferences.setMockInitialValues({});
  await testMain();
}
