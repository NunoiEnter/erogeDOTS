// THESIS: Transport control rendered as one circular glyph.
// OWN-WORLD: Prev, play, pause, next and shuffle are painted with a Canvas
// (Context2D). QtQuick.Shapes renders nothing on this stack, so no Shape
// import here either, and no icon font or emoji fallback can change the
// glyph weight between themes.
import QtQuick
import QtQuick.Controls
import "Keyboard.js" as Keyboard

Control {
    id: button
    required property string glyph
    property color tint: Theme.ink
    property real diameter: 44
    implicitWidth: diameter
    implicitHeight: diameter
    signal clicked()
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    activeFocusOnTab: true
    padding: 0
    Accessible.name: glyph
    readonly property color glyphColor: enabled ? tint : Theme.translucent(tint, 0.3)
    Keys.onTabPressed: event => { Keyboard.move(button, !(event.modifiers & Qt.ShiftModifier)); event.accepted = true; }
    Keys.onBacktabPressed: event => { Keyboard.move(button, false); event.accepted = true; }

    background: Rectangle {
        radius: width / 2
        color: button.pressed ? Theme.translucent(button.tint, 0.15) : (button.hovered ? Theme.translucent(button.tint, 0.08) : Theme.translucent(button.tint, 0.04))
        border.width: button.visualFocus ? 2 : 1
        border.color: button.visualFocus ? Theme.accent : Theme.translucent(button.tint, 0.12)
        opacity: button.enabled ? 1 : 0.5
        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }
        scale: button.pressed ? 0.93 : 1
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    }

    // One 20x20 glyph box at the center of the disc, scaled to the canvas.
    contentItem: Canvas {
        id: tray
        anchors.centerIn: parent
        width: button.diameter
        height: width
        readonly property color ink: button.glyphColor
        onInkChanged: requestPaint()
        antialiasing: true
        renderStrategy: Canvas.Immediate
        contextType: "2d"

        onPaint: {
            const ctx = getContext("2d")
            if (!ctx) return
            ctx.fillStyle = ink
            // Work in a 20x20 glyph box mapped across the canvas diameter.
            ctx.save()
            ctx.scale(width / 20, width / 20)
            const p = function(points) {
                ctx.beginPath()
                ctx.moveTo(points[0][0], points[0][1])
                for (let i = 1; i < points.length; i++) ctx.lineTo(points[i][0], points[i][1])
                ctx.closePath()
                ctx.fill()
            }
            const bar = function(x, w) { ctx.fillRect(x, 3, w, 14) }

            if (button.glyph === "prev") {
                bar(3, 2.4)
                p([[15, 3], [15, 17], [8.5, 10]])
                p([[19, 3], [19, 17], [12.5, 10]])
            } else if (button.glyph === "next") {
                bar(14.6, 2.4)
                p([[5, 3], [5, 17], [11.5, 10]])
                p([[1, 3], [1, 17], [7.5, 10]])
            } else if (button.glyph === "play") {
                p([[6, 3], [17, 10], [6, 17]])
            } else if (button.glyph === "pause") {
                bar(5.6, 3.2)
                bar(11.2, 3.2)
            } else if (button.glyph === "shuffle") {
                ctx.strokeStyle = ink
                ctx.lineWidth = 2
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                const stroke = function(points) {
                    ctx.beginPath()
                    ctx.moveTo(points[0][0], points[0][1])
                    for (let i = 1; i < points.length; i++) ctx.lineTo(points[i][0], points[i][1])
                    ctx.stroke()
                }
                stroke([[2, 13.5], [7, 6.5], [13, 13.5]])
                stroke([[2, 6.5], [7, 13.5], [13, 6.5]])
                p([[17.5, 10.4], [11.6, 10.4], [14.6, 6.9]])
                p([[17.5, 9.6], [11.6, 9.6], [14.6, 13.1]])
            }
            ctx.restore()
        }
    }
}
