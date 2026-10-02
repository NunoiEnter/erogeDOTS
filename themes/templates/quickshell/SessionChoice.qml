import QtQuick
import QtQuick.Controls
import "Keyboard.js" as Keyboard

AbstractButton {
    id: choice
    property string japanese: ""
    property string description: ""
    property bool selected: false
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    Keys.onTabPressed: event => { Keyboard.move(choice, !(event.modifiers & Qt.ShiftModifier)); event.accepted = true; }
    Keys.onBacktabPressed: event => { Keyboard.move(choice, false); event.accepted = true; }
    Keys.onReturnPressed: event => { if (!event.isAutoRepeat) click(); event.accepted = true; }
    Keys.onEnterPressed: event => { if (!event.isAutoRepeat) click(); event.accepted = true; }
    Keys.onUpPressed: event => { Keyboard.move(choice, false); event.accepted = true; }
    Keys.onDownPressed: event => { Keyboard.move(choice, true); event.accepted = true; }
    Keys.onLeftPressed: event => { Keyboard.move(choice, false); event.accepted = true; }
    Keys.onRightPressed: event => { Keyboard.move(choice, true); event.accepted = true; }
    implicitHeight: 88
    implicitWidth: 960
    Accessible.name: text + ": " + description
    Accessible.description: description
    readonly property bool highlighted: enabled && (hovered || selected || visualFocus)
    readonly property color labelColor: Theme.retro ? (highlighted ? Theme.paper : Theme.ink) : (highlighted ? "#ff9de1" : "#fff8fa")
    opacity: enabled ? 1 : 0.45
    ToolTip.text: description
    ToolTip.visible: hovered && description !== ""
    ToolTip.delay: 700
    onActiveFocusChanged: {
        if (!activeFocus) return;
        // Keep every action reachable when a short screen needs to scroll.
        for (let view = parent; view; view = view.parent) {
            if (view.contentItem && view.contentY !== undefined && view.contentHeight !== undefined) {
                const top = mapToItem(view.contentItem, 0, 0).y;
                if (top < view.contentY) view.contentY = top;
                else if (top + height > view.contentY + view.height)
                    view.contentY = Math.min(view.contentHeight - view.height, top + height - view.height);
                break;
            }
        }
    }
    contentItem: Item {
        Column {
            anchors.centerIn: parent
            width: Math.max(0, parent.width - 40)
            spacing: 0
            VnText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: choice.text
                font.family: Theme.retro ? Theme.bodyFont : Theme.titleFont
                font.pixelSize: 28
                color: choice.labelColor
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            VnText {
                width: parent.width
                visible: text !== ""
                horizontalAlignment: Text.AlignHCenter
                text: choice.japanese
                font.family: Theme.retro ? Theme.bodyFont : Theme.titleFont
                font.pixelSize: 22
                color: choice.labelColor
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
    }
    background: Rectangle {
        radius: Theme.retro ? 0 : height / 2
        color: Theme.retro ? (choice.highlighted ? Theme.accent : Theme.paper) : "#08090a"
        border.width: 2
        border.color: choice.visualFocus ? (Theme.retro ? Theme.accent : "#ff9de1") : "#37343a"
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Canvas {
            visible: !Theme.retro
            anchors.fill: parent
            anchors.margins: 4
            property string textureSeed: choice.text
            onTextureSeedChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width, h = height, r = h / 2;
                if (w <= 0 || h <= 0) return;
                ctx.beginPath();
                ctx.moveTo(r, 0); ctx.lineTo(w - r, 0);
                ctx.arc(w - r, r, r, -Math.PI / 2, Math.PI / 2);
                ctx.lineTo(r, h); ctx.arc(r, r, r, Math.PI / 2, Math.PI * 1.5);
                ctx.closePath(); ctx.clip();
                ctx.fillStyle = "#171619";
                ctx.fillRect(0, 0, w, h);
                let seed = 1987;
                for (let i = 0; i < textureSeed.length; i++) seed = (seed * 31 + textureSeed.charCodeAt(i)) >>> 0;
                function random() { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; }
                // Static washi fibers: painted only when the label or size changes.
                for (let i = 0; i < w * h / 5; i++) {
                    const x = random() * w, y = random() * h;
                    const light = random() > 0.54;
                    ctx.fillStyle = light ? "rgba(137,128,137,0.12)" : "rgba(0,0,0,0.30)";
                    ctx.fillRect(x, y, 1 + random() * 3, 0.5 + random() * 1.5);
                }
                for (let i = 0; i < w / 36; i++) {
                    const x = random() * w;
                    const y = random() > 0.5 ? 3 + random() * 9 : h - 3 - random() * 9;
                    const size = 1.5 + random() * 2;
                    ctx.fillStyle = i % 3 === 0 ? "#c0a466" : "#ded7c8";
                    ctx.globalAlpha = 0.45 + random() * 0.4;
                    ctx.beginPath(); ctx.moveTo(x, y);
                    ctx.lineTo(x + size, y - size * 0.35);
                    ctx.lineTo(x + size * 0.65, y + size);
                    ctx.lineTo(x - size * 0.4, y + size * 0.6);
                    ctx.closePath(); ctx.fill();
                }
                ctx.globalAlpha = 1;
            }
        }
        Rectangle {
            visible: !Theme.retro
            anchors.fill: parent
            anchors.margins: 4
            radius: height / 2
            color: "transparent"
            border.width: 1
            border.color: choice.down ? "#8b7a8c" : "#5b555e"
        }
        RetroBevel { anchors.fill: parent; visible: Theme.retro; sunken: choice.down || choice.highlighted }
    }
}
