import QtQuick

Item {
    width: 9
    height: Settings.itemH

    Rectangle {
        anchors.centerIn: parent
        width: 1
        height: Math.round(parent.height * 0.47)
        color: Settings.col(Settings.c.textColor, 0.15)
    }
}
