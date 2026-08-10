#include "config/AppConfig.h"

#include <QLocale>

AppConfig::AppConfig(QObject *parent) : QObject(parent) {}

QStringList AppConfig::categoriasGastos() const
{
    return {QStringLiteral("Productos"), QStringLiteral("Servicios"),
            QStringLiteral("Alquiler"), QStringLiteral("Transporte"),
            QStringLiteral("Otros")};
}

QStringList AppConfig::categoriasProductos() const
{
    return {QStringLiteral("Esmaltes"),     QStringLiteral("Geles"),
            QStringLiteral("Acrílicos"),    QStringLiteral("Decoraciones"),
            QStringLiteral("Herramientas"), QStringLiteral("Limpiadores"),
            QStringLiteral("Otros")};
}

QStringList AppConfig::metodosPago() const
{
    return {QStringLiteral("Efectivo"), QStringLiteral("Transferencia"),
            QStringLiteral("Tarjeta")};
}

QStringList AppConfig::tiposPost() const
{
    return {QStringLiteral("Oferta"), QStringLiteral("Promoción"),
            QStringLiteral("Trabajo"), QStringLiteral("Testimonio"),
            QStringLiteral("Educativo")};
}

QStringList AppConfig::plataformasSociales() const
{
    return {QStringLiteral("Instagram"), QStringLiteral("Facebook"),
            QStringLiteral("WhatsApp"), QStringLiteral("Todas")};
}

QStringList AppConfig::emojisPopulares() const
{
    return {QStringLiteral("💅"), QStringLiteral("✨"), QStringLiteral("🌹"),
            QStringLiteral("💖"), QStringLiteral("🎀"), QStringLiteral("👑"),
            QStringLiteral("💄"), QStringLiteral("🌸"), QStringLiteral("🦋"),
            QStringLiteral("💫"), QStringLiteral("🔥"), QStringLiteral("😍"),
            QStringLiteral("🤩"), QStringLiteral("😊"), QStringLiteral("👌")};
}

QStringList AppConfig::hashtagsComunes() const
{
    return {QStringLiteral("#manicura"),  QStringLiteral("#uñas"),
            QStringLiteral("#nails"),     QStringLiteral("#beauty"),
            QStringLiteral("#diseño"),    QStringLiteral("#gelmanicure"),
            QStringLiteral("#acrylicnails"), QStringLiteral("#nailart"),
            QStringLiteral("#belleza"),   QStringLiteral("#esmalte")};
}

QString AppConfig::moneda(double valor) const
{
    return QStringLiteral("$") + QLocale(QLocale::Spanish).toString(valor, 'f', 2);
}

QString AppConfig::etiquetaEstado(const QString &estado) const
{
    if (estado == QStringLiteral("confirmada")) return QStringLiteral("Confirmada");
    if (estado == QStringLiteral("completada")) return QStringLiteral("Completada");
    if (estado == QStringLiteral("cancelada")) return QStringLiteral("Cancelada");
    return QStringLiteral("Pendiente");
}

QVariantMap AppConfig::ayuda(const QString &clave) const
{
    // Portado de lib/config/ayuda_content.dart (Ayudas).
    auto info = [](const QString &icono, const QString &titulo, const QStringList &puntos) {
        return QVariantMap{{QStringLiteral("icono"), icono},
                           {QStringLiteral("titulo"), titulo},
                           {QStringLiteral("puntos"), puntos}};
    };

    if (clave == QStringLiteral("inicio"))
        return info("🏠", "Inicio", {
            "El \"Resumen del día\" muestra tus citas, ingresos, gastos y balance de hoy en tiempo real.",
            "Usa las \"Acciones rápidas\" para crear al vuelo: Nueva Cita, Nuevo Cliente, Finanzas o Servicios.",
            "Toca el menú ⋮ (arriba a la derecha) para abrir Servicios, Inventario y la Galería de trabajos.",
            "El resumen se actualiza al volver a esta pestaña."});
    if (clave == QStringLiteral("agenda"))
        return info("📅", "Agenda", {
            "Usa las flechas ‹ › o \"Hoy\" para moverte entre días; debajo verás las citas de ese día.",
            "Pulsa + para agendar: elige cliente y servicio (el monto se rellena solo con el precio del servicio).",
            "Toca una cita para cambiar su estado, editarla o eliminarla.",
            "Al marcar una cita como COMPLETADA, su monto se registra automáticamente como ingreso en Finanzas.",
            "Las citas COMPLETADAS y CANCELADAS salen del día y pasan al Historial; aquí solo se ven las activas.",
            "Abre el Historial desde el menú ⋮ (arriba a la derecha)."});
    if (clave == QStringLiteral("historial"))
        return info("🗂", "Historial de citas", {
            "Aquí quedan las citas completadas (verde) y canceladas (rojo), de la más reciente a la más antigua.",
            "\"Deshacer\" corrige un error: devuelve la cita al calendario como Pendiente. Si estaba completada, también le quita el ingreso."});
    if (clave == QStringLiteral("clientes"))
        return info("👥", "Clientes", {
            "Busca por nombre con la barra superior.",
            "Pulsa + para agregar un cliente (nombre y teléfono son obligatorios).",
            "Toca un cliente para ver su ficha con contacto, notas e historial de citas.",
            "En la ficha, usa los botones para Llamar, abrir WhatsApp o enviar SMS.",
            "Desde la ficha puedes editar o eliminar al cliente."});
    if (clave == QStringLiteral("finanzas"))
        return info("💰", "Finanzas", {
            "Arriba ves el balance del periodo y los mini-balances de hoy y de la semana.",
            "Usa + para registrar un Ingreso o un Gasto manualmente.",
            "Los ingresos de las citas completadas aparecen aquí automáticamente (marcados como \"auto\").",
            "Usa los filtros Hoy / Semana / Mes / Todo para acotar los datos.",
            "La dona reparte tus gastos por categoría; en \"Analíticas\" ves comparación, KPIs y rankings."});
    if (clave == QStringLiteral("redes"))
        return info("📣", "Redes Sociales", {
            "Pulsa + y escribe título y contenido.",
            "Toca los chips sugeridos para añadir emojis y hashtags al instante.",
            "En cada post: Copiar (al portapapeles), Abrir la plataforma, marcar Publicado, Editar o Eliminar.",
            "Usa los filtros Todos / Pendientes / Publicados para organizar tus posts."});
    if (clave == QStringLiteral("servicios"))
        return info("💅", "Servicios", {
            "Es tu catálogo de servicios con precio y duración.",
            "Pulsa + para agregar uno; toca un servicio para editar o eliminar.",
            "Estos servicios son los que eliges al crear una cita, y su precio rellena el monto automáticamente."});
    if (clave == QStringLiteral("inventario"))
        return info("📦", "Inventario", {
            "Controla tus productos: stock actual, mínimo y costo.",
            "Usa los botones + y − para ajustar el stock rápidamente.",
            "Los productos por debajo del mínimo se marcan como \"bajo\".",
            "Arriba ves el valor total del inventario."});
    if (clave == QStringLiteral("galeria"))
        return info("📸", "Galería de trabajos", {
            "Guarda fotos de tus trabajos para tenerlas siempre a mano (offline).",
            "Pulsa + para elegir una imagen.",
            "Toca una foto para verla en grande o eliminarla."});
    return info("💡", "Ayuda", {"Sin ayuda para esta ventana."});
}
