#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantMap>

// Constantes globales de la app, expuestas a QML.
// Portado de lib/config/constants.dart (AppConstants).
class AppConfig : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString appName READ appName CONSTANT)
    Q_PROPERTY(QString appVersion READ appVersion CONSTANT)
    Q_PROPERTY(QString appAuthor READ appAuthor CONSTANT)
    Q_PROPERTY(QStringList categoriasGastos READ categoriasGastos CONSTANT)
    Q_PROPERTY(QStringList categoriasProductos READ categoriasProductos CONSTANT)
    Q_PROPERTY(QStringList metodosPago READ metodosPago CONSTANT)
    Q_PROPERTY(QStringList tiposPost READ tiposPost CONSTANT)
    Q_PROPERTY(QStringList plataformasSociales READ plataformasSociales CONSTANT)
    Q_PROPERTY(QStringList emojisPopulares READ emojisPopulares CONSTANT)
    Q_PROPERTY(QStringList hashtagsComunes READ hashtagsComunes CONSTANT)
    Q_PROPERTY(int duracionCitaDefault READ duracionCitaDefault CONSTANT)
    Q_PROPERTY(int maxLongitudNombre READ maxLongitudNombre CONSTANT)
    Q_PROPERTY(int maxLongitudTelefono READ maxLongitudTelefono CONSTANT)
    Q_PROPERTY(int maxLongitudNotas READ maxLongitudNotas CONSTANT)

public:
    explicit AppConfig(QObject *parent = nullptr);

    QString appName() const { return QStringLiteral("ManiCuba"); }
    QString appVersion() const { return QStringLiteral("1.0.0"); }
    QString appAuthor() const { return QStringLiteral("Alberto Feito"); }

    QStringList categoriasGastos() const;
    QStringList categoriasProductos() const;
    QStringList metodosPago() const;
    QStringList tiposPost() const;
    QStringList plataformasSociales() const;
    QStringList emojisPopulares() const;
    QStringList hashtagsComunes() const;

    int duracionCitaDefault() const { return 30; }
    int maxLongitudNombre() const { return 100; }
    int maxLongitudTelefono() const { return 20; }
    int maxLongitudNotas() const { return 500; }

    // Formatea un importe como moneda (p. ej. "$12.50").
    Q_INVOKABLE QString moneda(double valor) const;
    // Etiqueta legible del estado de una cita.
    Q_INVOKABLE QString etiquetaEstado(const QString &estado) const;
};
