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
  await _cargarRubroGuardado();
  runApp(const Restarter(child: MyApp()));
}

/// Carga en [AppConfig]/[AppTheme] el rubro guardado de un arranque anterior
/// (si existe) y arranca/continúa su prueba de licencia. Se separó de
/// `main()` para poder llamarlo también después de un reinicio en caliente
/// (ver [Restarter]) sin duplicar lógica.
Future<void> _cargarRubroGuardado() async {
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
}

/// Permite reconstruir toda la app desde cero sin reiniciar el proceso.
/// Se usa tanto al terminar el onboarding (primer rubro elegido) como al
/// cambiar de rubro después, desde el menú de Inicio — ver
/// `screens/onboarding/business_type_screen.dart`.
class Restarter extends StatefulWidget {
  const Restarter({super.key, required this.child});

  final Widget child;

  static void reiniciar(BuildContext context) {
    context.findAncestorStateOfType<_RestarterState>()?._reiniciar();
  }

  @override
  State<Restarter> createState() => _RestarterState();
}

class _RestarterState extends State<Restarter> {
  Key _key = UniqueKey();

  void _reiniciar() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          : const BusinessTypeScreen(),
    );
  }
}
