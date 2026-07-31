import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configuración global para los tests: inicializa sqflite con el motor FFI
/// (SQLite embebido) para que la base de datos funcione en la VM de pruebas,
/// donde no existe el plugin nativo de Android.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}
