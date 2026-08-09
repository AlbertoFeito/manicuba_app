import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Alta/edición de gasto. Portado de lib/screens/finanzas/gasto_form_screen.dart.
Page {
    id: page
    property var gasto: ({})
    readonly property bool esEdicion: gasto && gasto.id !== undefined

    function fechaInicial() {
        return page.gasto.fecha ? String(page.gasto.fecha).substring(0, 10)
                                : Qt.formatDate(new Date(), "yyyy-MM-dd")
    }

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "‹"; font.pixelSize: 24; onClicked: page.StackView.view.pop() }
            Label {
                text: page.esEdicion ? "Editar gasto" : "Nuevo gasto"
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

            Text { text: "Concepto *"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fConcepto
                Layout.fillWidth: true
                text: page.gasto.concepto || ""
                Material.accent: Theme.primary
            }

            Text { text: "Monto *"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fMonto
                Layout.fillWidth: true
                text: page.gasto.monto !== undefined ? String(page.gasto.monto) : ""
                placeholderText: "0.00"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator { bottom: 0; decimals: 2; notation: DoubleValidator.StandardNotation }
                Material.accent: Theme.primary
            }

            Text { text: "Categoría"; font.pixelSize: 13; color: Theme.textSecondary }
            ComboBox {
                id: cbCategoria
                Layout.fillWidth: true
                model: Categorias.obtenerCategorias()
                Material.accent: Theme.primary
                Component.onCompleted: {
                    if (page.gasto.categoria)
                        currentIndex = Math.max(0, model.indexOf(page.gasto.categoria))
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
                text: page.gasto.notas || ""
                wrapMode: TextArea.Wrap
                Material.accent: Theme.primary
            }

            Text {
                id: error
                visible: false
                text: "Completa concepto, un monto válido y una fecha (yyyy-MM-dd)."
                color: Theme.error; font.pixelSize: 13; Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Button {
                Layout.fillWidth: true
                text: page.esEdicion ? "Guardar cambios" : "Registrar gasto"
                Material.background: Theme.primary
                Material.foreground: "white"
                background: Rectangle { color: Theme.primary; radius: 6 }
                onClicked: page.guardar()
            }
        }
    }

    function guardar() {
        var monto = parseFloat(fMonto.text)
        if (fConcepto.text.trim().length === 0 || isNaN(monto) || monto <= 0
            || isNaN(Date.parse(fFecha.text.trim() + "T12:00:00"))) {
            error.visible = true
            return
        }
        var datos = {
            concepto: fConcepto.text.trim(),
            monto: monto,
            categoria: cbCategoria.currentText,
            fecha: fFecha.text.trim() + "T12:00:00",
            notas: fNotas.text.trim()
        }
        if (page.esEdicion) {
            datos.id = page.gasto.id
            Finanzas.actualizarGasto(datos)
        } else {
            Finanzas.registrarGasto(datos)
        }
        page.StackView.view.pop()
    }

    Dialog {
        id: confirmar
        anchors.centerIn: parent
        modal: true
        title: "Eliminar gasto"
        standardButtons: Dialog.Cancel | Dialog.Yes
        Label { text: "¿Eliminar este gasto?" }
        onAccepted: {
            Finanzas.eliminarGasto(page.gasto.id)
            page.StackView.view.pop()
        }
    }
}
