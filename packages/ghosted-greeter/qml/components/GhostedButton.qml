import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string text: ""
    property string iconSource: ""
    property bool isPrimary: false
    property bool isDestructive: false
    property bool loading: false
    property int customHeight: 44
    property int customWidth: 0

    signal clicked()

    implicitWidth: customWidth > 0 ? customWidth : (btnContent.implicitWidth + 36)
    implicitHeight: customHeight

    opacity: enabled ? 1.0 : 0.4
    Behavior on opacity { NumberAnimation { duration: 180 } }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 8
        color: {
            if (!root.enabled) return "transparent"
            if (root.loading) {
                return root.isPrimary ? "#d8d8d8" : "#222222"
            }
            if (mouseArea.pressed) {
                return root.isPrimary ? "#ffffff" : (root.isDestructive ? "#cf6679" : "#383838")
            }
            if (mouseArea.containsMouse || root.activeFocus) {
                return root.isPrimary ? "#e0e0e0" : (root.isDestructive ? "#4a282e" : "#282828")
            }
            return root.isPrimary ? "#cccccc" : (root.isDestructive ? "#2a1518" : "#161616")
        }
        border.color: {
            if (root.activeFocus) return "#ffffff"
            if (mouseArea.containsMouse) return root.isDestructive ? "#cf6679" : "#555555"
            return root.isPrimary ? "#cccccc" : (root.isDestructive ? "#522227" : "#2e2e2e")
        }
        border.width: root.activeFocus ? 2 : 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Row {
        id: btnContent
        anchors.centerIn: parent
        spacing: 10

        // Hardware-accelerated vector spinner (zero FBO overhead)
        Item {
            id: spinnerItem
            visible: root.loading
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source: root.isPrimary ? Qt.resolvedUrl("../../assets/spinner.svg") : Qt.resolvedUrl("../../assets/spinner-light.svg")
                sourceSize: Qt.size(16, 16)
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 750
                    loops: Animation.Infinite
                    running: root.loading && root.visible
                }
            }
        }

        Image {
            id: btnIcon
            visible: !root.loading && root.iconSource !== ""
            source: root.iconSource
            width: 15
            height: 15
            sourceSize: Qt.size(15, 15)
            anchors.verticalCenter: parent.verticalCenter
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: mouseArea.containsMouse ? 0.95 : 0.65
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }


        Text {
            id: btnText
            text: root.text
            anchors.verticalCenter: parent.verticalCenter
            font.family: backend ? backend.fontFamily : "sans-serif"
            font.pixelSize: 14
            font.weight: root.isPrimary ? Font.Medium : Font.Normal
            color: {
                if (root.isPrimary) {
                    return mouseArea.pressed ? "#000000" : "#121212"
                }
                if (root.isDestructive) {
                    return mouseArea.containsMouse ? "#ffffff" : "#cf6679"
                }
                return mouseArea.containsMouse || root.activeFocus ? "#ffffff" : "#c0c0c0"
            }
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (root.enabled && !root.loading) ? Qt.PointingHandCursor : (root.loading ? Qt.WaitCursor : Qt.ArrowCursor)
        onClicked: {
            if (root.enabled && !root.loading) {
                root.clicked()
            }
        }
    }

    Keys.onReturnPressed: if (root.enabled && !root.loading) root.clicked()
    Keys.onEnterPressed: if (root.enabled && !root.loading) root.clicked()
    Keys.onSpacePressed: if (root.enabled && !root.loading) root.clicked()
}
