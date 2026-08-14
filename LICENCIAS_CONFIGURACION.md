# Sistema de Licencias Multi-App

Configuración centralizada para gestionar licencias en ManiCuba, PelucuBA y otras aplicaciones.

## Información de las Apps

```
┌─────────────────────────────────────────────────────────────┐
│                      APLICACIONES                           │
├─────────────────────────────────────────────────────────────┤
│ App         │ ID       │ Secreto de Producción              │
├─────────────────────────────────────────────────────────────┤
│ ManiCuba    │ manicuba │ manicuba-prod-v1-2024-secure-key   │
│ PelucuBA    │ pelucuba │ pelucuba-prod-v1-2024-secure-key   │
│ (Future)    │ (id)     │ (secret)                           │
└─────────────────────────────────────────────────────────────┘
```

## Secretos de Desarrollo (Solo Pruebas)

Estos secretos **NO** generan licencias válidas para venta:

```javascript
// Válido solo para desarrollo/testing
manicuba-dev-secret      // ManiCuba (v1.3.2+)
pelucuba-dev-secret      // PelucuBA (próximamente)
```

## Generador de Licencias (Compartido)

Ubicación: `herramientas/generador-licencias.html`

**Características:**
- ✅ Interfaz unificada para todas las apps
- ✅ Soporta múltiples secretos de producción
- ✅ Feedback visual en copiar
- ✅ Validación de códigos de equipo
- ✅ Advertencia de secreto de desarrollo

**Uso:**

```javascript
// Ejemplo: Generar licencia para PelucuBA
const secret = 'pelucuba-prod-v1-2024-secure-key';
const deviceCode = '7K3M9-2QXBD';
const licencia = await computeLicence(deviceCode, secret);
// Resultado: XGKM-KGCJ-G2BG-P8GJ
```

## Compilación con Secreto

### ManiCuba (Actual)

**Desarrollo:**
```bash
flutter build apk --release
# Usa: manicuba-dev-secret (sin venta)
```

**Producción (Venta Directa):**
```bash
flutter build apk --release \
  --dart-define=LICENSE_SECRET=manicuba-prod-v1-2024-secure-key-xyz789
# Licencias válidas solo para este APK
```

### PelucuBA (Próximamente)

**Producción:**
```bash
flutter build apk --release \
  --dart-define=LICENSE_SECRET=pelucuba-prod-v1-2024-secure-key-xyz789
# Licencias válidas solo para PelucuBA
```

## Estructura de Licencias

**Formato:**
```
ABCD-EFGH-IJKL-MNOP
```

**Generación:**
1. Código de equipo normalizado (mayúsculas, sin símbolos)
2. HMAC-SHA256(secreto, `app:v1:CODIGO`)
3. Codificado en Base32
4. Agrupado en bloques de 4 caracteres

**Validación en la App:**

```dart
// lib/services/licencia_service.dart
static const String _secret = String.fromEnvironment(
  'LICENSE_SECRET',
  defaultValue: 'manicuba-dev-secret',
);

Future<bool> validarLicencia(String codigo, String licencia) async {
  final generada = await _computarLicencia(codigo, _secret);
  return generada.replaceAll('-', '') == licencia.replaceAll('-', '');
}
```

## Flujo de Venta Directa

### 1. Cliente Compra
- Paga el costo de la app
- Recibe un APK o link de descarga

### 2. Instalación
- Instala ManiCuba/PelucuBA en su teléfono
- La app detecta el código de equipo único

### 3. Generación de Licencia
- Cliente proporciona su código de equipo
- Tu generador crea la licencia correspondiente
- Envías la licencia por WhatsApp/email

### 4. Validación
- Cliente ingresa la licencia en la app
- La app valida usando el secreto de producción
- ✅ App desbloqueada (30 días, renovable)
- ❌ Licencia rechazada (si es de otra app o desarrollo)

## Seguridad

**Qué está protegido:**
- ✅ Cada app tiene su propio secreto
- ✅ Cada equipo genera licencias únicas
- ✅ Las licencias no pueden portarse entre apps
- ✅ Las licencias dev no funcionan en producción

**Qué NO está protegido:**
- ❌ El secreto en el APK compilado
- ❌ Ingeniería inversa de la app
- ❌ Compartir APK entre usuarios

**Para mayor seguridad (futuro):**
- Server de validación en línea (requiere conexión)
- Licencias con fecha de expiración
- Validación de firma digital
- Rate limiting por IP

## Cambio de Secreto (Rotación)

Si un secreto se compromete:

1. Generar nuevo secreto
2. Compilar nuevo APK con nuevo secreto
3. Las licencias antiguas NO funcionarán
4. Los usuarios necesitan nuevo APK + nueva licencia

**Ejemplo:**
```bash
# Viejo APK (secreto_v1)
# → Licencias válidas solo para este APK

# Nuevo APK (secreto_v2)
# → Licencias válidas solo para este APK
# → Las licencias de secreto_v1 no funcionan
```

## Verificación

**Test rápido del generador:**

| Campo | Valor |
|-------|-------|
| Secreto | `manicuba-dev-secret` |
| Código | `7K3M9-2QXBD` |
| Licencia esperada | `XGKM-KGCJ-G2BG-P8GJ` |

Si obtienes este resultado, el generador funciona.

## Próximos Pasos

- [ ] PelucuBA: Integrar licencia_service.dart
- [ ] PelucuBA: Compilar con secreto de producción
- [ ] Crear generador personalizado si es necesario
- [ ] Documentar para soporte técnico
- [ ] Establecer política de validación/actualización

## Contacto para Soporte

- Reportar secreto comprometido: [email de seguridad]
- Cambios de licencia: [email de soporte]
- Nuevas apps: [email de desarrollo]

---

**Última actualización:** 2026-08-14
**Versión:** 1.0 (ManiCuba v1.3.2+19)
