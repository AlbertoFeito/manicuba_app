import QtQuick
import ManiCuba

// Título de sección con línea inferior sutil.
Column {
    property string titulo: ""
    property string subtitulo: ""

    spacing: 2
    width: parent ? parent.width : implicitWidth

    Text {
        text: titulo
        font.pixelSize: 20
        font.bold: true
        color: Theme.primary
    }
    Text {
        text: subtitulo
        visible: subtitulo.length > 0
        font.pixelSize: 13
        color: Theme.textSecondary
    }
}
