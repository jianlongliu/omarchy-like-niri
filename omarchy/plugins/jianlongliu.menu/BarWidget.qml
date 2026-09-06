import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "jianlongliu.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue900"
    fontFamily: "omarchy"
    horizontalMargin: 4
    tooltipText: "Omarchy menu"
    labelVisible: false
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle jianlongliu.menu '{\"menu\":\"root\"}'")
    }
  }
}
