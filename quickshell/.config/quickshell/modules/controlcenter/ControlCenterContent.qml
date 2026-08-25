import QtQuick
import "../../components"
import "../../theme"

Item {
    id: root
    property var composition: ["header", "quickControls", "volume", "brightness", "media"]
    property int cursorIndex: -1
    property bool cursorVisible: false
    property var navigableControls: []
    property var ensureVisible: function(item) {}
    property bool panelVisible: false
    signal closeRequested()

    implicitHeight: content.height

    function rebuildNavigation() {
        const controls = [];
        for (let i = 0; i < content.children.length; ++i) {
            const module = content.children[i];
            if (!module.visible || !module.moduleControls)
                continue;
            for (const control of module.moduleControls) {
                if (control && control.visible && (control.navigable || control.accessibleStatus))
                    controls.push(control);
            }
        }
        navigableControls = controls;
        if (cursorIndex >= controls.length)
            cursorIndex = controls.length - 1;
    }

    function moveCursor(delta) {
        rebuildNavigation();
        if (!navigableControls.length)
            return;
        cursorVisible = true;
        cursorIndex = (cursorIndex + delta + navigableControls.length) % navigableControls.length;
        updateCursor();
    }

    function updateCursor() {
        for (let i = 0; i < navigableControls.length; ++i)
            navigableControls[i].cursorActive = cursorVisible && i === cursorIndex;
        if (cursorIndex >= 0)
            ensureVisible(navigableControls[cursorIndex]);
    }

    function adoptPointer(control) {
        rebuildNavigation();
        const index = navigableControls.indexOf(control);
        if (index >= 0) {
            cursorVisible = true;
            cursorIndex = index;
            updateCursor();
        }
    }

    function activateCurrent() {
        if (cursorVisible && cursorIndex >= 0 && navigableControls[cursorIndex].enabled)
            navigableControls[cursorIndex].activated();
    }

    function adjustCurrent(direction) {
        if (!cursorVisible || cursorIndex < 0)
            return;
        const control = navigableControls[cursorIndex];
        if (control.adjust)
            control.adjust(direction);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) closeRequested();
        else if (event.key === Qt.Key_Tab) moveCursor(event.modifiers & Qt.ShiftModifier ? -1 : 1);
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) moveCursor(1);
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) moveCursor(-1);
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) adjustCurrent(1);
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) adjustCurrent(-1);
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) activateCurrent();
        else return;
        event.accepted = true;
    }

    Column {
        id: content
        width: parent.width
        spacing: Appearance.controlCenterMajorSpacing

        Repeater {
            model: root.composition
            delegate: Loader {
                required property string modelData
                width: content.width
                active: ["header", "quickControls", "volume", "brightness", "media"].indexOf(modelData) >= 0
                sourceComponent: modelData === "header" ? headerComponent
                    : modelData === "quickControls" ? quickComponent
                    : modelData === "volume" ? volumeComponent
                    : modelData === "brightness" ? brightnessComponent
                    : mediaComponent
                visible: active && item && item.effectiveVisible
                height: visible ? item.preferredHeight : 0
                property var moduleControls: item ? item.moduleControls : []
                onLoaded: root.rebuildNavigation()
            }
        }
    }

    Component {
        id: headerComponent
        Item {
            property bool effectiveVisible: true
            property int preferredHeight: Appearance.controlCenterHeaderHeight
            property var moduleControls: [powerButton]
            IconButton { id: powerButton; anchors.right: parent.right; icon: "󰐥"; accessibleStatus: "Power actions"; onHovered: root.adoptPointer(powerButton) }
            SectionHeader { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Control Center" }
        }
    }

    Component {
        id: quickComponent
        ConnectivityControls {
            panelVisible: root.panelVisible
            adoptPointer: control => root.adoptPointer(control)
        }
    }

    Component {
        id: volumeComponent
        VolumeControl { adoptPointer: control => root.adoptPointer(control) }
    }
    Component {
        id: brightnessComponent
        BrightnessControl {
            panelVisible: root.panelVisible
            adoptPointer: control => root.adoptPointer(control)
        }
    }
    Component {
        id: mediaComponent
        Item { property bool effectiveVisible: false; property int preferredHeight: Appearance.controlCenterMediaHeight; property var moduleControls: [] }
    }
}
