import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
  id: root
  
  property var pluginApi: null

  // Standard panel properties
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 320 * Style.uiScaleRatio
  property real contentPreferredHeight: 450 * Style.uiScaleRatio
  
  readonly property var mainInstance: pluginApi?.mainInstance

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      // Header Box
      NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + Style.marginM * 2
        
        RowLayout {
           id: headerRow
           anchors.fill: parent
           anchors.margins: Style.marginM
           spacing: Style.marginS

           NIcon {
             icon: "shield-check"
             color: Color.mPrimary
             pointSize: Style.fontSizeL
           }

           NText {
             Layout.fillWidth: true
             text: pluginApi?.tr("history.title") || "Access History"
             font.weight: Style.fontWeightBold
             pointSize: Style.fontSizeL
             color: Color.mOnSurface
           }
           
           NIconButton {
               icon: "trash"
               baseSize: Style.baseWidgetSize * 0.8
               onClicked: {
                   if (mainInstance) mainInstance.clearHistory();
               }
           }
        }
      }

      
      Item {
          Layout.fillWidth: true
          Layout.fillHeight: true
          
          NScrollView {
            id: scrollView
            anchors.fill: parent
            horizontalPolicy: ScrollBar.AlwaysOff
            verticalPolicy: ScrollBar.AsNeeded
            
            ColumnLayout {
                width: scrollView.availableWidth
                spacing: Style.marginS
                
                Repeater {
                    model: mainInstance ? mainInstance.accessHistory : []
                    
                    delegate: Rectangle {
                      Layout.fillWidth: true
                      implicitHeight: 56 * Style.uiScaleRatio
                      radius: Style.radiusM
                      color: Color.mSurfaceVariant
                      
                      RowLayout {
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM
                        
                        Rectangle {
                            width: 32 * Style.uiScaleRatio
                            height: 32 * Style.uiScaleRatio
                            radius: width/2
                            color: Qt.alpha(iconColor, 0.1)
                            
                            readonly property color iconColor: Color.resolveColorKey(modelData.colorKey || "primary")
                            
                            NIcon {
                               anchors.centerIn: parent
                               icon: modelData.icon
                               color: parent.iconColor
                               pointSize: Style.fontSizeM
                            }
                        }
                        
                        ColumnLayout {
                          Layout.fillWidth: true
                          spacing: 0
                          
                          NText {
                            Layout.fillWidth: true
                            text: modelData.appName
                            elide: Text.ElideRight
                            font.weight: Style.fontWeightBold
                            pointSize: Style.fontSizeM
                          }
                          
                          RowLayout {
                              Layout.fillWidth: true
                              spacing: Style.marginS
                              
                              NText {
                                text: modelData.time
                                color: Qt.alpha(Color.mOnSurface, 0.7)
                                pointSize: Style.fontSizeS
                              }
                              
                              NText {
                                text: "•"
                                color: Qt.alpha(Color.mOnSurface, 0.3)
                                pointSize: Style.fontSizeS
                              }
                              
                              NText {
                                text: {
                                    const action = modelData.action || "started";
                                    return pluginApi?.tr("history.action." + action) || action;
                                }
                                color: (modelData.action || "started") === "stopped" ? Color.resolveColorKey("error") : Color.resolveColorKey("primary")
                                font.weight: Style.fontWeightBold
                                pointSize: Style.fontSizeS
                              }
                          }
                        }
                      }
                    }
                }
                
                // Empty state
                NText {
                    Layout.alignment: Qt.AlignHCenter
                    visible: (!mainInstance || mainInstance.accessHistory.length === 0)
                    text: pluginApi?.tr("history.empty") || "No recent access"
                    color: Qt.alpha(Color.mOnSurface, 0.5)
                    pointSize: Style.fontSizeM
                    Layout.topMargin: Style.marginL
                }
                
                Item { Layout.fillHeight: true } // spacer
            }
          }
      }
    }
  }
}
