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
                visible: page.esEdicion && page.cita.estado !== "completada"
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
                SelectorFecha {
                    id: fFecha
                    Layout.fillWidth: true
                    etiqueta: "Fecha *"
                    fecha: page.fechaInicial()
                }
                SelectorHora {
                    id: fHora
                    Layout.fillWidth: true
                    etiqueta: "Hora *"
                    hora: page.horaInicial()
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
        var fechaHora = fFecha.fecha + "T" + fHora.hora + ":00"
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
            monto: fMonto.text.trim().length > 0 ? parseFloat(fMonto.text) : 0,
            notas: fNotas.text.trim()
        }
        if (page.esEdicion) {
            // El estado se cambia desde el menú de la cita en Agenda, no
            // aquí: se conserva el que ya tenía.
            datos.id = page.cita.id
            datos.estado = page.cita.estado || "pendiente"
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
        width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 360)
        title: "Eliminar cita"
        footer: DialogButtonBox {
            Button { text: "Cancelar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.RejectRole }
            Button { text: "Eliminar"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; Material.foreground: Theme.error }
        }
        Label { text: "¿Eliminar esta cita? Si tenía ingreso asociado, también se eliminará." }
        onAccepted: {
            if (Citas.eliminar(page.cita.id))
                page.StackView.view.pop()
            else
                avisoNoSePuede.open()
        }
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
            text: "Esta cita ya está completada y forma parte del historial de ingresos, así que no se puede eliminar."
        }
    }
}
