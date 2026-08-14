#include "services/InventarioService.h"

#include "db/Database.h"
#include "services/FinanzasService.h"

#include <QDateTime>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QVariant>
#include <algorithm>
#include <cmath>

namespace {
const QString kCategoriaGastoProductos = QStringLiteral("Productos");
const QString kNotaAutomatica = QStringLiteral("Generado automáticamente desde Inventario");
const QString kMotivoCompra = QStringLiteral("compra");
const QString kMotivoSaldoInicial = QStringLiteral("saldo_inicial");
const QString kMotivoCorreccion = QStringLiteral("correccion");
const QString kTipoEntrada = QStringLiteral("entrada");
const QString kTipoSalida = QStringLiteral("salida");
const QString kTipoAjuste = QStringLiteral("ajuste");
}

const QString InventarioService::kSelect = QStringLiteral(
    "SELECT id, nombre, categoria, cantidad_stock AS cantidadStock, "
    "cantidad_minima AS cantidadMinima, costo_unitario AS costoUnitario, "
    "fecha_compra AS fechaCompra, proveedor, fecha_creacion AS fechaCreacion "
    "FROM productos ");

const QString InventarioService::kSelectMov = QStringLiteral(
    "SELECT id, producto_id AS productoId, tipo, cantidad, "
    "costo_unitario AS costoUnitario, motivo, gasto_id AS gastoId, fecha, notas "
    "FROM movimientos_inventario ");

InventarioService::InventarioService(FinanzasService *finanzas, QObject *parent)
    : QObject(parent), m_finanzas(finanzas)
{
}

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

QVariantMap InventarioService::buscarPorNombreYCategoria(const QString &nombre,
                                                          const QString &categoria,
                                                          int exceptoId) const
{
    const QString buscadoNombre = nombre.trimmed().toLower();
    const QString buscadaCategoria = categoria.trimmed().toLower();
    for (const QVariant &v : obtenerTodos()) {
        const QVariantMap m = v.toMap();
        if (exceptoId >= 0 && m.value(QStringLiteral("id")).toInt() == exceptoId)
            continue;
        if (m.value(QStringLiteral("nombre")).toString().trimmed().toLower() == buscadoNombre &&
            m.value(QStringLiteral("categoria")).toString().trimmed().toLower() == buscadaCategoria)
            return m;
    }
    return {};
}

int InventarioService::crear(const QVariantMap &datos, bool registrarGasto)
{
    QString fecha = datos.value(QStringLiteral("fechaCreacion")).toString();
    if (fecha.isEmpty())
        fecha = QDateTime::currentDateTime().toString(Qt::ISODate);

    const int cantidadInicial = datos.value(QStringLiteral("cantidadStock")).toInt();
    const double costo = datos.value(QStringLiteral("costoUnitario")).toDouble();
    const QString nombre = datos.value(QStringLiteral("nombre")).toString();

    QSqlDatabase &db = Database::instance().db();
    db.transaction();

    QSqlQuery ins = Database::instance().exec(
        QStringLiteral("INSERT INTO productos (nombre, categoria, cantidad_stock, "
                       "cantidad_minima, costo_unitario, fecha_compra, proveedor, fecha_creacion) "
                       "VALUES (?, ?, ?, ?, ?, ?, ?, ?)"),
        {nombre,
         datos.value(QStringLiteral("categoria")),
         cantidadInicial,
         datos.value(QStringLiteral("cantidadMinima")),
         costo,
         datos.value(QStringLiteral("fechaCompra")),
         datos.value(QStringLiteral("proveedor")),
         fecha});
    const QVariant nuevoId = ins.lastInsertId();
    if (!nuevoId.isValid()) {
        db.rollback();
        return -1;
    }
    const int productoId = nuevoId.toInt();

    if (cantidadInicial > 0) {
        const double total = cantidadInicial * costo;
        const bool esCompra = registrarGasto && total > 0;
        QVariant gastoId;
        if (esCompra) {
            gastoId = m_finanzas->registrarGasto(QVariantMap{
                {QStringLiteral("concepto"), QStringLiteral("Compra: ") + nombre},
                {QStringLiteral("monto"), total},
                {QStringLiteral("categoria"), kCategoriaGastoProductos},
                {QStringLiteral("fecha"), fecha},
                {QStringLiteral("notas"), kNotaAutomatica},
                {QStringLiteral("productoId"), productoId}});
        }
        Database::instance().exec(
            QStringLiteral("INSERT INTO movimientos_inventario (producto_id, tipo, cantidad, "
                           "costo_unitario, motivo, gasto_id, fecha, notas) "
                           "VALUES (?, ?, ?, ?, ?, ?, ?, ?)"),
            {productoId, kTipoEntrada, cantidadInicial, costo,
             esCompra ? kMotivoCompra : kMotivoSaldoInicial,
             gastoId, fecha, QVariant()});
    }

    db.commit();
    emit cambiado();
    return productoId;
}

