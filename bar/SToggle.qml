import QtQuick

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool value)

    width: 40
    height: 22
    radius: 11
    color: checked ? Pal.accent : Pal.bg3
    Behavior on color { ColorAnimation { duration: Settings.ms(120) } }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        y: 3
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? Pal.onAccent : "#c7cad4"
        Behavior on x { NumberAnimation { duration: Settings.ms(120); easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
