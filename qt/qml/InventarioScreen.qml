import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Inventario de productos: estadísticas, alerta de bajo stock y lista con
// control rápido de existencias. Portado de
// lib/screens/inventario/inventario_screen.dart.
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
            property var stats: ({})

            function refrescar() {
                lista = Inventario.obtenerTodos()
                stats = Inventario.estadisticas()
            }
            Component.onCompleted: refrescar()
            Connections { target: Inventario; function onCambiado() { page.refrescar() } }

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: col.implicitHeight + Theme.paddingLarge + 72
                clip: true

                ColumnLayout {
                    id: col
                    width: parent.width - Theme.padding * 2
                    x: Theme.padding
                    y: Theme.padding
                    spacing: Theme.padding

                    // Estadísticas
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Theme.padding
                        rowSpacing: Theme.padding
                        Stat { icono: "📦"; titulo: "Productos"; valor: String(page.stats.totalProductos || 0); acento: Theme.info }
                        Stat { icono: "🔢"; titulo: "Unidades"; valor: String(page.stats.cantidadTotal || 0); acento: Theme.primary }
                        Stat { icono: "💵"; titulo: "Valor total"; valor: AppConfig.moneda(page.stats.valorTotal || 0); acento: Theme.success }
                        Stat { icono: "⚠️"; titulo: "Bajo stock"; valor: String(page.stats.productosBajoStock || 0); acento: Theme.error }
                    }

                    // Alerta de bajo stock
                    AppCard {
                        Layout.fillWidth: true
                        visible: (page.stats.productosBajoStock || 0) > 0
                        RowLayout {
                            width: parent.width
                            spacing: Theme.paddingSmall
                            Text { text: "⚠️"; font.pixelSize: 20 }
                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                color: Theme.textPrimary
                                font.pixelSize: 13
                                text: (page.stats.productosBajoStock || 0) + " producto(s) por debajo del mínimo. Reponlos pronto."
                            }
                        }
                    }

                    SectionHeader { titulo: "Productos"; subtitulo: page.lista.length + " en catálogo" }

                    Repeater {
                        model: page.lista
                        delegate: AppCard {
                            required property var modelData
                            readonly property bool bajo: (modelData.cantidadStock || 0) <= (modelData.cantidadMinima || 0)
                            Layout.fillWidth: true
                            RowLayout {
                                width: parent.width
                                spacing: Theme.paddingSmall

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    RowLayout {
                                        spacing: 6
                                        Text {
                                            text: modelData.nombre || ""
                                            font.pixelSize: 15; font.bold: true; color: Theme.textPrimary
                                            elide: Text.ElideRight; Layout.maximumWidth: 160
                                        }
                                        Rectangle {
                                            visible: bajo
                                            radius: 4; color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
                                            implicitWidth: bajoTxt.implicitWidth + 10; implicitHeight: bajoTxt.implicitHeight + 4
                                            Text { id: bajoTxt; anchors.centerIn: parent; text: "bajo"; font.pixelSize: 10; font.bold: true; color: Theme.error }
                                        }
                                    }
                                    Text {
                                        text: (modelData.categoria || "") + " · " + AppConfig.moneda(modelData.costoUnitario || 0) + " c/u"
                                        font.pixelSize: 12; color: Theme.textSecondary
                                    }
                                    Text {
                                        text: "Mínimo: " + (modelData.cantidadMinima || 0)
                                              + (modelData.proveedor ? " · " + modelData.proveedor : "")
                                        font.pixelSize: 11; color: Theme.textSecondary
                                    }
                                }

                                // Control de stock
                                RowLayout {
                                    spacing: 4
                                    RoundButton {
                                        implicitWidth: 34; implicitHeight: 34
                                        text: "−"; font.pixelSize: 18
                                        flat: true
                                        Material.foreground: Theme.primary
                                        onClicked: Inventario.disminuirStock(modelData.id, 1)
                                    }
                                    Text {
                                        text: String(modelData.cantidadStock || 0)
                                        font.pixelSize: 18; font.bold: true
                                        color: bajo ? Theme.error : Theme.textPrimary
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.minimumWidth: 28
                                    }
                                    RoundButton {
                                        implicitWidth: 34; implicitHeight: 34
                                        text: "+"; font.pixelSize: 16
                                        flat: true
                                        Material.foreground: Theme.primary
                                        onClicked: Inventario.aumentarStock(modelData.id, 1)
                                    }
                                }

                                ToolButton {
                                    text: "✎"; font.pixelSize: 15
                                    Material.foreground: Theme.primary
                                    onClicked: stack.push(formComp, { producto: modelData })
                                }
                            }
                        }
                    }

                    EmptyState {
                        Layout.fillWidth: true
                        visible: page.lista.length === 0
                        icono: "📦"
                        mensaje: "Sin productos"
                        detalle: "Agrega productos para controlar tu stock y su costo."
                    }
                }
            }

            RoundButton {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Theme.paddingLarge
                text: "+"
                font.pixelSize: 26
                Material.foreground: "white"
                background: Rectangle { radius: width / 2; color: Theme.primary }
                onClicked: stack.push(formComp, {})
            }
        }
    }

    Component { id: formComp; ProductoForm {} }

    component Stat: AppCard {
        property string icono: ""
        property string titulo: ""
        property string valor: ""
        property color acento: Theme.primary
        Layout.fillWidth: true
        implicitHeight: 88
        color: Qt.rgba(acento.r, acento.g, acento.b, Theme.dark ? 0.18 : 0.10)
        border.color: Qt.rgba(acento.r, acento.g, acento.b, 0.35)
        ColumnLayout {
            width: parent.width
            spacing: 2
            RowLayout {
                spacing: 6
                Text { text: icono; font.pixelSize: 16 }
                Text { text: titulo; font.pixelSize: 12; color: Theme.textSecondary; Layout.fillWidth: true }
            }
            Text {
                text: valor; font.pixelSize: 20; font.bold: true; color: acento
                Layout.fillWidth: true; elide: Text.ElideRight
            }
        }
    }
}
