import QtQuick

// Small authored line icons: one stroke family, no font or raster dependency.
// Painted with a Canvas (Context2D): QtQuick.Shapes renders nothing on this
// stack, and this keeps the stroke weight identical across themes. The SVG
// path data is walked by hand because the QML JS engine has no Path2D.
Item {
    id: icon
    property string symbol: "settings"
    property color color: Theme.accent
    implicitWidth: 24; implicitHeight: 24
    readonly property var paths: ({
        wifi: "M3 8 C8 3 16 3 21 8 M6 12 C9 9 15 9 18 12 M9 16 C11 14 13 14 15 16 M12 20 L12 20.1",
        bluetooth: "M12 2 L18 7 L6 17 M6 7 L18 17 L12 22 L12 2",
        sound: "M3 9 H7 L12 5 V19 L7 15 H3 Z M16 8 C19 10 19 14 16 16 M19 5 C24 9 24 15 19 19",
        bell: "M5 17 H19 L17 14 V9 C17 2 7 2 7 9 V14 Z M10 20 C11 22 13 22 14 20",
        theme: "M12 3 C4 3 1 9 3 15 C5 22 14 22 14 18 C14 15 17 16 20 14 C24 10 20 3 12 3 Z M8 8 H8.1 M13 6 H13.1 M17 9 H17.1 M7 13 H7.1",
        style: "M3 4 H21 V20 H3 Z M3 9 H21 M9 9 V20 M6 6.5 H6.1",
        settings: "M4 6 H20 M4 12 H20 M4 18 H20 M8 3 V9 M16 9 V15 M10 15 V21",
        clipboard: "M8 5 H5 V21 H19 V5 H16 M8 3 H16 V7 H8 Z M8 12 H16 M8 16 H14",
        terminal: "M3 4 H21 V20 H3 Z M6 8 L10 12 L6 16 M13 16 H18",
        dropdown: "M3 4 H21 V20 H3 Z M3 8 H21 M9 12 L12 15 L15 12",
        grid: "M3 3 H10 V10 H3 Z M14 3 H21 V10 H14 Z M3 14 H10 V21 H3 Z M14 14 H21 V21 H14 Z",
        lock: "M5 10 H19 V21 H5 Z M8 10 V6 C8 1 16 1 16 6 V10 M12 15 V17",
        launch: "M13 3 H21 V11 M21 3 L10 14 M9 5 H3 V21 H19 V15",
        key: "M10 14 C3 17 0 10 4 6 C8 2 15 5 12 12 L21 21 M16 16 L19 13 M19 19 L22 16"
    })
    Canvas {
        id: paint
        width: 24; height: 24
        anchors.centerIn: parent
        scale: Math.min(icon.width, icon.height) / 24
        antialiasing: true
        renderStrategy: Canvas.Immediate
        contextType: "2d"
        onPaint: {
            const ctx = getContext("2d")
            if (!ctx) return
            ctx.reset()
            ctx.strokeStyle = icon.color
            ctx.lineWidth = 1.7
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            const data = icon.paths[icon.symbol] || icon.paths.settings
            let x = 0, y = 0
            let ptr = 0
            const tokens = []
            const re = /([MLHVCSQZAmlhvcsqza])|([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)/g
            let hit
            while ((hit = re.exec(data)) !== null) {
                if (hit[1]) tokens.push({ cmd: hit[1] })
                else tokens.push({ n: parseFloat(hit[2]) })
            }
            ctx.beginPath()
            const arg = index => tokens[ptr + index].n
            while (ptr < tokens.length && tokens[ptr].cmd) {
                const cmd = tokens[ptr++].cmd
                switch (cmd) {
                case "M": x = arg(0); y = arg(1); ptr += 2; ctx.moveTo(x, y); break
                case "m": x += arg(0); y += arg(1); ptr += 2; ctx.moveTo(x, y); break
                case "L": x = arg(0); y = arg(1); ptr += 2; ctx.lineTo(x, y); break
                case "l": x += arg(0); y += arg(1); ptr += 2; ctx.lineTo(x, y); break
                case "H": x = arg(0); ptr += 1; ctx.lineTo(x, y); break
                case "h": x += arg(0); ptr += 1; ctx.lineTo(x, y); break
                case "V": y = arg(0); ptr += 1; ctx.lineTo(x, y); break
                case "v": y += arg(0); ptr += 1; ctx.lineTo(x, y); break
                case "C": ctx.bezierCurveTo(arg(0), arg(1), arg(2), arg(3), arg(4), arg(5)); x = arg(4); y = arg(5); ptr += 6; break
                case "c": ctx.bezierCurveTo(x + arg(0), y + arg(1), x + arg(2), y + arg(3), x + arg(4), y + arg(5)); x += arg(4); y += arg(5); ptr += 6; break
                case "S": ctx.bezierCurveTo(x, y, arg(0), arg(1), arg(2), arg(3)); x = arg(2); y = arg(3); ptr += 4; break
                case "Q": ctx.quadraticCurveTo(arg(0), arg(1), arg(2), arg(3)); x = arg(2); y = arg(3); ptr += 4; break
                case "Z": case "z": ctx.closePath(); break
                }
            }
            ctx.stroke()
        }
    }
}
