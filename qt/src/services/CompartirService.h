#pragma once

#include <QObject>
#include <QString>

// Compartir un archivo local con la hoja de compartir nativa de Android.
// Portado de lib/services/compartir_service.dart (la parte de compartir una
// foto suelta; el envío directo a WhatsApp/Instagram con texto prellenado que
// hace compartir_nativo.dart en Flutter queda fuera de alcance por ahora).
class CompartirService : public QObject
{
    Q_OBJECT
public:
    explicit CompartirService(QObject *parent = nullptr);

    // Abre la hoja de compartir del sistema con el archivo local adjunto.
    // true si se pudo lanzar (no en escritorio: ahí no hay share sheet).
    Q_INVOKABLE bool compartirFoto(const QString &rutaLocal);
};
