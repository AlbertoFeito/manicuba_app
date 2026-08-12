import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Alta/edición de ingreso manual. Portado de
// lib/screens/finanzas/ingreso_form_screen.dart.
Page {
    id: page
    property var ingreso: ({})
    readonly property bool esEdicion: ingreso && ingreso.id !== undefined

    function fechaInicial() {
        return page.ingreso.fecha ? String(page.ingreso.fecha).substring(0, 10)
                                  : Qt.formatDate(new Date(), "yyyy-MM-dd")
    }

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        Material.foreground: "white"
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "‹"; font.pixelSize: 24; onClicked: page.StackView.view.pop() }
            Label {
                text: page.esEdicion ? "Editar ingreso" : "Nuevo ingreso"
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

            Text { text: "Monto *"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fMonto
                Layout.fillWidth: true
                text: page.ingreso.monto !== undefined ? String(page.ingreso.monto) : ""
                placeholderText: "0.00"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator { bottom: 0; decimals: 2; notation: DoubleValidator.StandardNotation }
                Material.accent: Theme.primary
            }

            Text { text: "Método de pago"; font.pixelSize: 13; color: Theme.textSecondary }
            ComboBox {
                id: cbMetodo
                Layout.fillWidth: true
                model: AppConfig.metodosPago
                Material.accent: Theme.primary
                Component.onCompleted: {
                    if (page.ingreso.metodo)
                        currentIndex = Math.max(0, model.indexOf(page.ingreso.metodo))
                }
            }

            Text { text: "Fecha"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fFecha
                Layout.fillWidth: true
                text: page.fechaInicial()
                placeholderText: "yyyy-MM-dd"
                Material.accent: Theme.primary
            }

            Text { text: "Notas"; font.pixelSize: 13; color: Theme.textSecondary }
            TextArea {
                id: fNotas
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                text: page.ingreso.notas || ""
                wrapMode: TextArea.Wrap
                Material.accent: Theme.primary
            }

            Text {
                id: error
                visible: false
                text: "Ingresa un monto válido y una fecha (yyyy-MM-dd)."
                color: Theme.error; font.pixelSize: 13; Layout.fillWidth: true
                wrapMode: Text.WordWrap
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
            text: page.esEdicion ? "Guardar cambios" : "Registrar ingreso"
            Material.background: Theme.primary
            Material.foreground: "white"
            background: Rectangle { color: Theme.primary; radius: 6 }
            onClicked: page.guardar()
        }
    }

    function guardar() {
        var monto = parseFloat(fMonto.text)
        if (isNaN(monto) || monto <= 0 || isNaN(Date.parse(fFecha.text.trim() + "T12:00:00"))) {
            error.visible = true
            return
        }
        var datos = {
            monto: monto,
            metodo: AppConfig.metodosPago[cbMetodo.currentIndex],
            fecha: fFecha.text.trim() + "T12:00:00",
            notas: fNotas.text.trim()
        }
        if (page.esEdicion) {
            datos.id = page.ingreso.id
            Finanzas.actualizarIngreso(datos)
        } else {
            Finanzas.registrarIngreso(datos)
        }
        page.StackView.view.pop()
    }

    Dialog {
        id: confirmar
        anchors.centerIn: parent
        modal: true
        title: "Eliminar ingreso"
        standardButtons: Dialog.Cancel | Dialog.Yes
        Label { text: "¿Eliminar este ingreso?" }
        onAccepted: {
            Finanzas.eliminarIngreso(page.ingreso.id)
            page.StackView.view.pop()
        }
    }
}
