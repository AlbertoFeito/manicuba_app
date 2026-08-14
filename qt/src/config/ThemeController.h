#pragma once

#include <QColor>
#include <QObject>

// Tema de la app (colores y medidas), expuesto a QML como propiedad global
// "Theme". Soporta modo claro/oscuro con persistencia (QSettings).
// Sustituye al antiguo singleton QML Theme.qml.
class ThemeController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool dark READ dark WRITE setDark NOTIFY changed)

    // Marca (constantes en ambos modos)
    Q_PROPERTY(QColor primary READ primary NOTIFY changed)
    Q_PROPERTY(QColor primaryLight READ primaryLight NOTIFY changed)
    Q_PROPERTY(QColor primaryDark READ primaryDark NOTIFY changed)
    Q_PROPERTY(QColor accent READ accent NOTIFY changed)
    Q_PROPERTY(QColor success READ success NOTIFY changed)
    Q_PROPERTY(QColor error READ error NOTIFY changed)
    Q_PROPERTY(QColor warning READ warning NOTIFY changed)
    Q_PROPERTY(QColor info READ info NOTIFY changed)

    // Dependientes del modo
    Q_PROPERTY(QColor background READ background NOTIFY changed)
    Q_PROPERTY(QColor surface READ surface NOTIFY changed)
    Q_PROPERTY(QColor surfaceAlt READ surfaceAlt NOTIFY changed)
    Q_PROPERTY(QColor textPrimary READ textPrimary NOTIFY changed)
    Q_PROPERTY(QColor textSecondary READ textSecondary NOTIFY changed)
    Q_PROPERTY(QColor divider READ divider NOTIFY changed)

    // Estados de cita (constantes)
    Q_PROPERTY(QColor estadoPendiente READ estadoPendiente NOTIFY changed)
    Q_PROPERTY(QColor estadoConfirmada READ estadoConfirmada NOTIFY changed)
    Q_PROPERTY(QColor estadoCompletada READ estadoCompletada NOTIFY changed)
    Q_PROPERTY(QColor estadoCancelada READ estadoCancelada NOTIFY changed)

    // Medidas
    Q_PROPERTY(int paddingSmall READ paddingSmall CONSTANT)
    Q_PROPERTY(int padding READ padding CONSTANT)
    Q_PROPERTY(int paddingLarge READ paddingLarge CONSTANT)
    Q_PROPERTY(int radiusSmall READ radiusSmall CONSTANT)
    Q_PROPERTY(int radius READ radius CONSTANT)
    Q_PROPERTY(int radiusLarge READ radiusLarge CONSTANT)

public:
    explicit ThemeController(QObject *parent = nullptr);

    bool dark() const { return m_dark; }
    void setDark(bool v);
    Q_INVOKABLE void toggle() { setDark(!m_dark); }

    QColor primary() const { return QColor(QStringLiteral("#E91E63")); }
    QColor primaryLight() const { return QColor(QStringLiteral("#F48FB1")); }
    QColor primaryDark() const { return QColor(QStringLiteral("#C2185B")); }
    QColor accent() const { return QColor(QStringLiteral("#FFC107")); }
    QColor success() const { return QColor(m_dark ? QStringLiteral("#66BB6A") : QStringLiteral("#2E9E52")); }
    QColor error() const { return QColor(m_dark ? QStringLiteral("#EF5350") : QStringLiteral("#E53935")); }
    QColor warning() const { return QColor(QStringLiteral("#FFB300")); }
    QColor info() const { return QColor(m_dark ? QStringLiteral("#42A5F5") : QStringLiteral("#1E88E5")); }

    QColor background() const { return QColor(m_dark ? QStringLiteral("#141019") : QStringLiteral("#FDF5F8")); }
    QColor surface() const { return QColor(m_dark ? QStringLiteral("#211A26") : QStringLiteral("#FFFFFF")); }
    QColor surfaceAlt() const { return QColor(m_dark ? QStringLiteral("#2A2230") : QStringLiteral("#FBE9F1")); }
    QColor textPrimary() const { return QColor(m_dark ? QStringLiteral("#F3EEF5") : QStringLiteral("#2A2A2E")); }
    QColor textSecondary() const { return QColor(m_dark ? QStringLiteral("#B7AEBD") : QStringLiteral("#7A7480")); }
    QColor divider() const { return QColor(m_dark ? QStringLiteral("#3A3340") : QStringLiteral("#EAD9E3")); }

    QColor estadoPendiente() const { return QColor(QStringLiteral("#FFB300")); }
    QColor estadoConfirmada() const { return QColor(QStringLiteral("#2196F3")); }
    QColor estadoCompletada() const { return QColor(QStringLiteral("#4CAF50")); }
    QColor estadoCancelada() const { return QColor(QStringLiteral("#F44336")); }

    int paddingSmall() const { return 8; }
    int padding() const { return 16; }
    int paddingLarge() const { return 24; }
    int radiusSmall() const { return 8; }
    int radius() const { return 12; }
    int radiusLarge() const { return 16; }

    Q_INVOKABLE QColor colorEstado(const QString &estado) const;

signals:
    void changed();

private:
    bool m_dark = false;
};
