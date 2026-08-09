#include "services/FinanzasService.h"

#include "db/Database.h"

#include <QDate>
#include <QDateTime>
#include <QSqlQuery>
#include <QVariant>

FinanzasService::FinanzasService(QObject *parent) : QObject(parent) {}

// ===== Ingresos =====

QVariantList FinanzasService::obtenerIngresos() const
{
    QSqlQuery q = Database::instance().exec(QStringLiteral(
        "SELECT id, cita_id AS citaId, monto, metodo_pago AS metodo, fecha, notas "
        "FROM ingresos ORDER BY fecha DESC"));
    return Database::rows(q);
}

QVariantList FinanzasService::obtenerIngresosPorCita(int citaId) const
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("SELECT id, cita_id AS citaId, monto, metodo_pago AS metodo, "
                       "fecha, notas FROM ingresos WHERE cita_id = ?"),
        {citaId});
    return Database::rows(q);
}

int FinanzasService::registrarIngreso(const QVariantMap &datos)
{
    QString fecha = datos.value(QStringLiteral("fecha")).toString();
    if (fecha.isEmpty())
        fecha = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlQuery q = Database::instance().exec(
        QStringLiteral("INSERT INTO ingresos (cita_id, monto, metodo_pago, fecha, notas) "
                       "VALUES (?, ?, ?, ?, ?)"),
        {datos.value(QStringLiteral("citaId")),
         datos.value(QStringLiteral("monto")),
         datos.value(QStringLiteral("metodo")),
         fecha,
         datos.value(QStringLiteral("notas"))});
    const QVariant nuevoId = q.lastInsertId();
    if (!nuevoId.isValid())
        return -1;
    emit cambiado();
    return nuevoId.toInt();
}

bool FinanzasService::eliminarIngresosPorCita(int citaId)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("DELETE FROM ingresos WHERE cita_id = ?"), {citaId});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

// ===== Gastos =====

QVariantList FinanzasService::obtenerGastos() const
{
    QSqlQuery q = Database::instance().exec(QStringLiteral(
        "SELECT id, concepto, monto, categoria, fecha, notas FROM gastos ORDER BY fecha DESC"));
    return Database::rows(q);
}

int FinanzasService::registrarGasto(const QVariantMap &datos)
{
    QString fecha = datos.value(QStringLiteral("fecha")).toString();
    if (fecha.isEmpty())
        fecha = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlQuery q = Database::instance().exec(
        QStringLiteral("INSERT INTO gastos (concepto, monto, categoria, fecha, notas) "
                       "VALUES (?, ?, ?, ?, ?)"),
        {datos.value(QStringLiteral("concepto")),
         datos.value(QStringLiteral("monto")),
         datos.value(QStringLiteral("categoria")),
         fecha,
         datos.value(QStringLiteral("notas"))});
    const QVariant nuevoId = q.lastInsertId();
    if (!nuevoId.isValid())
        return -1;
    emit cambiado();
    return nuevoId.toInt();
}

bool FinanzasService::eliminarGasto(int id)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("DELETE FROM gastos WHERE id = ?"), {id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

// ===== Analíticas =====

double FinanzasService::sumaHoy(const QString &tabla) const
{
    const QString hoy = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("SELECT COALESCE(SUM(monto), 0) FROM ") + tabla +
            QStringLiteral(" WHERE DATE(fecha) = ?"),
        {hoy});
    return q.next() ? q.value(0).toDouble() : 0.0;
}

double FinanzasService::sumaDesde(const QString &tabla, int dias) const
{
    const QString corte =
        QDateTime::currentDateTime().addDays(-dias).toString(Qt::ISODate);
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("SELECT COALESCE(SUM(monto), 0) FROM ") + tabla +
            QStringLiteral(" WHERE fecha >= ?"),
        {corte});
    return q.next() ? q.value(0).toDouble() : 0.0;
}

double FinanzasService::ingresoHoy() const { return sumaHoy(QStringLiteral("ingresos")); }
double FinanzasService::ingresoSemana() const { return sumaDesde(QStringLiteral("ingresos"), 7); }
double FinanzasService::ingresoMes() const { return sumaDesde(QStringLiteral("ingresos"), 30); }
double FinanzasService::gastoHoy() const { return sumaHoy(QStringLiteral("gastos")); }
double FinanzasService::gastoSemana() const { return sumaDesde(QStringLiteral("gastos"), 7); }
double FinanzasService::gastoMes() const { return sumaDesde(QStringLiteral("gastos"), 30); }
double FinanzasService::balanceHoy() const { return ingresoHoy() - gastoHoy(); }
double FinanzasService::balanceSemana() const { return ingresoSemana() - gastoSemana(); }
double FinanzasService::balanceMes() const { return ingresoMes() - gastoMes(); }
