# Proceso de Actualización Segura (Sin Pérdida de Datos)

Documento que asegura que los clientes **NO pierden ningún dato** al actualizar ManiCuba o PeluCuba a una versión más nueva.

## ✅ Lo que se Preserva Automáticamente

### 1. Base de Datos SQLite
```
ManiCuba: /data/data/com.albertofeito.manicuba_app/databases/manicuba.db
PeluCuba: /data/data/com.albertofeito.pelucuba_app/databases/pelucuba.db
```

**Garantía:** Android NUNCA borra la base de datos durante actualización de app.

**Proceso:**
- Cliente compra v1.2.0 (dbVersion: 2)
- Cliente actualiza a v1.3.0 (dbVersion: 2)
  → BD se mantiene intacta
  → onUpgrade NO se ejecuta (misma versión)
  → Todos los datos se conservan ✅

- Cliente compra v1.0.0 (dbVersion: 1)
- Cliente actualiza a v2.0.0 (dbVersion: 2)
  → onUpgrade se ejecuta automáticamente
  → Migración v1→v2 idempotente (segura)
  → Todos los datos se conservan ✅

### 2. SharedPreferences (Licencia)
```
Almacén: /data/data/com.albertofeito.manicuba_app/shared_prefs/
```

**Datos guardados:**
- `lic_device_id` - Código único del equipo (generado al instalar)
- `lic_trial_started_at` - Fecha de inicio del trial
- `lic_license_key` - Licencia activada (si la tiene)

**Garantía:** Android NUNCA borra SharedPreferences durante actualización.

**Resultado:**
- Trial: sigue contando desde el primer día ✅
- Licencia activada: se mantiene activa ✅
- Código de equipo: permanece igual (NO cambia) ✅

### 3. Datos de Usuario (SQLite)
```
Almacenado en: manicuba.db / pelucuba.db
```

**Datos conservados:**
- ✅ Clientes (nombres, teléfono, dirección)
- ✅ Citas (fechas, servicios, dinero)
- ✅ Productos (nombre, categoría, stock, costo)
- ✅ Gastos (fecha, monto, categoría, producto_id)
- ✅ Ingresos (fecha, monto, servicio)
- ✅ Posts de redes sociales (fotos, descripciones)
- ✅ Movimientos de inventario (historial completo)

### 4. Fotos y Archivos
```
Almacén: /data/data/com.albertofeito.manicuba_app/app_documents/
```

**Garantía:** Guardadas con `getApplicationDocumentsDirectory()`.
Android NUNCA borra este directorio durante actualización.

**Resultado:**
- ✅ Todas las fotos de trabajos se mantienen ✅
- ✅ Todas las fotos de la galería se mantienen ✅

## ⚠️ Lo que BORRARIA los datos (y no hacer)

### ❌ Desinstalar la app
```bash
adb uninstall com.albertofeito.manicuba_app
# ← ESTO BORRA TODO
```

**Si el cliente desinstala la app:**
- ❌ Base de datos se borra
- ❌ SharedPreferences se borra
- ❌ Fotos se borran
- ❌ Código de licencia se pierde
- ⚠️ El cliente **perdería TODO**

**Solución:** El cliente debe **ACTUALIZAR**, NO desinstalar.

### ❌ Cambiar de certificado de firma
Si compilas una actualización con un certificado distinto:
```bash
# Versión 1.0 compilada con Certificado A
# Versión 2.0 compilada con Certificado B
# ← ANDROID RECHAZA LA ACTUALIZACIÓN
```

**Resultado:** El cliente ve "No se puede instalar sobre la app existente"

**Solución:** Usar SIEMPRE el MISMO certificado para cada app.

### ❌ Decrementar versionCode
```yaml
# Versión 1.3.0+19 instalada
# Cliente intenta actualizar a 1.2.0+18
# ← ANDROID RECHAZA (versión anterior)
```

**Solución:** Incrementar versionCode siempre.

## 🔐 Certificados Firmeza (CRÍTICO)

### ManiCuba
```
App ID:     com.albertofeito.manicuba_app
Keystore:   android/app/manicuba-release.jks
SHA-256:    3d70919f9def755f735cd392eda59e1f20df8ec83d0040750eb5e5c4aae22494

IMPORTANTE: TODAS las actualizaciones deben usar este certificado.
Si lo pierdes, no puedes compilar actualizaciones para usuarios existentes.
```

