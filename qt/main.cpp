#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlError>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QTimer>

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QMutex>
#include <QStandardPaths>
#include <QStringList>
#include <QTextStream>

#include "config/AppConfig.h"
#include "config/ThemeController.h"
#include "db/Database.h"
#include "services/CategoriaService.h"
#include "services/CitaService.h"
#include "services/ClienteService.h"
#include "services/FinanzasService.h"
#include "services/FotoService.h"
#include "services/InventarioService.h"
#include "services/CamaraService.h"
#include "services/LicenciaService.h"
#include "services/RedesService.h"
#include "services/ServicioService.h"

// ---------------------------------------------------------------------------
// Diagnóstico de arranque.
//
// En Android, si el árbol QML no llega a crearse la app se cierra "al instante"
// sin dejar rastro visible. Para poder ver el motivo desde el propio teléfono
// (sin PC ni adb), acumulamos todos los mensajes (qDebug/qWarning/qCritical y
// los errores del motor QML) en un buffer y en un fichero de log, y —si el root
// falla— mostramos ese texto en una ventana de respaldo mínima.
// ---------------------------------------------------------------------------
namespace {
QMutex g_diagMutex;
QStringList g_diagBuffer;
QtMessageHandler g_previousHandler = nullptr;

QString diagLogPath()
{
    static QString cached;
    if (!cached.isEmpty())
        return cached;
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!dir.isEmpty()) {
        QDir().mkpath(dir);
        cached = QDir(dir).filePath(QStringLiteral("manicuba_log.txt"));
    }
    return cached;
}

void appendDiag(const QString &line)
{
    QMutexLocker lock(&g_diagMutex);
    g_diagBuffer.append(line);
    const QString path = diagLogPath();
    if (path.isEmpty())
        return;
    QFile f(path);
    if (f.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&f);
        out << QDateTime::currentDateTime().toString(Qt::ISODate) << "  " << line << '\n';
    }
}

void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    const char *etiqueta = "INFO";
    switch (type) {
    case QtDebugMsg: etiqueta = "DEBUG"; break;
    case QtInfoMsg: etiqueta = "INFO"; break;
    case QtWarningMsg: etiqueta = "WARN"; break;
    case QtCriticalMsg: etiqueta = "CRIT"; break;
    case QtFatalMsg: etiqueta = "FATAL"; break;
    }
    appendDiag(QStringLiteral("[%1] %2").arg(QString::fromUtf8(etiqueta), msg));
    // Mantén el comportamiento normal (logcat / stderr).
    if (g_previousHandler)
        g_previousHandler(type, context, msg);
}

