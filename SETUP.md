# 📱 Guía de Configuración - ManiCuba App

Esta guía te ayudará a configurar el proyecto para desarrollar desde tu teléfono usando Claude Code y GitHub.

## ✅ Requisitos Previos

- Teléfono con Android 7.0+
- Acceso a internet (para descargar dependencias)
- Cuenta GitHub creada
- Acceso a Claude Code desde el móvil
- 500 MB de espacio disponible

---

## 🚀 PASO 1: Crear Repositorio en GitHub

### Desde tu teléfono (navegador):

1. Ve a **https://github.com**
2. Inicia sesión con `AlbertoFeito` / `albertofeito10@gmail.com`
3. Click en **"+"** (arriba a la derecha) → **"New repository"**
4. Ingresa los datos:
   - **Repository name:** `manicuba-app`
   - **Description:** "App de gestión de manicura - Flutter - Offline first"
   - **Visibility:** Selecciona **Public**
   - **README:** ✅ Activa "Add a README file"
   - **Gitignore:** Selecciona **Flutter**
5. Click **"Create repository"**

**URL del repo:**
```
https://github.com/AlbertoFeito/manicuba-app
```

---

## 📦 PASO 2: Preparar Claude Code

### Abre Claude Code en tu teléfono:

```
Abre la app de Claude → Menu → Claude Code
```

---

## 🔧 PASO 3: Clonar el Repositorio

En Claude Code, ejecuta:

```bash
git clone https://github.com/AlbertoFeito/manicuba-app.git
cd manicuba-app
```

---

## ⚙️ PASO 4: Configurar Git

Configura tu identidad de Git:

```bash
git config --global user.name "AlbertoFeito"
git config --global user.email "albertofeito10@gmail.com"
```

Verifica la configuración:

```bash
git config --global user.name
git config --global user.email
```

---

## 📚 PASO 5: Instalar Dependencias Flutter

```bash
flutter pub get
```

Este comando descargará todas las dependencias listadas en `pubspec.yaml`.

---

## 🏃 PASO 6: Ejecutar la App

### Opción A: Conectar tu teléfono

1. Habilita **Depuración USB** en el teléfono:
   - Configuración → Opciones de desarrollador → Depuración USB

2. Conecta el teléfono por USB

3. Ejecuta:
```bash
flutter devices
```

Deberías ver tu teléfono listado.

### Opción B: Usar un emulador Android

```bash
flutter emulators --launch Emulator-Name
```

### Ejecutar la app:

```bash
flutter run
```

---

## 💾 PASO 7: Flujo de Trabajo Diario

### Crear una rama para tu trabajo:

```bash
git checkout -b sprint-1-agenda
```

### Hacer cambios en los archivos

Edita los archivos necesarios usando Claude Code.

### Guardar cambios:

```bash
git add .
git commit -m "Sprint 1: Agenda completada"
```

### Subir a GitHub:

```bash
git push origin sprint-1-agenda
```

### Crear Pull Request (opcional):

Desde GitHub en el navegador:
1. Ve a tu repositorio
2. Verás un botón "Compare & pull request"
3. Llena los detalles y click "Create pull request"

### Volver a la rama principal:

```bash
git checkout main
git pull origin main
```

---

## 📁 Estructura de Carpetas

```
manicuba-app/
├── lib/
│   ├── main.dart                  # Punto de entrada
│   ├── config/                    # Configuración
│   ├── models/                    # Modelos de datos
│   ├── database/                  # SQLite
│   ├── services/                  # Lógica de negocio
│   └── screens/                   # Pantallas UI
├── pubspec.yaml                   # Dependencias
├── README.md                       # Documentación
└── SETUP.md                        # Esta guía
```

---

## 🐛 Solucionar Problemas

### Error: "Permission denied" en git push

```bash
# Genera una token en GitHub:
# 1. Configuración → Developer settings → Personal access tokens
# 2. Genera un nuevo token con permisos 'repo'
# 3. Usa el token como contraseña
```

### Error: "No provider found for..."

Asegúrate de instalar todas las dependencias:

```bash
flutter pub get
flutter clean
flutter pub get
```

### Error: "Gradle build failed"

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "The connection was refused"

Verifica que tienes internet y que el dispositivo está conectado:

```bash
flutter devices
```

---

## 📊 Comandos Útiles

| Comando | Descripción |
|---------|-------------|
| `flutter run` | Ejecutar app en desarrollo |
| `flutter run -v` | Ejecutar con modo verbose (detallado) |
| `flutter clean` | Limpiar build cache |
| `flutter pub get` | Descargar dependencias |
| `flutter pub upgrade` | Actualizar dependencias |
| `flutter build apk` | Generar APK de release |
| `flutter devices` | Listar dispositivos conectados |
| `git status` | Ver cambios sin guardar |
| `git log --oneline` | Ver historial de commits |
| `git diff` | Ver diferencias en archivos |

---

## 🎯 Próximos Pasos

1. ✅ Crear repositorio en GitHub
2. ✅ Clonar el repositorio
3. ✅ Instalar Flutter y dependencias
4. ✅ Ejecutar la app
5. 📝 Empezar a trabajar en los sprints

---

## 📞 Ayuda

Si tienes problemas:

1. Verifica la conexión a internet
2. Revisa los logs de error en detalle
3. Intenta `flutter clean` y `flutter pub get` de nuevo
4. Asegúrate que Flutter está actualizado: `flutter upgrade`

---

**¡Listo para empezar! 🚀**

Ahora puedes empezar a desarrollar. El siguiente paso es trabajar en los Sprint.

---

*Última actualización: 2024*
*Versión: 1.0.0*
