import QtQuick
import QtQuick.Controls

Item {
    id: root

    property alias text: passInput.text
    property bool passwordVisible: false

    signal accepted()
    signal requestPrevious()

    implicitWidth: 320
    implicitHeight: 48

    function clear() {
        passInput.text = ""
    }

    function forceFocus() {
        passInput.forceActiveFocus()
    }

    function triggerShake() {
        shakeAnimation.restart()
    }

    Item {
        id: container
        anchors.fill: parent

        // Horizontal shake animation on authentication failure
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
                if (backend && backend.authError !== "") return "#cf6679"
                if (passInput.activeFocus) return "#777777"
                if (mouseArea.containsMouse) return "#444444"
                return "#2c2c2c"
            }
            border.width: passInput.activeFocus ? 2 : 1

            Behavior on border.color { ColorAnimation { duration: 150 } }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            spacing: 10

            // Lock Vector Icon
            Image {
                id: lockIcon
                source: Qt.resolvedUrl("../assets/lock.svg")
                width: 16
                height: 16
                sourceSize: Qt.size(16, 16)
                fillMode: Image.PreserveAspectFit
                anchors.verticalCenter: parent.verticalCenter
                smooth: true
                mipmap: true
                opacity: passInput.activeFocus ? 0.75 : 0.38

                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            TextInput {
                id: passInput
                width: parent.width - 60 - (capsLockIndicator.visible ? 30 : 0)
                anchors.verticalCenter: parent.verticalCenter

                font.family: backend ? backend.fontFamily : "sans-serif"
                font.pixelSize: 15
                color: "#f0f0f0"
                echoMode: root.passwordVisible ? TextInput.Normal : TextInput.Password
                passwordCharacter: "•"
                passwordMaskDelay: 0
                clip: true
                enabled: root.enabled
                selectByMouse: true
                selectionColor: "#404040"
                selectedTextColor: "#ffffff"

                Text {
                    id: placeholder
                    text: "Password"
                    color: "#606060"
                    font.family: parent.font.family
                    font.pixelSize: parent.font.pixelSize
                    visible: passInput.text.length === 0 && !passInput.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                }

                Keys.onReturnPressed: {
                    if (root.enabled) root.accepted()
                }
                Keys.onEnterPressed: {
                    if (root.enabled) root.accepted()
                }
                Keys.onUpPressed: root.requestPrevious()
                Keys.onBacktabPressed: root.requestPrevious()

                // Detect Caps Lock state changes if available
                Keys.onPressed: (event) => {
                    if (event.modifiers & Qt.ShiftModifier) {
                        // user shift
                    }
                    if (backend && typeof backend.setCapsLock === "function") {
                        // Check caps lock via native modifiers if supported
                    }
                }
            }

            // Caps Lock warning indicator
            Item {
                id: capsLockIndicator
                visible: backend ? backend.capsLockOn : false
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "⇪"
                    color: "#ffb74d"
                    font.pixelSize: 14
                }
            }

            // Eye Icon / Button for Password Visibility Toggle
            Item {
                id: eyeBtn
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: eyeIcon
                    anchors.centerIn: parent
                    source: root.passwordVisible ? Qt.resolvedUrl("../assets/eye-off.svg") : Qt.resolvedUrl("../assets/eye.svg")
                    width: 17
                    height: 17
                    sourceSize: Qt.size(17, 17)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    opacity: eyeMouseArea.containsMouse ? 0.9 : 0.45
                    scale: eyeMouseArea.pressed ? 0.9 : 1.0

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                MouseArea {
                    id: eyeMouseArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.passwordVisible = !root.passwordVisible
                        passInput.forceActiveFocus()
                    }
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            z: -1
            onClicked: passInput.forceActiveFocus()
        }
    }
}
