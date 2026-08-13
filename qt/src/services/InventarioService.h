#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class FinanzasService;

// Inventario de productos. Portado de lib/services/inventario_service.dart.
//
// Modelo de costo: el gasto ocurre cuando se compra, por el total pagado y en
// la fecha de la compra. Descontar stock después no genera gasto -el dinero
// ya salió-; el stock solo dice cuánto queda. Toda entrada pagada crea un
// gasto automático en Finanzas (categoría "Productos"); toda salida no toca
// dinero. Cada movimiento (entrada/salida/ajuste) queda en
// movimientos_inventario, así que editar/borrar/aumentar stock a mano ya no
// existe: todo pasa por crear/registrarCompra/registrarSalida/registrarCorreccion.
class InventarioService : public QObject
{
    Q_OBJECT
public:
    explicit InventarioService(FinanzasService *finanzas, QObject *parent = nullptr);

    Q_INVOKABLE QVariantList obtenerTodos() const;         // ordenados por nombre
    Q_INVOKABLE QVariantList ordenarPorStock() const;      // asc por stock
    Q_INVOKABLE QVariantList obtenerPorCategoria(const QString &categoria) const;
    Q_INVOKABLE QVariantList obtenerBajoStock() const;     // stock <= minimo
    Q_INVOKABLE QVariantMap obtenerPorId(int id) const;
    // Producto con el mismo nombre+categoría (insensible a mayúsculas/espacios
    // sobrantes), o vacío si no hay ninguno. exceptoId excluye ese id (al editar).
    Q_INVOKABLE QVariantMap buscarPorNombreYCategoria(const QString &nombre,
                                                       const QString &categoria,
                                                       int exceptoId = -1) const;

    // Alta de ficha. Si trae stock inicial, esa es la primera entrada;
    // registrarGasto decide si generó un gasto ahora (compra real) o no
    // (stock que ya se tenía). Devuelve el id del producto (-1 si falla).
    Q_INVOKABLE int crear(const QVariantMap &datos, bool registrarGasto = true);
    // Solo la ficha (nombre/categoría/mínimo/proveedor): el stock y el costo
    // se mueven con registrarCompra/registrarSalida/registrarCorreccion, que
    // dejan rastro. Cambiarlos aquí descuadraría el historial.
    Q_INVOKABLE bool actualizar(const QVariantMap &datos);
    // Borra el producto y su historial de movimientos. Los gastos que generó
    // se desvinculan (no se borran: ese dinero salió de verdad).
    Q_INVOKABLE bool eliminar(int id);

    // ===== Movimientos de stock =====

    // Compra: sube stock, recalcula el costo por promedio ponderado y crea el
    // gasto en Finanzas si totalPagado > 0. datos: productoId, cantidad,
    // totalPagado, fecha, proveedor, notas.
    // Devuelve el id del gasto creado, o -1 si no se pagó nada / datos inválidos.
    Q_INVOKABLE int registrarCompra(const QVariantMap &datos);
    // Descuenta stock por consumo/rotura/vencido; no genera gasto (el dinero
    // ya salió al comprar). datos: productoId, cantidad, motivo, notas.
    // Devuelve las unidades realmente descontadas (el stock no baja de 0).
    Q_INVOKABLE int registrarSalida(const QVariantMap &datos);
    // Cuadra stock/costo tras un conteo físico; no toca Finanzas. datos:
    // productoId, nuevoStock, nuevoCosto, notas. true si aplicó algún cambio.
    Q_INVOKABLE bool registrarCorreccion(const QVariantMap &datos);

    Q_INVOKABLE QVariantList obtenerMovimientos() const;   // todos, más reciente primero
    Q_INVOKABLE QVariantList movimientosDe(int productoId) const;

    // Deshace una compra o salida (las correcciones no se deshacen: se vuelven
    // a corregir). "ok" | "no_existe" | "no_se_puede" (dejaría stock negativo)
    // | "no_aplica".
    Q_INVOKABLE QString deshacerMovimiento(int movimientoId);

    // Dinero gastado en compras dentro de los últimos [dias] días.
    Q_INVOKABLE double compradoUltimosDias(int dias) const;

    // Estadísticas: totalProductos, cantidadTotal, valorTotal, costoTotal,
    // compradoUltimoMes, bajoStock.
    Q_INVOKABLE QVariantMap estadisticas() const;
    // Resumen por categoría: [{ nombre, productos, cantidad, costo }] desc por costo.
    Q_INVOKABLE QVariantList resumenPorCategoria() const;

signals:
    void cambiado();

private:
    QVariantMap movimientoPorId(int id) const;

    FinanzasService *m_finanzas;
    static const QString kSelect;
    static const QString kSelectMov;
};
