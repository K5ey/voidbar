import QtQuick

// Text box that commits on Enter / focus loss. Esc reverts and leaves the field.
Rectangle {
    id: root

    property string value: ""
    property string placeholder: ""
    property bool mono: false
    signal committed(string text)

    width: 200
    height: 28
    radius: 8
    color: Pal.bg3
    border.width: 1
    border.color: input.activeFocus ? Pal.accent : "transparent"

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: Pal.text
        selectionColor: Pal.accent
        selectedTextColor: Pal.onAccent
        font.pixelSize: 12
        font.family: root.mono ? "monospace" : Qt.application.font.family
        text: root.value
        onEditingFinished: { if (text !== root.value) root.committed(text); }
        Keys.onEscapePressed: event => { text = root.value; focus = false; Settings.refocus(); event.accepted = true; }
    }

    Text {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === "" && !input.activeFocus
        text: root.placeholder
        color: Pal.dim
        font.pixelSize: 12
    }
}