bool InventarioService::actualizar(const QVariantMap &datos)
{
    if (!datos.contains(QStringLiteral("id")))
        return false;
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE productos SET nombre = ?, categoria = ?, cantidad_minima = ?, "
                       "proveedor = ? WHERE id = ?"),
        {datos.value(QStringLiteral("nombre")),
         datos.value(QStringLiteral("categoria")),
         datos.value(QStringLiteral("cantidadMinima")),
         datos.value(QStringLiteral("proveedor")),
         datos.value(QStringLiteral("id"))});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool InventarioService::eliminar(int id)
{
    QSqlDatabase &db = Database::instance().db();
    db.transaction();
    m_finanzas->desvincularGastosDeProducto(id);
    Database::instance().exec(
        QStringLiteral("DELETE FROM movimientos_inventario WHERE producto_id = ?"), {id});
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("DELETE FROM productos WHERE id = ?"), {id});
    const bool ok = q.numRowsAffected() > 0;
    db.commit();
    if (ok)
        emit cambiado();
    return ok;
}

int InventarioService::registrarCompra(const QVariantMap &datos)
{
    const int productoId = datos.value(QStringLiteral("productoId")).toInt();
    const int cantidad = datos.value(QStringLiteral("cantidad")).toInt();
    if (cantidad <= 0)
        return -1;
    const QVariantMap producto = obtenerPorId(productoId);
    if (producto.isEmpty())
        return -1;

    QString fecha = datos.value(QStringLiteral("fecha")).toString();
    if (fecha.isEmpty())
        fecha = QDateTime::currentDateTime().toString(Qt::ISODate);
    const double totalPagado = datos.value(QStringLiteral("totalPagado")).toDouble();

    const int stockViejo = producto.value(QStringLiteral("cantidadStock")).toInt();
    const double costoViejo = producto.value(QStringLiteral("costoUnitario")).toDouble();
    const int nuevoStock = stockViejo + cantidad;
    // Costo promedio ponderado: mezcla lo que ya había con lo que entra.
    const double nuevoCosto = nuevoStock > 0
        ? (stockViejo * costoViejo + totalPagado) / nuevoStock : costoViejo;

    const bool esCompra = totalPagado > 0;
    const QString proveedorNuevo = datos.value(QStringLiteral("proveedor")).toString().trimmed();

    QSqlDatabase &db = Database::instance().db();
    db.transaction();

    Database::instance().exec(
        QStringLiteral("UPDATE productos SET cantidad_stock = ?, costo_unitario = ?, "
                       "fecha_compra = ?, proveedor = ? WHERE id = ?"),
        {nuevoStock, nuevoCosto, fecha,
         proveedorNuevo.isEmpty() ? producto.value(QStringLiteral("proveedor")) : QVariant(proveedorNuevo),
         productoId});

    QVariant gastoId;
    if (esCompra) {
        gastoId = m_finanzas->registrarGasto(QVariantMap{
            {QStringLiteral("concepto"),
             QStringLiteral("Compra: ") + producto.value(QStringLiteral("nombre")).toString()},
            {QStringLiteral("monto"), totalPagado},
            {QStringLiteral("categoria"), kCategoriaGastoProductos},
            {QStringLiteral("fecha"), fecha},
            {QStringLiteral("notas"), kNotaAutomatica},
            {QStringLiteral("productoId"), productoId}});
    }

    Database::instance().exec(
        QStringLiteral("INSERT INTO movimientos_inventario (producto_id, tipo, cantidad, "
                       "costo_unitario, motivo, gasto_id, fecha, notas) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"),
        {productoId, kTipoEntrada, cantidad, totalPagado / cantidad,
         esCompra ? kMotivoCompra : kMotivoSaldoInicial,
         gastoId, fecha, datos.value(QStringLiteral("notas"))});

    db.commit();
    emit cambiado();
    return gastoId.isValid() ? gastoId.toInt() : -1;
}

