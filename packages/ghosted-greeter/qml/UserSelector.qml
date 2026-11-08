import QtQuick
import QtQuick.Controls

Item {
    id: root

    property alias text: userInput.text
    signal accepted()

    implicitWidth: 320
    implicitHeight: 48

    function forceFocus() {
        userInput.forceActiveFocus()
    }

    function clear() {
        userInput.text = ""
    }

    function triggerShake() {
        shakeAnimation.restart()
    }

    // Auto-detect and sync with backend
    Component.onCompleted: {
        if (backend && backend.currentUser) {
            userInput.text = backend.currentUser
        }
    }

    Connections {
        target: backend

        function onUserChanged() {
            if (!userInput.activeFocus && backend && backend.currentUser) {
                if (userInput.text !== backend.currentUser) {
                    userInput.text = backend.currentUser
                }
            }
        }
    }

    Item {
        id: container
        anchors.fill: parent

        // Horizontal shake animation on empty input warning
        SequentialAnimation {
            id: shakeAnimation
            NumberAnimation { target: container; property: "x"; from: 0; to: -10; duration: 50; easing.type: Easing.OutQuad }
            NumberAnimation { target: container; property: "x"; from: -10; to: 10; duration: 70; easing.type: Easing.InOutQuad }
            NumberAnimation { target: container; property: "x"; from: 10; to: -8; duration: 70; easing.type: Easing.InOutQuad }
            NumberAnimation { target: container; property: "x"; from: -8; to: 8; duration: 70; easing.type: Easing.InOutQuad }
            NumberAnimation { target: container; property: "x"; from: 8; to: -4; duration: 60; easing.type: Easing.InOutQuad }
            NumberAnimation { target: container; property: "x"; from: -4; to: 0; duration: 60; easing.type: Easing.OutQuad }
        }

        Rectangle {
            id: fieldBg
            anchors.fill: parent
            radius: 8
            color: "#161616"
            border.color: {
                if (userInput.activeFocus) return "#777777"
                if (mouseArea.containsMouse) return "#444444"
                return "#2c2c2c"
            }
            border.width: userInput.activeFocus ? 2 : 1

            Behavior on border.color { ColorAnimation { duration: 150 } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 10

                // User Vector Icon
                Image {
                    id: userIcon
                    source: Qt.resolvedUrl("../assets/user.svg")
                    width: 16
                    height: 16
                    sourceSize: Qt.size(16, 16)
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter
                    smooth: true
                    mipmap: true
                    opacity: userInput.activeFocus ? 0.75 : 0.38

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                TextInput {
                    id: userInput
                    width: parent.width - 26 - (clearBtn.visible ? 34 : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: backend ? backend.fontFamily : "sans-serif"
                    font.pixelSize: 15
                    color: "#f0f0f0"
                    clip: true
                    enabled: root.enabled
                    selectByMouse: true
                    selectionColor: "#404040"
                    selectedTextColor: "#ffffff"

                    Text {
                        id: placeholder
                        text: "Username"
                        color: "#606060"
                        font.family: parent.font.family
                        font.pixelSize: parent.font.pixelSize
                        visible: userInput.text.length === 0 && !userInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    onTextEdited: {
                        if (backend && userInput.text.trim().length > 0) {
                            backend.selectUser(userInput.text.trim())
                        }
                    }

                    Keys.onReturnPressed: {
                        if (backend && userInput.text.trim().length > 0) {
                            backend.selectUser(userInput.text.trim())
                        }
                        root.accepted()
                    }

                    Keys.onEnterPressed: {
                        if (backend && userInput.text.trim().length > 0) {
                            backend.selectUser(userInput.text.trim())
                        }
                        root.accepted()
                    }

                    Keys.onTabPressed: {
                        if (backend && userInput.text.trim().length > 0) {
                            backend.selectUser(userInput.text.trim())
                        }
                        root.accepted()
                    }

                    Keys.onDownPressed: root.accepted()
                }

                // Quick clear button when editing
                Item {
                    id: clearBtn
                    width: 24
                    height: 24
                    visible: userInput.activeFocus && userInput.text.length > 0
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.centerIn: parent
                        source: Qt.resolvedUrl("../assets/close.svg")
                        width: 12
                        height: 12
                        sourceSize: Qt.size(12, 12)
                        fillMode: Image.PreserveAspectFit
                        opacity: clearMouse.containsMouse ? 0.9 : 0.4
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            userInput.text = ""
                            userInput.forceActiveFocus()
                        }
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                z: -1
                onClicked: userInput.forceActiveFocus()
            }
        }
    }
}
