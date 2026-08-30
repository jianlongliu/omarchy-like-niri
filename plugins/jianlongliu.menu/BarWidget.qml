import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "jianlongliu.menu"

  readonly property int avatarSize: Math.max(24, Math.round(root.barSize * 0.55))

  implicitWidth: root.avatarSize + 14
  implicitHeight: root.barSize

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    horizontalMargin: 4
    tooltipText: "Omarchy menu"
    text: "\ue900"
    labelVisible: false

    Item {
      anchors.centerIn: parent
      width: root.avatarSize
      height: root.avatarSize

      Image {
        anchors.fill: parent
        source: "/home/jianlongliu/.config/omarchy/avatar_circle.png"
        fillMode: Image.PreserveAspectFit
        asynchronous: true
      }

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: Qt.rgba(1, 1, 1, 0.18)
      }
    }

    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle jianlongliu.menu '{\"menu\":\"root\"}'")
    }
  }
}
