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

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        property bool hovered: false

        // 明暗层级:空点 < 有窗口 < 聚焦胶囊;悬停任意点点亮以示可点
        readonly property color col: focused
          ? Qt.alpha(root.base, hovered ? 1.0 : 0.9)
          : hovered
            ? Qt.alpha(root.base, 0.85)
            : occupied
              ? Qt.alpha(root.base, 0.62)
              : Qt.alpha(root.base, 0.15)

        implicitWidth: width
        implicitHeight: height
        width: focused ? root.expanded : root.dot
        height: root.dot
        radius: height / 2
        color: col

        Behavior on width {
          // 展开时轻微过冲回弹(OutBack),收起时快速落定
          NumberAnimation {
            duration: 220
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
          }
        }
        Behavior on color {
          ColorAnimation { duration: 160; easing.type: Easing.InOutCubic }
        }

        MouseArea {
          id: hoverArea
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.ArrowCursor
          onEntered: dot.hovered = true
          onExited: dot.hovered = false
          onClicked: function(mouse) { root.focusWorkspace(modelData) }
        }
      }
    }
  }
}
