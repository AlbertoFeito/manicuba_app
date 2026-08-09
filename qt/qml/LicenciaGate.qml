import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Envuelve la app: muestra el contenido normalmente, pero superpone la pantalla
// de activación cuando la prueba está vencida (bloqueante) o cuando el usuario
// abre "Licencia" desde el menú. Portado de lib/screens/licencia/licencia_gate.dart.
Item {
    id: gate
    default property alias contenido: holder.data

    // El menú puede pedir mostrar el panel aunque no esté bloqueado.
    property bool mostrarPanel: false

    Item {
        id: holder
        anchors.fill: parent
    }

    // Capa de activación (bloqueante o abierta a voluntad).
    Rectangle {
        anchors.fill: parent
        visible: Licencia.bloqueada || gate.mostrarPanel
        color: Theme.background

        // Bloquea la interacción con el contenido de atrás.
        MouseArea { anchors.fill: parent }

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: panel.implicitHeight + Theme.paddingLarge * 2
            clip: true

            ColumnLayout {
                id: panel
                width: Math.min(gate.width - Theme.padding * 2, 460)
                x: (gate.width - width) / 2
                y: Theme.paddingLarge
                spacing: Theme.padding

                Text {
                    text: "💅 ManiCuba"
                    font.pixelSize: 30
                    font.bold: true
                    color: Theme.primary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: Theme.textPrimary
                    font.pixelSize: 15
                    text: Licencia.bloqueada
                          ? "Tu prueba de 15 días terminó. Activa una licencia para seguir usando la app."
                          : (Licencia.estadoTipo === "activa"
                             ? "Licencia activa. ¡Gracias!"
                             : "Prueba: quedan " + Licencia.diasRestantes + " días.")
                }

                AppCard {
                    Layout.fillWidth: true
                    ColumnLayout {
                        width: parent.width
                        spacing: Theme.paddingSmall
                        Text {
                            text: "Código de este equipo"
                            font.pixelSize: 13
                            color: Theme.textSecondary
                        }
                        Text {
                            text: Licencia.deviceIdFormateado
                            font.pixelSize: 20
                            font.bold: true
                            font.family: "monospace"
                            color: Theme.textPrimary
                            Layout.fillWidth: true
                            wrapMode: Text.WrapAnywhere
                        }
                        Text {
                            visible: Licencia.usandoSecretoDev
                            text: "⚠️ Usando secreto de desarrollo (solo para pruebas)."
                            font.pixelSize: 11
                            color: Theme.warning
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                TextField {
                    id: campoCodigo
                    Layout.fillWidth: true
                    placeholderText: "Pega aquí tu código de licencia"
                    font.family: "monospace"
                    Material.accent: Theme.primary
                }

                Text {
                    id: errorMsg
                    visible: false
                    text: "Código incorrecto para este equipo."
                    color: Theme.error
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Button {
                    Layout.fillWidth: true
                    text: "Activar licencia"
                    Material.foreground: "white"
                    background: Rectangle { color: Theme.primary; radius: 6 }
                    onClicked: {
                        if (Licencia.activar(campoCodigo.text)) {
                            errorMsg.visible = false
                            campoCodigo.text = ""
                            gate.mostrarPanel = false
                        } else {
                            errorMsg.visible = true
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    visible: !Licencia.bloqueada
                    flat: true
                    text: "Cerrar"
                    onClicked: gate.mostrarPanel = false
                }
            }
        }
    }
}
