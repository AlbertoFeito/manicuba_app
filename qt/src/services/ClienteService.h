#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

// Lógica de negocio de clientes. Portado de lib/services/cliente_service.dart.
// Los datos viajan a QML como mapas con claves camelCase.
class ClienteService : public QObject
{
    Q_OBJECT
public:
    explicit ClienteService(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList obtenerTodos() const;
    Q_INVOKABLE QVariantMap obtenerPorId(int id) const;
    Q_INVOKABLE QVariantList buscarPorNombre(const QString &nombre) const;
    Q_INVOKABLE int total() const;

    // Crea un cliente (marca fecha_creacion). Devuelve el id nuevo (-1 si falla).
    Q_INVOKABLE int crear(const QVariantMap &datos);
    Q_INVOKABLE bool actualizar(const QVariantMap &datos);
    Q_INVOKABLE bool eliminar(int id);

    // Fija la última visita del cliente a la fecha dada (ISO-8601).
    bool marcarUltimaVisita(int id, const QString &fechaIso);

signals:
    void cambiado();

private:
    static const QString kSelect;
};
