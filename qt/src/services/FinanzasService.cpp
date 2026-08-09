#include "services/FinanzasService.h"

#include "db/Database.h"

#include <QDate>
#include <QSqlQuery>
#include <QVariant>
#include <algorithm>

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

bool FinanzasService::actualizarIngreso(const QVariantMap &datos)
{
    if (!datos.contains(QStringLiteral("id")))
        return false;
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE ingresos SET monto = ?, metodo_pago = ?, fecha = ?, "
                       "notas = ? WHERE id = ?"),
        {datos.value(QStringLiteral("monto")),
         datos.value(QStringLiteral("metodo")),
         datos.value(QStringLiteral("fecha")),
         datos.value(QStringLiteral("notas")),
         datos.value(QStringLiteral("id"))});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool FinanzasService::eliminarIngreso(int id)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("DELETE FROM ingresos WHERE id = ?"), {id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
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

bool FinanzasService::actualizarGasto(const QVariantMap &datos)
{
    if (!datos.contains(QStringLiteral("id")))
        return false;
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE gastos SET concepto = ?, monto = ?, categoria = ?, "
                       "fecha = ?, notas = ? WHERE id = ?"),
        {datos.value(QStringLiteral("concepto")),
         datos.value(QStringLiteral("monto")),
         datos.value(QStringLiteral("categoria")),
         datos.value(QStringLiteral("fecha")),
         datos.value(QStringLiteral("notas")),
         datos.value(QStringLiteral("id"))});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
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

// ===== Totales rápidos =====

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

// ===== Filtros de periodo (replican finanzas_screen.dart) =====

QDateTime FinanzasService::parseFecha(const QVariant &v)
{
    return QDateTime::fromString(v.toString(), Qt::ISODate);
}

bool FinanzasService::enPeriodo(const QDateTime &f, const QString &periodo,
                                const QDateTime &ahora)
{
    if (!f.isValid())
        return false;
    if (periodo == QStringLiteral("hoy"))
        return f.date() == ahora.date();
    if (periodo == QStringLiteral("semana"))
        return f > ahora.addDays(-7);
    if (periodo == QStringLiteral("mes"))
        return f > ahora.addDays(-30);
    return true; // "todo"
}

bool FinanzasService::enPeriodoAnterior(const QDateTime &f, const QString &periodo,
                                        const QDateTime &ahora)
{
    if (!f.isValid())
        return false;
    if (periodo == QStringLiteral("hoy"))
        return f.date() == ahora.date().addDays(-1);
    if (periodo == QStringLiteral("semana"))
        return f > ahora.addDays(-14) && f < ahora.addDays(-7);
    if (periodo == QStringLiteral("mes"))
        return f > ahora.addDays(-60) && f < ahora.addDays(-30);
    return false; // "todo"
}

// ===== Analíticas =====

QVariantMap FinanzasService::calcularKpis(const QString &periodo, bool anterior) const
{
    const QDateTime ahora = QDateTime::currentDateTime();
    const QVariantList ings = obtenerIngresos();
    const QVariantList gas = obtenerGastos();

    double totalIng = 0, totalGas = 0;
    int nIng = 0, nGas = 0;
    for (const QVariant &v : ings) {
        const QVariantMap m = v.toMap();
        const QDateTime f = parseFecha(m.value(QStringLiteral("fecha")));
        const bool dentro = anterior ? enPeriodoAnterior(f, periodo, ahora)
                                     : enPeriodo(f, periodo, ahora);
        if (dentro) { totalIng += m.value(QStringLiteral("monto")).toDouble(); ++nIng; }
    }
    for (const QVariant &v : gas) {
        const QVariantMap m = v.toMap();
        const QDateTime f = parseFecha(m.value(QStringLiteral("fecha")));
        const bool dentro = anterior ? enPeriodoAnterior(f, periodo, ahora)
                                     : enPeriodo(f, periodo, ahora);
        if (dentro) { totalGas += m.value(QStringLiteral("monto")).toDouble(); ++nGas; }
    }

    const double balance = totalIng - totalGas;
    const double ticket = nIng == 0 ? 0.0 : totalIng / nIng;
    const double margen = totalIng > 0 ? (balance / totalIng * 100.0) : 0.0;

    QVariantMap out;
    out.insert(QStringLiteral("ingresos"), totalIng);
    out.insert(QStringLiteral("gastos"), totalGas);
    out.insert(QStringLiteral("balance"), balance);
    out.insert(QStringLiteral("ticketPromedio"), ticket);
    out.insert(QStringLiteral("transacciones"), nIng + nGas);
    out.insert(QStringLiteral("margen"), margen);
    return out;
}

