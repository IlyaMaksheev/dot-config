pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property int fontPixelSize: 17
    readonly property int barHeight: 40
    readonly property int accentHeight: 3
    readonly property int workspaceHorizontalPadding: 10
    readonly property int trayIconSize: 27
    readonly property int trayItemHorizontalPadding: 10
    readonly property int menuItemHeight: 32
    readonly property int menuHorizontalPadding: 10
    readonly property int menuMaxWidth: 420
    readonly property int controlCenterEdgeGap: 14
    readonly property int controlCenterPadding: 14
    readonly property int controlCenterMajorSpacing: 14
    readonly property int controlCenterGap: 8
    readonly property int controlCenterRowHeight: 40
    readonly property int controlCenterHeaderHeight: 40
    readonly property int controlCenterTileHeight: 72
    readonly property int controlCenterSliderHeight: 40
    readonly property int controlCenterMediaHeight: 112
    readonly property int controlCenterRadius: 2
    readonly property int controlCenterBorderWidth: 3
    readonly property int controlCenterFocusWidth: 2
    readonly property int controlCenterFocusClearance: 3
    readonly property int feedbackDuration: 120
    readonly property int structuralDuration: 150
    // Qt exposes no dependable cross-desktop preference here yet. Feature behavior is
    // nevertheless centralized so a runtime integration can replace this binding.
    readonly property bool reducedMotion: false
    readonly property int feedbackAnimationDuration: reducedMotion ? 0 : feedbackDuration
    readonly property int structuralAnimationDuration: reducedMotion ? 0 : structuralDuration

    readonly property color panelBackground: dark0_soft
    readonly property color panelBorder: dark_green_hard
    readonly property color surfaceBackground: dark1
    readonly property color surfaceHover: dark2
    readonly property color surfacePressed: dark0
    readonly property color surfaceSelected: dark2
    readonly property color surfaceFocused: dark2
    readonly property color surfaceSelectedFocused: dark3
    readonly property color surfaceRaised: dark2
    readonly property color surfaceRaisedHover: dark3
    readonly property color focusColor: bright_green
    readonly property color separatorColor: dark3
    readonly property color textPrimary: light1
    readonly property color textSecondary: light3
    readonly property color disabledColor: gray
    readonly property color destructiveColor: bright_red

    readonly property color dark0_hard: "#1d2021"
    readonly property color dark0: "#282828"
    readonly property color dark0_soft: "#32302f"
    readonly property color dark1: "#3c3836"
    readonly property color dark2: "#504945"
    readonly property color dark3: "#665c54"
    readonly property color dark4: "#7c6f64"
    readonly property color light0_hard: "#f9f5d7"
    readonly property color light0: "#fbf1c7"
    readonly property color light0_soft: "#f2e5bc"
    readonly property color light1: "#ebdbb2"
    readonly property color light2: "#d5c4a1"
    readonly property color light3: "#bdae93"
    readonly property color light4: "#a89984"
    readonly property color bright_red: "#fb4934"
    readonly property color bright_green: "#b8bb26"
    readonly property color bright_yellow: "#fabd2f"
    readonly property color bright_blue: "#83a598"
    readonly property color bright_purple: "#d3869b"
    readonly property color bright_aqua: "#8ec07c"
    readonly property color bright_orange: "#fe8019"
    readonly property color neutral_red: "#cc241d"
    readonly property color neutral_green: "#98971a"
    readonly property color neutral_yellow: "#d79921"
    readonly property color neutral_blue: "#458588"
    readonly property color neutral_purple: "#b16286"
    readonly property color neutral_aqua: "#689d6a"
    readonly property color neutral_orange: "#d65d0e"
    readonly property color faded_red: "#9d0006"
    readonly property color faded_green: "#79740e"
    readonly property color faded_yellow: "#b57614"
    readonly property color faded_blue: "#076678"
    readonly property color faded_purple: "#8f3f71"
    readonly property color faded_aqua: "#427b58"
    readonly property color faded_orange: "#af3a03"
    readonly property color dark_red_hard: "#792329"
    readonly property color dark_red: "#722529"
    readonly property color dark_red_soft: "#7b2c2f"
    readonly property color light_red_hard: "#fc9690"
    readonly property color light_red: "#fc9487"
    readonly property color light_red_soft: "#f78b7f"
    readonly property color dark_green_hard: "#5a633a"
    readonly property color dark_green: "#62693e"
    readonly property color dark_green_soft: "#686d43"
    readonly property color light_green_hard: "#d3d6a5"
    readonly property color light_green: "#d5d39b"
    readonly property color light_green_soft: "#cecb94"
    readonly property color dark_aqua_hard: "#3e4934"
    readonly property color dark_aqua: "#49503b"
    readonly property color dark_aqua_soft: "#525742"
    readonly property color light_aqua_hard: "#e6e9c1"
    readonly property color light_aqua: "#e8e5b5"
    readonly property color light_aqua_soft: "#e1dbac"
    readonly property color gray: "#928374"
}
