import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Inventario de productos: estadísticas, alerta de bajo stock y lista con
// control rápido de existencias. Portado de
// lib/screens/inventario/inventario_screen.dart.
Item {
    id: root

    // Usado por el botón atrás de Android (ver Main.qml).
    function volver() {
        if (stack.depth > 1) { stack.pop(); return true }
        return false
    }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: listaPage
    }

    Component {
        id: listaPage
        Page {
            id: page
            property var lista: []
            property var stats: ({})
            property var productoActivo: ({})

            function refrescar() {
                lista = Inventario.obtenerTodos()
                stats = Inventario.estadisticas()
            }
            Component.onCompleted: refrescar()
            Connections { target: Inventario; function onCambiado() { page.refrescar() } }

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: col.implicitHeight + Theme.paddingLarge + 72
                clip: true

                ColumnLayout {
                    id: col
                    width: parent.width - Theme.padding * 2
                    x: Theme.padding
                    y: Theme.padding
                    spacing: Theme.padding

                    // Estadísticas
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Theme.padding
                        rowSpacing: Theme.padding
                        Stat { icono: "📦"; titulo: "Productos"; valor: String(page.stats.totalProductos || 0); acento: Theme.info }
                        Stat { icono: "🛒"; titulo: "Comprado (30 días)"; valor: AppConfig.moneda(page.stats.compradoUltimoMes || 0); acento: Theme.primary }
                        Stat { icono: "💵"; titulo: "Valor total"; valor: AppConfig.moneda(page.stats.valorTotal || 0); acento: Theme.success }
                        Stat { icono: "⚠️"; titulo: "Bajo stock"; valor: String(page.stats.productosBajoStock || 0); acento: Theme.error }
                    }

                    // Alerta de bajo stock
                    AppCard {
                        Layout.fillWidth: true
                        visible: (page.stats.productosBajoStock || 0) > 0
                        RowLayout {
                            width: parent.width
                            spacing: Theme.paddingSmall
                            Text { text: "⚠️"; font.pixelSize: 20 }
                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                color: Theme.textPrimary
                                font.pixelSize: 13
                                text: (page.stats.productosBajoStock || 0) + " producto(s) por debajo del mínimo. Reponlos pronto."
                            }
                        }
                    }

                    SectionHeader { titulo: "Productos"; subtitulo: page.lista.length + " en catálogo" }

                    Repeater {
                        model: page.lista
                        delegate: AppCard {
                            id: itemProducto
                            required property var modelData
                            readonly property bool bajo: (modelData.cantidadStock || 0) <= (modelData.cantidadMinima || 0)
                            Layout.fillWidth: true
                            RowLayout {
                                width: parent.width
                                spacing: Theme.paddingSmall

                                Item {
                                    Layout.fillWidth: true
                                    implicitHeight: infoCol.implicitHeight

                                    ColumnLayout {
                                        id: infoCol
                                        anchors.fill: parent
                                        spacing: 2
                                        RowLayout {
                                            spacing: 6
                                            Text {
                                                text: itemProducto.modelData.nombre || ""
                                                font.pixelSize: 15; font.bold: true; color: Theme.textPrimary
                                                elide: Text.ElideRight; Layout.maximumWidth: 140
                                            }
                                            Rectangle {
                                                visible: itemProducto.bajo
                                                radius: 4; color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
                                                implicitWidth: bajoTxt.implicitWidth + 10; implicitHeight: bajoTxt.implicitHeight + 4
                                                Text { id: bajoTxt; anchors.centerIn: parent; text: "bajo"; font.pixelSize: 10; font.bold: true; color: Theme.error }
                                            }
                                        }
                                        Text {
                                            text: (itemProducto.modelData.categoria || "") + " · " + AppConfig.moneda(itemProducto.modelData.costoUnitario || 0) + " c/u"
                                            font.pixelSize: 12; color: Theme.textSecondary
                                        }
                                        Text {
                                            text: "Mínimo: " + (itemProducto.modelData.cantidadMinima || 0)
                                                  + (itemProducto.modelData.proveedor ? " · " + itemProducto.modelData.proveedor : "")
                                            font.pixelSize: 11; color: Theme.textSecondary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: stack.push(movimientosComp, { producto: itemProducto.modelData })
                                    }
                                }

                                // Control de stock: entra/sale por diálogo, con rastro.
                                RowLayout {
                                    spacing: 4
                                    ToolButton {
                                        implicitWidth: 34; implicitHeight: 34
                                        text: "−"; font.pixelSize: 18
                                        enabled: (itemProducto.modelData.cantidadStock || 0) > 0
                                        Material.foreground: Theme.primary
                                        onClicked: { page.productoActivo = itemProducto.modelData; dlgSalida.abrir() }
                                    }
                                    Text {
                                        text: String(itemProducto.modelData.cantidadStock || 0)
                                        font.pixelSize: 18; font.bold: true
                                        color: itemProducto.bajo ? Theme.error : Theme.textPrimary
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.minimumWidth: 28
                                    }
                                    ToolButton {
                                        implicitWidth: 34; implicitHeight: 34
                                        text: "+"; font.pixelSize: 16
                                        Material.foreground: Theme.primary
                                        onClicked: { page.productoActivo = itemProducto.modelData; dlgCompra.abrir() }
                                    }
                                }

                                ToolButton {
                                    text: "⋮"; font.pixelSize: 18
                                    Material.foreground: Theme.textSecondary
                                    onClicked: menuProducto.open()
                                    Menu {
                                        id: menuProducto
                                        MenuItem {
                                            text: "🕘  Ver historial"
                                            onTriggered: stack.push(movimientosComp, { producto: itemProducto.modelData })
                                        }
                                        MenuItem {
                                            text: "🔧  Corregir stock"
                                            onTriggered: { page.productoActivo = itemProducto.modelData; dlgCorreccion.abrir() }
                                        }
                                        MenuItem {
                                            text: "✏️  Editar"
                                            onTriggered: stack.push(formComp, { producto: itemProducto.modelData })
                                        }
                                        MenuItem {
                                            text: "🗑  Eliminar"
                                            onTriggered: { page.productoActivo = itemProducto.modelData; confirmarEliminar.open() }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    EmptyState {
                        Layout.fillWidth: true
                        visible: page.lista.length === 0
                        icono: "📦"
                        mensaje: "Sin productos"
                        detalle: "Agrega productos para controlar tu stock y su costo."
                    }
                }
            }

            RoundButton {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Theme.paddingLarge
                text: "+"
                font.pixelSize: 26
                Material.foreground: "white"
                background: Rectangle { radius: width / 2; color: Theme.primary }
                onClicked: stack.push(formComp, {})
            }

            // ----- Compra: sube stock, recalcula costo, genera el gasto -----
            Dialog {
                id: dlgCompra
                anchors.centerIn: parent
                modal: true
                width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 380)
                padding: Theme.padding
                title: "Comprar " + (page.productoActivo.nombre || "")

                function abrir() {
                    cCantidad.text = "1"
                    var sugerido = (page.productoActivo.costoUnitario || 0)
                    cTotal.text = sugerido > 0 ? sugerido.toFixed(2) : ""
                    cTotal.editadoAMano = false
                    cProveedor.text = page.productoActivo.proveedor || ""
                    cFecha.fecha = Qt.formatDate(new Date(), "yyyy-MM-dd")
                    open()
                }

                footer: DialogButtonBox {
                    Button { text: "Cancelar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
                    Button { text: "Registrar compra"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; Material.foreground: Theme.primary }
                }

                ColumnLayout {
                    width: dlgCompra.availableWidth
                    spacing: Theme.paddingSmall

                    Text { text: "Unidades que entran *"; font.pixelSize: 13; color: Theme.textSecondary }
                    TextField {
                        id: cCantidad
                        Layout.fillWidth: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 1; top: 999999 }
                        onTextChanged: if (!cTotal.editadoAMano) {
                            var sugerido = (parseInt(cCantidad.text) || 0) * (page.productoActivo.costoUnitario || 0)
                            cTotal.text = sugerido > 0 ? sugerido.toFixed(2) : ""
                        }
                    }

                    Text { text: "Total que pagaste *"; font.pixelSize: 13; color: Theme.textSecondary }
                    TextField {
                        id: cTotal
                        property bool editadoAMano: false
                        Layout.fillWidth: true
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator { bottom: 0; decimals: 2; notation: DoubleValidator.StandardNotation }
                        onTextEdited: editadoAMano = true
                    }
                    Text {
                        visible: (parseInt(cCantidad.text) || 0) > 0 && (parseFloat(cTotal.text) || 0) > 0
                        text: "Te sale a " + AppConfig.moneda((parseFloat(cTotal.text) || 0) / (parseInt(cCantidad.text) || 1)) + " cada una"
                        font.pixelSize: 11; color: Theme.textSecondary
                    }

                    Text { text: "Proveedor"; font.pixelSize: 13; color: Theme.textSecondary }
                    TextField { id: cProveedor; Layout.fillWidth: true }

                    SelectorFecha { id: cFecha; etiqueta: "Fecha de la compra" }
                }

                onAccepted: {
                    var cantidad = parseInt(cCantidad.text) || 0
                    var total = parseFloat(cTotal.text)
                    if (cantidad <= 0 || isNaN(total) || total < 0)
                        return
                    var gastoId = Inventario.registrarCompra({
                        productoId: page.productoActivo.id,
                        cantidad: cantidad,
                        totalPagado: total,
                        fecha: cFecha.fecha,
                        proveedor: cProveedor.text.trim()
                    })
                    page.refrescar()
                }
            }

            // ----- Salida: descuenta stock; no toca Finanzas -----
            Dialog {
                id: dlgSalida
                anchors.centerIn: parent
                modal: true
                width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 380)
                padding: Theme.padding
                title: "Descontar " + (page.productoActivo.nombre || "")

                readonly property var motivos: [
                    { id: "consumo", texto: "Consumo" },
                    { id: "rotura", texto: "Rotura o pérdida" },
                    { id: "vencido", texto: "Vencido" }
                ]

                function abrir() {
                    sCantidad.text = "1"
                    cbMotivo.currentIndex = 0
                    open()
                }

                footer: DialogButtonBox {
                    Button { text: "Cancelar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
                    Button { text: "Descontar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; Material.foreground: Theme.primary }
                }

                ColumnLayout {
                    width: dlgSalida.availableWidth
                    spacing: Theme.paddingSmall

                    Text {
                        text: "Unidades que salen * · Tienes " + (page.productoActivo.cantidadStock || 0)
                        font.pixelSize: 13; color: Theme.textSecondary
                        wrapMode: Text.WordWrap
                    }
                    TextField {
                        id: sCantidad
                        Layout.fillWidth: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 1; top: 999999 }
                    }

                    Text { text: "Motivo"; font.pixelSize: 13; color: Theme.textSecondary }
                    ComboBox {
                        id: cbMotivo
                        Layout.fillWidth: true
                        model: dlgSalida.motivos.map(function (m) { return m.texto })
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11; color: Theme.textSecondary
                        text: "Esto no genera ningún gasto: ese dinero salió cuando compraste el producto."
                    }
                }

                onAccepted: {
                    var cantidad = parseInt(sCantidad.text) || 0
                    if (cantidad <= 0)
                        return
                    Inventario.registrarSalida({
                        productoId: page.productoActivo.id,
                        cantidad: cantidad,
                        motivo: dlgSalida.motivos[cbMotivo.currentIndex].id
                    })
                    page.refrescar()
                }
            }

            // ----- Corrección: cuadra stock/costo tras un conteo físico -----
            Dialog {
                id: dlgCorreccion
                anchors.centerIn: parent
                modal: true
                width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 380)
                padding: Theme.padding
                title: "Corregir stock"

                function abrir() {
                    rStock.text = String(page.productoActivo.cantidadStock || 0)
                    rCosto.text = (page.productoActivo.costoUnitario || 0).toFixed(2)
                    open()
                }

                footer: DialogButtonBox {
                    Button { text: "Cancelar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
                    Button { text: "Corregir"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; Material.foreground: Theme.primary }
                }

                ColumnLayout {
                    width: dlgCorreccion.availableWidth
                    spacing: Theme.paddingSmall

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.pixelSize: 12; color: Theme.textSecondary
                        text: "Cuenta lo que tienes de verdad y escríbelo aquí. Se usa para cuadrar el inventario, no cambia tus finanzas."
                    }

                    Text {
                        text: "Unidades reales * · la app tiene apuntadas " + (page.productoActivo.cantidadStock || 0)
                        font.pixelSize: 13; color: Theme.textSecondary
                        wrapMode: Text.WordWrap
                    }
                    TextField {
                        id: rStock
                        Layout.fillWidth: true
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 0; top: 999999 }
                    }

                    Text { text: "Costo unitario * · corrígelo solo si lo tecleaste mal"; font.pixelSize: 13; color: Theme.textSecondary; wrapMode: Text.WordWrap }
                    TextField {
                        id: rCosto
                        Layout.fillWidth: true
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator { bottom: 0; decimals: 2; notation: DoubleValidator.StandardNotation }
                    }
                }

                onAccepted: {
                    var cambio = Inventario.registrarCorreccion({
                        productoId: page.productoActivo.id,
                        nuevoStock: parseInt(rStock.text) || 0,
                        nuevoCosto: parseFloat(rCosto.text)
                    })
                    page.refrescar()
                }
            }

            Dialog {
                id: confirmarEliminar
                anchors.centerIn: parent
                modal: true
                width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 360)
                title: "Eliminar producto"
                footer: DialogButtonBox {
                    Button { text: "Cancelar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
                    Button { text: "Eliminar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; Material.foreground: Theme.error }
                }
                Label {
                    width: confirmarEliminar.availableWidth
                    wrapMode: Text.WordWrap
                    text: "¿Eliminar \"" + (page.productoActivo.nombre || "") + "\" del inventario?\n\nSe borra el producto y su historial. Los gastos de sus compras se quedan en Finanzas, porque ese dinero salió de verdad."
                }
                onAccepted: Inventario.eliminar(page.productoActivo.id)
            }
        }
    }

    Component { id: formComp; ProductoForm {} }
    Component { id: movimientosComp; MovimientosScreen {} }

    component Stat: AppCard {
        property string icono: ""
        property string titulo: ""
        property string valor: ""
        property color acento: Theme.primary
        Layout.fillWidth: true
        implicitHeight: 88
        color: Qt.rgba(acento.r, acento.g, acento.b, Theme.dark ? 0.18 : 0.10)
        border.color: Qt.rgba(acento.r, acento.g, acento.b, 0.35)
        ColumnLayout {
            width: parent.width
            spacing: 2
            RowLayout {
                spacing: 6
                Text { text: icono; font.pixelSize: 16 }
                Text { text: titulo; font.pixelSize: 12; color: Theme.textSecondary; Layout.fillWidth: true }
            }
            Text {
                text: valor; font.pixelSize: 20; font.bold: true; color: acento
                Layout.fillWidth: true; elide: Text.ElideRight
            }
        }
    }
}
