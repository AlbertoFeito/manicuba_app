import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Campo de hora: mismo patrón que SelectorFecha.qml — un TextField de solo
// lectura con el mismo estilo que los demás campos, que al tocarlo abre un
// selector emergente (dos ruedas hora/minuto) en vez del teclado. Sustituye
// al showTimePicker() de la versión Flutter original. "hora" sigue siendo
// un string "HH:mm" por compatibilidad con el resto del código.
ColumnLayout {
    id: root
    property string etiqueta: "Hora"
    property string hora: Qt.formatTime(new Date(), "HH:mm")

    readonly property int horaNum: parseInt(root.hora.split(":")[0]) || 0
    readonly property int minNum: parseInt(root.hora.split(":")[1]) || 0

    spacing: 4

    Text { text: root.etiqueta; font.pixelSize: 13; color: Theme.textSecondary }

    TextField {
        id: campo
        Layout.fillWidth: true
        readOnly: true
        activeFocusOnPress: false
        text: root.hora
        rightPadding: icono.implicitWidth + 12
        Material.accent: Theme.primary

        Text {
            id: icono
            text: "🕐"
            font.pixelSize: 16
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.open()
        }
    }

    Popup {
        id: popup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        padding: Theme.padding
        background: Rectangle { color: Theme.surface; radius: Theme.radius }

        // Fijar currentIndex de los Tumbler ANTES de abrir (p. ej. en el
        // onClicked del campo) no queda bien: el Tumbler todavía no calculó
        // su geometría y la rueda no se sincroniza visualmente aunque el
        // índice interno sea el correcto. Hay que esperar a que el popup
        // esté realmente abierto.
        onOpened: {
            tumblerH.currentIndex = root.horaNum
            tumblerM.currentIndex = root.minNum
        }

        ColumnLayout {
            spacing: Theme.paddingSmall

            Label {
                text: "Seleccionar hora"
                font.bold: true
                font.pixelSize: 15
                color: Theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Tumbler {
                    id: tumblerH
                    implicitWidth: 64
                    implicitHeight: 140
                    model: 24
                    delegate: Text {
                        text: String(modelData).padStart(2, "0")
                        font.pixelSize: 20
                        color: Theme.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: 1.0 - Math.min(1, Math.abs(Tumbler.displacement) * 0.6)
                    }
                }
                Text { text: ":"; font.pixelSize: 22; font.bold: true; color: Theme.textPrimary }
                Tumbler {
                    id: tumblerM
                    implicitWidth: 64
                    implicitHeight: 140
                    model: 60
                    delegate: Text {
                        text: String(modelData).padStart(2, "0")
                        font.pixelSize: 20
                        color: Theme.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: 1.0 - Math.min(1, Math.abs(Tumbler.displacement) * 0.6)
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.padding
                Button {
                    text: "Ahora"
                    flat: true
                    Material.foreground: Theme.textSecondary
                    onClicked: {
                        const n = new Date()
                        tumblerH.currentIndex = n.getHours()
                        tumblerM.currentIndex = n.getMinutes()
                    }
                }
                Button {
                    text: "Listo"
                    flat: true
                    Material.foreground: Theme.primary
                    onClicked: {
                        root.hora = String(tumblerH.currentIndex).padStart(2, "0") + ":"
                                  + String(tumblerM.currentIndex).padStart(2, "0")
                        popup.close()
                    }
                }
            }
        }
    }
}
