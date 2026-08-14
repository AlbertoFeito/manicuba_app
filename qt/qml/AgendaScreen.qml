import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Agenda con calendario (mes/semana) y la lista de citas del día
// seleccionado. Portado de lib/screens/agenda/agenda_screen.dart, que usaba
// el paquete table_calendar con toggle Mes/Semana; aquí se reconstruye ese
// mismo comportamiento con MonthGrid/DayOfWeekRow (igual que
// SelectorFecha.qml, pero con puntos marcando los días que tienen citas).
Item {
    id: root

    function abrirHistorial() { stack.push(histComp) }
    function abrirNuevaCita() { stack.push(citaFormComp) }

    // Usado por el botón atrás de Android (ver Main.qml): si hay algo
    // apilado (formulario, historial) lo cierra y devuelve true; si ya
    // está en la raíz de la pestaña, no hace nada y devuelve false.
    function volver() {
        if (stack.depth > 1) { stack.pop(); return true }
        return false
    }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: agendaPage
    }

    Component {
        id: agendaPage
        Page {
            id: page

            readonly property var localeEs: Qt.locale("es_ES")
            property string formato: "mes"          // "mes" | "semana"
            property date focusedDate: new Date()   // mes/semana visible
            property date selectedDay: new Date()   // día elegido en el calendario
            property var citasPorDia: ({})          // "yyyy-MM-dd" -> [citas]
            property var citaAEliminar: ({})

            function claveDia(d) { return Qt.formatDate(d, "yyyy-MM-dd") }
            function citasDe(d) { return page.citasPorDia[page.claveDia(d)] || [] }
            function esMismoDia(a, b) {
                return a.getFullYear() === b.getFullYear()
                    && a.getMonth() === b.getMonth()
                    && a.getDate() === b.getDate()
            }
            function inicioSemana(d) {
                const dow = d.getDay() // 0=domingo..6=sábado
                const diff = dow === 0 ? -6 : 1 - dow // retrocede hasta el lunes
                const lunes = new Date(d)
                lunes.setDate(d.getDate() + diff)
                return lunes
            }

            function refrescar() {
                const todas = Citas.obtenerTodas()
                const mapa = {}
                for (let i = 0; i < todas.length; i++) {
                    const c = todas[i]
                    // Las citas completadas/canceladas salen del calendario y
                    // pasan al Historial; aquí solo se ven las activas.
                    if (c.estado === "completada" || c.estado === "cancelada")
                        continue
                    const key = page.claveDia(new Date(c.fechaHora))
                    if (!mapa[key])
                        mapa[key] = []
                    mapa[key].push(c)
                }
                for (const key in mapa) {
                    mapa[key].sort(function (a, b) {
                        return new Date(a.fechaHora) - new Date(b.fechaHora)
                    })
                }
                page.citasPorDia = mapa
            }
            Component.onCompleted: refrescar()
            Connections { target: Citas; function onCambiado() { page.refrescar() } }

            header: ColumnLayout {
                width: parent.width
                spacing: Theme.paddingSmall

                // Toggle Mes / Semana (igual estilo que los chips de periodo
                // en Finanzas).
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.padding
                    Layout.rightMargin: Theme.padding
                    Layout.topMargin: Theme.paddingSmall
                    spacing: 0
                    Repeater {
                        model: [{ id: "mes", t: "Mes" }, { id: "semana", t: "Semana" }]
                        delegate: Button {
                            required property var modelData
                            Layout.fillWidth: true
                            flat: page.formato !== modelData.id
                            text: modelData.t
                            Material.foreground: page.formato === modelData.id ? "white" : Theme.textPrimary
                            background: Rectangle {
                                radius: 6
                                color: page.formato === modelData.id ? Theme.primary : "transparent"
                            }
                            onClicked: page.formato = modelData.id
                        }
                    }
                }

                // Navegación mes/semana anterior-siguiente.
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.padding
                    Layout.rightMargin: Theme.padding
                    ToolButton {
                        text: "‹"; font.pixelSize: 20
                        onClicked: {
                            const d = new Date(page.focusedDate)
                            if (page.formato === "mes") d.setMonth(d.getMonth() - 1)
                            else d.setDate(d.getDate() - 7)
                            page.focusedDate = d
                        }
                    }
                    Label {
                        text: page.focusedDate.toLocaleDateString(page.localeEs, "MMMM yyyy")
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        font.bold: true
                        font.pixelSize: 15
                        color: Theme.textPrimary
                    }
                    ToolButton {
                        text: "›"; font.pixelSize: 20
                        onClicked: {
                            const d = new Date(page.focusedDate)
                            if (page.formato === "mes") d.setMonth(d.getMonth() + 1)
                            else d.setDate(d.getDate() + 7)
                            page.focusedDate = d
                        }
                    }
                    ToolButton {
                        text: "Hoy"; font.pixelSize: 12
                        onClicked: { page.focusedDate = new Date(); page.selectedDay = new Date() }
                    }
                }

                DayOfWeekRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.padding
                    Layout.rightMargin: Theme.padding
                    locale: page.localeEs
                    delegate: Text {
                        required property var model
                        text: model.shortName
                        font.pixelSize: 11
                        color: Theme.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                }

                // Vista mensual: cuadrícula completa del mes.
                MonthGrid {
                    id: grid
                    visible: page.formato === "mes"
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.padding
                    Layout.rightMargin: Theme.padding
                    month: page.focusedDate.getMonth()
                    year: page.focusedDate.getFullYear()
                    locale: page.localeEs
                    delegate: CeldaDia {
                        required property var model
                        fecha: new Date(model.year, model.month, model.day)
                        atenuada: model.month !== grid.month
                    }
                }

                // Vista semanal: una sola fila con los 7 días de la semana.
                RowLayout {
                    visible: page.formato === "semana"
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.padding
                    Layout.rightMargin: Theme.padding
                    spacing: 0
                    Repeater {
                        model: 7
                        delegate: CeldaDia {
                            required property int index
                            Layout.fillWidth: true
                            fecha: {
                                const l = page.inicioSemana(page.focusedDate)
                                l.setDate(l.getDate() + index)
                                return l
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: Theme.paddingSmall }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }
            }

            ListView {
                anchors.fill: parent
                model: page.citasDe(page.selectedDay)
                spacing: 6
                clip: true
                topMargin: Theme.paddingSmall
                bottomMargin: 88

                delegate: ItemDelegate {
                    id: fila
                    required property var modelData
                    width: ListView.view.width
                    // Tocar la cita ofrece las acciones (cambiar estado,
                    // editar, eliminar) en vez de ir directo al formulario:
                    // el estado se cambia aquí, NO dentro del formulario de
                    // edición (ver CitaForm.qml).
                    onClicked: menuCita.open()
                    contentItem: RowLayout {
                        spacing: Theme.padding
                        ColumnLayout {
                            spacing: 0
                            Text {
                                text: Qt.formatDateTime(new Date(modelData.fechaHora), "HH:mm")
                                font.pixelSize: 18; font.bold: true; color: Theme.primary
                            }
                            Text {
                                text: (modelData.duracionMinutos || 0) + " min"
                                font.pixelSize: 11; color: Theme.textSecondary
                            }
                        }
                        Rectangle { width: 1; Layout.fillHeight: true; color: Theme.divider }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: modelData.nombreCliente || "Cliente"
                                font.pixelSize: 15; font.bold: true; color: Theme.textPrimary
                                Layout.fillWidth: true; elide: Text.ElideRight
                            }
                            Text {
                                text: (modelData.nombreServicio || "Servicio") + " · "
                                      + AppConfig.moneda(modelData.monto || 0)
                                font.pixelSize: 13; color: Theme.textSecondary
                            }
                        }
                        EstadoBadge { estado: modelData.estado || "pendiente" }
                    }

                    Menu {
                        id: menuCita
                        MenuItem {
                            visible: fila.modelData.estado !== "confirmada"
                            text: "✅  Confirmar"
                            onTriggered: Citas.cambiarEstado(fila.modelData.id, "confirmada")
                        }
                        MenuItem {
                            text: "🏁  Marcar completada"
                            onTriggered: Citas.cambiarEstado(fila.modelData.id, "completada")
                        }
                        MenuItem {
                            text: "🚫  Cancelar cita"
                            onTriggered: Citas.cambiarEstado(fila.modelData.id, "cancelada")
                        }
                        MenuSeparator {}
                        MenuItem {
                            text: "✏️  Editar"
                            onTriggered: stack.push(citaFormComp, { cita: fila.modelData, fechaDefault: page.claveDia(page.selectedDay) })
                        }
                        MenuItem {
                            text: "🗑  Eliminar"
                            onTriggered: { page.citaAEliminar = fila.modelData; confirmarEliminar.open() }
                        }
                    }
                }

                EmptyState {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: page.citasDe(page.selectedDay).length === 0
                    icono: "📅"
                    mensaje: "Sin citas el " + Qt.formatDate(page.selectedDay, "dd/MM/yyyy")
                    detalle: "Toca + para agendar una cita."
                }
            }

            // FAB "extendido" (icono + etiqueta), igual que el
            // FloatingActionButton.extended de la versión Flutter.
            Button {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Theme.paddingLarge
                padding: 14
                Material.foreground: "white"
                background: Rectangle { radius: height / 2; color: Theme.primary }
                contentItem: RowLayout {
                    spacing: 6
                    Text { text: "+"; font.pixelSize: 20; font.bold: true; color: "white" }
                    Text { text: "Nueva cita"; font.pixelSize: 14; color: "white" }
                }
                onClicked: stack.push(citaFormComp, { fechaDefault: page.claveDia(page.selectedDay) })
            }

            Dialog {
                id: confirmarEliminar
                anchors.centerIn: parent
                modal: true
                width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 360)
                title: "Eliminar cita"
                footer: DialogButtonBox {
                    Button { text: "Cancelar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
                    Button { text: "Eliminar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; Material.foreground: Theme.error }
                }
                Label { text: "¿Eliminar esta cita? Si tenía ingreso asociado, también se eliminará." }
                onAccepted: Citas.eliminar(page.citaAEliminar.id)
            }

            // ----- Celda de día (reusada por la vista de mes y de semana) -----
            component CeldaDia: Rectangle {
                id: celda
                property date fecha: new Date()
                property bool atenuada: false
                readonly property bool esSel: page.esMismoDia(fecha, page.selectedDay)
                readonly property bool esHoy: page.esMismoDia(fecha, new Date())
                readonly property bool tieneCitas: page.citasDe(fecha).length > 0

                implicitWidth: 40
                implicitHeight: 44
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    width: 32; height: 32; radius: 16
                    color: celda.esSel ? Theme.primary : "transparent"
                    border.color: (celda.esHoy && !celda.esSel) ? Theme.primary : "transparent"
                    border.width: 1
                }
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -4
                    text: celda.fecha.getDate()
                    font.pixelSize: 13
                    font.bold: celda.esHoy || celda.esSel
                    opacity: celda.atenuada ? 0.35 : 1
                    color: celda.esSel ? "white" : Theme.textPrimary
                }
                Rectangle {
                    visible: celda.tieneCitas
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height - 8
                    width: 5; height: 5; radius: 2.5
                    color: celda.esSel ? "white" : Theme.primary
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        page.selectedDay = celda.fecha
                        if (celda.atenuada)
                            page.focusedDate = celda.fecha
                    }
                }
            }
        }
    }

    Component { id: citaFormComp; CitaForm {} }
    Component { id: histComp; HistorialScreen {} }
}
