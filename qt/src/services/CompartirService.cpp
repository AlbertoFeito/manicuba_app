#include "services/CompartirService.h"

#include <QFile>
#include <QFileInfo>
#include <QIODevice>

#ifdef Q_OS_ANDROID
#include <QJniEnvironment>
#include <QJniObject>
#include <QtCore/qcoreapplication_platform.h>
#include "services/JniUtil.h"
using JniUtil::limpiarExcepcion;
#endif

CompartirService::CompartirService(QObject *parent) : QObject(parent) {}

#ifdef Q_OS_ANDROID

namespace {

QString mimeDeArchivo(const QString &ruta)
{
    const QString ext = QFileInfo(ruta).suffix().toLower();
    if (ext == QStringLiteral("jpg") || ext == QStringLiteral("jpeg"))
        return QStringLiteral("image/jpeg");
    if (ext == QStringLiteral("png"))
        return QStringLiteral("image/png");
    if (ext == QStringLiteral("webp"))
        return QStringLiteral("image/webp");
    if (ext == QStringLiteral("bmp"))
        return QStringLiteral("image/bmp");
    return QStringLiteral("image/*");
}

} // namespace

bool CompartirService::compartirFoto(const QString &rutaLocal)
{
    QFile origen(rutaLocal);
    if (!origen.exists() || !origen.open(QIODevice::ReadOnly))
        return false;
    const QByteArray datos = origen.readAll();
    origen.close();
    if (datos.isEmpty())
        return false;

    QJniObject actividad = QNativeInterface::QAndroidApplication::context();
    if (!actividad.isValid())
        return false;

    const QString mime = mimeDeArchivo(rutaLocal);
    const QString nombre = QFileInfo(rutaLocal).fileName();

    QJniObject valores("android/content/ContentValues");
    valores.callMethod<void>("put", "(Ljava/lang/String;Ljava/lang/String;)V",
                             QJniObject::fromString(QStringLiteral("_display_name")).object<jstring>(),
                             QJniObject::fromString(nombre).object<jstring>());
    valores.callMethod<void>("put", "(Ljava/lang/String;Ljava/lang/String;)V",
                             QJniObject::fromString(QStringLiteral("mime_type")).object<jstring>(),
                             QJniObject::fromString(mime).object<jstring>());

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

    // Escribe los bytes del archivo local en la fila de MediaStore recién
    // creada -operación inversa a la lectura por bloques que ya hace
    // CamaraService::recogerCaptura()-, así se obtiene un URI content://
    // compartible sin depender de FileProvider/androidx.
    QJniObject flujo = resolver.callObjectMethod(
        "openOutputStream", "(Landroid/net/Uri;)Ljava/io/OutputStream;", uriNueva.object<jobject>());
    limpiarExcepcion(env);
    if (!flujo.isValid()) {
        resolver.callMethod<jint>(
            "delete", "(Landroid/net/Uri;Ljava/lang/String;[Ljava/lang/String;)I",
            uriNueva.object<jobject>(), static_cast<jstring>(nullptr),
            static_cast<jobjectArray>(nullptr));
        limpiarExcepcion(env);
        return false;
    }

    const int tamBloque = 65536;
    for (int i = 0; i < datos.size(); i += tamBloque) {
        const int n = qMin(tamBloque, datos.size() - i);
        jbyteArray buffer = env->NewByteArray(n);
        env->SetByteArrayRegion(buffer, 0, n,
                                reinterpret_cast<const jbyte *>(datos.constData() + i));
        flujo.callMethod<void>("write", "([BII)V", buffer, jint(0), jint(n));
        env->DeleteLocalRef(buffer);
    }
    limpiarExcepcion(env);
    flujo.callMethod<void>("close", "()V");

    QJniObject intent(
        "android/content/Intent", "(Ljava/lang/String;)V",
        QJniObject::fromString(QStringLiteral("android.intent.action.SEND")).object<jstring>());
    intent.callObjectMethod("setType", "(Ljava/lang/String;)Landroid/content/Intent;",
                            QJniObject::fromString(mime).object<jstring>());
    intent.callObjectMethod(
        "putExtra", "(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;",
        QJniObject::fromString(QStringLiteral("android.intent.extra.STREAM")).object<jstring>(),
        uriNueva.object<jobject>());
    intent.callObjectMethod("addFlags", "(I)Landroid/content/Intent;",
                            jint(1)); // FLAG_GRANT_READ_URI_PERMISSION

    QJniObject titulo = QJniObject::fromString(QStringLiteral("Compartir foto"));
    QJniObject chooser = QJniObject::callStaticObjectMethod(
        "android/content/Intent", "createChooser",
        "(Landroid/content/Intent;Ljava/lang/CharSequence;)Landroid/content/Intent;",
        intent.object<jobject>(), titulo.object<jobject>());
    limpiarExcepcion(env);
    if (!chooser.isValid())
        return false;

    actividad.callMethod<void>("startActivity", "(Landroid/content/Intent;)V", chooser.object<jobject>());
    limpiarExcepcion(env);
    return true;
}

#else

bool CompartirService::compartirFoto(const QString &)
{
    return false;
}

#endif
