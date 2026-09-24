# Omarchy bar 视觉与克隆整合笔记

> 最后核对：2026-09-15 · Omarchy 4.0.3 / Hyprland 0.56.2
> 整合 （本地笔记存档） 原分散的 bar 视觉笔记（字号/对齐、克隆插件、工作区胶囊/磨砂玻璃、字体链、flea 对齐、GTK 应用对齐），去重后重排。相关总文档：`omarchy-nirification.md`；插件清单见 `omarchy-plugins.md`。
> 本机 bar：`charlieras262.floating-bar`（`Bar.qml`）；Hyprland 层规则在 `~/.config/hypr/apps/omarchy-shell.lua`；透明底在 `~/.config/omarchy/shell.toml`。

## 〇、公共前置（各节通用，先读）

### 为什么不能直接改 `/usr/share/omarchy/`
- `/usr/share/omarchy/` 是包拥有目录，**每次 `omarchy update` 会被还原**。
- 首选姿势：`omarchy plugin clone <id>` → 生成 `~/.config/omarchy/plugins/jianlongliu.<id>/`，**自动把 bar 布局切到克隆版**，改动持久。**仅适用于纯 `bar-widget`** 的内建控件（clock / workspaces / indicators…）。
- **⚠️ 带其它 kind 的插件（菜单 `menu`、OSD `panel`）不能这么干**：克隆会自动把源插件写进 `disabledPlugins`，你只剩克隆那一份 → 见 §4.1。
- 克隆后 `shell.json` 布局里 id 从 `omarchy.X` 换成 `jianlongliu.X`。**⚠️ `bar.centerAnchor` 不会跟着改**——原 anchor 若是 `omarchy.clock`，需手动改 `jianlongliu.clock`，否则中心锚定失效。

### 尺寸体系真相（别再猜数字）
`~/.config/omarchy/shell.toml` **覆盖默认值**，本机：`[bar] size-horizontal=40`、`[font] base-size=14`。
- Omarchy `Style`：`barScaleWithFont=true`，`fontScale = base-size/12 = 14/12 ≈ 1.167`，所有 `barToken`/`space` 都乘它。
- **⚠️ `size-horizontal` 也是 barToken，同样要乘**：40 × 1.167 ≈ **46.7 → bar 实测高 47px**（`hyprctl layers` 量 `omarchy-bar` 的 h）。别把 shell.toml 里的 40 当成 bar 高度。
- 其它 token 生效值：`iconSlot` 27→**31.5px**（按钮槽）、`iconCanvas` 16→**18.7px**（图标绘制区）。
- 字体 token（base=14）：`body` 14（clock/media/active-window）· `caption` ≈12 · `Style.bar.iconFont` 13→**≈15.2**（状态图标，同样吃 fontScale）。
- **禁用魔数**：13/16/18/27/32/`0.68*width` 一律不写，全走 Style token。想整体缩放改 `base-size`，bar 按 `barScaleWithFont` 一起长高。

### 生效 / 重启 / 回退
- `~/.config/omarchy/plugins/` 保存通常热重载；不稳用 `omarchy-shell shell rescanPlugins`。
- 彻底生效：`omarchy restart shell`；`ps -eo pid,lstart,cmd | grep "quickshell -n"` 确认新进程。
- 一键重置：`omarchy refresh shell`（自动备份当前配置再拷默认）。
- `omarchy theme set` 会重置 `base-size`；整栏不对劲先查 `shell.toml` base-size 是否 14。

### ⚠️ 改 `environment.d` 后要**重启**，注销无效
`environment.d` 只在 **systemd user manager 启动时**读一次，之后由它下传给子进程。
**注销不会结束 user manager**（它跨登录存活），所以新起的 Hyprland 仍旧继承旧变量；
`systemctl --user unset-environment` 也清不掉——omarchy `autostart.lua` 会 `import-environment` 回灌。

**验证**：`echo $变量名` 与 `tr '\0' '\n' < /proc/$(pgrep -x Hyprland)/environ | grep 变量名` 都为空才算生效。

---

## 一、图标 / 字号微调

### 1.1 整栏字号统一到 clock
**标准**：以 clock 为准（走 `Style.font.body`=base-size，本机 14，×scale 1.6 → 物理约 22.4px）。**问题**：大量控件写死 `caption`(≈12) 比 clock 小一圈。**改动**（caption→body）：
1. 克隆 `omarchy.keyboard-layout` → 改 `KeyboardLayout.qml` ~213
2. 克隆 `omarchy.system-update` → 改 `SystemUpdate.qml` ~61
> 右侧状态图标用 `Style.bar.iconFont`=13，比 body 略小但彼此统一，本次未动（可选项）。

### 1.2 图标对齐 / 换图标（历史任务，方法仍适用）
> **现状（2026-09-11 实测）**：剪贴板 `io.github.majesticio.clipboard-button` 现挂在 **right** 栏（不在左）；`local.opencode-go-usage` 现为 **disabled**（不在 bar）。下方"左侧"是当时的场景描述。
**需求**：左两用户插件图标（剪贴板、opencode-go）比右侧 tray/mihomo 大、剪贴板不垂直居中，要跟右侧视觉一致。
**右侧秘密**：外壳 `BarIconButton`（槽 `iconSlot`、图标画在 `iconCanvas`）→ 图标仅 ~18px 非满槽。**正确做法**：直接套 `BarIconButton` + 塞 `iconComponent`，别自制 `Item`+手写宽高。
- 白/单色 SVG：`iconComponent` 里包 `Item+Image+MultiEffect`，`colorizationColor = bar.barForeground` 随主题变色。**源 SVG 本身必须是白的**（`colorization` 按亮度相乘，有色的源会偏暗）——完整做法与两个坑见 §4.1。
- 删 `fixedHeight: Style.bar.iconSlot`（高度跟 barSize）；槽宽用 `iconSlot`，别 `Style.space(32)`。
- 改的文件：`io.github.majesticio.clipboard-button/BarWidget.qml`、`local.opencode-go-usage/Panel.qml`。
- 换图标例：opencode-go 的白色三柱折线（画布满、固定白、不随主题）→ 换 `assets/opencode-logo.svg`（单色）经 MultiEffect 着色。
- 调试：`OMARCHY_DEBUG_BAR_ICONS=1` 起 shell → 红框=槽、蓝框=iconCanvas。

**回退**：克隆的 keyboard-layout/system-update 用 `omarchy plugin remove jianlongliu.<id>` 或删目录并把 shell.json id 改回 `omarchy.<id>`；图标插件改回原组件。

### 1.3 ⚠️ 右侧状态图标是字体字形 —— 换字体别选 Mono 变体
**事实**：`omarchy.microphone` / `omarchy.bluetooth` / `omarchy.network` / `omarchy.audio` / `omarchy.monitor` 以及 `jianlongliu.indicators` 里的图标**不是 SVG**，是 Nerd Font 的 MDI 字形（私用区 U+F0001–U+F1AF0），走 `Style.fontFamily = "monospace"`（`/usr/share/omarchy/shell/Commons/Style.qml:270`）。`omarchy font set` 改的就是这个 monospace 别名（写 `~/.config/fontconfig/fonts.conf`）。字体链见 §八。

**坑**：`omarchy font list` 里带 **`Mono` 后缀**的变体为保等宽，把每个图标**等比压进同一窄格** → 长宽比不同的图标墨迹高矮从 11px 到 22px 不等，右侧一排看着「有大有小」；tray / mihomo / 截图等 SVG 图标不受影响，对比之下更刺眼。

**规则**：`omarchy font set "X Nerd Font"` —— **不带 `Mono` 后缀**。

| 同一字形墨迹宽×高（24pt） | Mono 变体 | 非 Mono 变体 |
|---|---|---|
| 麦克风 󰍬 | 15×20 | 15×20 |
| 显示器 󰍹 | **15×14** | 23×21 |
| Wi-Fi 󰖂 | **15×11** | 23×16 |
| 音量 󰕾 | 15×15 | 18×18 |

**不会撑歪终端**：两变体的 ASCII 单元格与图标步进都是 14（24pt），8 个图标连写宽度 = 8 个 `M` = 117px，只有墨迹大小不同。

- **生效**：字体在 shell **启动时**解析 → 改完必须 `omarchy restart shell`。
- **验证**：`omarchy font current`、`fc-match monospace`。
- **复发排查**：`omarchy theme set` 或重跑 `omarchy font set` 会重写 `fonts.conf`；图标又不齐就先看是不是被换回 Mono 了。

**换成 Material Symbols（已落地，走「替身字体」）**：

改的**不是插件，是字体**——把底字体 `GoogleSansCodeNerdFont-Regular.ttf` 里的 140 个私用区字形就地替换成 Material 轮廓，再把 `monospace` 别名指过去。一行 fontconfig → bar / 菜单 / 所有走该别名的面（含第三方插件图标）一次性生效；终端不受影响（字体名写死在 ghostty/alacritty 配置里）。

| 项 | 值 |
|---|---|
| 字体 | `~/.local/share/fonts/GoogleSansCodeMaterial-Regular.ttf`（族名 `GoogleSansCode Material`） |
| 别名 | `~/.config/fontconfig/fonts.conf` 的 `prepend_first` 一行 |
| 换掉 | 140 个（映射表见 `tmp-material-bar-icons/nerd_to_material.py`） |
| 保留 Nerd | 17 个品牌图标（apple / google / discord / arch / docker … Material 无对应 logo） |
| 效果 | ASCII 逐像素不变，只有图标字形变；尺寸中位 1.15× |

- **⚠️ 观感预期**：**bar 上几乎看不出变化**——只有 4 个图标走字体（蓝牙 0.84 / 音量 0.85 新旧几乎一样，wifi 0.50 / 显示器 0.60），且只有 24 物理 px。菜单换了 39%（174 个码位里 68 个），但菜单是弹一下就走的面板。**这次迁移的价值是血统统一 / 可维护性，不是换脸**；真正解决「图标有大有小」的是换成**非 Mono 变体**那一步，跟 Material 无关。
- **为什么看着差不多**：Nerd 的 `md-*` 就是 Material Design Icons，Material Symbols 是它的后继，同源设计 → 大部分图标几乎一样。全量 140 个的 IoU 中位 0.53，但要看出差别得逐个放大比。
- **坑**：① `getBestCmap()` 改了不写回，必须遍历 `font["cmap"].tables` 改 `table.cmap[cp]`；② 多个 Nerd 名共用一个 Material 名（`image`/`image_move`）会互相覆盖，字形名要带码位；③ 尺寸参照用**原字形包围盒**，不能用单元格宽（Nerd 字形本就溢出）。
- 完整流程 / 量化方法 / 回退见 `tmp-material-bar-icons/README.md`（**临时稿**，用户暂定不并入本文）。

> 早期「克隆 4 个面板 + 覆盖 `fontFamily` + 连字名」的路线已废弃（改动仍在 `~/.config/omarchy/plugins/jianlongliu.{bluetooth,network,audio,monitor}`，但 shell.json 已切回出厂 `omarchy.*`、克隆全部 disable，可直接 remove）。

**其它两路为什么不走**：
- `omarchy font list` 只列 `spacing=100` 等宽字体（`/usr/share/omarchy/bin/omarchy-font-list`），比例图标字体进不了菜单，`omarchy font set` 也切不过去。
- 直接填 Material 码位不行：Material 在 BMP 私用区（`bluetooth`=U+E1A7 / `wifi`=U+E63E / `mic`=U+E31D，共 4284 个），而 GoogleSansCode NF 自己在 U+E63E / U+E3AB / U+E31D / U+EC08 有字形 → 会画出怪东西。替身字体法按**码位**替换所以不受此限，但换完别再用连字名。
- `omarchy font set` 会重写 `fonts.conf`，把上面那行别名覆盖掉，需重设。

---

### 1.4 桌面图标主题（MacTahoe）与 Arc Dock 图标锯齿
> 最后核对：2026-09-16 · Omarchy 4.0.4

**现状**：`gsettings get org.gnome.desktop.interface icon-theme` = **`MacTahoe`**（用户级 `~/.local/share/icons/MacTahoe{,-light,-dark}`，只服务 **Arc Dock + Nautilus**）。

**为什么一条 gsettings 能同时管两者**：

| 使用方 | 取图路径 |
|---|---|
| Nautilus（GTK4） | 直接读 `org.gnome.desktop.interface icon-theme` |
| Arc Dock（`io.github.claudsondouglas.arcdock`） | `Quickshell.iconPath()` → Qt 图标查找 → 本机 `QT_QPA_PLATFORMTHEME=gtk3` → 同一个 GTK 设置 |

**图标主题会被「套主题」重置 —— 真源是主题自己的 `icons.theme`**：`omarchy-theme-set` 先把主题目录 `cp -r` 进 `~/.local/state/omarchy/current/theme/`，再跑 `omarchy-theme-set-gnome`，**后者读那份 state 副本的 `icons.theme` 覆盖 gsettings**（该文件不存在才回落 `Yaru-blue`）。所以要让改动持久，改的是 `~/.config/omarchy/themes/<主题>/icons.theme`（本机 `tonal-spot` / `expressive` 均已写 `MacTahoe`，state 副本同步）；`materal-update` 只重写 `colors.toml`，**不碰** `icons.theme`。**残余风险**：切到库存主题（`/usr/share/omarchy/themes/*`，各自写死 `Yaru-*` 且只读）仍会被换掉，要彻底锁死只能加 `~/.config/omarchy/hooks/theme-set.d/` hook（hook 在 `omarchy-theme-set-gnome` **之后**执行，顺序正好）。

**三套变体别指望**：app 图标在三套里是**同一份文件**（`zen-browser.svg` md5 三套一致），差异只在 places/UI 图标（文件数 27981 / 3737 / 14260）→ 把 `icon-theme` 换成 `MacTahoe-light` 后 dock 截图 **RMSE = 0**（逐像素一致），已切回 `MacTahoe`。

