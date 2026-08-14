#include "db/Database.h"

#include <QDir>
#include <QSqlError>
#include <QSqlRecord>
#include <QStandardPaths>
#include <QVariant>
#include <QDebug>

Database &Database::instance()
{
    static Database inst;
    return inst;
}

bool Database::open()
{
    if (m_db.isOpen())
        return true;

    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    m_path = QDir(dir).filePath(QStringLiteral("manicuba.db"));

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    m_db.setDatabaseName(m_path);
    if (!m_db.open()) {
        qWarning() << "No se pudo abrir la base de datos:" << m_db.lastError().text();
        return false;
    }

    // Respeta las claves foráneas del esquema.
    m_db.exec(QStringLiteral("PRAGMA foreign_keys = ON"));

    // ¿Primera vez? Si no existe la tabla clientes, crea el esquema y siembra.
    QSqlQuery check = m_db.exec(QStringLiteral(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='clientes'"));
    const bool primeraVez = !check.next();
    if (primeraVez) {
        createTables();
        seedServicios();
    }
    return true;
}

QSqlQuery Database::exec(const QString &sql, const QVariantList &params)
{
    QSqlQuery query(m_db);
    query.prepare(sql);
    for (const QVariant &p : params)
        query.addBindValue(p);
    if (!query.exec())
        qWarning() << "Error SQL:" << query.lastError().text() << "\n  " << sql;
    return query;
}

void Database::createTables()
{
    const QStringList sentencias = {
        // Clientes
        QStringLiteral(R"(CREATE TABLE clientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            telefono TEXT NOT NULL,
            email TEXT,
            direccion TEXT,
            notas TEXT,
            fecha_creacion TEXT,
            ultima_visita TEXT
        ))"),
        // Servicios
        QStringLiteral(R"(CREATE TABLE servicios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            duracion_minutos INTEGER NOT NULL,
            descripcion TEXT
        ))"),
        // Citas
        QStringLiteral(R"(CREATE TABLE citas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente_id INTEGER NOT NULL,
            servicio_id INTEGER NOT NULL,
            fecha_hora TEXT NOT NULL,
            duracion_minutos INTEGER NOT NULL,
            estado TEXT DEFAULT 'pendiente',
            monto REAL,
            notas TEXT,
            fecha_creacion TEXT,
            FOREIGN KEY(cliente_id) REFERENCES clientes(id),
            FOREIGN KEY(servicio_id) REFERENCES servicios(id)
        ))"),
        // Ingresos
        QStringLiteral(R"(CREATE TABLE ingresos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cita_id INTEGER,
            monto REAL NOT NULL,
            metodo_pago TEXT NOT NULL,
            fecha TEXT NOT NULL,
            notas TEXT,
            FOREIGN KEY(cita_id) REFERENCES citas(id)
        ))"),
        // Gastos
        QStringLiteral(R"(CREATE TABLE gastos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            concepto TEXT NOT NULL,
            monto REAL NOT NULL,
            categoria TEXT NOT NULL,
            fecha TEXT NOT NULL,
            notas TEXT,
            producto_id INTEGER,
            FOREIGN KEY(producto_id) REFERENCES productos(id)
        ))"),
        // Productos (Inventario)
        QStringLiteral(R"(CREATE TABLE productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            categoria TEXT NOT NULL,
            cantidad_stock INTEGER NOT NULL,
            cantidad_minima INTEGER NOT NULL,
            costo_unitario REAL NOT NULL,
            fecha_compra TEXT,
            proveedor TEXT,
            fecha_creacion TEXT
        ))"),
        // Movimientos de inventario (auditoría de entradas/salidas/ajustes)
        QStringLiteral(R"(CREATE TABLE movimientos_inventario (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            producto_id INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            cantidad INTEGER NOT NULL,
            costo_unitario REAL,
            motivo TEXT NOT NULL,
            gasto_id INTEGER,
            fecha TEXT NOT NULL,
            notas TEXT,
            FOREIGN KEY(producto_id) REFERENCES productos(id),
            FOREIGN KEY(gasto_id) REFERENCES gastos(id)
        ))"),
        // Posts de redes sociales
        QStringLiteral(R"(CREATE TABLE posts_redes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            contenido TEXT NOT NULL,
            emojis TEXT,
            hashtags TEXT,
            tipo TEXT NOT NULL,
            foto_ids TEXT,
            fecha_creacion TEXT NOT NULL,
            fecha_programada TEXT,
            publicado INTEGER DEFAULT 0,
            plataforma TEXT NOT NULL,
            visualizaciones INTEGER DEFAULT 0,
            notas TEXT
        ))"),
        // Fotos de trabajo
        QStringLiteral(R"(CREATE TABLE fotos_trabajo (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cita_id INTEGER,
            ruta_foto TEXT NOT NULL,
            fecha TEXT NOT NULL,
            descripcion TEXT,
            compartida INTEGER DEFAULT 0,
            FOREIGN KEY(cita_id) REFERENCES citas(id)
        ))"),
        // Estadísticas de redes
        QStringLiteral(R"(CREATE TABLE estadisticas_redes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT NOT NULL,
            posts_creados INTEGER DEFAULT 0,
            fotos_compartidas INTEGER DEFAULT 0,
            ofertas_promocionadas INTEGER DEFAULT 0,
            clientes_nuevos INTEGER DEFAULT 0
        ))"),
    };

    for (const QString &sql : sentencias) {
        QSqlQuery q = m_db.exec(sql);
        if (m_db.lastError().isValid())
            qWarning() << "Error creando tabla:" << m_db.lastError().text();
    }
}

void Database::seedServicios()
{
    struct Def { const char *nombre; double precio; int dur; const char *desc; };
    const QList<Def> servicios = {
        {"Manicura Básica", 10.0, 30, "Corte, lima y esmalte básico"},
        {"Manicura con Gel", 20.0, 45, "Gel UV resistente y duradero"},
        {"Acrílicas", 25.0, 60, "Uñas acrílicas con acabado"},
        {"Manicura Decorada", 15.0, 40, "Con decoraciones y diseños"},
        {"Esmaltado Francés", 12.0, 35, "Clásico francés elegante"},
    };
    for (const Def &s : servicios) {
        exec(QStringLiteral("INSERT INTO servicios (nombre, precio, duracion_minutos, descripcion) "
                            "VALUES (?, ?, ?, ?)"),
             {QString::fromUtf8(s.nombre), s.precio, s.dur, QString::fromUtf8(s.desc)});
    }
}

QVariantList Database::rows(QSqlQuery &query)
{
    QVariantList out;
    const QSqlRecord rec = query.record();
    const int cols = rec.count();
    while (query.next()) {
        QVariantMap row;
        for (int i = 0; i < cols; ++i)
            row.insert(rec.fieldName(i), query.value(i));
        out.append(row);
    }
    return out;
}

QVariantMap Database::firstRow(QSqlQuery &query)
{
    const QVariantList all = rows(query);
    return all.isEmpty() ? QVariantMap() : all.first().toMap();
}
