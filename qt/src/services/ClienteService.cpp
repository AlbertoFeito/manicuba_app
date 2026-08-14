#include "services/ClienteService.h"

#include "db/Database.h"

#include <QDateTime>
#include <QSqlQuery>
#include <QVariant>

const QString ClienteService::kSelect = QStringLiteral(
    "SELECT id, nombre, telefono, email, direccion, notas, "
    "fecha_creacion AS fechaCreacion, ultima_visita AS ultimaVisita FROM clientes ");

ClienteService::ClienteService(QObject *parent) : QObject(parent) {}

QVariantList ClienteService::obtenerTodos() const
{
    QSqlQuery q = Database::instance().exec(kSelect + QStringLiteral("ORDER BY nombre"));
    return Database::rows(q);
}

QVariantMap ClienteService::obtenerPorId(int id) const
{
    QSqlQuery q = Database::instance().exec(kSelect + QStringLiteral("WHERE id = ?"), {id});
    return Database::firstRow(q);
}

QVariantList ClienteService::buscarPorNombre(const QString &nombre) const
{
    QSqlQuery q = Database::instance().exec(
        kSelect + QStringLiteral("WHERE lower(nombre) LIKE ? ORDER BY nombre"),
        {QStringLiteral("%") + nombre.toLower() + QStringLiteral("%")});
    return Database::rows(q);
}

int ClienteService::total() const
{
    QSqlQuery q = Database::instance().exec(QStringLiteral("SELECT COUNT(*) FROM clientes"));
    return q.next() ? q.value(0).toInt() : 0;
}

int ClienteService::crear(const QVariantMap &datos)
{
    QString fecha = datos.value(QStringLiteral("fechaCreacion")).toString();
    if (fecha.isEmpty())
        fecha = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlQuery q = Database::instance().exec(
        QStringLiteral("INSERT INTO clientes (nombre, telefono, email, direccion, notas, "
                       "fecha_creacion, ultima_visita) VALUES (?, ?, ?, ?, ?, ?, ?)"),
        {datos.value(QStringLiteral("nombre")),
         datos.value(QStringLiteral("telefono")),
         datos.value(QStringLiteral("email")),
         datos.value(QStringLiteral("direccion")),
         datos.value(QStringLiteral("notas")),
         fecha,
         datos.value(QStringLiteral("ultimaVisita"))});

    const QVariant nuevoId = q.lastInsertId();
    if (!nuevoId.isValid())
        return -1;
    emit cambiado();
    return nuevoId.toInt();
}

bool ClienteService::actualizar(const QVariantMap &datos)
{
    if (!datos.contains(QStringLiteral("id")))
        return false;
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE clientes SET nombre = ?, telefono = ?, email = ?, "
                       "direccion = ?, notas = ?, ultima_visita = ? WHERE id = ?"),
        {datos.value(QStringLiteral("nombre")),
         datos.value(QStringLiteral("telefono")),
         datos.value(QStringLiteral("email")),
         datos.value(QStringLiteral("direccion")),
         datos.value(QStringLiteral("notas")),
         datos.value(QStringLiteral("ultimaVisita")),
         datos.value(QStringLiteral("id"))});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool ClienteService::eliminar(int id)
{
    // No se borra un cliente con citas completadas: se perdería su historial.
    QSqlQuery check = Database::instance().exec(
        QStringLiteral("SELECT COUNT(*) FROM citas WHERE cliente_id = ? AND estado = 'completada'"),
        {id});
    if (check.next() && check.value(0).toInt() > 0)
        return false;

    QSqlQuery q = Database::instance().exec(
        QStringLiteral("DELETE FROM clientes WHERE id = ?"), {id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool ClienteService::marcarUltimaVisita(int id, const QString &fechaIso)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE clientes SET ultima_visita = ? WHERE id = ?"),
        {fechaIso, id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}
