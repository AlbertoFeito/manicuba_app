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
    // Nodos "Pantalla" en el mismo orden que "pantallas" (índice = navIndex),
    // para que el botón atrás pueda alcanzar la pestaña activa sin importar
    // cuál sea.
    readonly property list<Item> pantallasNodos: [
        homeTab, agendaTab, clientesTab, finanzasTab,
        serviciosTab, inventarioTab, redesTab, galeriaTab
    ]

    // Botón/gesto atrás de Android: primero intenta cerrar lo que haya
    // apilado dentro de la pestaña activa (formulario, detalle, visor de
    // foto); si no hay nada que cerrar y no estamos en Inicio, va a Inicio;
    // si ya estamos en Inicio, deja que quien llama decida (doble toque).
    function volverAtras() {
        const pantalla = win.pantallasNodos[win.navIndex] ? win.pantallasNodos[win.navIndex].item : null
        if (pantalla && typeof pantalla.volver === "function" && pantalla.volver())
            return true
        if (win.navIndex !== 0) {
            win.navIndex = 0
            return true
        }
        return false
    }

    onClosing: (close) => {
        close.accepted = false
        if (win.volverAtras())
            return
        // Ya en Inicio sin nada que cerrar: hace falta un segundo toque.
        if (salirTimer.running) {
            close.accepted = true
        } else {
            salirTimer.restart()
            toast.mostrar("Toca atrás de nuevo para salir")
        }
    }

    Timer { id: salirTimer; interval: 2000 }

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
                    if (ayudaLoader.item)
                        ayudaLoader.item.open()
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
    //
    // "clave" se enlaza con Qt.binding() en vez de asignarse una sola vez, así
    // siempre sigue a la pestaña activa aunque el diálogo ya estuviera cargado
    // de una visita anterior (no hace falta reasignarla en cada clic).
    Loader {
        id: ayudaLoader
        active: false
        source: "qrc:/qt/qml/ManiCuba/qml/AyudaDialog.qml"
        onLoaded: item.clave = Qt.binding(function () { return win.clavesAyuda[win.navIndex] })
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
                                Text {
                                    text: modelData.icono
                                    font.pixelSize: 20
                                    opacity: win.navIndex === index ? 1 : 0.6
                                }
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

                // Fundido suave al cambiar de pestaña en vez del cambio
                // instantáneo por defecto de StackLayout. "from: 0" hace que
                // cada vez que se reinicia, la opacidad salte a 0 y luego
                // suba a 1, sin necesidad de apagarla a mano primero.
                NumberAnimation {
                    id: fundidoPestana
                    target: contenido
                    property: "opacity"
                    from: 0; to: 1
                    duration: 150
                    easing.type: Easing.OutQuad
                }
                Connections {
                    target: win
                    function onNavIndexChanged() { fundidoPestana.restart() }
                }

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
                Pantalla { id: clientesTab; indice: 2; url: "qrc:/qt/qml/ManiCuba/qml/ClientesScreen.qml" }
                Pantalla { id: finanzasTab; indice: 3; url: "qrc:/qt/qml/ManiCuba/qml/FinanzasScreen.qml" }
                Pantalla { id: serviciosTab; indice: 4; url: "qrc:/qt/qml/ManiCuba/qml/ServiciosScreen.qml" }
                Pantalla { id: inventarioTab; indice: 5; url: "qrc:/qt/qml/ManiCuba/qml/InventarioScreen.qml" }
                Pantalla { id: redesTab; indice: 6; url: "qrc:/qt/qml/ManiCuba/qml/RedesScreen.qml" }
                Pantalla { id: galeriaTab; indice: 7; url: "qrc:/qt/qml/ManiCuba/qml/GaleriaScreen.qml" }
            }
        }
    }

    // Aviso breve para el doble-toque-para-salir (ver onClosing). Encima de
    // todo lo demás: declarado después de LicenciaGate en el orden de hijos.
    Rectangle {
        id: toast
        visible: opacity > 0
        opacity: 0
        radius: 8
        color: "#000000cc"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        width: toastTxt.implicitWidth + Theme.padding * 2
        height: toastTxt.implicitHeight + Theme.paddingSmall * 2

        Behavior on opacity { NumberAnimation { duration: 150 } }

        Text {
            id: toastTxt
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 13
        }

        Timer { id: toastTimer; interval: 1500; onTriggered: toast.opacity = 0 }

        function mostrar(texto) {
            toastTxt.text = texto
            opacity = 1
            toastTimer.restart()
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
                        opacity: activo ? 1 : 0.6
                        Layout.alignment: Qt.AlignHCenter
                        Behavior on opacity { NumberAnimation { duration: 120 } }
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
