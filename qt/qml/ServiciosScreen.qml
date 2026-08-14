import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Catálogo de servicios. Portado de lib/screens/servicios/servicios_screen.dart.
Item {
    id: root

    // Usado por el botón atrás de Android (ver Main.qml).
    function volver() {
        if (stack.depth > 1) { stack.pop(); return true }
        return false
    }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: listaPage
    }

    Component {
        id: listaPage
        Page {
            id: page
            property var lista: []
            function refrescar() { lista = Servicios.obtenerTodos() }
            Component.onCompleted: refrescar()
            Connections { target: Servicios; function onCambiado() { page.refrescar() } }

            ListView {
                anchors.fill: parent
                model: page.lista
                spacing: 6
                clip: true
                topMargin: Theme.paddingSmall
                bottomMargin: 88

                delegate: ItemDelegate {
                    required property var modelData
                    width: ListView.view.width
                    onClicked: stack.push(formComp, { servicio: modelData })
                    contentItem: RowLayout {
                        spacing: Theme.padding
                        Text { text: "💅"; font.pixelSize: 22 }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: modelData.nombre || ""
                                font.pixelSize: 16; font.bold: true; color: Theme.textPrimary
                                Layout.fillWidth: true; elide: Text.ElideRight
                            }
                            Text {
                                text: "⏱ " + (modelData.duracionMinutos || 0) + " min"
                                font.pixelSize: 13; color: Theme.textSecondary
                            }
                        }
                        Text {
                            text: AppConfig.moneda(modelData.precio || 0)
                            font.pixelSize: 16; font.bold: true; color: Theme.primary
                        }
                    }
                }

                EmptyState {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: page.lista.length === 0
                    icono: "💅"
                    mensaje: "Sin servicios"
                    detalle: "Agrega los servicios que ofreces con su precio y duración."
                }
            }

            RoundButton {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Theme.paddingLarge
                text: "+"
                font.pixelSize: 26
                Material.background: Theme.primary
                Material.foreground: "white"
                background: Rectangle { radius: width / 2; color: Theme.primary }
                onClicked: stack.push(formComp, {})
            }
        }
    }

    Component { id: formComp; ServicioForm {} }
}