QString diagTexto()
{
    QMutexLocker lock(&g_diagMutex);
    if (g_diagBuffer.isEmpty())
        return QStringLiteral("(sin mensajes registrados)");
    return g_diagBuffer.join(QLatin1Char('\n'));
}
} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Identidad para QSettings (licencia, categorías personalizadas) y para que
    // QStandardPaths::AppDataLocation resuelva la carpeta de datos/log.
    QCoreApplication::setOrganizationName(QStringLiteral("AlbertoFeito"));
    QCoreApplication::setApplicationName(QStringLiteral("ManiCubaQt"));
    QCoreApplication::setApplicationVersion(QStringLiteral("1.0.0"));

    // Captura de mensajes para diagnóstico (ver bloque de arriba). Empieza un
    // registro nuevo en cada arranque.
    if (const QString path = diagLogPath(); !path.isEmpty())
        QFile::remove(path);
    g_previousHandler = qInstallMessageHandler(messageHandler);
    appendDiag(QStringLiteral("== Arranque ManiCubaQt %1 ==")
                   .arg(QCoreApplication::applicationVersion()));

    // Estilo Material (rosa) para acercarnos al look de la app Flutter.
    QQuickStyle::setStyle(QStringLiteral("Material"));

    if (!Database::instance().open()) {
        qCritical("No se pudo inicializar la base de datos. Saliendo.");
        return 1;
    }

    // Servicios (el orden importa: Citas depende de Finanzas y Clientes).
    auto *appConfig = new AppConfig(&app);
    auto *theme = new ThemeController(&app);
    auto *licencia = new LicenciaService(&app);
    auto *categorias = new CategoriaService(&app);
    auto *clientes = new ClienteService(&app);
    auto *servicios = new ServicioService(&app);
    auto *finanzas = new FinanzasService(&app);
    auto *inventario = new InventarioService(finanzas, &app);
    auto *redes = new RedesService(&app);
    auto *fotos = new FotoService(&app);
    auto *citas = new CitaService(finanzas, clientes, &app);
    auto *camara = new CamaraService(&app);

    licencia->refrescar();

    QQmlApplicationEngine engine;

    // Vuelca los errores del motor QML al buffer/log de diagnóstico.
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, &app,
                     [](const QList<QQmlError> &errores) {
                         for (const QQmlError &e : errores)
                             appendDiag(QStringLiteral("[QML] %1").arg(e.toString()));
                     });

    QQmlContext *ctx = engine.rootContext();
    ctx->setContextProperty(QStringLiteral("AppConfig"), appConfig);
    ctx->setContextProperty(QStringLiteral("Theme"), theme);
    ctx->setContextProperty(QStringLiteral("Licencia"), licencia);
    ctx->setContextProperty(QStringLiteral("Categorias"), categorias);
    ctx->setContextProperty(QStringLiteral("Clientes"), clientes);
    ctx->setContextProperty(QStringLiteral("Servicios"), servicios);
    ctx->setContextProperty(QStringLiteral("Finanzas"), finanzas);
    ctx->setContextProperty(QStringLiteral("Inventario"), inventario);
    ctx->setContextProperty(QStringLiteral("Redes"), redes);
    ctx->setContextProperty(QStringLiteral("Fotos"), fotos);
    ctx->setContextProperty(QStringLiteral("Citas"), citas);
    ctx->setContextProperty(QStringLiteral("Camara"), camara);

    bool creado = false;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [&creado](QObject *obj, const QUrl &) {
            if (obj)
                creado = true;
        },
        Qt::DirectConnection);

    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/ManiCuba/qml/Main.qml")));
    if (engine.rootObjects().isEmpty() || !creado) {
        qCritical("No se pudo cargar la interfaz QML.");

        // Diagnóstico extra: intenta cargar por SEPARADO, con su propio
        // QQmlComponent, algunos de los .qml que suelen aparecer como
        // "no es un tipo" al fallar Main.qml. El error agregado que reporta
        // el motor al fallar el documento raíz suele resumir la causa real;
        // aquí se pide el detalle completo (Component::errors()) archivo por
        // archivo para saber el motivo verdadero.
        static const char *kSondas[] = {
            "qrc:/qt/qml/ManiCuba/qml/AppCard.qml",
            "qrc:/qt/qml/ManiCuba/qml/AyudaDialog.qml",
            "qrc:/qt/qml/ManiCuba/qml/EmptyState.qml",
            "qrc:/qt/qml/ManiCuba/qml/SectionHeader.qml",
            "qrc:/qt/qml/ManiCuba/qml/LicenciaGate.qml",
            "qrc:/qt/qml/ManiCuba/qml/HomeScreen.qml",
        };
        for (const char *ruta : kSondas) {
            QQmlComponent sonda(&engine, QUrl(QString::fromUtf8(ruta)),
                                 QQmlComponent::PreferSynchronous);
            QString resultado = QStringLiteral("[SONDA] %1 -> ").arg(QString::fromUtf8(ruta));
            if (sonda.isReady()) {
                resultado += QStringLiteral("OK (listo para crear)");
            } else if (sonda.isError()) {
                resultado += QStringLiteral("ERROR:");
                for (const QQmlError &e : sonda.errors())
                    resultado += QStringLiteral("\n    ") + e.toString();
            } else {
                resultado += QStringLiteral("status=%1 (ni listo ni error; ¿async?)")
                                  .arg(sonda.status());
            }
            appendDiag(resultado);
        }

        // En vez de cerrar en silencio, muestra el error en pantalla para que se
        // pueda diagnosticar desde el teléfono (una captura basta). La ventana de
        // respaldo usa solo QtQuick + QtQuick.Window, sin Controls/Material, para
        // mostrarse aunque el fallo esté en esos módulos.
        engine.rootContext()->setContextProperty(
            QStringLiteral("DiagLog"),
            QStringLiteral("ManiCuba no pudo cargar la interfaz.\n"
                           "Manda esta pantalla por captura.\n"
                           "----------------------------------------\n")
                + diagTexto());

        static const char *kFallbackQml = R"QML(
import QtQuick
import QtQuick.Window

Window {
    visible: true
    title: "ManiCuba — error de arranque"
    color: "#12121a"
    width: 420
    height: 820

    Flickable {
        anchors.fill: parent
        anchors.margins: 12
        contentWidth: width
        contentHeight: col.implicitHeight + 24
        clip: true

        Column {
            id: col
            width: parent.width
            spacing: 8

            Text {
                width: parent.width
                text: "ManiCuba — error de arranque"
                color: "#ff8fb0"
                font.pixelSize: 20
                font.bold: true
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: DiagLog
                color: "#f0f0f0"
                font.pixelSize: 13
                font.family: "monospace"
                wrapMode: Text.WrapAnywhere
                textFormat: Text.PlainText
            }
        }
    }
}
)QML";

        engine.loadData(QByteArray(kFallbackQml),
                        QUrl(QStringLiteral("qrc:/manicuba_fallback.qml")));

        if (engine.rootObjects().isEmpty()) {
            // Ni siquiera la ventana de respaldo cargó: no queda más que salir.
            return -1;
        }
        return app.exec();
    }

    // Herramienta de desarrollo: MANICUBA_SHOT=/ruta.png captura la ventana y sale.
    const QByteArray shot = qgetenv("MANICUBA_SHOT");
    if (!shot.isEmpty()) {
        if (auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first())) {
            QTimer::singleShot(900, win, [win, shot]() {
                const QImage img = win->grabWindow();
                if (!img.isNull())
                    img.save(QString::fromUtf8(shot));
                QCoreApplication::quit();
            });
        }
    }

    return app.exec();
}