int InventarioService::registrarSalida(const QVariantMap &datos)
{
    const int productoId = datos.value(QStringLiteral("productoId")).toInt();
    const int cantidad = datos.value(QStringLiteral("cantidad")).toInt();
    if (cantidad <= 0)
        return 0;
    const QVariantMap producto = obtenerPorId(productoId);
    if (producto.isEmpty())
        return 0;

    const int stockViejo = producto.value(QStringLiteral("cantidadStock")).toInt();
    const int descontado = std::min(cantidad, stockViejo);
    if (descontado <= 0)
        return 0;

    const QString motivo = datos.value(QStringLiteral("motivo"), QStringLiteral("consumo")).toString();
    const QString fecha = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlDatabase &db = Database::instance().db();
    db.transaction();
    Database::instance().exec(
        QStringLiteral("UPDATE productos SET cantidad_stock = ? WHERE id = ?"),
        {stockViejo - descontado, productoId});
    Database::instance().exec(
        QStringLiteral("INSERT INTO movimientos_inventario (producto_id, tipo, cantidad, motivo, "
                       "fecha, notas) VALUES (?, ?, ?, ?, ?, ?)"),
        {productoId, kTipoSalida, descontado, motivo, fecha, datos.value(QStringLiteral("notas"))});
    db.commit();

    emit cambiado();
    return descontado;
}

bool InventarioService::registrarCorreccion(const QVariantMap &datos)
{
    const int productoId = datos.value(QStringLiteral("productoId")).toInt();
    const QVariantMap producto = obtenerPorId(productoId);
    if (producto.isEmpty())
        return false;

    const int stockViejo = producto.value(QStringLiteral("cantidadStock")).toInt();
    const double costoViejo = producto.value(QStringLiteral("costoUnitario")).toDouble();

    int objetivo = datos.value(QStringLiteral("nuevoStock")).toInt();
    if (objetivo < 0)
        objetivo = 0;
    const int diferencia = objetivo - stockViejo;

    const bool traeCosto = datos.contains(QStringLiteral("nuevoCosto"));
    const double costoPedido = datos.value(QStringLiteral("nuevoCosto")).toDouble();
    const double costo = (traeCosto && costoPedido >= 0) ? costoPedido : costoViejo;
    const bool cambiaCosto = std::abs(costo - costoViejo) > 0.001;

    if (diferencia == 0 && !cambiaCosto)
        return false;

    const QString fecha = QDateTime::currentDateTime().toString(Qt::ISODate);
    QString nota = datos.value(QStringLiteral("notas")).toString().trimmed();
    if (nota.isEmpty()) {
        QStringList partes;
        if (diferencia > 0)
            partes << QStringLiteral("Había %1 de más").arg(diferencia);
        else if (diferencia < 0)
            partes << QStringLiteral("Faltaban %1").arg(-diferencia);
        if (cambiaCosto)
            partes << QStringLiteral("Costo corregido a %1").arg(costo, 0, 'f', 2);
        nota = partes.join(QStringLiteral(" · "));
    }

    QSqlDatabase &db = Database::instance().db();
    db.transaction();
    Database::instance().exec(
        QStringLiteral("UPDATE productos SET cantidad_stock = ?, costo_unitario = ? WHERE id = ?"),
        {objetivo, costo, productoId});
    Database::instance().exec(
        QStringLiteral("INSERT INTO movimientos_inventario (producto_id, tipo, cantidad, motivo, "
                       "fecha, notas) VALUES (?, ?, ?, ?, ?, ?)"),
        {productoId, kTipoAjuste, std::abs(diferencia), kMotivoCorreccion, fecha, nota});
    db.commit();

    emit cambiado();
    return true;
}

