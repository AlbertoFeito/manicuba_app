import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import ManiCuba

// Alta/edición de post con sugerencias de emojis y hashtags.
// Portado de lib/screens/redes_sociales/post_form_screen.dart.
Page {
    id: page
    property var post: ({})
    readonly property bool esEdicion: post && post.id !== undefined
    readonly property var tipos: ["oferta", "promocion", "trabajo", "testimonio", "educativo"]

    // IDs de las fotos adjuntas al post, en el orden en que se agregaron.
    property var fotoIdsSel: parseFotoIds(post.fotoIds)
    function parseFotoIds(s) {
        if (!s)
            return []
        return String(s).split(",").map(function (x) { return parseInt(x.trim()) })
                         .filter(function (n) { return !isNaN(n) })
    }
    function fotosSeleccionadas() {
        var todas = Fotos.obtenerTodas()
        return page.fotoIdsSel.map(function (id) {
            return todas.find(function (f) { return f.id === id })
        }).filter(function (f) { return f !== undefined })
    }
    function quitarFoto(id) {
        page.fotoIdsSel = page.fotoIdsSel.filter(function (i) { return i !== id })
    }
    function agregarFotoId(id) {
        if (id > 0 && page.fotoIdsSel.indexOf(id) === -1)
            page.fotoIdsSel = page.fotoIdsSel.concat([id])
    }
    // La app de Cámara del sistema corre fuera del proceso: se recoge la
    // foto (si la hubo) en cuanto la app recupera el foco. Mismo patrón que
    // GaleriaScreen.qml.
    Connections {
        target: Qt.application
        function onStateChanged() {
            if (Qt.application.state === Qt.ApplicationActive) {
                const ruta = Camara.recogerCaptura()
                if (ruta)
                    page.agregarFotoId(Fotos.guardarDesdeArchivo(ruta))
            }
        }
    }

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

            Text { text: "Fotos del post"; font.pixelSize: 13; color: Theme.textSecondary }
            Text {
                visible: page.fotoIdsSel.length === 0
                text: "Sin fotos (opcional)"
                font.pixelSize: 12; color: Theme.textSecondary
            }
            ListView {
                visible: page.fotoIdsSel.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 88
                orientation: ListView.Horizontal
                spacing: Theme.paddingSmall
                model: page.fotosSeleccionadas()

                delegate: Item {
                    required property var modelData
                    width: 80; height: 80
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius
                        color: Theme.surfaceAlt
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: modelData.url
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                    RoundButton {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 2
                        implicitWidth: 22; implicitHeight: 22
                        text: "✕"; font.pixelSize: 11
                        background: Rectangle { radius: width / 2; color: "#000000aa" }
                        contentItem: Text { text: "✕"; color: "white"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: page.quitarFoto(modelData.id)
                    }
                }
            }
            Button {
                text: "➕  Agregar fotos"
                flat: true
                Material.foreground: Theme.primary
                onClicked: menuAgregarFotos.open()
            }

            Menu {
                id: menuAgregarFotos
                MenuItem {
                    text: "📷  Tomar foto"
                    visible: Qt.platform.os === "android"
                    height: visible ? implicitHeight : 0
                    onTriggered: Camara.tomarFoto()
                }
                MenuItem {
                    text: "🖼  Elegir de la galería del teléfono"
                    onTriggered: selectorArchivo.open()
                }
                MenuItem {
                    text: "🗂  Elegir de la Galería de trabajos"
                    onTriggered: {
                        if (Fotos.obtenerTodas().length === 0)
                            avisoSinFotos.open()
                        else
                            selectorGaleria.abrir()
                    }
                }
            }

            FileDialog {
                id: selectorArchivo
                title: "Elegir imagen"
                nameFilters: ["Imágenes (*.png *.jpg *.jpeg *.webp *.bmp)"]
                onAccepted: page.agregarFotoId(Fotos.guardarDesdeArchivo(selectedFile))
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
            fotoIds: page.fotoIdsSel.join(","),
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

    Dialog {
        id: avisoSinFotos
        anchors.centerIn: parent
        modal: true
        width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 340)
        title: "Galería de trabajos"
        footer: DialogButtonBox {
            Button { text: "Entendido"; flat: true; DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole }
        }
        Label {
            width: avisoSinFotos.availableWidth
            wrapMode: Text.WordWrap
            text: "Aún no tienes fotos en la Galería de trabajos. Agrega alguna desde la pestaña Galería primero."
        }
    }

    // Selector en cuadrícula de la Galería de trabajos, con multi-selección.
    Popup {
        id: selectorGaleria
        anchors.centerIn: Overlay.overlay
        width: parent.width
        height: parent.height * 0.85
        modal: true
        padding: 0
        property var seleccionTemp: []

        function abrir() {
            seleccionTemp = page.fotoIdsSel.slice()
            open()
        }

        background: Rectangle { color: Theme.background; radius: Theme.radius }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.padding
            spacing: Theme.paddingSmall

            Text { text: "Elegir fotos"; font.pixelSize: 16; font.bold: true; color: Theme.textPrimary }

            GridView {
                id: gridSelector
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / Math.max(3, Math.floor(width / 110)))
                cellHeight: cellWidth
                model: Fotos.obtenerTodas()

                delegate: Item {
                    required property var modelData
                    readonly property bool marcada: selectorGaleria.seleccionTemp.indexOf(modelData.id) !== -1
                    width: gridSelector.cellWidth
                    height: gridSelector.cellHeight
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Theme.radius
                        color: Theme.surfaceAlt
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: modelData.url
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: marcada
                            radius: parent.radius
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
                            Text {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 4
                                text: "✓"; color: "white"; font.pixelSize: 18; font.bold: true
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                const id = modelData.id
                                const sel = selectorGaleria.seleccionTemp
                                const i = sel.indexOf(id)
                                selectorGaleria.seleccionTemp = i === -1
                                    ? sel.concat([id]) : sel.filter(function (x) { return x !== id })
                            }
                        }
                    }
                }
            }

            Button {
                Layout.fillWidth: true
                text: "Listo"
                Material.background: Theme.primary
                Material.foreground: "white"
                background: Rectangle { color: Theme.primary; radius: 6 }
                onClicked: {
                    page.fotoIdsSel = selectorGaleria.seleccionTemp
                    selectorGaleria.close()
                }
            }
        }
    }
}
