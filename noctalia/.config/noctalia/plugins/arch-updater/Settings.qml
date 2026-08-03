import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    // General
    property string systemCmd: pluginApi.pluginSettings.systemCmd || pluginApi.manifest.metadata.defaultSettings.systemCmd
    property string aurCmd: pluginApi.pluginSettings.aurCmd || pluginApi.manifest.metadata.defaultSettings.aurCmd
    property string updateCmd: pluginApi.pluginSettings.updateCmd || pluginApi.manifest.metadata.defaultSettings.updateCmd
    property string aurHomepageCmd: pluginApi.pluginSettings.aurHomepageCmd || pluginApi.manifest.metadata.defaultSettings.aurHomepageCmd
    property bool flatpak: pluginApi.pluginSettings.flatpak ?? pluginApi.manifest.metadata.defaultSettings.flatpak
    property bool toast: pluginApi.pluginSettings.toast ?? pluginApi.manifest.metadata.defaultSettings.toast
    property bool refreshTimer: pluginApi.pluginSettings.refreshTimer ?? pluginApi.manifest.metadata.defaultSettings.refreshTimer
    property int refreshInterval: pluginApi.pluginSettings.refreshInterval || pluginApi.manifest.metadata.defaultSettings.refreshInterval

    // Bar
    property bool noctalia: pluginApi.pluginSettings.noctalia ?? pluginApi.manifest.metadata.defaultSettings.noctalia
    property bool tooltip: pluginApi.pluginSettings.tooltip ?? pluginApi.manifest.metadata.defaultSettings.tooltip
    property bool hideOnEmpty: pluginApi.pluginSettings.hideOnEmpty ?? pluginApi.manifest.metadata.defaultSettings.hideOnEmpty
    property bool boldText: pluginApi.pluginSettings.boldText ?? pluginApi.manifest.metadata.defaultSettings.boldText
    property bool useDistroLogo: pluginApi.pluginSettings.useDistroLogo ?? pluginApi.manifest.metadata.defaultSettings.useDistroLogo
    property bool enableColorization: pluginApi.pluginSettings.enableColorization ?? pluginApi.manifest.metadata.defaultSettings.enableColorization
    property string iconColor: pluginApi.pluginSettings.iconColor ?? pluginApi.manifest.metadata.defaultSettings.iconColor
    property string iconName: pluginApi.pluginSettings.iconName || pluginApi.manifest.metadata.defaultSettings.iconName
    property string customIconPath: pluginApi.pluginSettings.customIconPath ?? pluginApi.manifest.metadata.defaultSettings.customIconPath

    // Panel
    property bool boldVerPanel: pluginApi.pluginSettings.boldVerPanel ?? pluginApi.manifest.metadata.defaultSettings.boldVerPanel
    property bool panelTooltip: pluginApi.pluginSettings.panelTooltip ?? pluginApi.manifest.metadata.defaultSettings.panelTooltip
    property bool panelContext: pluginApi.pluginSettings.panelContext ?? pluginApi.manifest.metadata.defaultSettings.panelContext
    property bool closeButton: pluginApi.pluginSettings.closeButton ?? pluginApi.manifest.metadata.defaultSettings.closeButton
    property bool closeOnSettings: pluginApi.pluginSettings.closeOnSettings ?? pluginApi.manifest.metadata.defaultSettings.closeOnSettings

    // Desktop Widget
    property bool boldVerDesktop: pluginApi.pluginSettings.boldVerDesktop ?? pluginApi.manifest.metadata.defaultSettings.boldVerDesktop
    property bool hoverTip: pluginApi.pluginSettings.hoverTip ?? pluginApi.manifest.metadata.defaultSettings.hoverTip

    spacing: Style.marginM

    // Runs when the plugin settings are loaded
    Component.onCompleted: {
        Logger.i("Arch Updater", "Settings UI loaded")
    }

    // Tab Bar
    NTabBar {
        id: tabBar
        Layout.fillWidth: true
        Layout.bottomMargin: Style.marginM
        distributeEvenly: true
        currentIndex: tabView.currentIndex

        NTabButton {
            icon: "settings"
            text: pluginApi.tr("settings.tabs.general")
            pointSize: Style.fontSizeL
            tabIndex: 0
            checked: tabBar.currentIndex === 0
        }

        NTabButton {
            icon: "crop-16-9"
            text: pluginApi.tr("settings.tabs.bar")
            pointSize: Style.fontSizeL
            tabIndex: 1
            checked: tabBar.currentIndex === 1
        }

        NTabButton {
            icon: "table"
            text: pluginApi.tr("settings.tabs.panel")
            pointSize: Style.fontSizeL
            tabIndex: 2
            checked: tabBar.currentIndex === 2
        }

        NTabButton {
            icon: "clock"
            text: pluginApi.tr("settings.tabs.desktop")
            pointSize: Style.fontSizeL
            tabIndex: 3
            checked: tabBar.currentIndex === 3
        }
    }

    NTabView {
        id: tabView
        currentIndex: tabBar.currentIndex

        ColumnLayout { // General Tab
            spacing: Style.marginM

            NText { // General Title
                text: pluginApi.tr("settings.general.title")
                pointSize: Style.fontSizeXL
                font.weight: Font.Bold
                color: Color.mOnSurface
            }
            
            NLabel { // General Description
                description: pluginApi.tr("settings.general.desc")
            }

            NDivider {
                Layout.fillWidth: true
                Layout.topMargin: Style.marginS
                Layout.bottomMargin: Style.marginS
            }

            NTextInput { // System Command
                Layout.fillWidth: true
                label: pluginApi.tr("settings.general.systemCmd.text")
                description: pluginApi.tr("settings.general.systemCmd.desc")
                placeholderText: pluginApi.manifest.metadata.defaultSettings.systemCmd
                text: root.systemCmd
                onTextChanged: {
                    root.systemCmd = text
                    Logger.d("Arch Updater", "System command set to: " + root.systemCmd)
                }
            }

            NTextInput { // AUR Command
                Layout.fillWidth: true
                label: pluginApi.tr("settings.general.aurCmd.text")
                description: pluginApi.tr("settings.general.aurCmd.desc")
                placeholderText: pluginApi.manifest.metadata.defaultSettings.aurCmd
                text: root.aurCmd
                onTextChanged: {
                    root.aurCmd = text
                    Logger.d("Arch Updater", "AUR command set to: " + root.aurCmd)
                }
            }

            NTextInput { // Update Command
                Layout.fillWidth: true
                label: pluginApi.tr("settings.general.updateCmd.text")
                description: pluginApi.tr("settings.general.updateCmd.desc")
                placeholderText: pluginApi.manifest.metadata.defaultSettings.updateCmd
                text: root.updateCmd
                onTextChanged: {
                    root.updateCmd = text
                    Logger.d("Arch Updater", "Update command set to: " + root.updateCmd)
                }
            }

            NTextInput { // AUR Homepage Command
                Layout.fillWidth: true
                label: pluginApi.tr("settings.general.aurHomepageCmd.text")
                description: pluginApi.tr("settings.general.aurHomepageCmd.desc")
                placeholderText: pluginApi.manifest.metadata.defaultSettings.aurHomepageCmd
                text: root.aurHomepageCmd
                onTextChanged: {
                    root.aurHomepageCmd = text
                    Logger.d("Arch Updater", "Update command set to: " + root.aurHomepageCmd)
                }
            }

            NDivider {
                Layout.fillWidth: true
                Layout.topMargin: Style.marginS
                Layout.bottomMargin: Style.marginS
            }

            // Flatpak Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: flatpakToggle.implicitHeight
                NToggle {
                    id: flatpakToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.general.flatpak.text")
                    description: pluginApi.tr("settings.general.flatpak.desc")
                    checked: root.flatpak
                    onToggled: checked => root.flatpak = checked
                }
            }

            // Toast Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: toastToggle.implicitHeight
                NToggle {
                    id: toastToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.general.toast.text")
                    description: pluginApi.tr("settings.general.toast.desc")
                    checked: root.toast
                    onToggled: checked => root.toast = checked
                }
            }

            // Refresh Interval Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: refreshTimerToggle.implicitHeight
                NToggle {
                    id: refreshTimerToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.general.refresh.text")
                    description: pluginApi.tr("settings.general.refresh.desc")
                    checked: root.refreshTimer
                    onToggled: checked => root.refreshTimer = checked
                }
            }

            // Refresh Interval
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginS
                visible: root.refreshTimer
                NLabel {
                    description: pluginApi.tr("settings.general.interval.desc") + root.refreshInterval
                }
                NSlider {
                    Layout.fillWidth: true
                    from: 30
                    to: 720
                    stepSize: 10
                    value: root.refreshInterval
                    onValueChanged: {
                        root.refreshInterval = value
                        Logger.d("Arch Updater", "Refresh interval set to: " + root.refreshInterval)
                    }
                }
            }
            
        }

        ColumnLayout { // Bar Tab
            spacing: Style.marginM

            NText { // Bar Title
                text: pluginApi.tr("settings.bar.title")
                pointSize: Style.fontSizeXL
                font.weight: Font.Bold
                color: Color.mOnSurface
            }
            
            NLabel { // Bar Description
                description: pluginApi.tr("settings.bar.desc")
            }

            NDivider {
                Layout.fillWidth: true
                Layout.topMargin: Style.marginS
                Layout.bottomMargin: Style.marginS
            }

            // Noctalia Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: noctaliaToggle.implicitHeight
                NToggle {
                    id: noctaliaToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.bar.noctalia.text")
                    description: pluginApi.tr("settings.bar.noctalia.desc")
                    checked: root.noctalia
                    onToggled: checked => root.noctalia = checked
                }
            }

            // Tooltip Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: tooltipToggle.implicitHeight
                NToggle {
                    id: tooltipToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.bar.tooltip.text")
                    description: pluginApi.tr("settings.bar.tooltip.desc")
                    checked: root.tooltip
                    onToggled: checked => root.tooltip = checked
                }
            }
            
            // Hide On Empty Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: hideOnEmptyToggle.implicitHeight
                NToggle {
                    id: hideOnEmptyToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.bar.hideOnEmpty.text")
                    description: pluginApi.tr("settings.bar.hideOnEmpty.desc")
                    checked: root.hideOnEmpty
                    onToggled: checked => root.hideOnEmpty = checked
                }
            }

            // Bold Text Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: boldTextToggle.implicitHeight
                NToggle {
                    id: boldTextToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.bar.boldCount.text")
                    description: pluginApi.tr("settings.bar.boldCount.desc")
                    checked: root.boldText
                    onToggled: checked => root.boldText = checked
                }
            }

            // Use Distro Logo Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: distroLogoToggle.implicitHeight
                NToggle {
                    id: distroLogoToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.bar.useDistroLogo.text")
                    description: pluginApi.tr("settings.bar.useDistroLogo.desc")
                    checked: root.useDistroLogo
                    onToggled: checked => root.useDistroLogo = checked
                }
            }

            // Enable Colorization Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: colorizeToggle.implicitHeight
                NToggle {
                    id: colorizeToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.bar.enableColorization.text")
                    description: pluginApi.tr("settings.bar.enableColorization.desc")
                    checked: root.enableColorization
                    onToggled: checked => root.enableColorization = checked
                }
            }

            // Icon Color (only visible when colorization is enabled)
            NColorChoice {
                visible: root.enableColorization
                label: pluginApi.tr("settings.bar.iconColor.text")
                description: pluginApi.tr("settings.bar.iconColor.desc")
                currentKey: root.iconColor
                onSelected: key => root.iconColor = key
            }

            // Icon preview and selection
            RowLayout {
                spacing: Style.marginM

                NLabel {
                    label: pluginApi.tr("settings.bar.iconName.text")
                    description: pluginApi.tr("settings.bar.iconName.desc")
                }

                NImageRounded {
                    Layout.preferredWidth: Style.fontSizeXL * 2
                    Layout.preferredHeight: Style.fontSizeXL * 2
                    Layout.alignment: Qt.AlignVCenter
                    radius: Math.min(Style.radiusL, Layout.preferredWidth / 2)
                    imagePath: root.customIconPath
                    visible: root.customIconPath !== "" && !root.useDistroLogo
                }

                NIcon {
                    Layout.alignment: Qt.AlignVCenter
                    icon: root.iconName
                    pointSize: Style.fontSizeXXL * 1.5
                    visible: root.iconName !== "" && root.customIconPath === "" && !root.useDistroLogo
                }
            }

            RowLayout {
                spacing: Style.marginM
                NButton {
                    enabled: !root.useDistroLogo
                    text: pluginApi.tr("settings.bar.iconName.browseLibrary")
                    onClicked: iconPicker.open()
                }
                NButton {
                    enabled: !root.useDistroLogo
                    text: pluginApi.tr("settings.bar.iconName.browseFile")
                    onClicked: imagePicker.openFilePicker()
                }
            }

            NIconPicker {
                id: iconPicker
                initialIcon: root.iconName
                onIconSelected: iconName => {
                    root.iconName = iconName
                    root.customIconPath = ""
                }
            }

            NFilePicker {
                id: imagePicker
                title: pluginApi.tr("settings.bar.iconName.selectCustomIcon")
                selectionMode: "files"
                nameFilters: ImageCacheService.basicImageFilters.concat(["*.svg"])
                initialPath: Quickshell.env("HOME")
                onAccepted: paths => {
                    if (paths.length > 0) {
                        root.customIconPath = paths[0]
                    }
                }
            }
        }

        ColumnLayout { // Panel Tab
            spacing: Style.marginM

            NText { // Panel Title
                text: pluginApi.tr("settings.panel.title")
                pointSize: Style.fontSizeXL
                font.weight: Font.Bold
                color: Color.mOnSurface
            }
            
            NLabel { // Panel Description
                description: pluginApi.tr("settings.panel.desc")
            }

            NDivider {
                Layout.fillWidth: true
                Layout.topMargin: Style.marginS
                Layout.bottomMargin: Style.marginS
            }

            // Bold New Version Column Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: boldVerPanelToggle.implicitHeight
                NToggle {
                    id: boldVerPanelToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.panel.boldVer.text")
                    description: pluginApi.tr("settings.panel.boldVer.desc")
                    checked: root.boldVerPanel
                    onToggled: checked => root.boldVerPanel = checked
                }
            }

            // Tooltip Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: panelTooltipToggle.implicitHeight
                NToggle {
                    id: panelTooltipToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.panel.tooltip.text")
                    description: pluginApi.tr("settings.panel.tooltip.desc")
                    checked: root.panelTooltip
                    onToggled: checked => root.panelTooltip = checked
                }
            }

            // Context Menu Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: panelContextToggle.implicitHeight
                NToggle {
                    id: panelContextToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.panel.context.text")
                    description: pluginApi.tr("settings.panel.context.desc")
                    checked: root.panelContext
                    onToggled: checked => root.panelContext = checked
                }
            }

            // Close Button Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: closeButtonToggle.implicitHeight
                NToggle {
                    id: closeButtonToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.panel.closeButton.text")
                    description: pluginApi.tr("settings.panel.closeButton.desc")
                    checked: root.closeButton
                    onToggled: checked => root.closeButton = checked
                }
            }

            // Close On Settings Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: closeOnSettingsToggle.implicitHeight
                NToggle {
                    id: closeOnSettingsToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.panel.closeOnSettings.text")
                    description: pluginApi.tr("settings.panel.closeOnSettings.desc")
                    checked: root.closeOnSettings
                    onToggled: checked => root.closeOnSettings = checked
                }
            }
        }

        ColumnLayout { // Desktop Widget Tab
            spacing: Style.marginM

            NText { // Desktop Widget Title
                text: pluginApi.tr("settings.desktop.title")
                pointSize: Style.fontSizeXL
                font.weight: Font.Bold
                color: Color.mOnSurface
            }

            NLabel { // Desktop Widget Description
                description: pluginApi.tr("settings.desktop.desc")
            }

            NDivider {
                Layout.fillWidth: true
                Layout.topMargin: Style.marginS
                Layout.bottomMargin: Style.marginS
            }

            // Bold New Version Column Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: boldVerDesktopToggle.implicitHeight
                NToggle {
                    id: boldVerDesktopToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.desktop.boldVer.text")
                    description: pluginApi.tr("settings.desktop.boldVer.desc")
                    checked: root.boldVerDesktop
                    onToggled: checked => root.boldVerDesktop = checked
                }
            }

            // Desktop Hover Tip Toggle
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: hoverTipToggle.implicitHeight
                NToggle {
                    id: hoverTipToggle
                    anchors.fill: parent
                    label: pluginApi.tr("settings.desktop.hoverTip.text")
                    description: pluginApi.tr("settings.desktop.hoverTip.desc")
                    checked: root.hoverTip
                    onToggled: checked => root.hoverTip = checked
                }
            }
        }
    }

    // Save function - called by the dialog
    function saveSettings() {
        if (!pluginApi) {
            Logger.e("Arch Updater", "Cannot save: pluginApi is null")
            return
        }

        // General
        pluginApi.pluginSettings.systemCmd = root.systemCmd
        pluginApi.pluginSettings.aurCmd = root.aurCmd
        pluginApi.pluginSettings.updateCmd = root.updateCmd
        pluginApi.pluginSettings.aurHomepageCmd = root.aurHomepageCmd
        pluginApi.pluginSettings.flatpak = root.flatpak
        pluginApi.pluginSettings.toast = root.toast
        pluginApi.pluginSettings.refreshTimer = root.refreshTimer
        pluginApi.pluginSettings.refreshInterval = root.refreshInterval

        // Bar
        pluginApi.pluginSettings.noctalia = root.noctalia
        pluginApi.pluginSettings.tooltip = root.tooltip
        pluginApi.pluginSettings.hideOnEmpty = root.hideOnEmpty
        pluginApi.pluginSettings.boldText = root.boldText
        pluginApi.pluginSettings.useDistroLogo = root.useDistroLogo
        pluginApi.pluginSettings.enableColorization = root.enableColorization
        pluginApi.pluginSettings.iconColor = root.iconColor
        pluginApi.pluginSettings.iconName = root.iconName
        pluginApi.pluginSettings.customIconPath = root.customIconPath

        // Panel
        pluginApi.pluginSettings.boldVerPanel = root.boldVerPanel
        pluginApi.pluginSettings.panelTooltip = root.panelTooltip
        pluginApi.pluginSettings.panelContext = root.panelContext
        pluginApi.pluginSettings.closeButton = root.closeButton
        pluginApi.pluginSettings.closeOnSettings = root.closeOnSettings

        // Desktop Widget
        pluginApi.pluginSettings.boldVerDesktop = root.boldVerDesktop
        pluginApi.pluginSettings.hoverTip = root.hoverTip

        pluginApi.saveSettings()
        root.pluginApi.mainInstance.refresh()

        Logger.i("Arch Updater", "Settings saved successfully")
    }
}