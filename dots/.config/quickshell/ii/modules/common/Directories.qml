pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common.functions
import QtCore
import QtQuick
import Quickshell

Singleton {
    // XDG Dirs, with "file://"
    readonly property string home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]
    readonly property string genericCache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    readonly property string documents: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
    readonly property string downloads: StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
    readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    readonly property string music: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
    readonly property string videos: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]

    // Other dirs used by the shell, without "file://"
    property string assetsPath: Quickshell.shellPath("assets")
    property string scriptPath: Quickshell.shellPath("scripts")
    property string favicons: FileUtils.trimFileProtocol(`${Directories.cache}/media/favicons`)
    property string coverArt: FileUtils.trimFileProtocol(`${Directories.cache}/media/coverart`)
    property string tempImages: "/tmp/quickshell/media/images"
    property string booruPreviews: FileUtils.trimFileProtocol(`${Directories.cache}/media/boorus`)
    property string booruDownloads: FileUtils.trimFileProtocol(Directories.pictures  + "/homework")
    property string booruDownloadsNsfw: FileUtils.trimFileProtocol(Directories.pictures + "/homework/🌶️")
    property string latexOutput: FileUtils.trimFileProtocol(`${Directories.cache}/media/latex`)
    property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse`)
    property string shellConfigName: "config.json"
    property string shellConfigPath: `${Directories.shellConfig}/${Directories.shellConfigName}`
	property string todoPath: FileUtils.trimFileProtocol(`${Directories.state}/user/todo.json`)
	property string notesPath: FileUtils.trimFileProtocol(`${Directories.state}/user/notes.txt`)
	property string conflictCachePath: FileUtils.trimFileProtocol(`${Directories.cache}/conflict-killer`)
    property string notificationsPath: FileUtils.trimFileProtocol(`${Directories.cache}/notifications/notifications.json`)
    property string generatedMaterialThemePath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/colors.json`)
    property string generatedWallpaperCategoryPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/wallpaper/category.txt`)
    property string generatedBlurredWallpaperPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/wallpaper/blurred.png`)
    property string cliphistDecode: FileUtils.trimFileProtocol(`/tmp/quickshell/media/cliphist`)
    property string cliphistPinsDir: FileUtils.trimFileProtocol(`${Directories.state}/user/cliphist-pins`)
    property string cliphistPinsIndex: FileUtils.trimFileProtocol(`${Directories.state}/user/cliphist-pins/index.json`)
    property string batteryHistoryPath: FileUtils.trimFileProtocol(`${Directories.state}/user/battery-history.json`)
    property string screenshotTemp: "/tmp/quickshell/media/screenshot"
    property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/switchwall.sh`)
    property string defaultAiPrompts: Quickshell.shellPath("defaults/ai/prompts")
    property string userAiPrompts: FileUtils.trimFileProtocol(`${Directories.shellConfig}/ai/prompts`)
    property string userActions: FileUtils.trimFileProtocol(`${Directories.shellConfig}/actions`)
    property string aiChats: FileUtils.trimFileProtocol(`${Directories.state}/user/ai/chats`)
    property string aiTranslationScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/gemini-translate.sh`)
    property string recordScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/videos/record.sh`)
    property string userAvatarPathAccountsService: FileUtils.trimFileProtocol(`/var/lib/AccountsService/icons/${SystemInfo.username}`)
    property string userAvatarPathRicersAndWeirdSystems: FileUtils.trimFileProtocol(`${Directories.home}.face`)
    property string userAvatarPathRicersAndWeirdSystems2: FileUtils.trimFileProtocol(`${Directories.home}.face.icon`)
    // Cleanup on init
    Component.onCompleted: {
        // One shell instead of a dozen process spawns at startup. Steps are
        // separated with `;`, not `&&`: one failing cleanup must not block
        // every other directory (and the pins index) from being created.
        // The state "user" dir is listed explicitly — battery history and
        // the cliphist pins both live under it and assume it exists.
        const keepDirs = [shellConfig, favicons, aiChats, userActions, cliphistPinsDir, FileUtils.trimFileProtocol(`${Directories.state}/user`)]
        const recreatedDirs = [coverArt, booruPreviews, latexOutput, cliphistDecode]
        const steps = []
        for (const path of keepDirs)
            steps.push(`mkdir -p '${path}'`)
        for (const path of recreatedDirs)
            steps.push(`rm -rf '${path}'; mkdir -p '${path}'`)
        steps.push(`rm -rf '${tempImages}'`)
        steps.push(`[ -f '${cliphistPinsIndex}' ] || printf '[]' > '${cliphistPinsIndex}'`)
        Quickshell.execDetached(["bash", "-c", steps.join("; ")])
    }
}
