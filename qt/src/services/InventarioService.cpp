#include "services/InventarioService.h"

#include "db/Database.h"

#include <QDateTime>
#include <QSqlQuery>
#include <QVariant>
#include <algorithm>

const QString InventarioService::kSelect = QStringLiteral(
    "SELECT id, nombre, categoria, cantidad_stock AS cantidadStock, "
    "cantidad_minima AS cantidadMinima, costo_unitario AS costoUnitario, "
    "fecha_compra AS fechaCompra, proveedor, fecha_creacion AS fechaCreacion "
    "FROM productos ");

InventarioService::InventarioService(QObject *parent) : QObject(parent) {}

QVariantList InventarioService::obtenerTodos() const
{
    QSqlQuery q = Database::instance().exec(kSelect + QStringLiteral("ORDER BY nombre"));
    return Database::rows(q);
}

QVariantList InventarioService::ordenarPorStock() const
{
    QSqlQuery q = Database::instance().exec(
        kSelect + QStringLiteral("ORDER BY cantidad_stock ASC"));
    return Database::rows(q);
}

QVariantList InventarioService::obtenerPorCategoria(const QString &categoria) const
{
    QSqlQuery q = Database::instance().exec(
        kSelect + QStringLiteral("WHERE categoria = ? ORDER BY nombre"), {categoria});
    return Database::rows(q);
}

QVariantList InventarioService::obtenerBajoStock() const
{
    QSqlQuery q = Database::instance().exec(
        kSelect + QStringLiteral("WHERE cantidad_stock <= cantidad_minima ORDER BY cantidad_stock ASC"));
    return Database::rows(q);
}

QVariantMap InventarioService::obtenerPorId(int id) const
{
    QSqlQuery q = Database::instance().exec(kSelect + QStringLiteral("WHERE id = ?"), {id});
    return Database::firstRow(q);
}

int InventarioService::crear(const QVariantMap &datos)
{
    QString fecha = datos.value(QStringLiteral("fechaCreacion")).toString();
    if (fecha.isEmpty())
        fecha = QDateTime::currentDateTime().toString(Qt::ISODate);
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("INSERT INTO productos (nombre, categoria, cantidad_stock, "
                       "cantidad_minima, costo_unitario, fecha_compra, proveedor, fecha_creacion) "
                       "VALUES (?, ?, ?, ?, ?, ?, ?, ?)"),
        {datos.value(QStringLiteral("nombre")),
         datos.value(QStringLiteral("categoria")),
         datos.value(QStringLiteral("cantidadStock")),
         datos.value(QStringLiteral("cantidadMinima")),
         datos.value(QStringLiteral("costoUnitario")),
         datos.value(QStringLiteral("fechaCompra")),
         datos.value(QStringLiteral("proveedor")),
         fecha});
    const QVariant nuevoId = q.lastInsertId();
    if (!nuevoId.isValid())
        return -1;
    emit cambiado();
    return nuevoId.toInt();
}

bool InventarioService::actualizar(const QVariantMap &datos)
{
    if (!datos.contains(QStringLiteral("id")))
        return false;
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE productos SET nombre = ?, categoria = ?, cantidad_stock = ?, "
                       "cantidad_minima = ?, costo_unitario = ?, proveedor = ? WHERE id = ?"),
        {datos.value(QStringLiteral("nombre")),
         datos.value(QStringLiteral("categoria")),
         datos.value(QStringLiteral("cantidadStock")),
         datos.value(QStringLiteral("cantidadMinima")),
         datos.value(QStringLiteral("costoUnitario")),
         datos.value(QStringLiteral("proveedor")),
         datos.value(QStringLiteral("id"))});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool InventarioService::eliminar(int id)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("DELETE FROM productos WHERE id = ?"), {id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool InventarioService::aumentarStock(int id, int cantidad)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE productos SET cantidad_stock = cantidad_stock + ?, "
                       "fecha_compra = ? WHERE id = ?"),
        {cantidad, QDateTime::currentDateTime().toString(Qt::ISODate), id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool InventarioService::disminuirStock(int id, int cantidad)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE productos SET cantidad_stock = MAX(0, cantidad_stock - ?) "
                       "WHERE id = ?"),
        {cantidad, id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

QVariantMap InventarioService::estadisticas() const
{
    QSqlQuery q = Database::instance().exec(QStringLiteral(
        "SELECT COUNT(*), COALESCE(SUM(cantidad_stock), 0), "
        "COALESCE(SUM(cantidad_stock * costo_unitario), 0), "
        "COALESCE(SUM(CASE WHEN cantidad_stock <= cantidad_minima THEN 1 ELSE 0 END), 0) "
        "FROM productos"));
    QVariantMap out;
    if (q.next()) {
        const double valor = q.value(2).toDouble();
        out.insert(QStringLiteral("totalProductos"), q.value(0).toInt());
        out.insert(QStringLiteral("cantidadTotal"), q.value(1).toInt());
        out.insert(QStringLiteral("valorTotal"), valor);
        out.insert(QStringLiteral("costoTotal"), valor); // igual que en la app original
        out.insert(QStringLiteral("productosBajoStock"), q.value(3).toInt());
    }
    return out;
}

QVariantList InventarioService::resumenPorCategoria() const
{
    QSqlQuery q = Database::instance().exec(QStringLiteral(
        "SELECT categoria, COUNT(*) AS productos, "
        "COALESCE(SUM(cantidad_stock), 0) AS cantidad, "
        "COALESCE(SUM(cantidad_stock * costo_unitario), 0) AS costo "
        "FROM productos GROUP BY categoria ORDER BY costo DESC"));
    QVariantList out;
    while (q.next())
        out.append(QVariantMap{{QStringLiteral("nombre"), q.value(0).toString()},
                               {QStringLiteral("productos"), q.value(1).toInt()},
                               {QStringLiteral("cantidad"), q.value(2).toInt()},
                               {QStringLiteral("costo"), q.value(3).toDouble()}});
    return out;
}
