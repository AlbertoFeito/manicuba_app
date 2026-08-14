import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Historial de entradas y salidas de un producto: responde cuánto se compró
// y cuánto se consumió, algo que antes no se podía saber porque el stock era
// un número que se sobreescribía. Portado de
// lib/screens/inventario/movimientos_screen.dart.
Page {
    id: page
    property var producto: ({})
    property var movimientos: []
    property var movimientoActivo: ({})
    property double compradoMes: 0
    property int consumidoMes: 0

    readonly property var etiquetasMotivo: ({
        compra: "Compra", saldo_inicial: "Stock inicial", consumo: "Consumo",
        rotura: "Rotura o pérdida", vencido: "Vencido", correccion: "Corrección de conteo"
    })

    function refrescar() {
        page.producto = Inventario.obtenerPorId(page.producto.id)
        page.movimientos = Inventario.movimientosDe(page.producto.id)
        const hoy = new Date()
        const desde = new Date(hoy.getTime() - 30 * 24 * 60 * 60 * 1000)
        let compraTot = 0, consumoTot = 0
        for (const m of page.movimientos) {
            const f = new Date(m.fecha)
            if (f < desde || f > hoy)
                continue
            if (m.tipo === "entrada" && m.gastoId)
                compraTot += (m.costoUnitario || 0) * m.cantidad
            if (m.tipo === "salida")
                consumoTot += m.cantidad
        }
        page.compradoMes = compraTot
        page.consumidoMes = consumoTot
    }
    Component.onCompleted: refrescar()
    Connections { target: Inventario; function onCambiado() { page.refrescar() } }

    function iconoDe(m) {
        if (m.tipo === "entrada") return m.gastoId ? "🛒" : "📦"
        if (m.tipo === "salida") return "📉"
        return "✅"
    }

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        Material.foreground: "white"
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "‹"; font.pixelSize: 24; onClicked: page.StackView.view.pop() }
            Label {
                text: page.producto.nombre || "Historial"
                font.pixelSize: 18; font.bold: true; color: "white"
                Layout.fillWidth: true; elide: Text.ElideRight
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.padding

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.padding
            spacing: Theme.paddingSmall
            Resumen { icono: "📦"; titulo: "En stock"; valor: String(page.producto.cantidadStock || 0); acento: Theme.primary }
            Resumen { icono: "🛒"; titulo: "Comprado (30 días)"; valor: AppConfig.moneda(page.compradoMes); acento: Theme.primary }
            Resumen { icono: "📉"; titulo: "Usado (30 días)"; valor: String(page.consumidoMes); acento: Theme.success }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: lista.implicitHeight + Theme.paddingLarge
            clip: true

            ColumnLayout {
                id: lista
                width: parent.width - Theme.padding * 2
                x: Theme.padding
                spacing: Theme.paddingSmall

                EmptyState {
                    Layout.fillWidth: true
                    visible: page.movimientos.length === 0
                    icono: "🕘"
                    mensaje: "Sin movimientos todavía"
                    detalle: "Aquí aparecerán las compras y las salidas de este producto."
                }

                Repeater {
                    model: page.movimientos
                    delegate: AppCard {
                        id: itemMovimiento
                        required property var modelData
                        readonly property bool sePuedeDeshacer: modelData.tipo === "entrada" || modelData.tipo === "salida"
                        Layout.fillWidth: true
                        RowLayout {
                            width: parent.width
                            spacing: Theme.paddingSmall
                            Text { text: page.iconoDe(modelData); font.pixelSize: 20 }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: (modelData.tipo === "salida" ? "−" : "+") + modelData.cantidad
                                          + " · " + (page.etiquetasMotivo[modelData.motivo] || modelData.motivo)
                                    font.pixelSize: 14; font.bold: true; color: Theme.textPrimary
                                }
                                Text {
                                    text: Qt.formatDateTime(new Date(modelData.fecha), "dd/MM/yyyy HH:mm")
                                          + (modelData.notas ? " · " + modelData.notas : "")
                                    font.pixelSize: 12; color: Theme.textSecondary
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                            Text {
                                visible: !!modelData.gastoId
                                text: AppConfig.moneda((modelData.costoUnitario || 0) * modelData.cantidad)
                                font.pixelSize: 13; font.bold: true; color: Theme.textPrimary
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: itemMovimiento.sePuedeDeshacer
                            onClicked: { page.movimientoActivo = itemMovimiento.modelData; confirmarDeshacer.open() }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: confirmarDeshacer
        anchors.centerIn: parent
        modal: true
        width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 360)
        title: "Deshacer movimiento"
        footer: DialogButtonBox {
            Button { text: "Cancelar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
            Button { text: "Deshacer"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; Material.foreground: Theme.error }
        }
        Label {
            width: confirmarDeshacer.availableWidth
            wrapMode: Text.WordWrap
            text: page.movimientoActivo.gastoId
                  ? "¿Deshacer esta compra de " + (page.movimientoActivo.cantidad || 0) + "? Se descuenta del stock y se borra su gasto de "
                    + AppConfig.moneda((page.movimientoActivo.costoUnitario || 0) * (page.movimientoActivo.cantidad || 0)) + " en Finanzas."
                  : "¿Deshacer esta salida de " + (page.movimientoActivo.cantidad || 0) + "? Las unidades vuelven al stock."
        }
        onAccepted: {
            const resultado = Inventario.deshacerMovimiento(page.movimientoActivo.id)
            avisoTexto.text = resultado === "ok" ? "Movimiento deshecho"
                : resultado === "no_se_puede" ? "No se puede: ya gastaste parte de esas unidades. Corrige el stock y borra el gasto a mano."
                : "No se pudo deshacer el movimiento."
            aviso.open()
            page.refrescar()
        }
    }

    Dialog {
        id: aviso
        anchors.centerIn: parent
        modal: true
        width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 340)
        title: "Inventario"
        footer: DialogButtonBox {
            Button { text: "Entendido"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole }
        }
        Label { id: avisoTexto; width: aviso.availableWidth; wrapMode: Text.WordWrap }
    }

    component Resumen: AppCard {
        property string icono: ""
        property string titulo: ""
        property string valor: ""
        property color acento: Theme.primary
        Layout.fillWidth: true
        implicitHeight: 84
        color: Qt.rgba(acento.r, acento.g, acento.b, Theme.dark ? 0.18 : 0.10)
        border.color: Qt.rgba(acento.r, acento.g, acento.b, 0.35)
        ColumnLayout {
            width: parent.width
            spacing: 2
            Text { text: icono; font.pixelSize: 16; Layout.alignment: Qt.AlignHCenter }
            Text {
                text: valor; font.pixelSize: 15; font.bold: true; color: acento
                Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
            Text {
                text: titulo; font.pixelSize: 10; color: Theme.textSecondary
                Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}
