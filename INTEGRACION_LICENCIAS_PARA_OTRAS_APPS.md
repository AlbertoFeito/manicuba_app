# Integración del Sistema de Licencias en Otras Apps

Guía para integrar el sistema de licencias de ManiCuba en PelucuBA y otras aplicaciones.

## Resumen

ManiCuba ya tiene implementado un sistema completo y robusto de licencias listo para venta directa. Tu segunda app (PelucuBA) puede reutilizar **exactamente** la misma lógica, solo cambiando el secreto.

## Archivos a Copiar/Adaptar

### 1. Modelo de Licencia
**Origen:** `lib/services/licencia_service.dart`

**Para PelucuBA:**
```bash
cp lib/services/licencia_service.dart ../pelucuba_app/lib/services/
```

**Cambios necesarios:**
```dart
// En pelucuba_app/lib/services/licencia_service.dart
static const String _secret = String.fromEnvironment(
  'LICENSE_SECRET',
  defaultValue: 'pelucuba-dev-secret',  // ← Cambiar esto
);
```

### 2. Pantalla de Licencia
**Origen:** `lib/screens/licencia/licencia_screen.dart`

**Para PelucuBA:**
```bash
cp lib/screens/licencia/licencia_screen.dart ../pelucuba_app/lib/screens/licencia/
cp lib/screens/licencia/licencia_gate.dart ../pelucuba_app/lib/screens/licencia/
```

Adaptar:
- Nombres de la app (ManiCuba → PelucuBA)
- Colores si es necesario
- Duración del trial si es diferente

### 3. Generador de Licencias
**Origen:** `herramientas/generador-licencias.html`

**Ya está listo para múltiples secretos:**
```html
<!-- El generador soporta cualquier secreto -->
<!-- Solo ingresa el secreto de tu app en el campo -->
```

**Opcional:** Crear versión personalizada:
```bash
cp herramientas/generador-licencias.html \
   herramientas/generador-licencias-pelucuba.html
```

## Pasos de Integración Completa

### Paso 1: Copiar Archivos

```bash
# Desde pelucuba_app/
mkdir -p lib/services lib/screens/licencia lib/widgets

# Copiar servicios
cp ../manicuba_app/lib/services/licencia_service.dart lib/services/

# Copiar pantallas
cp ../manicuba_app/lib/screens/licencia/* lib/screens/licencia/

# Copiar widgets de ayuda (opcional)
cp ../manicuba_app/lib/widgets/ayuda_button.dart lib/widgets/
```

### Paso 2: Actualizar Secrets

```dart
// pelucuba_app/lib/services/licencia_service.dart

static const String _secret = String.fromEnvironment(
  'LICENSE_SECRET',
  defaultValue: 'pelucuba-dev-secret',  // ← Cambiar
);
```

### Paso 3: Integrar en Main

```dart
// pelucuba_app/lib/main.dart

import 'screens/licencia/licencia_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LicenciaService.instance.init();  // ← Agregar esto
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LicenciaGate(  // ← Envolver aquí
        child: HomeScreen(),
      ),
    );
  }
}
```

### Paso 4: Actualizar Pubspec

Verificar que tengas `shared_preferences`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.3.2
```

### Paso 5: Configurar BuildGradle (Android)

```gradle
// pelucuba_app/android/app/build.gradle
android {
    compileSdk = 34
    ndkVersion = "23.1.7779620"
}
```

### Paso 6: Compilar para Desarrollo

```bash
# Desde pelucuba_app/
flutter build apk --release
# Usa: pelucuba-dev-secret (sin venta)
```

### Paso 7: Compilar para Producción

Generar secreto único:
```bash
# Usar el formato: [app]-prod-v1-2024-secure-key-[random]
# Ejemplo: pelucuba-prod-v1-2024-secure-key-abc123xyz789

flutter build apk --release \
  --dart-define=LICENSE_SECRET=pelucuba-prod-v1-2024-secure-key-abc123xyz789
