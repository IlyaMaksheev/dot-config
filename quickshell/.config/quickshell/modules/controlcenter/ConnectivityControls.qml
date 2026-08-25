import QtQuick
import Quickshell.Bluetooth
import "../../components"
import "../../services"
import "../../theme"

Grid {
    id: root
    property bool effectiveVisible: true
    property int preferredHeight: Appearance.controlCenterTileHeight * 2 + Appearance.controlCenterGap
    property var moduleControls: [network, bluetooth, nightLight]
    property var adoptPointer: function(control) {}
    property bool panelVisible: false

    onPanelVisibleChanged: {
        if (panelVisible)
            NightLight.refresh();
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.panelVisible
        onTriggered: NightLight.refresh()
    }

    columns: 2
    spacing: Appearance.controlCenterGap

    function networkSubtitle() {
        if (!Connectivity.networkManagerAvailable)
            return "NetworkManager unavailable";
        if (!Connectivity.wifiDevicePresent) {
            if (Connectivity.wiredConnected)
                return "Wired connected · Wi-Fi unavailable";
            if (Connectivity.wiredPresent)
                return "Wired disconnected · Wi-Fi unavailable";
            return "No network devices";
        }

        let wifi = !Connectivity.wifiHardwareAvailable ? "Wi-Fi hardware disabled"
            : !Connectivity.wifiEnabled ? "Wi-Fi off"
            : Connectivity.ssid ? Connectivity.ssid : "Wi-Fi disconnected";
        if (Connectivity.wiredPresent)
            wifi += Connectivity.wiredConnected ? " · Wired connected"
                : Connectivity.wiredLink ? " · Wired link" : " · Wired disconnected";
        return wifi;
    }

    function bluetoothSubtitle() {
        if (!Connectivity.bluetoothAvailable)
            return "No Bluetooth adapter";
        switch (Connectivity.bluetoothState) {
        case BluetoothAdapterState.Enabled: return "On";
        case BluetoothAdapterState.Disabled: return "Off";
        case BluetoothAdapterState.Enabling: return "Enabling…";
        case BluetoothAdapterState.Disabling: return "Disabling…";
        case BluetoothAdapterState.Blocked: return "Blocked by hardware or rfkill";
        default: return "State unavailable";
        }
    }

    QuickToggleTile {
        id: network
        width: (parent.width - parent.spacing) / 2
        title: "Network"
        subtitle: root.networkSubtitle()
        icon: Connectivity.wifiDevicePresent ? "󰤨" : "󰈀"
        enabled: Connectivity.wifiWritable && !Connectivity.wifiRequestPending
        selected: Connectivity.wifiEnabled && Connectivity.wifiHardwareAvailable
        navigable: true
        accessibleStatus: subtitle
        onActivated: Connectivity.requestWifiToggle()
        onHovered: root.adoptPointer(network)
    }

    QuickToggleTile {
        id: bluetooth
        width: (parent.width - parent.spacing) / 2
        title: "Bluetooth"
        subtitle: root.bluetoothSubtitle()
        icon: "󰂯"
        enabled: Connectivity.bluetoothWritable && !Connectivity.bluetoothRequestPending
        selected: Connectivity.bluetoothState === BluetoothAdapterState.Enabled
        navigable: true
        accessibleStatus: subtitle
        onActivated: Connectivity.requestBluetoothToggle()
        onHovered: root.adoptPointer(bluetooth)
    }

    QuickToggleTile {
        id: nightLight
        width: (parent.width - parent.spacing) / 2
        title: "Night Light"
        subtitle: !NightLight.available ? "wl-gammarelay unavailable"
            : NightLight.togglePending ? "Changing…"
            : NightLight.enabled ? "On · " + NightLight.temperature + " K"
            : "Off · " + NightLight.temperature + " K"
        icon: "󰖔"
        enabled: NightLight.available && !NightLight.togglePending
        selected: NightLight.available && NightLight.enabled
        navigable: true
        accessibleStatus: subtitle
        onActivated: NightLight.requestToggle()
        onHovered: root.adoptPointer(nightLight)
    }

    Item { width: (parent.width - parent.spacing) / 2; height: Appearance.controlCenterTileHeight }
}
