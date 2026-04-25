import org.kde.breeze.components

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

SessionManagementScreen {
    id: root
    property Item mainPasswordBox: passwordBox

    property bool showUsernamePrompt: !showUserList

    property string lastUserName
    property bool loginScreenUiVisible: false

    //the y position that should be ensured visible when the on screen keyboard is visible
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + Kirigami.Units.smallSpacing

    property real fontSize: Kirigami.Theme.defaultFont.pointSize

    signal loginRequest(string username, string password)

    onShowUsernamePromptChanged: {
        if (!showUsernamePrompt) {
            lastUserName = ""
        }
    }

    onUserSelected: {
        // Don't startLogin() here, because the signal is connected to the
        // Escape key as well, for which it wouldn't make sense to trigger
        // login.
        passwordBox.clear()
        focusFirstVisibleFormControl();
    }

    QQC2.StackView.onActivating: {
        // Controls are not visible yet.
        Qt.callLater(focusFirstVisibleFormControl);
    }

    function focusFirstVisibleFormControl() {
        const nextControl = (userNameInput.visible
            ? userNameInput
            : (passwordBox.visible
                ? passwordBox
                : loginButton));
        // Using TabFocusReason, so that the loginButton gets the visual highlight.
        nextControl.forceActiveFocus(Qt.TabFocusReason);
    }

    /*
     * Login has been requested with the following username and password
     * If username field is visible, it will be taken from that, otherwise from the "name" property of the currentIndex
     */
    function startLogin() {
        const username = showUsernamePrompt ? userNameInput.text : userList.selectedUser
        const password = passwordBox.text

        footer.enabled = false
        mainStack.enabled = false
        userListComponent.userList.opacity = 0.75

        // This is partly because it looks nicer, but more importantly it
        // works round a Qt bug that can trigger if the app is closed with a
        // TextField focused.
        //
        // See https://bugreports.qt.io/browse/QTBUG-55460
        loginButton.forceActiveFocus();
        loginRequest(username, password);
    }

    PlasmaComponents3.TextField {
        id: userNameInput
        font.pointSize: fontSize + 1
        Layout.fillWidth: true

        Kirigami.Theme.backgroundColor: "#32302f"
        Kirigami.Theme.textColor: "#ebdbb2"
        Kirigami.Theme.highlightColor: "#b8bb26"
        Kirigami.Theme.highlightedTextColor: "#1d2021"
        Kirigami.Theme.negativeTextColor: "#fb4934"

        palette.base: "#32302f"
        palette.text: "#ebdbb2"
        palette.highlight: "#b8bb26"
        palette.highlightedText: "#1d2021"
        palette.placeholderText: "#a89984"
        color: "#ebdbb2"
        placeholderTextColor: "#a89984"
        selectionColor: "#b8bb26"
        selectedTextColor: "#1d2021"

        background: Rectangle {
            property var margins: ({ left: 6, top: 4, right: 6, bottom: 4 })
            implicitWidth: Kirigami.Units.gridUnit * 8 + margins.left + margins.right
            implicitHeight: Kirigami.Units.gridUnit + margins.top + margins.bottom
            color: "#32302f"
            border.color: userNameInput.activeFocus ? "#b8bb26" : "#504945"
            border.width: userNameInput.activeFocus ? 2 : 1
            radius: 3
        }

        text: lastUserName
        visible: showUsernamePrompt
        focus: showUsernamePrompt && !lastUserName //if there's a username prompt it gets focus first, otherwise password does
        placeholderText: i18ndc("plasma-desktop-sddm-theme", "@info:placeholder in textfield", "Username")

        onAccepted: {
            if (root.loginScreenUiVisible) {
                passwordBox.forceActiveFocus()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaExtras.PasswordField {
            id: passwordBox
            font.pointSize: fontSize + 1
            Layout.fillWidth: true

            Kirigami.Theme.backgroundColor: "#32302f"
            Kirigami.Theme.textColor: "#ebdbb2"
            Kirigami.Theme.highlightColor: "#b8bb26"
            Kirigami.Theme.highlightedTextColor: "#1d2021"
            Kirigami.Theme.negativeTextColor: "#fb4934"

            palette.base: "#32302f"
            palette.text: "#ebdbb2"
            palette.highlight: "#b8bb26"
            palette.highlightedText: "#1d2021"
            palette.placeholderText: "#a89984"
            color: "#ebdbb2"
            placeholderTextColor: "#a89984"
            selectionColor: "#b8bb26"
            selectedTextColor: "#1d2021"

            background: Rectangle {
                property var margins: ({ left: 6, top: 4, right: 6, bottom: 4 })
                implicitWidth: Kirigami.Units.gridUnit * 8 + margins.left + margins.right
                implicitHeight: Kirigami.Units.gridUnit + margins.top + margins.bottom
                color: "#32302f"
                border.color: passwordBox.activeFocus ? "#b8bb26" : "#504945"
                border.width: passwordBox.activeFocus ? 2 : 1
                radius: 3
            }

            placeholderText: i18ndc("plasma-desktop-sddm-theme",  "@info:placeholder in textfield", "Password")
            focus: !showUsernamePrompt || lastUserName

            // Disable reveal password action because SDDM does not have the breeze icon set loaded
            rightActions: []

            onAccepted: {
                if (root.loginScreenUiVisible) {
                    startLogin();
                }
            }

            visible: root.showUsernamePrompt || userList.currentItem.needsPassword

            Keys.onEscapePressed: {
                mainStack.currentItem.forceActiveFocus();
            }

            //if empty and left or right is pressed change selection in user switch
            //this cannot be in keys.onLeftPressed as then it doesn't reach the password box
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left && !text) {
                    userList.decrementCurrentIndex();
                    event.accepted = true
                }
                if (event.key === Qt.Key_Right && !text) {
                    userList.incrementCurrentIndex();
                    event.accepted = true
                }
            }

            Connections {
                target: sddm
                function onLoginFailed() {
                    passwordBox.selectAll()
                    passwordBox.forceActiveFocus()
                }
            }
        }

        QQC2.Button {
            id: loginButton
            Accessible.name: i18ndc("plasma-desktop-sddm-theme", "@action:button Accessible name", "Log in")
            Layout.preferredHeight: passwordBox.implicitHeight
            Layout.preferredWidth: text.length === 0 ? loginButton.Layout.preferredHeight : -1

            Kirigami.Theme.backgroundColor: "#32302f"
            Kirigami.Theme.textColor: "#ebdbb2"
            Kirigami.Theme.highlightColor: "#a89984"
            Kirigami.Theme.highlightedTextColor: "#1d2021"
            palette.button: "#32302f"
            palette.buttonText: "#ebdbb2"
            palette.highlight: "#a89984"
            palette.highlightedText: "#1d2021"

            icon.name: ""
            icon.color: "transparent"

            background: Rectangle {
                implicitWidth: passwordBox.implicitHeight
                implicitHeight: passwordBox.implicitHeight
                color: loginButton.down ? "#504945" : (loginButton.activeFocus || loginButton.hovered ? "#3c3836" : "#32302f")
                border.color: loginButton.activeFocus || loginButton.hovered ? "#a89984" : "#504945"
                border.width: 1
                radius: 3
            }

            contentItem: Text {
                text: loginButton.text.length > 0 ? loginButton.text : (root.LayoutMirroring.enabled ? "‹" : "›")
                color: loginButton.activeFocus || loginButton.hovered ? "#ebdbb2" : "#a89984"
                font: loginButton.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            text: root.showUsernamePrompt || userList.currentItem.needsPassword ? "" : i18nc("@action:button", "Log In")
            onClicked: startLogin()
            Keys.onEnterPressed: clicked()
            Keys.onReturnPressed: clicked()
        }
    }
}