**dock 出现「首字母方块」**（例：自建 `~/.local/share/applications/colamd.desktop`，`Icon=colamd`）：dock 的图标查找**只认当前激活主题**——`hicolor` 虽然写在主题 `Inherits` 链里，实际不被走。
**解法**：把图标复制进 `~/.local/share/icons/<当前主题>/apps/scalable/`（该目录已声明 `Type=Scalable / MinSize=16 / MaxSize=512`，放 PNG 也能正常缩放）→ `gtk-update-icon-cache -f -t <主题>` → `omarchy restart shell`。**重装图标主题会丢，需重 cp**。

本机手动塞过 / 换过的图标（都在各主题的 `apps/scalable/`）：

| 图标名 | 处理 | 原因 |
|---|---|---|
| `omarchy.svg` | 覆盖成白色 Arch A | dock 右端启动按钮（细节见 §4.1） |
| `colamd.png` | 新增 | 自建 desktop 条目（`Icon=colamd`）在 hicolor 里有图但 dock 查不到 |
| `qq.png` | 换官方彩色企鹅，**移除同目录 `qq.svg`** | MacTahoe 的 `qq.svg` 是「企鹅画在**近白圆角板**上」= macOS 原版：实测该区域 **29.8% 像素 ≥240**（同尺寸 VS Code 0%、Zen 6%）→ 深色 dock 上看着"过曝"；换后 **11.2%**、区均值 168 → 94.5 |

> **判"某枚图标过曝"的方法**：量该图标区域里灰度 **≥240** 的像素占比（`grim` 抓 dock → `magick … -crop … -colorspace Gray -depth 8 gray:-` → 计数）。占比远高于旁边图标 = **图标自身底板就是亮的**，不是渲染问题，换掉那枚图标即可。原 `qq.svg` 备份在 `~/.local/share/mactahoe-icon-overrides-backup/`。

**dock 图标锯齿（细白线图标最明显，如 Zen 的同心环）**：图标取图尺寸 = `显示尺寸 × magnifyScale × DPR`。本机 `~/.config/omarchy/arc-dock.json` 的 `magnifyScale = 200` → 取 **166px** 却只显示在 **83px** 上 = **2 倍缩小**，双线性缩小把 SVG 的抗锯齿丢掉了。
**修法**：`plugins/io.github.claudsondouglas.arcdock/ArcSlot.qml` 里图标 `Image`（约 388 行）加 **`mipmap: true`** —— 本地补丁，见 `omarchy-plugins.md` §8.1。⚠️ 只在 ≥2 倍缩小（`magnifyScale > 150`）时才生效，≤150 时等于没加。

**过曝嫌疑（非渲染）**：`glassOpacity` 只有 20%（Background 段可调）时玻璃极透，背后亮内容会把整条 dock 洗白；作者的官方预览是在**空工作区 + 深色壁纸**上抓的（`docs/preview.sh`，会临时开 `printMode`、切空工作区、抓完自动还原；注意它是按**逻辑坐标**抓 → 本机 1200x500 会得到 1920x800）。

**验证法**：
```bash
gsettings get org.gnome.desktop.interface icon-theme      # 期望 MacTahoe
hyprctl layers -j | jq -r '..|objects|select(.namespace?=="arc-dock")|"\(.x),\(.y) \(.w)x\(.h)"'
grim -g "<上面那串>" /tmp/dock.png
magick /tmp/dock.png -crop 88x88+X+Y +repage -filter point -resize 500% /tmp/dock-5x.png   # 5 倍点放大看台阶
```
**AA 量化（别靠肉眼）**：环区中间灰像素（100<v≤200）计数，`mipmap` 前 **752** → 后 **936**（+24%），白像素 767 → 728。


## 二、克隆插件实例

### 2.1 纯克隆总纲（keyboard-layout / system-update）
两个**纯克隆自内建、AI 重写注释、行为与原版一致**，非官方首层插件。manifest 标 `"clonedFrom": "omarchy.X"`；QML 里 `moduleName` **仍保留 `omarchy.*`**（未改 `jianlongliu.*`）。> **⚠️ 上游位置（2026-09-10 核实）**：这两个 + `workspaces/indicators` 的上游在 **`omarchy.bar` 的内建 widget**（`/usr/share/omarchy/shell/plugins/bar/widgets/{KeyboardLayout,SystemUpdate,Workspaces,Indicators}.qml`），不是 plugins 首层目录。4.0.1→4.0.3 均如此。

- **jianlongliu.keyboard-layout**（My Keyboard layout，bar-widget）：显示当前 xkb 布局、点击循环切换；多布局才显示。布局切换用 `hyprctl switchxkblayout <kbd> next`（命令非 dispatcher）；`xkbcli list --load-exotic` 生成短语言码；多 seat 的 `selectKeyboard`/`stallTimer`(5s)/10s 轮询。
- **jianlongliu.system-update**（My Omarchy update，bar-widget）：指示有可用更新、点击跑更新。`omarchy-update-available` exitCode===0 显示图标；6h 定时；点击 → `omarchy-launch-floating-terminal-with-presentation omarchy-update`。

**回退**：`omarchy plugin disable jianlongliu.<id> && enable omarchy.<id>`。

### 2.2 OSD 卡片化克隆（jianlongliu.osd）——绕开全屏 surface 的 ignore_alpha 失效
**根因**：出厂 `omarchy.osd`（音量/亮度浮层）PanelWindow 铺满整屏 + 半透明卡片(alpha 0.97)。现行 Hyprland 对**全屏透明 layer 的 `ignore_alpha` 失效**：加→不磨砂，去→全屏糊。所以 OSD surface 不能横跨整屏，要改**卡片大小 surface**。

**改动**（`clone omarchy.osd` → `jianlongliu.osd`；diff 自 `/usr/share/omarchy/shell/plugins/osd/`）：
- manifest：`id→jianlongliu.osd`、`name→"My On-screen display"`、加 `"omarchy": {"clonedFrom":"omarchy.osd"}`。
- `Osd.qml` PanelWindow（全屏→卡片小 surface）：
```qml
PanelWindow {
  visible: root.opened
  anchors { left: true; right: true; bottom: true }
  implicitHeight: card.borderTop + root.pad + Style.font.displayLarge + root.pad + card.borderBottom
  margins { bottom: Style.space(67)
    left: (Quickshell.screens[0].width - (card.borderLeft + root.pad + root.contentWidth + root.pad + card.borderRight)) / 2
    right: 同 left }               // 对称 margin 水平居中
  color: "transparent"
  WlrLayershell.namespace: "omarchy-osd"; WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None; exclusionMode: ExclusionMode.Ignore
  mask: Region {}                  // input 区域留空，不挡点击桌面
  BorderSurface {
    id: card
    anchors.fill: parent
    color: Util.alpha(Color.background, 0.65)   // 半透明→底层 blur 透出
    borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
    radius: Style.cornerRadius
  }
}
```
**要点**：surface 只占卡片大小、贴底 bottom=67、`mask: Region{}` 不挡鼠标；其余逻辑未改。相关 blur 见 §3.3。

**回退**：`omarchy plugin disable jianlongliu.osd && enable omarchy.osd`（回官方全屏版→全屏糊 bug）；或 `omarchy refresh config`。

> **⚠️ 复发排查（2026-09-07 亲历）**：某次 update/refresh/theme 重置 shell.json 会把克隆踢掉——`jianlongliu.osd` 变 `disabled`、出厂 `omarchy.osd` 顶上跑全屏，OSD 又没磨砂。**快速自检**：`omarchy plugin list | grep osd`，看到 `jianlongliu.osd disabled` + `omarchy.osd enabled` 即此因。**修法**：`omarchy plugin enable jianlongliu.osd`（克隆自动 `addDisabled(omarchy.osd)`），`omarchy restart shell` 后验证 surface 变卡片（`hyprctl layers -j` 里 `omarchy-osd` 约 324×75 贴底，非 2400×1350 全屏）。克隆机制：非 first-party 的 `jianlongliu.*` 必须进 shell.json `plugins` 才启用（PluginRegistry.isEnabled 第 136-138 行），启用克隆时自动禁用源。**如果重置的是整个 shell.json（bar 布局一起没了，不只 OSD）→ 别一个个 enable，直接按 `omarchy-plugins.md` §8.3 从 `shell.json.bak.*` 整份捞回来。**

---

## 三、视觉效果

### 3.0 视觉参数：真源与共享（改视觉前先读）
**准则**：一类值只留**一个真源**，其余由它派生；发现第二份硬编码就合并，别各自维护。

**omarchy 原生就能共享的（能派生就别手写）**

| 机制 | 覆盖 | 出处 |
|---|---|---|
| Hyprland 运行时值回拉 | `cornerRadius` ← `decoration:rounding`；`gapsOut` ← `general:gaps_out` 的一半 | `Commons/Style.qml:11-17`（启动/主题应用时 `hyprctl getoption`） |
| 颜色 `段.键` 引用 | 主题发 `[hyprland] active-border*`，各段写 `border = "hyprland.active-border-foreground"` 即可引用 | `Commons/Border.qml:37 resolveValueRef()` |
| 段内键回退链 | `[controls]` 的 hover/focus ← normal；字号由 `[font] base-size` 乘系数派生 | `Commons/Style.qml:54-92` |
| 主题模板 `{{ }}` | colors.toml 里任意 key（含 matugen 派生色如 `lighter_background`） | `themed/shell.toml.tpl` |

**原生盖不到、必须手工同步的（共 3 处，改一处就要顾另一处）**

| 参数 | 为什么原生不行 | 现况 |
|---|---|---|
| 各 surface `background-alpha` | `Color.qml:35 pickAlpha()` 只吃字面数字，读到 `段.键` 会 `Number()` 失败并回落 1.0——引用机制只给颜色用 | 6 处：bar 0.5 / popups 0.58 / notifications 0.6 / menu 0.65 / launcher 0.6 / tooltip 0.8 |
| `[popups]`、`[menu]` 的 `border-width` | `Border.qml:111 valueOr()` 只做段内回退（`border-width-top` → `border-width`），不跨段继承 | 与窗口 `general:border_size`（4）同值、手写复制 |
| `looknfeel.lua` 的 blur/rounding | hypr 侧配置，与 shell.toml 两套体系，原生不互通 | 单文件单块 → 本身已是单源 |

**改一处时的同步清单**

- **圆角 / 窗口边框宽**：只改 Hyprland（`decoration:rounding` / `general:border_size`）。浮栏环宽自己 probe、面板圆角由 `Style.cornerRadius` 镜像 —— 都自动跟。但 `shell.toml` 里那两处 `border-width` 不会跟，要一并改（或干脆删掉让默认值接管）。
- **玻璃透明度**：6 个 alpha 相互独立，**只能逐个改**，改完 `omarchy restart shell`（`[menu]` 段是共享的：clipboard / emojis / reminders 一起变）。
- **模糊强度 / 开关**：只改 `looknfeel.lua` 基础块 + `hyprctl reload`。
- **主题色、边框色**：不用改任何东西（matugen 派生）。

### 3.1 工作区指示器：GNOME 胶囊（jianlongliu.workspaces）
**目标**：嵌在顶栏内的纯圆点胶囊——当前轻微拉长、其余小圆点，无数字/无边框/无厚重背景。同色**单前景**，靠 alpha 明暗分级（不搞多彩，用户嫌花哨）。
```
▬▬  ●  ●  ●  ●     ·空：前景 @15%（最淡，还没开窗口）
↑当前                ●占用：前景 @62%（有窗口更实）
                    ▬▬当前：同高、宽 2.6×，前景 @90%；悬停纯 @100%
```
**禁止**：数字/空心圆/大按钮感/高饱和色（尤其纯蓝）/厚重背景。**载体**：`clone omarchy.workspaces`；`disable omarchy.workspaces` 避免双排。

**核心**：`dot=max(7, round(barSize*0.28))`、`expanded=dot*2.6`、`spacing=dot*0.5`；本机 barSize=47 → **dot≈13px**、spacing≈6.5px。**`implicitHeight=barSize` 撑满**否则顶部对齐偏上；`Row anchors.verticalCenter` 垂直居中。
**四档状态**（`Workspaces.qml` `col`，全走 `bar.barForeground` 的 alpha）：
- **空点** `@0.15` · **有窗口** `@0.62` · **当前胶囊** `@0.9` · **悬停**（任一非当前点）`@0.85`、当前胶囊悬停 `@1.0`。
- 占用判定：`root.workspaceById(id).toplevels.values.length > 0`（官方同款写法，`length>0` 即占用）。
- hover：`MouseArea { hoverEnabled:true }` → `hoverArea.hovered` 点亮，无 hover 时点击纯静默。
- **动画**：宽 `Behavior NumberAnimation 220ms Easing.OutBack overshoot:1.2`（胶囊展开轻微过冲回弹、收起平滑）；色 `ColorAnimation 160ms InOutCubic`。
- 点击：`MouseArea` 单击 `focusWorkspace(id)`（`hyprctl dispatch hl.dsp.focus`，`Util.shellQuote` 包裹）。

