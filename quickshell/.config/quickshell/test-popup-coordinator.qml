// Run: timeout 4s quickshell --path test-popup-coordinator.qml --no-color
import Quickshell
import QtQuick
import "services"

ShellRoot {
    function check(condition, message) {
        if (!condition)
            throw new Error(message);
    }

    Component.onCompleted: {
        let closes = 0;
        const first = {
            close: function() {
                check(PopupCoordinator.currentOwner === first, "close precedes replacement");
                closes++;
                PopupCoordinator.release(first);
            }
        };
        const second = {
            close: function() { PopupCoordinator.release(second); }
        };

        PopupCoordinator.activate(first);
        check(PopupCoordinator.currentOwner === first, "initial activation");
        PopupCoordinator.activate(first);
        check(closes === 0, "same owner must not toggle or close");
        PopupCoordinator.activate(second);
        check(closes === 1, "replacement synchronously closes prior owner once");
        check(PopupCoordinator.currentOwner === second, "new owner installed after close");
        PopupCoordinator.release(first);
        PopupCoordinator.release(first);
        check(PopupCoordinator.currentOwner === second, "stale release cannot clear new owner");
        second.close();
        second.close();
        PopupCoordinator.release(second);
        check(PopupCoordinator.currentOwner === null, "repeated close/release is safe");
        PopupCoordinator.activate(second);
        check(PopupCoordinator.currentOwner === second, "reactivation after release");
        second.close();
        console.log("PASS: popup coordinator behavioral checks");
    }
}
