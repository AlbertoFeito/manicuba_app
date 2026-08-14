import QtQuick
import QtQuick.Controls.Material
import ManiCuba

// Tarjeta simple con sombra suave, equivalente al Card de Material3.
Rectangle {
    default property alias content: inner.data
    property alias padding: inner.anchors.margins

    radius: Theme.radius
    color: Theme.surface
    border.color: Qt.rgba(0, 0, 0, 0.06)
    border.width: 1
    implicitHeight: inner.implicitHeight + inner.anchors.margins * 2

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: Theme.padding
        implicitHeight: childrenRect.height
    }
}
