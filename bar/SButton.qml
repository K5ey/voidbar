import QtQuick

Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    property bool danger: false
    signal clicked()

    width: lbl.implicitWidth + 24
    height: 28
    radius: 8
    color: ma.pressed ? "#33ffffff"
         : primary ? (ma.containsMouse ? Qt.lighter(Pal.accent, 1.12) : Pal.accent)
         : ma.containsMouse ? "#2effffff" : Pal.bg3
    Behavior on color { ColorAnimation { duration: Settings.ms(100) } }

    Text {
        id: lbl
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Pal.onAccent : (root.danger ? Pal.danger : Pal.text)
        font.pixelSize: 12
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
