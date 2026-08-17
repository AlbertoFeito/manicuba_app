# ManiCuba como Referencia para Otras Apps

Este documento es la guía maestra para que otras aplicaciones (PelucuBA, etc.) repliquen la arquitectura y características de ManiCuba.

## ✅ Estado Final - v1.3.0

ManiCuba está **lista para venta directa** con:
- ✅ Sistema de licencias completamente funcional
- ✅ Modelo freemium: 15 días gratis + pago voluntario
- ✅ Generador de licencias para propietario
- ✅ Inventario + Finanzas sincronizados automáticamente
- ✅ Gráficas interactivas
- ✅ Base de datos offline con migración v1→v2
- ✅ 50+ tests automatizados
- ✅ Arquitectura modular y escalable

## 📚 Documentación de Referencia

### Para entender la arquitectura completa:
- **`MANICUBA_FEATURES.md`** - Guía técnica de todas las características (1398 líneas)
  - Esquema de base de datos (10 tablas)
  - Modelos de datos (9 servicios)
  - Lógica de negocio (cálculos de costos, migraciones)
  - Pantallas y UI (14 screens)
  - Tests y validaciones

### Para el sistema de licencias (documento único):
- **`LICENCIAS.md`** - Sistema de licencias multi-app
  - Algoritmo común y secreto por app
  - Generador único (`herramientas/generador-licencias.html`)
  - Secretos de producción y compilación de venta
  - Vectores de verificación correctos
  - Flujo de venta y rotación de secretos

### Para inicio rápido:
- **`INICIACION_RAPIDA.md`** - Setup del proyecto
- **`SETUP.md`** - Configuración de entorno
- **`docs/LICENCIA.md`** - Documentación para usuarios finales

## 🎯 Pasos para Nueva App (PelucuBA)

### 1. Copiar Sistema de Licencias
```bash
# Desde pelucuba_app/
cp -r ../manicuba_app/lib/services/licencia_service.dart lib/services/
cp -r ../manicuba_app/lib/screens/licencia/* lib/screens/licencia/
cp ../manicuba_app/herramientas/generador-licencias.html herramientas/
```

### 2. Adaptar Secreto
```dart
// lib/services/licencia_service.dart
static const String _secret = String.fromEnvironment(
  'LICENSE_SECRET',
  defaultValue: 'pelucuba-dev-secret',  // ← CAMBIAR AQUÍ
);
```

### 3. Integrar en main.dart
```dart
import 'screens/licencia/licencia_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LicenciaService.instance.init();  // ← AGREGAR
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LicenciaGate(  // ← ENVOLVER AQUÍ
        child: HomeScreen(),
      ),
    );
  }
}
```

### 4. Copiar Inventario y Finanzas (Si es necesario)
- `lib/models/` - Todos los modelos de datos
- `lib/services/` - Servicios de negocio
- `lib/screens/inventario/` - UI de inventario
- `lib/screens/finanzas/` - UI de finanzas
- `lib/utils/database.dart` - Inicialización de BD

### 5. Generar Secreto de Producción
```bash
# Formato: [app]-prod-v1-2024-secure-key-[random]
# Ejemplo: pelucuba-prod-v1-2024-secure-key-abc123xyz789

# Generar parte random:
openssl rand -hex 16
```

### 6. Compilar para Producción
```bash
flutter build apk --release \
  --dart-define=LICENSE_SECRET=<TU_SECRETO_DE_PRODUCCION>
```

## 🔄 Modelo de Venta (Freemium + Viral)

```
Cliente instala APK
    ↓
15 días de prueba gratis (app funciona completamente)
    ↓
Puede compartir con amigos (cada instalación = nuevo trial de 15 días)
    ↓
Después de 15 días, app se bloquea
    ↓
Contacen al propietario para pagar
    ↓
Propietario genera licencia con generador-licencias.html
    ↓
Cliente activa licencia en app → acceso ilimitado
```

## 🔐 Seguridad

### Cada app tiene:
- ✅ Secreto único de producción
- ✅ Código de equipo único por dispositivo
- ✅ Licencias NO portables entre apps
- ✅ 15 días de trial antes de bloqueo

### Propietario debe:
- ✅ Guardar secreto en lugar seguro
- ✅ Nunca compartir secreto por email/chat
- ✅ Usar generador-licencias.html solo localmente
- ✅ Rotar secreto si se compromete

## 📊 Características Copiables

### Base de Datos
- ✅ SQLite offline-first
- ✅ Migration automática v1→v2
- ✅ Preservación de datos

### Inventario
- ✅ Productos por (nombre, categoria) - sin duplicados
- ✅ Movimientos (compra, salida, corrección)
- ✅ Costo promedio ponderado
- ✅ Integración automática con Finanzas

### Finanzas
- ✅ Gastos automáticos desde compras
- ✅ Gráficas de tendencia interactiva
- ✅ Filtros por período y categoría
- ✅ Sincronización bidireccional

### Navegación
- ✅ PopScope para control del botón atrás
- ✅ Double-tap para cerrar (Android)
- ✅ Navegación entre tabs inteligente

### Testing
- ✅ 50+ tests unitarios
- ✅ Tests de base de datos
- ✅ Tests de migración
- ✅ Tests de lógica de negocio

## 📦 Archivos Clave a Usar de Referencia

| Archivo | Propósito |
|---------|-----------|
| `lib/services/licencia_service.dart` | Sistema de licencias offline |
| `lib/screens/licencia/licencia_gate.dart` | Gate wrapper de la app |
| `lib/screens/licencia/licencia_screen.dart` | Pantalla de licencia/activación |
| `lib/utils/database.dart` | Inicialización y migraciones de BD |
| `lib/models/producto.dart` | Modelo de productos |
| `lib/services/inventario_service.dart` | Lógica de inventario |
| `lib/services/finanzas_service.dart` | Lógica de finanzas |
| `herramientas/generador-licencias.html` | Generador JS offline |
| `pubspec.yaml` | Dependencias recomendadas |
| `MANICUBA_FEATURES.md` | Documentación técnica completa |

## 🚀 Compilación Release

Ambas apps usan el mismo proceso:

```bash
# Con secreto de desarrollo (testing)
flutter build apk --release

# Con secreto de producción (venta)
flutter build apk --release \
  --dart-define=LICENSE_SECRET=[app]-prod-v1-2024-secure-key-[random]
```

## ✨ Próximas Apps

- **PelucuBA** - Copia sistema de licencias + UI propia
- **Future App** - Seguir mismo patrón
- **Etc.**

## 📞 Contacto y Soporte

Para dudas sobre la integración:
- Ver `LICENCIAS.md` - Sistema de licencias (documento único)
- Ver `MANICUBA_FEATURES.md` - Detalles técnicos

---

**ManiCuba v1.3.0** - Base para todas las aplicaciones
**Fecha**: 2026-08-14
**Compatible con**: Flutter 3.19.0+, Dart 3.3.0+
**Modelo**: Freemium + Viral Sharing (15 días gratis)
