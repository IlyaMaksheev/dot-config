pragma Singleton

import Quickshell

Singleton {
    property var currentMenu: null

    function open(menu) {
        if (currentMenu && currentMenu !== menu)
            currentMenu.closeMenu();

        currentMenu = menu;
        menu.openMenu();
    }

    function closed(menu) {
        if (currentMenu === menu)
            currentMenu = null;
    }
}
