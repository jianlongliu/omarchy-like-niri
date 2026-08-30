# Changelog — ~/.config/hypr

改动日志（倒序，最新在上）。提交代码时同步更新本节。

## 2026-08-30
- **zen**: `windows.lua` 给 zen 加 `opacity 0.92 0.88` 实现毛玻璃透壁纸；`idle_inhibit` 保持看视频（bilibili）不锁屏。改动理由：Firefox Wayland 单 surface 无法 CSS 局部透明，只能整窗 opacity + userChrome 全透明（详见 `~/Documents/AI Agents/zen-frosted-glass.md`）。

## 2026-08-28
- **workspace-overview 移除**: 删掉 `io.github.sirmenef.workspace-overview` 绑定（Super+GRAVE），总览只保留 niri 化 scrolloverview 一套，避免两套总览互扰。

## 2026-08-25
- **scrolloverview**: 用 Lua 函数 `hl.plugin.scrolloverview.overview("toggle all")` 绑定 Super+Tab，修复 dispatcher 字符串走 exec_cmd 的静默空操作。
- **animation**: `looknfeel.lua` 打开 `workspaces` 纵向动画（`style=slidevert`），切工作区从硬切改 niri 式平滑滑动。
- **bindings**: 加有界动态工作区（Super+滚轮，滚到底建一个空区即停）、有界移窗（Super+Ctrl+↑/↓，独窗不越界）、Alt+滚轮空间聚焦、Super+Q/Alt+F4 关窗。
- **workspace-pill**: bar 工作区指示器改 GNOME 45 圆点/胶囊（克隆 `jianlongliu.workspaces`）。
