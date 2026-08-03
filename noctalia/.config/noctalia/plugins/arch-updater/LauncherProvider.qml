import QtQuick
import qs.Commons

Item {
    id: root

    // Required properties
    property var pluginApi: null
    property var launcher: null
    property string name: "Arch Updater"

    function handleCommand(searchText) {
        return searchText.startsWith(">au-search")
    }

    // Return available commands when user types ">"
    function commands() {
        return [
            {
                "name": ">au-refresh",
                "description": pluginApi.tr("launcher.refresh"),
                "icon": "refresh",
                "isTablerIcon": true,
                "onActivate": function() {
                    root.pluginApi.mainInstance.refresh()
                }
            },
            {
                "name": ">au-update",
                "description": pluginApi.tr("launcher.update"),
                "icon": "arrow-big-down-lines",
                "isTablerIcon": true,
                "onActivate": function() {
                    root.pluginApi.mainInstance.update()
                }
            },
            {
                "name": ">au-search",
                "description": pluginApi.tr("launcher.search"),
                "icon": "search",
                "isTablerIcon": true,
                "onActivate": function() {
                    launcher.setSearchText(">au-search ")
                }
            }
        ]
    }

    // Get search results
    function getResults(searchText) {
        if (!searchText.startsWith(">au-search")) {
            return []
        }

        var query = searchText.slice(11).trim() // Remove ">au-search"
        var updates = root.pluginApi?.mainInstance?.updates
        var formatted = []

        for (const i in updates) {
            // Sets the icon for each entry
            switch(updates[i].source) {
                case "system":
                    var icon = pluginApi.pluginDir + "/icons/arch.svg"
                    var isTabler = false
                    break
                case "aur":
                    var icon = pluginApi.pluginDir + "/icons/aur.svg"
                    var isTabler = false
                    break
                case "flatpak":
                    var icon = pluginApi.pluginDir + "/icons/flatpak.svg"
                    var isTabler = false
                    break
                default:
                    var icon = "package"
                    var isTabler = true
            }

            // Formats the entry
            formatted.push({
                "name": updates[i].name,
                "description": updates[i].oldVer + " -> " + updates[i].newVer,
                "icon": icon,
                "isTablerIcon": isTabler,
                "onActivate": function() {
                    // Open url to the package
                    root.pluginApi.mainInstance.openURL(updates[i].source, updates[i].id)
                }
            })
        }

        // Return formatted results
        return formatted
    }
}