import QtQuick
import Quickshell

QtObject {
    enum IconType { Material, Text, System, None }
    enum FontType { Normal, Monospace }

    // General stuff
    property string type: ""
    property var fontType: LauncherSearchResult.FontType.Normal
    property string name: ""
    property string rawValue: ""
    property string iconName: ""
    property var iconType: LauncherSearchResult.IconType.None
    property string verb: ""
    property bool blurImage: false
    property var execute: () => {
        print("Not implemented");
    }
    property var actions: []
    property bool pinned: false
    property string pinnedImageFile: ""
    property int pinnedWidth: 0
    property int pinnedHeight: 0
    
    // Stuff needed for DesktopEntry 
    property string id: ""
    property bool shown: true
    property string comment: ""
    property bool runInTerminal: false
    property string genericName: ""
    property list<string> keywords: []

    // Extra stuff to allow for more flexibility
    property string category: type
}