**踩过的坑**：①必须撑满 bar 高才垂直居中 ②尺寸 0.14 太细/0.48 太大/**0.28 最终** ③用前景 alpha 别用 `Color.accent`（会蓝/彩） ④无数字无外框 ⑤点击静默无 hover 放大 ⑥**槽位别用固定填充**（见下「槽位规则」） ⑦**尾部留白要动态补**（见下「间距规则」）。
**过冲回弹体感 ≈ 0**：13px 点 + 220ms 里那点 OutBack 过冲，肉眼几乎感知不到——同形态的视觉/动画天花板很低。**要更明显的"活"须换形态**（如悬停浮卡），不在点里继续调。
**GNOME 标准已回退**：GNOME 未选中缩放 0.75×、当前满尺寸 → 大小不一破坏统一，仅借用紧凑点距(`dot*0.5`≈6.5 逻辑px；GNOME 固定 5px 不随 bar 缩放)。

**调参表**：圆点 `dot`(0.28×，下限 7px) · 拉长 `expanded`(2.6×) · 间距 `spacing`(0.5×) · 空 `@0.15` · 占用 `@0.62` · 当前 `@0.9`(悬停`@1.0`) · 非当前悬停 `@0.85` · 宽动画 OutBack 220ms(over 1.2) · 色动画 160ms · 尾部留白 `Style.space(8)`≈9px（仅无标题时）。

#### 槽位规则：`workspaceIds()` 决定"画几个点"

| 情况 | 上屏？ |
|---|---|
| 有窗口的工作区 | ✅ 占用色 |
| 当前工作区（哪怕它是空的） | ✅ 胶囊 |
| 空工作区（Hyprland 不会自动回收，会留下残留） | ❌ **不上屏**，否则中间挂一串暗点 |
| 列表末尾 | 补 **1 个空槽**代表"下一个工作区"，点击即新建 |

- **别再用固定填充数组**：上游 `omarchy.workspaces` 写死 `[1,2,3,4,5]`，克隆初期是 `[1,2,3]` → 只开 ws1+ws6 时会渲染成 `1,2,3,6`，中间 2、3 是**凭空冒出来的暗点**。这就是"多开工作区就出 bug / 中间有空白工作区"的根因。
- 空槽只在**末尾**补（仅当末位有窗口时补 `last+1`），所以中间永远不会留空。
- `id<=10` 的截断已去掉，超过 10 个工作区也不会漏点。

#### 间距规则：与右侧窗口名字之间的空隙

bar 的模块列表是 **`Row { spacing: 0 }`**（浮栏 `charlieras262.floating-bar/Bar.qml:1666`、`1684`；内建 `Bar.qml` 同款）→ **widget 之间的空隙全靠各自的内边距**。胶囊右边紧挨着 `omarchy.active-window`，它自己带 `Style.space(8)` 左边距，**但它切到空白工作区时会整块隐藏、宽度归零**：

| active-window 状态 | 胶囊尾部留白 |
|---|---|
| 有窗口标题 | `0`（对方已自带左边距，不必重复） |
| 空白工作区（宽度归零） | `Style.space(8)` ≈ **9px** |

- 判定用 `ToplevelManager.activeToplevel` **复刻 active-window 的 `visible` 条件**（`title \|\| appId` 非空），两边必须一致否则会不同步。
- 症状复现：切到空白工作区后 ai-subs 直接贴上胶囊（实测起点 x 由 398 → 94）= 用户报的「窗口名字没了 + ai sub 间隔窄」——**是同一个原因，不是两个 bug**。
- ⚠️ 该判定依赖 active-window **仍然在 bar 布局里**；哪天把它从 bar 上拖走，有标题时也会贴住。

**验证**：`omarchy restart shell` 后截图核对——`grim -o "$(hyprctl monitors -j | python3 -c 'import sys,json;print(json.load(sys.stdin)[0]["name"])')" /tmp/bar.png` 再裁 bar 左放大。日志确认：`journalctl --user -n 30 | grep jianlongliu.workspaces` 应见 `Local plugin changed, reloading: jianlongliu.workspaces`，无 QML 报错。
> **下一步候选（未做）**：悬停浮卡 = 每个 ws 点 hover 弹 `PopupCard` 显示该 ws 窗口**几何线框**+标题。已探明**中低工作量、单文件**——复用 `/usr/share/omarchy/shell/Ui/PopupCard.qml`(`triggerMode:"hover"`，锚定自动避边，范本见 `services/media/BarWidget.qml:104`)，窗口数据走 `toplevels.values` 遍历 + `hyprctl clients -j`(含 address/class/title/geometry)，按 `hidden` 过滤。真像素缩略图才是中高工作量(需 portal 抓帧)，先不做。做前先 `cp Workspaces.qml` 备份。

**回退**：`disable jianlongliu.workspaces && enable omarchy.workspaces`；QML 备份 `Workspaces.qml.bak.*`。
> 与 `omarchy-nirification.md` 互补不冲突：那个管切换交互（ScrollOverview），这个管 bar 上指示器外观。

### 3.2 悬浮栏：圆角暗角修复
> 本机 bar 是第三方 `charlieras262.floating-bar`，**git clone 目录，`omarchy update` 不覆盖**，靠 `omarchy plugin update charlieras262.floating-bar` 更新（走 omarchy 通道）。⚠️ 每次更新后 blur/暗角可能变化——上游 1.4.0 起 bar 表面改读 `Style.shellOpacity`（且先把背景 alpha 强制成 1），而该 token 已随 Omablur 一起废弃 → **本机已打补丁改回吃主题 `[bar] background-alpha`**（2026-09-16，见 §3.3 现状）。**4.0.3（2026-09-10）**：浮栏已是最新上游（`5e7dc23`）；内置 Bar.qml 新增 `PluginBarApi` + `fallbackBarWidgetRegistry` 兼容第三方完整 bar，**无需等浮栏适配**。

**① 圆角暗角（已修复，保留）**：悬浮栏四角有暗色模糊残影。根因：bar 的 layer-surface 是完整矩形、QML 用 radius 裁角使四角全透明，但 blur 规则**没带 `ignore_alpha`** → Hyprland 对整块矩形（含透明角）blur，透明角仍糊背景。修复（`omarchy-shell.lua` 第 7 行）：
> ⚠️ **五彩琉璃外描边**（2026-09-09，颜色/宽度均镜映窗口，与 matugen 一体）见 **§7.2**；勿在 bar 里写死边框色。暗角修复本身继续保留。

```lua
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, blur_popups = true, ignore_alpha = 0.1 })
```
`ignore_alpha` 必须 **< bar 背景 alpha(0.5)**，取 0.1；别用 0.5。角仍微暗调 0.15~0.25。验证：`hyprctl reload` 后 `hyprctl configerrors` 空。

**② 阴影立体感（做不了，已放弃）**：layer-surface 高度定死 40px，"透明窗口内缩 + 阴影"必然破坏 `Bar.qml` 布局；浮栏上无可行解，勿再试。
> `Bar.qml` 改动前都 `.bak.时间戳` 备份于插件目录；恢复用最新 `.bak.*` 覆盖再 `omarchy restart shell`。`omarchy-shell.lua` 的 `ignore_alpha=0.1` **保留有效，勿回滚**。

**③ widget 间水平间距（2026-09-06）**：bar 各 section 把 widget 摆进 `Row { spacing: 0 }`——**间距硬编码 0、不读任何配置**，浮 bar 与原生皆然（详见「机制不足」注）。中心锚前 indicators↔CPU 太挤时，用纯配置 spacer 兜底，update 免疫：
- 在 `shell.json` `bar.layout.center` 数组、两 widget 之间插 `{"id":"omarchy.spacer","size":16}`（`size`=px，默认 12，见 `/usr/share/omarchy/shell/plugins/bar/widgets/Spacer.qml`），改完 `omarchy restart shell`。想留 0 宽占位填 0。
- **这是 per-位置 手动方案**，不是全局统一间距。
- 若想**在插件里自己控制**尾部留白（动态、条件式），见 §3.1「间距规则」——工作区胶囊就是那么做的，可作为范式。

### 3.3 磨砂玻璃（Liquid Glass）恢复手册
> 状态栏/菜单/通知/OSD 所有表面的磨砂 = **三层叠加，全部无需 root**：① 全局 `decoration:blur`（`~/.config/hypr/looknfeel.lua`）② 每个 shell 层的 `layer_rule`（`~/.config/hypr/apps/omarchy-shell.lua`，按命名空间开 blur + 用 `ignore_alpha` 阈值只糊卡片）③ 表面自身的 alpha（用户级 `~/.config/omarchy/shell.toml` 的 `background-alpha`）。被 `omarchy update` / `omarchy refresh hyprland` 覆盖则按此恢复。

> **现状（4.0.4 起）**：本机不使用 Omablur → `Style.shellOpacity`（blur 开时把 shell 统一压到 0.62）整体作废：没有任何 surface 读它，配套 4 行系统文件 patch 不再需要，也不再存在"升级后被静默还原"。各层半透明**只由 `shell.toml` 的 `background-alpha` 决定**（同步注意项见 §3.0）。
>
> **浮栏是唯一例外（必须本地补丁）**：`charlieras262.floating-bar/Bar.qml` 上游把背景 alpha 强制成 1、再乘 `Style.shellOpacity`；token 缺失时回落 1 → **bar 会变实心**。已改成 `color: root.background`（直接用主题 `[bar] background-alpha`）+ `opacity: 1`。补丁清单见 `omarchy-plugins.md` §8.1。
>
> **历史（已废弃，仅存档）**：`shellOpacity` 4 文件 root patch（`Style.qml` / `KeyboardPanel.qml` / `NotificationCard.qml` / `Menu.qml`）与"升级必复补"流程全文 → `archive/omablur-shellopacity-patch.md`。**上游为何不修**：作者 2026-08-28 删掉自动 patch 脚本（`bf8b25d`，理由 = 用 root 写一份用户可写的 git 检出，等于提权通道），仓库 0 issue；omarchy 上游（仓库已改名 `omacom/omarchy`，默认分支 `quattro`）至今没有这个 token。

**① 落点：`~/.config/hypr/apps/omarchy-shell.lua`**（由 `hyprland.lua` `require` 加载，**不是 hyprland.lua 本体**——实测 `layer_rule` 只出现在该文件）。追加：
```lua
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, blur_popups = true })
hl.layer_rule({ match = { namespace = "^(omarchy-menu|omarchy-image-selector|omarchy-emojis|omarchy-clipboard|omarchy-keyboard-panel)$" }, blur = true, blur_popups = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "^(omarchy-notifications|omarchy-osd)$" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "omarchy-workspace-overview" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "omarchy-polkit" }, blur = true, ignore_alpha = 0.75 })
hl.layer_rule({ match = { namespace = "omarchy-reminders" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "omarchy-lock-preview" }, blur = true })
o.window("org.gnome.Nautilus", { opacity = "0.88 0.82" })
o.window("org.gnome.Loupe", { opacity = "0.88 0.82" })
```
**② `looknfeel.lua` decoration.blur**：**现在只有一个基础块**（原 Omablur 标记块 2026-09-16 已删、值折了进来）：`rounding=20`、`size=11`、`passes=2`、`xray=false`、`new_optimizations=true`、`ignore_opacity=true`、`vibrancy=0.5`、`brightness=1.05`、`contrast=0.95`、`input_methods=true`。**运行时生效值 = 11 / 2**（`hyprctl getoption decoration:blur:size` 实测）。调参直接改这个块 + `hyprctl reload`。
> **⚠️ xray 已全局关闭（2026-09-10）**：`xray = true` → `false`。原因：xray 开启时模糊只取壁纸、忽略背后窗口，Spotlight 命令面板关闭淡出（Hyprland `layersOut` fade）时会露出"只糊壁纸"的 X 光残影。关掉后所有层/窗口的模糊都取背后真实内容（含窗口），更接近真玻璃。性能代价（xray 省的是浮动模糊开销）在 6950 XT 上可忽略。**Omablur 已卸载（2026-09-16），现在没有任何东西会回写这个值**。回退：`looknfeel.lua.bak.<时间戳>`。
**③ `shell.toml`**：`[bar] background-alpha 0.5`·`[popups] 0.58`·`[launcher] 0.6+scrim 0.4`·`[notifications] **0.6**`·`[tooltip] 0.8`·**`[menu] 0.65`**（卡片色走用户模板取 `lighter_background`、scrim 0；2026-09-16 由 0.9 降到 0.65 与同族对齐，见 §3.4）。
**④ OSD**：`jianlongliu.osd`（§2.2 卡片小 surface，blur 只盖卡片，不需 ignore_alpha）。

**⑤ 新增 shell 层规则（2026-09-10）**：Spotlight 命令面板（`io.github.maajix.spotlight`，overlay，命名空间 `omarchy-spotlight`）。实际写在 `~/.config/hypr/apps/omarchy-shell.lua`（由 `hyprland.lua` `require` 加载）：
```lua
hl.layer_rule({ match = { namespace = "omarchy-spotlight" }, blur = true, ignore_alpha = 0.4 })
```
> 卡片 `glassBackground` alpha≈0.62、scrim≈0.25，取 `ignore_alpha=0.4` 让 scrim 不糊、只糊卡片。是否加 `xray`/`no_anim` 视视觉而定；目前靠全局 `xray=false` 消除关闭残影。

**⑥ Arc Dock 设置面板（2026-09-16）**：dock 插件（`io.github.claudsondouglas.arcdock`）**自己向 Hyprland 注册 dock 本体的 blur**（运行时 `eval hl.layer_rule(...)`，命名空间写成 `^(arc-dock)$`——带锚点是**故意避开**同插件的设置面板 `arc-dock-settings`，作者的理由是"文字卡片不该糊"）。结果：设置面板是半透明却没磨砂，背后终端/窗口文字透上来看不清。补一条静态规则即可：
```lua
hl.layer_rule({ match = { namespace = "^arc-dock-settings$" }, blur = true, ignore_alpha = 0.3 })
```
> 面板形状 = 全屏透明 surface + 一张居中卡片（卡片色 `Color.popups.background`，alpha = `shell.toml` `[popups] background-alpha` 0.58）→ `ignore_alpha` 取 **0.3**（低于卡片 alpha、高于透明区，同 §3.2 的算法）。**dock 本体不要再加规则**（插件自己管，加了会打架）。验证：`omarchy-shell shell toggle io.github.claudsondouglas.arcdock '{}'` 打开面板截图对比。

**⑦ Arc Dock 右键菜单（2026-09-16）**：右键菜单是 dock 本体那层 surface（`arc-dock`）的 **XDG popup**，而插件自注册的规则**故意不带 `blur_popups`**（`Arcdock.qml:514` 注释：菜单"按设计不透明"，糊了也看不见）。但菜单卡片读 `Color.popups.background` —— 即 `shell.toml` `[popups] background-alpha` 0.58 → 实际半透明、**无磨砂**。补一条**只写 `blur_popups`** 的静态规则：
```lua
hl.layer_rule({ match = { namespace = "^arc-dock$" }, blur_popups = true })
```
> **同命名空间两条规则是按属性合并的**（未设字段不覆盖）：库存 `omarchy-shell.lua` 有一条 `omarchy-bar` 的 `no_anim` 规则，与用户那条 `blur/blur_popups/ignore_alpha` 长期共存且都生效。
> **所以这里只写 `blur_popups`**——`blur` / `ignore_alpha` 由插件运行时代管（`Arcdock.qml:504`：`glassIgnoreAlpha = 10/100/2 = 0.05`），在这里再写会顶掉插件"玻璃"开关与不透明度滑块的联动。
> 菜单卡片 alpha 0.58 > 0.05 → 磨砂生效。验证：右键 dock 开菜单截图（卡片区应有磨砂）；`hyprctl configerrors` 须空。

**原理**：
- Hyprland 对 layer 表面**默认不模糊**，须每层显式 `blur=true`（全局 decoration.blur.enabled 对 layer 无效）。
- XDG 窗口走全局 blur 自动对透明区模糊；但 Omarchy 给所有窗口打 `default-opacity` 标签(0.985)→看不出 blur，给 nautilus/loupe 单独降 opacity(0.88 0.82) 即透出（注册在 default/hypr/windows.lua 之后故覆盖）。
- **全屏 surface 陷阱**：菜单/通知等层都是全屏 surface，直接 `blur=true` 会整屏糊，须配 `ignore_alpha` 只模糊 alpha>阈值 区域。
- `ignore_alpha` 取值：透明底+卡片 0.5（卡片须>0.5）；scrim+卡片取两者间（polkit scrim0.5/卡1.0→0.75）。
- `omarchy-network-qr` 故意不加 blur；`omarchy-lock-preview` 保留全屏 blur；`omarchy-background` 壁纸层不碰。
- **⚠️ ignore_alpha 在 OSD 已失效(2026-08-19)**：对策=卡片小 surface（§2.2）；菜单/通知复现"全屏糊/完全不糊"先疑同因；notifications 现靠 0.5 正常先不动。
- **shell 自身（bar/弹窗/通知/菜单）的透明度**：**已无统一 token**（`Style.shellOpacity` 随 Omablur 一起废弃，2026-09-16）——各层按自己在 `shell.toml` 的 `background-alpha` 走：bar 0.5、popups 0.58、notifications 0.6、menu 0.9（刻意更实，见 §3.4）。想统一就把这几个值调齐；不再需要任何系统文件 patch。

**各层 alpha 备忘**：
| layer | 结构 | 卡片 alpha | scrim | ignore_alpha |
|---|---|---|---|---|
| bar | 条 | 0.5 | 无 | 无(整条糊) |
| menu/image-selector/emojis/clipboard/keyboard-panel | 全屏+卡 | 0.6→**menu 已改 0.65**（2026-09-16，原 0.9） | 0.4→**menu 已改 0** | 0.5 |
| notifications | 全屏+卡 | **0.6**（用户层，实测 0.6） | 无 | 0.5 |
| osd | **卡片小 surface** | 0.65 | 无 | 不需要 |
| polkit | 全屏+卡 | 1.0 | 0.5 | 0.75 |
| reminders | 全屏+卡 | 0.6 | 0.4 | 0.5 |
| spotlight | 全屏 scrim+卡 | 0.62 | 0.25 | 0.4 |
| workspace-overview | 全屏+半透明底 | 0.82 | 无 | 0.5 |
| lock-preview | 全屏锁屏 | 不透明 | — | 无 |

> **菜单 alpha = 0.65**（与 bar 0.5 / popups 0.58 / notifications 0.6 / launcher 0.6 同档；原 0.9 的起因见 §3.4）。**仍 > 菜单层 `ignore_alpha` 0.5，磨砂不受影响**；`[menu]` 是共享段 → clipboard / emojis / reminders 卡片一起变。

> **实测（换帧回归法）**：Display 面板 **0.584**（= 配置 0.58）；菜单在 alpha 还是 0.9 时量到 ≈0.95。⚠️ 该法只在**背景静态**时可信——背后有视频/动画（bilibili 那类）时比差会被动态内容污染，数值直接失真（实测出现过 slope 为负的垃圾值），此时只信配置值或改用 A/B 法。

**约束公式**：`卡片 alpha > ignore_alpha > scrim alpha`（polkit 1.0>0.75>0.5）。`scrim alpha` **可为 0**（=不压暗整屏，见 §3.4）；卡片降到 ≤ ignore_alpha → 失磨砂，需同步调低 hyprland.lua。

**调参**：壁纸更明显降 `background-alpha`；更顺滑 `passes` 6~8；更鲜艳 vibrancy 0.5~0.7。**别调 `brightness`**——实测 0.6→2.0 无感（§3.4）。

**被覆盖信号**：磨砂消失/bar 实心→layer_rule 丢；nautilus 实心→o.window opacity 丢；菜单全屏糊→rule 丢 ignore_alpha；OSD 无磨砂/全屏糊→jianlongliu.osd 丢；bar 不透→shell.toml 丢。

**恢复步骤**：查 3 文件在否 → 旧内容在 `~/.config/hypr/*.lua.bak.*`、`shell.toml.bak.*` → 重写并验证 → 默认 hypr 配置 `/usr/share/omarchy/` 只读只能写 `~/.config/` → OSD 缺失就 clone 再改。

**透明度实测法（2026-09-16 新增，别靠肉眼）**：
- **A/B 法（判"某表面到底吃不吃主题 alpha"）**：把该段 `background-alpha` 临时改成 0.15 → `omarchy restart shell` → `grim` 截图看壁纸是否明显透上来 → **务必还原并再重启**。本机浮栏就是这样验证的（改前实心，改后透）。
- **换帧回归法（量出有效 alpha）**：同一区域截"开/关"两帧灰度图（如面板开 vs 关），由 `pixel_open = α·C + (1-α)·pixel_closed`（C=卡片色，该区域内为常数）→ 取 (closed, open) 像素对的**斜率中位数**，`α = 1 - slope`。用 `magick -colorspace Gray -depth 8` 导 PGM，纯 Python 统计即可（本机没装 PIL）。实测样本：Display 面板 0.584、菜单（0.9 时代）0.95。
- **⚠️ 两个失效条件**：① 背后有**动态内容**（视频、动画）→ 两帧本身就在变，比差被污染（实测出现过 slope 为负）；② 背后**繁杂**时 blur 会破坏 open/closed 的像素级相关性 → slope 系统性偏小、α 偏大。**先确认背景静态**，否则只信配置值或改用 A/B 法。
- **解析法（最省事、可作上界判断）**：`卡片实际 = α·卡片色 + (1-α)·背景`，直接代入最亮/最暗背景算文字对比度（§3.4 那张表就是这么来的），不依赖截图。

**验证**：`hyprctl reload && hyprctl configerrors`（须空）；肉眼（bar 磨砂、菜单只卡片糊、`notify-send` 只右上卡糊）；（可选）`grim`+`magick ... -edge 1` 比角落边缘能量（修好≈1.0、全屏糊骤降≈0）。

### 3.4 菜单面板发黑 / 卡片色不跟主题（卡片色 + 全屏 scrim）

> 最后核对：2026-09-11 · Omarchy 4.0.3

**现象**（两个症状，同一个落点）：

| 症状 | 什么时候发现 |
|---|---|
| 菜单一打开，卡片和遮罩糊成一片暗色，看不出「卡片浮在遮罩上」的层次 | 初始问题 |
| **换壁纸/换主题后菜单卡片还是那身冷灰蓝，不跟主题走** | 后续发现（用户 2026-09-11 问起） |

**根因**（两条叠加，**跟 blur 参数无关**）：

| 因素 | 实际值 | 后果 |
|---|---|---|
| 卡片底色 | 未指定 → 回落主题 `background`（Tonal Spot `#101417`，近黑） | 卡片本身就黑 |
| 卡片不透明度 | `background-alpha` × `Style.shellOpacity` = 0.6 × 0.62（当年 Omablur 提供该 token） | 最终仅 **0.37**，背后内容透上来。**2026-09-16 Omablur 卸载后只剩 `background-alpha`**，不再有乘子 |
| 全屏 scrim | `scrim-alpha` 0.4 | 再压一层暗 → 卡片(37) 比 scrim(41) 还暗 |
| （后续修的）卡片色写死 | `~/.config/omarchy/shell.toml` 里写死 `#333940`，**用户层键盖过主题生成值** | 亮是够亮了，但主题换了它不动 |

**修复**（分两层，别混）：

**① 卡片色——走用户级模板，随壁纸自动变**（2026-09-11 改）

`~/.config/omarchy/themed/shell.toml.tpl`（= 上游 `/usr/share/omarchy/default/themed/shell.toml.tpl` 的副本，只改一行）：

```toml
[menu]
background = "{{ lighter_background }}"   # 原为 {{ background }}
```

- 模板渲染器 `omarchy-theme-set-templates` 的加载顺序是**用户模板先、内建模板后**（`<user>/*.tpl <builtin>/*.tpl`），且已存在的输出文件不覆盖 → 同名 `shell.toml.tpl` 用户版完全接管。
- `lighter_background` 是 matugen 生成的 `surface_container_high`（当前壁纸下 `#322826`），比 `background` 亮两档，正是要的层次。
- 好处：**换壁纸/换主题自动跟随**，不必再让 `materal-update` 去反写配置文件。
- ⚠️ 代价：这份 tpl 是**整份副本**，上游 `omarchy update` 改了 `shell.toml.tpl` 后要手动 diff 合并（文件头已注明）。
- 备选（未采用）：主题目录放 `shell.<section>.toml` 做分区覆盖——**不支持 `{{ }}` 变量**（那段是 awk 原样拼接，不过 sed），只能写死 hex，等于没解决。

**② alpha / scrim——仍留在用户 `~/.config/omarchy/shell.toml`**

```toml
[menu]
background-alpha = 0.65     # 2026-09-16：0.9 → 0.65，与同族对齐（bar 0.5/popups 0.58/notifications 0.6/launcher 0.6）；仍 > ignore_alpha 0.5
scrim-alpha = 0             # 不再压暗整屏
```
（这两行热重载吃不满，改完 `omarchy restart shell`。）

**效果**（`grim` 截图量卡片区平均亮度，非肉眼。**这组数是第 ① 步之前、用旧色 `#333940` 测的**，用来证明「越改越亮」的趋势；换成 `lighter_background` 后绝对值会随壁纸变，别拿旧数对号）：

| 阶段 | 卡片 | 背后 scrim |
|---|---|---|
| 原始 | 37.5 | 41.8（卡比遮罩更暗） |
| 改 `shell.toml` 后 | 46.1 | 34.4 |
| `restart shell` 后 | 53.0 | 35.3 |
| （当时）提到 alpha 0.9 + 去 scrim | **~64**（文字对比 4.8:1） | — |

**要点 / 坑**：

- `shell.toml` 热重载**不完整**，改完必须 `omarchy restart shell` 才吃满（实测差一档亮度）。
- `scrim-alpha = 0` **不影响「点空白处关闭」**：scrim 是 `Menu.qml:1045` 一个独立 `Rectangle`，关闭用的 `MouseArea` 在下一层（`Menu.qml:1050`），两者无关。
- **`[menu]` 是共享段**：clipboard / emojis / reminders 三个面板都读 `Color.menu.*`（含 `scrim`），改这段会连带它们一起变。
- ~~**Omablur 没有「blur 亮度」这一项**~~（仅存档：该插件已不在本机使用）：其 `decorationConfig()` 只写 `rounding / enabled / size / passes / new_optimizations / ignore_opacity`；面板滑块只有**圆角 + 强度**两个。`brightness / contrast / vibrancy` 归 `looknfeel.lua` 基础块管。
- **`decoration:blur:brightness` 是死旋钮**：实测 0.6 → 2.0，卡片亮度只动 ≤3%，别拿它诊断「偏暗」。
- **`hyprctl keyword decoration:blur:*` 现在只是临时值**：Omablur 卸载后没人再监听/写回（当年它会自动写回 `looknfeel.lua` 标记块，实测把 `rounding 20 / size 11 / passes 2` 改成 `14 / 14 / 3`）。要持久就改 `looknfeel.lua` 基础块 + `hyprctl reload`，别再靠 keyword。

**遗留**（2026-09-11 已解决）：卡片色不再写死，改由用户模板取 `lighter_background` → 换壁纸/换主题自动跟随，不需要往 `materal-update` 里加同步步骤。

**验证**（2026-09-11 实测）：`omarchy theme refresh` 后 `~/.local/state/omarchy/current/theme/shell.toml` 的 `[menu] background` = `#322826`（= 当时 `colors.toml` 的 `lighter_background`）；菜单开着截图，卡片内边距条取色 `srgb(23.6%,20.8%,22.0%)` → **R > B**（暖调）。对照：若仍是旧的 `#333940`，同条件合成应为 B > R（冷灰蓝）。scrim 未出现（角落像素与关菜单时逐位相同），说明用户层 `scrim-alpha = 0` 照常生效。

**0.65 的文字对比度（2026-09-16 算的，不靠肉眼）**：卡片色 `#272a2f`（灰度≈42）+ 文字主题 foreground（≈226），按 `卡片实际 = α·卡片色 + (1-α)·背景` 推：

| 背后背景 | 卡片有效灰度 | 文字对比 |
|---|---|---|
| 纯黑壁纸 | 25 | 13.4:1 |
| 中灰 | 70 | 7.1:1 |
| **纯白壁纸** | **115** | **3.6:1**（低于 WCAG AA 4.5:1） |

实拍（菜单压在 bilibili 亮缩略图上）文字仍可读，但卡片被背景"洗白"的地方观感偏软。想更稳就回调 **0.7（纯白 4.3:1）/ 0.75（5.0:1）**——改完 `omarchy restart shell`。

**回退**：删 `~/.config/omarchy/themed/shell.toml.tpl` + 在 `~/.config/omarchy/shell.toml` 的 `[menu]` 补回 `background = "#333940"` + `omarchy theme refresh` + `omarchy restart shell`。（`shell.toml.bak.*` 亦可用。）

### 3.5 浮动 TUI 窗口尺寸（btop / yazi）—— 1280×800

> 最后核对：2026-09-11 · Omarchy 4.0.3

**问题**：`CTRL+SHIFT+ESCAPE`(btop) 和 `SUPER+Y`(yazi) 的浮动窗沿用了 `floating-window` 标签的出厂 **875×600**，在 3840×2160@1.6（逻辑 2400×1350）上太小——btop 挤掉指标列、yazi 预览栏被压扁。

**做法**：只给这两个 app-id 打补丁，**不动共用标签**（1password / Bitwarden / portal 文件选择框、拖拽对话框都靠 `floating-window` 拿小尺寸，改标签会连带放大）。落点 `~/.config/hypr/windows.lua`：

```lua
o.window("^(org\\.omarchy\\.btop|org\\.omarchy\\.yazi)$", {
  tag = "-floating-window",
  float = true, center = true,
  size = { 1280, 800 },
})
```

**⚠️ 关键是 `tag = "-floating-window"`，不是 `size`**：标签那套 `float/center/size` 是**动态规则**，Hyprland 每个窗口**先静态、后动态**，与文件先后无关 → 后写的静态 `size` 一定被 875×600 盖掉（实测只加 `size` 完全无效）。必须先脱标签再重述属性。

**生效条件**：窗口属性创建时求值，`hyprctl reload` 不改已开窗口，**重开一次才生效**；验证要先杀干净旧窗口（该 TUI 助手是「已开则聚焦」，否则永远读到旧尺寸）。

> 完整上下文（快捷键、TUI 助手行为、验证脚本）见 `omarchy-function-tweaks.md` §3.5。

---

## 四、bar 左上角 logo / 锁屏头像

> **现状（2026-09-11 核实）**
> - **bar 左上角 = Arch logo**（自建插件 `jianlongliu.arch-logo`，见 4.1）
> - **锁屏 = 头像**（lock-explorer 原生探测 `lock-avatar.png`，见 4.2）

### 4.1 bar 左上角：Arch logo（插件 `jianlongliu.arch-logo`）

**先分清两类**：克隆**纯 `bar-widget`** 的内建控件（clock / workspaces / indicators…）是官方推荐路径，没问题。但**带其它 kind** 的插件（菜单是 `menu`、OSD 是 `panel`）克隆要当心——

`PluginRegistry.qml:548` 规定：启用一个带**非 `bar-widget` kind** 的克隆时，会**自动把源插件写进 `disabledPlugins`**（设计如此：克隆即替代，禁用克隆会 `restoreCloneSource` 还原）。所以克隆菜单之后，出厂的 `omarchy.menu` 被禁，**你只剩克隆那一份面板**；而克隆面板的 Apps 分类因 scoped 注入缺陷是空的 → 菜单废掉，且**没法「克隆画按钮 + 出厂出面板」两全**。

**本机做法**（不碰 `/usr/share`，升级不丢）：既然按钮和面板可以拆开，就建一个**独立小插件**——纯 `bar-widget`、**不带 `clonedFrom`**，只负责画按钮；面板仍用出厂的，不碰它。

```
~/.config/omarchy/plugins/jianlongliu.arch-logo/
├── manifest.json    # kinds:["bar-widget"]，无 omarchy.clonedFrom
├── BarWidget.qml    # BarIconButton + Image(svg) + MultiEffect 染色
└── arch-logo.svg    # 自 /usr/share/pixmaps/archlinux-logo.svg（filesystem 包，稳定），fill 已改 #ffffff
```

- **点击**：`omarchy-shell shell toggle omarchy.menu '{"menu":"root"}'`；右键开终端。
- **面板照常**：`omarchy.menu` 从 bar 布局挪走后，靠 manifest 的 `keepLoaded: true` **仍常驻挂载**（`shell.qml:1337`），菜单功能一点没动。
  ⚠️ 但 `omarchy plugin list` 会把它标成 `DISABLED`——那栏按 bar 布局算，**不代表面板真没了**，用下面的截图法验证。

**两个坑**（都踩过）：
1. **`MultiEffect.colorization` 是按源亮度相乘**，不是「涂成某色」。原 SVG 是 Arch 蓝（亮度≈125/255），染出来只有一半亮（实测 70 vs 邻居 133）。**必须先把 SVG 的 `fill` 改成 `#ffffff`**，染完才是满亮度的前景色。
2. **`Image` 没有 `color` 属性**（那是 `IconImage`）。要 `Image` 隐藏 + `layer.enabled: true`，再用 `MultiEffect` 采样——这是 omarchy 自己 `Tray.qml:785` 的单色图标管线。

**验证**：
```bash
omarchy restart shell
# 面板真的画出来了？开关各截一张图做差
grim -o DP-2 /tmp/closed.png
omarchy-shell shell toggle omarchy.menu '{"menu":"root"}'; sleep 2
grim -o DP-2 /tmp/opened.png
omarchy-shell shell toggle omarchy.menu '{"menu":"root"}'      # 关掉
magick compare -metric AE /tmp/closed.png /tmp/opened.png null:  # 差异应为百万像素级
```
**像素级验收**（AI 无视觉时用）：裁 bar 左上角，logo 区**最亮像素应等于当前主题前景色**——本机 Tonal Spot 为 `#e0e3e8` = `(224,227,232)`，且 `B-R ≤ 10`（中性、无蓝）。

**换图**：替换 `arch-logo.svg` 即可（保持 `fill="#ffffff"`）。想改回圆形头像：同一个 `iconComponent` 里把 `Image` 指向 `~/.config/omarchy/avatar_circle.png` 就行。

**回退**：bar 布局里把 `jianlongliu.arch-logo` 换回 `{"id": "omarchy.menu"}`，再删插件目录。

### 4.2 锁屏头像（走 lock-explorer 原生探测，勿改 QML）

`lock-explorer` 已合并上游新版（2026-09-06），用共享 `Avatar{}` 组件（`designs/Avatar.qml`），**不要再改 `Split.qml`**。头像源按顺序探测：

`~/.config/omarchy/lock-avatar.{png,jpeg,webp}` → `~/.face` → `~/.face.icon` → AccountsService 图标 → 无则回退首字母。

```bash
cp ~/.config/omarchy/avatar_circle.png ~/.config/omarchy/lock-avatar.png
omarchy restart shell
```
预览：`omarchy-shell lock previewDesign split`；交互选择 `omarchy-shell lock pickAvatar`（锁屏无键盘，仍推荐探测路径法）。

**回退**：删 `~/.config/omarchy/lock-avatar.png` 再 `omarchy restart shell`（自动回退首字母），或 `omarchy-shell lock setDesign card` 换设计。

### 4.3 头像素材（现仅锁屏用）

**产物**（放 `~/.config/omarchy/`）：
| 文件 | 用途 |
|---|---|
| `avatar.png` | 512×512 方形底图（母版） |
| `avatar_circle.png` | 512×512 **圆形透明** PNG，lock-avatar 的母版 |
| `lock-avatar.png` | 锁屏实际读取的文件 |

生成：
```bash
cd ~/Pictures/wallpapers
magick "壁纸.png" -crop 1500x1500+1560+460 +repage -resize 512x512 ~/.config/omarchy/avatar.png
magick ~/.config/omarchy/avatar.png -resize 512x512 \
  \( -size 512x512 xc:black -fill white -draw "circle 256,256 256,0" \) \
  -alpha off -compose CopyOpacity -composite ~/.config/omarchy/avatar_circle.png
cp ~/.config/omarchy/avatar_circle.png ~/.config/omarchy/lock-avatar.png
magick ~/.config/omarchy/avatar_circle.png -format "%[pixel:p{2,2}] %[pixel:p{256,256}]\n" info:
# 期望 → srgba(0,0,0,0) srgba(...,1)   （角透明、心不透明，证明是圆形）
```
换头像：换 `avatar_circle.png` → 重新 `cp` 成 `lock-avatar.png`。

**坑**：①`Rectangle.clip` 不按 radius 裁圆（裁成方形）②`MultiEffect` mask 读不到、也不裁圆 ③keepLoaded 组件改后必须 `omarchy restart shell`，热重载不生效。

---

## 五、系统光标：Bibata（bibata-cursor）
**目标**：默认光标换 **Bibata-Modern-Amber**(琥珀圆角),尺寸 30,Hyprland + GTK/XWayland 统一生效。
**装包**：`yay -S --noconfirm --needed --sudo pkexec bibata-cursor-theme`（AUR 2.0.7-1,变体装 `/usr/share/icons/Bibata-Modern-Amber`）。常用变体：Amber(琥珀)/Ice(冰蓝)/Classic(经典黑)。
> 坑：无 tty 装 AUR,`sudo` 要密码会失败 → 用 `yay --sudo pkexec` 让 yay 以 pkexec 当 sudo 替身。

**配置（两处缺一不可）**：
1. `~/.config/hypr/envs.lua`(GTK/XWayland 读)：
```lua
hl.env("XCURSOR_THEME", "Bibata-Modern-Amber")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Amber")
hl.env("XCURSOR_SIZE", "30"); hl.env("HYPRCURSOR_SIZE", "30")
```
> Omarchy 默认只在 `/usr/share/.../envs.lua` 设尺寸(24)**不设主题名**,必须自己补 `*_THEME`。
2. `~/.config/hypr/autostart.lua`(Hyprland 自身光标),`hyprland.start` 钩子内 `hyprpm reload` 前加 `hyprctl setcursor Bibata-Modern-Amber 30`（`hl.env` 只影响子进程,Hyprland 自己画的光标靠 setcursor）。

**立即生效**：`hyprctl setcursor Bibata-Modern-Amber 30` → ok；`hyprctl configerrors` 干净。
> 光标主题是运行时 IPC 状态非静态 option,`hyprctl getoption cursor:*` 报 `no such option` 属正常。

**回退**：临时 `hyprctl setcursor Bibata-Modern-Ice 30`；永久改 envs.lua + autostart.lua 再 reload；卸载 `yay -R --sudo pkexec bibata-cursor-theme`。

---

## 六、登录界面(SDDM)壁纸跟随桌面
**目标**：登录界面从纯色深底改成跟桌面一致的壁纸,且 `omarchy theme bg next` 换图后下次开机自动同步。
**机制**：Omarchy 用状态软链记录当前壁纸——`~/.local/state/omarchy/current/background → ~/Pictures/wallpapers/<当前>.png`。登录背景引用**这条软链的绝对路径**即自动同步(QML 每次进登录界面重载读最新指向)。

**改动**（复制官方主题,官方目录全程未动防被 `omarchy refresh sddm` 重置）：
1. 复制：`pkexec cp -r /usr/share/sddm/themes/omarchy /usr/share/sddm/themes/omarchy-wallpaper`
2. `Main.qml` 在根 Rectangle 内、Column 前插背景图+遮罩(声明在前渲染在底,logo 在最上)：
```qml
Image { id: wallpaper; anchors.fill: parent
  source: "/home/<你的用户名>/.local/state/omarchy/current/background"
  fillMode: Image.PreserveAspectCrop; asynchronous: true }
Rectangle { anchors.fill: parent; color: "#1e1e2e"; opacity: 0.45 }  // 遮罩保可读
```
3. 切主题：新增 `/etc/sddm.conf.d/zz-omarchy-wallpaper.conf`（`zz-` 前缀排最后覆盖官方 `10`/`99` conf 的 `Current=omarchy`）：`printf "[Theme]\nCurrent=omarchy-wallpaper\n"`。

**排障(背景不显示)**：greeter 以 **`sddm` 用户(uid=962)** 跑,非 root;`$HOME` 是 `drwx------`,sddm 读不到软链 → 需给 traverse ACL：`setfacl -m u:sddm:x "$HOME"`。验证：`pkexec su -s /bin/sh sddm -c 'T=$(readlink -f .../background); file "$T"'`(应打印 JPEG)。
**验证**：无 qmlformat/qmlscene 本机,做粗校验 `python3 -c "...count('{')==count('}')"`;真效果下次登录界面确认(当前会话别 `systemctl restart sddm` 会踢人)。
**调参**：遮罩 `Rectangle.opacity`(0 纯壁纸/1 纯色)、`fillMode`、兜底色 `color`。
**还原**：`rm /etc/sddm.conf.d/zz-omarchy-wallpaper.conf` → 官方主题恢复;`rm -rf /usr/share/sddm/themes/omarchy-wallpaper`;`setfacl -x u:sddm "$HOME"`。
**注意**：`zz-` 前缀不能省(否则被官方 Current 覆盖);别删 `current/background` 软链(全机壁纸同步锚点);锁屏是 lock-explorer 另一套,≠ SDDM 登录界面。

---

## 七、动态取色主题：matugen M3（tonal-spot / expressive）
**目标**：从当前壁纸取 Material 3 动态色,自动套到窗口边框/状态栏/全部 Quickshell 毛玻璃面/终端文本;换壁纸或登录自动重取色。做成两套主题。**只改颜色**,不碰毛玻璃 layer rules/ignore_alpha(正交)。
**默认取向**：**tonal-spot**(沉稳,primary 与 surface 同冷暖)。expressive 会把 primary 大转色相与 surface 撕裂,铺大色块刺眼,只作可选。锁 **dark** 模式。ANSI 16 色保留 catppuccin 静态(可读性优先)。
**颜色流**：主题 colors.toml → `/usr/share/omarchy/default/themed/*.tpl` → 生成 hyprland.lua(边框)/shell.toml(毛玻璃面)。**只需 matugen 写一套 colors.toml,再 `omarchy theme refresh` 触发模板重渲**。
**M3→colors.toml 映射**（输入就 20 键）:accent←primary、selection←primary_container、muted←on_surface_variant、background←surface、foreground←on_surface、red+ANSI 保留 catppuccin 原值。派生键(background_rgb/*_strip/selection_*/theme_type)由这些生成;foot 用 `purple_strip`,catppuccin 无 purple,由 magenta 派生。
**主题结构**：`~/.config/omarchy/themes/{tonal-spot,expressive}/` 各含 `colors.toml`(matugen 生成)+ `matugen.toml`(meta scheme/mode)。fork catppuccin,激活 `omarchy theme set Tonal-Spot`。⚠️ 目录名须小写 slug 否则 `theme set` 归一后找不到。
**触发**：幂等脚本 `~/.local/bin/materal-update`（读激活主题→matugen 取色→临时写→校验→替换→留备份→apply）。apply 用 `OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy-theme-set <slug>`(=refresh,**不轮换壁纸**),设 guard 防死循环。三处触发:
1. systemd 用户服务 `matugen-theme.service`(启动取一次+inotify 循环)
2. 换壁纸:`inotifywait` 盯 `current/` 目录、匹配 background 文件、300-500ms 去抖
3. 换主题:`~/.config/omarchy/hooks/theme-set.d/` 钩子
> 盯目录而非软链本体:`ln -nsf` 重建软链,盯父目录+文件名最稳。
**实施**：`omarchy pkg aur add matugen`(用户只做这步)→ fork 两主题目录 → 各写 matugen.toml → 写 materal-update 脚本 → 写 theme-set hook → 建 systemd service enable --now → (可选)materal-menu(gum)。
**matugen CLI(用户不碰,实施者用)**：`matugen image <壁纸> -t scheme-tonal-spot -m dark -j hex --dry-run --prefer=saturation`。非交互**必须带 `--prefer`** 否则无 tty 报 `Multiple source colors`;`--dry-run` 防 set wallpaper。
**回退**：`disable --now matugen-theme.service`;删 theme-set hook;`omarchy theme set catppuccin`;删两主题目录。官方 catppuccin 目录全程未动。
**踩坑**：别改 `/usr/share/omarchy/themes/catppuccin`(update 覆盖,须 fork);`theme set` 每次 reload(换壁纸轻闪可接受);ANSI 静态致终端功能色不跟 M3 同相;日/夜锁 dark;别删 `current/background` 软链;expressive 冷暖撕裂别当默认。

