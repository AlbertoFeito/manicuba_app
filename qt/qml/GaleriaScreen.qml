import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import ManiCuba

// Galería de fotos de trabajo. Portado de
// lib/screens/galeria/galeria_screen.dart. Al agregar una foto se puede
// tomarla con la cámara del dispositivo (Camara.tomarFoto(), Android) o
// elegirla del selector del sistema (FileDialog, que en Android es su propia
// galería/Fotos).
Item {
    id: root

    property var fotos: []
    function refrescar() { fotos = Fotos.obtenerTodas() }
    Component.onCompleted: refrescar()
    Connections { target: Fotos; function onCambiado() { root.refrescar() } }

    // La app de Cámara del sistema corre fuera del proceso: no hay callback
    // de resultado sin una subclase Java propia, así que se recoge la foto
    // (si la hubo) en cuanto la app recupera el foco.
    Connections {
        target: Qt.application
        function onStateChanged() {
            if (Qt.application.state === Qt.ApplicationActive) {
                const ruta = Camara.recogerCaptura()
                if (ruta)
                    Fotos.guardarDesdeArchivo(ruta)
            }
        }
    }

    // Usado por el botón atrás de Android (ver Main.qml): cierra el visor de
    // foto si está abierto.
    function volver() {
        if (visor.visible) { visor.close(); return true }
        return false
    }

    FileDialog {
        id: selector
        title: "Elegir imagen"
        nameFilters: ["Imágenes (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: Fotos.guardarDesdeArchivo(selectedFile)
    }

    Menu {
        id: menuAgregar
        MenuItem {
            text: "📷  Tomar foto"
            visible: Qt.platform.os === "android"
            height: visible ? implicitHeight : 0
            onTriggered: Camara.tomarFoto()
        }
        MenuItem { text: "🖼  Elegir de la galería"; onTriggered: selector.open() }
    }

    GridView {
        id: grid
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall
        clip: true
        cellWidth: Math.floor(width / Math.max(2, Math.floor(width / 150)))
        cellHeight: cellWidth
        model: root.fotos
        bottomMargin: 88

        delegate: Item {
            required property var modelData
            width: grid.cellWidth
            height: grid.cellHeight
            Rectangle {
                anchors.fill: parent
                anchors.margins: 3
                radius: Theme.radius
                color: Theme.surfaceAlt
                clip: true
                Image {
                    anchors.fill: parent
                    source: modelData.url
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { visor.foto = modelData; visor.open() }
                }
            }
        }
    }

    EmptyState {
        anchors.centerIn: parent
        width: parent.width
        visible: root.fotos.length === 0
        icono: "📸"
        mensaje: "Galería vacía"
        detalle: "Agrega fotos de tus trabajos con el botón +."
    }

    RoundButton {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.paddingLarge
        text: "+"
        font.pixelSize: 26
        Material.foreground: "white"
        background: Rectangle { radius: width / 2; color: Theme.primary }
        onClicked: menuAgregar.open()
    }

    // Visor a pantalla completa con opción de eliminar
    Popup {
        id: visor
        property var foto: ({})
        anchors.centerIn: Overlay.overlay
        width: parent.width
        height: parent.height
        modal: true
        padding: 0
        background: Rectangle { color: Qt.rgba(0, 0, 0, 0.92) }

        Image {
            anchors.fill: parent
            anchors.margins: Theme.padding
            source: visor.foto.url || ""
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
        RowLayout {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Theme.padding
            spacing: Theme.paddingSmall
            RoundButton {
                text: "📤"; font.pixelSize: 16
                visible: Qt.platform.os === "android"
                background: Rectangle { radius: width / 2; color: Theme.surface }
                onClicked: Compartir.compartirFoto(visor.foto.rutaFoto)
            }
            RoundButton {
                text: "🗑"; font.pixelSize: 18
                background: Rectangle { radius: width / 2; color: Theme.error }
                onClicked: { Fotos.eliminar(visor.foto.id); visor.close() }
            }
            RoundButton {
                text: "✕"; font.pixelSize: 18
                background: Rectangle { radius: width / 2; color: Theme.surface }
                onClicked: visor.close()
            }
        }
        Text {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: Theme.paddingLarge
            visible: visor.foto.fecha !== undefined
            text: visor.foto.fecha ? Qt.formatDate(new Date(visor.foto.fecha), "dd/MM/yyyy") : ""
            color: "white"
            font.pixelSize: 13
        }
    }
}
