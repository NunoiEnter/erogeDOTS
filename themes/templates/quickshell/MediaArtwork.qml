import QtQuick

Rectangle {
    id: artwork
    property string source: ""
    color: Theme.tint
    border.color: Theme.line
    // The disc is an explicit fallback when the player provides no cover.
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.62
        height: width
        radius: width / 2
        color: Theme.accent
        visible: cover.status !== Image.Ready
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.27
            height: width
            radius: width / 2
            color: Theme.paper
        }
    }
    Image {
        id: cover
        anchors.fill: parent
        anchors.margins: 2
        source: artwork.source
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.ceil(artwork.width * 2)
        sourceSize.height: Math.ceil(artwork.height * 2)
        asynchronous: true
        clip: true
        visible: status === Image.Ready
    }
}
