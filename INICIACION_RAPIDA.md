# ⚡ Iniciación Rápida - ManiCuba App

**Tiempo estimado: 15 minutos**

---

## 🎯 ¿Qué tienes listo?

El proyecto completo está configurado con:

✅ Estructura Flutter lista
✅ Base de datos SQLite integrada
✅ Todos los modelos creados
✅ Servicios de negocio implementados
✅ Pantalla principal funcionando
✅ Tema personalizado
✅ Constantes globales

---

## 📋 Checklist Rápido

Copia y pega estos comandos **en orden** en Claude Code:

### 1️⃣ CLONAR Y CONFIGURAR (5 min)

```bash
# Clonar el repositorio
git clone https://github.com/AlbertoFeito/manicuba-app.git
cd manicuba-app

# Configurar Git (solo la primera vez)
git config --global user.name "AlbertoFeito"
git config --global user.email "albertofeito10@gmail.com"
```

### 2️⃣ INSTALAR DEPENDENCIAS (5 min)

```bash
# Descargar todas las dependencias
flutter pub get

# Verificar que todo está bien
flutter doctor
```

### 3️⃣ EJECUTAR LA APP (5 min)

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en tu teléfono (asegúrate de tener depuración USB habilitada)
flutter run

# O ejecutar en modo liberado (más rápido):
flutter run --release
```

### 4️⃣ VER LA APP FUNCIONANDO ✅

Debería ver:
- ✅ Pantalla de inicio con "¡Bienvenida a ManiCuba!"
- ✅ Menú de navegación en la parte inferior
- ✅ Botones de acciones rápidas
- ✅ Información de versión

---

## 📂 Próximos Pasos para Desarrollo

### Sprint 1: AGENDA 📅

```bash
# Crear rama para trabajar
git checkout -b sprint-1-agenda

# Los archivos a crear están en:
# lib/screens/agenda/
# lib/services/cita_service.dart (YA ESTÁ LISTO)
```

### Sprint 2: CLIENTES 👥

```bash
git checkout -b sprint-2-clientes

# Los servicios ya están listos:
# lib/services/cliente_service.dart
```

### Sprint 3: FINANZAS 💰

```bash
git checkout -b sprint-3-finanzas

# Los servicios ya están listos:
# lib/services/finanzas_service.dart
```

### Sprint 4: REDES SOCIALES 📸

```bash
git checkout -b sprint-4-redes

# Los servicios ya están listos:
# lib/services/redes_service.dart
```

---

## 🔄 Workflow de Desarrollo Diario

### Cuando empieces a trabajar:

```bash
# 1. Ir a la rama principal
git checkout main

# 2. Traer cambios del servidor
git pull origin main

# 3. Crear una rama nueva para tu tarea
git checkout -b feature/mi-nueva-funcionalidad
```

### Mientras trabajas:

```bash
# Ver cambios hechos
git status

# Ver diferencias
git diff

# Ver logs
git log --oneline -10
```

### Cuando termines:

```bash
# Agregar cambios
git add .

# Hacer commit
git commit -m "feat: Descripción de lo que hiciste"

# Subir a GitHub
git push origin feature/mi-nueva-funcionalidad
```

### Crear Pull Request:

```bash
# Ve a GitHub en el navegador
# https://github.com/AlbertoFeito/manicuba-app

# Verás opción "Compare & pull request"
# Llena los detalles y crea el PR
```

---

## 🛠️ Servicios Ya Listos para Usar

### ClienteService
```dart
import 'services/cliente_service.dart';

final service = ClienteService();
await service.crearCliente(cliente);
await service.obtenerTodos();
await service.buscarPorNombre("nombre");
```

### CitaService
```dart
import 'services/cita_service.dart';

final service = CitaService();
await service.crearCita(cita);
await service.obtenerHoy();
await service.cambiarEstado(id, EstadoCita.completada);
```

### FinanzasService
```dart
import 'services/finanzas_service.dart';

final service = FinanzasService();
await service.registrarIngreso(ingreso);
await service.ingresoHoy();
await service.balanceMes();
```

### RedesService
```dart
import 'services/redes_service.dart';

