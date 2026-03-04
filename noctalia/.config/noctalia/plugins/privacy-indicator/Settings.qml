import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property bool hideInactive: cfg.hideInactive ?? defaults.hideInactive ?? false
  property bool enableToast: cfg.enableToast ?? defaults.enableToast ?? true
  property bool removeMargins: cfg.removeMargins ?? defaults.removeMargins ?? false
  property int iconSpacing: cfg.iconSpacing ?? defaults.iconSpacing ?? 4
  property string activeColor: cfg.activeColor ?? defaults.activeColor ?? "primary"
  property string inactiveColor: cfg.inactiveColor ?? defaults.inactiveColor ?? "none"

  spacing: Style.marginL

  Component.onCompleted: {
    Logger.i("PrivacyIndicator", "Settings UI loaded");
  }

  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    NToggle {
      label: pluginApi?.tr("settings.hideInactive.label")
      description: pluginApi?.tr("settings.hideInactive.desc")

      checked: root.hideInactive
      onToggled: checked =>  {
        root.hideInactive = checked;
      }
    }

    NToggle {
      label: pluginApi?.tr("settings.enableToast.label")
      description: pluginApi?.tr("settings.enableToast.desc")

      checked: root.enableToast
      onToggled: checked => {
        root.enableToast = checked;
      }
    }    

    NToggle {
      label: pluginApi?.tr("settings.removeMargins.label")
      description: pluginApi?.tr("settings.removeMargins.desc")

      checked: root.removeMargins
      onToggled: checked =>  {
        root.removeMargins = checked;
      }
    }

    NColorChoice {
      label: pluginApi?.tr("settings.activeColor.label")
      description: pluginApi?.tr("settings.activeColor.desc")
      currentKey: root.activeColor
      onSelected: key => root.activeColor = key
    }

    NColorChoice {
      label: pluginApi?.tr("settings.inactiveColor.label")
      description: pluginApi?.tr("settings.inactiveColor.desc")
      currentKey: root.inactiveColor
      onSelected: key => root.inactiveColor = key
      noneColor: Qt.alpha(Color.mOnSurfaceVariant, 0.3)
      noneOnColor: Qt.alpha(Color.mOnSurface, 0.7)
    }

    NComboBox {
      label: pluginApi?.tr("settings.iconSpacing.label")
      description: pluginApi?.tr("settings.iconSpacing.desc")

      model: {
        const labels = ["XXS", "XS", "S", "M", "L", "XL"];
        const values = [Style.marginXXS, Style.marginXS, Style.marginS, Style.marginM, Style.marginL, Style.marginXL];

        const result = [];
        for (var i = 0; i < labels.length; ++i) {
          const v = values[i];
          result.push({
            key: v.toFixed(0),
            name: `${labels[i]} (${v}px)`
          });
        }
        return result;
      }

      // INFO: From my understanding, the toFixed(0) shouldn't be needed here and there, but without the
      // current key does not show when opening the settings window.
      currentKey: root.iconSpacing.toFixed(0)
      onSelected: key => root.iconSpacing = key
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("PrivacyIndicator", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.hideInactive = root.hideInactive;
    pluginApi.pluginSettings.enableToast = root.enableToast;
    pluginApi.pluginSettings.iconSpacing = root.iconSpacing;
    pluginApi.pluginSettings.removeMargins = root.removeMargins;
    pluginApi.pluginSettings.activeColor = root.activeColor;
    pluginApi.pluginSettings.inactiveColor = root.inactiveColor;

    pluginApi.saveSettings();

    Logger.i("PrivacyIndicator", "Settings saved successfully");
  }
}