QVariantMap FinanzasService::kpis(const QString &periodo) const
{
    return calcularKpis(periodo, false);
}

QVariantMap FinanzasService::kpisAnterior(const QString &periodo) const
{
    return calcularKpis(periodo, true);
}

QVariantList FinanzasService::movimientos(const QString &periodo) const
{
    const QDateTime ahora = QDateTime::currentDateTime();
    QVariantList lista;

    for (const QVariant &v : obtenerIngresos()) {
        const QVariantMap m = v.toMap();
        const QDateTime f = parseFecha(m.value(QStringLiteral("fecha")));
        if (!enPeriodo(f, periodo, ahora))
            continue;
        const bool porCita = !m.value(QStringLiteral("citaId")).isNull() &&
                             m.value(QStringLiteral("citaId")).toInt() > 0;
        const QString metodo = m.value(QStringLiteral("metodo")).toString();
        QVariantMap mov = m;
        mov.insert(QStringLiteral("tipo"), QStringLiteral("ingreso"));
        mov.insert(QStringLiteral("esIngreso"), true);
        mov.insert(QStringLiteral("etiqueta"),
                   (porCita ? QStringLiteral("Ingreso por cita · ")
                            : QStringLiteral("Ingreso · ")) + metodo);
        mov.insert(QStringLiteral("editable"), !porCita);
        lista.append(mov);
    }
    for (const QVariant &v : obtenerGastos()) {
        const QVariantMap m = v.toMap();
        const QDateTime f = parseFecha(m.value(QStringLiteral("fecha")));
        if (!enPeriodo(f, periodo, ahora))
            continue;
        QVariantMap mov = m;
        mov.insert(QStringLiteral("tipo"), QStringLiteral("gasto"));
        mov.insert(QStringLiteral("esIngreso"), false);
        mov.insert(QStringLiteral("etiqueta"),
                   m.value(QStringLiteral("concepto")).toString() + QStringLiteral(" · ") +
                       m.value(QStringLiteral("categoria")).toString());
        mov.insert(QStringLiteral("editable"), true);
        lista.append(mov);
    }

    std::sort(lista.begin(), lista.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("fecha")).toString() >
               b.toMap().value(QStringLiteral("fecha")).toString();
    });
    return lista;
}

QVariantList FinanzasService::gastosPorCategoria(const QString &periodo) const
{
    const QDateTime ahora = QDateTime::currentDateTime();
    QMap<QString, double> mapa;
    for (const QVariant &v : obtenerGastos()) {
        const QVariantMap m = v.toMap();
        if (!enPeriodo(parseFecha(m.value(QStringLiteral("fecha"))), periodo, ahora))
            continue;
        mapa[m.value(QStringLiteral("categoria")).toString()] +=
            m.value(QStringLiteral("monto")).toDouble();
    }
    QVariantList out;
    for (auto it = mapa.constBegin(); it != mapa.constEnd(); ++it)
        out.append(QVariantMap{{QStringLiteral("nombre"), it.key()},
                               {QStringLiteral("total"), it.value()}});
    std::sort(out.begin(), out.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("total")).toDouble() >
               b.toMap().value(QStringLiteral("total")).toDouble();
    });
    return out;
}

QVariantList FinanzasService::ingresosPorMetodo(const QString &periodo) const
{
    const QDateTime ahora = QDateTime::currentDateTime();
    QMap<QString, double> mapa;
    for (const QVariant &v : obtenerIngresos()) {
        const QVariantMap m = v.toMap();
        if (!enPeriodo(parseFecha(m.value(QStringLiteral("fecha"))), periodo, ahora))
            continue;
        mapa[m.value(QStringLiteral("metodo")).toString()] +=
            m.value(QStringLiteral("monto")).toDouble();
    }
    QVariantList out;
    for (auto it = mapa.constBegin(); it != mapa.constEnd(); ++it)
        out.append(QVariantMap{{QStringLiteral("nombre"), it.key()},
                               {QStringLiteral("total"), it.value()}});
    std::sort(out.begin(), out.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("total")).toDouble() >
               b.toMap().value(QStringLiteral("total")).toDouble();
    });
    return out;
}

