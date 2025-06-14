// ClockWidget.qml
import QtQuick

Text {
    // we no longer need time as an input

    // directly access the time property from the Time singleton
    text: Time.time
}
