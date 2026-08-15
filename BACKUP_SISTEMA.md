# Sistema de Backup Automático - ManiCuba y PeluCuba

## ✅ Descripción

Ambas apps (ManiCuba y PeluCuba) incluyen un sistema de backup automático que protege los datos del cliente. Si el dispositivo se daña, se pierde, o se borran accidentalmente los datos, el cliente puede restaurarlos desde un backup compartido.

## 🔄 Cómo Funciona

### 1. Backup Automático
- ✅ Se ejecuta automáticamente al iniciar la app
- ✅ Crea un archivo JSON con TODOS los datos
- ✅ Se guarda en: `/Backups/` en el directorio Documents del dispositivo
- ✅ Nombre: `manicuba-copia-AAAA-MM-DD.json` (o `pelucuba-copia-...`)

### 2. Contenido del Backup
El archivo JSON contiene:
```
{
  "exportDate": "2026-08-15T20:15:30.123456Z",
  "dbVersion": 2,
  "clientes": [...],        ← Todos los clientes
  "citas": [...],           ← Todas las citas
  "productos": [...],       ← Todos los productos
  "gastos": [...],          ← Todos los gastos
  "ingresos": [...],        ← Todos los ingresos
  "posts": [...],           ← Posts de redes sociales
  "movimientos_inventario": [...]  ← Historial de inventario
}
```

### 3. Guardar Automáticamente
No requiere acción del cliente. Al abrir la app:
1. Sistema detecta si hace falta un backup reciente
2. Exporta TODOS los datos a JSON
3. Guarda en `/Backups/` del dispositivo

## 📤 Compartir un Backup (Restauración de Emergencia)

### Para el Cliente
**Desde la app** (próximamente con UI):
1. Abre la app → Menú Ajustes/Ayuda
2. Busca "Backup de seguridad"
3. Toca "Compartir copia de seguridad"
4. Elige: WhatsApp, Gmail, Google Drive, etc.
5. Guarda el archivo en lugar seguro

**Manualmente**:
1. Abre Archivos del dispositivo
2. Navega a: Documents → Backups
3. Encuentra: `manicuba-copia-2026-08-15.json`
4. Comparte por WhatsApp/Email/Drive

### Para el Desarrollador
```dart
// Generar backup manualmente
final json = await BackupService.exportData();
print('Backup JSON: $json');

// Crear archivo de backup
final filePath = await BackupService.createBackupFile(storeName: 'Mi Tienda');
print('Guardado en: $filePath');

// Compartir por WhatsApp/email/Drive
await BackupService.shareBackup(storeName: 'Mi Tienda');
```

## 📥 Restaurar Datos desde Backup

### Escenario 1: Desinstalación Accidental
Si el cliente desinstala la app sin querer:

1. **Vuelve a instalar** la última versión de la app
2. **Abre** el archivo `manicuba-copia-AAAA-MM-DD.json` compartido
3. **Importa** en la app (botón "Restaurar backup")
4. ✅ **Todos los datos se recuperan**

### Escenario 2: Pérdida/Robo del Dispositivo
Si el cliente pierde el teléfono:

1. **Instala** la app en el dispositivo nuevo
2. **Obtiene** el archivo de backup compartido (WhatsApp, Drive, email)
3. **Restaura** en la nueva app
4. ✅ **Todos los datos se recuperan**

### Escenario 3: Borrado Accidental de Datos
Si se borra la app del dispositivo pero no se desinstala:

1. **Abre la app** (datos se han perdido)
2. **Busca** la carpeta `/Backups/` en Files
3. **Envía** el archivo más reciente a ti mismo (email/Drive)
4. **Abre** la app en dispositivo diferente
5. **Importa** el backup
6. ✅ **Datos recuperados**

## 💾 Dónde se Guardan los Backups

### En Dispositivos Android/iOS
```
Dispositivo → Archivos → Documents → Backups → manicuba-copia-2026-08-15.json
```

