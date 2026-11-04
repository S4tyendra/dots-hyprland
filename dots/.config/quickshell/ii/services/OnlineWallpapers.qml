pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root
    property var results: []
    property string error: ""
    property string query: ""
    property string sorting: "relevance"
    property string resolution: ""
    property string category: "111"
    property int page: 1
    property int lastPage: 1
    readonly property bool loading: searchProc.running
    readonly property bool downloading: downloadProc.running
    property string selectedId: ""

    function search(nextPage = 1) {
        if (loading || downloading) return;
        error = "";
        searchProc.command = ["python3", Quickshell.shellPath("scripts/wallpapers/online.py"), "search",
            query, String(nextPage), sorting, resolution, category];
        searchProc.running = true;
    }
    function apply(item, darkMode, monitor) {
        if (downloading || loading) return;
        error = "";
        selectedId = item.id;
        downloadProc.darkMode = darkMode;
        downloadProc.monitorName = monitor;
        downloadProc.command = ["python3", Quickshell.shellPath("scripts/wallpapers/online.py"), "download", item.url,
            FileUtils.trimFileProtocol(Directories.pictures) + "/Wallpapers/Online"];
        downloadProc.running = true;
    }
    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim()) return;
                try {
                    const response = JSON.parse(text);
                    root.results = response.results;
                    root.page = response.page;
                    root.lastPage = response.lastPage;
                } catch (e) { root.error = "Could not read wallpaper search results"; }
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim() }
    }
    Process {
        id: downloadProc
        property string monitorName: ""
        property bool darkMode: true
        property string downloadedPath: ""
        onStarted: downloadedPath = ""
        stdout: StdioCollector { onStreamFinished: downloadProc.downloadedPath = text.trim() }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim() }
        onExited: code => {
            if (code === 0 && downloadedPath) Wallpapers.apply(downloadedPath, darkMode, monitorName);
        }
    }
}
