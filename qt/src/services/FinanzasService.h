#pragma once

#include <QDateTime>
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

// Motor de ingresos y gastos. Portado de lib/services/finanzas_service.dart y de
// las analíticas de lib/screens/finanzas/finanzas_screen.dart.
// Las analíticas reciben un periodo ("hoy" | "semana" | "mes" | "todo") y filtran
// en memoria, igual que la pantalla original (así cambiar de periodo es inmediato).
class FinanzasService : public QObject
{
    Q_OBJECT
public:
    explicit FinanzasService(QObject *parent = nullptr);

    // ===== Ingresos (CRUD) =====
    Q_INVOKABLE QVariantList obtenerIngresos() const;
    Q_INVOKABLE QVariantList obtenerIngresosPorCita(int citaId) const;
    Q_INVOKABLE int registrarIngreso(const QVariantMap &datos);
    Q_INVOKABLE bool actualizarIngreso(const QVariantMap &datos);
    Q_INVOKABLE bool eliminarIngreso(int id);
    Q_INVOKABLE bool eliminarIngresosPorCita(int citaId);

    // ===== Gastos (CRUD) =====
    Q_INVOKABLE QVariantList obtenerGastos() const;
    Q_INVOKABLE int registrarGasto(const QVariantMap &datos);
    Q_INVOKABLE bool actualizarGasto(const QVariantMap &datos);
    Q_INVOKABLE bool eliminarGasto(int id);

    // ===== Totales rápidos (panel de Inicio) =====
    Q_INVOKABLE double ingresoHoy() const;
    Q_INVOKABLE double ingresoSemana() const;
    Q_INVOKABLE double ingresoMes() const;
    Q_INVOKABLE double gastoHoy() const;
    Q_INVOKABLE double gastoSemana() const;
    Q_INVOKABLE double gastoMes() const;
    Q_INVOKABLE double balanceHoy() const;
    Q_INVOKABLE double balanceSemana() const;
    Q_INVOKABLE double balanceMes() const;

    // ===== Analíticas por periodo =====
    // KPIs del periodo: ingresos, gastos, balance, ticketPromedio, transacciones, margen.
    Q_INVOKABLE QVariantMap kpis(const QString &periodo) const;
    // Mismos KPIs para el periodo anterior (comparación); "todo" no aplica.
    Q_INVOKABLE QVariantMap kpisAnterior(const QString &periodo) const;
    // Movimientos (ingresos + gastos) del periodo, ordenados por fecha desc.
    Q_INVOKABLE QVariantList movimientos(const QString &periodo) const;
    // Gastos agrupados por categoría dentro del periodo: [{nombre, total}] desc.
    Q_INVOKABLE QVariantList gastosPorCategoria(const QString &periodo) const;
    // Ingresos por método de pago dentro del periodo: [{nombre, total}] desc.
    Q_INVOKABLE QVariantList ingresosPorMetodo(const QString &periodo) const;
    // Serie diaria de ingresos y gastos de los últimos [dias] días.
    Q_INVOKABLE QVariantList serieDiaria(int dias) const;
    // Nº de días recomendado para la tendencia (0 = periodo demasiado corto).
    Q_INVOKABLE int diasTendencia(const QString &periodo) const;
    // Top 5 por servicio / por cliente (citas completadas del periodo).
    Q_INVOKABLE QVariantList topServicios(const QString &periodo) const;
    Q_INVOKABLE QVariantList topClientes(const QString &periodo) const;

signals:
    void cambiado();

private:
    double sumaHoy(const QString &tabla) const;
    double sumaDesde(const QString &tabla, int dias) const;

    static bool enPeriodo(const QDateTime &f, const QString &periodo, const QDateTime &ahora);
    static bool enPeriodoAnterior(const QDateTime &f, const QString &periodo, const QDateTime &ahora);
    static QDateTime parseFecha(const QVariant &v);

    QVariantMap calcularKpis(const QString &periodo, bool anterior) const;
    QVariantList topPor(const QString &periodo, const QString &campo) const;
    QVariantList citasCompletadas() const;
};
