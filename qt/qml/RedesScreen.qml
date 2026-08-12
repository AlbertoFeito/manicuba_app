import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Gestor de posts de redes sociales. Portado de
// lib/screens/redes_sociales/redes_screen.dart.
Item {
    id: root

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: listaPage
    }

    Component {
        id: listaPage
        Page {
            id: page
            property string filtro: "todos"
            property var lista: []
            property var stats: ({})

            function refrescar() {
                lista = Redes.filtrar(filtro)
                stats = Redes.estadisticas()
            }
            Component.onCompleted: refrescar()
            onFiltroChanged: refrescar()
            Connections { target: Redes; function onCambiado() { page.refrescar() } }

            header: Pane {
                Material.elevation: 0
                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.paddingSmall
                    Repeater {
                        model: [{ id: "todos", t: "Todos" }, { id: "pendientes", t: "Pendientes" }, { id: "publicados", t: "Publicados" }]
                        delegate: Button {
                            required property var modelData
                            Layout.fillWidth: true
                            text: modelData.t
                            flat: page.filtro !== modelData.id
                            Material.foreground: page.filtro === modelData.id ? Theme.primary : Theme.textSecondary
                            background: Rectangle {
                                radius: 16
                                color: page.filtro === modelData.id
                                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"
                            }
                            onClicked: page.filtro = modelData.id
                        }
                    }
                }
            }

            ListView {
                anchors.fill: parent
                model: page.lista
                spacing: 8
                clip: true
                topMargin: Theme.paddingSmall
                bottomMargin: 88
                leftMargin: Theme.padding
                rightMargin: Theme.padding

                header: AppCard {
                    width: ListView.view.width - Theme.padding * 2
                    visible: (page.stats.totalPosts || 0) > 0
                    RowLayout {
                        width: parent.width
                        MiniStat { valor: String(page.stats.totalPosts || 0); etiqueta: "Posts" }
                        MiniStat { valor: String(page.stats.publicados || 0); etiqueta: "Publicados" }
                        MiniStat { valor: String(page.stats.noPublicados || 0); etiqueta: "Pendientes" }
                        MiniStat { valor: String(page.stats.totalVisualizaciones || 0); etiqueta: "Vistas" }
                    }
                }

                delegate: AppCard {
                    required property var modelData
                    width: ListView.view.width - Theme.padding * 2
                    ColumnLayout {
                        width: parent.width
                        spacing: Theme.paddingSmall
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Text {
                                text: modelData.titulo || ""
                                font.pixelSize: 16; font.bold: true; color: Theme.primary
                                Layout.fillWidth: true; elide: Text.ElideRight
                            }
                            Rectangle {
                                radius: 4
                                color: modelData.publicado
                                    ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)
                                    : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.20)
                                implicitWidth: est.implicitWidth + 12; implicitHeight: est.implicitHeight + 6
                                Text {
                                    id: est; anchors.centerIn: parent
                                    text: modelData.publicado ? "Publicado" : "Pendiente"
                                    font.pixelSize: 11; font.bold: true
                                    color: modelData.publicado ? Theme.success : Theme.warning
                                }
                            }
                        }
                        Text {
                            text: (modelData.tipo || "") + " · " + (modelData.plataforma || "")
                            font.pixelSize: 12; color: Theme.textSecondary
                        }
                        Text {
                            text: Redes.contenidoFormateado(modelData)
                            font.pixelSize: 13; color: Theme.textPrimary
                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                            maximumLineCount: 4; elide: Text.ElideRight
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Accion { icono: "📋"; texto: "Copiar"; onClicked: { Redes.copiar(Redes.contenidoFormateado(modelData)); avisar("Copiado al portapapeles") } }
                            Accion {
                                icono: "🔗"; texto: "Abrir"
                                onClicked: {
                                    Redes.copiar(Redes.contenidoFormateado(modelData))
                                    var p = modelData.plataforma
                                    var url = p === "Instagram" ? "https://instagram.com"
                                            : p === "Facebook" ? "https://facebook.com"
                                            : p === "WhatsApp" ? "https://web.whatsapp.com" : "https://instagram.com"
                                    Qt.openUrlExternally(url)
                                }
                            }
                            Accion {
                                icono: modelData.publicado ? "↩️" : "✅"
                                texto: modelData.publicado ? "—" : "Publicar"
                                enabled: !modelData.publicado
                                onClicked: Redes.marcarPublicado(modelData.id)
                            }
                            Item { Layout.fillWidth: true }
                            ToolButton { text: "✎"; font.pixelSize: 15; Material.foreground: Theme.primary; onClicked: stack.push(formComp, { post: modelData }) }
                            ToolButton { text: "🗑"; font.pixelSize: 14; Material.foreground: Theme.error; onClicked: { page.pendiente = modelData; confirmar.open() } }
                        }
                    }
                }

                EmptyState {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: page.lista.length === 0
                    icono: "📣"
                    mensaje: "Sin publicaciones"
                    detalle: "Crea posts con emojis y hashtags para tus redes."
                }
            }

            property var pendiente: ({})
            Dialog {
                id: confirmar
                anchors.centerIn: parent
                modal: true
                title: "Eliminar post"
                standardButtons: Dialog.Cancel | Dialog.Yes
                Label { text: "¿Eliminar “" + (page.pendiente.titulo || "") + "”?" }
                onAccepted: Redes.eliminar(page.pendiente.id)
            }

            Popup {
                id: aviso
                y: parent.height - 120; x: (parent.width - width) / 2
                property alias texto: avisoTxt.text
                Material.elevation: 6
                background: Rectangle { color: Theme.textPrimary; radius: 20 }
                Text { id: avisoTxt; color: Theme.background; font.pixelSize: 13 }
                Timer { running: aviso.visible; interval: 1500; onTriggered: aviso.close() }
            }
            function avisar(t) { aviso.texto = t; aviso.open() }

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

            component MiniStat: ColumnLayout {
                property string valor: ""
                property string etiqueta: ""
                Layout.fillWidth: true
                spacing: 0
                Text { text: valor; font.pixelSize: 18; font.bold: true; color: Theme.primary; Layout.alignment: Qt.AlignHCenter }
                Text { text: etiqueta; font.pixelSize: 11; color: Theme.textSecondary; Layout.alignment: Qt.AlignHCenter }
            }

            component Accion: Button {
                property string icono: ""
                property string texto: ""
                flat: true
                Material.foreground: Theme.primary
                contentItem: RowLayout {
                    spacing: 3
                    Text { text: icono; font.pixelSize: 14 }
                    Text { text: texto; font.pixelSize: 12; color: enabled ? Theme.primary : Theme.textSecondary }
                }
            }
        }
    }

    Component { id: formComp; PostForm {} }
}