final service = RedesService();
await service.crearPost(post);
await service.obtenerNoPublicados();
await service.estadisticas();
```

### InventarioService
```dart
import 'services/inventario_service.dart';

final service = InventarioService();

// Alta. Con registrarGasto: false para stock que ya se tenía.
await service.crearProducto(producto);

// Una compra sube el stock, promedia el costo y crea el gasto en Finanzas.
await service.registrarCompra(
  productoId: id,
  cantidad: 10,
  totalPagado: 500,
);

// Una salida solo descuenta: el dinero salió al comprar, no ahora.
await service.registrarSalida(productoId: id, cantidad: 2);

await service.registrarCorreccion(productoId: id, nuevoStock: 7);
await service.movimientosDe(id);
await service.obtenerBajoStock();
```

> **Modelo de costo:** el gasto ocurre cuando compras, por el total pagado.
> Consumir producto después no genera gasto. Solo `registrarCompra` (y el
> stock inicial de `crearProducto`) tocan Finanzas.

---

## 📊 Base de Datos

La base de datos está totalmente configurada con **10 tablas**:

- `clientes` - Información de clientes
- `servicios` - Servicios ofrecidos
- `citas` - Registro de citas
- `ingresos` - Dinero recibido
- `gastos` - Dinero gastado (`producto_id` marca los de compras de inventario)
- `productos` - Inventario
- `movimientos_inventario` - Entradas y salidas de stock
- `posts_redes` - Posts para redes
- `fotos_trabajo` - Galería
- `estadisticas_redes` - Métricas

Se crean automáticamente la primera vez que ejecutes la app.

Las instalaciones anteriores se actualizan solas: `DatabaseHelper.runMigrations`
aplica las migraciones en cadena al abrir la base. Al añadir o cambiar
columnas hay que subir `dbVersion` **y** escribir la migración correspondiente,
o los teléfonos que ya tienen la app se quedan con el esquema viejo.

---

## 🎨 Configuración del Tema

Todo está configurado en `lib/config/theme.dart`:

- Color primario: Rosa (#E91E63)
- Colores de estado personalizados
- Tipografía completa
- Botones y formularios estilizados

---

## 📱 Tamaño de Archivos

| Componente | Tamaño |
|-----------|--------|
| Código fuente | ~50 KB |
| Dependencias | ~200 MB (descargadas) |
| APK final | ~50-60 MB |
| Base de datos | Vacía al inicio |

---

## ❓ FAQs Rápidas

**P: ¿Necesito VPN?**  
R: No. La app funciona 100% offline.

**P: ¿Qué Android necesita?**  
R: 7.0+ (API 24+). La mayoría de teléfonos lo tienen.

**P: ¿Puedo cambiar los colores?**  
R: Sí. Edita `lib/config/theme.dart`

**P: ¿Dónde están los datos?**  
R: En la base de datos SQLite del teléfono. Privados y seguros.

**P: ¿Cómo hago backup?**  
R: Se implementarán exportaciones a JSON/CSV en Sprint 5.

**P: ¿Puedo compartir el código?**  
R: Sí, el repositorio es público en GitHub.

---

## 🚨 Si Algo Sale Mal

```bash
# Limpiar todo y empezar
flutter clean
flutter pub get

# Ver errores detallados
flutter run -v

# Actualizar Flutter
flutter upgrade

# Ver problemas del sistema
flutter doctor -v
```

---

## 📞 Documentación Completa

- **Guía completa:** `SETUP.md`
- **README:** `README.md`
- **Código comentado** en cada servicio

---

## ✨ Estado del Proyecto

| Fase | Estado |
|------|--------|
| Setup | ✅ Completo |
| Modelos | ✅ Completo |
| Base datos | ✅ Completo |
| Servicios | ✅ Completo |
| Pantalla inicio | ✅ Completo |
| Agenda | 🔄 Próximo |
| Clientes | 🔄 Próximo |
| Finanzas | 🔄 Próximo |
| Redes | 🔄 Próximo |
| Testing | 📋 Planeo |

---

**¿Listo para empezar? 🚀**

Copia el primer comando y comienza:

```bash
git clone https://github.com/AlbertoFeito/manicuba-app.git && cd manicuba-app
```

---

*Versión: 1.0.0*  
*Última actualización: 2024*