### PeluCuba
```
App ID:     com.albertofeito.pelucuba_app
Keystore:   pelos/android/app/pelucuba-release.jks (en pelucuba_app)
SHA-256:    39ab16a92939ab944f0de52d46141d4d8de5a97df7c639611b7fe60af5a14eb8

IMPORTANTE: TODAS las actualizaciones deben usar este certificado.
Si lo pierdes, no puedes compilar actualizaciones para usuarios existentes.
```

**⚠️ GUARDAR ESTOS CERTIFICADOS EN LUGAR SEGURO:**
- Hacer backup del archivo .jks
- Guardar la contraseña en lugar seguro
- NO perder el certificado (es imposible recuperarlo)

## 📊 Sistema de Migraciones (Seguro)

Ambas apps tienen migraciones incrementales idempotentes:

```dart
// database_helper.dart
static const int dbVersion = 2;

static Future<void> runMigrations(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await _migrarAV2(db);  // ← Idempotente (segura, no duplica)
  }
}
```

**Ejemplos de actualización segura:**

### Caso 1: Cliente en v1.0 (dbVersion: 1) → Actualiza a v1.3.2 (dbVersion: 2)
```
1. Android ejecuta onUpgrade(db, 1, 2)
2. runMigrations() corre _migrarAV2()
3. Añade columna producto_id a gastos (con CHECK para no duplicar)
4. Crea tabla movimientos_inventario
5. Genera saldo_inicial para productos existentes (idempotente)
6. ✅ Todos los datos se conservan
```

### Caso 2: Cliente en v1.3.0 (dbVersion: 2) → Actualiza a v1.3.2 (dbVersion: 2)
```
1. Android ve dbVersion: 2 → 2 (sin cambios)
2. onUpgrade NO se ejecuta
3. ✅ Todo se mantiene intacta
```

### Caso 3: Cliente actualiza v1.3.0 → v1.3.1 → v1.3.2
```
1. v1.3.0 → v1.3.1: dbVersion 2 → 2 (nada)
2. v1.3.1 → v1.3.2: dbVersion 2 → 2 (nada)
3. ✅ Datos se preservan en cada paso
```

## 🚀 Compilación Correcta (Preserva Datos)

### ManiCuba
```bash
cd /home/user/manicuba_app

# Incrementar versionCode (ej: 1.3.2+19 → 1.3.2+20)
# Editar pubspec.yaml: version: 1.3.2+20

# Compilar con MISMO certificado
flutter build apk --release \
  --dart-define=LICENSE_SECRET=<TU_SECRETO_DE_PRODUCCION>

# Verificar firma
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
# Debe mostrar: SHA-256: 3d70919f9def755f735cd392eda59e1f20df8ec83d0040750eb5e5c4aae22494
```

### PeluCuba
```bash
cd /home/user/manicuba_app/pelos

# Incrementar versionCode (ej: 1.0.4+5 → 1.0.4+6)
# Editar pubspec.yaml: version: 1.0.4+6

# Compilar con MISMO certificado
flutter build apk --release \
  --dart-define=LICENSE_SECRET=<TU_SECRETO_DE_PRODUCCION>

# Verificar firma
apksigner verify --print-certs dist/PeluCuba-1.0.4-venta.apk
# Debe mostrar: SHA-256: 39ab16a92939ab944f0de52d46141d4d8de5a97df7c639611b7fe60af5a14eb8
```

## ✅ Checklist Antes de Compilar Actualización

- [ ] Incrementé el versionCode (build number después del +)
- [ ] Usé el MISMO certificado (keystore) que la versión anterior
- [ ] Verifiqué que el SHA-256 del certificado coincida
- [ ] Testeé en un dispositivo: "Instalar actualización" (no reinstalar)
- [ ] Los datos del cliente se conservaron ✅
- [ ] Las fotos se conservaron ✅
- [ ] La licencia se conservó ✅
- [ ] El código de equipo sigue siendo el mismo ✅

## 🧪 Test de Actualización (Paso a Paso)

### En dispositivo de prueba:

