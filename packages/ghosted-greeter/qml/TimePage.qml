import QtQuick
import QtQuick.Controls

Item {
    id: root

    signal requestAuth()

    anchors.fill: parent

    Column {
        id: timeContent
        anchors.centerIn: parent
        spacing: 32

        // Digital Clock
        Column {
            id: clockColumn
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: -20

            // Stacked Clock: Hours on top, Minutes on bottom
            Text {
                id: hoursText
                visible: backend ? backend.stackedClock : false
                text: backend ? backend.clockHours : "21"
                color: "#ffffff"
                font.family: backend ? backend.fontFamily : "sans-serif"
                font.pixelSize: backend ? backend.clockFontSize : 150
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                id: minutesText
                visible: backend ? backend.stackedClock : false
                text: backend ? backend.clockMinutes : "57"
                color: "#e8e8e8"
                font.family: backend ? backend.fontFamily : "sans-serif"
                font.pixelSize: backend ? backend.clockFontSize : 150
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Single line Clock (if configured)
            Text {
                id: fullClockText
                visible: backend ? !backend.stackedClock : false
                text: backend ? backend.clockFull : "21:57"
                color: "#ffffff"
                font.family: backend ? backend.fontFamily : "sans-serif"
                font.pixelSize: backend ? Math.round(backend.clockFontSize * 0.8) : 120
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Optional Date
        Text {
            id: dateText
            visible: backend ? backend.showDate : true
            text: backend ? backend.clockDate : "Thursday, September 18"
            color: "#a8a8a8"
            font.family: backend ? backend.fontFamily : "sans-serif"
            font.pixelSize: backend ? Math.round(backend.brandFontSize * 0.95) : 23
            font.weight: Font.Normal
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Branding
        Text {
            id: brandText
            text: backend ? backend.brandName : "Ghosted Arch"
            color: "#6c6c6c"
            font.family: backend ? backend.fontFamily : "sans-serif"
            font.pixelSize: backend ? backend.brandFontSize : 24
            font.weight: Font.Medium
            font.letterSpacing: 4
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Interaction hint at bottom
    Text {
        id: hintText
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 42
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Press any key or click to unlock"
        color: "#555555"
        font.family: backend ? backend.fontFamily : "sans-serif"
        font.pixelSize: 15
        font.letterSpacing: 1

        opacity: 0.60
    }

    // Mouse area covering entire time page
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.requestAuth()
    }

    // Keyboard listener for any key
    Keys.onPressed: (event) => {
        root.requestAuth()
    }
}
