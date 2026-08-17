# Sistema de Licencias (ManiCuba · PeluCuba)

Documento **único** del sistema de licencias, común a todas las apps del repo.
Sustituye a los antiguos `LICENCIAS_CONFIGURACION.md` e
`INTEGRACION_LICENCIAS_PARA_OTRAS_APPS.md` (eliminados por redundantes).

## Idea en una frase

Todas las apps usan **exactamente el mismo algoritmo**; lo único que cambia
entre apps es **el secreto**. Una licencia de una app no sirve en otra.

- Algoritmo: `HMAC_SHA256(secreto, "manicuba:v1:" + CODIGO_EQUIPO)` → Base32 (16
  caracteres) → agrupado en bloques de 4.
- El prefijo `manicuba:v1:` es **compartido** (histórico) y NO debe cambiarse:
  así un mismo generador vale para todas las apps.
- La separación entre apps la da **el secreto** (cada app el suyo).

## Apps y secretos

| App      | applicationId                    | Secreto de desarrollo   | Secreto de producción                       |
|----------|----------------------------------|-------------------------|---------------------------------------------|
| ManiCuba | `com.albertofeito.manicuba_app`  | `manicuba-dev-secret`   | `<TU_SECRETO_DE_PRODUCCION>`   |
| PeluCuba | `com.albertofeito.pelucuba_app`  | `pelucuba-dev-secret`   | `<TU_SECRETO_DE_PRODUCCION>`   |

> Los secretos de producción se guardan (fuera de aquí) en `SECRETO_PRODUCCION.txt`
> de cada app. El de desarrollo solo sirve para probar; NO genera licencias de venta.

## Generador único

`herramientas/generador-licencias.html` — **una sola herramienta para todas las
apps**. Ábrela en el navegador (funciona offline):

1. Elige la **App** en el desplegable (ManiCuba / PeluCuba).
2. Escribe el **secreto** de esa app (el mismo con el que se compiló el APK).
3. (Opcional) el **nombre de la clienta**.
4. Pega el **código de equipo** que te envía la clienta.
5. **Generar** → copia con "Copiar licencia" (solo el código) o "Copiar mensaje"
   (texto listo para WhatsApp con el nombre de la app y la clienta).

Alternativa por terminal: `scripts/generar_licencia.mjs`
```bash
LICENSE_SECRET=<secreto> node scripts/generar_licencia.mjs 7K3M9-2QXBD
```

## Compilar el APK de venta (cada app con su secreto)

```bash
# ManiCuba (desde la raíz del repo)
flutter build apk --release \
  --dart-define=LICENSE_SECRET=<TU_SECRETO_DE_PRODUCCION>

# PeluCuba (desde pelos/)
cd pelos && flutter build apk --release \
  --dart-define=LICENSE_SECRET=<TU_SECRETO_DE_PRODUCCION>
```
Sin `--dart-define` se usa el secreto de desarrollo (solo pruebas).

## Vectores de verificación (código `7K3M9-2QXBD`)

| Secreto                                       | Licencia esperada       |
|-----------------------------------------------|-------------------------|
| `manicuba-dev-secret`                         | `0ERE-DAE5-DDSZ-ESAP`   |
| `<TU_SECRETO_DE_PRODUCCION>`     | `FQ57-6JE1-66PJ-A888`   |
| `pelucuba-dev-secret`                         | `NFA9-KYPE-FZFM-6T7F`   |
| `<TU_SECRETO_DE_PRODUCCION>`     | `8H2H-XE2H-BCKC-8D8B`   |

> Nota: el valor `XGKM-KGCJ-G2BG-P8GJ` que aparecía en la documentación antigua
> era **incorrecto** (no coincide con el algoritmo real). Usa la tabla de arriba.

## Flujo de venta

1. La clienta instala el APK (15 días de prueba, luego bloquea).
2. En la pantalla **Licencia** ve su **código de equipo** y te lo envía.
3. Generas la licencia con el generador + tu secreto de producción.
4. Se la envías; la activa y queda desbloqueada.

## Seguridad (qué protege y qué no)

- ✅ Cada app tiene su secreto; las licencias no son portables entre apps.
- ✅ Cada equipo genera una licencia única.
- ❌ El secreto viaja dentro del APK compilado: alguien técnico podría extraerlo
  con ingeniería inversa. Es una barrera comercial normal, no seguridad fuerte.
- Si un secreto se compromete: genera uno nuevo, recompila y redistribuye
  (las licencias antiguas dejan de valer).

## Código de referencia

- App (validación): `lib/services/licencia_service.dart` (solo cambia el
  `defaultValue` del secreto por app).
- Pantallas: `lib/screens/licencia/licencia_gate.dart`, `licencia_screen.dart`.
- Trial: 15 días, bloqueante al vencer.
