import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets
import qs.Services.UI

DraggableDesktopWidget {
    id: root

    property var pluginApi: null

    // Scale dimensions by widgetScale
    implicitWidth: Math.round(320 * widgetScale)
    implicitHeight: Math.round(180 * widgetScale)
    width: implicitWidth
    height: implicitHeight

    // Shared column width reference
    readonly property real tableContentWidth: root.implicitWidth - 2 * Style.marginXL

    Column {
        spacing: Style.marginL
        padding: Style.marginXL

        Rectangle { // Heading
            width: root.tableContentWidth
            height: Style.fontSizeXL
            color: "transparent"

            NText {
                text: (root.pluginApi.mainInstance.updates.length).toString() + " " + pluginApi.trp("desktop.header", root.pluginApi.mainInstance.updates.length)
                pointSize: Style.fontSizeXL
                font.weight: Font.Bold
                color: Color.mOnSurface
                anchors.centerIn: parent
            }
        }

        NDivider {
            color: Color.mOnSurface
            width: root.tableContentWidth
            height: 1
            Layout.topMargin: Style.marginL
            Layout.bottomMargin: Style.marginL
        }

        // Headers
        RowLayout {
            width: root.tableContentWidth
            spacing: Style.marginS

            NText {
                Layout.preferredWidth: 0.4 * root.tableContentWidth
                text: pluginApi.tr("desktop.name")
                pointSize: Style.fontSizeM
                font.weight: Font.Bold
                color: Color.mOnSurface
                horizontalAlignment: Text.AlignLeft
            }
            NText {
                Layout.preferredWidth: 0.3 * root.tableContentWidth
                text: pluginApi.tr("desktop.oldVer")
                pointSize: Style.fontSizeM
                font.weight: Font.Bold
                color: Color.mOnSurface
                horizontalAlignment: Text.AlignHCenter
            }
            NText {
                Layout.preferredWidth: 0.3 * root.tableContentWidth
                text: pluginApi.tr("desktop.newVer")
                pointSize: Style.fontSizeM
                font.weight: Font.Bold
                color: Color.mOnSurface
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Table
        NListView {
            id: tableView
            width: root.tableContentWidth
            height: root.implicitHeight - Style.fontSizeXL - Style.fontSizeM - 4 * Style.marginL - 2 * Style.marginXL - 1
            model: root.pluginApi?.mainInstance?.updates
            clip: true
            spacing: Style.marginXS
            onContentYChanged: hoverTip.visible = false

            delegate: RowLayout {
                required property var modelData
                width: tableView.width
                spacing: Style.marginS

                NText { // Name
                    Layout.preferredWidth: 0.4 * root.tableContentWidth
                    text: modelData.name
                    pointSize: Style.fontSizeM
                    color: (modelData.source == "flatpak") ? Color.mTertiary : (modelData.source == "system") ? Color.mSecondary : Color.mPrimary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                NText { // Old Version
                    Layout.preferredWidth: 0.3 * root.tableContentWidth
                    text: modelData.oldVer
                    pointSize: Style.fontSizeM
                    color: (modelData.source == "flatpak") ? Color.mTertiary : (modelData.source == "system") ? Color.mSecondary : Color.mPrimary
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                NText { // New Version
                    Layout.preferredWidth: 0.3 * root.tableContentWidth
                    text: modelData.newVer
                    pointSize: Style.fontSizeM
                    font.weight: (pluginApi.pluginSettings.boldVerDesktop ?? pluginApi.manifest.metadata.defaultSettings.boldVerDesktop) ? Font.Bold : Font.Normal
                    color: (modelData.source == "flatpak") ? Color.mTertiary : (modelData.source == "system") ? Color.mSecondary : Color.mPrimary
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }

    Rectangle { // Hover Tip
        id: hoverTip

        width: root.width - (Style.marginL * widgetScale)
        height: root.height - (Style.marginL * widgetScale)
        anchors.centerIn: parent
        radius: Style.marginL

        color: Color.mShadow
        opacity: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        NText {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter

            pointSize: Style.fontSizeXL
            font.weight: Font.Bold
            color: Color.mOnSurface

            text: pluginApi.tr("desktop.tipLeft") + "\n---------------\n" + pluginApi.tr("desktop.tipMiddle") + "\n---------------\n" + pluginApi.tr("desktop.tipRight")
        }
    }

    MouseArea { // Clicks
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Logger.d("Arch Updater", "Refreshing from desktop widget...")
                hoverTip.visible = false
                root.pluginApi.mainInstance.refresh()
            }
            else if (mouse.button === Qt.MiddleButton) {
                Logger.d("Arch Updater", "Updating from desktop widget...")
                root.pluginApi.mainInstance.update()
            }
            else if (mouse.button === Qt.RightButton) {
                Logger.d("Arch Updater", "Opening settings from desktop widget...")
                BarService.openPluginSettings(screen, pluginApi.manifest)
            }
        }

        Timer {
            id: hoverTimer
            interval: 1500
            running: false
            repeat: false
            onTriggered: {
                Logger.d("Arch Updater", "Showing hover tip...")
                hoverTip.opacity = 0.85
                hoverTip.visible = true
            }
        }

        onEntered: {
            if (pluginApi.pluginSettings.hoverTip ?? pluginApi.manifest.metadata.defaultSettings.hoverTip) {
                Logger.d("Arch Updater", "Starting hover tip timer...")
                hoverTimer.restart()
            }
        }

        onExited: {
            Logger.d("Arch Updater", "Hover tip timer stopped!")
            hoverTimer.stop()
            hoverTip.opacity = 0
            hoverTip.visible = false
        }
    }
}
