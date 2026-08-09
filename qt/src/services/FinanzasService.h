#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

// Motor de ingresos y gastos. Portado de lib/services/finanzas_service.dart.
// En esta entrega se implementa el núcleo de ingresos (necesario para la
// sincronización cita→ingreso) y los totales del panel de Inicio.
class FinanzasService : public QObject
{
    Q_OBJECT
public:
    explicit FinanzasService(QObject *parent = nullptr);

    // ===== Ingresos =====
    Q_INVOKABLE QVariantList obtenerIngresos() const;
    Q_INVOKABLE QVariantList obtenerIngresosPorCita(int citaId) const;
    Q_INVOKABLE int registrarIngreso(const QVariantMap &datos);
    Q_INVOKABLE bool eliminarIngresosPorCita(int citaId);

    // ===== Gastos =====
    Q_INVOKABLE QVariantList obtenerGastos() const;
    Q_INVOKABLE int registrarGasto(const QVariantMap &datos);
    Q_INVOKABLE bool eliminarGasto(int id);

    // ===== Analíticas (para el panel de Inicio) =====
    Q_INVOKABLE double ingresoHoy() const;
    Q_INVOKABLE double ingresoSemana() const;
    Q_INVOKABLE double ingresoMes() const;
    Q_INVOKABLE double gastoHoy() const;
    Q_INVOKABLE double gastoSemana() const;
    Q_INVOKABLE double gastoMes() const;
    Q_INVOKABLE double balanceHoy() const;
    Q_INVOKABLE double balanceSemana() const;
    Q_INVOKABLE double balanceMes() const;

signals:
    void cambiado();

private:
    double sumaHoy(const QString &tabla) const;
    double sumaDesde(const QString &tabla, int dias) const;
};
