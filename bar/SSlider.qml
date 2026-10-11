import QtQuick

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property string unit: ""
    property int decimals: 0
    property real trackWidth: 150
    signal moved(real v)

    width: trackWidth + 74
    height: 28

    readonly property real ratio: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

    function snap(v) {
        const s = stepSize > 0 ? Math.round((v - from) / stepSize) * stepSize + from : v;
        return Math.max(from, Math.min(to, Number(s.toFixed(4))));
    }

    Rectangle {
        id: track
        width: root.trackWidth
        height: 4
        radius: 2
        anchors.verticalCenter: parent.verticalCenter
        color: Pal.bg3

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: 2
            color: Pal.accent
        }
    }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        x: track.width * root.ratio - 7
        anchors.verticalCenter: parent.verticalCenter
        color: drag.pressed || drag.containsMouse ? "#ffffff" : "#d4d7e0"
        border.width: 2
        border.color: Pal.accent
        scale: drag.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Settings.ms(90) } }
    }

    MouseArea {
        id: drag
        x: -8
        width: track.width + 16
        height: parent.height
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        function update(mx) {
            const r = Math.max(0, Math.min(1, (mx - 8) / track.width));
            const v = root.snap(root.from + r * (root.to - root.from));
            if (v !== root.value) root.moved(v);
        }
        onPressed: mouse => update(mouse.x)
        onPositionChanged: mouse => { if (pressed) update(mouse.x); }
    }

    Text {
        x: track.width + 14
        width: 60
        anchors.verticalCenter: parent.verticalCenter
        text: Number(root.value).toFixed(root.decimals) + root.unit
        color: Pal.dim
        font.pixelSize: 12
        font.family: "monospace"
        horizontalAlignment: Text.AlignRight
    }
}
