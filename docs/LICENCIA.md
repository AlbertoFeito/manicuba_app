# Licencia y prueba de 15 días

ManiCuba usa un modelo de **licencia por dispositivo, 100 % offline**, con una
**prueba gratis de 15 días** desde el primer arranque. Es fricción contra la
copia casual (no resistencia a que alguien desempaque el APK).

## Cómo funciona

1. En el primer uso, la app genera un **código de equipo** único (guardado en
   el dispositivo) y arranca el contador de prueba (15 días).
2. Durante la prueba, la app funciona con normalidad. En **Menú ⋮ → Licencia**
   la clienta ve los días restantes y su código de equipo.
3. Al vencer la prueba, la app queda bloqueada en la pantalla de activación.
4. La clienta te envía su **código de equipo**; tú generas la **licencia** con
   el generador (que guarda el secreto) y se la envías. Ella la escribe y la
   app se desbloquea para siempre en ese teléfono.

La verificación es local: `licencia = base32( HMAC-SHA256( secreto,
"manicuba:v1:<código-equipo>" ) )`. La app recomputa ese valor y lo compara.

## El secreto (IMPORTANTE)

- El secreto **no está en el repositorio**. Se inyecta al compilar:

  ```bash
  flutter build apk --release --dart-define=LICENSE_SECRET=TU_SECRETO
  ```

- Debes usar **el mismo secreto** en el generador. Si compilas sin
  `--dart-define`, la app usa `manicuba-dev-secret` (solo para desarrollo) y
  cualquiera podría generar códigos.
- Guarda el secreto en un lugar seguro. Si lo cambias, las licencias ya
  emitidas dejan de servir.

## Generar una licencia

### Opción A — Navegador (sin instalar nada)

Abre `herramientas/generador-licencias.html`, escribe tu secreto y el código
de equipo de la clienta, y copia la licencia.

### Opción B — Node

```bash
LICENSE_SECRET=TU_SECRETO node scripts/generar_licencia.mjs 7K3M9-2QXBD
# Equipo:   7K3M9-2QXBD
# Licencia: XXXX-XXXX-XXXX-XXXX
```

Los guiones y las minúsculas se ignoran; I/L se leen como 1 y O como 0, para
que sea fácil dictar los códigos.

## Archivos

| Archivo | Rol |
|---------|-----|
| `lib/services/licencia_service.dart` | Lógica (prueba, HMAC, estados) |
| `lib/screens/licencia/licencia_gate.dart` | Bloquea la app al vencer |
| `lib/screens/licencia/licencia_screen.dart` | Pantalla de activación |
| `scripts/generar_licencia.mjs` | Generador (Node) |
| `herramientas/generador-licencias.html` | Generador (navegador, offline) |
