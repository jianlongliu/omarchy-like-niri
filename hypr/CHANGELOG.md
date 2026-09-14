# Changelog — ~/.config/hypr

改动日志（倒序，最新在上）。提交代码时同步更新本节。

## 2026-09-15 — 便携屏接入、工作区滚动限定主屏、btop/yazi 浮窗、边框 4
- **monitors: 便携屏接入**：`HDMI-A-1`（BOE 2560x1600@120）放 DP-2 **左侧** `-1600x0`（scale 1.6 → 逻辑宽 1600，与 DP-2 的 `0..2400` 正好接壤）；DP-2 由 `3840x2160@144` 改 `@120` 并固定 `position = "0x0"`（原 `auto`）。**为什么**：两屏逻辑矩形必须接壤鼠标才跨得过去，留缝会卡在中间。
- **monitors: `ws6` 钉在便携屏**（`hl.workspace_rule`）——看片专用，其余工作区留给主屏。
- **bindings: 工作区滚动/移动限定主屏 1–3 并加边界 clamp**：Hyprland 工作区 ID **全局唯一且绑定在各自屏上**，`focus({workspace=N})` 的语义是"去 N 所在的那块屏"而非"当前屏切到 N"，不设范围就会跨屏或抢走别屏的工作区号（已实测原生 `focus({workspace="r+1"/"r-1"})` 是相对本屏、不跨屏，但仍会吃掉别屏的号且无边界，故改用显式 `MAIN_WS_MIN/MAX` + clamp）。
- **bindings: `SUPER+E` 直连 `nautilus`**：原 wrapper `~/.local/bin/nautilus` 只为注入 `GTK_THEME=Catppuccin`，随 GTK 配色改由主题模板驱动而废弃。**为什么非改不可**：绑定直指被删的脚本路径，不改会按键静默失效。
- **bindings: 补 Windows 风格快捷键 `CTRL+ALT+DELETE → 系统菜单`**（出厂此项是 Close all windows）。
- **windows: `btop`/`yazi` 脱 `floating-window` 标签、自定 1280×800 居中浮窗**：omarchy 给的 875×600 对 TUI 太挤（btop 丢列、yazi 丢预览）；该标签尺寸以**动态规则**形式后套，普通静态 `size` 压不过 → 先 `tag = "-floating-window"` 脱标签再重述 `float`/`center`/`size`（共享该标签的对话框、文件选择器保持小尺寸不变）。`yazi` 另加 `opacity 0.92 0.88` 配合全局 blur。
- **looknfeel: 边框 5 → 4**。

## 2026-09-11
- **looknfeel: 关 blur `xray`**（true → false）：模糊改为取背后真实内容（含窗口），不再只糊壁纸。代价是浮动层模糊开销略高，6950 XT 无压力。
- **looknfeel: 加 `fadeSwitch` 动画**（`speed=5, easeOutQuint`）：同工作区内切换焦点（如 Super+Shift+滚轮切应用）原是硬切，现平滑淡入。注意这是**全局**的——Super+方向键切焦点同样生效。Omarchy 默认此项关闭。
- **looknfeel: 边框 4 → 5**。
- **looknfeel: 合入 `charlieras262.omablur` 覆盖块**（`rounding=20`、`blur size=11 passes=2`、`ignore_opacity=true`）。该块在文件末尾，**覆盖**上文基础 blur 块（size=8/passes=5），运行时以 11/2 为准。
- **windows: 加 Chromium 规则**（`^org\.chromium\.Chromium$`）：公司工单系统需 Windows UA，用精确 class 匹配以免被上面的 `zen` 规则误伤；同时 `idle_inhibit=always` + `opacity 0.92 0.88`。
- **windows: flea（Quickshell 文件管理器）加 `opacity 0.92 0.88`**：让全局 blur 透出来，与 Omarchy liquid-glass 观感一致。
- **apps/omarchy-shell: 加两条 layer_rule**：`omarchy-keybinding-editor`（全屏 scrim + 居中卡片，`ignore_alpha=0.5`）与 `omarchy-spotlight`（Spotlight 命令面板，只糊卡片本体，`ignore_alpha=0.4`）。
- **autostart: 加 `activate-linux`**（Windows 风格"激活 Windows"水印，玩梗）。
- **bindings: `ALT + SPACE → Spotlight`**（`io.github.maajix.spotlight`）。ALT+SPACE 此前空闲（见上一条死绑定移除）；**不用 CTRL+SPACE 是因为与 fcitx5 冲突**。
- **hyprland: 接入 `firstpick.keybindings` 键位编辑器**（`bridge.lua` 的 start/finish 捕获块）。编辑器数据存 `keybindings-editor/overrides.lua`；其 `.lock` 与 `backups/` 已加 `.gitignore`。
- **plugins: scrolloverview `scale` 0.8 → 0.7、`workspace_gap` 100 → 50**（总览卡片更紧凑）。

## 2026-09-10
- **bindings: 移除 ALT+SPACE 死绑定**: `ALT+SPACE → omarchy-shell shell toggle jesseburlamaque.omarchy-find` 指向早已卸载的 find 插件（日志 `summon: unknown plugin jesseburlamaque.omarchy-find`），删除以减少无效键位与噪音。若日后重装 find 插件再按需加回。

## 2026-08-30
- **cursor**: 系统光标换 Bibata-Modern-Amber（琥珀色），尺寸 30。`envs.lua` 设 `XCURSOR_THEME`/`HYPRCURSOR_THEME`/`XCURSOR_SIZE`/`HYPRCURSOR_SIZE`（GTK/XWayland 应用读）；`autostart.lua` 加 `hyprctl setcursor Bibata-Modern-Amber 30`（Hyprland 自身光标）。Omarchy 默认只设尺寸不设主题名，故补 `*_THEME`。详见（本地笔记存档）。
- **zen**: `windows.lua` 给 zen 加 `opacity 0.92 0.88` 实现毛玻璃透壁纸；`idle_inhibit` 保持看视频（bilibili）不锁屏。改动理由：Firefox Wayland 单 surface 无法 CSS 局部透明，只能整窗 opacity + userChrome 全透明（详见（本地笔记存档））。

## 2026-08-28
- **workspace-overview 移除**: 删掉 `io.github.sirmenef.workspace-overview` 绑定（Super+GRAVE），总览只保留 niri 化 scrolloverview 一套，避免两套总览互扰。

## 2026-08-25
- **scrolloverview**: 用 Lua 函数 `hl.plugin.scrolloverview.overview("toggle all")` 绑定 Super+Tab，修复 dispatcher 字符串走 exec_cmd 的静默空操作。
- **animation**: `looknfeel.lua` 打开 `workspaces` 纵向动画（`style=slidevert`），切工作区从硬切改 niri 式平滑滑动。
- **bindings**: 加有界动态工作区（Super+滚轮，滚到底建一个空区即停）、有界移窗（Super+Ctrl+↑/↓，独窗不越界）、Alt+滚轮空间聚焦、Super+Q/Alt+F4 关窗。
- **workspace-pill**: bar 工作区指示器改 GNOME 45 圆点/胶囊（克隆 `jianlongliu.workspaces`）。
