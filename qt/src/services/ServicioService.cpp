#include "services/ServicioService.h"

#include "db/Database.h"

#include <QSqlQuery>
#include <QVariant>

const QString ServicioService::kSelect = QStringLiteral(
    "SELECT id, nombre, precio, duracion_minutos AS duracionMinutos, "
    "descripcion FROM servicios ");

ServicioService::ServicioService(QObject *parent) : QObject(parent) {}

QVariantList ServicioService::obtenerTodos() const
{
    QSqlQuery q = Database::instance().exec(kSelect + QStringLiteral("ORDER BY nombre"));
    return Database::rows(q);
}

QVariantMap ServicioService::obtenerPorId(int id) const
{
    QSqlQuery q = Database::instance().exec(kSelect + QStringLiteral("WHERE id = ?"), {id});
    return Database::firstRow(q);
}

int ServicioService::crear(const QVariantMap &datos)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("INSERT INTO servicios (nombre, precio, duracion_minutos, descripcion) "
                       "VALUES (?, ?, ?, ?)"),
        {datos.value(QStringLiteral("nombre")),
         datos.value(QStringLiteral("precio")),
         datos.value(QStringLiteral("duracionMinutos")),
         datos.value(QStringLiteral("descripcion"))});
    const QVariant nuevoId = q.lastInsertId();
    if (!nuevoId.isValid())
        return -1;
    emit cambiado();
    return nuevoId.toInt();
}

bool ServicioService::actualizar(const QVariantMap &datos)
{
    if (!datos.contains(QStringLiteral("id")))
        return false;
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE servicios SET nombre = ?, precio = ?, "
                       "duracion_minutos = ?, descripcion = ? WHERE id = ?"),
        {datos.value(QStringLiteral("nombre")),
         datos.value(QStringLiteral("precio")),
         datos.value(QStringLiteral("duracionMinutos")),
         datos.value(QStringLiteral("descripcion")),
         datos.value(QStringLiteral("id"))});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool ServicioService::eliminar(int id)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("DELETE FROM servicios WHERE id = ?"), {id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

double ServicioService::precioPromedio() const
{
    QSqlQuery q = Database::instance().exec(QStringLiteral("SELECT AVG(precio) FROM servicios"));
    return q.next() ? q.value(0).toDouble() : 0.0;
}
