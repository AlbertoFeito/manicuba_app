import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/constants.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/licencia/licencia_gate.dart';
import 'services/licencia_service.dart';
import 'services/backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los datos de formato de fecha en español (meses, días).
  await initializeDateFormatting('es_ES', null);
  // Arranca la prueba en el primer uso.
  await LicenciaService.instance.init();
  // Crea backup automático si es necesario.
  BackupService.maybeAutoBackup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.getLightTheme(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LicenciaGate(child: HomeScreen()),
    );
  }
}