### 7.1 激活窗口边框接入多色渐变
**目标**：激活边框不再单色 accent,改随壁纸自动生成的三色渐变,换壁纸自动跟上(matugen 一体)。

**关键机制**：
- 模板 `hyprland.lua.tpl`:`local active_border_color = {{ hypr_gradient hyprland_active_border accent }}`——colors.toml 有 `hyprland_active_border` 就用它,否则退回单色 `accent`。**所以只需往 colors.toml 写 `hyprland_active_border`**。
- colors.toml 该键正确格式（见 `hackerman`/`last-horizon` 主题）：
  - colors.toml:`hyprland_active_border = "rgba(26a269ee) rgba(2ec27eee) 45deg"`（多色空格分隔+角度）
  - 模板渲染结果:hyprland.lua 里成 `{ colors = { "rgba(..)", "rgba(..)" }, angle = 45 }`（DHH table 形式,**非**字符串 `gradient(...)`）
- **生效位置**：`hyprctl getoption general:col.active_border` 会看到 `gradient data: ... 45deg`。

**改 `~/.local/bin/materal-update`（Python 段）两处**：
1. 读 tertiary:加 `tertiary = col('tertiary')`。
2. inactive_border 定义后拼 active_border 并写进 colors.toml 输出 L 列表:
   `active_border = "%s %s %s 45deg" % (to_rgba(accent), to_rgba(tertiary or accent), to_rgba(selection or accent))`
   → 生成 `hyprland_active_border = "rgba(accent) rgba(tertiary) rgba(selection) 45deg"`。三色同冷暖(primary/tertiary/primary_container)协调随壁纸。

