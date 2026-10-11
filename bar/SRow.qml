import QtQuick

// One settings row: title + description on the left, control on the right.
// `stacked: true` puts the control on its own line below the text (wide controls).
Item {
    id: root

    property string title: ""
    property string desc: ""
    property string keywords: ""
    property bool stacked: false
    default property alias content: slot.data

    readonly property bool matches: Settings.query === ""
        || (title + " " + desc + " " + keywords).toLowerCase().indexOf(Settings.query) >= 0

    visible: matches
    width: parent ? parent.width : 400
    height: visible ? implicitHeight : 0
    implicitHeight: stacked
        ? head.implicitHeight + slot.height + 26
        : Math.max(head.implicitHeight, slot.height) + 22
    opacity: enabled ? 1 : 0.38

    Column {
        id: head
        anchors.left: parent.left
        anchors.right: root.stacked ? parent.right : slot.left
        anchors.rightMargin: root.stacked ? 0 : 20
        y: root.stacked ? 11 : (root.height - implicitHeight) / 2
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            color: Pal.text
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
        Text {
            width: parent.width
            visible: root.desc !== ""
            text: root.desc
            color: Pal.dim
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
    }

    Item {
        id: slot
        width: childrenRect.width
        height: childrenRect.height
        anchors.right: parent.right
        y: root.stacked ? head.y + head.implicitHeight + 10 : (root.height - height) / 2
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Pal.line
    }
}
