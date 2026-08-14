#include "services/RedesService.h"

#include "db/Database.h"

#include <QClipboard>
#include <QDateTime>
#include <QGuiApplication>
#include <QSqlQuery>
#include <QVariant>

const QString RedesService::kSelect = QStringLiteral(
    "SELECT id, titulo, contenido, emojis, hashtags, tipo, "
    "foto_ids AS fotoIds, fecha_creacion AS fechaCreacion, "
    "fecha_programada AS fechaProgramada, publicado, plataforma, "
    "visualizaciones, notas FROM posts_redes ");

RedesService::RedesService(QObject *parent) : QObject(parent) {}

QVariantList RedesService::obtenerTodos() const
{
    QSqlQuery q = Database::instance().exec(
        kSelect + QStringLiteral("ORDER BY fecha_creacion DESC"));
    return Database::rows(q);
}

QVariantList RedesService::filtrar(const QString &filtro) const
{
    QString where;
    if (filtro == QStringLiteral("pendientes"))
        where = QStringLiteral("WHERE publicado = 0 ");
    else if (filtro == QStringLiteral("publicados"))
        where = QStringLiteral("WHERE publicado = 1 ");
    QSqlQuery q = Database::instance().exec(
        kSelect + where + QStringLiteral("ORDER BY fecha_creacion DESC"));
    return Database::rows(q);
}

QVariantMap RedesService::obtenerPorId(int id) const
{
    QSqlQuery q = Database::instance().exec(kSelect + QStringLiteral("WHERE id = ?"), {id});
    return Database::firstRow(q);
}

int RedesService::crear(const QVariantMap &datos)
{
    QString fecha = datos.value(QStringLiteral("fechaCreacion")).toString();
    if (fecha.isEmpty())
        fecha = QDateTime::currentDateTime().toString(Qt::ISODate);
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("INSERT INTO posts_redes (titulo, contenido, emojis, hashtags, tipo, "
                       "foto_ids, fecha_creacion, fecha_programada, publicado, plataforma, "
                       "visualizaciones, notas) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, 0, ?)"),
        {datos.value(QStringLiteral("titulo")),
         datos.value(QStringLiteral("contenido")),
         datos.value(QStringLiteral("emojis")),
         datos.value(QStringLiteral("hashtags")),
         datos.value(QStringLiteral("tipo")),
         datos.value(QStringLiteral("fotoIds")),
         fecha,
         datos.value(QStringLiteral("fechaProgramada")),
         datos.value(QStringLiteral("plataforma")),
         datos.value(QStringLiteral("notas"))});
    const QVariant nuevoId = q.lastInsertId();
    if (!nuevoId.isValid())
        return -1;
    emit cambiado();
    return nuevoId.toInt();
}

bool RedesService::actualizar(const QVariantMap &datos)
{
    if (!datos.contains(QStringLiteral("id")))
        return false;
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE posts_redes SET titulo = ?, contenido = ?, emojis = ?, "
                       "hashtags = ?, tipo = ?, foto_ids = ?, plataforma = ?, notas = ? WHERE id = ?"),
        {datos.value(QStringLiteral("titulo")),
         datos.value(QStringLiteral("contenido")),
         datos.value(QStringLiteral("emojis")),
         datos.value(QStringLiteral("hashtags")),
         datos.value(QStringLiteral("tipo")),
         datos.value(QStringLiteral("fotoIds")),
         datos.value(QStringLiteral("plataforma")),
         datos.value(QStringLiteral("notas")),
         datos.value(QStringLiteral("id"))});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool RedesService::eliminar(int id)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("DELETE FROM posts_redes WHERE id = ?"), {id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool RedesService::marcarPublicado(int id)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE posts_redes SET publicado = 1 WHERE id = ?"), {id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

bool RedesService::aumentarVisualizaciones(int id)
{
    QSqlQuery q = Database::instance().exec(
        QStringLiteral("UPDATE posts_redes SET visualizaciones = visualizaciones + 1 WHERE id = ?"),
        {id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok)
        emit cambiado();
    return ok;
}

QVariantMap RedesService::estadisticas() const
{
    const QVariantList todos = obtenerTodos();
    int publicados = 0, totalVis = 0;
    QMap<QString, int> porTipo, porPlataforma;
    for (const QVariant &v : todos) {
        const QVariantMap m = v.toMap();
        if (m.value(QStringLiteral("publicado")).toInt() == 1)
            ++publicados;
        totalVis += m.value(QStringLiteral("visualizaciones")).toInt();
        porTipo[m.value(QStringLiteral("tipo")).toString()]++;
        porPlataforma[m.value(QStringLiteral("plataforma")).toString()]++;
    }
    auto aLista = [](const QMap<QString, int> &m) {
        QVariantList l;
        for (auto it = m.constBegin(); it != m.constEnd(); ++it)
            l.append(QVariantMap{{QStringLiteral("nombre"), it.key()},
                                 {QStringLiteral("total"), it.value()}});
        return l;
    };
    QVariantMap out;
    out.insert(QStringLiteral("totalPosts"), todos.size());
    out.insert(QStringLiteral("publicados"), publicados);
    out.insert(QStringLiteral("noPublicados"), int(todos.size()) - publicados);
    out.insert(QStringLiteral("totalVisualizaciones"), totalVis);
    out.insert(QStringLiteral("porTipo"), aLista(porTipo));
    out.insert(QStringLiteral("porPlataforma"), aLista(porPlataforma));
    return out;
}

QString RedesService::contenidoFormateado(const QVariantMap &post) const
{
    QString out = post.value(QStringLiteral("contenido")).toString();
    const QString emojis = post.value(QStringLiteral("emojis")).toString();
    const QString hashtags = post.value(QStringLiteral("hashtags")).toString();
    if (!emojis.isEmpty())
        out += QStringLiteral("\n\n") + emojis;
    if (!hashtags.isEmpty())
        out += QStringLiteral("\n\n") + hashtags;
    return out;
}

QStringList RedesService::sugerenciasHashtags(const QString &contenido) const
{
    const QString c = contenido.toLower();
    QStringList s;
    if (c.contains(QStringLiteral("descuento")) || c.contains(QStringLiteral("oferta")))
        s << QStringLiteral("#oferta") << QStringLiteral("#descuento") << QStringLiteral("#promocion");
    if (c.contains(QStringLiteral("trabajo")) || c.contains(QStringLiteral("diseño")))
        s << QStringLiteral("#diseño") << QStringLiteral("#trabajo") << QStringLiteral("#nailart");
    s << QStringLiteral("#manicura") << QStringLiteral("#belleza")
      << QStringLiteral("#nails") << QStringLiteral("#uñas");
    // dedup preservando orden
    QStringList out;
    for (const QString &h : s)
        if (!out.contains(h))
            out << h;
    return out;
}

QStringList RedesService::sugerenciasEmojis(const QString &tipo) const
{
    if (tipo == QStringLiteral("oferta")) return {"🎉", "💰", "✨", "🎁"};
    if (tipo == QStringLiteral("promocion")) return {"💖", "🌹", "👑", "💅"};
    if (tipo == QStringLiteral("trabajo")) return {"✨", "💫", "🌟", "👌"};
    if (tipo == QStringLiteral("testimonio")) return {"💬", "⭐", "😍", "👍"};
    if (tipo == QStringLiteral("educativo")) return {"📚", "💡", "📖", "✏️"};
    return {"✨", "💅", "💖"};
}

void RedesService::copiar(const QString &texto) const
{
    if (auto *cb = QGuiApplication::clipboard())
        cb->setText(texto);
}
