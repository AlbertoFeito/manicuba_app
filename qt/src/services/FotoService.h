#pragma once

#include <QObject>
#include <QVariantList>

// Galería de fotos de trabajo. Portado de lib/services/foto_service.dart.
// Copia la imagen elegida al almacenamiento de la app y la registra en la BD.
class FotoService : public QObject
{
    Q_OBJECT
public:
    explicit FotoService(QObject *parent = nullptr);

    // Copia la imagen (ruta local o file:// URL) al almacenamiento de la app y
    // registra la foto. Devuelve el id nuevo (-1 si falla).
    Q_INVOKABLE int guardarDesdeArchivo(const QString &origen, const QString &descripcion = QString());
    // Lista de fotos con un campo extra "url" (file://…) para mostrar en QML.
    Q_INVOKABLE QVariantList obtenerTodas() const;
    Q_INVOKABLE bool eliminar(int id);
    Q_INVOKABLE int total() const;

signals:
    void cambiado();

private:
    QString directorioFotos() const;
};
