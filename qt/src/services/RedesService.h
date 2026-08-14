#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

// Gestor de posts de redes sociales. Portado de lib/services/redes_service.dart.
class RedesService : public QObject
{
    Q_OBJECT
public:
    explicit RedesService(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList obtenerTodos() const;
    // filtro: "todos" | "pendientes" | "publicados"
    Q_INVOKABLE QVariantList filtrar(const QString &filtro) const;
    Q_INVOKABLE QVariantMap obtenerPorId(int id) const;

    Q_INVOKABLE int crear(const QVariantMap &datos);
    Q_INVOKABLE bool actualizar(const QVariantMap &datos);
    Q_INVOKABLE bool eliminar(int id);
    Q_INVOKABLE bool marcarPublicado(int id);
    Q_INVOKABLE bool aumentarVisualizaciones(int id);

    // Estadísticas: totalPosts, publicados, noPublicados, totalVisualizaciones,
    // porTipo [{nombre,total}], porPlataforma [{nombre,total}].
    Q_INVOKABLE QVariantMap estadisticas() const;

    // Contenido + emojis + hashtags, listo para copiar/pegar.
    Q_INVOKABLE QString contenidoFormateado(const QVariantMap &post) const;
    Q_INVOKABLE QStringList sugerenciasHashtags(const QString &contenido) const;
    Q_INVOKABLE QStringList sugerenciasEmojis(const QString &tipo) const;

    // Copia texto al portapapeles del sistema.
    Q_INVOKABLE void copiar(const QString &texto) const;

signals:
    void cambiado();

private:
    static const QString kSelect;
};
