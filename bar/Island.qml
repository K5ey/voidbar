import QtQuick

// One floating glass capsule. Hyprland blurs it through the "qsbar" layer rule.
// With islandStyle "bar" the capsule is invisible and Bar.qml draws one background behind all three.
Rectangle {
    id: root

    property int padding: Settings.c.islandPadding
    property bool active: true
    default property alias content: holder.data

    readonly property bool flat: Settings.c.islandStyle === "bar"

    visible: active && holder.childrenRect.width > 0
    implicitWidth: holder.childrenRect.width + padding * 2
    radius: Math.min(Settings.c.islandRadius, height / 2)
    color: flat ? "transparent" : Settings.col(Settings.c.bgColor, Settings.c.bgOpacity)
    border.width: !flat && Settings.c.borderEnabled ? Settings.c.borderWidth : 0
    border.color: Settings.col(Settings.c.borderColor, Settings.c.borderOpacity)

    Behavior on width { NumberAnimation { duration: Settings.ms(180); easing.type: Easing.OutCubic } }

    Item {
        id: holder
        x: root.padding
        width: childrenRect.width
        height: parent.height
    }
}
