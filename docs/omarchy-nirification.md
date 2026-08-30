# Omarchy 的 niri 化配置教程

把 Omarchy 的工作区切换改造成 niri 风格——滚动总览（ScrollOverview）+ 纵向平滑切换动画。本教程可移植，适用于任何 Omarchy/Hyprland 环境。

参考项目：[yayuuu/hyprland-scroll-overview](https://github.com/yayuuu/hyprland-scroll-overview)（niri scroll-overview 移植，基于 hyprexpo 的 scroll-overview 分支）。

## 目录

- [一、目标效果](#一目标效果)
- [二、安装 ScrollOverview 插件](#二安装-scrolloverview-插件)
- [三、配置 ScrollOverview](#三配置-scrolloverview)
- [四、触发总览（Super+Tab）](#四触发总览supertab)
- [五、纵向平滑切换动画](#五纵向平滑切换动画)
- [六、niri 化快捷键与有界工作区](#六niri-化快捷键与有界工作区)
- [七、验证命令](#七验证命令)
- [八、可选：触控板手势](#八可选触控板手势)
- [九、可选：nautilus 默认浮动](#九可选nautilus-默认浮动)
- [十、注意事项](#十注意事项)

## 安装步骤（执行顺序总览）

按序逐步执行，每步带验证与回退。**先备份**要改的 hypr 配置（`.bak.<ts>`），或记下 `omarchy refresh config hypr/<file>` 可还原。

| 步骤 | 做什么 | 章节 | 验证 | 回退 |
| --- | --- | --- | --- | --- |
| 1 | 安装 ScrollOverview 插件 | 二 | `hyprctl plugins list` 含 `scrolloverview` | `hyprpm remove scrolloverview` |
| 2 | 配 `plugins.lua` 的 `plugin.scrolloverview` | 三 | `hyprctl configerrors` 空 | 删 `plugin` 块 |
| 3 | 加 autostart 自加载（hyprpm reload） | 二 | 重启后 `hyprctl plugins list` 仍加载 | 删 `hyprland.start` 回调 |
| 4 | 开 `workspaces` 纵向动画 | 五 | `configerrors` 空；切工作区有滑动 | `enabled=false` |
| 5 | 绑 niri 化快捷键 | 六 | `hyprctl -j binds` 查到新绑定 | `hl.unbind` 那些键 |
| 6 | 加有界动态工作区函数 | 六 | 滚轮 1→2→3 停在空区 | 还原 `bindings.lua` |
| 7 | （可选）nautilus 默认浮动 | 九 | 重开 nautilus 为浮动 | 删 `o.window` 行 |
| 8 | （可选）触控板手势 | 八 | 手势触发总览 | 移除 gesture 调用 |
| 9 | 总验证 | 七 | `configerrors` 空 + 插件加载 | 逐节回退 |

> 换机器先 `hyprctl -j binds` 查 Super+Tab 等是否已被占，再决定覆盖。
> 笔记本/有触控板可启用第 8 节手势（桌面机默认不启用）。

## 一、目标效果

| 交互 | niri 风格 | Omarchy 默认 |
| --- | --- | --- |
| 打开工作区总览 | ScrollOverview（网格卡片、模糊背景） | 出厂无对应 |
| 总览里滚动切工作区 | 卡片带动画滑动切换 | 生硬瞬切 |
| 平铺下 Super+滚轮切工作区 | **纵向**滑动（slidevert） | 硬切（`workspaces` 动画默认关闭） |

## 二、安装 ScrollOverview 插件

```bash
hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git
hyprpm update
hyprpm enable scrolloverview
```

验证：`hyprctl plugins list` 应含 `Plugin scrolloverview`；`hyprpm list` 里 `scrolloverview enabled: true`。

> **插件编译失败**：若加载因 Hyprland 版本不匹配失败，用 `hyprpm add <url> <git-rev>` 锁定适配你版本的提交（先用默认分支，失败再锁 rev）。

**重启后插件自动加载**（`~/.config/hypr/autostart.lua`）：`hyprpm enable` 只是持久化状态，真正注入 Hyprland 靠 `hyprpm reload`，重启后需重跑。

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd("sleep 2 && hyprpm reload")
end)
```

> `sleep 2` 给 Hyprland socket 就绪时间（hyprpm reload 要调 hyprland）。此坑对任何 hyprpm 插件都成立。

## 三、配置 ScrollOverview

`~/.config/hypr/plugins.lua`：

```lua
hl.config({
  plugin = {
    scrolloverview = {
      gesture_distance = 300,   -- 手势"最大行程"
      scale = 0.8,              -- overview 缩放 [0.1–0.9]
      workspace_gap = 100,      -- 卡片间距(px)
      layout = "vertical",      -- vertical(竖排,niri 同款) / horizontal
      wallpaper = 2,            -- 0 仅全局 1 仅每工作区 2 两者
      blur = true,              -- 只模糊主壁纸
      shadow = { enabled = true, range = 50 },
    },
  },
})
```

> **不要写 `input` 子块**：`scroll_event_delay` / `touchpad_scroll_factor` 等在本插件版本不存在（`hyprctl getoption plugin:scrolloverview:*` 报 `no such option`），overview 内滚动/拖拽走插件默认。可用 `hyprctl getoption plugin:scrolloverview:<key>` 逐键确认版本支持的配置项。

## 四、触发总览（Super+Tab）

**必须用 Lua 函数，别用 dispatcher 字符串**（后者走 exec_cmd 会静默空操作，按了没反应）。

`~/.config/hypr/bindings.lua`：

```lua
hl.unbind("SUPER + TAB")
hl.bind("SUPER + TAB", function()
  hl.plugin.scrolloverview.overview("toggle all")
end, { description = "Scroll overview" })
```

手动测试：`hyprctl dispatch 'hl.plugin.scrolloverview.overview("toggle all")'`。

### 可用 dispatcher
- `overview(...)`：`toggle [monitor|all]` / `open|on` / `close|off` / `select`
- `navigate(left|right|up|down)`：overview 内移动选中
- `window(select|close)`：对鼠标所指窗口操作

### overview 打开时按键 submap（可选）
```lua
hl.define_submap("scrolloverview", function()
  hl.bind("left",  hl.plugin.scrolloverview.navigate("left"))
  hl.bind("right", hl.plugin.scrolloverview.navigate("right"))
  hl.bind("return", hl.plugin.scrolloverview.overview("select"))
  hl.bind("escape", hl.plugin.scrolloverview.overview("off"))
  hl.bind("mouse:272", function()
    hl.plugin.scrolloverview.overview("select")
    hl.plugin.scrolloverview.window("select")
    hl.plugin.scrolloverview.overview("off")
  end, { mouse = true })
end)
```

## 五、纵向平滑切换动画

`~/.config/hypr/looknfeel.lua`。Omarchy 默认关闭 `workspaces` 动画（切工作区硬切），打开并设为纵向：

```lua
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
```

- `style = "slidevert"`：**纵向**滑动（niri 竖排）。`slide` / `slidefade` 是横向；`popin` 弹入。
- `bezier` 可选：`default` `easeOutQuint` `easeInOutCubic` `linear` `almostLinear` `quick`。想更"流"换 `easeInOutCubic`。
- `speed` 越低越慢/平滑。

## 六、niri 化快捷键与有界工作区

### 快捷键表

| 按键 | 动作 |
| --- | --- |
| `Super + Tab` | 开/关 ScrollOverview |
| `Super + PageUp` / `PageDown` | 上一 / 下一工作区 |
| `Super + Ctrl + ↑` / `↓` | 移焦点窗口到上一 / 下一工作区（有界） |
| `Super + 滚轮` | 上一 / 下一工作区（有界动态，到空区即停） |
| `Super + Q` / `Alt + F4` | 关闭当前窗口 |
| `Alt + 滚轮` | 聚焦右 / 左窗（空间，非循环） |

原 Omarchy 默认 `SUPER + W` 是关窗，此处 `hl.unbind` 挪到 `Super + Q` / `Alt + F4`。滚轮切窗用单 `Alt`（原 Super+Alt 挪走）。

`~/.config/hypr/bindings.lua`：

```lua
hl.unbind("SUPER + TAB")
hl.bind("SUPER + TAB", function()
  hl.plugin.scrolloverview.overview("toggle all")
end, { description = "Scroll overview" })

o.bind("SUPER + PAGE_UP",   "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + PAGE_DOWN", "Next workspace",     hl.dsp.focus({ workspace = "e+1" }))

hl.unbind("SUPER + W")
o.bind("SUPER + Q",   "Close window", hl.dsp.window.close())
o.bind("ALT + F4",    "Close window", hl.dsp.window.close())

hl.unbind("SUPER + ALT + mouse_down")
hl.unbind("SUPER + ALT + mouse_up")
o.bind("ALT + mouse_down", "Focus window right", hl.dsp.focus({ direction = "r" }))
o.bind("ALT + mouse_up",   "Focus window left",  hl.dsp.focus({ direction = "l" }))
```

### 有界动态工作区（Super+滚轮）

默认 `e+1`/`e-1` 只在已有非空工作区间跳、末尾不新建。想要 niri 那种"滚到底自动建一个空区就停"（1、2 有 app → 滚到 3 后停，不续建 4、5），在 `bindings.lua` 覆盖为自定函数：

```lua
local function table_value(value, ...)
  if value == nil then return nil end
  for _, key in ipairs({ ... }) do
    local ok, item = pcall(function() return value[key] end)
    if ok and item ~= nil then return item end
  end
  return nil
end

local function current_workspace()
  local ok, monitor = pcall(function() return hl.get_monitor_at_cursor() end)
  if not ok or not monitor then
    ok, monitor = pcall(function() return hl.get_active_monitor() end)
  end
  if not ok or not monitor then return nil end
  local active = table_value(monitor, "active_workspace")
  local id = table_value(active, "id")
  if type(id) ~= "number" then return nil end
  local windows = table_value(active, "windows")
  return { id = id, windows = windows or 0 }
end

local function scroll_next_workspace()
  local current = current_workspace()
  if not current or current.windows == 0 then return end   -- 已在空区 → 停
  hl.dispatch(hl.dsp.focus({ workspace = tostring(current.id + 1) }))
end

local function scroll_prev_workspace()
  local current = current_workspace()
  if not current or current.id <= 1 then return end        -- 不低于 1
  hl.dispatch(hl.dsp.focus({ workspace = tostring(current.id - 1) }))
end

hl.unbind("SUPER + mouse_down")
hl.unbind("SUPER + mouse_up")
hl.bind("SUPER + mouse_down", scroll_next_workspace, { description = "Next workspace (create at end, stop at empty)" })
hl.bind("SUPER + mouse_up",   scroll_prev_workspace, { description = "Previous workspace" })
```

**逻辑**：前进时当前区有窗口 → `focus(当前id+1)`（Hyprland 对不存在编号自动创建），到空区后 `windows==0` 停；后退到 1 停。用 `hl.dispatch` 走真实按键路径。

### 有界移动窗口（Super+Ctrl+↑/↓）

把焦点窗口移到相邻工作区，但**禁止连环建空区**。`bindings.lua`：

```lua
local function move_next_workspace()
  local current = current_workspace()
  if not current or current.windows == 0 then return end
  if current.windows > 1 then   -- 仅当区里还有其他窗口才推出去
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(current.id + 1) }))
  end
end

local function move_prev_workspace()
  local current = current_workspace()
  if not current or current.windows == 0 then return end
  if current.id <= 1 then return end   -- 无工作区 0 / 负数
  hl.dispatch(hl.dsp.window.move({ workspace = tostring(current.id - 1) }))
end

hl.unbind("SUPER + CTRL + UP")
hl.unbind("SUPER + CTRL + DOWN")
hl.bind("SUPER + CTRL + UP",   move_prev_workspace, { description = "Move window to previous workspace (stop at empty)" })
hl.bind("SUPER + CTRL + DOWN", move_next_workspace, { description = "Move window to next workspace (stop at empty)" })
```

> **回退方向不能也卡 `windows>1`**：窗口被推走后区里只剩它自己，回退再卡窗口数会锁死回不来。所以前进卡（停空边界）、回退只守下限。

## 七、验证命令

```bash
hyprctl reload
hyprctl configerrors                    # 必须为空
hyprctl plugins list                    # 确认 scrolloverview 已加载
hyprctl dispatch 'hl.plugin.scrolloverview.overview("toggle all")'   # 手动开关 overview
```

## 八、可选：触控板手势

```lua
hl.plugin.scrolloverview.gesture({ fingers = 4, direction = "vertical", mod = "SUPER" })
hl.plugin.scrolloverview.gesture({ fingers = 3, direction = "vertical" })
hl.plugin.scrolloverview.gesture({ fingers = 3, direction = "vertical", action = "unset" })  -- 移除
```

- `fingers` 2–9（必填），`direction` up/down/left/right（必填），`mod` 按住修饰键，`action` 默认 `overview`。

## 九、可选：nautilus 默认浮动

文件管理器用浮动窗口更好拖拽/多开。`~/.config/hypr/windows.lua`：

```lua
o.window("org.gnome.Nautilus", { float = true, opacity = "0.88 0.82" })
```

- `float = true` 让窗口浮动；`opacity` 保留毛玻璃。
- 新版 Hyprland 用 `o.window(match, rules)` 助手（match 可传 class 字符串或 `{ class=..., float=... }` 表），**别用**旧 hyprlang 的 `windowrule = float`。
- `float` 是**静态效果，窗口创建时求值**：改规则后要**重开该窗口**才生效，`hyprctl reload` 不会变已平铺的旧窗口。

## 十、注意事项

- **触发总览必须用 Lua 函数**，dispatcher 字符串会静默空操作（见第四节）。
- **`getoption animation:*` 报 `no such option`** 是这版 Hyprland 的正常现象（连已生效的 `animation:windows` 也报），判断看 `configerrors` 是否为空，不是配置没生效。
- **查绑定用 `hyprctl -j binds` + python 解析 modmask/key**，别用 `grep -B`——上下文会错位，把别的绑定的 modmask/description 串过来误导。
- **移动窗口到工作区**：`hl.dsp.window.move({ workspace = "e+n" })` 只跳已打开区（单区会静默空操作）；`"+n"` 会无限连环建空区。有界要用 `current.windows > 1` 卡前进、回退只守下限。
- **`cycle_next` 天生循环**（`cyclic=false` 无效），滚轮切窗要用空间聚焦（到边缘就停）。
- **scrolloverview vs Omarchy shell 插件**是两套机制：`hyprpm` / `hyprctl plugins` vs `omarchy plugin` / `shell.json`。scrolloverview 相关 `hl.plugin.*` 报 `unknown config key` = 插件没加载（`hyprpm reload`）；shell 插件不生效先查 `omarchy plugin list`。
