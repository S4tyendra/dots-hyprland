pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: false

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (!Persistent.isNewHyprlandInstance) {
                root.inhibit = Persistent.states.idle.inhibit;
            } else {
                Persistent.states.idle.inhibit = root.inhibit;
            }
        }
    }

    function toggleInhibit(active = null) {
        if (active !== null) {
            root.inhibit = active;
        } else {
            root.inhibit = !root.inhibit;
        }
        Persistent.states.idle.inhibit = root.inhibit;
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            // Needs a real Wayland surface for the inhibitor to register.
            // A 1x1 anchored transparent window with no interactive mask is enough.
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors {
                right: true
                bottom: true
            }
            // Not interactable
            mask: Region {
                item: null
            }
        }
    }
}
