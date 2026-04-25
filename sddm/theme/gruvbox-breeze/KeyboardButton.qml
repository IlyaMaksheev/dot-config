/*
    SPDX-FileCopyrightText: 2016 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2022 Aleix Pol Gonzalez <aleixpol@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmaComponents.ToolButton {
    id: root

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false
    Kirigami.Theme.backgroundColor: "#32302f"
    Kirigami.Theme.textColor: "#ebdbb2"
    Kirigami.Theme.highlightColor: "#a89984"
    Kirigami.Theme.highlightedTextColor: "#1d2021"
    palette.window: "#32302f"
    palette.base: "#32302f"
    palette.button: "#32302f"
    palette.text: "#ebdbb2"
    palette.buttonText: "#ebdbb2"
    palette.highlight: "#a89984"
    palette.highlightedText: "#1d2021"

    property int currentIndex: keyboard.currentLayout
    onCurrentIndexChanged: keyboard.currentLayout = currentIndex

    text: i18ndc("plasma-desktop-sddm-theme", "@action:button opens layout chooser %1 is current", "Keyboard Layout: %1", keyboard.layouts[currentIndex]?.longName ?? "")
    visible: keyboard.layouts.length > 1

    checkable: true
    checked: menu.opened
    onToggled: {
        if (checked) {
            menu.popup(root, 0, 0)
        } else {
            menu.dismiss()
        }
    }

    signal keyboardLayoutChanged()

    PlasmaComponents.Menu {
        id: menu
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.inherit: false
        Kirigami.Theme.backgroundColor: "#32302f"
        Kirigami.Theme.textColor: "#ebdbb2"
        Kirigami.Theme.highlightColor: "#a89984"
        Kirigami.Theme.highlightedTextColor: "#1d2021"
        palette.window: "#32302f"
        palette.base: "#32302f"
        palette.button: "#32302f"
        palette.text: "#ebdbb2"
        palette.buttonText: "#ebdbb2"
        palette.highlight: "#a89984"
        palette.highlightedText: "#1d2021"

        onAboutToShow: {
            if (instantiator.model === null) {
                let layouts = keyboard.layouts;
                layouts.sort((a, b) => a.longName.localeCompare(b.longName));
                instantiator.model = layouts;
            }
        }

        Instantiator {
            id: instantiator
            model: null
            onObjectAdded: (index, object) => menu.insertItem(index, object)
            onObjectRemoved: (index, object) => menu.removeItem(object)
            delegate: PlasmaComponents.MenuItem {
                Kirigami.Theme.colorSet: Kirigami.Theme.Window
                Kirigami.Theme.inherit: false
                Kirigami.Theme.backgroundColor: "#32302f"
                Kirigami.Theme.textColor: "#ebdbb2"
                Kirigami.Theme.highlightColor: "#a89984"
                Kirigami.Theme.highlightedTextColor: "#1d2021"
                palette.window: "#32302f"
                palette.base: "#32302f"
                palette.button: "#32302f"
                palette.text: "#ebdbb2"
                palette.buttonText: "#ebdbb2"
                palette.highlight: "#a89984"
                palette.highlightedText: "#1d2021"

                text: modelData.longName
                onTriggered: {
                    keyboard.currentLayout = keyboard.layouts.indexOf(modelData)
                    root.keyboardLayoutChanged()
                }
            }
        }
    }
}
