import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Campo de fecha: un botón que muestra la fecha elegida (en español) y abre
// un calendario emergente para seleccionarla, en vez de escribirla a mano
// como texto libre "yyyy-MM-dd". "fecha" sigue siendo ese mismo formato de
// string por compatibilidad con el resto del código (Finanzas, Citas...).
ColumnLayout {
    id: root
    property string etiqueta: "Fecha"
    property string fecha: Qt.formatDate(new Date(), "yyyy-MM-dd")

    readonly property var localeEs: Qt.locale("es_ES")
    readonly property date fechaObj: {
        const p = root.fecha.split("-")
        return p.length === 3
            ? new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
            : new Date()
    }

    spacing: 4

    Text { text: root.etiqueta; font.pixelSize: 13; color: Theme.textSecondary }

    Button {
        id: campo
        Layout.fillWidth: true
        flat: true
        background: Rectangle {
            radius: 6
            color: Theme.surfaceAlt
            border.color: Theme.divider
            border.width: 1
            implicitHeight: 44
        }
        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            Text {
                text: root.localeEs.toString(root.fechaObj, "d MMM yyyy")
                color: Theme.textPrimary
                font.pixelSize: 14
                Layout.fillWidth: true
            }
            Text { text: "📅"; font.pixelSize: 16 }
        }
        onClicked: {
            grid.month = root.fechaObj.getMonth()
            grid.year = root.fechaObj.getFullYear()
            popup.open()
        }
    }

    Popup {
        id: popup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        padding: Theme.padding
        background: Rectangle { color: Theme.surface; radius: Theme.radius }

        ColumnLayout {
            spacing: Theme.paddingSmall

            RowLayout {
                Layout.fillWidth: true
                ToolButton {
                    text: "‹"
                    font.pixelSize: 18
                    onClicked: {
                        let m = grid.month - 1, y = grid.year
                        if (m < 0) { m = 11; y-- }
                        grid.month = m; grid.year = y
                    }
                }
                Label {
                    text: root.localeEs.standaloneMonthName(grid.month + 1) + " " + grid.year
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                    color: Theme.textPrimary
                }
                ToolButton {
                    text: "›"
                    font.pixelSize: 18
                    onClicked: {
                        let m = grid.month + 1, y = grid.year
                        if (m > 11) { m = 0; y++ }
                        grid.month = m; grid.year = y
                    }
                }
            }

            DayOfWeekRow {
                Layout.fillWidth: true
                locale: root.localeEs
                delegate: Text {
                    required property var model
                    text: model.shortName
                    font.pixelSize: 11
                    color: Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }

            MonthGrid {
                id: grid
                Layout.fillWidth: true
                locale: root.localeEs
                delegate: Rectangle {
                    id: celda
                    required property var model
                    readonly property bool esSel: model.month === root.fechaObj.getMonth()
                        && model.year === root.fechaObj.getFullYear()
                        && model.day === root.fechaObj.getDate()
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: width / 2
                    color: esSel ? Theme.primary : "transparent"
                    border.color: (model.today && !esSel) ? Theme.primary : "transparent"
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: model.day
                        opacity: model.month === grid.month ? 1 : 0.35
                        color: celda.esSel ? "white" : Theme.textPrimary
                        font.bold: model.today || celda.esSel
                        font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.fecha = Qt.formatDate(new Date(celda.model.year, celda.model.month, celda.model.day), "yyyy-MM-dd")
                            popup.close()
                        }
                    }
                }
            }

            Button {
                text: "Hoy"
                flat: true
                Layout.alignment: Qt.AlignHCenter
                Material.foreground: Theme.primary
                onClicked: {
                    root.fecha = Qt.formatDate(new Date(), "yyyy-MM-dd")
                    popup.close()
                }
            }
        }
    }
}
