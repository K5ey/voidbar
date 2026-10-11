import QtQuick

// Titled card of rows. Shows its page, or every section with a match while searching.
Item {
    id: root

    property string title: ""
    property string page: ""
    default property alias content: body.data

    function hasMatch() {
        const ch = body.children;
        for (let i = 0; i < ch.length; i++) if (ch[i].matches === true) return true;
        return false;
    }
    readonly property bool any: hasMatch()

    visible: Settings.query === "" ? page === Settings.page : any
    width: parent ? parent.width : 400
    height: visible ? card.height + 22 : 0

    Text {
        id: head
        text: root.title.toUpperCase()
        color: Pal.dim
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 1.2
        x: 4
    }

    Rectangle {
        id: card
        y: head.height + 8
        width: parent.width
        height: body.height + 4
        radius: 12
        color: Pal.bg2
        border.width: 1
        border.color: Pal.line

        Column {
            id: body
            x: 16
            y: 2
            width: parent.width - 32
        }
    }
}