### Desde la App (Programáticamente)
```dart
// Obtener ruta del backup
final filePath = await BackupService.createBackupFile();
// Retorna: /data/user/0/com.albertofeito.manicuba_app/documents/Backups/manicuba-copia-2026-08-15.json
```

## ⚠️ Importante: Casos Peligrosos

### ❌ NO Perderá Datos
- ✅ Actualizar la app a versión nueva
- ✅ Reiniciar el dispositivo
- ✅ Cerrar la app
- ✅ Tomar backup automático (es seguro)

### ❌ SÍ Perderá Datos
- ❌ **Desinstalar la app sin antes compartir backup**
- ❌ **Limpiar datos de la app sin backup**
- ❌ **Formatear el dispositivo sin backup**
- ❌ **Borrar la carpeta /Backups/ manualmente**

### ⚠️ Recomendación Crítica
**Toda vez que exporte datos importantes:**
1. Guarda el backup en **al menos 2 lugares**:
   - Google Drive
   - Email (enviado a ti mismo)
   - Dropbox
   - Computadora (USB)

## 🔧 Implementación Técnica

### BackupService API

```dart
// Exportar datos a JSON
String json = await BackupService.exportData();

// Crear archivo de backup local
String? filePath = await BackupService.createBackupFile(
  storeName: 'Mi Negocio'
);

// Compartir backup (WhatsApp/email/Drive)
await BackupService.shareBackup(
  storeName: 'Mi Negocio'
);

// Importar datos desde JSON (⚠️ REEMPLAZA TODOS LOS DATOS)
await BackupService.importData(jsonString);

// Backup automático (se llama en main.dart)
await BackupService.maybeAutoBackup();
```

### Ubicación en Código
- **ManiCuba**: `lib/services/backup_service.dart`
- **PeluCuba**: `lib/services/backup_service.dart`

### Integración en main.dart
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await LicenciaService.instance.init();
  BackupService.maybeAutoBackup();  // ← Backup automático
  runApp(const MyApp());
}
```

## 📋 Checklist para Clientes

Cada cliente debería:

- [ ] Abrir la app regularmente (triggerea backup automático)
- [ ] Compartir un backup cada semana a Google Drive
- [ ] Guardar backup por email (enviar a ti mismo)
- [ ] Guardar backup en pendrive/computadora
- [ ] Revisar la carpeta `/Backups/` periódicamente
- [ ] Probar restaurar backup en dispositivo de prueba (anual)

## 🚀 Próximas Mejoras

- [ ] UI para ver backups disponibles
- [ ] Calendarioio de backups con historial
- [ ] Opción de backup cifrado
- [ ] Sincronización automática a Google Drive
- [ ] Comparación de datos entre backups
- [ ] Restauración parcial (seleccionar qué restaurar)

## ✅ Estado

- ✅ Sistema de backup implementado en ambas apps
- ✅ Auto-backup automático al iniciar
- ✅ Exportación a JSON funcional
- ✅ Importación desde JSON funcional
- ✅ Compartir por WhatsApp/email/Drive funcional
- ⏳ UI para gestionar backups (pendiente)

## 📞 Para Clientes

**Si pierdes datos:**
1. Revisa carpeta `/Backups/` en el dispositivo
2. Busca el archivo más reciente: `app-copia-AAAA-MM-DD.json`
3. Comparte conmigo por email/WhatsApp
4. Yo restauraré los datos en tu dispositivo

**Si te roban/pierdes el teléfono:**
1. Busca el backup guardado en Drive/email/pendrive
2. Instala la app en el dispositivo nuevo
3. Abre el archivo de backup
4. Restaura → ¡Listo!

---

**Compatibilidad:** Android 5.0+, iOS 11.0+ | Flutter 3.19.0+ | Dart 3.3.0+
**Fecha:** 2026-08-15
**Estado:** ✅ Implementado y funcional
