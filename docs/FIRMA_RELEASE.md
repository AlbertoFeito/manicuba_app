# Firma de release (Android)

La app está configurada para firmar el build de release con una **keystore
propia** cuando existe el archivo `android/key.properties`. Si ese archivo no
está presente (por ejemplo en un clon limpio o en CI sin secretos), el build
cae automáticamente a la clave de depuración, de modo que `flutter build` sigue
funcionando sin configuración adicional.

## Archivos implicados

| Archivo | ¿Se versiona? | Contenido |
|---------|---------------|-----------|
| `android/app/build.gradle` | ✅ Sí | Lee `key.properties` y define `signingConfigs.release` |
| `android/key.properties` | ❌ No (gitignored) | Contraseñas y alias de la keystore |
| `android/app/manicuba-release.jks` | ❌ No (gitignored) | La keystore (clave privada) |
| `android/key.properties.example` | ✅ Sí | Plantilla de referencia |

> ⚠️ **Importante:** la keystore `.jks` y su contraseña **no están en el
> repositorio** (contienen la clave privada de firma). Guárdalas en un lugar
> seguro y con copia de respaldo. Si pierdes la keystore no podrás publicar
> actualizaciones de la app en Google Play bajo la misma identidad.

## Configurar la firma en una máquina nueva

1. Coloca tu keystore en `android/app/manicuba-release.jks`.
2. Copia la plantilla y rellena tus datos:
   ```bash
   cp android/key.properties.example android/key.properties
   # edita android/key.properties con tus contraseñas
   ```
3. Compila:
   ```bash
   flutter build apk --release      # APK firmado (instalación directa)
   flutter build appbundle --release  # AAB firmado (Google Play)
   ```

## Generar una keystore nueva (si hiciera falta)

```bash
keytool -genkeypair -v \
  -keystore android/app/manicuba-release.jks \
  -alias manicuba \
  -keyalg RSA -keysize 2048 -validity 10000
```

## Salidas del build

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

Para verificar la firma de un APK:

```bash
$ANDROID_SDK_ROOT/build-tools/<versión>/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk
```
