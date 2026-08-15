pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var _workspaces: []
    readonly property var workspaces: _workspaces
    property var _windows: []
    readonly property var windows: _windows
    property string pendingAction: ""

    function handleEvent(line) {
        try {
            const event = JSON.parse(line);

            if (event.WorkspacesChanged)
                root._workspaces = event.WorkspacesChanged.workspaces;
            else if (event.WorkspaceActivated)
                root.activateWorkspace(event.WorkspaceActivated.id);
            else if (event.WorkspaceActiveWindowChanged)
                root.setWorkspaceActiveWindow(event.WorkspaceActiveWindowChanged.workspace_id, event.WorkspaceActiveWindowChanged.active_window_id);
            else if (event.WindowsChanged)
                root._windows = event.WindowsChanged.windows;
            else if (event.WindowOpenedOrChanged)
                root.updateWindow(event.WindowOpenedOrChanged.window);
            else if (event.WindowClosed)
                root._windows = root._windows.filter(window => window.id !== event.WindowClosed.id);
        } catch (error) {
            console.error("Failed to parse Niri event:", error, line);
        }
    }

    function activateWorkspace(id) {
        const activated = root._workspaces.find(workspace => workspace.id === id);

        if (!activated)
            return;

        root._workspaces = root._workspaces.map(workspace => {
            if (workspace.output !== activated.output)
                return workspace;

            return Object.assign({}, workspace, {
                is_active: workspace.id === id
            });
        });
    }

    function setWorkspaceActiveWindow(workspaceId, windowId) {
        root._workspaces = root._workspaces.map(workspace => {
            if (workspace.id !== workspaceId)
                return workspace;

            return Object.assign({}, workspace, {
                active_window_id: windowId
            });
        });
    }

    function updateWindow(updatedWindow) {
        const existingIndex = root._windows.findIndex(window => window.id === updatedWindow.id);

        if (existingIndex === -1) {
            root._windows = root._windows.concat([updatedWindow]);
            return;
        }

        root._windows = root._windows.map(window => window.id === updatedWindow.id ? updatedWindow : window);
    }

    function activeWindowForOutput(outputName) {
        const workspace = root._workspaces.find(workspace => workspace.output === outputName && workspace.is_active);

        if (!workspace || workspace.active_window_id === null)
            return null;

        return root._windows.find(window => window.id === workspace.active_window_id) ?? null;
    }

    function focusWorkspace(id) {
        if (actionSocket.connected)
            return;

        pendingAction = JSON.stringify({
            Action: {
                FocusWorkspace: {
                    reference: {
                        Id: id
                    }
                }
            }
        }) + "\n";
        actionSocket.connected = true;
    }

    Socket {
        id: eventSocket
        path: Quickshell.env("NIRI_SOCKET")
        connected: true

        onConnectionStateChanged: {
            if (connected) {
                write("\"EventStream\"\n");
                flush();
            }
        }

        parser: SplitParser {
            onRead: line => root.handleEvent(line)
        }
    }

    Socket {
        id: actionSocket
        path: Quickshell.env("NIRI_SOCKET")

        onConnectionStateChanged: {
            if (connected && root.pendingAction !== "") {
                write(root.pendingAction);
                flush();
                root.pendingAction = "";
            }
        }

        parser: SplitParser {
            onRead: line => {
                actionSocket.connected = false;
            }
        }
    }
}
