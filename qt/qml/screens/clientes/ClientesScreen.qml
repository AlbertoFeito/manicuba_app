import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Lista de clientes con búsqueda en vivo. Portado de
// lib/screens/clientes/clientes_screen.dart.
Item {
    id: root

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

            function refrescar() {
                lista = buscador.text.trim().length > 0
                        ? Clientes.buscarPorNombre(buscador.text.trim())
                        : Clientes.obtenerTodos()
            }
            Component.onCompleted: refrescar()
            Connections { target: Clientes; function onCambiado() { page.refrescar() } }

            header: Pane {
                Material.elevation: 0
                RowLayout {
                    anchors.fill: parent
                    TextField {
                        id: buscador
                        Layout.fillWidth: true
                        placeholderText: "🔍 Buscar por nombre…"
                        Material.accent: Theme.primary
                        onTextChanged: page.refrescar()
                    }
                }
            }

            ListView {
                id: listView
                anchors.fill: parent
                model: page.lista
                spacing: 6
                clip: true
                topMargin: Theme.paddingSmall
                bottomMargin: 88

                delegate: ItemDelegate {
                    required property var modelData
                    width: ListView.view.width
                    onClicked: stack.push(detalleComp, { clienteId: modelData.id })
                    contentItem: RowLayout {
                        spacing: Theme.padding
                        Rectangle {
                            width: 42; height: 42; radius: 21
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                            Text {
                                anchors.centerIn: parent
                                text: (modelData.nombre || "?").charAt(0).toUpperCase()
                                font.pixelSize: 18
                                font.bold: true
                                color: Theme.primary
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: modelData.nombre || ""
                                font.pixelSize: 16
                                font.bold: true
                                color: Theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "📞 " + (modelData.telefono || "")
                                font.pixelSize: 13
                                color: Theme.textSecondary
                            }
                        }
                        Text { text: "›"; font.pixelSize: 22; color: Theme.textSecondary }
                    }
                }

                EmptyState {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: page.lista.length === 0
                    icono: "👥"
                    mensaje: "Sin clientes todavía"
                    detalle: "Toca el botón + para agregar tu primer cliente."
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

    Component { id: formComp; ClienteForm {} }
    Component { id: detalleComp; ClienteDetail {} }
}
