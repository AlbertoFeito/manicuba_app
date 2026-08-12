import QtQuick
import ManiCuba

// Etiqueta de color según el estado de la cita.
Rectangle {
    property string estado: "pendiente"

    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 8
    radius: height / 2
    color: Qt.rgba(Theme.colorEstado(estado).r,
                   Theme.colorEstado(estado).g,
                   Theme.colorEstado(estado).b, 0.15)

    Text {
        id: label
        anchors.centerIn: parent
        text: AppConfig.etiquetaEstado(estado)
        font.pixelSize: 12
        font.bold: true
        color: Theme.colorEstado(estado)
    }
}