QVariantList InventarioService::obtenerMovimientos() const
{
    QSqlQuery q = Database::instance().exec(kSelectMov + QStringLiteral("ORDER BY fecha DESC"));
    return Database::rows(q);
}

QVariantList InventarioService::movimientosDe(int productoId) const
{
    QSqlQuery q = Database::instance().exec(
        kSelectMov + QStringLiteral("WHERE producto_id = ? ORDER BY fecha DESC, id DESC"), {productoId});
    return Database::rows(q);
}

QVariantMap InventarioService::movimientoPorId(int id) const
{
    QSqlQuery q = Database::instance().exec(kSelectMov + QStringLiteral("WHERE id = ?"), {id});
    return Database::firstRow(q);
}

QString InventarioService::deshacerMovimiento(int movimientoId)
{
    const QVariantMap mov = movimientoPorId(movimientoId);
    if (mov.isEmpty())
        return QStringLiteral("no_existe");

    const QString tipo = mov.value(QStringLiteral("tipo")).toString();
    const bool esEntrada = tipo == kTipoEntrada;
    const bool esSalida = tipo == kTipoSalida;
    if (!esEntrada && !esSalida)
        return QStringLiteral("no_aplica");

    const int productoId = mov.value(QStringLiteral("productoId")).toInt();
    const QVariantMap producto = obtenerPorId(productoId);
    if (producto.isEmpty())
        return QStringLiteral("no_existe");

    const int stockViejo = producto.value(QStringLiteral("cantidadStock")).toInt();
    const double costoViejo = producto.value(QStringLiteral("costoUnitario")).toDouble();
    const int cantidad = mov.value(QStringLiteral("cantidad")).toInt();

    int nuevoStock;
    double nuevoCosto = costoViejo;
    if (esEntrada) {
        nuevoStock = stockViejo - cantidad;
        if (nuevoStock < 0)
            return QStringLiteral("no_se_puede");
        const double importe = mov.value(QStringLiteral("costoUnitario")).toDouble() * cantidad;
        const double valorRestante = stockViejo * costoViejo - importe;
        nuevoCosto = (nuevoStock > 0 && valorRestante > 0) ? valorRestante / nuevoStock : costoViejo;
    } else {
        nuevoStock = stockViejo + cantidad;
    }

    const QVariant gastoId = mov.value(QStringLiteral("gastoId"));
    const bool tieneGasto = !gastoId.isNull() && gastoId.toInt() > 0;

    QSqlDatabase &db = Database::instance().db();
    db.transaction();
    Database::instance().exec(
        QStringLiteral("UPDATE productos SET cantidad_stock = ?, costo_unitario = ? WHERE id = ?"),
        {nuevoStock, nuevoCosto, productoId});
    // El movimiento referencia al gasto por FK: hay que borrarlo primero,
    // o SQLite rechaza borrar el gasto todavía referenciado.
    Database::instance().exec(
        QStringLiteral("DELETE FROM movimientos_inventario WHERE id = ?"), {movimientoId});
    if (tieneGasto)
        Database::instance().exec(QStringLiteral("DELETE FROM gastos WHERE id = ?"), {gastoId});
    db.commit();

    emit cambiado();
    if (tieneGasto)
        emit m_finanzas->cambiado();
    return QStringLiteral("ok");
}

double InventarioService::compradoUltimosDias(int dias) const
{
    const QString corte = QDateTime::currentDateTime().addDays(-dias).toString(Qt::ISODate);
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("SELECT COALESCE(SUM(costo_unitario * cantidad), 0) FROM movimientos_inventario "
                       "WHERE tipo = ? AND gasto_id IS NOT NULL AND fecha >= ?"),
        {kTipoEntrada, corte});
    return q.next() ? q.value(0).toDouble() : 0.0;
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
    out.insert(QStringLiteral("compradoUltimoMes"), compradoUltimosDias(30));
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
