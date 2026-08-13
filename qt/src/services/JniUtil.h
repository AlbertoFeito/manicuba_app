#pragma once

// Utilidades JNI compartidas entre los servicios Android (CamaraService,
// CompartirService). Solo tiene sentido incluir esto bajo #ifdef Q_OS_ANDROID.

#ifdef Q_OS_ANDROID
#include <QJniEnvironment>

namespace JniUtil {

// Limpia una excepción Java pendiente para no dejar el JNIEnv en un estado
// que rompería la siguiente llamada (p. ej. si alguna operación de archivo
// lanza SecurityException en algún fabricante raro).
inline void limpiarExcepcion(QJniEnvironment &env)
{
    if (env->ExceptionCheck()) {
        env->ExceptionClear();
    }
}

} // namespace JniUtil
#endif
