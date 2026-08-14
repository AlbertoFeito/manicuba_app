import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ManiCuba

// Campo de fecha: se ve y se comporta como los demás TextField de la app
// (misma línea inferior Material, sin caja/relleno de color), pero es de
// solo lectura y al tocarlo abre un calendario emergente en vez del
// teclado — igual que el showDatePicker() de la versión Flutter original
// (ver lib/screens/agenda/cita_form_screen.dart). "fecha" sigue siendo un
// string "yyyy-MM-dd" por compatibilidad con el resto del código.
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

    TextField {
        id: campo
        Layout.fillWidth: true
        readOnly: true
        activeFocusOnPress: false
        text: root.fechaObj.toLocaleDateString(root.localeEs, "dd/MM/yyyy")
        rightPadding: iconoCal.implicitWidth + 12
        Material.accent: Theme.primary

        Text {
            id: iconoCal
            text: "📅"
            font.pixelSize: 16
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                grid.month = root.fechaObj.getMonth()
                grid.year = root.fechaObj.getFullYear()
                popup.open()
            }
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
                    text: (new Date(grid.year, grid.month, 1)).toLocaleDateString(root.localeEs, "MMMM yyyy")
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
