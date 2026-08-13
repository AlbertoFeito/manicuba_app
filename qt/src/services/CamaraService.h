#pragma once

#include <QObject>
#include <QString>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#endif

// Cámara del dispositivo vía el Intent nativo de Android
// (MediaStore.ACTION_IMAGE_CAPTURE), igual que hace image_picker en Flutter:
// no hay visor propio, se delega en la app de Cámara del sistema. No hace
// falta el permiso CAMERA (solo se necesita si la app usara la Camera API
// directamente) ni dependencias androidx: el hueco de salida se crea con
// MediaStore.Images.Media, framework puro disponible desde min-SDK 24.
class CamaraService : public QObject
{
    Q_OBJECT
public:
    explicit CamaraService(QObject *parent = nullptr);

    // Lanza la app de Cámara del sistema. true si el Intent se pudo lanzar
    // (no implica que la usuaria vaya a completar la foto: eso se sabe
    // llamando a recogerCaptura() cuando la app recupere el foco).
    Q_INVOKABLE bool tomarFoto();

    // Se llama cuando la app vuelve a primer plano (ver GaleriaScreen.qml).
    // Devuelve la ruta local de la foto tomada, o "" si no hay ninguna
    // captura pendiente o la usuaria canceló.
    Q_INVOKABLE QString recogerCaptura();

private:
#ifdef Q_OS_ANDROID
    QJniObject m_uriPendiente;
#endif
};
