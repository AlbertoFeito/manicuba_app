#include "services/CitaService.h"

#include "db/Database.h"
#include "services/ClienteService.h"
#include "services/FinanzasService.h"

#include <QDate>
#include <QDateTime>
#include <QSqlQuery>
#include <QVariant>

const QString CitaService::kSelect = QStringLiteral(
    "SELECT c.id, c.cliente_id AS clienteId, c.servicio_id AS servicioId, "
    "c.fecha_hora AS fechaHora, c.duracion_minutos AS duracionMinutos, "
    "c.estado, c.monto, c.notas, c.fecha_creacion AS fechaCreacion, "
    "cl.nombre AS nombreCliente, s.nombre AS nombreServicio "
    "FROM citas c "
    "LEFT JOIN clientes cl ON c.cliente_id = cl.id "
    "LEFT JOIN servicios s ON c.servicio_id = s.id ");

CitaService::CitaService(FinanzasService *finanzas, ClienteService *clientes,
                         QObject *parent)
    : QObject(parent), m_finanzas(finanzas), m_clientes(clientes)
{
}

QVariantList CitaService::obtenerTodas() const
{
    QSqlQuery q = Database::instance().exec(kSelect + QStringLiteral("ORDER BY c.fecha_hora DESC"));
    return Database::rows(q);
}

QVariantList CitaService::obtenerPorFecha(const QString &fechaIso) const
{
    const QString dia = fechaIso.left(10); // yyyy-MM-dd
    QSqlQuery q = Database::instance().exec(
        kSelect + QStringLiteral("WHERE DATE(c.fecha_hora) = ? ORDER BY c.fecha_hora"),
        {dia});
    return Database::rows(q);
}

QVariantList CitaService::obtenerPorCliente(int clienteId) const
{
    QSqlQuery q = Database::instance().exec(
        kSelect + QStringLiteral("WHERE c.cliente_id = ? ORDER BY c.fecha_hora DESC"),
        {clienteId});
    return Database::rows(q);
}

QVariantList CitaService::activasPorFecha(const QString &fechaIso) const
{
    const QString dia = fechaIso.left(10);
    QSqlQuery q = Database::instance().exec(
        kSelect + QStringLiteral("WHERE DATE(c.fecha_hora) = ? AND c.estado IN "
                                 "('pendiente','confirmada') ORDER BY c.fecha_hora"),
        {dia});
    return Database::rows(q);
}

QVariantList CitaService::historial() const
{
    QSqlQuery q = Database::instance().exec(
        kSelect + QStringLiteral("WHERE c.estado IN ('completada','cancelada') "
                                 "ORDER BY c.fecha_hora DESC"));
    return Database::rows(q);
}

int CitaService::crear(const QVariantMap &datos)
{
    QString fechaCreacion = datos.value(QStringLiteral("fechaCreacion")).toString();
    if (fechaCreacion.isEmpty())
        fechaCreacion = QDateTime::currentDateTime().toString(Qt::ISODate);
    const QString estado = datos.value(QStringLiteral("estado"),
                                       QStringLiteral("pendiente")).toString();

    QSqlQuery q = Database::instance().exec(
        QStringLiteral("INSERT INTO citas (cliente_id, servicio_id, fecha_hora, "
                       "duracion_minutos, estado, monto, notas, fecha_creacion) "
                       "VALUES (?, ?, ?, ?, ?, ?, ?, ?)"),
        {datos.value(QStringLiteral("clienteId")),
         datos.value(QStringLiteral("servicioId")),
         datos.value(QStringLiteral("fechaHora")),
         datos.value(QStringLiteral("duracionMinutos")),
         estado,
         datos.value(QStringLiteral("monto")),
         datos.value(QStringLiteral("notas")),
         fechaCreacion});

    const QVariant nuevoId = q.lastInsertId();
    if (!nuevoId.isValid())
        return -1;
    const int id = nuevoId.toInt();
    sincronizarIngreso(id, datos.value(QStringLiteral("clienteId")).toInt(), estado,
                       datos.value(QStringLiteral("monto")),
                       datos.value(QStringLiteral("fechaHora")).toString());
    emit cambiado();
    return id;
}

bool CitaService::actualizar(const QVariantMap &datos)
{
    if (!datos.contains(QStringLiteral("id")))
        return false;
    const int id = datos.value(QStringLiteral("id")).toInt();
    const QString estado = datos.value(QStringLiteral("estado"),
                                       QStringLiteral("pendiente")).toString();

    Database::instance().exec(
        QStringLiteral("UPDATE citas SET cliente_id = ?, servicio_id = ?, fecha_hora = ?, "
                       "duracion_minutos = ?, estado = ?, monto = ?, notas = ? WHERE id = ?"),
        {datos.value(QStringLiteral("clienteId")),
         datos.value(QStringLiteral("servicioId")),
         datos.value(QStringLiteral("fechaHora")),
         datos.value(QStringLiteral("duracionMinutos")),
         estado,
         datos.value(QStringLiteral("monto")),
         datos.value(QStringLiteral("notas")),
         id});

    sincronizarIngreso(id, datos.value(QStringLiteral("clienteId")).toInt(), estado,
                       datos.value(QStringLiteral("monto")),
                       datos.value(QStringLiteral("fechaHora")).toString());
    emit cambiado();
    return true;
}

