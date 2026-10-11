import QtQuick

// Segmented control. model: [{ label, value }]
Rectangle {
    id: root

    property var model: []
    property var current
    signal picked(var value)

    width: row.width + 6
    height: 28
    radius: 8
    color: Pal.bg3

    Row {
        id: row
        x: 3
        y: 3
        spacing: 2

        Repeater {
            model: root.model
            delegate: Rectangle {
                id: seg
                required property var modelData
                readonly property bool sel: root.current === modelData.value

                height: 22
                width: lbl.implicitWidth + 20
                radius: 6
                color: sel ? Pal.accent : (ma.containsMouse ? "#18ffffff" : "transparent")
                Behavior on color { ColorAnimation { duration: Settings.ms(100) } }

                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text: seg.modelData.label
                    color: seg.sel ? Pal.onAccent : Pal.text
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(seg.modelData.value)
                }
            }
        }
    }
}
