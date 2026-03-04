import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  // Bar positioning properties
  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: Style.getBarHeightForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // Access main instance for state
  readonly property var mainInstance: pluginApi?.mainInstance
  
  property bool micActive: mainInstance ? mainInstance.micActive : false
  property bool camActive: mainInstance ? mainInstance.camActive : false
  property bool scrActive: mainInstance ? mainInstance.scrActive : false
  property var micApps: mainInstance ? mainInstance.micApps : []
  property var camApps: mainInstance ? mainInstance.camApps : []
  property var scrApps: mainInstance ? mainInstance.scrApps : []

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property bool hideInactive: cfg.hideInactive ?? defaults.hideInactive ?? false
  property bool enableToast: cfg.enableToast ?? defaults.enableToast ?? true
  property bool removeMargins: cfg.removeMargins ?? defaults.removeMargins ?? false
  property int iconSpacing: cfg.iconSpacing ?? defaults.iconSpacing ?? 4
  property string activeColorKey: cfg.activeColor ?? defaults.activeColor ?? "primary"
  property string inactiveColorKey: cfg.inactiveColor ?? defaults.inactiveColor ?? "none"

  readonly property color activeColor: Color.resolveColorKey(activeColorKey)
  readonly property color inactiveColor: inactiveColorKey === "none" ? Qt.alpha(Color.mOnSurfaceVariant, 0.3) : Color.resolveColorKey(inactiveColorKey)
  readonly property color micColor: micActive ? activeColor : inactiveColor
  readonly property color camColor: camActive ? activeColor : inactiveColor
  readonly property color scrColor: scrActive ? activeColor : inactiveColor

  readonly property bool isVisible: !hideInactive || micActive || camActive || scrActive

  property real margins: removeMargins ? 0 : Style.marginM * 2

  readonly property real contentWidth: isVertical ? Style.capsuleHeight : Math.round(layout.implicitWidth + margins)
  readonly property real contentHeight: isVertical ? Math.round(layout.implicitHeight + margins) : Style.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Layout.alignment: Qt.AlignVCenter
  visible: root.isVisible
  opacity: root.isVisible ? 1.0 : 0.0

  function buildTooltip() {
    var parts = [];

    if (micActive && micApps.length > 0) {
      parts.push("Mic: " + micApps.join(", "));
    }

    if (camActive && camApps.length > 0) {
      parts.push("Cam: " + camApps.join(", "));
    }

    if (scrActive && scrApps.length > 0) {
      parts.push("Screen sharing: " + scrApps.join(", "));
    }

    return parts.length > 0 ? parts.join("\n") : "";
  }

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusM
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Item {
      id: layout

      anchors.verticalCenter: parent.verticalCenter
      anchors.horizontalCenter: parent.horizontalCenter

      implicitWidth: iconsLayout.implicitWidth
      implicitHeight: iconsLayout.implicitHeight

      GridLayout {
        id: iconsLayout

        columns: root.isVertical ? 1 : 3
        rows: root.isVertical ? 3 : 1

        rowSpacing: root.iconSpacing
        columnSpacing: root.iconSpacing

        NIcon {
          visible: micActive || !root.hideInactive
          icon: micActive ? "microphone" : "microphone-off"
          color: root.micColor
        }
        NIcon {
          visible: camActive || !root.hideInactive
          icon: camActive ? "camera" : "camera-off"
          color: root.camColor
        }
        NIcon {
          visible: scrActive || !root.hideInactive
          icon: scrActive ? "screen-share" : "screen-share-off"
          color: root.scrColor
        }
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": pluginApi?.tr("menu.settings"),
        "action": "settings",
        "icon": "settings"
      },
    ]

    onTriggered: function (action) {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "settings") {
        BarService.openPluginSettings(root.screen, pluginApi.manifest);
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton | Qt.LeftButton
    hoverEnabled: true

    onClicked: function (mouse) {
      if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      } else if (mouse.button === Qt.LeftButton) {
        if (pluginApi) pluginApi.openPanel(root.screen, root);
      }
    }

    onEntered: {
      var tooltipText = buildTooltip();
      if (tooltipText) {
        TooltipService.show(root, tooltipText, BarService.getTooltipDirection());
      }
    }
    onExited: TooltipService.hide()
  }
}
