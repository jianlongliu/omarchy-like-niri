import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "jianlongliu.arch-logo"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: "Omarchy menu"

    // Arch logo, tinted to the bar foreground so it matches every other icon.
    // The SVG ships as Arch blue (#1793d1); without colorization it would be
    // the only coloured thing in the bar.
    iconComponent: Component {
      Item {
        Image {
          id: logo
          anchors.fill: parent
          source: Qt.resolvedUrl("arch-logo.svg")
          sourceSize.width: Math.round(width * Screen.devicePixelRatio)
          sourceSize.height: Math.round(height * Screen.devicePixelRatio)
          fillMode: Image.PreserveAspectFit
          smooth: true
          // Hidden but layered, so MultiEffect can sample it as a texture.
          visible: false
          layer.enabled: true
        }

        MultiEffect {
          anchors.fill: parent
          source: logo
          colorization: 1.0
          colorizationColor: button.foreground
        }
      }
    }

    onPressed: function(btn) {
      if (!root.bar) return
      if (btn === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }
  }
}
