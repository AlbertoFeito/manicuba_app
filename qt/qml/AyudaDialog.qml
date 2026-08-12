import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Diálogo de ayuda contextual de una ventana. Se alimenta de AppConfig.ayuda(clave).
Dialog {
    id: dlg
    property string clave: "inicio"
    property var info: AppConfig.ayuda(clave)

    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(parent ? parent.width - Theme.padding * 2 : 400, 460)
    padding: Theme.padding
    standardButtons: Dialog.Ok

    onAboutToShow: info = AppConfig.ayuda(clave)

    background: Rectangle { color: Theme.surface; radius: Theme.radius }

    header: Rectangle {
        color: Theme.primary
        radius: Theme.radius
        implicitHeight: 52
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.padding
            anchors.rightMargin: Theme.padding
            spacing: Theme.paddingSmall
            Text { text: dlg.info.icono || "💡"; font.pixelSize: 20 }
            Text {
                text: dlg.info.titulo || "Ayuda"
                color: "white"; font.pixelSize: 17; font.bold: true
                Layout.fillWidth: true
            }
        }
    }

    contentItem: Flickable {
        implicitHeight: Math.min(col.implicitHeight, 420)
        contentHeight: col.implicitHeight
        clip: true
        ColumnLayout {
            id: col
            width: parent.width
            spacing: Theme.padding
            Repeater {
                model: dlg.info.puntos || []
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Theme.paddingSmall
                    Text { text: "•"; color: Theme.primary; font.pixelSize: 16; font.bold: true }
                    Text {
                        text: modelData
                        color: Theme.textPrimary
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
