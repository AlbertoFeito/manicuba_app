import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Ficha del cliente con acciones de contacto e historial de citas.
// Portado de lib/screens/clientes/cliente_detail_screen.dart.
Page {
    id: page
    property int clienteId: -1
    property var cliente: ({})
    property var citas: []

    function refrescar() {
        cliente = Clientes.obtenerPorId(clienteId)
        citas = Citas.obtenerPorCliente(clienteId)
    }
    Component.onCompleted: refrescar()
    Connections { target: Clientes; function onCambiado() { page.refrescar() } }
    Connections { target: Citas; function onCambiado() { page.refrescar() } }

    function soloDigitos(t) { return (t || "").replace(/[^0-9]/g, "") }

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        Material.foreground: "white"
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "‹"; font.pixelSize: 24; onClicked: page.StackView.view.pop() }
            Label {
                text: page.cliente.nombre || "Cliente"
                font.pixelSize: 18; font.bold: true; color: "white"
                Layout.fillWidth: true; elide: Text.ElideRight
            }
            ToolButton {
                text: "✏️"; font.pixelSize: 18
                onClicked: page.StackView.view.push(formComp, { cliente: page.cliente })
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + Theme.paddingLarge
        clip: true

        ColumnLayout {
            id: col
            width: parent.width - Theme.padding * 2
            x: Theme.padding
            y: Theme.padding
            spacing: Theme.padding

            // Acciones de contacto
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.paddingSmall
                Contacto {
                    icono: "📞"; texto: "Llamar"
                    onClicked: Qt.openUrlExternally("tel:" + page.cliente.telefono)
                }
                Contacto {
                    icono: "💬"; texto: "WhatsApp"
                    onClicked: Qt.openUrlExternally("https://wa.me/" + page.soloDigitos(page.cliente.telefono))
                }
                Contacto {
                    icono: "✉️"; texto: "SMS"
                    onClicked: Qt.openUrlExternally("smsto:" + page.cliente.telefono)
                }
                Contacto {
                    icono: "📋"; texto: "Copiar"
                    onClicked: { Redes.copiar(page.cliente.telefono); toastCopiado.open() }
                }
            }

            AppCard {
                Layout.fillWidth: true
                ColumnLayout {
                    width: parent.width
                    spacing: Theme.paddingSmall
                    Dato { etiqueta: "Teléfono"; valor: page.cliente.telefono || "—" }
                    Dato { etiqueta: "Email"; valor: page.cliente.email || "—" }
                    Dato { etiqueta: "Dirección"; valor: page.cliente.direccion || "—" }
                    Dato { etiqueta: "Notas"; valor: page.cliente.notas || "—" }
                    Dato {
                        etiqueta: "Última visita"
                        valor: page.cliente.ultimaVisita
                               ? Qt.formatDate(new Date(page.cliente.ultimaVisita), "dd/MM/yyyy") : "—"
                    }
                }
            }

            SectionHeader { titulo: "Historial de citas"; subtitulo: page.citas.length + " en total" }

            Repeater {
                model: page.citas
                delegate: AppCard {
                    required property var modelData
                    Layout.fillWidth: true
                    RowLayout {
                        width: parent.width
                        spacing: Theme.paddingSmall
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: (modelData.nombreServicio || "Servicio") + " · "
                                      + AppConfig.moneda(modelData.monto || 0)
                                font.pixelSize: 14; font.bold: true; color: Theme.textPrimary
                            }
                            Text {
                                text: Qt.formatDateTime(new Date(modelData.fechaHora), "dd/MM/yyyy HH:mm")
                                font.pixelSize: 12; color: Theme.textSecondary
                            }
                        }
                        EstadoBadge { estado: modelData.estado || "pendiente" }
                    }
                }
            }

        }
    }

    // Botón fijo (mismo patrón que Guardar/Crear en los formularios): no
    // depende de hacer scroll hasta el final para encontrarlo.
    footer: Rectangle {
        color: Theme.surface
        implicitHeight: btnEliminar.implicitHeight + Theme.padding * 2

        Button {
            id: btnEliminar
            anchors.fill: parent
            anchors.margins: Theme.padding
            text: "Eliminar cliente"
            flat: true
            Material.foreground: Theme.error
            onClicked: confirmar.open()
        }
    }

    Dialog {
        id: confirmar
        anchors.centerIn: parent
        modal: true
        width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 360)
        title: "Eliminar cliente"
        footer: DialogButtonBox {
            Button { text: "Cancelar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
            Button { text: "Eliminar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; Material.foreground: Theme.error }
        }
        Label { text: "¿Seguro que deseas eliminar a " + (page.cliente.nombre || "") + "?" }
        onAccepted: {
            if (Clientes.eliminar(page.clienteId))
                page.StackView.view.pop()
            else
                avisoNoSePuede.open()
        }
    }

    Popup {
        id: toastCopiado
        x: (page.width - width) / 2
        y: page.height - height - Theme.paddingLarge * 3
        closePolicy: Popup.NoAutoClose
        background: Rectangle { color: "#333333"; radius: 8 }
        contentItem: Label { text: "Teléfono copiado"; color: "white"; padding: 10 }
        Timer { interval: 1500; running: toastCopiado.visible; onTriggered: toastCopiado.close() }
    }

    Dialog {
        id: avisoNoSePuede
        anchors.centerIn: parent
        modal: true
        width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 340)
        title: "No se puede eliminar"
        footer: DialogButtonBox {
            Button { text: "Entendido"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole }
        }
        Label {
            width: avisoNoSePuede.availableWidth
            wrapMode: Text.WordWrap
            text: "Este cliente tiene citas completadas en su historial, así que no se puede eliminar."
        }
    }

    Component { id: formComp; ClienteForm {} }

    component Contacto: Button {
        property string icono: ""
        property string texto: ""
        Layout.fillWidth: true
        implicitHeight: 60
        background: Rectangle {
            color: Theme.surface
            radius: Theme.radius
            border.color: Qt.rgba(0, 0, 0, 0.08)
            border.width: 1
        }
        contentItem: ColumnLayout {
            spacing: 2
            Text { text: icono; font.pixelSize: 20; Layout.alignment: Qt.AlignHCenter }
            Text { text: texto; font.pixelSize: 12; color: Theme.textPrimary; Layout.alignment: Qt.AlignHCenter }
        }
    }

    component Dato: RowLayout {
        property string etiqueta: ""
        property string valor: ""
        Layout.fillWidth: true
        spacing: Theme.paddingSmall
        Text { text: etiqueta; font.pixelSize: 13; color: Theme.textSecondary; Layout.preferredWidth: 110 }
        Text {
            text: valor; font.pixelSize: 14; color: Theme.textPrimary
            Layout.fillWidth: true; wrapMode: Text.WordWrap
        }
    }
}
