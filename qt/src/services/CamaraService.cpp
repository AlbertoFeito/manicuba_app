#include "services/CamaraService.h"

#include <QDateTime>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>

#ifdef Q_OS_ANDROID
#include <QJniEnvironment>
#include <QtCore/qcoreapplication_platform.h>
#endif

CamaraService::CamaraService(QObject *parent) : QObject(parent) {}

#ifdef Q_OS_ANDROID

namespace {

// Limpia una excepción Java pendiente para no dejar el JNIEnv en un estado
// que rompería la siguiente llamada (p. ej. si openInputStream lanza
// SecurityException en algún fabricante raro).
void limpiarExcepcion(QJniEnvironment &env)
{
    if (env->ExceptionCheck()) {
        env->ExceptionClear();
    }
}

} // namespace

bool CamaraService::tomarFoto()
{
    QJniObject actividad = QNativeInterface::QAndroidApplication::context();
    if (!actividad.isValid())
        return false;

    const QString nombre = QStringLiteral("ManiCuba_%1.jpg")
                               .arg(QDateTime::currentMSecsSinceEpoch());

    QJniObject valores("android/content/ContentValues");
    valores.callMethod<void>("put", "(Ljava/lang/String;Ljava/lang/String;)V",
                             QJniObject::fromString(QStringLiteral("_display_name")).object<jstring>(),
                             QJniObject::fromString(nombre).object<jstring>());
    valores.callMethod<void>("put", "(Ljava/lang/String;Ljava/lang/String;)V",
                             QJniObject::fromString(QStringLiteral("mime_type")).object<jstring>(),
                             QJniObject::fromString(QStringLiteral("image/jpeg")).object<jstring>());

    QJniObject uriBase = QJniObject::getStaticObjectField(
        "android/provider/MediaStore$Images$Media", "EXTERNAL_CONTENT_URI", "Landroid/net/Uri;");
    if (!uriBase.isValid())
        return false;

    QJniObject resolver = actividad.callObjectMethod(
        "getContentResolver", "()Landroid/content/ContentResolver;");
    if (!resolver.isValid())
        return false;

    QJniEnvironment env;
    QJniObject uriNueva = resolver.callObjectMethod(
        "insert", "(Landroid/net/Uri;Landroid/content/ContentValues;)Landroid/net/Uri;",
        uriBase.object<jobject>(), valores.object<jobject>());
    limpiarExcepcion(env);
    if (!uriNueva.isValid())
        return false;

    QJniObject intent("android/content/Intent",
                      "(Ljava/lang/String;)V",
                      QJniObject::fromString(QStringLiteral("android.media.action.IMAGE_CAPTURE"))
                          .object<jstring>());
    intent.callObjectMethod(
        "putExtra", "(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;",
        QJniObject::fromString(QStringLiteral("output")).object<jstring>(),
        uriNueva.object<jobject>());

    actividad.callMethod<void>("startActivity", "(Landroid/content/Intent;)V", intent.object<jobject>());
    limpiarExcepcion(env);

    m_uriPendiente = uriNueva;
    return true;
}

QString CamaraService::recogerCaptura()
{
    if (!m_uriPendiente.isValid())
        return QString();

    QJniObject actividad = QNativeInterface::QAndroidApplication::context();
    QJniObject resolver = actividad.callObjectMethod(
        "getContentResolver", "()Landroid/content/ContentResolver;");
    if (!resolver.isValid()) {
        m_uriPendiente = QJniObject();
        return QString();
    }

    QJniEnvironment env;
    const QJniObject uriActual = m_uriPendiente;
    QString ruta;

    // Vía rápida: la columna DATA suele seguir resolviendo una ruta de
    // archivo válida para filas que la propia app insertó.
    {
        jclass claseString = env->FindClass("java/lang/String");
        jobjectArray proyeccion = env->NewObjectArray(1, claseString, nullptr);
        env->SetObjectArrayElement(proyeccion, 0,
                                   QJniObject::fromString(QStringLiteral("_data")).object<jstring>());
        QJniObject cursor = resolver.callObjectMethod(
            "query",
            "(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)"
            "Landroid/database/Cursor;",
            uriActual.object<jobject>(), proyeccion, static_cast<jstring>(nullptr),
            static_cast<jobjectArray>(nullptr), static_cast<jstring>(nullptr));
        env->DeleteLocalRef(proyeccion);
        limpiarExcepcion(env);

        if (cursor.isValid()) {
            const bool tieneFila = cursor.callMethod<jboolean>("moveToFirst", "()Z");
            if (tieneFila) {
                const jint idx = cursor.callMethod<jint>(
                    "getColumnIndex", "(Ljava/lang/String;)I",
                    QJniObject::fromString(QStringLiteral("_data")).object<jstring>());
                if (idx >= 0) {
                    ruta = cursor.callObjectMethod("getString", "(I)Ljava/lang/String;", idx).toString();
                }
            }
            cursor.callMethod<void>("close", "()V");
        }
    }

    const QFileInfo infoRapida(ruta);
    if (!ruta.isEmpty() && infoRapida.exists() && infoRapida.size() > 0) {
        m_uriPendiente = QJniObject();
        return ruta;
    }

    // Camino robusto: copiar los bytes vía InputStream (válido con scoped
    // storage en cualquier versión de Android).
    QJniObject flujo = resolver.callObjectMethod(
        "openInputStream", "(Landroid/net/Uri;)Ljava/io/InputStream;", uriActual.object<jobject>());
    limpiarExcepcion(env);

    QByteArray datos;
    if (flujo.isValid()) {
        jbyteArray buffer = env->NewByteArray(8192);
        while (true) {
            const jint leidos = flujo.callMethod<jint>("read", "([B)I", buffer);
            if (leidos <= 0)
                break;
            const int tamAnterior = datos.size();
            datos.resize(tamAnterior + leidos);
            env->GetByteArrayRegion(buffer, 0, leidos,
                                    reinterpret_cast<jbyte *>(datos.data() + tamAnterior));
        }
        env->DeleteLocalRef(buffer);
        flujo.callMethod<void>("close", "()V");
    }

    // Fila vacía (usuaria canceló la foto) o sin acceso: se limpia y no
    // queda una entrada fantasma en la Fotos del sistema.
    if (datos.isEmpty()) {
        resolver.callMethod<jint>(
            "delete", "(Landroid/net/Uri;Ljava/lang/String;[Ljava/lang/String;)I",
            uriActual.object<jobject>(), static_cast<jstring>(nullptr),
            static_cast<jobjectArray>(nullptr));
        limpiarExcepcion(env);
        m_uriPendiente = QJniObject();
        return QString();
    }

    const QString destino = QStandardPaths::writableLocation(QStandardPaths::TempLocation)
        + QStringLiteral("/manicuba_captura_%1.jpg").arg(QDateTime::currentMSecsSinceEpoch());
    QFile archivo(destino);
    if (archivo.open(QIODevice::WriteOnly)) {
        archivo.write(datos);
        archivo.close();
        ruta = destino;
    } else {
        ruta.clear();
    }

    m_uriPendiente = QJniObject();
    return ruta;
}

#else

bool CamaraService::tomarFoto()
{
    return false;
}

QString CamaraService::recogerCaptura()
{
    return QString();
}

#endif
