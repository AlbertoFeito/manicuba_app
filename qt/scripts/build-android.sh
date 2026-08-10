#!/usr/bin/env bash
# Compila ManiCuba (Qt) para Android y genera un APK (debug, autofirmado).
#
# Requisitos (ajusta las rutas a tu instalación):
#   - Qt for Android + Qt host de la MISMA versión (aquí 6.4.2).
#   - Android SDK (platform-34, build-tools 34) y NDK.
#
# Uso:  bash qt/scripts/build-android.sh
set -euo pipefail

QT_VER="${QT_VER:-6.4.2}"
ABI="${ABI:-arm64-v8a}"                     # arm64-v8a | armeabi-v7a | x86_64
QT_ANDROID="${QT_ANDROID:-/opt/Qt/${QT_VER}/android_${ABI//-/_}}"
QT_HOST="${QT_HOST:-/opt/Qt/${QT_VER}/gcc_64}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/android-sdk}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-$(ls -d "$ANDROID_SDK_ROOT"/ndk/* | head -1)}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"     # carpeta qt/
BUILD="$ROOT/build-android"

echo ">> Qt Android : $QT_ANDROID"
echo ">> Qt host    : $QT_HOST"
echo ">> SDK / NDK  : $ANDROID_SDK_ROOT  |  $ANDROID_NDK_ROOT"

"$QT_ANDROID/bin/qt-cmake" -S "$ROOT" -B "$BUILD" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_HOST_PATH="$QT_HOST" \
    -DANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
    -DANDROID_NDK_ROOT="$ANDROID_NDK_ROOT" \
    -DQT_ANDROID_ABIS="$ABI"

cmake --build "$BUILD" -j"$(nproc)"

# Empaquetado: androiddeployqt usa el JSON de settings generado al configurar.
SETTINGS="$(ls "$BUILD"/android-*-deployment-settings.json | head -1)"
"$QT_HOST/bin/androiddeployqt" \
    --input "$SETTINGS" \
    --output "$BUILD/android-build" \
    --android-platform android-34 \
    --gradle

APK="$(find "$BUILD/android-build" -name '*.apk' | head -1)"
echo ">> APK generado: $APK"
