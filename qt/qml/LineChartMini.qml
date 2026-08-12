import QtQuick
import ManiCuba

// Gráfico de líneas (ingresos vs gastos) dibujado con Canvas.
// `points`: lista de { etiqueta, ingresos, gastos }.
Item {
    id: root
    property var points: []
    property color colorIngresos: Theme.success
    property color colorGastos: Theme.error

    implicitHeight: 160
    onPointsChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var pts = root.points
            var n = pts.length
            var padL = 6, padR = 6, padT = 10, padB = 18
            var w = width - padL - padR
            var h = height - padT - padB
            if (n < 2 || w <= 0 || h <= 0)
                return

            var maxV = 1
            for (var i = 0; i < n; i++)
                maxV = Math.max(maxV, pts[i].ingresos, pts[i].gastos)

            function x(i) { return padL + (w * i) / (n - 1) }
            function y(v) { return padT + h - (h * v) / maxV }

            // Línea base
            ctx.beginPath()
            ctx.moveTo(padL, padT + h)
            ctx.lineTo(padL + w, padT + h)
            ctx.strokeStyle = "#E0E0E0"
            ctx.lineWidth = 1
            ctx.stroke()

            function serie(getter, color) {
                ctx.beginPath()
                for (var i = 0; i < n; i++) {
                    var px = x(i), py = y(getter(pts[i]))
                    if (i === 0) ctx.moveTo(px, py)
                    else ctx.lineTo(px, py)
                }
                ctx.strokeStyle = color
                ctx.lineWidth = 2
                ctx.lineJoin = "round"
                ctx.stroke()
            }
            serie(function (p) { return p.ingresos }, root.colorIngresos)
            serie(function (p) { return p.gastos }, root.colorGastos)

            // Etiquetas en extremos y centro
            ctx.fillStyle = "#9E9E9E"
            ctx.font = "10px sans-serif"
            ctx.textAlign = "center"
            var idxs = [0, Math.floor((n - 1) / 2), n - 1]
            for (var j = 0; j < idxs.length; j++) {
                var k = idxs[j]
                ctx.fillText(pts[k].etiqueta, x(k), height - 4)
            }
        }
    }
}