**生成验证**：`MATERAL_NO_APPLY=1 materal-update`（只写 colors.toml 不 apply）→ `grep active_border ~/.config/omarchy/themes/<slug>/colors.toml`。真正 apply 后看 `~/.local/state/omarchy/current/theme/hyprland.lua` 的 `active_border_color`。

**踩坑**：
- 写死渐变放 `looknfeel.lua` **会覆盖** matugen 主题文件(因 looknfeel require 在 theme 之后),要"随 matugen"必须**不要**在 looknfeel 写死,把颜色留给 colors.toml/主题。
- 想"流动跑马灯"(角度随时间转)在 Omarchy 的 DHH 层**做不了**——`angle` 是静态数字无动画,别为它逆向/ hack 官方配置层(不值)。
- 不用时删 materal-update 里那几行 + 从 colors.toml 去掉 `hyprland_active_border` 即回单色;备份 `materal-update.bak.*`。

### 7.2 浮动 bar 跟窗口同一套五彩琉璃边框
**目标**：浮动 bar 外圈描一层五彩琉璃环，让 bar 与聚焦窗口边框**视觉完全一致**（同色渐变 + 同粗）。用户核心诉求：**整体视觉一致性，全部走同一套参数，别让 bar 自成一套。**

**方法论（关键，别违反）**：任何 surface 想"跟窗口边框一致"，**绝不单独给它写颜色或宽度魔数**，而是镜映窗口边框的**两个同源参数**，让 bar 只是窗口边框的"缩小复制"：

