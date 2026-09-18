// CalendarPopup.qml
import QtQuick
import QtQuick.Controls
import "../" as Modules

Rectangle {
    id: popup
    implicitWidth: 230
    implicitHeight: 270
    radius: 8
    color: "transparent"
    border.color: Modules.Theme.foreground
    border.width: 0


    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: Qt.formatDate(new Date(), "MMMM yyyy")
            color: Modules.Theme.foreground
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
        }

        Row {
            spacing: 4
            Repeater {
                model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                delegate: Text {
                    text: modelData
                    color: Modules.Theme.foreground
                    font.pixelSize: 12
                    width: 24
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Grid {
            id: dayGrid
            columns: 7
            spacing: 4
            property date today: new Date()
            property int year: today.getFullYear()
            property int month: today.getMonth()
            property int daysInMonth: new Date(year, month + 1, 0).getDate()
            property int firstDay: (new Date(year, month, 1).getDay() + 6) % 7

            Repeater {
                model: dayGrid.firstDay + dayGrid.daysInMonth
                delegate: Rectangle {
                    id: day
                    width: 24; height: 24; radius: 4

                    readonly property bool inMonth: index >= dayGrid.firstDay
                    readonly property int dayNum: index - dayGrid.firstDay + 1
                    readonly property bool isToday: inMonth && dayNum === dayGrid.today.getDate()

                    border.color: Modules.Theme.foreground
                    border.width: inMonth ? 1 : 0
                    color: isToday ? Modules.Theme.foreground : "transparent"

                    Text {
                        anchors.centerIn: parent
                        color: day.isToday ? Modules.Theme.onAccent : Modules.Theme.foreground
                        text: day.inMonth ? day.dayNum : ""
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

}
