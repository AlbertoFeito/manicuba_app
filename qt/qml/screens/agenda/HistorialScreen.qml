import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Historial de citas completadas y canceladas, con opción de deshacer.
// Portado de lib/screens/agenda/historial_screen.dart.
Page {
    id: page
    property var lista: []

    function refrescar() { lista = Citas.historial() }
    Component.onCompleted: refrescar()
    Connections { target: Citas; function onCambiado() { page.refrescar() } }

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "‹"; font.pixelSize: 24; onClicked: page.StackView.view.pop() }
            Label {
                text: "Historial de citas"
                font.pixelSize: 18; font.bold: true; color: "white"
                Layout.fillWidth: true
            }
        }
    }

    ListView {
        anchors.fill: parent
        model: page.lista
        spacing: 6
        clip: true
        topMargin: Theme.paddingSmall

        delegate: AppCard {
            required property var modelData
            width: ListView.view.width - Theme.padding * 2
            x: Theme.padding
            RowLayout {
                width: parent.width
                spacing: Theme.paddingSmall
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: (modelData.nombreCliente || "Cliente") + " · "
                              + AppConfig.moneda(modelData.monto || 0)
                        font.pixelSize: 15; font.bold: true; color: Theme.textPrimary
                        Layout.fillWidth: true; elide: Text.ElideRight
                    }
                    Text {
                        text: (modelData.nombreServicio || "Servicio") + " — "
                              + Qt.formatDateTime(new Date(modelData.fechaHora), "dd/MM/yyyy HH:mm")
                        font.pixelSize: 12; color: Theme.textSecondary
                    }
                }
                EstadoBadge { estado: modelData.estado || "completada" }
                Button {
                    text: "Deshacer"
                    flat: true
                    Material.foreground: Theme.primary
                    onClicked: Citas.cambiarEstado(modelData.id, "pendiente")
                }
            }
        }

        EmptyState {
            anchors.centerIn: parent
            width: parent.width
            visible: page.lista.length === 0
            icono: "🗂"
            mensaje: "Sin historial"
            detalle: "Las citas completadas o canceladas aparecerán aquí."
        }
    }
}
