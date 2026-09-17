// CalendarPopup.qml
import QtQuick
import QtQuick.Controls

Rectangle {
    id: popup
    implicitWidth: 230
    implicitHeight: 270
    radius: 8
    color: "transparent"
    border.color: "#ebffd9"
    border.width: 0


    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: Qt.formatDate(new Date(), "MMMM yyyy")
            color: "#ebffd9"
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
                    color: "#ebffd9"
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
                    width: 24; height: 24; radius: 4
                    border.color: "#ebffd9"
                    border.width: index >= dayGrid.firstDay ? 1 : 0
                    color: {
                        const dayNum = index - dayGrid.firstDay + 1
                        return index >= dayGrid.firstDay && dayNum === dayGrid.today.getDate()
                            ? "#ebffd9" : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        color: parent.color === "#ebffd9" ? "#1a1a1a" : "#ebffd9"
                        text: index >= dayGrid.firstDay ? (index - dayGrid.firstDay + 1) : ""
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

}