int FinanzasService::diasTendencia(const QString &periodo) const
{
    if (periodo == QStringLiteral("hoy"))
        return 0;
    if (periodo == QStringLiteral("semana"))
        return 7;
    return 30; // mes / todo
}

QVariantList FinanzasService::serieDiaria(int dias) const
{
    if (dias <= 0)
        return {};
    const QDate hoy = QDate::currentDate();
    const QDate inicio = hoy.addDays(-(dias - 1));

    // Acumula por día (clave: yyyy-MM-dd).
    QMap<QString, double> ingPorDia, gasPorDia;
    for (const QVariant &v : obtenerIngresos()) {
        const QVariantMap m = v.toMap();
        const QDateTime f = parseFecha(m.value(QStringLiteral("fecha")));
        if (f.isValid())
            ingPorDia[f.date().toString(QStringLiteral("yyyy-MM-dd"))] +=
                m.value(QStringLiteral("monto")).toDouble();
    }
    for (const QVariant &v : obtenerGastos()) {
        const QVariantMap m = v.toMap();
        const QDateTime f = parseFecha(m.value(QStringLiteral("fecha")));
        if (f.isValid())
            gasPorDia[f.date().toString(QStringLiteral("yyyy-MM-dd"))] +=
                m.value(QStringLiteral("monto")).toDouble();
    }

    QVariantList out;
    for (int i = 0; i < dias; ++i) {
        const QDate d = inicio.addDays(i);
        const QString clave = d.toString(QStringLiteral("yyyy-MM-dd"));
        out.append(QVariantMap{
            {QStringLiteral("fecha"), clave},
            {QStringLiteral("etiqueta"), d.toString(QStringLiteral("d/M"))},
            {QStringLiteral("ingresos"), ingPorDia.value(clave, 0.0)},
            {QStringLiteral("gastos"), gasPorDia.value(clave, 0.0)}});
    }
    return out;
}

QVariantList FinanzasService::citasCompletadas() const
{
    QSqlQuery q = Database::instance().exec(QStringLiteral(
        "SELECT c.monto, c.fecha_hora AS fechaHora, "
        "cl.nombre AS nombreCliente, s.nombre AS nombreServicio "
        "FROM citas c "
        "LEFT JOIN clientes cl ON c.cliente_id = cl.id "
        "LEFT JOIN servicios s ON c.servicio_id = s.id "
        "WHERE c.estado = 'completada'"));
    return Database::rows(q);
}

QVariantList FinanzasService::topPor(const QString &periodo, const QString &campo) const
{
    const QDateTime ahora = QDateTime::currentDateTime();
    const QString porDefecto = campo == QStringLiteral("nombreServicio")
                                   ? QStringLiteral("Servicio")
                                   : QStringLiteral("Cliente");
    QMap<QString, QPair<double, int>> mapa; // nombre -> (total, veces)
    for (const QVariant &v : citasCompletadas()) {
        const QVariantMap m = v.toMap();
        if (!enPeriodo(parseFecha(m.value(QStringLiteral("fechaHora"))), periodo, ahora))
            continue;
        QString clave = m.value(campo).toString();
        if (clave.isEmpty())
            clave = porDefecto;
        auto &par = mapa[clave];
        par.first += m.value(QStringLiteral("monto")).toDouble();
        par.second += 1;
    }
    QVariantList out;
    for (auto it = mapa.constBegin(); it != mapa.constEnd(); ++it)
        out.append(QVariantMap{{QStringLiteral("nombre"), it.key()},
                               {QStringLiteral("total"), it.value().first},
                               {QStringLiteral("veces"), it.value().second}});
    std::sort(out.begin(), out.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("total")).toDouble() >
               b.toMap().value(QStringLiteral("total")).toDouble();
    });
    if (out.size() > 5)
        out = out.mid(0, 5);
    return out;
}

QVariantList FinanzasService::topServicios(const QString &periodo) const
{
    return topPor(periodo, QStringLiteral("nombreServicio"));
}

QVariantList FinanzasService::topClientes(const QString &periodo) const
{
    return topPor(periodo, QStringLiteral("nombreCliente"));
}
