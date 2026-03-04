import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null

  // --- Logic extracted from BarWidget.qml ---
  
  property bool micActive: false
  property bool camActive: false
  property bool scrActive: false
  property var micApps: []
  property var camApps: []
  property var scrApps: []

  property var accessHistory: []
  
  // Previous states for history tracking
  property var _prevMicApps: []
  property var _prevCamApps: []
  property var _prevScrApps: []

  // Get active color from settings or default
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property bool enableToast: cfg.enableToast ?? defaults.enableToast ?? true
  property string activeColorKey: cfg.activeColor ?? defaults.activeColor ?? "primary"

  PwObjectTracker {
    objects: Pipewire.ready ? Pipewire.nodes.values : []
  }

  Process {
    id: cameraDetectionProcess
    running: false
    command: ["sh", "-c", "for dev in /sys/class/video4linux/video*; do [ -e \"$dev/name\" ] && grep -qv 'Metadata' \"$dev/name\" && dev_name=$(basename \"$dev\") && find /proc/[0-9]*/fd -lname \"/dev/$dev_name\" 2>/dev/null; done | cut -d/ -f3 | xargs -r ps -o comm= -p | sort -u | tr '\\n' ',' | sed 's/,$//'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var appsString = this.text.trim();
        var apps = appsString.length > 0 ? appsString.split(',') : [];
        root.camApps = apps;
        root.camActive = apps.length > 0;
      }
    }
  }


  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: updatePrivacyState()
  }

  function hasNodeLinks(node, links) {
    for (var i = 0; i < links.length; i++) {
        var link = links[i];
        if (link && (link.source === node || link.target === node)) return true;
    }
    return false;
  }

  function getAppName(node) {
    return node.properties["application.name"] || node.nickname || node.name || "";
  }

  function updateMicrophoneState(nodes, links) {
    var appNames = [];
    var isActive = false;
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (!node || !node.isStream || !node.audio || node.isSink) continue;
      if (!hasNodeLinks(node, links) || !node.properties) continue;
      var mediaClass = node.properties["media.class"] || "";
      if (mediaClass === "Stream/Input/Audio") {
        if (node.properties["stream.capture.sink"] === "true") continue;
        isActive = true;
        var appName = getAppName(node);
        if (appName && appNames.indexOf(appName) === -1) appNames.push(appName);
      }
    }
    root.micActive = isActive;
    root.micApps = appNames;
  }

  function updateCameraState() {
    cameraDetectionProcess.running = true;
  }

  function isScreenShareNode(node) {
    if (!node.properties) return false;
    var mediaClass = node.properties["media.class"] || "";
    if (mediaClass.indexOf("Audio") >= 0) return false;
    if (mediaClass.indexOf("Video") === -1) return false;
    var mediaName = (node.properties["media.name"] || "").toLowerCase();
    if (mediaName.match(/^(xdph-streaming|gsr-default|game capture|screen|desktop|display|cast|webrtc|v4l2)/) ||
        mediaName === "gsr-default_output" ||
        mediaName.match(/screen-cast|screen-capture|desktop-capture|monitor-capture|window-capture|game-capture/i)) {
      return true;
    }
    return false;
  }

  function updateScreenShareState(nodes, links) {
    var appNames = [];
    var isActive = false;
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (!node || !hasNodeLinks(node, links) || !node.properties) continue;
      if (isScreenShareNode(node)) {
        isActive = true;
        var appName = getAppName(node);
        if (appName && appNames.indexOf(appName) === -1) appNames.push(appName);
      }
    }
    root.scrActive = isActive;
    root.scrApps = appNames;
  }

  function updatePrivacyState() {
    if (!Pipewire.ready) return;
    var nodes = Pipewire.nodes.values || [];
    var links = Pipewire.links.values || [];
    updateMicrophoneState(nodes, links);
    updateCameraState();
    updateScreenShareState(nodes, links);
  }

  // --- History Persistence ---
  
  property string stateFile: ""
  property bool isLoaded: false

  Component.onCompleted: {
    // Setup state file path
    Qt.callLater(() => {
                   if (typeof Settings !== 'undefined' && Settings.cacheDir) {
                     stateFile = Settings.cacheDir + "privacy-history.json";
                     historyFileView.path = stateFile;
                   }
                 });
  }

  FileView {
    id: historyFileView
    printErrors: false
    watchChanges: false

    adapter: JsonAdapter {
      id: adapter
      property var history: []
    }

    onLoaded: {
      root.isLoaded = true;
      if (adapter.history) {
        // Restore history
        root.accessHistory = adapter.history;
      }
    }
    
    onLoadFailed: error => {
        // If file doesn't exist (error 2), we are ready to save new data
        if (error === 2) {
            root.isLoaded = true;
        } else {
            console.error("PrivacyIndicator: Failed to load history file:", error);
            root.isLoaded = true; // Try to continue anyway
        }
    }
  }

  function saveHistory() {
    if (!stateFile || !isLoaded) return;
    
    adapter.history = root.accessHistory;
    
    // Ensure cache directory exists and save
    try {
      Quickshell.execDetached(["mkdir", "-p", Settings.cacheDir]);
      Qt.callLater(() => {
                     try {
                       historyFileView.writeAdapter();
                     } catch (e) {
                       console.error("PrivacyIndicator: Failed to save history", e);
                     }
                   });
    } catch (e) {
      console.error("PrivacyIndicator: Failed to save history", e);
    }
  }

  function addToHistory(app, type, icon, colorKey, action) {
    var time = new Date().toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
    var entry = {
      "appName": app,
      "type": type,
      "icon": icon,
      "colorKey": colorKey,
      "time": time,
      "timestamp": Date.now(),
      "action": action // "started" or "stopped"
    };
    var newHistory = [entry].concat(accessHistory);
    if (newHistory.length > 50) newHistory = newHistory.slice(0, 50); // Increased limit as we have more entries now
    accessHistory = newHistory;
    saveHistory();
  }

  function clearHistory() {
      accessHistory = [];
      saveHistory();
  }

  function checkAppChanges(newApps, oldApps, type, icon, colorKey) {
    if (!newApps && !oldApps) return;
    
    // Check for new apps (Started)
    if (newApps) {
        for (var i = 0; i < newApps.length; i++) {
            var app = newApps[i];
            if (!oldApps || oldApps.indexOf(app) === -1) {
                addToHistory(app, type, icon, colorKey, "started");
            }
        }
    }
    
    // Check for removed apps (Stopped)
    if (oldApps) {
        for (var j = 0; j < oldApps.length; j++) {
            var oldApp = oldApps[j];
            if (!newApps || newApps.indexOf(oldApp) === -1) {
                addToHistory(oldApp, type, icon, colorKey, "stopped");
            }
        }
    }
  }


  onMicAppsChanged: {
    checkAppChanges(micApps, _prevMicApps, "Microphone", "microphone", activeColorKey);
    _prevMicApps = micApps;
  }
  // Helper to detect activation edge
  property bool oldMicActive: false
  onMicActiveChanged: {
    if (enableToast && micActive && !oldMicActive) {
        ToastService.showNotice(pluginApi?.tr("toast.mic-on") || "Microphone is active", "", "microphone");
    }
    oldMicActive = micActive
  }

  property bool oldCamActive: false
  onCamActiveChanged: {
      if (enableToast && camActive && !oldCamActive) {
          ToastService.showNotice(pluginApi?.tr("toast.cam-on") || "Camera is active", "", "camera");
      }
      oldCamActive = camActive
  }
  onCamAppsChanged: {
    checkAppChanges(camApps, _prevCamApps, "Camera", "camera", activeColorKey);
    _prevCamApps = camApps;
  }

  property bool oldScrActive: false
  onScrActiveChanged: {
      if (enableToast && scrActive && !oldScrActive) {
          ToastService.showNotice(pluginApi?.tr("toast.screen-on") || "Screen sharing is active", "", "screen-share");
      }
      oldScrActive = scrActive
  }
  onScrAppsChanged: {
    checkAppChanges(scrApps, _prevScrApps, "Screen", "screen-share", activeColorKey);
    _prevScrApps = scrApps;
  }
  

}
