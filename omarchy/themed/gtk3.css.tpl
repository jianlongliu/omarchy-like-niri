/* GTK3 主题色 —— 由 Omarchy 主题模板生成，请勿直接编辑。
   要改配色请改 ~/.config/omarchy/themed/gtk3.css.tpl 后重跑 omarchy theme set。

   ⚠️ 与 GTK4 的关键差异（实测）：
   1. GTK3 里 `@define-color` 压不过主题，**只能用显式选择器**；
   2. Adwaita 大量使用 `background-image` 渐变，**不写 `background-image: none` 就盖不住**；
   3. `GTK_THEME` 环境变量同样会压死本文件，须先清除。
   4. 路径固定为 `$HOME/.config/gtk-3.0/gtk.css`——`XDG_CONFIG_HOME` 隔离对它无效。 */

/* ===== 基础表面 ===== */
window, .background {
  background-color: {{ background }};
  color: {{ foreground }};
}

/* 内容区（列表 / 树 / 图标视图）比窗口更暗 */
.view, treeview.view, iconview, .view text {
  background-color: {{ dark_background }};
  color: {{ foreground }};
}

/* ===== 标题栏 / 页眉 ===== */
headerbar, .titlebar, headerbar.default-decoration {
  background-image: none;
  background-color: {{ lighter_background }};
  color: {{ foreground }};
  border-color: {{ background }};
  box-shadow: none;
}
headerbar:backdrop, .titlebar:backdrop { background-image: none; background-color: {{ background }}; }

/* 对话框动作区（Cancel / Select 那一行）*/
.dialog-action-area, .dialog-action-box, actionbar > revealer > box {
  background-image: none;
  background-color: {{ background }};
}

/* ===== 侧栏 ===== */
.sidebar, placessidebar, stacksidebar, .sidebar list {
  background-color: {{ lighter_background }};
  color: {{ foreground }};
}
.sidebar row:selected, placessidebar row:selected, stacksidebar row:selected,
.sidebar list row:selected {
  background-color: {{ accent }};
  color: {{ dark_background }};
}
.sidebar row:hover, placessidebar row:hover { background-color: {{ selection }}; }

/* ===== 选中态（全局）===== */
row:selected, .view:selected, treeview:selected, iconview:selected,
flowboxchild:selected, .view:selected:focus {
  background-color: {{ accent }};
  color: {{ dark_background }};
}
row:selected label, .view:selected label { color: {{ dark_background }}; }

/* ===== 按钮 ===== */
button {
  background-image: none;
  background-color: {{ lighter_background }};
  color: {{ foreground }};
  border-color: {{ background }};
}
button:hover { background-image: none; background-color: {{ selection }}; }
button:active, button:checked { background-image: none; background-color: {{ accent }}; color: {{ dark_background }}; }
button:disabled { background-color: {{ background }}; color: {{ muted }}; }

/* 建议动作按钮（Select / Open）*/
button.suggested-action {
  background-image: none;
  background-color: {{ accent }};
  color: {{ dark_background }};
}
button.suggested-action:hover { background-image: none; background-color: {{ muted }}; color: {{ dark_background }}; }
button:focus { outline-color: {{ accent }}; }

/* ===== 输入框 ===== */
entry, entry:focus, spinbutton, searchentry {
  background-image: none;
  background-color: {{ dark_background }};
  color: {{ foreground }};
  border-color: {{ lighter_background }};
}
/* 焦点环：Adwaita 用 box-shadow 画（不是 border-color），只改 border 会留下蓝环 */
entry:focus, spinbutton:focus:not(.vertical) {
  border-color: {{ accent }};
  box-shadow: inset 0 0 0 1px {{ accent }};
}
entry selection, label selection, textview selection, spinbutton selection {
  background-color: {{ accent }};
  color: {{ dark_background }};
}
entry:disabled { color: {{ muted }}; }

