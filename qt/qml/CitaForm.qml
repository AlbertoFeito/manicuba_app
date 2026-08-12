import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Alta/edición de cita. Portado de lib/screens/agenda/cita_form_screen.dart.
// Al guardar, CitaService sincroniza el ingreso si la cita queda completada.
Page {
    id: page
    property var cita: ({})
    property string fechaDefault: Qt.formatDate(new Date(), "yyyy-MM-dd")
    readonly property bool esEdicion: cita && cita.id !== undefined

    readonly property var estados: ["pendiente", "confirmada", "completada", "cancelada"]

    function horaInicial() {
        if (page.cita.fechaHora)
            return Qt.formatDateTime(new Date(page.cita.fechaHora), "HH:mm")
        return "10:00"
    }
    function fechaInicial() {
        if (page.cita.fechaHora)
            return Qt.formatDate(new Date(page.cita.fechaHora), "yyyy-MM-dd")
        return page.fechaDefault
    }

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        Material.foreground: "white"
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "‹"; font.pixelSize: 24; onClicked: page.StackView.view.pop() }
            Label {
                text: page.esEdicion ? "Editar cita" : "Nueva cita"
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

            Text { text: "Cliente *"; font.pixelSize: 13; color: Theme.textSecondary }
            ComboBox {
                id: cbCliente
                Layout.fillWidth: true
                textRole: "nombre"
                valueRole: "id"
                model: Clientes.obtenerTodos()
                Material.accent: Theme.primary
                Component.onCompleted: {
                    if (page.cita.clienteId !== undefined)
                        currentIndex = indexOfValue(page.cita.clienteId)
                }
            }

            Text { text: "Servicio *"; font.pixelSize: 13; color: Theme.textSecondary }
            ComboBox {
                id: cbServicio
                Layout.fillWidth: true
                textRole: "nombre"
                valueRole: "id"
                model: Servicios.obtenerTodos()
                Material.accent: Theme.primary
                Component.onCompleted: {
                    if (page.cita.servicioId !== undefined)
                        currentIndex = indexOfValue(page.cita.servicioId)
                }
                onActivated: {
                    var s = model[currentIndex]
                    if (s) {
                        fDuracion.text = String(s.duracionMinutos)
                        if (fMonto.text.trim().length === 0 || parseFloat(fMonto.text) === 0)
                            fMonto.text = String(s.precio)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.padding
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Fecha *"; font.pixelSize: 13; color: Theme.textSecondary }
                    TextField {
                        id: fFecha
                        Layout.fillWidth: true
                        text: page.fechaInicial()
                        placeholderText: "yyyy-MM-dd"
                        Material.accent: Theme.primary
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Hora *"; font.pixelSize: 13; color: Theme.textSecondary }
                    TextField {
                        id: fHora
                        Layout.fillWidth: true
                        text: page.horaInicial()
                        placeholderText: "HH:mm"
                        Material.accent: Theme.primary
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.padding
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Duración (min)"; font.pixelSize: 13; color: Theme.textSecondary }
                    TextField {
                        id: fDuracion
                        Layout.fillWidth: true
                        text: page.cita.duracionMinutos !== undefined
                              ? String(page.cita.duracionMinutos) : String(AppConfig.duracionCitaDefault)
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 1; top: 600 }
                        Material.accent: Theme.primary
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Monto"; font.pixelSize: 13; color: Theme.textSecondary }
                    TextField {
                        id: fMonto
                        Layout.fillWidth: true
                        text: page.cita.monto !== undefined && page.cita.monto !== null
                              ? String(page.cita.monto) : ""
                        placeholderText: "0.00"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator { bottom: 0; decimals: 2; notation: DoubleValidator.StandardNotation }
                        Material.accent: Theme.primary
                    }
                }
            }

            Text { text: "Estado"; font.pixelSize: 13; color: Theme.textSecondary }
            ComboBox {
                id: cbEstado
                Layout.fillWidth: true
                model: page.estados.map(function (e) { return AppConfig.etiquetaEstado(e) })
                Material.accent: Theme.primary
                Component.onCompleted: {
                    var actual = page.cita.estado || "pendiente"
                    currentIndex = Math.max(0, page.estados.indexOf(actual))
                }
            }

            Text { text: "Notas"; font.pixelSize: 13; color: Theme.textSecondary }
            TextArea {
                id: fNotas
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                text: page.cita.notas || ""
                wrapMode: TextArea.Wrap
                Material.accent: Theme.primary
            }

            Text {
                id: error
                visible: false
                text: ""
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
            text: page.esEdicion ? "Guardar cambios" : "Crear cita"
            Material.background: Theme.primary
            Material.foreground: "white"
            background: Rectangle { color: Theme.primary; radius: 6 }
            onClicked: page.guardar()
        }
    }

    function guardar() {
        if (cbCliente.currentIndex < 0 || cbServicio.currentIndex < 0) {
            error.text = "Selecciona cliente y servicio."
            error.visible = true
            return
        }
        var fechaHora = fFecha.text.trim() + "T" + fHora.text.trim() + ":00"
        if (isNaN(Date.parse(fechaHora))) {
            error.text = "Fecha u hora inválida (usa yyyy-MM-dd y HH:mm)."
            error.visible = true
            return
        }
        var datos = {
            clienteId: cbCliente.currentValue,
            servicioId: cbServicio.currentValue,
            fechaHora: fechaHora,
            duracionMinutos: parseInt(fDuracion.text) || AppConfig.duracionCitaDefault,
            estado: page.estados[cbEstado.currentIndex],
            monto: fMonto.text.trim().length > 0 ? parseFloat(fMonto.text) : 0,
            notas: fNotas.text.trim()
        }
        if (page.esEdicion) {
            datos.id = page.cita.id
            Citas.actualizar(datos)
        } else {
            Citas.crear(datos)
        }
        page.StackView.view.pop()
    }

    Dialog {
        id: confirmar
        anchors.centerIn: parent
        modal: true
        title: "Eliminar cita"
        standardButtons: Dialog.Cancel | Dialog.Yes
        Label { text: "¿Eliminar esta cita? Si tenía ingreso asociado, también se eliminará." }
        onAccepted: {
            Citas.eliminar(page.cita.id)
            page.StackView.view.pop()
        }
    }
}
