import QtQuick

// Colour field: preview swatch, hex box and a row of quick swatches.
Item {
    id: root

    property string value: "#ffffff"
    property var swatches: ["#ffffff", "#7aa2ff", "#cba6f7", "#a6e3a1", "#fab387", "#f38ba8", "#f9e2af", "#94e2d5"]
    signal picked(string hex)

    width: row.width
    height: 28

    Row {
        id: row
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.swatches
            delegate: Rectangle {
                id: sw
                required property string modelData
                width: 18
                height: 18
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                color: Settings.col(modelData)
                border.width: root.value.toLowerCase() === modelData.toLowerCase() ? 2 : 1
                border.color: root.value.toLowerCase() === modelData.toLowerCase() ? Pal.text : "#33ffffff"
                scale: swMa.containsMouse ? 1.15 : 1
                Behavior on scale { NumberAnimation { duration: Settings.ms(90) } }
                MouseArea {
                    id: swMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(sw.modelData)
                }
            }
        }

        Rectangle {
            width: 26
            height: 26
            radius: 7
            color: Settings.col(root.value)
            border.width: 1
            border.color: "#40ffffff"
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 86
            height: 28
            radius: 8
            color: Pal.bg3
            border.width: 1
            border.color: hex.activeFocus ? (Settings.validHex(hex.text) ? Pal.accent : Pal.danger) : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            TextInput {
                id: hex
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Pal.text
                selectionColor: Pal.accent
                selectedTextColor: Pal.onAccent
                font.pixelSize: 12
                font.family: "monospace"
                maximumLength: 7
                text: root.value
                onEditingFinished: {
                    if (Settings.validHex(text)) root.picked(Settings.normHex(text));
                    else text = root.value;
                }
                Keys.onEscapePressed: event => { text = root.value; focus = false; Settings.refocus(); event.accepted = true; }
            }
            Connections {
                target: root
                function onValueChanged() { if (!hex.activeFocus) hex.text = root.value; }
            }
        }
    }
}