```

### Paso 8: Actualizar Generador

```bash
cp ../manicuba_app/herramientas/generador-licencias.html \
   herramientas/
```

El generador soporta cualquier secreto automáticamente.

## Validación de Integración

Después de integrar, verificar:

### ✅ Checklist

- [ ] App inicia con pantalla de licencia (primer uso)
- [ ] Código de equipo se genera automáticamente (único por dispositivo)
- [ ] Trial de 30 días funciona correctamente
- [ ] Licencia válida desbloquea la app
- [ ] Licencia inválida muestra error
- [ ] Licencia de desarrollo muestra advertencia
- [ ] El generador produce licencias válidas
- [ ] Botón de copiar funciona en generador

### Test Manual

```javascript
// Abrir generador en navegador
// Secreto: pelucuba-dev-secret
// Código: 7K3M9-2QXBD
// Licencia esperada: XGKM-KGCJ-G2BG-P8GJ (función hash es igual)
```

## Diferencias Entre Apps

Cada app tiene:
- **Secreto único:** pelucuba-prod-v1-2024-secure-key-xyz789
- **Código de equipo único:** generado por dispositivo
- **Licencias no portables:** una licencia de ManiCuba NO funciona en PelucuBA

Esto asegura que cada app tiene su propio ecosistema de licencias.

## Seguridad

### Producción Segura

1. **Generar secreto:** 
   ```bash
   openssl rand -hex 32
   # Ej: a1b2c3d4e5f6... (64 caracteres)
   ```

2. **Formato recomendado:**
   ```
   [app]-prod-v1-2024-secure-key-[random]
   ```

3. **Guardar en archivo SECRETO_PRODUCCION.txt** (gitignored)

4. **Nunca compartir el secreto**
   - No en GitHub
   - No en email
   - No en chats
   - Solo en compilación interna

### Rotación de Secreto

Si se compromete un secreto:

```bash
# Viejo APK compilado con secreto_v1
# → Las licencias de secreto_v1 funcionan

# Nuevo APK compilado con secreto_v2  
# → Las licencias de secreto_v2 funcionan
# → Las licencias de secreto_v1 NO funcionan
# → Los usuarios necesitan nuevo APK + nueva licencia
```

## Generador Personalizado (Opcional)

Si quieres un generador exclusivo para PelucuBA:

```bash
cp herramientas/generador-licencias.html \
   herramientas/generador-licencias-pelucuba.html
```

Cambiar en el HTML:
```html
<h1>💐 PelucuBA · Generador de Licencias</h1>
<p>Secreto por defecto (desarrollo): pelucuba-dev-secret</p>
```

## Troubleshooting

### "Licencia inválida"
- Verificar que el secreto de compilación coincide
- Verificar que el código de equipo es el correcto
- Verificar que la licencia no tiene espacios/guiones extras

### "Advertencia: secreto de desarrollo"
- Normal en versiones dev
- No comprar licencias basadas en este secreto
- Compilar con secreto de producción para vender

### "El código de equipo cambia cada vez"
- Es un bug
- Verificar que la app guarda el código en SharedPreferences
- Ver `licencia_service.dart` línea ~160

## Documentación Adicional

Ver archivos:
- `LICENCIAS_CONFIGURACION.md` - Configuración centralizada
- `SECRETO_PRODUCCION.txt` - Secreto actual de ManiCuba
- `docs/LICENCIA.md` - Documentación de usuarios

## Próximos Pasos

1. ✅ ManiCuba lista para venta (v1.3.2+19)
2. ⬜ PelucuBA: Integrar sistema de licencias
3. ⬜ PelucuBA: Compilar para producción
4. ⬜ Crear política de licencias y soporte
5. ⬜ Documentar para equipo de ventas

---

**Últimas pruebas:** 2026-08-14
**Compatible con:** Flutter 3.19.0+, Dart 3.3.0+
**Apps integradas:** ManiCuba v1.3.2+19
