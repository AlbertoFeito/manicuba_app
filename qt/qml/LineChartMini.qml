import QtQuick
import ManiCuba

// Gráfico de líneas (ingresos vs gastos) dibujado con Canvas.
// `points`: lista de { fecha, etiqueta, ingresos, gastos }.
//
// Toca o arrastra sobre la gráfica para ver el valor de un día concreto,
// igual que el touch por defecto de fl_chart en la versión Flutter (que no
// desactiva `lineTouchData`, así que ya viene con línea guía + tooltip de
// fábrica al tocar el punto más cercano).
Item {
    id: root
    property var points: []
    property color colorIngresos: Theme.success
    property color colorGastos: Theme.error
    property int seleccion: -1

    readonly property real padL: 6
    readonly property real padR: 6
    readonly property real padT: 10
    readonly property real padB: 18

    implicitHeight: 160
    onPointsChanged: { seleccion = -1; canvas.requestPaint() }
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onSeleccionChanged: canvas.requestPaint()

    function anchoUtil() { return width - padL - padR }
    function altoUtil() { return height - padT - padB }
    function maxValor() {
        var maxV = 1
        for (var i = 0; i < points.length; i++)
            maxV = Math.max(maxV, points[i].ingresos, points[i].gastos)
        return maxV
    }
    function xDe(i) {
        var n = root.points.length
        return padL + (anchoUtil() * i) / Math.max(1, n - 1)
    }
    function yDe(v) {
        return padT + altoUtil() - (altoUtil() * v) / maxValor()
    }
    // Índice del punto más cercano a una posición horizontal en píxeles.
    function indiceEn(px) {
        var n = root.points.length
        if (n === 0)
            return -1
        if (n === 1)
            return 0
        var i = Math.round(((px - padL) / anchoUtil()) * (n - 1))
        return Math.max(0, Math.min(n - 1, i))
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var pts = root.points
            var n = pts.length
            if (n < 2 || root.anchoUtil() <= 0 || root.altoUtil() <= 0)
                return

            // Línea base
            ctx.beginPath()
            ctx.moveTo(root.padL, root.padT + root.altoUtil())
            ctx.lineTo(root.padL + root.anchoUtil(), root.padT + root.altoUtil())
            ctx.strokeStyle = "#E0E0E0"
            ctx.lineWidth = 1
            ctx.stroke()

            // Línea guía del punto seleccionado (detrás de las series)
            if (root.seleccion >= 0) {
                var gx = root.xDe(root.seleccion)
                ctx.beginPath()
                ctx.moveTo(gx, root.padT)
                ctx.lineTo(gx, root.padT + root.altoUtil())
                ctx.strokeStyle = "#BDBDBD"
                ctx.lineWidth = 1
                ctx.stroke()
            }

            function serie(getter, color) {
                ctx.beginPath()
                for (var i = 0; i < n; i++) {
                    var px = root.xDe(i), py = root.yDe(getter(pts[i]))
                    if (i === 0) ctx.moveTo(px, py)
                    else ctx.lineTo(px, py)
                }
                ctx.strokeStyle = color
                ctx.lineWidth = 2
                ctx.lineJoin = "round"
                ctx.stroke()

                if (root.seleccion >= 0) {
                    var sx = root.xDe(root.seleccion), sy = root.yDe(getter(pts[root.seleccion]))
                    ctx.beginPath()
                    ctx.arc(sx, sy, 4, 0, 2 * Math.PI)
                    ctx.fillStyle = color
                    ctx.fill()
                }
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
                ctx.fillText(pts[k].etiqueta, root.xDe(k), height - 4)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => root.seleccion = root.indiceEn(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) root.seleccion = root.indiceEn(mouse.x) }
    }

    // Tooltip del día seleccionado (aparte del Canvas: el texto se ve nítido).
    Rectangle {
        id: tooltip
        visible: root.seleccion >= 0 && root.points.length > 0
        readonly property var punto: visible ? root.points[root.seleccion] : ({})
        radius: 6
        color: "#2E2E2E"
        implicitWidth: tooltipCol.implicitWidth + 16
        implicitHeight: tooltipCol.implicitHeight + 10
        x: Math.max(0, Math.min(root.width - width, root.xDe(root.seleccion >= 0 ? root.seleccion : 0) - width / 2))
        y: 0

        Column {
            id: tooltipCol
            x: 8; y: 5
            spacing: 2
            Text {
                text: tooltip.punto.fecha ? new Date(tooltip.punto.fecha).toLocaleDateString(Qt.locale("es_ES"), "dddd d 'de' MMMM") : ""
                color: "white"; font.pixelSize: 11; font.bold: true
            }
            Text {
                text: "Ingresos: " + AppConfig.moneda(tooltip.punto.ingresos || 0)
                color: root.colorIngresos; font.pixelSize: 11
            }
            Text {
                text: "Gastos: " + AppConfig.moneda(tooltip.punto.gastos || 0)
                color: root.colorGastos; font.pixelSize: 11
            }
        }
    }
}
