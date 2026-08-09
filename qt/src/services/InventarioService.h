#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

// Inventario de productos. Portado de lib/services/inventario_service.dart.
class InventarioService : public QObject
{
    Q_OBJECT
public:
    explicit InventarioService(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList obtenerTodos() const;         // ordenados por nombre
    Q_INVOKABLE QVariantList ordenarPorStock() const;      // asc por stock
    Q_INVOKABLE QVariantList obtenerPorCategoria(const QString &categoria) const;
    Q_INVOKABLE QVariantList obtenerBajoStock() const;     // stock <= minimo
    Q_INVOKABLE QVariantMap obtenerPorId(int id) const;

    Q_INVOKABLE int crear(const QVariantMap &datos);
    Q_INVOKABLE bool actualizar(const QVariantMap &datos);
    Q_INVOKABLE bool eliminar(int id);
    Q_INVOKABLE bool aumentarStock(int id, int cantidad);  // marca fecha_compra
    Q_INVOKABLE bool disminuirStock(int id, int cantidad); // no baja de 0

    // Estadísticas: totalProductos, cantidadTotal, valorTotal, costoTotal, bajoStock.
    Q_INVOKABLE QVariantMap estadisticas() const;
    // Resumen por categoría: [{ nombre, productos, cantidad, costo }] desc por costo.
    Q_INVOKABLE QVariantList resumenPorCategoria() const;

signals:
    void cambiado();

private:
    static const QString kSelect;
};
