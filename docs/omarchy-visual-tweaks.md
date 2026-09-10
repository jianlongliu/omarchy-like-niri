# Omarchy bar 视觉与克隆整合笔记

> 最后核对：2026-09-11 · Omarchy 4.0.3 / Hyprland 0.56.2
> 整合原分散的本地 bar 视觉笔记（字号/对齐、克隆插件、工作区胶囊/磨砂玻璃、字体链、flea 对齐），去重后重排。相关总文档：`omarchy-nirification.md`；插件清单见 `omarchy-plugins.md`。
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

---

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

> **⚠️ 复发排查（2026-09-07 亲历）**：某次 update/refresh/theme 重置 shell.json 会把克隆踢掉——`jianlongliu.osd` 变 `disabled`、出厂 `omarchy.osd` 顶上跑全屏，OSD 又没磨砂。**快速自检**：`omarchy plugin list | grep osd`，看到 `jianlongliu.osd disabled` + `omarchy.osd enabled` 即此因。**修法**：`omarchy plugin enable jianlongliu.osd`（克隆自动 `addDisabled(omarchy.osd)`），`omarchy restart shell` 后验证 surface 变卡片（`hyprctl layers -j` 里 `omarchy-osd` 约 324×75 贴底，非 2400×1350 全屏）。克隆机制：非 first-party 的 `jianlongliu.*` 必须进 shell.json `plugins` 才启用（PluginRegistry.isEnabled 第 136-138 行），启用克隆时自动禁用源。

---

## 三、视觉效果

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

