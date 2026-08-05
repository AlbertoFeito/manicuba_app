#!/bin/bash

# Script de Inicialización - ManiCuba App
# Este script configura el proyecto automáticamente

echo "════════════════════════════════════════════════════"
echo "  🎀 INICIANDO MANICUBA APP 🎀"
echo "════════════════════════════════════════════════════"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Verificar si Flutter está instalado
echo ""
print_info "Verificando Flutter..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter no está instalado"
    echo "Descarga Flutter desde: https://flutter.dev/docs/get-started/install"
    exit 1
fi
print_status "Flutter encontrado"

# Verificar versión de Flutter
FLUTTER_VERSION=$(flutter --version | grep -oP 'Flutter \K[^ ]*')
print_info "Versión de Flutter: $FLUTTER_VERSION"

# Verificar si Git está instalado
echo ""
print_info "Verificando Git..."
if ! command -v git &> /dev/null; then
    print_error "Git no está instalado"
    echo "Descarga Git desde: https://git-scm.com"
    exit 1
fi
print_status "Git encontrado"

# Ejecutar flutter doctor
echo ""
print_info "Ejecutando flutter doctor..."
flutter doctor

# Instalar dependencias
echo ""
print_info "Instalando dependencias..."
flutter pub get

if [ $? -eq 0 ]; then
    print_status "Dependencias instaladas correctamente"
else
    print_error "Error al instalar dependencias"
    exit 1
fi

# Configurar Git (si es necesario)
echo ""
print_info "Configurando Git..."
if [ -z "$(git config user.name)" ]; then
    git config --global user.name "AlbertoFeito"
    git config --global user.email "albertofeito10@gmail.com"
    print_status "Git configurado"
else
    print_status "Git ya está configurado"
fi

# Ver dispositivos disponibles
echo ""
print_info "Dispositivos disponibles:"
flutter devices

# Crear carpetas necesarias si no existen
echo ""
print_info "Verificando estructura de carpetas..."
mkdir -p lib/screens/agenda
mkdir -p lib/screens/clientes
mkdir -p lib/screens/servicios
mkdir -p lib/screens/finanzas
mkdir -p lib/screens/inventario
mkdir -p lib/screens/redes_sociales
mkdir -p lib/widgets
mkdir -p lib/utils
mkdir -p assets/images
mkdir -p assets/icons

print_status "Estructura de carpetas verificada"

# Resumen final
echo ""
echo "════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Inicialización completada${NC}"
echo "════════════════════════════════════════════════════"
echo ""
echo "Próximos pasos:"
echo ""
echo "1. Ejecutar la app:"
echo "   flutter run"
echo ""
echo "2. Ver dispositivos:"
echo "   flutter devices"
echo ""
echo "3. Ejecutar en modo release (más rápido):"
echo "   flutter run --release"
echo ""
echo "4. Compilar APK:"
echo "   flutter build apk --release"
echo ""
echo "Documentación:"
echo "  • SETUP.md - Guía completa de configuración"
echo "  • INICIACION_RAPIDA.md - Comandos esenciales"
echo "  • README.md - Información del proyecto"
echo ""
print_info "¡Listo para empezar a desarrollar! 🚀"
echo ""
