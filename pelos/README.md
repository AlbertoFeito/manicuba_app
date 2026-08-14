# PeluCuba - App de Gestión de Peluquería 💇

App móvil Flutter para gestionar un negocio de peluquería y peinados con sincronización offline-first.

> Adaptada de **ManiCuba** (app de manicura). Comparte la misma arquitectura, orientada al trabajo con el pelo.

## ✨ Características

✅ **Gestión de citas y clientes** - Calendario y perfiles
✅ **Control de finanzas** - Ingresos, gastos, balance
✅ **Inventario de productos** - Stock, alertas
✅ **Gestor de redes sociales** - Posts, publicador, estadísticas
✅ **Reportes y estadísticas** - Análisis completo
✅ **100% Offline** - Funciona sin internet
✅ **Backup automático** - Respaldo de datos
✅ **Exportación** - CSV, JSON, PDF

## 📱 Requisitos

- Flutter 3.0+
- Android 7.0+ (API 24+)
- 50 MB espacio libre
- Dart 3.0+

## 🚀 Instalación Rápida

### Desde GitHub

```bash
git clone https://github.com/AlbertoFeito/pelucuba-app.git
cd pelucuba-app
flutter pub get
flutter run
```

### Crear APK

```bash
flutter build apk --release
# El APK estará en: build/app/outputs/flutter-app.apk
```

## 📁 Estructura del Proyecto

```
pelucuba-app/
├── lib/
│   ├── main.dart                 # Punto de entrada
│   ├── config/
│   │   ├── theme.dart            # Tema de la app
│   │   └── constants.dart        # Constantes globales
│   ├── models/                   # Modelos de datos
│   │   ├── cliente.dart
│   │   ├── cita.dart
│   │   ├── servicio.dart
│   │   ├── ingreso.dart
│   │   ├── gasto.dart
│   │   ├── producto.dart
│   │   └── post_redes.dart
│   ├── database/                 # SQLite
│   │   ├── database_helper.dart
│   │   └── schema.sql
│   ├── services/                 # Lógica de negocio
│   │   ├── cliente_service.dart
│   │   ├── cita_service.dart
│   │   ├── servicio_service.dart
│   │   ├── finanzas_service.dart
│   │   ├── inventario_service.dart
│   │   └── redes_service.dart
│   ├── screens/                  # Pantallas UI
│   │   ├── agenda/
│   │   ├── clientes/
│   │   ├── servicios/
│   │   ├── finanzas/
│   │   ├── inventario/
│   │   ├── redes_sociales/
│   │   └── home_screen.dart
│   ├── widgets/                  # Componentes reutilizables
│   └── utils/
│       ├── exportadores.dart
│       └── validadores.dart
├── assets/
│   ├── images/
│   └── icons/
├── pubspec.yaml
└── README.md
```

## 🗂️ Estructura de Base de Datos

### Tablas principales:

- **clientes** - Información de clientes
- **citas** - Registro de citas/turnos
- **servicios** - Servicios ofrecidos
- **ingresos** - Dinero recibido
- **gastos** - Dinero gastado
- **productos** - Inventario
- **movimientos_inventario** - Entradas y salidas de stock
- **posts_redes** - Posts para redes sociales
- **fotos_trabajo** - Galería de trabajos
- **estadisticas_redes** - Métricas sociales

## 📊 Funcionalidades por Módulo

### 📅 Agenda
- Calendario mensual/semanal
- Crear/editar/eliminar citas
- Estados: pendiente, confirmada, completada, cancelada
- Buscar por cliente o fecha

### 👥 Clientes
- Base de datos de clientes
- Historial de citas
- Notas personales
- Preferencias y alergias

### 💰 Finanzas
- Registrar ingresos por cita
- Control de gastos por categoría
- Dashboard con balance
- Gráficos de tendencias
- Reportes mensuales

### 📦 Inventario
- Listado de productos
- Control de stock
- Alertas de bajo stock
- Registrar compras: crea el gasto en Finanzas automáticamente
- Historial de entradas y salidas por producto
- Costo unitario con promedio ponderado entre compras

### 📸 Redes Sociales
- Crear posts con emojis y hashtags
- Galería de fotos del trabajo
- Plantillas predefinidas
- Programador de publicaciones
- Exportar para Instagram/WhatsApp
- Estadísticas de posts

### 📈 Reportes
- Reporte diario
- Reporte semanal
- Reporte mensual
- Exportar a PDF
- Gráficos de análisis

## 🔧 Desarrollo

### Configurar entorno

```bash
# Clonar
git clone https://github.com/AlbertoFeito/pelucuba-app.git
cd pelucuba-app

# Instalar dependencias
flutter pub get

# Generar código (json_serializable)
flutter pub run build_runner build

# Ejecutar
flutter run
```

### Crear rama para nuevo feature

```bash
git checkout -b feature/nombre-feature
# Hacer cambios...
git add .
git commit -m "Descripción del cambio"
git push origin feature/nombre-feature
```

### Commits convencionales

```
feat: Agregar nueva funcionalidad
fix: Corregir bug
refactor: Mejorar código
test: Agregar tests
docs: Actualizar documentación
```

## 📱 Compatibilidad

| Aspecto | Soporte |
|--------|---------|
| Versión Android | 7.0+ (API 24+) |
| Versión iOS | No soportado actualmente |
| Tamaño APK | ~50-60 MB |
| RAM mínima | 1 GB |
| Almacenamiento | 50 MB |

## 🔐 Privacidad y Seguridad

- ✅ Todos los datos se almacenan localmente
- ✅ Sin conexión a internet para funcionar
- ✅ Base de datos cifrada (opcional)
- ✅ Backup manual controlado por usuario
- ✅ Sin análisis ni telemetría

## 🆘 Soporte y Reportar Bugs

- 📧 Email: albertofeito10@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/AlbertoFeito/pelucuba-app/issues)

## 📝 Licencia

MIT License - Ver LICENSE.md

## 🙏 Créditos

Desarrollado por **Alberto Feito** con asistencia de Claude AI.

---

**Versión:** 1.0.0  
**Última actualización:** 2024  
**Estado:** En desarrollo activo
