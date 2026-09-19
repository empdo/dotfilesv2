// Toggle.qml -- the small on/off switch used for the Wi-Fi and Bluetooth radios.
import QtQuick
import "../" as Modules

Rectangle {
    id: root

    property bool checked: false
    property bool enabled: true

    signal toggled

    implicitWidth: 34
    implicitHeight: 18
    radius: height / 2

    color: checked ? Modules.Theme.foreground : Modules.Theme.trough
    opacity: enabled ? 1.0 : 0.4

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    Rectangle {
        width: parent.height - 4
        height: width
        radius: width / 2
        y: 2
        x: root.checked ? parent.width - width - 2 : 2
        // Rides on the filled track when on, so it stays visible in both themes.
        color: root.checked ? Modules.Theme.background : Modules.Theme.inactive

        Behavior on x {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
