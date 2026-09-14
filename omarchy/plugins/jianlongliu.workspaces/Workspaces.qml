import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
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
    var ids = []
    var values = Hyprland.workspaces.values
    var focused = Hyprland.focusedWorkspace
    var focusId = focused !== null && focused.id > 0 ? focused.id : 0

    // 只上屏"有窗口的工作区"和"当前工作区"。
    // 空工作区(Hyprland 不会自动回收)不占位,否则中间会挂着一串暗点。
    for (var i = 0; i < values.length; i++) {
      var ws = values[i]
      if (ws.id <= 0) continue
      if (ws.toplevels.values.length > 0 || ws.id === focusId) ids.push(ws.id)
    }

    if (focusId > 0 && ids.indexOf(focusId) === -1) ids.push(focusId)
    if (ids.length === 0) ids.push(1)

    ids.sort(function(left, right) { return left - right })

    // GNOME 惯例:末尾补一个空槽代表"下一个工作区",点击即新建。
    // 空槽只会出现在末尾,除非用户在别的空工作区里,否则就是列表最后一个。
    var lastWs = workspaceById(ids[ids.length - 1])
    var lastOccupied = lastWs !== null && lastWs.toplevels.values.length > 0
    if (lastOccupied) ids.push(ids[ids.length - 1] + 1)

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

  // bar 上的模块是零间距紧挨着排的(Row { spacing: 0 }),模块之间的空隙
  // 全靠各个 widget 自己的内边距。胶囊右边紧挨着 omarchy.active-window:
  // 有窗口时它自己带左边距,胶囊不必再留;切到空白工作区时它会整块收起、
  // 宽度归零,后面的模块就会直接贴到胶囊上。所以只在那一种情况下由胶囊
  // 自己补一段等宽留白,让两种情况下的间隔看起来一致。
  // 判定条件与 active-window 的 visible 保持一致,否则两边会不同步。
  readonly property var activeToplevel: ToplevelManager.activeToplevel
  readonly property bool windowTitleShowing: !root.vertical && activeToplevel !== null
    && (activeToplevel.title || activeToplevel.appId || "") !== ""
  readonly property real trailingGap: root.windowTitleShowing ? 0 : Style.space(8)

  implicitWidth: row.implicitWidth + root.trailingGap
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
