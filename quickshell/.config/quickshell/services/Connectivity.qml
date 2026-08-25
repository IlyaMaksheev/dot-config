pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Networking
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property bool networkManagerAvailable: Networking.backend === NetworkBackendType.NetworkManager
    readonly property bool wifiHardwareAvailable: networkManagerAvailable && Networking.wifiHardwareEnabled
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiWritable: networkManagerAvailable && wifiHardwareAvailable
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothAvailable: bluetoothAdapter !== null
    readonly property int bluetoothState: bluetoothAvailable ? bluetoothAdapter.state : -1
    readonly property bool bluetoothWritable: bluetoothAvailable
        && bluetoothState !== BluetoothAdapterState.Enabling
        && bluetoothState !== BluetoothAdapterState.Disabling
        && bluetoothState !== BluetoothAdapterState.Blocked

    property bool wifiRequestPending: false
    property bool requestedWifiState: false
    property bool bluetoothRequestPending: false
    property bool requestedBluetoothState: false

    function modelValues(model) {
        return model && model.values ? model.values : [];
    }

    function devicesOfType(type) {
        return modelValues(Networking.devices).filter(device => device.type === type);
    }

    function connectedWifiName() {
        for (const device of devicesOfType(DeviceType.Wifi)) {
            for (const network of modelValues(device.networks)) {
                if (network.connected)
                    return network.name;
            }
        }
        return "";
    }

    readonly property bool wifiDevicePresent: devicesOfType(DeviceType.Wifi).length > 0
    readonly property var wiredDevices: devicesOfType(DeviceType.Wired)
    readonly property bool wiredPresent: wiredDevices.length > 0
    readonly property bool wiredConnected: wiredDevices.some(device => device.connected)
    readonly property bool wiredLink: wiredDevices.some(device => device.state === ConnectionState.Connected
        || device.state === ConnectionState.Connecting)
    readonly property string ssid: connectedWifiName()

    function requestWifiToggle() {
        if (!wifiWritable || wifiRequestPending)
            return;
        requestedWifiState = !wifiEnabled;
        wifiRequestPending = true;
        Networking.wifiEnabled = requestedWifiState;
        wifiConfirmation.restart();
    }

    function requestBluetoothToggle() {
        if (!bluetoothWritable || bluetoothRequestPending)
            return;
        requestedBluetoothState = !bluetoothAdapter.enabled;
        bluetoothRequestPending = true;
        bluetoothAdapter.enabled = requestedBluetoothState;
        bluetoothConfirmation.restart();
    }

    Connections {
        target: Networking
        function onWifiEnabledChanged() {
            if (root.wifiRequestPending && root.wifiEnabled === root.requestedWifiState) {
                root.wifiRequestPending = false;
                wifiConfirmation.stop();
            }
        }
    }

    Connections {
        target: root.bluetoothAdapter
        ignoreUnknownSignals: true
        function onEnabledChanged() {
            if (root.bluetoothRequestPending && root.bluetoothAdapter.enabled === root.requestedBluetoothState) {
                root.bluetoothRequestPending = false;
                bluetoothConfirmation.stop();
            }
        }
    }

    Timer {
        id: wifiConfirmation
        interval: 1800
        onTriggered: {
            if (root.wifiRequestPending && root.wifiEnabled !== root.requestedWifiState)
                OperationFailures.report("wifi-toggle", "Wi-Fi change failed", "The network backend did not confirm the requested Wi-Fi state.");
            root.wifiRequestPending = false;
        }
    }

    Timer {
        id: bluetoothConfirmation
        interval: 2500
        onTriggered: {
            if (root.bluetoothRequestPending && (!root.bluetoothAdapter || root.bluetoothAdapter.enabled !== root.requestedBluetoothState))
                OperationFailures.report("bluetooth-toggle", "Bluetooth change failed", "The Bluetooth adapter did not confirm the requested state.");
            root.bluetoothRequestPending = false;
        }
    }
}