**踩过的坑**：①必须撑满 bar 高才垂直居中 ②尺寸 0.14 太细/0.48 太大/**0.28 最终** ③用前景 alpha 别用 `Color.accent`（会蓝/彩） ④无数字无外框 ⑤点击静默无 hover 放大。
**过冲回弹体感 ≈ 0**：13px 点 + 220ms 里那点 OutBack 过冲，肉眼几乎感知不到——同形态的视觉/动画天花板很低。**要更明显的"活"须换形态**（如悬停浮卡），不在点里继续调。
**GNOME 标准已回退**：GNOME 未选中缩放 0.75×、当前满尺寸 → 大小不一破坏统一，仅借用紧凑点距(`dot*0.5`≈6.5 逻辑px；GNOME 固定 5px 不随 bar 缩放)。

**调参表**：圆点 `dot`(0.28×，下限 7px) · 拉长 `expanded`(2.6×) · 间距 `spacing`(0.5×) · 空 `@0.15` · 占用 `@0.62` · 当前 `@0.9`(悬停`@1.0`) · 非当前悬停 `@0.85` · 宽动画 OutBack 220ms(over 1.2) · 色动画 160ms。

**验证**：`omarchy restart shell` 后截图核对——`grim -o "$(hyprctl monitors -j | python3 -c 'import sys,json;print(json.load(sys.stdin)[0]["name"])')" /tmp/bar.png` 再裁 bar 左放大。日志确认：`journalctl --user -n 30 | grep jianlongliu.workspaces` 应见 `Local plugin changed, reloading: jianlongliu.workspaces`，无 QML 报错。
> **下一步候选（未做）**：悬停浮卡 = 每个 ws 点 hover 弹 `PopupCard` 显示该 ws 窗口**几何线框**+标题。已探明**中低工作量、单文件**——复用 `/usr/share/omarchy/shell/Ui/PopupCard.qml`(`triggerMode:"hover"`，锚定自动避边，范本见 `services/media/BarWidget.qml:104`)，窗口数据走 `toplevels.values` 遍历 + `hyprctl clients -j`(含 address/class/title/geometry)，按 `hidden` 过滤。真像素缩略图才是中高工作量(需 portal 抓帧)，先不做。做前先 `cp Workspaces.qml` 备份。

**回退**：`disable jianlongliu.workspaces && enable omarchy.workspaces`；QML 备份 `Workspaces.qml.bak.*`。
> 与 `omarchy-nirification.md` 互补不冲突：那个管切换交互（ScrollOverview），这个管 bar 上指示器外观。

### 3.2 悬浮栏：圆角暗角修复
> 本机 bar 是第三方 `charlieras262.floating-bar`，**git clone 目录，`omarchy update` 不覆盖**，靠 `omarchy plugin update charlieras262.floating-bar` 更新（走 omarchy 通道）。⚠️ 每次更新后 blur/暗角可能变化——1.4.0 起 bar 表面改读 `Style.shellOpacity`（需装 Omablur + 系统 Style.qml 注入该行，见 §3.3 现状）。**4.0.3（2026-09-10）**：浮栏已是最新上游（`5e7dc23`）；内置 Bar.qml 新增 `PluginBarApi` + `fallbackBarWidgetRegistry` 兼容第三方完整 bar，**无需等浮栏适配**。

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

### 3.3 磨砂玻璃（Liquid Glass）恢复手册
> 状态栏/菜单/通知/OSD 所有表面的磨砂。被 `omarchy update`/`omarchy refresh hyprland` 覆盖则按此恢复。涉及 3 个 hypr 文件 + 1 个 OSD 克隆插件 + **Omablur 的 shellOpacity 4 文件系统 patch**（见下现状注，2026-09-10 已全套执行）。

> **⚠️ 现状（2026-09-06 · 4.0.3 复核 2026-09-10）**：bar 的圆角 + blur 已移交 **Omablur 插件**统一管理（`charlieras262.omablur`，bar 右侧 chip 调节，持久化 `looknfeel.lua` 标记块）。菜单/通知/OSD 等其它层的 blur 仍靠下方层规则。**shell 全表面透明度依赖系统 Style.qml 的 `shellOpacity`** —— Omablur 通过它让 bar/弹窗/通知/菜单随 blur 变 0.62 半透明。
>
> **✅ shellOpacity 4 文件 patch 已执行（2026-09-10，方案 A 全套）**：此前 4.0.3 里系统文件无 `shellOpacity`（Omablur 靠 `typeof` 防御静默降级 → blur 只看得到窗口圆角、shell 自身不透明）。按 Omablur 上游 README 手动 patch 4 个系统文件（**先备份到临时目录**）：
> 1. `/usr/share/omarchy/shell/Commons/Style.qml`：`property int gapsOut: 5` 后加一行 `property real shellOpacity: 1`
> 2. `/usr/share/omarchy/shell/Ui/KeyboardPanel.qml`：卡片 `color: Color.popups.background` → `Qt.rgba(...r, g, b, 1)`；`opacity: root.open || root.popoutSwitching ? 1.0 : 0` → `(...) * Style.shellOpacity`
> 3. `/usr/share/omarchy/shell/plugins/notifications/components/NotificationCard.qml`：`color: Color.notifications.background` → `Qt.rgba(...)` + 加 `opacity: Style.shellOpacity`
> 4. `/usr/share/omarchy/shell/plugins/menu/Menu.qml`：`color: root.background` → `Qt.rgba(...)` + 加 `opacity: Style.shellOpacity`
>
> **⚠️ 升级必复补**：`omarchy update` 覆盖这 4 个系统文件会**静默还原**——blur 时 shell 不再变透明（浮栏/弹窗/通知/菜单恢复实心）。若 blur chip 拖动只有窗口圆角变化、shell 不透明，就重打上面 4 行。**4.0.3 起 Omablur 上游已移除自动 patch 脚本**（`bf8b25d` security 提交，防 root 自动写 git 管理目录），改由用户手动，无捷径。

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
**② `looknfeel.lua` decoration.blur**：基础块写 `{ size=8, passes=5, xray=false, ... }`，但**文件末尾的 Omablur 标记块会覆盖它**（`-- BEGIN charlieras262.omablur`，写 `size=11, passes=2, new_optimizations=true, ignore_opacity=true`）。**运行时生效值 = 11 / 2**（`hyprctl getoption decoration:blur:size` 实测）。改完要么动 Omablur 的 chip，要么改那个标记块——改上面基础块没用。
> **⚠️ xray 已全局关闭（2026-09-10）**：`xray = true` → `false`。原因：xray 开启时模糊只取壁纸、忽略背后窗口，Spotlight 命令面板关闭淡出（Hyprland `layersOut` fade）时会露出"只糊壁纸"的 X 光残影。关掉后所有层/窗口的模糊都取背后真实内容（含窗口），更接近真玻璃。性能代价（xray 省的是浮动模糊开销）在 6950 XT 上可忽略。Omablur 滑块只写 `rounding/size/passes/new_optimizations/ignore_opacity`，**不写 xray**，不会被拖回去。回退：`looknfeel.lua.bak.<时间戳>`。
**③ `shell.toml`**：`[bar] background-alpha 0.5`·`[popups] 0.58`·`[menu] 0.6+scrim 0.4`·`[launcher] 0.6+scrim 0.4`·`[notifications] **0.6**`·`[tooltip] 0.8`。（通知实测 0.6，非 0.8）
**④ OSD**：`jianlongliu.osd`（§2.2 卡片小 surface，blur 只盖卡片，不需 ignore_alpha）。

**⑤ 新增 shell 层规则（2026-09-10）**：Spotlight 命令面板（`io.github.maajix.spotlight`，overlay，命名空间 `omarchy-spotlight`）。实际写在 `~/.config/hypr/apps/omarchy-shell.lua`（由 `hyprland.lua` `require` 加载）：
```lua
hl.layer_rule({ match = { namespace = "omarchy-spotlight" }, blur = true, ignore_alpha = 0.4 })
```
> 卡片 `glassBackground` alpha≈0.62、scrim≈0.25，取 `ignore_alpha=0.4` 让 scrim 不糊、只糊卡片。是否加 `xray`/`no_anim` 视视觉而定；目前靠全局 `xray=false` 消除关闭残影。

**原理**：
- Hyprland 对 layer 表面**默认不模糊**，须每层显式 `blur=true`（全局 decoration.blur.enabled 对 layer 无效）。
- XDG 窗口走全局 blur 自动对透明区模糊；但 Omarchy 给所有窗口打 `default-opacity` 标签(0.985)→看不出 blur，给 nautilus/loupe 单独降 opacity(0.88 0.82) 即透出（注册在 default/hypr/windows.lua 之后故覆盖）。
- **全屏 surface 陷阱**：菜单/通知等层都是全屏 surface，直接 `blur=true` 会整屏糊，须配 `ignore_alpha` 只模糊 alpha>阈值 区域。
- `ignore_alpha` 取值：透明底+卡片 0.5（卡片须>0.5）；scrim+卡片取两者间（polkit scrim0.5/卡1.0→0.75）。
- `omarchy-network-qr` 故意不加 blur；`omarchy-lock-preview` 保留全屏 blur；`omarchy-background` 壁纸层不碰。
- **⚠️ ignore_alpha 在 OSD 已失效(2026-08-19)**：对策=卡片小 surface（§2.2）；菜单/通知复现"全屏糊/完全不糊"先疑同因；notifications 现靠 0.5 正常先不动。
- **shell 自身（bar/弹窗/通知/菜单）的透明度**：由 `Style.shellOpacity` 统一控制（Omablur blur 开=0.62、关=1）。该 token 需手动注入系统 4 文件（见上现状注）；不注入则靠 Omablur `typeof` 防御静默降级——blur 只作用于窗口圆角，shell 表面保持不透明，**功能不崩但 blur 视觉缺失**。

**各层 alpha 备忘**：
| layer | 结构 | 卡片 alpha | scrim | ignore_alpha |
|---|---|---|---|---|
| bar | 条 | 0.5 | 无 | 无(整条糊) |
| menu/image-selector/emojis/clipboard/keyboard-panel | 全屏+卡 | 0.6 | 0.4 | 0.5 |
| notifications | 全屏+卡 | 0.8 | 无 | 0.5 |
| osd | **卡片小 surface** | 0.65 | 无 | 不需要 |
| polkit | 全屏+卡 | 1.0 | 0.5 | 0.75 |
| reminders | 全屏+卡 | 0.6 | 0.4 | 0.5 |
| spotlight | 全屏 scrim+卡 | 0.62 | 0.25 | 0.4 |
| workspace-overview | 全屏+半透明底 | 0.82 | 无 | 0.5 |
| lock-preview | 全屏锁屏 | 不透明 | — | 无 |

**约束公式**：`卡片 alpha > ignore_alpha > scrim alpha`（menu 0.6>0.5>0.4；polkit 1.0>0.75>0.5）。卡片降到 ≤ ignore_alpha → 失磨砂，需同步调低 hyprland.lua。

**调参**：壁纸更明显降 `background-alpha`；更顺滑 `passes` 6~8；更鲜艳 vibrancy 0.5~0.7；更亮 brightness。

**被覆盖信号**：磨砂消失/bar 实心→layer_rule 丢；nautilus 实心→o.window opacity 丢；菜单全屏糊→rule 丢 ignore_alpha；OSD 无磨砂/全屏糊→jianlongliu.osd 丢；bar 不透→shell.toml 丢。

**恢复步骤**：查 3 文件在否 → 旧内容在 `~/.config/hypr/*.lua.bak.*`、`shell.toml.bak.*` → 重写并验证 → 默认 hypr 配置 `/usr/share/omarchy/` 只读只能写 `~/.config/` → OSD 缺失就 clone 再改。

**验证**：`hyprctl reload && hyprctl configerrors`（须空）；肉眼（bar 磨砂、菜单只卡片糊、`notify-send` 只右上卡糊）；（可选）`grim`+`magick ... -edge 1` 比角落边缘能量（修好≈1.0、全屏糊骤降≈0）。

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
grim -o "$MON" /tmp/closed.png   # MON=你的显示器名，见 hyprctl monitors
omarchy-shell shell toggle omarchy.menu '{"menu":"root"}'; sleep 2
grim -o "$MON" /tmp/opened.png
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
     color: root.transparent ? "transparent"
       : Qt.rgba(root.background.r, root.background.g, root.background.b, 1)
     opacity: root.transparent ? 1 : (typeof Style.shellOpacity === "number" ? Style.shellOpacity : 1)
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
**回退**：`Bar.qml.bak.*` 覆盖 + `omarchy restart shell`。
**复发提醒**：`omarchy update` 或重置可能还原插件 → 用 `Bar.qml.bak.*` 重放；颜色随壁纸变是正常（同源 matugen），觉得跳脱就调 colors.toml 的 `hyprland_active_border`，别在 bar 里写死色。

**切回单色备选（五彩用腻时）**：整套镜映同源，故 bar 环 + 弹层 + **窗口激活边框一起**回单色（一致性下无法只切 bar 不切窗口；想窗口单色=§7.1 全套回退）。只需把 `colors.toml` 的 `hyprland_active_border` 从多色改回**单个 accent**：
```toml
hyprland_active_border = "rgba(ffb4a8ff)"   # 只留单色、去掉 45deg 与其余两色
```
因 `Border.borderValue` 里 `colors.length===1` → `gradient.enabled=false`，bar 环自动退回单色 accent、弹层同步。改后跑 `omarchy theme refresh`（重渲 themed hyprland.lua / shell.toml）。要回多色就改回三色串再刷新。
> 更彻底想单色全退：删掉 `materal-update` 里拼 active_border 那几行 + 从 colors.toml 删 `hyprland_active_border`（回 §7.1 之前单色 accent）。备份 `materal-update.bak.*`。

### 7.3 弹层(popup/menu)边框宽度也统一到窗口 border_size
**目标**：bar 上点开的插件浮层(时钟日历、托盘、媒体、菜单面板等)的边框，跟窗口和 bar **同一套**——颜色同源渐变(早已是)、宽度对齐 `border_size=5`。
**背景**：浮层颜色**早就同源**(全部引 `hyprland.active-border` 主题渐变)，唯独**宽度**没对齐——各容器自己 fallback 成 `Style.space(2)`≈2，肉眼比窗口/bar 的 5 细一圈。§7.2 那条"镜映窗口同源参数"的漏网区。

**根因**：浮层边框由统一容器画——
- `PopupCard`(`Ui/PopupCard.qml`)系(Tray/媒体/键盘等)走 `[popups]` section：`Border.localOrSurfaceSpec("popups","border",…, Math.max(1,Style.space(2)))`，**fallback 宽约 2px**。
- 菜单面板 `Menu.qml` 走 `[menu]` section：`Border.surfaceSpec("menu","border",…, Math.max(1,Style.space(2)))`。
两处 fallback 都偏窄且不看窗口 `border_size`。

**修复（零改源码，用户级 shell.toml，集中可逆）**：给 `~/.config/omarchy/shell.toml` 补 `border-width`，颜色/alpha 维持主题同源值：
```toml
[popups]
border-width = 5      # 对齐窗口 border_size

[menu]
border-width = 5
```
`Border.surfaceSpec` 读 `[popups] border-width`（存在则不 fallback）→ 弹层边框宽=窗口宽，颜色仍 `hyprland.active-border`。

**生效**：`omarchy restart shell`（UserShell 热重载 `userShellValues`；重启保险）。日志无 `falling back` 即好。
**回退**：删掉这两行 `border-width` 或 `cp shell.toml.bak.*` 还原 + `omarchy restart shell`。
**验证**：点开任一 bar 插件浮层，边框粗细应肉眼等同窗口/bar。
**坑**：
- 颜色`border`/alpha 是主题生成，**别**在用户 shell.toml 里覆盖它们，只补 `border-width`——避免破坏"随壁纸"。
- **此值是静态 5**：改窗口 `border_size` 后浮栏会跟(§7.2 动态 probe)，但弹层这处 shell.toml 要手动同步。将来可仿 §7.2 做运行时对齐，暂不值当。

---

## 八、全局字体链：SF Mono + 苹方 + Nerd 按字形分工

> ⚠️ **现状（2026-09-11 实测）：这条链当前【未生效】**——`fc-match monospace` 落回 **JetBrainsMono Nerd Font**，不是 SF Mono Powerline。
> 原因：`51-omarchy-body-fallback.conf` 里**只剩第一条**（拦 `monospace`），而**第二条（拦 `JetBrainsMono Nerd Font`）已于 2026-09-08 删除**。缺了第二条，第一条也拦不住（见 §8.5 机制）。
> 即 bar 正文现在实际是 **JBM 主导 + 苹方兜中文**。想真正启用这条链要按 §8.3 补回第二条，但要先接受 §8.5 的字形代价。
> 下面 8.1–8.4 是「链路成立时」的完整方案，保留备查。

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

## 总结

| 章 | 要点 |
|---|---|
| 〇 公共前置 | 改内建插件**必须** `omarchy plugin clone` 成 `jianlongliu.<id>`，否则 update 还原；克隆后记得手动同步 `centerAnchor`。尺寸一律走 Style token，不写魔数 |
| 一 字号 / 图标 | 全栏字号以 clock 的 `body`(14) 为准；bar 图标套官方 `BarIconButton` + `iconComponent`，别手写宽高 |
| 二 克隆实例 | keyboard-layout / system-update 是纯克隆；OSD 因 `ignore_alpha` 在全屏 surface 失效，改成卡片大小的 surface |
| 三 视觉效果 | 工作区胶囊：撑满 bar 高才垂直居中、用前景 alpha 别用 accent。浮栏四角暗角靠 `ignore_alpha=0.1` 修；阴影无解已放弃。磨砂=每层配 `ignore_alpha`（卡片 > 阈值 > scrim） |
| 四 菜单 / 锁屏 | 头像要用**预裁好的圆形透明 PNG**（QML 里遮罩裁不圆）；锁屏走 lock-explorer 的 `lock-avatar.png` 探测路径 |
| 五 光标 | AUR 装 Bibata；`envs.lua`（子进程）和 `autostart.lua`（Hyprland 自己画的 `setcursor`）**两处都要写** |
| 六 SDDM | 复制官方主题改背景、指向 `current/background` 软链；greeter 以 sddm 用户跑，home 是 700 需 `setfacl` 放行 |
| 七 动态主题 | matugen 从壁纸取 M3 色写 `colors.toml`，再 `theme refresh` 重渲；激活边框渐变靠 `hyprland_active_border` |
| 八 字体链 | 系统已把 `monospace` assign 成 JBM，正解是 `conf.d/51-*.conf` 再 prepend（SF Mono Powerline → 苹方 → JBM） |
| 九 flea | 别改共享的 Style（会连带 bar）；`cp -rL` 一份副本到 `~/.local/share/flea`，用 `FLEA_UI` 指过去 |

**贯穿全篇的一条准则**：任何想跟窗口视觉一致的 surface 边框，都去**镜映窗口的同源参数**（颜色取 matugen 的 active-border、宽度取 Hyprland `border_size`），别自己写一套色和宽度。
