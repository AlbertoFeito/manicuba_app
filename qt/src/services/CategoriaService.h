#pragma once

#include <QObject>
#include <QStringList>

// Categorías de productos: las de fábrica más las personalizadas del usuario,
// persistidas con QSettings. Portado de lib/services/categoria_service.dart.
class CategoriaService : public QObject
{
    Q_OBJECT
public:
    explicit CategoriaService(QObject *parent = nullptr);

    // Categorías de fábrica + personalizadas, "Otros" siempre al final,
    // sin duplicados (case-insensitive).
    Q_INVOKABLE QStringList obtenerCategorias() const;
    // Agrega una categoría personalizada; devuelve true si se agregó.
    Q_INVOKABLE bool agregarCategoria(const QString &nombre);

signals:
    void categoriasCambiadas();

private:
    static const char *kKey;
};