| 属性 | bar 的取法 | 窗口的真源 | 换壁纸/调边框时 |
|---|---|---|---|
| 颜色/渐变 | `Border.hyprlandActiveSpec()` → themed `[hyprland] active-border` | `hyprland_active_border`(colors.toml, matugen 生成) | 只改 colors.toml/换壁纸,全部自动跟上 |
| 粗细 | 运行时读 Hyprland `general:border_size` | `general:border_size`(looknfeel) | 只调 border_size,bar 自动跟(经 configreloaded) |

- **为什么用 `Border.hyprlandActiveSpec()`**：它是 Omarchy 官方给 surface 取"当前激活窗口渐变"的入口（`Commons/Border.qml`）。颜色三色渐变成 DHH table，Rectangle.border 只能单色，画不了。
- **为什么宽度 probe `border_size` 而非 Omarchy `[hyprland] active-border-width`**：该 token 当前**没有任何 surface 消费**（`hyprlandActiveSpec` 在**上游 shell 全库零调用**——`/usr/share/omarchy/shell/` 里只有 `Border.qml:152` 的定义、无调用点；**唯一的调用方就是本机浮栏 `Bar.qml`**，这正是本节在做的事），宽度真源只有 Hyprland `border_size`。probe 它才真正"跟窗口同一个数"。将来 Omarchy 铺开 `active-border-width` 再迁。
- **可选手调**：`configuredBorderWidth` 设非 -1 即覆盖自动值；设为 0 可关环。

**实现（Bar.qml，浮动栏插件 `charlieras262.floating-bar/`）**：
1. 把 `barBackground` 由 `Rectangle` 换成官方 `Ui.BorderSurface`（`qs.Ui` 已 import；gradient.enabled 时它自动用 `BorderOverlay` 画 Shape 渐变 ring）：
   ```qml
   BorderSurface {
     id: barBackground
     anchors.fill: parent
     radius: root.effectiveCornerRadius          // 圆角贴合
     borderSpec: root.transparent
       ? Border.none()
       : Border.withWidth(Border.hyprlandActiveSpec(root.background, 2), root.barBorderWidth)
     color: root.transparent ? "transparent" : root.background   // 主题 [bar] background-alpha（0.5）
     opacity: 1                                                   // 上游原本是 Style.shellOpacity，已废弃
     Behavior on radius { ... } /* 原有三句 Behavior 保留 */
   }
   ```
2. 宽度属性 + 运行时探测（复用文件里现成的 `gaps_out` 异步探测模式，同一 `configreloaded` 钩子一起刷）：
   ```qml
   property real configuredBorderWidth: -1
   property real autoDetectedBorderWidth: 5
   readonly property real barBorderWidth: configuredBorderWidth >= 0 ? configuredBorderWidth : autoDetectedBorderWidth
   Process { id: borderWidthProbe
     command: ["hyprctl","-j","getoption","general:border_size"]
     /* stdout 收进 buffer, onExited parse parsed.int → autoDetectedBorderWidth */
   }
   ```
   `refreshGapsOut()` 内同时启 `borderWidthProbe`，`onRawEvent==configreloaded` 已由原 gapsOut 触发，无需新钩子。

**验证**：`hyprctl -j getoption general:border_size`（.int 即环宽）。裁顶栏放大看圆角外沿三色渐变，内部仍是 bar 背景色。
> **本机现状（2026-09-11）**：环宽 = **4**（`border_size` 由 5 收窄，三处同改见 §7.4）。上面代码块里的 `autoDetectedBorderWidth: 5` 只是 probe 出结果**之前**的兜底初值，不是生效值。
**回退**：`Bar.qml.bak.*` 覆盖 + `omarchy restart shell`。
**复发提醒**：`omarchy update` 或重置可能还原插件 → 用 `Bar.qml.bak.*` 重放；颜色随壁纸变是正常（同源 matugen），觉得跳脱就调 colors.toml 的 `hyprland_active_border`，别在 bar 里写死色。

**切回单色备选（五彩用腻时）**：整套镜映同源，故 bar 环 + 弹层 + **窗口激活边框一起**回单色（一致性下无法只切 bar 不切窗口；想窗口单色=§7.1 全套回退）。只需把 `colors.toml` 的 `hyprland_active_border` 从多色改回**单个 accent**：
```toml
hyprland_active_border = "rgba(ffb4a8ff)"   # 只留单色、去掉 45deg 与其余两色
```
因 `Border.borderValue` 里 `colors.length===1` → `gradient.enabled=false`，bar 环自动退回单色 accent、弹层同步。改后跑 `omarchy theme refresh`（重渲 themed hyprland.lua / shell.toml）。要回多色就改回三色串再刷新。
> 更彻底想单色全退：删掉 `materal-update` 里拼 active_border 那几行 + 从 colors.toml 删 `hyprland_active_border`（回 §7.1 之前单色 accent）。备份 `materal-update.bak.*`。

### 7.3 弹层(popup/menu)边框宽度也统一到窗口 border_size
**目标**：bar 上点开的插件浮层(时钟日历、托盘、媒体、菜单面板等)的边框，跟窗口和 bar **同一套**——颜色同源渐变(早已是)、宽度对齐 `border_size`（**当前 = 4**）。
**背景**：浮层颜色**早就同源**(全部引 `hyprland.active-border` 主题渐变)，唯独**宽度**没对齐——各容器自己 fallback 成 `Style.space(2)`≈2，肉眼比窗口/bar 细一圈。§7.2 那条"镜映窗口同源参数"的漏网区。

**根因**：浮层边框由统一容器画——
- `PopupCard`(`Ui/PopupCard.qml`)系(Tray/媒体/键盘等)走 `[popups]` section：`Border.localOrSurfaceSpec("popups","border",…, Math.max(1,Style.space(2)))`，**fallback 宽约 2px**。
- 菜单面板 `Menu.qml` 走 `[menu]` section：`Border.surfaceSpec("menu","border",…, Math.max(1,Style.space(2)))`。
两处 fallback 都偏窄且不看窗口 `border_size`。

**修复（零改源码，用户级 shell.toml，集中可逆）**：给 `~/.config/omarchy/shell.toml` 补 `border-width`，颜色/alpha 维持主题同源值：
```toml
[popups]
border-width = 4      # 对齐窗口 border_size

[menu]
border-width = 4
```
`Border.surfaceSpec` 读 `[popups] border-width`（存在则不 fallback）→ 弹层边框宽=窗口宽，颜色仍 `hyprland.active-border`。

**生效**：`omarchy restart shell`（UserShell 热重载 `userShellValues`；重启保险）。日志无 `falling back` 即好。
**回退**：删掉这两行 `border-width` 或 `cp shell.toml.bak.*` 还原 + `omarchy restart shell`。
**验证**：点开任一 bar 插件浮层，边框粗细应肉眼等同窗口/bar。
**坑**：
- 颜色`border`/alpha 是主题生成，**别**在用户 shell.toml 里覆盖它们，只补 `border-width`——避免破坏"随壁纸"。
- **此处是静态值**：改窗口 `border_size` 后浮栏会跟(§7.2 动态 probe)，但弹层这两处 shell.toml 要**手动同步**。将来可仿 §7.2 做运行时对齐，暂不值当。
- **本机现状（2026-09-11）**：`border_size` 由 5 收窄到 **4**，三处一起改（见 §7.4）。

### 7.4 边框收窄 5→4（2026-09-11）
**诉求**：窗口/bar 的五彩环看着略粗，收一档。**必须三处一起改**，否则破坏 §7.2/§7.3 好不容易建立的一致性——只有一处改会让 bar 环、窗口、弹层各粗各的。

| 改哪 | 位置 | 管什么 |
|---|---|---|
| `border_size = 4` | `~/.config/hypr/looknfeel.lua:19` | **真源**：窗口边框；浮栏环运行时 probe 它自动跟 |
| `border-width = 4` | `~/.config/omarchy/shell.toml:9`（`[popups]`） | 弹层/OSD |
| `border-width = 4` | `~/.config/omarchy/shell.toml:19`（`[menu]`） | 菜单面板 |

