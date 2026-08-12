import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Nota: las pantallas y el diálogo de ayuda NO se importan por tipo aquí a
// propósito (ver "Pantalla" más abajo). Referenciar un tipo por nombre obliga
// al motor QML a resolverlo al compilar ESTE documento: si ese tipo falla
// (p. ej. en Android), toda la ventana deja de crearse. Cargándolos por URL
// con Loader.source, el fallo queda contenido en su Loader.

ApplicationWindow {
    id: win
    width: 420
    height: 820
    visible: true
    title: "ManiCuba Qt 💅"

    Material.theme: Theme.dark ? Material.Dark : Material.Light
    Material.primary: Theme.primary
    Material.accent: Theme.primary
    color: Theme.background

    // Navegación adaptativa: panel lateral en pantallas anchas, barra inferior
    // en pantallas estrechas (móvil).
    readonly property bool anchoEscritorio: width >= 900
    property int navIndex: 0

    // Orden de las pantallas en el StackLayout (índice = posición).
    readonly property var pantallas: [
        { icono: "🏠", texto: "Inicio" },      // 0
        { icono: "📅", texto: "Agenda" },      // 1
        { icono: "👥", texto: "Clientes" },    // 2
        { icono: "💰", texto: "Finanzas" },    // 3
        { icono: "💅", texto: "Servicios" },   // 4
        { icono: "📦", texto: "Inventario" },  // 5
        { icono: "📣", texto: "Redes" },       // 6
        { icono: "📸", texto: "Galería" }      // 7
    ]
    // Pestañas de la barra inferior (móvil): un subconjunto curado.
    readonly property var tabsMovil: [0, 1, 2, 3, 6]
    // Clave de ayuda por pantalla (mismo orden que "pantallas").
    readonly property var clavesAyuda: [
        "inicio", "agenda", "clientes", "finanzas", "servicios", "inventario", "redes", "galeria"
    ]

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        Material.foreground: "white"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.padding
            anchors.rightMargin: Theme.paddingSmall
            Label {
                text: win.pantallas[win.navIndex].texto
                font.pixelSize: 20
                font.bold: true
                color: "white"
                Layout.fillWidth: true
            }
            ToolButton {
                text: "?"
                font.pixelSize: 20; font.bold: true
                onClicked: {
                    ayudaLoader.active = true
                    if (ayudaLoader.item) {
                        ayudaLoader.item.clave = win.clavesAyuda[win.navIndex]
                        ayudaLoader.item.open()
                    }
                }
            }
            ToolButton {
                text: Theme.dark ? "☀️" : "🌙"
                font.pixelSize: 18
                onClicked: Theme.toggle()
            }
            ToolButton {
                text: "⋮"
                font.pixelSize: 22
                onClicked: menu.open()
                Menu {
                    id: menu
                    y: parent.height
                    MenuItem { text: "💅  Servicios"; onTriggered: win.navIndex = 4 }
                    MenuItem { text: "📦  Inventario"; onTriggered: win.navIndex = 5 }
                    MenuItem { text: "📸  Galería"; onTriggered: win.navIndex = 7 }
                    MenuSeparator {}
                    MenuItem {
                        text: "🗂  Historial de citas"
                        onTriggered: {
                            win.navIndex = 1
                            agendaTab.activar()
                            if (agendaTab.item)
                                agendaTab.item.abrirHistorial()
                        }
                    }
                    MenuItem {
                        text: "🔑  Licencia"
                        onTriggered: gate.mostrarPanel = true
                    }
                }
            }
        }
    }

    // El diálogo de ayuda se carga de forma perezosa por URL (ver nota de los
    // imports): si AyudaDialog.qml fallara al cargar, solo se pierde el botón
    // "?" en vez de tumbar toda la app en el arranque.
    Loader {
        id: ayudaLoader
        active: false
        source: "qrc:/qt/qml/ManiCuba/qml/AyudaDialog.qml"
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
                        model: win.pantallas
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

            // Contenido. Cada pantalla se carga de forma perezosa (Loader) la
            // primera vez que se visita y permanece cargada. Así un fallo en una
            // pantalla concreta no impide arrancar la app: se aísla y se muestra
            // el error dentro de esa pestaña en lugar de cerrar todo.
            StackLayout {
                id: contenido
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: win.navIndex

                Pantalla {
                    id: homeTab
                    indice: 0
                    url: "qrc:/qt/qml/ManiCuba/qml/HomeScreen.qml"
                    Connections {
                        target: homeTab.item
                        function onIrA(indice) { win.navIndex = indice }
                    }
                }
                Pantalla { id: agendaTab; indice: 1; url: "qrc:/qt/qml/ManiCuba/qml/AgendaScreen.qml" }
                Pantalla { indice: 2; url: "qrc:/qt/qml/ManiCuba/qml/ClientesScreen.qml" }
                Pantalla { indice: 3; url: "qrc:/qt/qml/ManiCuba/qml/FinanzasScreen.qml" }
                Pantalla { indice: 4; url: "qrc:/qt/qml/ManiCuba/qml/ServiciosScreen.qml" }
                Pantalla { indice: 5; url: "qrc:/qt/qml/ManiCuba/qml/InventarioScreen.qml" }
                Pantalla { indice: 6; url: "qrc:/qt/qml/ManiCuba/qml/RedesScreen.qml" }
                Pantalla { indice: 7; url: "qrc:/qt/qml/ManiCuba/qml/GaleriaScreen.qml" }
            }
        }
    }

    // Barra inferior (móvil)
    footer: TabBar {
        visible: !win.anchoEscritorio
        height: visible ? implicitHeight : 0
        currentIndex: Math.max(0, win.tabsMovil.indexOf(win.navIndex))
        Material.background: Theme.surface
        Repeater {
            model: win.tabsMovil
            delegate: TabButton {
                required property var modelData   // índice de pantalla
                readonly property var info: win.pantallas[modelData]
                readonly property bool activo: win.navIndex === modelData
                onClicked: win.navIndex = modelData
                contentItem: ColumnLayout {
                    spacing: 2
                    Text {
                        text: info.icono
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: info.texto
                        font.pixelSize: 11
                        color: activo ? Theme.primary : Theme.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    // ----- Carga perezosa de pantallas -----
    //
    // Cada pestaña se instancia con un Loader la primera vez que se visita y
    // permanece cargada. Si una pantalla falla al crearse, se muestra el error
    // dentro de su pestaña (con el registro de diagnóstico) en lugar de cerrar
    // toda la app.
    component Pantalla: Item {
        id: pant
        property int indice: 0
        property url url: ""
        property alias item: loader.item

        function activar() { loader.active = true }

        Loader {
            id: loader
            anchors.fill: parent
            active: false
            source: pant.url

            Connections {
                target: win
                function onNavIndexChanged() {
                    if (win.navIndex === pant.indice)
                        loader.active = true
                }
            }
            Component.onCompleted: if (win.navIndex === pant.indice) loader.active = true
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: Theme.padding
            visible: loader.status === Loader.Error
            contentWidth: width
            contentHeight: errTxt.implicitHeight + 24
            clip: true
            Text {
                id: errTxt
                width: parent.width
                wrapMode: Text.WrapAnywhere
                color: Theme.textPrimary
                font.pixelSize: 13
                textFormat: Text.PlainText
                text: loader.status === Loader.Error
                      ? "No se pudo cargar esta pantalla.\n\n" + AppConfig.diagRegistro()
                      : ""
            }
        }
    }
}
