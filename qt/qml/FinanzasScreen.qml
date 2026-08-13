import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Finanzas: resumen (hero, dona de gastos, tendencia, movimientos) y analíticas
// (comparación con el periodo anterior, KPIs, métodos de pago, rankings).
// Portado de lib/screens/finanzas/finanzas_screen.dart.
Item {
    id: root

    readonly property var paleta: [
        "#E91E63", "#2196F3", "#FF9800", "#4CAF50", "#9C27B0", "#00BCD4", "#795548"
    ]
    readonly property var periodos: [
        { id: "hoy", texto: "Hoy" }, { id: "semana", texto: "Semana" },
        { id: "mes", texto: "Mes" }, { id: "todo", texto: "Todo" }
    ]

    // Usado por el botón atrás de Android (ver Main.qml).
    function volver() {
        if (stack.depth > 1) { stack.pop(); return true }
        return false
    }
    function abrirNuevoGasto() { stack.push(gastoFormComp) }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: mainPage
    }

    Component {
        id: mainPage
        Page {
            id: page
            property string periodo: "mes"
            property string vista: "resumen"

            property var k: ({})
            property var kAnt: ({})
            property real balHoy: 0
            property real balSem: 0
            property var movs: []
            property var cats: []
            property var metodos: []
            property var serie: []
            property var topServ: []
            property var topCli: []

            function refrescar() {
                k = Finanzas.kpis(periodo)
                kAnt = Finanzas.kpisAnterior(periodo)
                balHoy = Finanzas.balanceHoy()
                balSem = Finanzas.balanceSemana()
                movs = Finanzas.movimientos(periodo)
                cats = Finanzas.gastosPorCategoria(periodo)
                metodos = Finanzas.ingresosPorMetodo(periodo)
                var dias = Finanzas.diasTendencia(periodo)
                serie = dias > 0 ? Finanzas.serieDiaria(dias) : []
                topServ = Finanzas.topServicios(periodo)
                topCli = Finanzas.topClientes(periodo)
            }
            Component.onCompleted: refrescar()
            onPeriodoChanged: refrescar()
            Connections { target: Finanzas; function onCambiado() { page.refrescar() } }
            Connections { target: Citas; function onCambiado() { page.refrescar() } }

            header: Pane {
                Material.elevation: 0
                padding: Theme.paddingSmall
                ColumnLayout {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    // Selector de vista
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Repeater {
                            model: [{ id: "resumen", t: "Resumen" }, { id: "analiticas", t: "Analíticas" }]
                            delegate: Button {
                                required property var modelData
                                Layout.fillWidth: true
                                flat: page.vista !== modelData.id
                                text: modelData.t
                                Material.foreground: page.vista === modelData.id ? "white" : Theme.textPrimary
                                background: Rectangle {
                                    radius: 6
                                    color: page.vista === modelData.id ? Theme.primary : "transparent"
                                }
                                onClicked: page.vista = modelData.id
                            }
                        }
                    }
                    // Chips de periodo
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.paddingSmall
                        Repeater {
                            model: root.periodos
                            delegate: Button {
                                required property var modelData
                                Layout.fillWidth: true
                                text: modelData.texto
                                flat: page.periodo !== modelData.id
                                Material.foreground: page.periodo === modelData.id ? Theme.primary : Theme.textSecondary
                                background: Rectangle {
                                    radius: 16
                                    color: page.periodo === modelData.id
                                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"
                                }
                                onClicked: page.periodo = modelData.id
                            }
                        }
                    }
                }
            }

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: contenido.implicitHeight + Theme.paddingLarge + 72
                clip: true

                ColumnLayout {
                    id: contenido
                    width: parent.width - Theme.padding * 2
                    x: Theme.padding
                    y: Theme.padding
                    spacing: Theme.padding

                    // ================= RESUMEN =================
                    Loader {
                        Layout.fillWidth: true
                        active: page.vista === "resumen"
                        visible: active
                        sourceComponent: ColumnLayout {
                            width: contenido.width
                            spacing: Theme.padding

                            // Hero balance
                            AppCard {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    width: parent.width
                                    spacing: Theme.paddingSmall
                                    Text {
                                        text: "Balance del periodo"
                                        font.pixelSize: 13; color: Theme.textSecondary
                                    }
                                    Text {
                                        text: AppConfig.moneda(page.k.balance || 0)
                                        font.pixelSize: 32; font.bold: true
                                        color: (page.k.balance || 0) >= 0 ? Theme.success : Theme.error
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.padding
                                        Pill { etiqueta: "Ingresos"; valor: page.k.ingresos || 0; acento: Theme.success }
                                        Pill { etiqueta: "Gastos"; valor: page.k.gastos || 0; acento: Theme.error }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.padding
                                MiniBalance { etiqueta: "Balance hoy"; valor: page.balHoy }
                                MiniBalance { etiqueta: "Balance 7 días"; valor: page.balSem }
                            }

                            // Dona de gastos por categoría
                            AppCard {
                                Layout.fillWidth: true
                                visible: page.cats.length > 0
                                ColumnLayout {
                                    width: parent.width
                                    spacing: Theme.paddingSmall
                                    Text { text: "Gastos por categoría"; font.pixelSize: 15; font.bold: true; color: Theme.textPrimary }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Theme.padding
                                        DonutChart {
                                            Layout.preferredWidth: 150
                                            Layout.preferredHeight: 150
                                            model: page.cats
                                            palette: root.paleta
                                            centroTexto: AppConfig.moneda(page.k.gastos || 0)
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4
                                            Repeater {
                                                model: page.cats
                                                delegate: RowLayout {
                                                    required property var modelData
                                                    required property int index
                                                    Layout.fillWidth: true
                                                    spacing: 6
                                                    Rectangle {
                                                        width: 12; height: 12; radius: 3
                                                        color: root.paleta[index % root.paleta.length]
                                                    }
                                                    Text {
                                                        text: modelData.nombre
                                                        font.pixelSize: 12; color: Theme.textPrimary
                                                        Layout.fillWidth: true; elide: Text.ElideRight
                                                    }
                                                    Text {
                                                        text: AppConfig.moneda(modelData.total)
                                                        font.pixelSize: 12; font.bold: true; color: Theme.textSecondary
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Tendencia diaria
                            AppCard {
                                Layout.fillWidth: true
                                visible: page.serie.length > 0
                                ColumnLayout {
                                    width: parent.width
                                    spacing: Theme.paddingSmall
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Tendencia"; font.pixelSize: 15; font.bold: true; color: Theme.textPrimary; Layout.fillWidth: true }
                                        LeyendaPunto { color: Theme.success; texto: "Ingresos" }
                                        LeyendaPunto { color: Theme.error; texto: "Gastos" }
                                    }
                                    LineChartMini {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 160
                                        points: page.serie
                                    }
                                }
                            }

                            SectionHeader { titulo: "Movimientos"; subtitulo: page.movs.length + " en el periodo" }

                            Repeater {
                                model: page.movs
                                delegate: MovimientoRow {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    mov: modelData
                                    onEditar: page.editarMov(modelData)
                                    onEliminar: page.pedirEliminar(modelData)
                                }
                            }

                            EmptyState {
                                Layout.fillWidth: true
                                visible: page.movs.length === 0
                                icono: "💰"
                                mensaje: "Sin movimientos"
                                detalle: "Registra ingresos y gastos con el botón +."
                            }
                        }
                    }

                    // ================= ANALÍTICAS =================
                    Loader {
                        Layout.fillWidth: true
                        active: page.vista === "analiticas"
                        visible: active
                        sourceComponent: ColumnLayout {
                            width: contenido.width
                            spacing: Theme.padding

                            AppCard {
                                Layout.fillWidth: true
                                visible: page.periodo !== "todo"
                                ColumnLayout {
                                    width: parent.width
                                    spacing: Theme.paddingSmall
                                    Text { text: "Comparación con el periodo anterior"; font.pixelSize: 15; font.bold: true; color: Theme.textPrimary }
                                    Comparacion { etiqueta: "Ingresos"; actual: page.k.ingresos || 0; previo: page.kAnt.ingresos || 0; positivoBueno: true }
                                    Comparacion { etiqueta: "Gastos"; actual: page.k.gastos || 0; previo: page.kAnt.gastos || 0; positivoBueno: false }
                                    Comparacion { etiqueta: "Balance"; actual: page.k.balance || 0; previo: page.kAnt.balance || 0; positivoBueno: true }
                                }
                            }

                            AppCard {
                                Layout.fillWidth: true
                                GridLayout {
                                    width: parent.width
                                    columns: 3
                                    columnSpacing: Theme.padding
                                    rowSpacing: Theme.paddingSmall
                                    Kpi { etiqueta: "Ticket prom."; valor: AppConfig.moneda(page.k.ticketPromedio || 0) }
                                    Kpi { etiqueta: "Transacciones"; valor: String(page.k.transacciones || 0) }
                                    Kpi { etiqueta: "Margen"; valor: (page.k.margen || 0).toFixed(0) + "%" }
                                }
                            }

                            AppCard {
                                Layout.fillWidth: true
                                visible: page.metodos.length > 0
                                ColumnLayout {
                                    width: parent.width
                                    spacing: 4
                                    Text { text: "Métodos de pago"; font.pixelSize: 15; font.bold: true; color: Theme.textPrimary }
                                    Repeater {
                                        model: page.metodos
                                        delegate: RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Text { text: modelData.nombre; font.pixelSize: 13; color: Theme.textPrimary; Layout.fillWidth: true }
                                            Text { text: AppConfig.moneda(modelData.total); font.pixelSize: 13; font.bold: true; color: Theme.success }
                                        }
                                    }
                                }
                            }

                            Ranking { titulo: "Top servicios"; datos: page.topServ }
                            Ranking { titulo: "Top clientes"; datos: page.topCli }

                            EmptyState {
                                Layout.fillWidth: true
                                visible: (page.k.transacciones || 0) === 0
                                icono: "📊"
                                mensaje: "Sin datos en el periodo"
                                detalle: "Registra movimientos o completa citas para ver analíticas."
                            }
                        }
                    }
                }
            }

            // FAB con dos acciones etiquetadas (Ingreso / Gasto) en vez de un
            // menú oculto: antes "+" abría un Menu invisible hasta tocarlo,
            // sin pista de que hubiera que elegir entre dos tipos de
            // movimiento. Ahora, al tocar "+", aparecen dos botones con
            // etiqueta encima del FAB.
            property bool fabAbierto: false

            MouseArea {
                anchors.fill: parent
                visible: page.fabAbierto
                onClicked: page.fabAbierto = false
            }

            ColumnLayout {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Theme.paddingLarge
                spacing: Theme.paddingSmall

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    visible: opacity > 0
                    opacity: page.fabAbierto ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 130 } }
                    spacing: Theme.paddingSmall
                    Rectangle {
                        color: "#000000aa"
                        radius: 6
                        implicitWidth: lblGasto.implicitWidth + 16
                        implicitHeight: lblGasto.implicitHeight + 10
                        Text { id: lblGasto; anchors.centerIn: parent; text: "Registrar gasto"; color: "white"; font.pixelSize: 13 }
                    }
                    RoundButton {
                        text: "🧾"
                        font.pixelSize: 18
                        Material.foreground: "white"
                        background: Rectangle { radius: width / 2; color: Theme.error }
                        onClicked: { page.fabAbierto = false; stack.push(gastoFormComp, {}) }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    visible: opacity > 0
                    opacity: page.fabAbierto ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 130 } }
                    spacing: Theme.paddingSmall
                    Rectangle {
                        color: "#000000aa"
                        radius: 6
                        implicitWidth: lblIngreso.implicitWidth + 16
                        implicitHeight: lblIngreso.implicitHeight + 10
                        Text { id: lblIngreso; anchors.centerIn: parent; text: "Registrar ingreso"; color: "white"; font.pixelSize: 13 }
                    }
                    RoundButton {
                        text: "➕"
                        font.pixelSize: 18
                        Material.foreground: "white"
                        background: Rectangle { radius: width / 2; color: Theme.success }
                        onClicked: { page.fabAbierto = false; stack.push(ingresoFormComp, {}) }
                    }
                }
                RoundButton {
                    Layout.alignment: Qt.AlignRight
                    text: page.fabAbierto ? "✕" : "+"
                    font.pixelSize: 26
                    Material.foreground: "white"
                    background: Rectangle { radius: width / 2; color: Theme.primary }
                    onClicked: page.fabAbierto = !page.fabAbierto
                }
            }

            // ----- acciones movimientos -----
            property var movPendiente: ({})
            function editarMov(m) {
                if (m.tipo === "ingreso") stack.push(ingresoFormComp, { ingreso: m })
                else stack.push(gastoFormComp, { gasto: m })
            }
            function pedirEliminar(m) { movPendiente = m; confirmarEliminar.open() }

            Dialog {
                id: confirmarEliminar
                anchors.centerIn: parent
                modal: true
                width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 360)
                title: "Eliminar movimiento"
                footer: DialogButtonBox {
                    Button { text: "Cancelar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
                    Button { text: "Eliminar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; Material.foreground: Theme.error }
                }
                Label { text: "¿Eliminar “" + (page.movPendiente.etiqueta || "") + "”?" }
                onAccepted: {
                    if (page.movPendiente.tipo === "ingreso")
                        Finanzas.eliminarIngreso(page.movPendiente.id)
                    else
                        Finanzas.eliminarGasto(page.movPendiente.id)
                }
            }
        }
    }

    Component { id: ingresoFormComp; IngresoForm {} }
    Component { id: gastoFormComp; GastoForm {} }

    // ================= Componentes locales =================

    component Pill: ColumnLayout {
        property string etiqueta: ""
        property real valor: 0
        property color acento: Theme.primary
        Layout.fillWidth: true
        spacing: 0
        Text { text: etiqueta; font.pixelSize: 12; color: Theme.textSecondary }
        Text { text: AppConfig.moneda(valor); font.pixelSize: 18; font.bold: true; color: acento }
    }

    component MiniBalance: AppCard {
        property string etiqueta: ""
        property real valor: 0
        Layout.fillWidth: true
        ColumnLayout {
            width: parent.width
            spacing: 0
            Text { text: etiqueta; font.pixelSize: 12; color: Theme.textSecondary }
            Text {
                text: AppConfig.moneda(valor)
                font.pixelSize: 18; font.bold: true
                color: valor >= 0 ? Theme.success : Theme.error
            }
        }
    }

    component LeyendaPunto: RowLayout {
        property color color: Theme.primary
        property string texto: ""
        spacing: 4
        Rectangle { width: 10; height: 10; radius: 5; color: parent.color }
        Text { text: texto; font.pixelSize: 11; color: Theme.textSecondary }
    }

    component Kpi: ColumnLayout {
        property string etiqueta: ""
        property string valor: ""
        Layout.fillWidth: true
        spacing: 0
        Text { text: valor; font.pixelSize: 18; font.bold: true; color: Theme.primary }
        Text { text: etiqueta; font.pixelSize: 11; color: Theme.textSecondary }
    }

    component Comparacion: RowLayout {
        property string etiqueta: ""
        property real actual: 0
        property real previo: 0
        property bool positivoBueno: true
        Layout.fillWidth: true
        spacing: Theme.paddingSmall
        readonly property real cambio: previo !== 0 ? ((actual - previo) / Math.abs(previo)) * 100 : (actual !== 0 ? 100 : 0)
        readonly property bool sube: actual >= previo
        Text { text: etiqueta; font.pixelSize: 13; color: Theme.textPrimary; Layout.preferredWidth: 90 }
        Text { text: AppConfig.moneda(actual); font.pixelSize: 13; font.bold: true; color: Theme.textPrimary; Layout.fillWidth: true }
        Text {
            text: (sube ? "▲ " : "▼ ") + Math.abs(cambio).toFixed(0) + "%"
            font.pixelSize: 12; font.bold: true
            color: (sube === positivoBueno) ? Theme.success : Theme.error
        }
    }

    component Ranking: AppCard {
        id: rankingCard
        property string titulo: ""
        property var datos: []
        Layout.fillWidth: true
        visible: datos.length > 0
        ColumnLayout {
            width: parent.width
            spacing: 4
            Text { text: rankingCard.titulo; font.pixelSize: 15; font.bold: true; color: Theme.textPrimary }
            Repeater {
                model: rankingCard.datos
                delegate: RowLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: (index + 1) + "."; font.pixelSize: 13; color: Theme.textSecondary }
                    Text { text: modelData.nombre; font.pixelSize: 13; color: Theme.textPrimary; Layout.fillWidth: true; elide: Text.ElideRight }
                    Text { text: modelData.veces + "×"; font.pixelSize: 12; color: Theme.textSecondary }
                    Text { text: AppConfig.moneda(modelData.total); font.pixelSize: 13; font.bold: true; color: Theme.success }
                }
            }
        }
    }

    component MovimientoRow: AppCard {
        property var mov: ({})
        signal editar()
        signal eliminar()
        implicitHeight: 60
        RowLayout {
            width: parent.width
            spacing: Theme.paddingSmall
            Rectangle {
                width: 6; height: 40; radius: 3
                color: mov.esIngreso ? Theme.success : Theme.error
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: mov.etiqueta || ""
                    font.pixelSize: 14; color: Theme.textPrimary
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
                Text {
                    text: Qt.formatDateTime(new Date(mov.fecha), "dd/MM/yyyy HH:mm")
                          + (mov.editable ? "" : "  · auto")
                    font.pixelSize: 11; color: Theme.textSecondary
                }
            }
            Text {
                text: (mov.esIngreso ? "+" : "−") + AppConfig.moneda(mov.monto || 0)
                font.pixelSize: 15; font.bold: true
                color: mov.esIngreso ? Theme.success : Theme.error
            }
            ToolButton {
                visible: mov.editable === true
                text: "✏️"; font.pixelSize: 15
                Material.foreground: Theme.primary
                onClicked: editar()
            }
            ToolButton {
                visible: mov.editable === true
                text: "🗑"; font.pixelSize: 14
                Material.foreground: Theme.error
                onClicked: eliminar()
            }
        }
    }
}
