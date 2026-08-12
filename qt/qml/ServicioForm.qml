import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Alta/edición de servicio. Portado de lib/screens/servicios/servicio_form_screen.dart.
Page {
    id: page
    property var servicio: ({})
    readonly property bool esEdicion: servicio && servicio.id !== undefined

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        Material.foreground: "white"
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "‹"; font.pixelSize: 24; onClicked: page.StackView.view.pop() }
            Label {
                text: page.esEdicion ? "Editar servicio" : "Nuevo servicio"
                font.pixelSize: 18; font.bold: true; color: "white"
                Layout.fillWidth: true
            }
            ToolButton {
                visible: page.esEdicion
                text: "🗑"; font.pixelSize: 16
                onClicked: confirmar.open()
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: form.implicitHeight + Theme.paddingLarge * 2
        clip: true

        ColumnLayout {
            id: form
            width: parent.width - Theme.padding * 2
            x: Theme.padding
            y: Theme.padding
            spacing: Theme.padding

            Text { text: "Nombre *"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fNombre
                Layout.fillWidth: true
                text: page.servicio.nombre || ""
                Material.accent: Theme.primary
            }

            Text { text: "Precio *"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fPrecio
                Layout.fillWidth: true
                text: page.servicio.precio !== undefined ? String(page.servicio.precio) : ""
                placeholderText: "0.00"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator { bottom: 0; decimals: 2; notation: DoubleValidator.StandardNotation }
                Material.accent: Theme.primary
            }

            Text { text: "Duración (minutos) *"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fDuracion
                Layout.fillWidth: true
                text: page.servicio.duracionMinutos !== undefined ? String(page.servicio.duracionMinutos) : "30"
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 1; top: 600 }
                Material.accent: Theme.primary
            }

            Text { text: "Descripción"; font.pixelSize: 13; color: Theme.textSecondary }
            TextArea {
                id: fDescripcion
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                text: page.servicio.descripcion || ""
                wrapMode: TextArea.Wrap
                Material.accent: Theme.primary
            }

            Text {
                id: error
                visible: false
                text: "Nombre, precio y duración son obligatorios."
                color: Theme.error; font.pixelSize: 13; Layout.fillWidth: true
            }
        }
    }

    // Botón fijo (no dentro del Flickable): siempre visible.
    footer: Rectangle {
        color: Theme.surface
        implicitHeight: btnGuardar.implicitHeight + Theme.padding * 2

        Button {
            id: btnGuardar
            anchors.fill: parent
            anchors.margins: Theme.padding
            text: page.esEdicion ? "Guardar cambios" : "Crear servicio"
            Material.background: Theme.primary
            Material.foreground: "white"
            background: Rectangle { color: Theme.primary; radius: 6 }
            onClicked: page.guardar()
        }
    }

    function guardar() {
        var precio = parseFloat(fPrecio.text)
        var dur = parseInt(fDuracion.text)
        if (fNombre.text.trim().length === 0 || isNaN(precio) || isNaN(dur) || dur <= 0) {
            error.visible = true
            return
        }
        var datos = {
            nombre: fNombre.text.trim(),
            precio: precio,
            duracionMinutos: dur,
            descripcion: fDescripcion.text.trim()
        }
        if (page.esEdicion) {
            datos.id = page.servicio.id
            Servicios.actualizar(datos)
        } else {
            Servicios.crear(datos)
        }
        page.StackView.view.pop()
    }

    Dialog {
        id: confirmar
        anchors.centerIn: parent
        modal: true
        title: "Eliminar servicio"
        footer: DialogButtonBox {
            Button { text: "Cancelar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
            Button { text: "Eliminar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; Material.foreground: Theme.error }
        }
        Label { text: "¿Eliminar este servicio del catálogo?" }
        onAccepted: {
            Servicios.eliminar(page.servicio.id)
            page.StackView.view.pop()
        }
    }
}
