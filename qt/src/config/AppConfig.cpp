#include "config/AppConfig.h"

#include <QLocale>

AppConfig::AppConfig(QObject *parent) : QObject(parent) {}

QStringList AppConfig::categoriasGastos() const
{
    return {QStringLiteral("Productos"), QStringLiteral("Servicios"),
            QStringLiteral("Alquiler"), QStringLiteral("Transporte"),
            QStringLiteral("Otros")};
}

QStringList AppConfig::categoriasProductos() const
{
    return {QStringLiteral("Esmaltes"),     QStringLiteral("Geles"),
            QStringLiteral("Acrílicos"),    QStringLiteral("Decoraciones"),
            QStringLiteral("Herramientas"), QStringLiteral("Limpiadores"),
            QStringLiteral("Otros")};
}

QStringList AppConfig::metodosPago() const
{
    return {QStringLiteral("Efectivo"), QStringLiteral("Transferencia"),
            QStringLiteral("Tarjeta")};
}

QStringList AppConfig::tiposPost() const
{
    return {QStringLiteral("Oferta"), QStringLiteral("Promoción"),
            QStringLiteral("Trabajo"), QStringLiteral("Testimonio"),
            QStringLiteral("Educativo")};
}

QStringList AppConfig::plataformasSociales() const
{
    return {QStringLiteral("Instagram"), QStringLiteral("Facebook"),
            QStringLiteral("WhatsApp"), QStringLiteral("Todas")};
}

QStringList AppConfig::emojisPopulares() const
{
    return {QStringLiteral("💅"), QStringLiteral("✨"), QStringLiteral("🌹"),
            QStringLiteral("💖"), QStringLiteral("🎀"), QStringLiteral("👑"),
            QStringLiteral("💄"), QStringLiteral("🌸"), QStringLiteral("🦋"),
            QStringLiteral("💫"), QStringLiteral("🔥"), QStringLiteral("😍"),
            QStringLiteral("🤩"), QStringLiteral("😊"), QStringLiteral("👌")};
}

QStringList AppConfig::hashtagsComunes() const
{
    return {QStringLiteral("#manicura"),  QStringLiteral("#uñas"),
            QStringLiteral("#nails"),     QStringLiteral("#beauty"),
            QStringLiteral("#diseño"),    QStringLiteral("#gelmanicure"),
            QStringLiteral("#acrylicnails"), QStringLiteral("#nailart"),
            QStringLiteral("#belleza"),   QStringLiteral("#esmalte")};
}

QString AppConfig::moneda(double valor) const
{
    return QStringLiteral("$") + QLocale(QLocale::Spanish).toString(valor, 'f', 2);
}

QString AppConfig::etiquetaEstado(const QString &estado) const
{
    if (estado == QStringLiteral("confirmada")) return QStringLiteral("Confirmada");
    if (estado == QStringLiteral("completada")) return QStringLiteral("Completada");
    if (estado == QStringLiteral("cancelada")) return QStringLiteral("Cancelada");
    return QStringLiteral("Pendiente");
}