- **生效**：`hyprctl reload`（窗口 + 浮栏环）**加** `omarchy restart shell`（shell.toml 两处）。浮栏环挂在 `configreloaded` 上，**`hyprctl reload` 后就已经跟上**（实测 reload 后环宽即 4）；图片侧"看着没变"是**测量阈值假象**，不是没生效，见下条。
- **验证**：`hyprctl -j getoption general:border_size` 的 `.int` = 4；`hyprctl configerrors` 空；裁 bar 左上角数环宽物理px。⚠️ **阈值陷阱**：含抗锯齿会读成 8 物理px（看着像没变），**只数 `r≥170` 的核心像素**才得 6 物理px = 4 逻辑px（`scale=1.6`）；改前的核心像素是 8 = 5 逻辑px。
- **回退**：`looknfeel.lua.bak.1789114438` / `shell.toml.bak.1789114438` 覆盖 + `hyprctl reload` + `omarchy restart shell`。
- **持久性**：`~/.config/omarchy/shell.toml` 是**用户覆盖层**，`omarchy theme set` 只读**主题目录**那份 `shell.toml` 推给 shell、**不重写**用户这份 → 改动不会被换主题吃掉。
- **坑**：这两处是**静态值**，`border_size` 再改时 shell.toml 得手动同步（§7.3 已注明）。

---

## 八、【已失效·存档】全局字体链：SF Mono + 苹方 + Nerd 按字形分工

> 🔴 **本节已失效，仅存档备查（2026-09-11 复核）**：`51-omarchy-body-fallback.conf` 已删（只剩 `conf.d/51-omarchy-body-fallback.conf.bak.1788803869`），**SF Mono + 苹方那条链现在完全不存在**。
> **现状**：`monospace` → `GoogleSansCode Material`（= GoogleSansCode Nerd Font 换过图标的版本，见 §1.3），中文由系统 fallback 兜。`fc-match -s monospace` 前三位 = `GoogleSansCode Material` → `JetBrainsMono Nerd Font` → `Noto Naskh Arabic`。
> 即 bar 正文现在是 **GoogleSansCode 主导**。SF Mono 那条链不必再补——除非重新想要「西文 SF Mono 主导」的观感，那才按 §8.3 补回并重测框线。
> 下面 8.1–8.5 保留原文，用于理解 fontconfig `assign` → 后置文件抢不回的机制（该机制本身仍成立）。

**目标**：bar/正文默认等宽字体改成「西文 SF Mono → 中文 PingFang SC → 图标 JetBrainsMono Nerd Font」按字形自动分工链。用户已接受「SF Mono 等宽主导」观感（macOS 味）。

- **链**：请求 `monospace` → **SF Mono Powerline**（西文）→ **PingFang SC**（中文）→ **JetBrainsMono Nerd Font**（仅图标兜底）。
- 曾试「西文 SF Pro（比例字体）」——用户不适应等宽→比例跳跃，故改回等宽主导。
- 落 `~/.config/fontconfig/conf.d/`，**用户级，`omarchy update` 永不还原**。

### 8.1 为什么直接改 Style.qml / fonts.conf 都不行
- Omarchy bar 正文硬编码在 `/usr/share/omarchy/shell/Commons/Style.qml` `property string fontFamily: "monospace"`；改它会被 update 还原。
- `shell.toml` **改不了 family**：`applyShellValues` 用 `parseInt`，非数值键被 `continue` 跳过。
- `~/.config/fontconfig/fonts.conf` 也别当长期落点：`omarchy font set`（菜单 Style>Font）会**整文件覆写**。
- **根因**：`/etc/fonts/conf.d/50-omarchy.conf` 把 monospace `assign` + `binding="strong"` 成 JetBrainsMono Nerd Font，后续普通 prepend 抢不过 → 用户级 `fonts.conf` 里写 prepend 无效。

### 8.2 SF Mono 装法（Omarchy 通道装不了）
```bash
yay --sudo pkexec -S otf-sfmono-patched
```
- Omarchy 的 `omarchy install font` **只装 Nerd Font**，候选里无 SF Mono；`otf-sfmono-patched` 是 AUR 包（纯 SF Mono + Powerline 补丁，不冲突已有 `otf-apple-sf-pro`/`otf-apple-pingfang`）。
- ⚠️ 该包族名是 **`SF Mono Powerline`**（带后缀），`fc-match "SF Mono"` 会落回 SF Pro。真等宽、有 Powerline 箭头、**无 Nerd 图标** → 图标靠 JBM 兜底。

### 8.3 正确落点与写法
新建 `~/.config/fontconfig/conf.d/51-omarchy-body-fallback.conf`（编号 51 > 系统 50，后加载能反制 assign）：
```xml
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <!-- 拦 monospace -->
  <match target="pattern">
    <test qual="any" name="family"><string>monospace</string></test>
    <edit name="family" mode="prepend" binding="strong">
      <string>SF Mono Powerline</string>
      <string>PingFang SC</string>
      <string>JetBrainsMono Nerd Font</string>
    </edit>
  </match>
  <!-- Omarchy 已把 monospace assign 成 JBM，故在 JBM 名上再盖一层 -->
  <match target="pattern">
    <test qual="any" name="family"><string>JetBrainsMono Nerd Font</string></test>
    <edit name="family" mode="prepend" binding="strong">
      <string>SF Mono Powerline</string>
      <string>PingFang SC</string>
    </edit>
  </match>
</fontconfig>
```
**两条都要**：第一条拦原始请求，第二条兜底已 assign 的 JBM。**⚠️ 缺第二条则整条链失效**（见 §8.5）——本机当前就是这种状态。

### 8.4 验收（仅在两条都在时成立）
```bash
fc-cache -f
fc-match monospace                    # 应 SF Mono Powerline（本机实测现在返回 JBM = 链未生效）
fc-match -s monospace | head -n 3     # SF Mono Powerline → PingFang SC → JBM Nerd
fc-match 'monospace:charset=0041'     # A  西文 → SF Mono Powerline
fc-match 'monospace:charset=4e00'     # 一 中文 → PingFang SC
fc-match 'monospace:charset=f001'     # Nerd 图标 → JBM Nerd
omarchy restart shell                 # Quickshell 要重启才重新解析字体
```
精确族名（差一空格即错）：`SF Mono Powerline` · `PingFang SC` · `JetBrainsMono Nerd Font`。

### 8.5 为什么"只留第一条"等于白配（本机现状的成因）

`/etc/fonts/conf.d/50-omarchy.conf` 把 `monospace` 用 **`assign` + `binding="strong"`** 换成了 JBM——**`assign` 会把 pattern 里的 family 直接替换掉**。等 51 号文件跑到时，pattern 的 family 已经是 `JetBrainsMono Nerd Font`，**不再含 `monospace`**，所以第一条的 `<test name="family">monospace</test>` **匹配不上**，什么也没做。

**真正起作用的是第二条**（`<test>JetBrainsMono Nerd Font</test>`）——它匹配的是 assign 之后的名字。

所以：
| 配置 | `fc-match monospace` 结果 |
|---|---|
| 两条都在 | SF Mono Powerline（链生效）|
| **只剩第一条（本机现状）** | **JetBrainsMono Nerd Font（链失效）** |
| 两条都无 | JetBrainsMono Nerd Font |

**历史代价（2026-09-08 删第二条时记的理由）**：第二条对**具名 JBM** 也强 prepend SF Mono，于是凡直接请求 JBM 的程序（fzf、终端）拿到 SF Mono，当时判断是框线 `╭╮╰╯` 被 SF Mono 截胡成方块。

> **⚠️ 该理由 2026-09-11 复测不成立**：`fc-query` + 实渲染（`magick label:` 逐个字形，比对 `.notdef`）显示 **SF Mono Powerline Regular 含全部框线字形** `┌─┐│└┘├┤┬┴┼╭╮╰╯`，无豆腐。**只有 Italic 变体缺**（Bold/Medium/Semibold/Regular 均含）。所以当初"框线豆腐"要么是别的原因（如 fzf 用了 Italic、或当时字体版本不同），要么判断有误——**未能复现**。删第二条这个事实仍在，但别再引用"缺字形"当依据。

**要重新启用**：把 §8.3 第二条补回，然后 `fc-cache -f`；若框线花，改用「只对 monospace 生效」的写法（例如第二条的 `<test>` 加 `qual="any"` 之外的条件，或给 fzf/终端逐个钉字体）。

**回退**：`rm ~/.config/fontconfig/conf.d/51-omarchy-body-fallback.conf && fc-cache -f && omarchy restart shell`；卸 SF Mono `yay --sudo pkexec -R otf-sfmono-patched`。不需动 `/etc/fonts/conf.d/50-omarchy.conf`。

---

## 九、其它应用视觉对齐：Flea 文件管理器

**目标**：让 flea 跟桌面一致（苹方字体、字号对齐 bar、毛玻璃）。配色天然同源，不用改。

### 9.1 为什么能"只改 flea 不动 bar"
`/usr/share/flea/ui/{Commons,Ui}` 是 **symlink → `/usr/share/omarchy/shell/{Commons,Ui}`**——flea 与 bar **共享同一套 Style/Color/Ui**，直接改会连带改 bar。**要只改 flea**：把 UI `cp -rL` 复制到用户区（**解引用** symlink 成真实目录），再改副本。

### 9.2 持久化落点（update 不还原）
1. UI 副本：`cp -rL /usr/share/flea/ui/. ~/.local/share/flea/`（副本里 `/usr/share/omarchy` 引用只是注释，无碍）。
2. 启动注入 `FLEA_UI`：flea 二进制支持该环境变量指向自定义 UI 目录。系统 `.desktop` 是 root 只读，故用**用户级 .desktop 覆盖** `~/.local/share/applications/com.thisisgm.flea.desktop`：
   `Exec=env FLEA_UI=%h/.local/share/flea flea --gui %f`
3. 系统版 `/usr/share/flea` 原封未动。

### 9.3 三处改动
| 项 | 文件 | 改法 |
|---|---|---|
| 字体 → 苹方 | 副本 `Commons/Style.qml` | `fontFamily: "PingFang SC"`（原 `"monospace"`） |
| 字号 → 对齐 bar 14 | 副本 `Theme.qml` | `bodySmall: Math.round(Style.font.body * ViewState.uiScale)`（原走 bodySmall=13px，小一档） |
| blur | `~/.config/hypr/windows.lua` | `o.window("com.thisisgm.flea", { opacity = "0.92 0.88" })`，重开窗口生效 |

- 苹方在 `/usr/share/fonts/pingFang/pingFangSC/`；⚠️ `fc-list :lang=zh` 可能**查漏**它（lang 标签不全），用 `fc-match "PingFang SC"` 验证。
- 想 flea 单独比 bar 大：改副本 bodySmall 取值来源（如 `title`=16px），**别动共享 base-size**（会连 bar 一起）。

### 9.4 配色天然一致（不用改）
flea `Theme.qml` 直读 `~/.local/state/omarchy/current/theme/colors.toml`，与 bar 同一 matugen 输出源；换主题靠 inotify 实时 reload；字体/圆角/间距全走 `Style.*` token。

**回退**：删 `~/.local/share/flea` + 用户级 `.desktop`，重开 flea 回系统版（改动前备份 `Theme.qml.bak` 于副本内）。

---

## 十、其它应用视觉对齐：GTK 应用（nautilus / loupe）

**目标**：nautilus / loupe 的**配色跟随 omarchy 主题**（和 ghostty 同待遇），**接口字号**对齐系统 14px。
**结论**：已落地。配色全程走 omarchy 原生扩展点（主题模板 + hook），没写野脚本。

### 10.1 为什么之前不跟主题：omarchy 官方就没有 gtk 模板

| 应用 | 是否跟主题 | 依据 |
|---|---|---|
| ghostty / foot / kitty / alacritty / btop / tmux / neovim / vscode / obsidian / helix …（**19 个**） | ✅ | 官方 `/usr/share/omarchy/default/themed/` 各有对应 `.tpl` |
| **GTK / nautilus / loupe** | ❌ | **官方无 gtk 模板**（全盘搜 `*gtk*` 只有一个粘贴脚本） |

omarchy 对 GTK 只做一件事：`omarchy-theme-set-gnome` 把 gsettings 的 `gtk-theme` 设成 **`Adwaita-dark`**——
那是 GNOME 的固定主题名，跟 matugen 取的颜色**毫无关系**（实测其 CSS 里搜不到主题 accent）。

本机原先靠手工补的两样上色，**都是静态的、不跟主题**：
`~/.config/environment.d/gtk-theme.conf`（全局 `GTK_THEME=Catppuccin-Mocha-Mauve`）+ `~/.local/bin/nautilus`（wrapper 再套一层）。

> **反直觉但重要**：**ghostty 才是"标准"待遇，GTK 才是异类**。本改动不是跟 omarchy 对着干，是把它漏掉的那块补上。

### 10.2 ⚠️ 硬坑：`GTK_THEME` 会压死用户 CSS 的 `@define-color`

| 写法 | GTK4 | GTK3 |
|---|---|---|
| `@define-color window_bg_color #xxx;`（**无** `GTK_THEME`） | ✅ 生效 | ❌ **不生效** |
| 选择器 `headerbar { ... }` | ✅ 生效 | ✅ 生效 |
| `@define-color`（**有** `GTK_THEME`） | ❌ **完全无效** | ❌ 无效 |
| `!important` | ❌ **GTK CSS 不支持**（报 `Junk at end of value`） | ❌ 同样不支持 |

**优先级**：`GTK_THEME` > 用户 CSS 的 `@define-color`；但**盖不过用户 CSS 的显式选择器**。

> **GTK4 与 GTK3 正相反**：GTK4 首选 `@define-color`，GTK3 只能用选择器。别混用。
> **排查铁律**：先 `env -u GTK_THEME` 再测，否则永远测不出效果。

### 10.3 实施：配色 6 处

| # | 位置 | 动作 | 说明 |
|---|---|---|---|
| 1 | `~/.config/environment.d/gtk-theme.conf` | **删除**（`.bak` 留） | 全局 `GTK_THEME`，压制 `@define-color` 的主犯 |
| 2 | `~/.local/bin/nautilus` | **删除**（`.bak` 留） | 只重复套一层 `GTK_THEME`，删掉走系统 `/usr/bin/nautilus` |
| 3 | `~/.config/hypr/bindings.lua` `SUPER+E` | **改指 `"nautilus"`** | ⚠️ **连带风险**：原绑定直指被删的 wrapper，不改会按键静默失效 |
| 4 | `~/.config/omarchy/themed/gtk.css.tpl` | **新增** | GTK4 主题模板，`@define-color` 接 matugen 色（41 条） |
| 5 | `~/.config/omarchy/themed/gtk3.css.tpl` | **新增** | GTK3 主题模板，**全走显式选择器**（`@define-color` 在 GTK3 无效），见 §10.6 |
| 6 | `~/.config/omarchy/hooks/theme-set.d/gtk-colors-sync` | **新增**（可执行） | 主题渲染后同步两份：`gtk.css`→`~/.config/gtk-4.0/`、`gtk3.css`→`~/.config/gtk-3.0/` |