bool CitaService::eliminar(int id)
{
    // Una cita completada ya generó su ingreso: borrarla se llevaría el
    // historial de facturación por delante. Se protege aquí, no solo en la UI.
    QSqlQuery info = Database::instance().exec(
        QStringLiteral("SELECT estado FROM citas WHERE id = ?"), {id});
    if (info.next() && info.value(0).toString() == QStringLiteral("completada"))
        return false;

    // Elimina también el ingreso asociado, si lo hubiera.
    m_finanzas->eliminarIngresosPorCita(id);
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("DELETE FROM citas WHERE id = ?"), {id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool CitaService::cambiarEstado(int id, const QString &estado)
{
    QSqlQuery info = Database::instance().exec(
        QStringLiteral("SELECT cliente_id, monto, fecha_hora FROM citas WHERE id = ?"),
        {id});
    if (!info.next())
        return false;
    const int clienteId = info.value(0).toInt();
    const QVariant monto = info.value(1);
    const QString fechaHora = info.value(2).toString();

    Database::instance().exec(
        QStringLiteral("UPDATE citas SET estado = ? WHERE id = ?"), {estado, id});
    sincronizarIngreso(id, clienteId, estado, monto, fechaHora);
    emit cambiado();
    return true;
}

// Mantiene el ingreso en sincronía con el estado de la cita. Idempotente.
void CitaService::sincronizarIngreso(int id, int clienteId, const QString &estado,
                                     const QVariant &monto, const QString &fechaHora)
{
    if (id <= 0)
        return;
    const QVariantList existentes = m_finanzas->obtenerIngresosPorCita(id);
    const double montoVal = monto.toDouble();
    const bool debeTenerIngreso =
        estado == QStringLiteral("completada") && montoVal > 0;

    // Al completar, registra la visita en la ficha del cliente.
    if (estado == QStringLiteral("completada"))
        m_clientes->marcarUltimaVisita(clienteId, fechaHora);

    if (!debeTenerIngreso) {
        if (!existentes.isEmpty())
            m_finanzas->eliminarIngresosPorCita(id);
        return;
    }

    // Debe existir un único ingreso que refleje el monto y la fecha actuales.
    bool yaCorrecto = false;
    if (existentes.size() == 1) {
        const QVariantMap ing = existentes.first().toMap();
        yaCorrecto = ing.value(QStringLiteral("monto")).toDouble() == montoVal &&
                     ing.value(QStringLiteral("fecha")).toString() == fechaHora;
    }
    if (yaCorrecto)
        return;

    if (!existentes.isEmpty())
        m_finanzas->eliminarIngresosPorCita(id);

    QVariantMap nuevo;
    nuevo.insert(QStringLiteral("citaId"), id);
    nuevo.insert(QStringLiteral("monto"), montoVal);
    nuevo.insert(QStringLiteral("metodo"), QStringLiteral("Efectivo")); // metodosPago.first
    nuevo.insert(QStringLiteral("fecha"), fechaHora);
    nuevo.insert(QStringLiteral("notas"),
                 QStringLiteral("Generado automáticamente por cita completada"));
    m_finanzas->registrarIngreso(nuevo);
}

int CitaService::totalHoy() const
{
    const QString hoy = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("SELECT COUNT(*) FROM citas WHERE DATE(fecha_hora) = ?"), {hoy});
    return q.next() ? q.value(0).toInt() : 0;
}

double CitaService::ingresosHoy() const
{
    const QString hoy = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("SELECT COALESCE(SUM(monto), 0) FROM citas "
                       "WHERE estado = 'completada' AND DATE(fecha_hora) = ?"),
        {hoy});
    return q.next() ? q.value(0).toDouble() : 0.0;
}

bool CitaService::estaDisponible(const QString &fechaHoraIso, int duracionMinutos) const
{
    const QDateTime inicioNuevo = QDateTime::fromString(fechaHoraIso, Qt::ISODate);
    if (!inicioNuevo.isValid())
        return true;
    const QDateTime finNuevo = inicioNuevo.addSecs(duracionMinutos * 60);

    const QString dia = fechaHoraIso.left(10);
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("SELECT fecha_hora, duracion_minutos FROM citas "
                       "WHERE DATE(fecha_hora) = ? AND estado = 'confirmada'"),
        {dia});
    while (q.next()) {
        const QDateTime inicio = QDateTime::fromString(q.value(0).toString(), Qt::ISODate);
        const QDateTime fin = inicio.addSecs(q.value(1).toInt() * 60);
        if (inicioNuevo < fin && finNuevo > inicio)
            return false;
    }
    return true;
}
