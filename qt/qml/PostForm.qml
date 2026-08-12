import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Alta/edición de post con sugerencias de emojis y hashtags.
// Portado de lib/screens/redes_sociales/post_form_screen.dart.
Page {
    id: page
    property var post: ({})
    readonly property bool esEdicion: post && post.id !== undefined
    readonly property var tipos: ["oferta", "promocion", "trabajo", "testimonio", "educativo"]

    header: ToolBar {
        Material.background: Theme.primary
        background: Rectangle { color: Theme.primary }
        Material.foreground: "white"
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "‹"; font.pixelSize: 24; onClicked: page.StackView.view.pop() }
            Label {
                text: page.esEdicion ? "Editar post" : "Nuevo post"
                font.pixelSize: 18; font.bold: true; color: "white"
                Layout.fillWidth: true
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

            Text { text: "Título *"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fTitulo
                Layout.fillWidth: true
                text: page.post.titulo || ""
                Material.accent: Theme.primary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.padding
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Tipo"; font.pixelSize: 13; color: Theme.textSecondary }
                    ComboBox {
                        id: cbTipo
                        Layout.fillWidth: true
                        model: page.tipos.map(function (t) { return t.charAt(0).toUpperCase() + t.slice(1) })
                        Material.accent: Theme.primary
                        Component.onCompleted: currentIndex = Math.max(0, page.tipos.indexOf(page.post.tipo || "oferta"))
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Plataforma"; font.pixelSize: 13; color: Theme.textSecondary }
                    ComboBox {
                        id: cbPlataforma
                        Layout.fillWidth: true
                        model: AppConfig.plataformasSociales
                        Material.accent: Theme.primary
                        Component.onCompleted: {
                            var i = AppConfig.plataformasSociales.indexOf(page.post.plataforma || "Todas")
                            currentIndex = i < 0 ? AppConfig.plataformasSociales.length - 1 : i
                        }
                    }
                }
            }

            Text { text: "Contenido *"; font.pixelSize: 13; color: Theme.textSecondary }
            TextArea {
                id: fContenido
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                text: page.post.contenido || ""
                wrapMode: TextArea.Wrap
                Material.accent: Theme.primary
            }

            Text { text: "Emojis"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fEmojis
                Layout.fillWidth: true
                text: page.post.emojis || ""
                Material.accent: Theme.primary
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Redes.sugerenciasEmojis(page.tipos[cbTipo.currentIndex])
                    delegate: Button {
                        required property var modelData
                        text: modelData
                        flat: true
                        padding: 6
                        onClicked: fEmojis.text = (fEmojis.text + modelData)
                    }
                }
            }

            Text { text: "Hashtags"; font.pixelSize: 13; color: Theme.textSecondary }
            TextField {
                id: fHashtags
                Layout.fillWidth: true
                text: page.post.hashtags || ""
                placeholderText: "#manicura #belleza"
                Material.accent: Theme.primary
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Redes.sugerenciasHashtags(fContenido.text)
                    delegate: Button {
                        required property var modelData
                        text: modelData
                        flat: true
                        padding: 6
                        Material.foreground: Theme.primary
                        onClicked: {
                            if (fHashtags.text.indexOf(modelData) === -1)
                                fHashtags.text = (fHashtags.text.trim() + " " + modelData).trim()
                        }
                    }
                }
            }

            // Vista previa
            AppCard {
                Layout.fillWidth: true
                color: Theme.surfaceAlt
                ColumnLayout {
                    width: parent.width
                    spacing: 4
                    Text { text: "Vista previa"; font.pixelSize: 12; font.bold: true; color: Theme.primary }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        text: {
                            var t = fContenido.text
                            if (fEmojis.text.length) t += "\n\n" + fEmojis.text
                            if (fHashtags.text.length) t += "\n\n" + fHashtags.text
                            return t
                        }
                    }
                }
            }

            Text {
                id: error
                visible: false
                text: "El título y el contenido son obligatorios."
                color: Theme.error; font.pixelSize: 13; Layout.fillWidth: true
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
            text: page.esEdicion ? "Guardar cambios" : "Crear post"
            Material.background: Theme.primary
            Material.foreground: "white"
            background: Rectangle { color: Theme.primary; radius: 6 }
            onClicked: page.guardar()
        }
    }

    function guardar() {
        if (fTitulo.text.trim().length === 0 || fContenido.text.trim().length === 0) {
            error.visible = true
            return
        }
        var datos = {
            titulo: fTitulo.text.trim(),
            contenido: fContenido.text.trim(),
            emojis: fEmojis.text.trim(),
            hashtags: fHashtags.text.trim(),
            tipo: page.tipos[cbTipo.currentIndex],
            plataforma: AppConfig.plataformasSociales[cbPlataforma.currentIndex],
            notas: ""
        }
        if (page.esEdicion) {
            datos.id = page.post.id
            Redes.actualizar(datos)
        } else {
            Redes.crear(datos)
        }
        page.StackView.view.pop()
    }
}
