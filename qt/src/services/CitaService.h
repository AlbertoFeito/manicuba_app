#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class FinanzasService;
class ClienteService;

// Lógica de negocio de citas. Portado de lib/services/cita_service.dart.
// Contiene la regla clave `sincronizarIngreso`: al completar una cita con
// monto se crea/actualiza un ingreso enlazado y se marca la última visita del
// cliente; al descompletarla o borrarla, el ingreso se elimina.
class CitaService : public QObject
{
    Q_OBJECT
public:
    CitaService(FinanzasService *finanzas, ClienteService *clientes,
                QObject *parent = nullptr);

    Q_INVOKABLE QVariantList obtenerTodas() const;
    Q_INVOKABLE QVariantList obtenerPorFecha(const QString &fechaIso) const;
    Q_INVOKABLE QVariantList obtenerPorCliente(int clienteId) const;
    // Citas activas (pendiente/confirmada) de un día, para la agenda.
    Q_INVOKABLE QVariantList activasPorFecha(const QString &fechaIso) const;
    // Citas históricas (completadas/canceladas), para el historial.
    Q_INVOKABLE QVariantList historial() const;

    Q_INVOKABLE int crear(const QVariantMap &datos);
    Q_INVOKABLE bool actualizar(const QVariantMap &datos);
    Q_INVOKABLE bool eliminar(int id);
    Q_INVOKABLE bool cambiarEstado(int id, const QString &estado);

    Q_INVOKABLE int totalHoy() const;
    Q_INVOKABLE double ingresosHoy() const;
    // ¿Hay hueco para una cita en esa fecha/hora? (choque con confirmadas)
    Q_INVOKABLE bool estaDisponible(const QString &fechaHoraIso, int duracionMinutos) const;

signals:
    void cambiado();

private:
    void sincronizarIngreso(int id, int clienteId, const QString &estado,
                            const QVariant &monto, const QString &fechaHora);

    FinanzasService *m_finanzas;
    ClienteService *m_clientes;
    static const QString kSelect;
};
