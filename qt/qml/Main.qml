import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

import "screens"
import "screens/clientes"
import "screens/servicios"
import "screens/finanzas"
import "screens/agenda"

ApplicationWindow {
    id: win
    width: 420
    height: 820
    visible: true
    title: "ManiCuba 💅"

    Material.theme: Material.Light
    Material.primary: Theme.primary
    Material.accent: Theme.primary

    // Navegación adaptativa: panel lateral en pantallas anchas, barra inferior
    // en pantallas estrechas (móvil).
    readonly property bool anchoEscritorio: width >= 900
    property int navIndex: 0

    readonly property var navItems: [
        { icono: "🏠", texto: "Inicio" },
        { icono: "📅", texto: "Agenda" },
        { icono: "👥", texto: "Clientes" },
        { icono: "💰", texto: "Finanzas" },
        { icono: "💅", texto: "Servicios" }
    ]

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.padding
            anchors.rightMargin: Theme.paddingSmall
            Label {
                text: win.navItems[win.navIndex].texto
                font.pixelSize: 20
                font.bold: true
                color: "white"
                Layout.fillWidth: true
            }
            ToolButton {
                text: "⋮"
                font.pixelSize: 22
                onClicked: menu.open()
                Menu {
                    id: menu
                    y: parent.height
                    MenuItem {
                        text: "Historial de citas"
                        onTriggered: { win.navIndex = 1; agendaTab.abrirHistorial() }
                    }
                    MenuItem {
                        text: "Licencia"
                        onTriggered: gate.mostrarPanel = true
                    }
                }
            }
        }
    }

    LicenciaGate {
        id: gate
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Panel lateral (escritorio)
            Rectangle {
                visible: win.anchoEscritorio
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                color: Theme.surface
                border.color: Theme.divider
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: Theme.padding
                    spacing: 4
                    Repeater {
                        model: win.navItems
                        delegate: ItemDelegate {
                            required property int index
                            required property var modelData
                            Layout.fillWidth: true
                            highlighted: win.navIndex === index
                            onClicked: win.navIndex = index
                            contentItem: RowLayout {
                                spacing: Theme.paddingSmall
                                Text { text: modelData.icono; font.pixelSize: 20 }
                                Text {
                                    text: modelData.texto
                                    font.pixelSize: 15
                                    font.bold: win.navIndex === index
                                    color: win.navIndex === index ? Theme.primary : Theme.textPrimary
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // Contenido
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: win.navIndex

                HomeScreen {
                    onIrA: function (indice) { win.navIndex = indice }
                }
                AgendaScreen { id: agendaTab }
                ClientesScreen {}
                FinanzasScreen {}
                ServiciosScreen {}
            }
        }
    }

    // Barra inferior (móvil)
    footer: TabBar {
        visible: !win.anchoEscritorio
        height: visible ? implicitHeight : 0
        currentIndex: win.navIndex
        Material.background: Theme.surface
        Repeater {
            model: win.navItems
            delegate: TabButton {
                required property var modelData
                required property int index
                onClicked: win.navIndex = index
                contentItem: ColumnLayout {
                    spacing: 2
                    Text {
                        text: modelData.icono
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: modelData.texto
                        font.pixelSize: 11
                        color: win.navIndex === index ? Theme.primary : Theme.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
