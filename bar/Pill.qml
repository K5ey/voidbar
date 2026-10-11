import QtQuick

// Hoverable, clickable chip. Put content inside; use `overlay` for things
// that must be positioned relative to the whole chip (indicators, badges).
Rectangle {
    id: root

    property bool highlighted: false
    property int padX: 10
    property color hoverColor: Settings.col(Settings.c.textColor, Settings.c.hoverOpacity)

    default property alias content: holder.data
    property alias overlay: overlayItem.data
    readonly property alias hovered: area.containsMouse

    signal clicked(var mouse)
    signal wheeled(var wheel)

    implicitWidth: holder.childrenRect.width + padX * 2
    implicitHeight: Settings.itemH
    radius: Math.min(Settings.c.pillRadius, implicitHeight / 2)
    color: area.pressed ? Settings.col(Settings.c.textColor, Settings.c.hoverOpacity + 0.08)
         : area.containsMouse ? hoverColor
         : highlighted ? Settings.col(Settings.c.textColor, Settings.c.hoverOpacity * 0.6)
         : "transparent"

    Behavior on color { ColorAnimation { duration: Settings.ms(120) } }

    Item {
        id: holder
        anchors.centerIn: parent
        width: childrenRect.width
        height: parent.height
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheeled(wheel)
    }

    Item {
        id: overlayItem
        anchors.fill: parent
    }
}
