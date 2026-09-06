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
    property var powerControl: null
    signal closeRequested()

    implicitHeight: content.implicitHeight

    onPanelVisibleChanged: if (!panelVisible) clearCursor()

    function clearCursor() {
        cursorVisible = false;
        for (const control of navigableControls) {
            if (!control)
                continue;
            control.cursorActive = false;
            control.pointerEngaged = false;
            if (control.adjustmentMode)
                control.adjustmentMode = false;
        }
    }

    function rebuildNavigation(preferredControl) {
        const previousControls = navigableControls;
        const previousControl = preferredControl || (cursorVisible && cursorIndex >= 0
            && cursorIndex < previousControls.length ? previousControls[cursorIndex] : null);
        const controls = [];
        let quickModule = null;
        let volumeModule = null;
        let brightnessModule = null;
        let mediaModule = null;
        for (let i = 0; i < content.children.length; ++i) {
            const module = content.children[i];
            if (!module.visible || !module.moduleControls)
                continue;
            if (module.modelData === "quickControls")
                quickModule = module.item;
            else if (module.modelData === "volume")
                volumeModule = module.item;
            else if (module.modelData === "brightness")
                brightnessModule = module.item;
            else if (module.modelData === "media")
                mediaModule = module.item;
            for (const control of module.moduleControls) {
                if (control && !control.controlCenterActivationRegistered) {
                    control.controlCenterActivationRegistered = true;
                    control.activated.connect(function() {
                        if (root.powerControl && !root.powerControl.isActionControl(control))
                            root.powerControl.collapse();
                    });
                }
                if (control && control.visible && (control.navigable || control.accessibleStatus))
                    controls.push(control);
            }
        }
        if (powerControl && powerControl.primaryControl && quickModule && quickModule.primaryControl) {
            powerControl.primaryControl.navigationDown = quickModule.primaryControl;
            for (const topControl of quickModule.topControls) {
                if (topControl)
                    topControl.navigationUp = powerControl.primaryControl;
            }
        }
        if (quickModule && quickModule.primaryControl && volumeModule && volumeModule.primaryControl) {
            if (quickModule.exitControl)
                quickModule.exitControl.navigationDown = volumeModule.primaryControl;
            volumeModule.primaryControl.navigationUp = quickModule.primaryControl;
        }
        if (volumeModule && volumeModule.primaryControl) {
            const nextEntry = brightnessModule && brightnessModule.entryControl
                ? brightnessModule.entryControl
                : mediaModule && mediaModule.entryControl ? mediaModule.entryControl : null;
            volumeModule.primaryControl.navigationDown = nextEntry;
            if (nextEntry)
                nextEntry.navigationUp = volumeModule.primaryControl;
        }
        if (brightnessModule && brightnessModule.entryControl && mediaModule && mediaModule.entryControl) {
            brightnessModule.entryControl.navigationDown = mediaModule.entryControl;
            mediaModule.entryControl.navigationUp = brightnessModule.entryControl;
        }
        if (mediaModule && mediaModule.transportControls) {
            const mediaUp = mediaModule.entryControl ? mediaModule.entryControl.navigationUp : null;
            for (const transport of mediaModule.transportControls) {
                if (!transport)
                    continue;
                transport.navigationUp = mediaUp;
                transport.navigationDown = mediaModule.progressControl && mediaModule.progressControl.visible
                    && mediaModule.progressControl.navigable ? mediaModule.progressControl
                    : powerControl && powerControl.primaryControl ? powerControl.primaryControl : null;
            }
            if (powerControl && powerControl.primaryControl && mediaModule.progressControl)
                mediaModule.progressControl.navigationDown = powerControl.primaryControl;
        }
        if (powerControl && powerControl.primaryControl) {
            powerControl.primaryControl.navigationUp = mediaModule && mediaModule.entryControl
                ? mediaModule.entryControl
                : brightnessModule && brightnessModule.entryControl ? brightnessModule.entryControl
                : volumeModule && volumeModule.primaryControl ? volumeModule.primaryControl
                : quickModule && quickModule.primaryControl ? quickModule.primaryControl : null;
        }
        for (const oldControl of previousControls)
            if (oldControl)
                oldControl.cursorActive = false;
        navigableControls = controls;
        const identityControl = previousControl && mediaModule && mediaModule.transportControls
                && mediaModule.transportControls.indexOf(previousControl) >= 0
                && controls.indexOf(previousControl) < 0
            ? mediaModule.entryControl : previousControl;
        const preservedIndex = identityControl ? controls.indexOf(identityControl) : -1;
        if (preservedIndex >= 0)
            cursorIndex = preservedIndex;
        else if (cursorIndex >= controls.length)
            cursorIndex = controls.length - 1;
        updateCursor();
    }

    function leaveAdjustmentMode() {
        if (!cursorVisible || cursorIndex < 0)
            return false;
        const control = navigableControls[cursorIndex];
        if (control.adjustmentMode) {
            control.adjustmentMode = false;
            return true;
        }
        return false;
    }

    function moveCursor(delta) {
        leaveAdjustmentMode();
        if (powerControl && powerControl.selectedAction !== "" && powerControl.cancelPending())
            rebuildNavigation();
        rebuildNavigation();
        if (!navigableControls.length)
            return;
        cursorVisible = true;
        cursorIndex = (cursorIndex + delta + navigableControls.length) % navigableControls.length;
        updateCursor();
    }

    function moveDirectional(direction) {
        rebuildNavigation();
        if (!navigableControls.length)
            return;
        if (!cursorVisible || cursorIndex < 0) {
            moveCursor(1);
            return;
        }
        const beforeCollapse = navigableControls[cursorIndex];
        if ((direction === "up" || direction === "down") && powerControl
                && powerControl.isExpandedActionControl(beforeCollapse)) {
            powerControl.collapse();
            rebuildNavigation(powerControl.primaryControl);
            cursorVisible = true;
            cursorIndex = navigableControls.indexOf(powerControl.primaryControl);
            updateCursor();
            return;
        }
        const current = navigableControls[cursorIndex];
        const target = direction === "left" ? current.navigationLeft
            : direction === "right" ? current.navigationRight
            : direction === "up" ? current.navigationUp : current.navigationDown;
        if (target && target.visible && navigableControls.indexOf(target) >= 0) {
            leaveAdjustmentMode();
            cursorIndex = navigableControls.indexOf(target);
            cursorVisible = true;
            updateCursor();
            return;
        }
        if (direction === "up" || direction === "down") {
            if (current.strictVerticalNavigation)
                return;
            moveCursor(direction === "down" ? 1 : -1);
        }
    }

    function updateCursor() {
        for (let i = 0; i < navigableControls.length; ++i)
            navigableControls[i].cursorActive = cursorVisible && i === cursorIndex;
        if (cursorIndex >= 0)
            ensureVisible(navigableControls[cursorIndex]);
    }

    function adoptPointer(control) {
        if (powerControl && powerControl.selectedAction !== "" && !powerControl.isSelectedControl(control))
            powerControl.cancelPending();
        const previous = cursorVisible && cursorIndex >= 0 && cursorIndex < navigableControls.length
            ? navigableControls[cursorIndex] : null;
        if (previous && previous !== control && previous.adjustmentMode)
            previous.adjustmentMode = false;
        rebuildNavigation();
        for (const candidate of navigableControls) {
            if (candidate && candidate !== control)
                candidate.pointerEngaged = false;
        }
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
        if (event.key === Qt.Key_Escape) {
            if (!leaveAdjustmentMode() && (!powerControl || !powerControl.escapePowerState()))
                closeRequested();
        }
        else if (event.key === Qt.Key_Tab) moveCursor(event.modifiers & Qt.ShiftModifier ? -1 : 1);
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) moveDirectional("down");
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) moveDirectional("up");
        else if (event.key === Qt.Key_L) {
            const control = cursorVisible && cursorIndex >= 0 ? navigableControls[cursorIndex] : null;
            if (control && control.adjustmentMode) adjustCurrent(1); else moveDirectional("right");
        }
        else if (event.key === Qt.Key_H) {
            const control = cursorVisible && cursorIndex >= 0 ? navigableControls[cursorIndex] : null;
            if (control && control.adjustmentMode) adjustCurrent(-1); else moveDirectional("left");
        }
        else if (event.key === Qt.Key_Right) adjustCurrent(1);
        else if (event.key === Qt.Key_Left) adjustCurrent(-1);
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
                onLoaded: {
                    if (modelData === "header")
                        root.powerControl = item;
                    root.rebuildNavigation();
                }
            }
        }
    }

    Component {
        id: headerComponent
        PowerControl {
            panelVisible: root.panelVisible
            adoptPointer: control => root.adoptPointer(control)
            onNavigationChanged: root.rebuildNavigation()
            onCloseRequested: root.closeRequested()
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
        MediaControl { adoptPointer: control => root.adoptPointer(control) }
    }
}
