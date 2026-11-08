import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Window {
    id: mainWindow

    visible: true
    title: backend && backend.isDemoMode ? "Ghosted Greeter (Demo Mode)" : "Ghosted Greeter"
    color: "#000000"

    // In demo mode, start with comfortable windowed size; in production, fullscreen
    width: backend && backend.isDemoMode ? 1280 : Screen.width
    height: backend && backend.isDemoMode ? 800 : Screen.height
    visibility: backend && backend.isDemoMode ? Window.Windowed : Window.FullScreen
    flags: backend && backend.isDemoMode ? Qt.Window : (Qt.FramelessWindowHint | Qt.BypassWindowManagerHint)

    // Current Greeter State: "TIME" or "AUTH"
    property string uiState: "TIME"

    // Background Layer
    Item {
        id: backgroundLayer
        anchors.fill: parent

        Image {
            id: bgImage
            anchors.fill: parent
            source: backend ? backend.backgroundUrl : Qt.resolvedUrl("../assets/ghosted.jpeg")
            sourceSize.width: mainWindow.width > 0 ? mainWindow.width : Screen.width
            sourceSize.height: mainWindow.height > 0 ? mainWindow.height : Screen.height
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: false
            visible: bgBlur.opacity < 1.0

            onStatusChanged: {
                if (status === Image.Error && source !== Qt.resolvedUrl("../assets/ghosted.jpeg")) {
                    console.warn("[Greeter QML] Failed to load wallpaper: " + source + ", falling back to default");
                    source = Qt.resolvedUrl("../assets/ghosted.jpeg");
                }
            }
        }

        // Blur effect using Qt5Compat.GraphicalEffects with smooth opacity fade instead of dynamic kernel recalculation
        FastBlur {
            id: bgBlur
            anchors.fill: parent
            source: bgImage
            radius: backend ? backend.blurRadius : 32
            transparentBorder: false
            opacity: mainWindow.uiState === "AUTH" ? 1.0 : 0.0
            visible: opacity > 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: backend ? backend.transitionDuration : 450
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // Dark Overlay: gradually darkens when transitioning to AUTH
        Rectangle {
            id: darkOverlay
            anchors.fill: parent
            color: "#000000"
            opacity: mainWindow.uiState === "AUTH"
                     ? (backend ? backend.authPageDim : 0.85)
                     : (backend ? backend.timePageDim : 0.60)

            Behavior on opacity {
                NumberAnimation {
                    duration: backend ? backend.transitionDuration : 450
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // Page 1: TIME PAGE
    TimePage {
        id: timePage
        anchors.fill: parent
        visible: opacity > 0.0
        opacity: mainWindow.uiState === "TIME" ? 1.0 : 0.0
        scale: mainWindow.uiState === "TIME" ? 1.0 : 0.96

        Behavior on opacity {
            NumberAnimation {
                duration: backend ? backend.transitionDuration : 450
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: backend ? backend.transitionDuration : 450
                easing.type: Easing.OutQuad
            }
        }

        onRequestAuth: {
            mainWindow.uiState = "AUTH"
            authPage.focusInput()
        }
    }

    // Page 2: AUTHENTICATION PAGE
    AuthPage {
        id: authPage
        anchors.fill: parent
        visible: opacity > 0.0
        opacity: mainWindow.uiState === "AUTH" ? 1.0 : 0.0
        scale: mainWindow.uiState === "AUTH" ? 1.0 : 0.96

        Behavior on opacity {
            NumberAnimation {
                duration: backend ? backend.transitionDuration : 450
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: backend ? backend.transitionDuration : 450
                easing.type: Easing.OutQuad
            }
        }

        onRequestTime: {
            mainWindow.uiState = "TIME"
            timePage.forceActiveFocus()
        }

        onRequestReboot: {
            powerDialog.open("reboot")
        }

        onRequestShutdown: {
            powerDialog.open("shutdown")
        }
    }

    // Power Confirmation Dialog
    PowerDialog {
        id: powerDialog
    }

    // Black curtain overlay for seamless fade-to-black before desktop compositor launches
    Rectangle {
        id: blackCurtain
        anchors.fill: parent
        color: "#000000"
        opacity: 0.0
        z: 99999
        visible: opacity > 0.0

        Behavior on opacity {
            NumberAnimation {
                id: curtainAnim
                duration: 120
                easing.type: Easing.InOutQuad
            }
        }
    }

    SequentialAnimation {
        id: sessionLaunchTransition

        // 1. Fade entire window to deep solid black
        ScriptAction {
            script: {
                blackCurtain.visible = true
                blackCurtain.opacity = 1.0
            }
        }
        // Guarantee the 120ms fade-to-black animation finishes cleanly
        PauseAnimation { duration: 130 }


        // 2. Request greetd to start the user desktop session and quit greeter
        ScriptAction {
            script: {
                if (backend) {
                    backend.startDesktopSession()
                }
            }
        }
    }

    Connections {
        target: backend

        function onAuthSucceeded() {
            sessionLaunchTransition.start()
        }
    }

    // Window-level key handling (e.g. F11 to toggle fullscreen in demo mode)
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (backend && backend.isDemoMode && event.key === Qt.Key_F11) {
                if (mainWindow.visibility === Window.FullScreen) {
                    mainWindow.visibility = Window.Windowed
                } else {
                    mainWindow.visibility = Window.FullScreen
                }
                event.accepted = true
            }
        }
    }

    Component.onCompleted: {
        timePage.forceActiveFocus()
    }
}
