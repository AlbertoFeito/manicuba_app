import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Alta/edición de cliente. Portado de lib/screens/clientes/cliente_form_screen.dart.
Page {
    id: page
    property var cliente: ({})
    readonly property bool esEdicion: cliente && cliente.id !== undefined

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        Material.foreground: "white"
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "‹"; font.pixelSize: 24; onClicked: page.StackView.view.pop() }
            Label {
                text: page.esEdicion ? "Editar cliente" : "Nuevo cliente"
                font.pixelSize: 18; font.bold: true; color: "white"
                Layout.fillWidth: true
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

            Campo { id: fNombre; etiqueta: "Nombre *"; texto: page.cliente.nombre || "" }
            Campo {
                id: fTelefono; etiqueta: "Teléfono *"
                texto: page.cliente.telefono || ""
                placeholder: "+53 5555 5555"
                imHints: Qt.ImhDialableCharactersOnly
            }
            Campo { id: fEmail; etiqueta: "Email"; texto: page.cliente.email || "" }
            Campo { id: fDireccion; etiqueta: "Dirección"; texto: page.cliente.direccion || "" }
            Campo { id: fNotas; etiqueta: "Notas"; texto: page.cliente.notas || ""; multilinea: true }

            Text {
                id: error
                visible: false
                text: "Nombre y teléfono son obligatorios."
                color: Theme.error
                font.pixelSize: 13
                Layout.fillWidth: true
            }
        }
    }

    // Botón fijo (no dentro del Flickable): siempre visible, sin depender
    // de hacer scroll hasta el final del formulario.
    footer: Rectangle {
        color: Theme.surface
        implicitHeight: btnGuardar.implicitHeight + Theme.padding * 2

        Button {
            id: btnGuardar
            anchors.fill: parent
            anchors.margins: Theme.padding
            text: page.esEdicion ? "Guardar cambios" : "Crear cliente"
            Material.background: Theme.primary
            Material.foreground: "white"
            background: Rectangle { color: Theme.primary; radius: 6 }
            onClicked: page.guardar()
        }
    }

    function guardar() {
        if (fNombre.texto.trim().length === 0 || fTelefono.texto.trim().length === 0) {
            error.visible = true
            return
        }
        var datos = {
            nombre: fNombre.texto.trim(),
            telefono: fTelefono.texto.trim(),
            email: fEmail.texto.trim(),
            direccion: fDireccion.texto.trim(),
            notas: fNotas.texto.trim()
        }
        if (page.esEdicion) {
            datos.id = page.cliente.id
            datos.ultimaVisita = page.cliente.ultimaVisita || ""
            Clientes.actualizar(datos)
        } else {
            Clientes.crear(datos)
        }
        page.StackView.view.pop()
    }

    component Campo: ColumnLayout {
        id: campo
        property string etiqueta: ""
        property string texto: ""
        property string placeholder: ""
        property bool multilinea: false
        property int imHints: Qt.ImhNone
        Layout.fillWidth: true
        spacing: 4
        Text { text: campo.etiqueta; font.pixelSize: 13; color: Theme.textSecondary }
        Loader {
            Layout.fillWidth: true
            sourceComponent: campo.multilinea ? areaComp : fieldComp
        }
        Component {
            id: fieldComp
            TextField {
                Layout.fillWidth: true
                text: campo.texto
                placeholderText: campo.placeholder
                inputMethodHints: campo.imHints
                Material.accent: Theme.primary
                onTextChanged: campo.texto = text
            }
        }
        Component {
            id: areaComp
            TextArea {
                width: campo.width
                implicitHeight: 90
                text: campo.texto
                wrapMode: TextArea.Wrap
                Material.accent: Theme.primary
                onTextChanged: campo.texto = text
            }
        }
    }
}
