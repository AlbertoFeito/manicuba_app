#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "config/AppConfig.h"
#include "db/Database.h"
#include "services/CategoriaService.h"
#include "services/CitaService.h"
#include "services/ClienteService.h"
#include "services/FinanzasService.h"
#include "services/LicenciaService.h"
#include "services/ServicioService.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Identidad para QSettings (licencia, categorías personalizadas).
    QCoreApplication::setOrganizationName(QStringLiteral("AlbertoFeito"));
    QCoreApplication::setApplicationName(QStringLiteral("ManiCuba"));
    QCoreApplication::setApplicationVersion(QStringLiteral("1.0.0"));

    // Estilo Material (rosa) para acercarnos al look de la app Flutter.
    QQuickStyle::setStyle(QStringLiteral("Material"));

    if (!Database::instance().open()) {
        qCritical("No se pudo inicializar la base de datos. Saliendo.");
        return 1;
    }

    // Servicios (el orden importa: Citas depende de Finanzas y Clientes).
    auto *appConfig = new AppConfig(&app);
    auto *licencia = new LicenciaService(&app);
    auto *categorias = new CategoriaService(&app);
    auto *clientes = new ClienteService(&app);
    auto *servicios = new ServicioService(&app);
    auto *finanzas = new FinanzasService(&app);
    auto *citas = new CitaService(finanzas, clientes, &app);

    licencia->refrescar();

    QQmlApplicationEngine engine;
    QQmlContext *ctx = engine.rootContext();
    ctx->setContextProperty(QStringLiteral("AppConfig"), appConfig);
    ctx->setContextProperty(QStringLiteral("Licencia"), licencia);
    ctx->setContextProperty(QStringLiteral("Categorias"), categorias);
    ctx->setContextProperty(QStringLiteral("Clientes"), clientes);
    ctx->setContextProperty(QStringLiteral("Servicios"), servicios);
    ctx->setContextProperty(QStringLiteral("Finanzas"), finanzas);
    ctx->setContextProperty(QStringLiteral("Citas"), citas);

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
        return -1;
    }

    return app.exec();
}