```bash
# 1. Instalar versión anterior
adb install build/app/outputs/flutter-apk/app-v1.3.0-release.apk

# 2. Abrir app, agregar datos
# - Crear cliente "Test"
# - Crear cita
# - Crear producto
# - Guardar fotos

# 3. Verificar datos guardados
# - Cerrar app
# - Abrir app: datos siguen ✅

# 4. Instalar actualización (NO desinstalar)
adb install build/app/outputs/flutter-apk/app-v1.3.2-release.apk
# (Android solicita permiso para actualizar sobre existente)

# 5. Abrir app actualizada
# - Cliente "Test" sigue ✅
# - Cita sigue ✅
# - Producto sigue ✅
# - Fotos siguen ✅
# - Licencia sigue activa (si la tenía) ✅
# - Código de equipo es el mismo ✅
```

## 📝 Documentación para Clientes

**Instrucciones de actualización (enviar al cliente):**

```
🔄 ACTUALIZAR TU APP (SIN PERDER DATOS)

1. Abre tu tienda de apps (Google Play, etc.)
2. Busca "ManiCuba" o "PeluCuba"
3. Toca "Actualizar" (NO desinstales)
4. Espera a que termine

✅ Tus datos se conservan automáticamente:
   - Todos tus clientes
   - Todas tus citas
   - Todos tus productos
   - Todos tus gastos
   - Tu código de licencia
   - Todas tus fotos

⚠️ NO desinstales la app (eso borra TODO)
```

## 🔒 Garantías de Seguridad

| Elemento | Almacenamiento | Preservado en actualización | Notas |
|----------|---|---|---|
| Clientes | SQLite | ✅ Siempre | Base de datos NO se borra |
| Citas | SQLite | ✅ Siempre | Base de datos NO se borra |
| Productos | SQLite | ✅ Siempre | Base de datos NO se borra |
| Gastos/Ingresos | SQLite | ✅ Siempre | Base de datos NO se borra |
| Fotos | App Documents | ✅ Siempre | Directorio de app NO se borra |
| Posts Redes | SQLite | ✅ Siempre | Base de datos NO se borra |
| Código Licencia | SharedPreferences | ✅ Siempre | Prefs NO se borran |
| Trial Start Date | SharedPreferences | ✅ Siempre | Sigue contando desde el inicio |
| Device Code | SharedPreferences | ✅ Siempre | NO cambia, es único |

## ❌ Errores Comunes (Evitar)

### ❌ Error 1: Desinstalar para actualizar
```bash
adb uninstall com.albertofeito.manicuba_app
adb install app-release.apk
# ← BORRA TODO
```
**Correcto:** Solo hacer `adb install app-release.apk` (Android pregunta si actualizar)

### ❌ Error 2: Olvidar incrementar versionCode
```yaml
# v1.3.0 tiene version: 1.3.0+19
# v1.3.1 también tiene version: 1.3.0+19
# ← Android rechaza como actualización
```
**Correcto:** Incrementar siempre el número después del +

### ❌ Error 3: Cambiar certificado
```bash
# Versión 1.0 con Keystore A
# Versión 2.0 con Keystore B
# ← Android rechaza: "No se puede instalar sobre existente"
```
**Correcto:** Usar SIEMPRE el MISMO certificado

### ❌ Error 4: Compilar con secreto de desarrollo
```bash
flutter build apk --release
# ← Sin --dart-define, usa desarrollo
# Cliente no puede activar licencias de producción
```
**Correcto:**
```bash
flutter build apk --release \
  --dart-define=LICENSE_SECRET=<TU_SECRETO_DE_PRODUCCION>
```

## 📞 Si Un Cliente Perdió Sus Datos

**Causa probable:** Desinstaló la app (no actualizó).

**Recuperación:** 
- Si se hizo backup de la BD: recuperar del backup
- Si no: lamentablemente los datos se perdieron

**Prevención:** Enviar instrucciones claras: "Toca ACTUALIZAR, no desinstales"

## 🎯 Conclusión

✅ **Android preserva automáticamente:**
- Base de datos SQLite
- SharedPreferences
- Archivos en Application Documents Directory

✅ **Migraciones implementadas:**
- Idempotentes (seguras de correr múltiples veces)
- Preservan todos los datos existentes
- Soportan cambios de esquema sin pérdida

✅ **Certificados guardados:**
- ManiCuba: manicuba-release.jks
- PeluCuba: pelucuba-release.jks

**RESULTADO: Los clientes pueden actualizar con total seguridad. Sus datos se conservan completamente.** ✅

---

**Última actualización:** 2026-08-15
**Compatible con:** Android 5.0+, Flutter 3.19.0+
**Estado:** ✅ Verificado y Documentado
