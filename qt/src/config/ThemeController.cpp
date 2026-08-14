#include "config/ThemeController.h"

#include <QSettings>

ThemeController::ThemeController(QObject *parent) : QObject(parent)
{
    m_dark = QSettings().value(QStringLiteral("ui_dark"), false).toBool();
}

void ThemeController::setDark(bool v)
{
    if (m_dark == v)
        return;
    m_dark = v;
    QSettings().setValue(QStringLiteral("ui_dark"), v);
    emit changed();
}

QColor ThemeController::colorEstado(const QString &estado) const
{
    if (estado == QStringLiteral("confirmada")) return estadoConfirmada();
    if (estado == QStringLiteral("completada")) return estadoCompletada();
    if (estado == QStringLiteral("cancelada")) return estadoCancelada();
    return estadoPendiente();
}
