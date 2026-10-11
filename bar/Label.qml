import QtQuick

// Text with the bar's defaults. Set `icon: true` for Nerd Font glyphs.
// Icons need a Nerd Font installed (Arch/Artix: ttf-nerd-fonts-symbols).
Text {
    property bool icon: false

    color: Settings.col(Settings.c.textColor)
    height: Settings.itemH
    verticalAlignment: Text.AlignVCenter
    font.family: icon ? Settings.c.iconFont
               : (Settings.c.fontFamily !== "" ? Settings.c.fontFamily : Qt.application.font.family)
    font.pixelSize: icon ? Settings.c.iconSize : Settings.c.fontSize
}
