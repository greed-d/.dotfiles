import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root

    // Plugin API (injected by PluginService)
    property var pluginApi: null

    // Strings
    property string systemStr: ""
    property string aurStr: ""
    property string flatpakStr: ""

    // Structured update data (used by Panel)
    property var updates: []

    // State
    property bool refreshing: false

    // Noctalia updates
    property var noctaliaNames: ["noctalia-qs", "noctalia-shell"]
    property bool noctaliaUpdate: false

    function checkNoctalia(string) {
        if (noctaliaNames.some(name => string.includes(name)) && (pluginApi.pluginSettings.noctalia ?? pluginApi.manifest.metadata.defaultSettings.noctalia ?? true)) {
            root.noctaliaUpdate = true
            Logger.d("Arch Updater", "Noctalia updates found")
        } else {
            Logger.d("Arch Updater", "No Noctalia updates found")
        }
    }

    Component.onCompleted: {
        refresh()
    }

    // Process to return the repo URL for a package
    Process {
        id: checkRepo
        
        property string _output: ""
        property var _callback: null

        stdout: SplitParser {
            onRead: data => checkRepo._output += data + "\n"
        }

        onExited: {
            if (_callback) _callback(_output)
            _output = ""
            _callback = null
        }

        function run(cmd, callback) {
            _output = ""
            _callback = callback
            command = cmd
            running = true
        }
    }

    // Process to return the Homepage for a package
    // Same as checkRepo but kept seperate incase one ends up needing to be different
    Process {
        id: getHomepage
        
        property string _output: ""
        property var _callback: null

        stdout: SplitParser {
            onRead: data => getHomepage._output += data + "\n"
        }

        onExited: {
            if (_callback) _callback(_output)
            _output = ""
            _callback = null
        }

        function run(cmd, callback) {
            _output = ""
            _callback = callback
            command = cmd
            running = true
        }
    }

    function openURL(source, id) {
        // Opens the page for the package
        // AUR and Flatpaks have the same URL for all packages but pacman can have multiple repos from which it sources
        // So it also checks the repo from which a package originates to open the correct URL
        var url = ""
        switch (source) {
            case "system":
                checkRepo.run(["sh", "-c", "LC_ALL=C pacman -Si " + id + " 2>/dev/null | awk '/^Repository/  {print $3; exit}'"], output => {
                    var repo = output.trim()
                    switch (repo) {
                        case "cachyos-znver4":
                            url = "https://packages.cachyos.org/package/cachyos-znver4/x86_64_v4/" + id
                            break
                        case "cachyos-extra-znver4":
                            url = "https://packages.cachyos.org/package/cachyos-extra-znver4/x86_64_v4/" + id
                            break
                        case "cachyos-core-znver4":
                            url = "https://packages.cachyos.org/package/cachyos-core-znver4/x86_64_v4/" + id
                            break
                        case "extra":
                            url = "https://archlinux.org/packages/extra/x86_64/" + id
                            break
                        case "multilib":
                            url = "https://archlinux.org/packages/multilib/x86_64/" + id
                            break
                        case "core":
                            url = "https://archlinux.org/packages/core/x86_64/" + id
                            break
                        default:
                            Logger.w("Arch Updater", "Failed to match repo: " + repo)
                            ToastService.showError("Failed to match repo: " + repo)
                            url = ""
                            break
                    }
                    Logger.i("Arch Updater", "Opening URL: " + url)
                    Qt.openUrlExternally(url)
                })
                break
            case "aur":
                url = "https://aur.archlinux.org/packages/" + id
                Logger.i("Arch Updater", "Opening URL: " + url)
                Qt.openUrlExternally(url)
                break
            case "flatpak":
                url = "https://flathub.org/en/apps/" + id
                Logger.i("Arch Updater", "Opening URL: " + url)
                Qt.openUrlExternally(url)
                break
            default:
                Logger.w("Arch Updater", "Unkown source: " + source)
                ToastService.showError("Unable to open URL\nUnkown source: " + source)
                break
        }
    }

    function openHomepage(source, id) {
        // Opens the homepage for the package
        var url = ""
        switch (source) {
            case "system":
                getHomepage.run(["sh", "-c", "LC_ALL=C pacman -Si " + id + " 2>/dev/null | awk '/^URL/ {print $3; exit}'"], output => {
                    url = output.trim()
                    Logger.i("Arch Updater", "Opening Homepage (System): " + url)
                    Qt.openUrlExternally(url)
                })
                break
            case "aur":
                getHomepage.run(["sh", "-c", (pluginApi.pluginSettings.aurHomepageCmd || pluginApi.manifest.metadata.defaultSettings.aurHomepageCmd).replace("{id}", id)], output => {
                    Logger.i("ASDASD", (pluginApi.pluginSettings.aurHomepageCmd || pluginApi.manifest.metadata.defaultSettings.aurHomepageCmd))
                    Logger.i("ASDASD", (pluginApi.pluginSettings.aurHomepageCmd || pluginApi.manifest.metadata.defaultSettings.aurHomepageCmd).replace("{id}", id))
                    url = output.trim()
                    Logger.i("Arch Updater", "Opening Homepage (AUR): " + url)
                    Qt.openUrlExternally(url)
                })
                break
            case "flatpak":
                getHomepage.run(["sh", "-c", "LC_ALL=C appstreamcli get " + id + " 2>/dev/null | awk '/^Homepage/ {print $2}'"], output => {
                    url = output.trim()
                    Logger.i("Arch Updater", "Opening Homepage (Flatpak): " + url)
                    Qt.openUrlExternally(url)
                })
                break
            default:
                Logger.w("Arch Updater", "Unkown source: " + source)
                ToastService.showError("Unable to open Homepage<br>Unkown source: " + source)
                break
        }
    }

    function copy(text) {
        // Copy the text and send a toast
        Quickshell.execDetached(["sh", "-c", "wl-copy '" + text + "'"])
        ToastService.showNotice('Copied "' + text + '"')
        Logger.d("Arch Updater", "Copied " + text)
    }

    function refresh() {
        Logger.i("Arch Updater", "Refreshing updates...")
        if (pluginApi.pluginSettings.toast ?? pluginApi.manifest.metadata.defaultSettings.toast ?? true) {
            ToastService.showNotice("Refreshing updates...")
        }
        root.systemStr = ""
        root.aurStr = ""
        root.flatpakStr = ""
        root.updates = []
        root.noctaliaUpdate = false
        root.refreshing = true

        // Use configurable check command (output format: "name oldver -> newver")
        getSystemUpdates.command = ["sh", "-c", pluginApi.pluginSettings.systemCmd || pluginApi.manifest.metadata.defaultSettings.systemCmd]
        getSystemUpdates.running = true
    }

    function update() {
        Logger.i("Arch Updater", "Updating...")
        runUpdate.command = ["sh", "-c", pluginApi.pluginSettings.updateCmd || pluginApi.manifest.metadata.defaultSettings.updateCmd]
        runUpdate.running = true
    }

    // Single process for all system update data
    // Expected output format: "name oldver -> newver" per line
    Process {
        id: getSystemUpdates
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Logger.w("Arch Updater", "Check command exited with code " + exitCode)
                root.refreshing = false
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text.slice(0, -1)
                if (!output) {
                    Logger.d("Arch Updater", "No system updates found")
                    getAURUpdates.command = ["sh", "-c", pluginApi.pluginSettings.aurCmd || pluginApi.manifest.metadata.defaultSettings.aurCmd]
                    getAURUpdates.running = true
                    return
                }

                var lines = output.split("\n")
                var names = []
                var rows = []

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(/\s+/)
                    // Expected format: name oldver -> newver
                    if (parts.length >= 4) {
                        names.push(parts[0])
                        rows.push({id: parts[0], name: parts[0], oldVer: parts[1], newVer: parts[3], source: "system" })
                    }
                }

                root.systemStr = names.join("\n")
                root.updates = rows

                Logger.d("Arch Updater", "System update count: " + names.length)
                Logger.d("Arch Updater", "System updates: " + names)

                // Chain: start AUR check after system updates are done
                getAURUpdates.command = ["sh", "-c", pluginApi.pluginSettings.aurCmd || pluginApi.manifest.metadata.defaultSettings.aurCmd]
                getAURUpdates.running = true
            }
        }
    }

    // Single process for all AUR update data
    // Expected output format: "name oldver -> newver" per line
    Process {
        id: getAURUpdates
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Logger.w("Arch Updater", "Check command exited with code " + exitCode)
                root.refreshing = false
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text.slice(0, -1)
                if (!output) {
                    Logger.d("Arch Updater", "No AUR updates found")
                    // Still start flatpak check if enabled
                    if (pluginApi.pluginSettings.flatpak ?? pluginApi.manifest.metadata.defaultSettings.flatpak) {
                        getFlatpakUpdates.running = true
                    } else {
                        root.refreshing = false
                    }
                    return
                }

                var lines = output.split("\n")
                var names = []
                var rows = [...root.updates]

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(/\s+/)
                    // Expected format: name oldver -> newver
                    if (parts.length >= 4) {
                        names.push(parts[0])
                        rows.push({id: parts[0], name: parts[0], oldVer: parts[1], newVer: parts[3], source: "aur" })
                    }
                }

                root.aurStr = names.join("\n")
                root.updates = rows

                Logger.d("Arch Updater", "AUR update count: " + names.length)
                Logger.d("Arch Updater", "AUR updates: " + names)

                checkNoctalia(systemStr + aurStr)

                // Chain: start flatpak check after system updates are done
                if (pluginApi.pluginSettings.flatpak ?? pluginApi.manifest.metadata.defaultSettings.flatpak) {
                    getFlatpakUpdates.running = true
                } else {
                    root.refreshing = false
                }
            }
        }
    }

    // Single process for all flatpak update data
    // Refreshes metadata using --no-deploy first so that the new version numbers get fetched
    // Joins remote (new) versions with installed (old) versions by application ID
    // Output format: application\tname\tnewver\toldver
    Process {
        id: getFlatpakUpdates
        command: ["sh", "-c", "flatpak update --no-deploy --noninteractive >/dev/null 2>&1; join -t'\t' -j1 <(flatpak remote-ls --updates --columns=application,name,version 2>/dev/null | sort -t'\t' -k1,1) <(flatpak list --columns=application,version 2>/dev/null | sort -t'\t' -k1,1)"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Logger.w("Arch Updater", "Flatpak check exited with code " + exitCode)
                root.refreshing = false
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text.slice(0, -1)
                if (!output) {
                    Logger.d("Arch Updater", "No flatpak updates found")
                    root.refreshing = false
                    return
                }

                var lines = output.split("\n")
                var names = []
                var rows = [...root.updates]

                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(/\t+/)
                    // Expected format: application\tname\tnewver\toldver
                    if (parts.length >= 4) {
                        names.push(parts[1])
                        rows.push({id: parts[0], name: parts[1], oldVer: parts[3], newVer: parts[2], source: "flatpak" })
                    }
                }

                root.flatpakStr = names.join("\n")
                root.updates = rows

                Logger.d("Arch Updater", "Flatpak update count: " + names.length)
                Logger.d("Arch Updater", "Flatpak updates: " + names)
                root.refreshing = false
            }
        }
    }

    Process {
        id: runUpdate
        stdout: StdioCollector {
            onStreamFinished: {
                refresh()
            }
        }
    }

    Timer {
        interval: (pluginApi.pluginSettings.refreshInterval || pluginApi.manifest.metadata.defaultSettings.refreshInterval) * 60000
        running: true
        repeat: true
        onTriggered: {
            Logger.d("Arch Updater", "Timer refresh...")
            refresh()
        }
    }

    IpcHandler {
        target: "plugin:arch-updater"

        function refresh() {
            Logger.d("Arch Updater", "Refreshing through IPC...")
            root.pluginApi.mainInstance.refresh()
        }

        function update() {
            Logger.d("Arch Updater", "Updating through IPC...")
            root.pluginApi.mainInstance.update()
        }
    }
}
