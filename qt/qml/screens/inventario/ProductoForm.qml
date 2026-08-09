import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Alta/edición de producto. Portado de
// lib/screens/inventario/producto_form_screen.dart.
Page {
    id: page
    property var producto: ({})
    readonly property bool esEdicion: producto && producto.id !== undefined

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "‹"; font.pixelSize: 24; onClicked: page.StackView.view.pop() }
            Label {
                text: page.esEdicion ? "Editar producto" : "Nuevo producto"
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
                text: page.producto.nombre || ""
                Material.accent: Theme.primary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Categoría"; font.pixelSize: 13; color: Theme.textSecondary }
                    ComboBox {
                        id: cbCategoria
                        Layout.fillWidth: true
                        model: Categorias.obtenerCategorias()
                        Material.accent: Theme.primary
                        Component.onCompleted: {
                            if (page.producto.categoria)
                                currentIndex = Math.max(0, model.indexOf(page.producto.categoria))
                        }
                    }
                }
                Button {
                    text: "＋"
                    Layout.alignment: Qt.AlignBottom
                    flat: true
                    Material.foreground: Theme.primary
                    onClicked: nuevaCat.open()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.padding
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Stock actual *"; font.pixelSize: 13; color: Theme.textSecondary }
                    TextField {
                        id: fStock
                        Layout.fillWidth: true
                        text: page.producto.cantidadStock !== undefined ? String(page.producto.cantidadStock) : "0"
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 0; top: 999999 }
                        Material.accent: Theme.primary
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Mínimo *"; font.pixelSize: 13; color: Theme.textSecondary }
                    TextField {
                        id: fMinimo
                        Layout.fillWidth: true
                        text: page.producto.cantidadMinima !== undefined ? String(page.producto.cantidadMinima) : "1"
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 0; top: 999999 }
                        Material.accent: Theme.primary
                    }
                }
            }

            Text { text: "Costo unitario *"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fCosto
                Layout.fillWidth: true
                text: page.producto.costoUnitario !== undefined ? String(page.producto.costoUnitario) : ""
                placeholderText: "0.00"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator { bottom: 0; decimals: 2; notation: DoubleValidator.StandardNotation }
                Material.accent: Theme.primary
            }

            Text { text: "Proveedor"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fProveedor
                Layout.fillWidth: true
                text: page.producto.proveedor || ""
                Material.accent: Theme.primary
            }

            Text {
                id: error
                visible: false
                text: "Completa nombre, stock, mínimo y un costo válido."
                color: Theme.error; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap
            }

            Button {
                Layout.fillWidth: true
                text: page.esEdicion ? "Guardar cambios" : "Crear producto"
                Material.foreground: "white"
                background: Rectangle { color: Theme.primary; radius: 6 }
                onClicked: page.guardar()
            }
        }
    }

    function guardar() {
        var costo = parseFloat(fCosto.text)
        if (fNombre.text.trim().length === 0 || isNaN(costo) || costo < 0
            || fStock.text.length === 0 || fMinimo.text.length === 0) {
            error.visible = true
            return
        }
        var datos = {
            nombre: fNombre.text.trim(),
            categoria: cbCategoria.currentText,
            cantidadStock: parseInt(fStock.text) || 0,
            cantidadMinima: parseInt(fMinimo.text) || 0,
            costoUnitario: costo,
            proveedor: fProveedor.text.trim()
        }
        if (page.esEdicion) {
            datos.id = page.producto.id
            Inventario.actualizar(datos)
        } else {
            Inventario.crear(datos)
        }
        page.StackView.view.pop()
    }

    Dialog {
        id: nuevaCat
        anchors.centerIn: parent
        modal: true
        title: "Nueva categoría"
        standardButtons: Dialog.Cancel | Dialog.Ok
        ColumnLayout {
            TextField { id: catField; Layout.fillWidth: true; placeholderText: "Nombre de la categoría"; Material.accent: Theme.primary }
        }
        onAccepted: {
            if (catField.text.trim().length > 0 && Categorias.agregarCategoria(catField.text.trim())) {
                cbCategoria.model = Categorias.obtenerCategorias()
                cbCategoria.currentIndex = cbCategoria.model.indexOf(catField.text.trim())
            }
            catField.text = ""
        }
    }

    Dialog {
        id: confirmar
        anchors.centerIn: parent
        modal: true
        title: "Eliminar producto"
        standardButtons: Dialog.Cancel | Dialog.Yes
        Label { text: "¿Eliminar este producto del inventario?" }
        onAccepted: {
            Inventario.eliminar(page.producto.id)
            page.StackView.view.pop()
        }
    }
}
