import QtQuick
import QtQuick.Controls
import "components"

Item {
    id: root

    property bool isOpen: false
    property string dialogType: "reboot" // "reboot" or "shutdown"

    anchors.fill: parent
    visible: opacity > 0.0
    opacity: isOpen ? 1.0 : 0.0
    z: 200

    Behavior on opacity { NumberAnimation { duration: 200 } }

    function open(type) {
        dialogType = type
        isOpen = true
        confirmBtn.forceActiveFocus()
    }

    function close() {
        isOpen = false
    }

    // Dimmed modal backdrop
    Rectangle {
        anchors.fill: parent
        color: "#d0000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Modal Card
    Rectangle {
        id: card
        width: 360
        height: 190
        anchors.centerIn: parent
        radius: 12
        color: "#181818"
        border.color: "#333333"
        border.width: 1
        scale: root.isOpen ? 1.0 : 0.92

        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            Column {
                width: parent.width
                spacing: 8

                Text {
                    id: titleText
                    text: root.dialogType === "reboot" ? "Reboot System?" : "Shutdown System?"
                    color: "#ffffff"
                    font.family: backend ? backend.fontFamily : "sans-serif"
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: root.dialogType === "reboot"
                          ? "The system will close all applications and restart."
                          : "The system will close all applications and power off."
                    color: "#8e8e8e"
                    font.family: backend ? backend.fontFamily : "sans-serif"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                GhostedButton {
                    text: "Cancel"
                    customWidth: 120
                    onClicked: root.close()
                }

                GhostedButton {
                    id: confirmBtn
                    text: root.dialogType === "reboot" ? "Reboot" : "Shutdown"
                    isDestructive: true
                    customWidth: 120
                    onClicked: {
                        root.close()
                        if (root.dialogType === "reboot") {
                            backend.requestReboot()
                        } else {
                            backend.requestShutdown()
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.close()
    Keys.onReturnPressed: {
        if (root.isOpen) {
            confirmBtn.clicked()
        }
    }
}
