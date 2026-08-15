pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var _workspaces: []
    readonly property var workspaces: _workspaces
    property string pendingAction: ""

    function handleEvent(line) {
        try {
            const event = JSON.parse(line);

            if (event.WorkspacesChanged)
                root._workspaces = event.WorkspacesChanged.workspaces;
            else if (event.WorkspaceActivated)
                root.activateWorkspace(event.WorkspaceActivated.id);
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
