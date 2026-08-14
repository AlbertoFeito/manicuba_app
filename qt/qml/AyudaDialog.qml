import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Diálogo de ayuda contextual de una ventana. Se alimenta de AppConfig.ayuda(clave).
//
// Deliberadamente NO personaliza "header"/"background"/"contentItem": son
// propiedades diferidas de Popup y sobreescribirlas a mano (con hijos con id
// propio dentro) dejaba el diálogo con alto 0 — el contenido se veía
// "flotando" sin tarjeta detrás en vez de dentro de un cuadro. Usando el
// cromado por defecto de Material (ya coloreado vía Material.primary /
// Material.theme puestos en Main.qml) el tamaño se calcula bien siempre.
Dialog {
    id: dlg
    property string clave: "inicio"
    // Binding puro y reactivo: se recalcula solo cuando cambia "clave". Antes
    // había además un "onAboutToShow: info = AppConfig.ayuda(clave)" que
    // ROMPÍA este binding (una asignación imperativa a una propiedad con
    // binding declarativo lo reemplaza por un valor fijo).
    readonly property var info: AppConfig.ayuda(clave)

    modal: true
    anchors.centerIn: Overlay.overlay
    // OJO: NO usar "parent.width" aquí. Como este diálogo se carga vía
    // Loader (ver Main.qml), su "parent" real es el propio Loader, que no
    // tiene ancho propio (0, no null) — "parent ? parent.width : 400"
    // evaluaba a "0 - padding" (ancho NEGATIVO) en vez de caer al valor por
    // defecto, y por eso el diálogo se veía sin fondo/tamaño ("sin
    // contenido"). Overlay.overlay sí tiene siempre el tamaño real de la
    // ventana.
    width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - Theme.padding * 2, 460)
    title: (info.icono || "💡") + "  " + (info.titulo || "Ayuda")

    footer: DialogButtonBox {
        Button {
            text: "Entendido"
            flat: true
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            Material.foreground: Theme.primary
        }
    }

    ColumnLayout {
        width: dlg.availableWidth
        spacing: Theme.padding

        Repeater {
            model: dlg.info.puntos || []
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.paddingSmall
                Text { text: "•"; color: Theme.primary; font.pixelSize: 16; font.bold: true }
                Text {
                    text: modelData
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
