import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// GNOME 45 风格 workspace 纯点指示器:每个 workspace 一个实心小圆,
// 当前工作区变成横向轻微拉长的圆头胶囊。无文字、无边框、无厚重背景。
BarWidget {
  id: root
  moduleName: "jianlongliu.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  // ---- 几何:极小圆点,当前轻微拉长 ----
  readonly property real dot: root.vertical ? root.barSize * 0.32 : Math.max(7, Math.round(root.barSize * 0.28))
  readonly property real expanded: root.vertical ? dot : dot * 2.6
  readonly property real spacing: dot * 0.5

  readonly property color base: root.bar ? root.bar.barForeground : Color.foreground
  readonly property color dim: Qt.alpha(base, 0.34)
  readonly property color active: Qt.alpha(base, 0.85)

  implicitWidth: row.implicitWidth
  implicitHeight: root.barSize

  Row {
    id: row
    spacing: root.spacing
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
      model: root.workspaceIds()

      Rectangle {
        id: dot
        required property int modelData

        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        implicitWidth: width
        implicitHeight: height
        width: focused ? root.expanded : root.dot
        height: root.dot
        radius: height / 2
        color: focused ? root.active : root.dim

        Behavior on width {
          NumberAnimation { duration: 220; easing.type: Easing.InOutCubic }
        }
        Behavior on color {
          ColorAnimation { duration: 220; easing.type: Easing.InOutCubic }
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.ArrowCursor
          onClicked: function(mouse) { root.focusWorkspace(modelData) }
        }
      }
    }
  }
}
