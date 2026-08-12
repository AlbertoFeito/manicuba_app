import QtQuick
import ManiCuba

// Gráfico de dona dibujado con Canvas (sin dependencias externas).
// `model`: lista de { nombre, total }. `palette`: colores por segmento.
Item {
    id: root
    property var model: []
    property var palette: [
        "#E91E63", "#2196F3", "#4CAF50", "#FFC107",
        "#9C27B0", "#00BCD4", "#FF5722", "#795548"
    ]
    property string centroTexto: ""

    implicitWidth: 180
    implicitHeight: 180

    function colorFor(i) { return palette[i % palette.length] }
    onModelChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var w = width, h = height
            var cx = w / 2, cy = h / 2
            var radio = Math.min(w, h) / 2 - 4
            var grosor = radio * 0.42

            var total = 0
            for (var k = 0; k < root.model.length; k++)
                total += root.model[k].total
            if (total <= 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, radio - grosor / 2, 0, 2 * Math.PI)
                ctx.lineWidth = grosor
                ctx.strokeStyle = "#E0E0E0"
                ctx.stroke()
                return
            }

            var ang = -Math.PI / 2
            for (var i = 0; i < root.model.length; i++) {
                var frac = root.model[i].total / total
                var fin = ang + frac * 2 * Math.PI
                ctx.beginPath()
                ctx.arc(cx, cy, radio - grosor / 2, ang, fin)
                ctx.lineWidth = grosor
                ctx.strokeStyle = root.colorFor(i)
                ctx.stroke()
                ang = fin
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.centroTexto
        font.pixelSize: 15
        font.bold: true
        color: Theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
    }
}
