import QtQuick

// "CPU 12%": dim label, bright value. With statsStyle "icons" the label becomes a glyph.
Row {
    id: root

    property string label: ""
    property string glyph: ""
    property string value: ""
    property color valueColor: Settings.col(Settings.c.textColor)

    readonly property bool useIcon: Settings.c.statsStyle === "icons" && glyph !== ""

    spacing: 5

    Label {
        text: root.useIcon ? root.glyph : root.label
        icon: root.useIcon
        color: Settings.col(Settings.c.textColor, 0.5)
        font.pixelSize: root.useIcon ? Math.max(10, Settings.c.iconSize - 3) : Math.max(8, Settings.c.fontSize - 3)
        font.bold: !root.useIcon
        font.letterSpacing: root.useIcon ? 0 : 0.8
    }
    Label {
        text: root.value
        color: root.valueColor
    }
}