> **改 wrapper 前必先搜引用**：`grep -rn "<被删路径>" ~/.config/`。绑定可能直指该路径，漏查会让按键静默失效。

### 10.4 数据流（换壁纸 / 换主题都自动跟）

```
换主题或换壁纸 → matugen 取色 → colors.toml → omarchy-theme-set
   → omarchy-theme-set-templates 渲染 *.tpl → current/theme/{gtk.css, gtk3.css}
   → omarchy-hook theme-set → gtk-colors-sync → cp 到 ~/.config/gtk-4.0/gtk.css
                                              → cp 到 ~/.config/gtk-3.0/gtk.css
   → GTK4 监听该文件 → 已开窗口实时换色（无需重启应用）
```

**两处设计取舍**：

| 决策 | 原因 |
|---|---|
| hook 用 **`cp` 而非软链** | GTK 靠文件监视器盯这两个路径；换主题时 omarchy 是 `rm -rf`+`mv` 换掉整个 theme 目录，**inode 会变**，软链会失效。写成真实文件才能触发监视器、已开窗口即时换色 |
| hook 内 `sync_one` **目标文件缺失就 `return 0`** | 非 materal 主题（或模板被删）不会被清空成空白配置——宁可维持现状也不糊掉你的 GTK 外观 |
| **层级对齐 Adwaita 惯例**（不是全用一个色） | `window`=`background`（底）、`view`=`dark_background`（内容区更暗）、`headerbar`/`sidebar`/`popover`/`card`=`lighter_background`（凸起更亮）。全用一个色会让窗口丢层次 |

**模板变量语法**（`omarchy-theme-set-templates`）：`{{ key }}` 直插 · `{{ key_strip }}` 去 `#` · `{{ key_rgb }}` 转 `R,G,B` · `{{ mix A B 30% }}` 调和。
用户模板 `~/.config/omarchy/themed/*.tpl` **优先于**官方同名；产物落 `current/theme/<模板名>`；**主题自带同名文件则跳过**。
变量名出处：libadwaita 官方 CSS Variables 文档（下划线形态，本机 1.9.3 实测有效）。

### 10.5 接口字体：对齐 14px（⚠️ `font-name` 的值是 **pt**，不是 px）

`font-name` 里的数字是 **pt**，**不能当像素用**（曾误当 px，差 33%）。换算：

```
text-scaling-factor 1.1667 → gtk-xft-dpi = 114690/1024 = 112 dpi (= 96 × 1.1667)
逻辑 px = pt × dpi / 72        反解：  pt = 目标px × 72 / dpi
```

| | 改前 | 改后 |
|---|---|---|
| `gsettings org.gnome.desktop.interface font-name` | `SF Pro 12`（= 18.7px） | **`SF Pro 9`（= 14.0px）** |

与 bar 的 `shell.toml base-size=14` **精确对齐**（皆 14 逻辑 px = 22.4 物理 @scale1.6）。

- **连带影响**（`font-name` 是**系统级接口字体**）：**Ghostty 右键菜单**、**Firefox / Zen 的 chrome**（标签栏/地址栏/菜单）**一起变小**。
- **持久**：`omarchy-font-set` 只管**等宽字体族**（写 fontconfig + alacritty/kitty/ghostty/foot），**不碰 `font-name`** → 不会被覆盖。
- **DPI 本身不用动**：Hyprland `scale=1.6` + `gtk-xft-dpi=112`，且**无** `GDK_SCALE`/`GDK_DPI_SCALE`（确认无双重缩放）。

### 10.6 GTK3 应用：已处理（必须走显式选择器）

**影响面**：`xdg-desktop-portal-gtk`（**文件选择器**）、`evince`、`gnome-disk-utility`、`sushi`、`xournalpp`、`linuxqq`、chromium/zen 部分外壳。

**做法**：走同一条链路，但**另写一个模板**——因为 GTK3 里 `@define-color` 完全压不过主题（见 §10.2 对照表）：

```
~/.config/omarchy/themed/gtk3.css.tpl  →  渲染  →  current/theme/gtk3.css
   →  hook gtk-colors-sync  →  cp  →  ~/.config/gtk-3.0/gtk.css
```

**GTK3 专属的 4 个坑**（模板里逐条对应）：

| 坑 | 表现 | 解法 |
|---|---|---|
| 渐变盖不住 | Adwaita 大量用 `background-image` 画渐变 | `button` / `headerbar` / `entry` / `popover` / `notebook` 等**都要显式写 `background-image: none`**，只改 `background-color` 无效 |
| 焦点环 / 下划线是 box-shadow | Adwaita 用 `box-shadow` 画输入框焦点环、选中标签下划线（**蓝色**） | 同形覆盖：`entry:focus` 用 `box-shadow: inset 0 0 0 1px`、`notebook tab:checked` 用 `box-shadow: inset 0 -4px`；只改 `border-color` 会留下蓝环 |
| 硬编码蓝兜底 | `.gtkstyle-fallback:selected`、`.content-view .tile:selected`、树表列头 `treeview.view header button` 另有一套高优先级样式 | 单独补规则压掉（普通 `button` 规则**盖不住** `treeview.view header button` 这种组合选择器） |
| 读取路径固定 | `~/.config/gtk-3.0/gtk.css` 是硬编码路径 | **`XDG_CONFIG_HOME` 隔离对它无效** → 试错只能直接改真机（配 `env -u GTK_THEME`），别指望隔离目录 |

**验证（2026-09-15 实测基线，无 vision 也能全程做）**：

| 检查 | 命令 / 判据 |
|---|---|
| 模板渲染干净 | `grep -c "{{" ~/.local/state/omarchy/current/theme/gtk3.css` → `0` |
| hook 同步到位 | `cmp ~/.config/gtk-3.0/gtk.css ~/.local/state/omarchy/current/theme/gtk3.css` → 无输出 |
| CSS 合法 | 起 GTK3 程序，stderr **不应**有 `Theme parsing error` |
| 真上色了 | 起 GTK3 程序截图取样：`evince`（无参 = 最近文档）头部栏应为 `lighter_background`、内容区 `dark_background`。实测拿到 headerbar `(48,40,43)`=`#30282b`、内容区 `(20,13,16)`≈`#130c0f`（**差 1** 是合成取整，正常）、左上角 `(250,172,204)` ≈ accent `#feb0d2` |

> ⚠️ **取样陷阱**：`grim -g "x,y WxH"` 吃的是**逻辑坐标**，吐出来的 PNG 却是**物理像素**（本机 `scale=1.6`：875×600 的窗口出 1400×960）。用 `magick -format "%[pixel:p{X,Y}]"` 取点前把坐标乘 1.6，否则量到的是别的区域（第一次就这么量错了）。
> ⚠️ 取色前先确认该窗**没有 opacity 规则**（`~/.config/hypr/windows.lua`）：nautilus/loupe/zen 都有，取到的是叠壁纸后的混合值。

**回退**（改 `environment.d` 那步需**重启**，见 §〇）：
```
cp ~/.config/environment.d/gtk-theme.conf.bak ~/.config/environment.d/gtk-theme.conf
cp ~/.local/bin/nautilus.bak ~/.local/bin/nautilus && chmod +x ~/.local/bin/nautilus
# bindings.lua 的 SUPER+E 改回 nautilus，然后 hyprctl reload
rm ~/.config/omarchy/themed/gtk.css.tpl ~/.config/omarchy/themed/gtk3.css.tpl
rm ~/.config/omarchy/hooks/theme-set.d/gtk-colors-sync
rm ~/.config/gtk-4.0/gtk.css ~/.config/gtk-3.0/gtk.css
gsettings set org.gnome.desktop.interface font-name "SF Pro 12"
```

### 10.7 复现 / 自检

**① 链路自检**（输出两个相同颜色即正常，应始终一致）：
```bash
grep -m1 "^accent " ~/.local/state/omarchy/current/theme/colors.toml
grep -m1 accent_bg_color ~/.config/gtk-4.0/gtk.css
```
不一致 → hook 没跑，手动触发：`omarchy theme set <主题名>`。

**② 换壁纸跟随**：`omarchy theme bg next`，再跑 ① 看颜色是否变了。

**③ 截图验色**（无 vision 也能验）：
```bash
hyprctl clients -j                     # 取目标窗口 at / size（**逻辑**坐标）
grim -g "x,y WxH" out.png              # 输出却是**物理**像素（本机 scale 1.6 → 乘 1.6）
magick out.png -crop <区域> +repage -colors 3 -format %c histogram:info: | sort -rn | head
```
拿主色对照 `colors.toml` 里的 `background` / `lighter_background`。
⚠️ 窗口有 `opacity`，取色会略偏（正常）。坐标与取点的换算细则见 §10.6 的取样陷阱。

**④ 试 CSS 的标准装置**（比直接改真机干净，且能绕开单实例）：
自写最小 libadwaita 程序（`Adw.ApplicationWindow` + `HeaderBar`），用隔离配置目录启动：
```bash
XDG_CONFIG_HOME=/tmp/try env -u GTK_THEME python3 rig.py
```
**`env -u GTK_THEME` 不可省**——否则测不出任何 `@define-color` 效果（见 10.2）。

**⑤ 测试对象取舍**：
| 对象 | 说明 |
|---|---|
| nautilus | 可用，但**是单实例**——必须先确认量到的是**新进程**，否则量的是旧窗口 |
| evince | ✅ **测 GTK3 的首选**（`ldd` 确认链 `libgtk-3.so.0`；无参启动=最近文档，头部栏/内容区齐全，实测已用来验 GTK3 配色） |
| loupe | ❌ **打开图片会隐掉全部 chrome**，没有可量的界面 |
| 最小 libadwaita 程序 | ✅ 首选，无实例污染、控件齐全 |

---

## 总结

| 章 | 要点 |
|---|---|
| 〇 公共前置 | 改内建插件**必须** `omarchy plugin clone` 成 `jianlongliu.<id>`，否则 update 还原；克隆后记得手动同步 `centerAnchor`。尺寸一律走 Style token，不写魔数。**改 `environment.d` 要「重启」不是「注销」**（user manager 跨登录存活，注销清不掉） |
| 一 字号 / 图标 | 全栏字号以 clock 的 `body`(14) 为准；bar 图标套官方 `BarIconButton` + `iconComponent`，别手写宽高。右侧状态图标是**字体字形**，`omarchy font set` 别选 `Mono` 变体（否则高矮不齐），改完 `omarchy restart shell`。换 Material 图标走**替身字体**（§1.3） |
| 二 克隆实例 | keyboard-layout / system-update 是纯克隆；OSD 因 `ignore_alpha` 在全屏 surface 失效，改成卡片大小的 surface |
| 三 视觉效果 | 工作区胶囊：撑满 bar 高才垂直居中、用前景 alpha 别用 accent。浮栏四角暗角靠 `ignore_alpha=0.1` 修；阴影无解已放弃。磨砂=每层配 `ignore_alpha`（卡片 > 阈值 > scrim，scrim 可为 0）。**菜单发黑是卡片色太黑 + scrim 压暗，不关 blur；卡片色别写死在用户 shell.toml，改用户模板取 `lighter_background` 才随主题**（§3.4）；btop/yazi 浮动窗 875×600 太挤 → 脱 `floating-window` 标签自定 1280×800（§3.5） |
| 四 菜单 / 锁屏 | 头像要用**预裁好的圆形透明 PNG**（QML 里遮罩裁不圆）；锁屏走 lock-explorer 的 `lock-avatar.png` 探测路径 |
| 五 光标 | AUR 装 Bibata；`envs.lua`（子进程）和 `autostart.lua`（Hyprland 自己画的 `setcursor`）**两处都要写** |
| 六 SDDM | 复制官方主题改背景、指向 `current/background` 软链；greeter 以 sddm 用户跑，home 是 700 需 `setfacl` 放行 |
| 七 动态主题 | matugen 从壁纸取 M3 色写 `colors.toml`，再 `theme refresh` 重渲；激活边框渐变靠 `hyprland_active_border` |
| 八 字体链 | **已失效存档**：SF Mono + 苹方那条链的 conf 已删。现状 `monospace` → `GoogleSansCode Material`（见 §1.3）。机制部分（fontconfig `assign` 抢不回来）仍成立 |
| 九 flea | 别改共享的 Style（会连带 bar）；`cp -rL` 一份副本到 `~/.local/share/flea`，用 `FLEA_UI` 指过去 |
| 十 GTK 应用 | omarchy 官方**没有** gtk 模板（ghostty 等 19 个才有）→ GTK 默认只拿 `Adwaita-dark`，不跟主题。补法：**两份**主题模板（`gtk.css.tpl` 给 GTK4 用 `@define-color`；`gtk3.css.tpl` 给 GTK3 只能全用**显式选择器**）+ hook 同步到 `~/.config/gtk-4.0/` 与 `~/.config/gtk-3.0/`。**`GTK_THEME` 会压死 `@define-color`（必须先删）；`!important` 不存在；GTK3 还额外要用 `background-image: none` 和 `box-shadow` 同形覆盖才盖得住 Adwaita**。接口字体 `font-name` **是 pt 不是 px**：`SF Pro 9` = 14px，对齐 bar |

**贯穿全篇的一条准则**：任何想跟窗口视觉一致的 surface 边框，都去**镜映窗口的同源参数**（颜色取 matugen 的 active-border、宽度取 Hyprland `border_size`），别自己写一套色和宽度。
