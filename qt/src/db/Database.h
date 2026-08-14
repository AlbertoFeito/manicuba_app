#pragma once

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

// Capa de acceso a SQLite. Portado de lib/database/database_helper.dart.
// Crea las 9 tablas y siembra los servicios por defecto en el primer arranque.
class Database
{
public:
    static Database &instance();

    // Abre (o crea) manicuba.db en la carpeta de datos de la app.
    // Devuelve false si el driver SQLite no está disponible.
    bool open();

    QSqlDatabase &db() { return m_db; }
    QString path() const { return m_path; }

    // Ejecuta una consulta preparada con parámetros posicionales.
    QSqlQuery exec(const QString &sql, const QVariantList &params = {});

    // Convierte todas las filas de una consulta ya ejecutada en una lista de
    // mapas (claves = nombres/alias de columna, tal cual vienen del SELECT).
    static QVariantList rows(QSqlQuery &query);
    static QVariantMap firstRow(QSqlQuery &query);

private:
    Database() = default;
    void createTables();
    void seedServicios();

    QSqlDatabase m_db;
    QString m_path;
};
