import QtQuick
import qs.Commons
import qs.Ui

BarIndicator {
  id: root

  // BarIndicator shrinks status glyphs to font.caption; use the same size as
  // sibling bar icons (BarIconButton → Style.bar.iconFont).
  fontSize: Style.bar.iconFont

  // System notification service (omarchy.notifications) drives Do Not Disturb.
  // Bind to it so this bell stays the single notification/DND indicator.
  readonly property var notificationService: bar?.shell?.firstPartyServiceFor("omarchy.notifications")
  readonly property bool dnd: notificationService ? notificationService.doNotDisturb : false

  active: dnd
  activeText: "󰂛"
  inactiveText: "󰂛"
  activeTooltipText: "Allow Notifications"
  inactiveTooltipText: "Silence Notifications"

  onPressed: function() {
    if (root.notificationService) {
      root.notificationService.setDoNotDisturb(!root.notificationService.doNotDisturb)
    }
  }
}
