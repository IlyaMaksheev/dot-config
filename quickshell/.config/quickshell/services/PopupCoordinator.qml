pragma Singleton

import Quickshell

// Participating roots provide close(); presentation and toggling belong to owners.
Singleton {
    property var currentOwner: null

    function activate(owner) {
        if (currentOwner === owner)
            return;

        if (currentOwner)
            currentOwner.close();

        currentOwner = owner;
    }

    function release(owner) {
        if (currentOwner === owner)
            currentOwner = null;
    }
}
