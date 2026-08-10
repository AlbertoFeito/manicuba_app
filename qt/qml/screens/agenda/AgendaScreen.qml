import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Agenda por día: navega fechas y muestra las citas activas del día.
// Portado de lib/screens/agenda/agenda_screen.dart.
Item {
    id: root

    function abrirHistorial() { stack.push(histComp) }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: agendaPage
    }

    Component {
        id: agendaPage
        Page {
            id: page
            property var fechaSel: new Date()
            property var citas: []

            function fechaStr() { return Qt.formatDate(fechaSel, "yyyy-MM-dd") }
            function refrescar() { citas = Citas.activasPorFecha(fechaStr()) }
            function moverDia(d) {
                var nueva = new Date(fechaSel)
                nueva.setDate(nueva.getDate() + d)
                fechaSel = nueva
                refrescar()
            }
            Component.onCompleted: refrescar()
            Connections { target: Citas; function onCambiado() { page.refrescar() } }

            header: Pane {
                Material.elevation: 0
                Material.foreground: Theme.primary
                RowLayout {
                    anchors.fill: parent
                    ToolButton { text: "‹"; font.pixelSize: 22; onClicked: page.moverDia(-1) }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: Qt.formatDate(page.fechaSel, "dddd")
                            font.pixelSize: 13; color: Theme.textSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: Qt.formatDate(page.fechaSel, "d 'de' MMMM yyyy")
                            font.pixelSize: 16; font.bold: true; color: Theme.textPrimary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    ToolButton { text: "›"; font.pixelSize: 22; onClicked: page.moverDia(1) }
                    ToolButton {
                        text: "Hoy"; font.pixelSize: 13
                        onClicked: { page.fechaSel = new Date(); page.refrescar() }
                    }
                }
            }

            ListView {
                anchors.fill: parent
                model: page.citas
                spacing: 6
                clip: true
                topMargin: Theme.paddingSmall
                bottomMargin: 88

                delegate: ItemDelegate {
                    required property var modelData
                    width: ListView.view.width
                    onClicked: stack.push(citaFormComp, { cita: modelData, fechaDefault: page.fechaStr() })
                    contentItem: RowLayout {
                        spacing: Theme.padding
                        ColumnLayout {
                            spacing: 0
                            Text {
                                text: Qt.formatDateTime(new Date(modelData.fechaHora), "HH:mm")
                                font.pixelSize: 18; font.bold: true; color: Theme.primary
                            }
                            Text {
                                text: (modelData.duracionMinutos || 0) + " min"
                                font.pixelSize: 11; color: Theme.textSecondary
                            }
                        }
                        Rectangle { width: 1; Layout.fillHeight: true; color: Theme.divider }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: modelData.nombreCliente || "Cliente"
                                font.pixelSize: 15; font.bold: true; color: Theme.textPrimary
                                Layout.fillWidth: true; elide: Text.ElideRight
                            }
                            Text {
                                text: (modelData.nombreServicio || "Servicio") + " · "
                                      + AppConfig.moneda(modelData.monto || 0)
                                font.pixelSize: 13; color: Theme.textSecondary
                            }
                        }
                        EstadoBadge { estado: modelData.estado || "pendiente" }
                    }
                }

                EmptyState {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: page.citas.length === 0
                    icono: "📅"
                    mensaje: "Sin citas este día"
                    detalle: "Toca + para agendar una cita."
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
                onClicked: stack.push(citaFormComp, { fechaDefault: page.fechaStr() })
            }
        }
    }

    Component { id: citaFormComp; CitaForm {} }
    Component { id: histComp; HistorialScreen {} }
}
