#include "services/CategoriaService.h"

#include "config/AppConfig.h"

#include <QSettings>

const char *CategoriaService::kKey = "categorias_productos_custom";

CategoriaService::CategoriaService(QObject *parent) : QObject(parent) {}

QStringList CategoriaService::obtenerCategorias() const
{
    AppConfig cfg;
    QStringList base = cfg.categoriasProductos();
    const QStringList custom =
        QSettings().value(QLatin1String(kKey)).toStringList();

    // "Otros" siempre al final.
    base.removeAll(QStringLiteral("Otros"));

    QStringList resultado = base;
    for (const QString &c : custom) {
        const QString limpio = c.trimmed();
        if (limpio.isEmpty())
            continue;
        bool existe = false;
        for (const QString &e : resultado)
            if (e.compare(limpio, Qt::CaseInsensitive) == 0) {
                existe = true;
                break;
            }
        if (!existe && limpio.compare(QStringLiteral("Otros"), Qt::CaseInsensitive) != 0)
            resultado << limpio;
    }
    resultado << QStringLiteral("Otros");
    return resultado;
}

bool CategoriaService::agregarCategoria(const QString &nombre)
{
    const QString limpio = nombre.trimmed();
    if (limpio.isEmpty())
        return false;
    for (const QString &e : obtenerCategorias())
        if (e.compare(limpio, Qt::CaseInsensitive) == 0)
            return false;

    QSettings sp;
    QStringList custom = sp.value(QLatin1String(kKey)).toStringList();
    custom << limpio;
    sp.setValue(QLatin1String(kKey), custom);
    emit categoriasCambiadas();
    return true;
}