/* ===== 路径条 / 面包屑 ===== */
.path-bar button, .path-bar button:checked { background-image: none; }
.path-bar button:checked { background-color: {{ lighter_background }}; color: {{ foreground }}; }

/* ===== 弹出层 / 菜单 ===== */
popover, popover.background, menu, .menu, .context-menu {
  background-image: none;
  background-color: {{ lighter_background }};
  color: {{ foreground }};
  border-color: {{ background }};
}
menuitem:hover, menu menuitem:hover { background-color: {{ accent }}; color: {{ dark_background }}; }
tooltip, tooltip.background {
  background-image: none;
  background-color: {{ lighter_background }};
  color: {{ foreground }};
  border-color: {{ accent }};
}

/* ===== 滚动条 ===== */
scrollbar { background-color: {{ background }}; border-color: {{ background }}; }
scrollbar slider { background-color: {{ muted }}; border-color: {{ background }}; }
scrollbar slider:hover { background-color: {{ accent }}; }
scrollbar trough { background-color: {{ background }}; }

/* ===== 进度 / 开关 / 勾选 ===== */
progressbar trough { background-color: {{ dark_background }}; border-color: {{ lighter_background }}; }
progressbar progress { background-color: {{ accent }}; border-color: {{ accent }}; }
switch { background-color: {{ lighter_background }}; border-color: {{ background }}; }
switch:checked { background-color: {{ accent }}; border-color: {{ accent }}; }
switch slider { background-color: {{ foreground }}; }
check:checked, radio:checked { background-image: none; background-color: {{ accent }}; color: {{ dark_background }}; }
check, radio { background-image: none; background-color: {{ dark_background }}; border-color: {{ muted }}; }
scale highlight { background-color: {{ accent }}; }
scale slider { background-color: {{ foreground }}; border-color: {{ background }}; }
levelbar block.filled { background-color: {{ accent }}; }

/* ===== 标签页 ===== */
notebook > header { background-image: none; background-color: {{ background }}; border-color: {{ lighter_background }}; }
notebook > header > tabs > tab { background-image: none; color: {{ muted }}; }
notebook > header > tabs > tab:checked { color: {{ foreground }}; }
/* 选中标签的下划线：Adwaita 用 inset box-shadow 画（蓝），必须同形覆盖 */
notebook > header.top > tabs > tab:checked { box-shadow: inset 0 -4px {{ accent }}; }
notebook > header.bottom > tabs > tab:checked { box-shadow: inset 0 4px {{ accent }}; }
notebook > header.left > tabs > tab:checked { box-shadow: inset -4px 0 {{ accent }}; }
notebook > header.right > tabs > tab:checked { box-shadow: inset 4px 0 {{ accent }}; }
notebook > header.top > tabs > tab:hover { box-shadow: inset 0 -4px {{ lighter_background }}; }
notebook > stack { background-color: {{ background }}; }

/* ===== 残留修正：Adwaita 里硬编码的蓝色兜底样式 ===== */
/* .gtkstyle-fallback 是视图控件的兜底选中态，不覆盖会在部分控件下透出蓝 */
.gtkstyle-fallback:selected, .content-view .tile:selected, .content-view .tile:active {
  background-color: {{ accent }};
  color: {{ dark_background }};
}
/* 树表列头：Adwaita 用 `treeview.view header button` 这种高优先级选择器，普通 button 规则盖不住 */
treeview.view header button {
  background-image: none;
  background-color: {{ lighter_background }};
  color: {{ muted }};
  border-color: {{ background }};
}
treeview.view header button:hover { background-image: none; background-color: {{ selection }}; color: {{ foreground }}; }
treeview.view header button:active { background-image: none; color: {{ foreground }}; }

/* ===== 分隔 / 杂项 ===== */
separator { background-color: {{ lighter_background }}; }
frame > border, .frame { border-color: {{ lighter_background }}; }
calendar:selected { background-color: {{ accent }}; color: {{ dark_background }}; }
dim-label, .dim-label { color: {{ muted }}; }
link, button.link { color: {{ accent }}; }
