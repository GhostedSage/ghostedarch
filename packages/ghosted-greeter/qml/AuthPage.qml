import QtQuick
import QtQuick.Controls
import "components"

Item {
    id: root

    signal requestTime()
    signal requestReboot()
    signal requestShutdown()

    anchors.fill: parent

    function reset() {
        passField.clear()
        if (backend) {
            backend.cancelAuth()
        }
    }

    function focusInput() {
        if (userSel.text.trim().length === 0) {
            userSel.forceFocus()
        } else {
            passField.forceFocus()
        }
    }

    function doLogin() {
        if (!backend || backend.isAuthenticating) return
        if (userSel.text.trim().length === 0) {
            userSel.triggerShake()
            userSel.forceFocus()
            return
        }
        backend.selectUser(userSel.text.trim())
        if (passField.text.length === 0) {
            passField.triggerShake()
            passField.forceFocus()
            return
        }
        backend.authenticate(backend.currentUser, passField.text)
    }

    // Connections to backend signals
    Connections {
        target: backend

        function onAuthFailed(message) {
            passField.triggerShake()
            passField.clear()
            passField.forceFocus()
        }
    }

    Column {
        id: authCard
        anchors.centerIn: parent
        spacing: 24
        width: 320

        // Dragon Logo
        Image {
            id: authLogo
            source: backend ? backend.logoUrl : Qt.resolvedUrl("../assets/icon.svg")
            width: backend ? (backend.logoSize * 0.85) : 80
            height: backend ? (backend.logoSize * 0.85) : 80
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            smooth: true
            mipmap: true
        }

        // Branding
        Text {
            id: authBrand
            text: backend ? backend.brandName : "Ghosted Arch"
            color: "#6c6c6c"
            font.family: backend ? backend.fontFamily : "sans-serif"
            font.pixelSize: backend ? (backend.brandFontSize * 0.9) : 17
            font.weight: Font.Medium
            font.letterSpacing: 3
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item { height: 4; width: 1 }

        // Username Field (Auto-detected, directly editable)
        UserSelector {
            id: userSel
            anchors.horizontalCenter: parent.horizontalCenter
            enabled: backend ? !backend.isAuthenticating : true
            onAccepted: passField.forceFocus()
        }

        // Password Field
        PasswordField {
            id: passField
            anchors.horizontalCenter: parent.horizontalCenter
            enabled: backend ? !backend.isAuthenticating : true
            onAccepted: root.doLogin()
            onRequestPrevious: userSel.forceFocus()
        }

        // Subtle Error Message
        Text {
            id: errorText
            visible: backend ? (backend.authError !== "") : false
            text: backend ? backend.authError : ""
            color: "#e57373"
            font.family: backend ? backend.fontFamily : "sans-serif"
            font.pixelSize: 13
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: visible ? 1.0 : 0.0

            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // Login Button with Loading Spinner
        GhostedButton {
            id: loginBtn
            text: backend && backend.isAuthenticating ? "Logging in..." : "Login"
            loading: backend ? backend.isAuthenticating : false
            isPrimary: true
            enabled: backend ? !backend.isAuthenticating : true
            anchors.horizontalCenter: parent.horizontalCenter
            customWidth: 320
            onClicked: root.doLogin()
        }

        Item { height: 16; width: 1 }

        // Power Actions (Reboot & Shutdown)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            GhostedButton {
                id: rebootBtn
                visible: backend ? backend.showReboot : true
                enabled: backend ? !backend.isAuthenticating : true
                iconSource: Qt.resolvedUrl("../assets/reboot.svg")
                text: "Reboot"
                customHeight: 36
                onClicked: root.requestReboot()
            }

            GhostedButton {
                id: shutdownBtn
                visible: backend ? backend.showShutdown : true
                enabled: backend ? !backend.isAuthenticating : true
                iconSource: Qt.resolvedUrl("../assets/power.svg")
                text: "Shutdown"
                customHeight: 36
                onClicked: root.requestShutdown()
            }
        }
    }

    // Escape key handling: return to TimePage and clear password
    Keys.onEscapePressed: {
        root.reset()
        root.requestTime()
    }
}
