import QtQuick
import ManiCuba

// Mensaje centrado cuando una lista está vacía.
Column {
    property string icono: "💅"
    property string mensaje: "Sin datos"
    property string detalle: ""

    spacing: 8
    width: parent ? parent.width : implicitWidth

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: icono
        font.pixelSize: 48
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: mensaje
        font.pixelSize: 16
        font.bold: true
        color: Theme.textSecondary
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: detalle
        visible: detalle.length > 0
        font.pixelSize: 13
        color: Theme.textSecondary
        horizontalAlignment: Text.AlignHCenter
        width: Math.min(parent.width, 320)
        wrapMode: Text.WordWrap
    }
}
