import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/business_config.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/licencia/licencia_gate.dart';
import 'screens/onboarding/business_type_screen.dart';
import 'services/licencia_service.dart';
import 'services/backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los datos de formato de fecha en español (meses, días).
  await initializeDateFormatting('es_ES', null);

  // Si ya se eligió un rubro en un arranque anterior, se carga ahora para
  // que el tema y los textos correctos estén listos antes del primer frame.
  // Si es la primera vez, AppConfig.instance.cargado queda en false y
  // MyApp muestra el selector de rubro (BusinessTypeScreen) en su lugar.
  final prefs = await SharedPreferences.getInstance();
  final tipoGuardado = prefs.getString(AppConfig.prefsKey);
  if (tipoGuardado != null) {
    BusinessType? tipo;
    for (final t in BusinessType.values) {
      if (t.name == tipoGuardado) {
        tipo = t;
        break;
      }
    }
    if (tipo != null) {
      AppConfig.instance.setBusinessType(tipo);
      AppTheme.aplicarConfig(kBusinessConfigs[tipo]!);
      // Arranca/continúa la prueba del rubro ya elegido.
      await LicenciaService.instance.init();
    }
  }

  // Crea backup automático si es necesario (solo tiene sentido si ya hay un
  // rubro elegido; en la primera pantalla de onboarding no hay nada que
  // respaldar todavía).
  if (AppConfig.instance.cargado) {
    BackupService.maybeAutoBackup();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Llamado por [BusinessTypeScreen] tras guardar la elección, para que el
  /// `MaterialApp` se reconstruya con el tema y la pantalla de inicio ya
  /// correctos, sin necesidad de reiniciar la app.
  void _onRubroElegido() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.instance.current.appName,
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
      home: AppConfig.instance.cargado
          ? const LicenciaGate(child: HomeScreen())
          : BusinessTypeScreen(onSeleccionado: _onRubroElegido),
    );
  }
}
