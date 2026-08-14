#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

// Catálogo de servicios. Portado de lib/services/servicio_service.dart.
class ServicioService : public QObject
{
    Q_OBJECT
public:
    explicit ServicioService(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList obtenerTodos() const;
    Q_INVOKABLE QVariantMap obtenerPorId(int id) const;
    Q_INVOKABLE int crear(const QVariantMap &datos);
    Q_INVOKABLE bool actualizar(const QVariantMap &datos);
    Q_INVOKABLE bool eliminar(int id);
    // Precio promedio del catálogo (0 si no hay servicios).
    Q_INVOKABLE double precioPromedio() const;

signals:
    void cambiado();

private:
    static const QString kSelect;
};
