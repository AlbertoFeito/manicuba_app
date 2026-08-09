import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Panel de Inicio: resumen del día y accesos rápidos.
// Portado de la pestaña "Inicio" de lib/screens/home_screen.dart.
Item {
    id: root
    signal irA(int indice)

    function refrescar() {
        stCitas.valor = Citas.totalHoy()
        stIngresos.valor = AppConfig.moneda(Citas.ingresosHoy())
        stGastos.valor = AppConfig.moneda(Finanzas.gastoHoy())
        stBalance.valor = AppConfig.moneda(Finanzas.balanceHoy())
    }

    Component.onCompleted: refrescar()
    Connections { target: Citas; function onCambiado() { root.refrescar() } }
    Connections { target: Finanzas; function onCambiado() { root.refrescar() } }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + Theme.paddingLarge
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: Theme.padding

            Item { Layout.preferredHeight: Theme.paddingSmall }

            SectionHeader {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.padding
                Layout.rightMargin: Theme.padding
                titulo: "Resumen del día"
                subtitulo: Qt.formatDate(new Date(), "dddd d 'de' MMMM")
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.padding
                Layout.rightMargin: Theme.padding
                columns: 2
                columnSpacing: Theme.padding
                rowSpacing: Theme.padding

                StatCard {
                    id: stCitas
                    Layout.fillWidth: true
                    icono: "📅"; titulo: "Citas hoy"; valor: "0"; acento: Theme.info
                }
                StatCard {
                    id: stIngresos
                    Layout.fillWidth: true
                    icono: "💰"; titulo: "Ingresos"; valor: "$0.00"; acento: Theme.success
                }
                StatCard {
                    id: stGastos
                    Layout.fillWidth: true
                    icono: "🧾"; titulo: "Gastos"; valor: "$0.00"; acento: Theme.error
                }
                StatCard {
                    id: stBalance
                    Layout.fillWidth: true
                    icono: "⚖️"; titulo: "Balance"; valor: "$0.00"; acento: Theme.primary
                }
            }

            SectionHeader {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.padding
                Layout.rightMargin: Theme.padding
                titulo: "Accesos rápidos"
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.padding
                Layout.rightMargin: Theme.padding
                columns: 2
                columnSpacing: Theme.padding
                rowSpacing: Theme.padding

                AccionRapida {
                    Layout.fillWidth: true
                    icono: "➕"; texto: "Nueva cita"
                    onClicked: root.irA(1)
                }
                AccionRapida {
                    Layout.fillWidth: true
                    icono: "🧑"; texto: "Nuevo cliente"
                    onClicked: root.irA(2)
                }
                AccionRapida {
                    Layout.fillWidth: true
                    icono: "💅"; texto: "Servicios"
                    onClicked: root.irA(3)
                }
                AccionRapida {
                    Layout.fillWidth: true
                    icono: "🔑"; texto: "Licencia: " + (Licencia.estadoTipo === "activa"
                        ? "activa" : Licencia.diasRestantes + "d")
                    onClicked: proximamente.open()
                }
            }
        }
    }

    Dialog {
        id: proximamente
        anchors.centerIn: parent
        modal: true
        title: "Licencia"
        standardButtons: Dialog.Ok
        Label {
            text: Licencia.estadoTipo === "activa"
                  ? "Licencia activa. ¡Gracias!"
                  : "Prueba: quedan " + Licencia.diasRestantes + " días.\nAbre el menú (⋮) → Licencia para activar."
        }
    }

    // ----- Componentes locales -----

    component StatCard: AppCard {
        property string icono: ""
        property string titulo: ""
        property string valor: ""
        property color acento: Theme.primary
        implicitHeight: 96
        ColumnLayout {
            width: parent.width
            spacing: 4
            RowLayout {
                spacing: 6
                Text { text: icono; font.pixelSize: 18 }
                Text {
                    text: titulo
                    font.pixelSize: 13
                    color: Theme.textSecondary
                    Layout.fillWidth: true
                }
            }
            Text {
                text: valor
                font.pixelSize: 24
                font.bold: true
                color: acento
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }

    component AccionRapida: Button {
        property string icono: ""
        property string texto: ""
        implicitHeight: 72
        Material.background: Theme.surface
        Material.elevation: 1
        contentItem: ColumnLayout {
            spacing: 4
            Text {
                text: icono
                font.pixelSize: 22
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: texto
                font.pixelSize: 12
                color: Theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
