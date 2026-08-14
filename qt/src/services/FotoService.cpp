#include "services/FotoService.h"

#include "db/Database.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QUrl>
#include <QVariant>

FotoService::FotoService(QObject *parent) : QObject(parent) {}

QString FotoService::directorioFotos() const
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString dir = QDir(base).filePath(QStringLiteral("fotos_trabajo"));
    QDir().mkpath(dir);
    return dir;
}

int FotoService::guardarDesdeArchivo(const QString &origen, const QString &descripcion)
{
    QString rutaOrigen = origen;
    if (rutaOrigen.startsWith(QStringLiteral("file:")))
        rutaOrigen = QUrl(rutaOrigen).toLocalFile();
    QFileInfo info(rutaOrigen);
    if (!info.exists())
        return -1;

    const QString ext = info.suffix().isEmpty() ? QStringLiteral("jpg") : info.suffix();
    const QString nombre = QStringLiteral("foto_%1.%2")
                               .arg(QDateTime::currentMSecsSinceEpoch())
                               .arg(ext);
    const QString destino = QDir(directorioFotos()).filePath(nombre);
    if (!QFile::copy(rutaOrigen, destino))
        return -1;

    QSqlQuery q = Database::instance().exec(
        QStringLiteral("INSERT INTO fotos_trabajo (cita_id, ruta_foto, fecha, descripcion, "
                       "compartida) VALUES (NULL, ?, ?, ?, 0)"),
        {destino, QDateTime::currentDateTime().toString(Qt::ISODate), descripcion});
    const QVariant nuevoId = q.lastInsertId();
    if (!nuevoId.isValid())
        return -1;
    emit cambiado();
    return nuevoId.toInt();
}

QVariantList FotoService::obtenerTodas() const
{
    QSqlQuery q = Database::instance().exec(QStringLiteral(
        "SELECT id, cita_id AS citaId, ruta_foto AS rutaFoto, fecha, descripcion, "
        "compartida FROM fotos_trabajo ORDER BY fecha DESC"));
    QVariantList out = Database::rows(q);
    for (QVariant &v : out) {
        QVariantMap m = v.toMap();
        m.insert(QStringLiteral("url"),
                 QUrl::fromLocalFile(m.value(QStringLiteral("rutaFoto")).toString()).toString());
        v = m;
    }
    return out;
}

bool FotoService::eliminar(int id)
{
    QSqlQuery sel = Database::instance().exec(
        QStringLiteral("SELECT ruta_foto FROM fotos_trabajo WHERE id = ?"), {id});
    QString ruta;
    if (sel.next())
        ruta = sel.value(0).toString();

    QSqlQuery q = Database::instance().exec(
        QStringLiteral("DELETE FROM fotos_trabajo WHERE id = ?"), {id});
    const bool ok = q.numRowsAffected() > 0;
    if (ok) {
        if (!ruta.isEmpty())
            QFile::remove(ruta);
        emit cambiado();
    }
    return ok;
}

int FotoService::total() const
{
    QSqlQuery q = Database::instance().exec(QStringLiteral("SELECT COUNT(*) FROM fotos_trabajo"));
    return q.next() ? q.value(0).toInt() : 0;
}
