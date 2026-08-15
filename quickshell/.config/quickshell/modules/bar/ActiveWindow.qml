import QtQuick
import "../../components"
import "../../services"

StyledText {
    required property string outputName

    readonly property var activeWindow: Niri.activeWindowForOutput(outputName)

    text: activeWindow?.title ?? ""
    elide: Text.ElideRight
}
