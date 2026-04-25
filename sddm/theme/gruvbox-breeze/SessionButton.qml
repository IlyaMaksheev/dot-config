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

    property int currentIndex: -1

    text: i18ndc("plasma-desktop-sddm-theme", "@action:button opens sessions menu %1 is current", "Desktop Session: %1", instantiator.objectAt(currentIndex).text || "")
    visible: menu.count > 1

    Component.onCompleted: {
        currentIndex = sessionModel.lastIndex
    }
    checkable: true
    checked: menu.opened
    onToggled: {
        if (checked) {
            menu.popup(root, 0, 0)
        } else {
            menu.dismiss()
        }
    }

    signal sessionChanged()

    PlasmaComponents.Menu {
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

        id: menu
        Instantiator {
            id: instantiator
            model: sessionModel
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

                text: model.name
                onTriggered: {
                    root.currentIndex = model.index
                    sessionChanged()
                }
            }
        }
    }
}
