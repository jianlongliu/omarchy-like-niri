# Omarchy 的 niri 化配置笔记（可移植版）

> 目标：把 Omarchy 的工作区切换做成 niri 风格——滚动总览(ScrollOverview) + 纵向平滑切换动画。记录完整配置、验证命令与踩坑点，可直接套用到任何 Omarchy/Hyprland 环境。
> 最后核对：2026-09-24 · Omarchy 4.0.4 / Hyprland 0.56.2
> 参考项目：[yayuuu/hyprland-scroll-overview](https://github.com/yayuuu/hyprland-scroll-overview)（niri scroll-overview 移植，基于 hyprexpo 的 scroll-overview 分支）。

## 一、目标效果

| 交互 | niri 风格 | Omarchy 默认 |
| --- | --- | --- |
| 打开工作区总览 | ScrollOverview（网格卡片，模糊背景） | 出厂无对应（原 `io.github.sirmenef.workspace-overview` 已移除） |
| 总览里滚动切工作区 | 卡片带动画滑动切换 | 生硬瞬切 |
| 普通平铺下 Super+滚轮切工作区 | **纵向**滑动（slidevert） | 硬切（`workspaces` 动画默认关闭） |

> Super+Tab 触发 ScrollOverview；Super+滚轮在普通平铺下纵向切换工作区（与 niri 一致）。总览只保留 scrolloverview 一套。

## 〇、执行顺序总览（AI agent / 人工按序执行）

> 按此顺序逐步完成，每步都带「验证 + 回退」。让 AI agent 执行时，逐节读对应章节再动手，做完一步验证过了再下一步。**先备份**：改动前把要改的 hypr 配置文件备份一份（`.bak.<ts>`），或记下 `omarchy refresh config hypr/<file>` 可还原。

| 步骤 | 做什么 | 章节 | 验证 | 回退 |
| --- | --- | --- | --- | --- |
| 1 | 安装 ScrollOverview 插件 | 二 | `hyprctl plugins list` 含 `scrolloverview` | `hyprpm remove scrolloverview` |
| 2 | 配 `plugins.lua` 的 `plugin.scrolloverview` | 三 | `hyprctl configerrors` 空 | 删掉 `plugin` 块 |
| 3 | 加 autostart 自加载（hyprpm reload） | 二 | 重启后 `hyprctl plugins list` 仍加载 | 删 `hyprland.start` 回调 |
| 4 | 开 `workspaces` 纵向动画 | 五 | `configerrors` 空；切工作区有滑动 | `enabled=false` |
| 5 | 绑 niri 化快捷键 | 六 | `hyprctl -j binds` 查到新绑定 | `hl.unbind` 那些键 |
| 6 | 加有界动态工作区函数（Super+滚轮） | 六 | 滚轮 1→2→3 停在空区 | 还原 `bindings.lua` |
| 7 | 加有界移窗函数（Super+Ctrl+↑/↓） | 六 | 实按：独窗不越界 | 还原 `bindings.lua` |
| 8 | 多屏：钉副屏工作区 + 加屏守卫/范围钳制 | 六 | 主屏滚不跳屏、副屏不响应 | 还原 `bindings.lua` + 删 `workspace_rule` |
| 9 | （可选）nautilus 默认浮动 | 九 | 重开 nautilus 为浮动 | 删 `o.window` 行 |
| 10 | 总验证 | 七 | `configerrors` 空 + 插件加载 | 逐节回退 |

> 第 8 步是**有边界**的做法（滚到底停）。若你要的是"每屏各自无限滚动"，原生 `r±1` 选择器更直接，但**无边界**；布局层还可开 `scrolling`。两者都见第六节「原生替代」。

> 键盘冲突：换机器先 `hyprctl -j binds` 查 Super+Tab 等是否已被占，再决定要不要覆盖。
> 笔记本/有触控板：可额外启用第八节触控板手势（桌面机默认不启用）。
> **多显示器：第 6、7 步的功能默认按单屏写，接第二块屏后必须做第 8 步**，否则 Super+滚轮会把焦点甩到另一块屏（见六「多显示器适配」）。

## 二、ScrollOverview 插件安装

```bash
hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git   # 用仓库默认分支即可
hyprpm update
hyprpm enable scrolloverview
```

> 插件用仓库**默认分支**即可。若插件编译/加载因 Hyprland 版本不匹配失败，用 `hyprpm add <url> <git-rev>` 锁定适配你 Hyprland 版本的提交——先用默认、失败再锁 rev。
> ⚠️ 但**依赖 ABI 类不匹配锁 rev 躲不过（2026-09-10 实测）**：Hyprland 包重编译只换依赖版本、commit 不变时（如 0.56.2-2 rebuild with aquamarine-0.15.0），hyprpm 仍拿过期的 `headersRoot` 快照重编，插件加载抛 `[he] Version mismatch` 且 hyprpm 打印假成功（以 `hyprctl plugins list` 为准）。完整根因+无 sudo 修复见（本地笔记存档）「09-10 事故」节：手动 make 编译 .so 顶替 `/var/cache/hyprpm/jianlongliu/hyprland-scroll-overview/` 下同名文件即可。
> 验证：`hyprpm add` 还可追加 `[git rev]` 参数（见 `hyprpm --help`）。

验证已加载：`hyprctl plugins list` 应含 `Plugin scrolloverview`；`hyprpm list` 里 `scrolloverview enabled: true`。

> ⚠️ **重启后插件不会自动加载（踩坑）**：hyprpm 的 `enabled` 只是持久化"状态"，真正把插件注入 Hyprland 靠 `hyprpm reload`。重启后没人跑它，`hyprctl plugins list` 会显示 `no plugins loaded`，`plugins.lua` 里的 `plugin.scrolloverview.*` 全部报 `unknown config key`。
> **启动自加载**（`~/.config/hypr/autostart.lua`）：
> ```lua
> hl.on("hyprland.start", function()
>   hl.exec_cmd([[
> for i in $(seq 1 50); do
>   if hyprctl ping >/dev/null 2>&1; then break; fi
>   sleep 0.2
> done
> hyprctl setcursor Bibata-Modern-Amber 30
> hyprpm reload && hyprctl reload
> ]])
> end)
> ```
> **别用固定 `sleep 2`**（早期写法）：冷启动/慢启动上会 race。改成**轮询 `hyprctl ping` 直到 socket 应答**再 reload，最多 50 次 ×0.2s 兜底。此坑对**任何 hyprpm 插件**都成立。
> 末尾 `&& hyprctl reload` 不能省，否则 gated 配置不会重放。
> 诊断：`hyprctl plugins list`（实际加载）vs `hyprpm list`（enabled 状态）二者不一致 = 插件没加载 → config unknown key。即时修复 = `hyprpm reload` + `hyprctl reload`。

## 三、ScrollOverview 配置（`~/.config/hypr/plugins.lua`）

```lua
hl.config({
  plugin = {
    scrolloverview = {
      gesture_distance = 300,   -- 手势"最大行程"
      scale = 0.7,              -- overview 缩放 [0.1–0.9]
      workspace_gap = 50,       -- 卡片间距(px)
      layout = "vertical",      -- vertical(竖排,niri 同款) / horizontal
      wallpaper = 2,            -- 0 仅全局 1 仅每工作区 2 两者
      blur = true,              -- 只模糊主壁纸
      shadow = { enabled = true, range = 50 },
    },
  },
})
```

> ⚠️ **不要写 `input` 子块**（旧版本有，本插件版本不存在）：`scroll_event_delay` / `touchpad_scroll_factor` / `scrolling_mode` / `drag_mode` / `drag_threshold` 经 `hyprctl getoption plugin:scrolloverview:*` 实测全部 `no such option`。overview 内滚动/拖拽行为走插件默认，无需配置。
> 用 `hyprctl getoption plugin:scrolloverview:<key>` 可逐键确认插件版本支持的配置项。

## 四、触发方式（⚠️ 必须是 Lua 函数，别用 dispatcher 字符串）

**正确**（`~/.config/hypr/bindings.lua`）：

```lua
hl.unbind("SUPER + TAB")
hl.bind("SUPER + TAB", function()
  hl.plugin.scrolloverview.overview("toggle all")
end, { description = "Scroll overview" })
```

**错误**(踩过)：`o.bind("SUPER + TAB", "Scroll overview", "scrolloverview:overview toggle all")` —— 它会走 `hl.dsp.exec_cmd(...)`，看似返回 ok，实际**静默空操作**(按了没反应、不报错)。

**手动调用**(测试用)：
- ✅ `hyprctl dispatch 'hl.plugin.scrolloverview.overview("toggle all")'`（能真开/关）
- ❌ `hyprctl dispatch scrolloverview:overview "toggle all"`（冒号名走 Lua 回退，报 `function arguments expected near 'toggle'`）

### 可用 dispatcher(`hl.plugin.scrolloverview.<name>`)
- `overview(...)`：`toggle [monitor|all]` / `open|on` / `close|off` / `select`
- `navigate(left|right|up|down)`：overview 内移动选中
- `window(select|close)`：对鼠标所指窗口操作

### overview 打开时的按键 submap(可选)
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

## 五、纵向平滑切换工作区(`~/.config/hypr/looknfeel.lua`)

**坑**：Omarchy 默认 `hl.animation({ leaf = "workspaces", enabled = false })`，切工作区是**硬切、零动画**(生硬/傻快)。

**解法**：
```lua
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
```
- `style = "slidevert"`：**纵向**滑动(niri 竖排)。`slide`/`slidefade` 是**横向**；`popin` 弹入。
- `bezier` 可选(Omarchy 已定义)：`default` `easeOutQuint` `easeInOutCubic` `linear` `almostLinear` `quick`。想更"流"换 `easeInOutCubic`。
- `speed` 越低越慢/平滑。
- 想滑+淡：可试 `slidefadevert`(属未验证项，改后看 `hyprctl configerrors` 是否为空)。

Super+滚轮绑定来源(`/usr/share/omarchy/default/hypr/bindings/tiling.lua`)：
`SUPER + mouse_down` → `hl.dsp.focus({ workspace = "e+1" })`；`SUPER + mouse_up` → `e-1`。方向反了就在 bindings.lua 里 `hl.unbind` 后对调。

## 六、niri 化快捷键(`~/.config/hypr/bindings.lua`)

| 按键 | 动作 | dispatcher |
| --- | --- | --- |
| `Super + Tab` | 开/关 ScrollOverview(总览, layout=vertical) | `hl.plugin.scrolloverview.overview("toggle all")` |
| `Super + PageUp` | 上一个工作区 | `hl.dsp.focus({ workspace = "e-1" })` |
| `Super + PageDown` | 下一个工作区 | `hl.dsp.focus({ workspace = "e+1" })` |
| `Super + Ctrl + ↑` | 移焦点窗口到上一个工作区（有界，不低于 1） | `move_prev_workspace()` |
| `Super + Ctrl + ↓` | 移焦点窗口到下一个工作区（有界，停在空边界） | `move_next_workspace()` |
| `Super + 滚轮` | 上一个/下一个工作区(纵向 slidevert, **有界动态**, 到空工作区即停) | `scroll_next / scroll_prev`(自定, 见下) |
| `Super + Q` | 关闭当前窗口 | `hl.dsp.window.close()` |
| `Alt + F4` | 关闭当前窗口 | `hl.dsp.window.close()` |
| `Super + Shift + 滚轮` | 聚焦右/左窗(空间, 非循环) | `hl.dsp.focus({ direction = "r"/"l" })` |

> 原 Omarchy 默认 `SUPER + W` = Close window，此处 `hl.unbind` 挪到 `SUPER + Q` / `Alt + F4`。
> 滚轮切窗绑在 **Super+Shift+滚轮**（原默认是 Super+Alt，**不是**单 Alt）。空间左右聚焦而非 `cycle_next`(Alt+Tab)，因后者**天生循环，`cyclic=false` 不生效**——滚轮是线性动作，疯狂滚会绕回打转；空间聚焦到边缘就停，不循环，适合"玩命滚"。
> ⚠️ 注意**别改绑到 Alt+滚轮**：浏览器内嵌视频播放器会把 Alt+wheel 抢去当音量，实测冲突（bindings.lua 注释有记）。
> 非 niri 化的快捷键（两种全屏、Windows 风格 `CTRL+ALT+DELETE`/`CTRL+SHIFT+ESCAPE`、`SUPER+L` 锁屏与 `SUPER+CTRL+L` 布局互换）统一记在 `omarchy-function-tweaks.md` §三。

实现(与默认同款 dispatcher，带 description 自动进速查面板)：

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

hl.unbind("SUPER + SHIFT + mouse_down")
hl.unbind("SUPER + SHIFT + mouse_up")
o.bind("SUPER + SHIFT + mouse_down", "Focus window right", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + SHIFT + mouse_up",   "Focus window left",  hl.dsp.focus({ direction = "l" }))
```

> 查询某键是否有绑定时**用 `hyprctl -j binds` + python 解析 modmask/key**，别用 `grep -B`——它的上下文会错位，把别的绑定的 modmask/description 串过来误导判断。

### 有界动态工作区（Super+滚轮）

原版 Super+滚轮用 `hl.dsp.focus({ workspace = "e+1"/"e-1" })`：`e+1` 是"下一个**空**工作区"，会在已有非空工作区间跳、**末尾不新建**。想要 niri 那种"滚到底自动进新工作区"，但**只进一个空工作区就停**（1、2 有 app → 滚到 3 后停，不续建 4、5），在 `~/.config/hypr/bindings.lua` 覆盖为自定函数：

```lua
local function table_value(value, ...)
  if value == nil then return nil end
  for _, key in ipairs({ ... }) do
    local ok, item = pcall(function() return value[key] end)
    if ok and item ~= nil then return item end
  end
  return nil
end

-- 绑定范围：主屏 DP-2 专用 1~3；便携屏钉住 6 号看片（见下文「多显示器适配」）。
-- 换机器要改这三个常量。
local MAIN_MONITOR = "DP-2"
local MAIN_WS_MIN, MAIN_WS_MAX = 1, 3

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
  return { id = id, windows = windows or 0, monitor = table_value(monitor, "name") }
end

local function scroll_next_workspace()
  local current = current_workspace()
  if not current or current.monitor ~= MAIN_MONITOR then return end  -- 非主屏不动作
  if current.windows == 0 then return end        -- 已在空工作区 → 停
  if current.id >= MAIN_WS_MAX then return end   -- 到上限 → 停，绝不越过 6 号
  hl.dispatch(hl.dsp.focus({ workspace = tostring(current.id + 1) }))
end

local function scroll_prev_workspace()
  local current = current_workspace()
  if not current or current.monitor ~= MAIN_MONITOR then return end
  if current.id <= MAIN_WS_MIN then return end   -- 不低于 1
  -- 夹回上限：从超范围的工作区往回滚，落到 MAIN_WS_MAX，而不是落到别的屏的 6（见「多显示器适配」）
  hl.dispatch(hl.dsp.focus({ workspace = tostring(math.min(current.id - 1, MAIN_WS_MAX)) }))
end

hl.unbind("SUPER + mouse_down")
hl.unbind("SUPER + mouse_up")
hl.bind("SUPER + mouse_down", scroll_next_workspace, { description = "Next workspace (create at end, stop at empty)" })
hl.bind("SUPER + mouse_up",   scroll_prev_workspace, { description = "Previous workspace" })
```

**逻辑**：前进时若当前工作区有窗口 → `focus(当前id+1)`（Hyprland 对不存在的编号自动创建），直到进入空工作区(如 3)后 `windows==0` 就停，不会续建 4、5。后退同理到 1 停。用 `hl.dispatch` 在真实按键路径执行（同 ScrollOverview 官方 Dynamic-workspaces recipe 的写法）。

**验证**：`hyprctl reload` + `hyprctl configerrors` 为空；在 1、2 有 app 时滚轮 1→2→3 停。
**回退**：备份 `~/.config/hypr/bindings.lua.bak.scroll.<ts>`，或 `omarchy refresh config hypr/bindings.lua`。

### 有界移动窗口到相邻工作区（Super+Ctrl+Up/Down）

把焦点窗口移到上一个/下一个工作区，但**禁止连环建空工作区**（同滚轮滚动一个哲学）。踩坑与实现都在 `~/.config/hypr/bindings.lua`。

**踩坑（两个都会"按不出来/按过头"）：**
- `hl.dsp.window.move({ workspace = "e+1" })`：`e+n` = 跳到**已打开**工作区。只有 1 个工作区时 → 没有下一个已打开工作区可移 → **静默空操作**，窗口纹丝不动。
- `hl.dsp.window.move({ workspace = "+1" })`：`+n` = 相对编号，会**自动建**下一个编号工作区。连续按会 1→2→3→4 … **无限连环建空工作区**。
- 结论：`e+n` 不建、`+n` 无限建 → 都要自定 Lua 函数做"停在空边界"。

**实现（有界，跟 Super+滚轮同款模式）：**
```lua
-- 移到下一个工作区：仅当当前工作区还有其他窗口(windows>1)才推出去；
-- 移过去后窗口成了该区唯一窗口 → 停，不会连环建 3、4、5。
local function move_next_workspace()
  local current = current_workspace()
  if not current or current.monitor ~= MAIN_MONITOR or current.windows == 0 then return end
  if current.windows > 1 and current.id < MAIN_WS_MAX then
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(current.id + 1) }))
  end
end

-- 移回上一个工作区：只守下限，不受窗口数限制（否则独窗会被锁死回不来）。
local function move_prev_workspace()
  local current = current_workspace()
  if not current or current.monitor ~= MAIN_MONITOR or current.windows == 0 then return end
  if current.id <= MAIN_WS_MIN then return end   -- 无工作区 0 / 负数
  -- 与 scroll_prev 同样夹回范围，避免把窗口甩到另一块屏
  hl.dispatch(hl.dsp.window.move({ workspace = tostring(math.min(current.id - 1, MAIN_WS_MAX)) }))
end

hl.unbind("SUPER + CTRL + UP")
hl.unbind("SUPER + CTRL + DOWN")
hl.bind("SUPER + CTRL + UP",   move_prev_workspace, { description = "Move window to previous workspace (stop at empty)" })
hl.bind("SUPER + CTRL + DOWN", move_next_workspace, { description = "Move window to next workspace (stop at empty)" })
```

**关键坑：回退方向不能也卡 `windows>1`**。若窗口被推到工作区后仅剩它自己，回退再卡窗口数会**把窗口锁死回不来**。所以前进卡（停空边界）、回退只守下限。

**边界行为**：某工作区只剩这一扇窗口时，按 ↓ 不会把它推进空白工作区——这是"停在空"边界（niri 一致）。如需"独窗也能推一步"，要加状态跟踪；当前 `hl` 无按 id 查窗口数的 API，只能靠**当前工作区**窗口数判定。

**验证**：`hyprctl reload` + `hyprctl configerrors` 空；底层 `move { workspace = "2" }` 实测窗口移到新建 ws2、ws1 3→2，复原后 ws1=3。停边界的 Lua 判定无法用 hyprctl 模拟按键触发，需实按一步终验。

### 多显示器适配（⚠️ 单屏配置接第二块屏后必修）

**症状**：接上第二块屏后 Super+滚轮"失效"——主屏工作区不换、焦点被甩到另一块屏，光标没动所以反复同一个结果，看着像卡死。

**根因三层**（实测坐实）：

| 层 | 情况 |
| --- | --- |
| Hyprland | 工作区 ID **全局唯一**且**绑定在某块屏上**（不是"每屏一套 1/2/3"，那是 niri）。当时 `ws1→DP-2`、`ws2→HDMI-A-1` |
| `focus({workspace=N})` 语义 | 是「**去 N 所在的那块屏**」，不是「在当前屏切到 N」。单屏两者等价所以看不出，双屏即跨屏跳 |
| 本机代码 | 自写版本用裸 `current.id + 1`，没带显示器判断 |

**这事不怪插件**：ScrollOverview 作者官方 recipe（`docs/wiki/Dynamic-workspaces.md`）**是按显示器过滤工作区的**（`table_value(workspace,"monitor") == monitor`）。是本机当初没照它写。omarchy 出厂默认 `focus({workspace="e+1"})` 实测**也跨屏跳**（便携屏 ws6 上滚 → 跑到主屏 ws1），同样不可依赖。

**做法：分段 + 屏守卫**（不做"每屏独立编号"）

| 屏 | 工作区 |
| --- | --- |
| 主屏 DP-2 | 专用 **1~3**，滚轮/移窗只在这段内动 |
| 便携屏 | 钉 **6** 号专用于看片，滚轮完全不响应 |

- 不用「每屏各自 1/2/3」的做法：数字工作区全局唯一，真按"每屏一套数字"去配会打断 `SUPER+1~0` 及其 SHIFT / SHIFT+ALT 变体、工作区指示器胶囊的按 id 排序、以及 `SUPER+SHIFT+ALT+方向` 移屏手势。**动态工作区必须自建、不能用全局数字**时，正解是命名工作区（`hl.workspace_rule({ workspace = "name:video", monitor = "HDMI-A-1" })`，实测接受），不是给每屏硬凑同一批数字。
- ⚠️ 上一条不代表"多屏 niri 化只能靠这套分段"——**Hyprland 原生就有相对本屏的选择器 `r`**，见下节。

**两处改动**：
1. `~/.config/hypr/monitors.lua` 钉住便携屏的工作区：
   ```lua
   hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1" })
   ```
2. `~/.config/hypr/bindings.lua`：`current_workspace()` 多返回 `monitor` 字段；四个函数（scroll_next/prev、move_next/prev）统一加 `current.monitor ~= MAIN_MONITOR` 早退 + 范围钳制（代码见上两段）。

**踩过的 bug（往回滚漏了上限）**：第一版只给 `scroll_next` 封了 `MAIN_WS_MAX`，`scroll_prev` 仅守 `id > 1`。于是在主屏上开了超范围工作区（当时上限是 5，开了 7 号）后往回滚 → 目标 6 → **6 钉在便携屏 → 又跳屏**（实测焦点确实跳走）。修法：`math.min(current.id - 1, MAIN_WS_MAX)` 夹回上限。`move_prev_workspace` 同病同治。**教训：单向封边界不够，反方向也要夹**。

**改完必做：清掉副屏当前那个空工作区**。空工作区回收规则（实测）：

| 情况 | 结果 |
| --- | --- |
| 是某屏**当前**的工作区，即使为空 | **保留** |
| 非当前的空工作区 | **自动回收** |

若副屏停在空的 ws2，滚轮第一次 `focus(2)` 依旧跳屏 → 把副屏切到目标工作区（如 focus ws6）让旧空工作区自然回收，或 `focus(该ws)` + `hl.dsp.workspace.move({ monitor = "DP-2" })` 搬回主屏。

**验证**：`hyprctl reload` + `hyprctl configerrors` 空；主屏滚 1→2→3 停在 3；超出范围的工作区（如 ws5）往回滚被夹回 3 且 `focused` 仍在 DP-2；光标在便携屏时滚轮无反应。**别用 `hyprctl dispatch movecursor` 验证光标**（本机失效，连续两次返回同一坐标）。
**回退**：还原 `~/.config/hypr/bindings.lua`，并删掉 `monitors.lua` 里的 `workspace_rule` 行。

### 原生替代：`r` 相对选择器（每屏独立切工作区）

**上面那套分段不是唯一解——Hyprland 原生就有「相对本屏」的工作区选择器。**

```lua
hl.dispatch(hl.dsp.focus({ workspace = "r+1" }))   -- 本屏下一个
hl.dispatch(hl.dsp.focus({ workspace = "r-1" }))   -- 本屏上一个
```

**是内置选择器、不是巧合**：二进制含报错串 `Relative workspace on no mon!`（与 `special:`、`Invalid workspace` 同族），即该选择器**必须有 monitor 才能解析**。

实测行为（出发时主屏段为 1~3、便携屏在 ws6）：

| 出发 | 操作 | 结果 |
| --- | --- | --- |
| 主屏 ws1 | `r+1` | → ws2，**仍在本屏** |
| 主屏 ws1 | `r-1` | **原地不动**（不跨屏、不变负数） |
| 便携屏 ws6 | `r+1` | → ws7，**在本屏新建** |
| 便携屏 ws6 | `r-1` ×4 | → ws5 → ws4 → ws3 → ws2，**全在便携屏新建** |
| 便携屏 ws6（主屏已有 ws7） | `r+1` | **不抢 ws7**，在本屏新建 **ws8** |
| 便携屏 ws2（主屏的 ws1 有窗口） | `r-1` | **原地不动**，不跨屏也不抢 |
| 对照：`e+1` | — | **跨屏跳**（不可依赖） |

**三条已坐实**：
1. **绝不跨屏** —— 全程实测焦点都留在出发那块屏。
2. **不抢别屏已有的号** —— 主屏有 ws7 时，便携屏 `r+1` 另建 ws8；目标号被别屏占着且有窗口时，干脆不动。
3. **到边界就停** —— 主屏 `r-1` 在 ws1 不动（不会跑到 0/负数，也不跨屏）。

**⚠️ 真正的限制：编号仍全局唯一。** 上表第 4 行就是证据——便携屏从 6 往回滚，**吃掉了 5、4、3、2 这些号**（3、2 本在主屏保留段内），且这些工作区都**建在便携屏上**。后果：若之后主屏想用 ws3，`focus({workspace="3"})` 会跑到**便携屏**去。所以 `r` 是"用相对数模拟每屏独立"，**不是真·独立命名空间**（niri 才是）。

**编号挑选规律**（实测推断，**未穷尽验证**）：沿方向找下一个「空闲 or 属于本屏」的号；遇到属于别屏的号就跳过；到 1 为止不再往下。上面第 5、6、8 行都符合这个模型，但只测了这几个点，别当定论。

**与 `e+1` 的区别**：`e` = 相对**全局**编号（会跨屏）；`r` = 相对**本屏**（不跨屏）。

> 本机为何仍用分段而不是 `r`：分段**有边界**（滚到底停、不无限造号），且用户要的就是"便携屏完全不响应滚轮"。`r` 适合"每屏各自无限滚动"那种需求——但要接受上面那个"吃号"的问题。

### 列式滚动布局（`scrolling`，hyprscroller 已上游化）

**`hyprscroller` 不再是外挂插件**——已并入主线。本机 0.56.2 二进制含 `Layout::Tiled::CScrollingAlgorithm`，官方 wiki 有独立页（`Configuring/Layouts/Scrolling-Layout/`，"windows get positioned on an infinitely growing tape"）。

```lua
hl.config({ general = { layout = "scrolling" } })
```

> omarchy **已经为它铺好路**：① `~/.config/hypr/looknfeel.lua` 顶部注释区有现成的 `layout = "scrolling"` 示例（写着 "Change to niri-like side-scrolling layout"），取消注释即可；② 出厂默认 `/usr/share/omarchy/default/hypr/looknfeel.lua` 里**已预调** `scrolling = { column_width = 0.49 }`（≈半屏减间隙，正好两列并排）。所以本机 `hyprctl getoption scrolling:column_width` 读到的是 **0.49**（omarchy 设的），不是上游文档写的默认值 0.5。

配置块 `scrolling`（活动值可直接读：`hyprctl getoption scrolling:<key>`）：

| 键 | 上游默认 | 说明 |
| --- | --- | --- |
| `column_width` | 0.5（**本机 0.49**，omarchy 预调） | 列宽 |
| `direction` | right | 新窗口出现/滚动方向 |
| `focus_fit_method` | 1 | 0=居中，1=适配 |
| `follow_focus` | true | 聚焦时自动滚入视野 |
| `follow_min_visible` | 0.4 | 聚焦跟随要求的可见比例 |
| `wrap_focus` / `wrap_swapcol` | true | 首尾环绕 |
| `fullscreen_on_one_column` | true | 单列占满屏 |

按工作区覆盖：`hl.workspace_rule({ workspace = "2", layout_opts = { direction = "right" } })`；窗口规则 `scrolling_width`；消息 `hl.dsp.layout("move +col" | "swapcol l" | "fit active" | "focus l" | "promote" | "consume" | "expel")`。

⚠️ **本机未启用、未实测**（仅确认二进制 + 文档存在）。启用会**改变全局布局**，是大改动，动前先备份并准备回退。

## 七、验证命令

```bash
hyprctl reload                          # 重载配置，应输出 ok
hyprctl configerrors                    # 必须为空
hyprctl plugins list                    # 确认 scrolloverview 已加载
hyprctl dispatch 'hl.plugin.scrolloverview.overview("toggle all")'   # 手动开关 overview
```

**注意**：新版 Hyprland 的 `hyprctl getoption animation:*` 一律报 `no such option`(连已生效的 `animation:windows` 也报)——**不是配置没生效**，判断看 `configerrors` 为空即可。

## 八、niri 式触控板手势(可选)

```lua
hl.plugin.scrolloverview.gesture({ fingers = 4, direction = "vertical", mod = "SUPER" })
hl.plugin.scrolloverview.gesture({ fingers = 3, direction = "vertical" })
hl.plugin.scrolloverview.gesture({ fingers = 3, direction = "vertical", action = "unset" })  -- 移除
```
- `fingers` 2–9(必填)，`direction` up/down/left/right(必填)，`mod` 按住修饰键，`action` 默认 `overview`。

## 九、nautilus 默认浮动（`~/.config/hypr/windows.lua`）

文件管理器用浮动窗口更好拖拽/多开；class 是 `org.gnome.Nautilus`（用 `hyprctl clients` 可查当前窗口 class）。

```lua
o.window("org.gnome.Nautilus", { float = true, opacity = "0.88 0.82" })
```

- 第二参是**效果表**，`float = true` 让窗口浮动；`opacity` 保留原有的毛玻璃。
- 新版 Hyprland 已转 Lua：规则用 `o.window(match, rules)` 助手，match 可传 class 字符串或 `{ class=..., float=... }` 表。**别用**旧 hyprlang 的 `windowrule = float`。
- `float` 属**静态效果，窗口创建时求值**：`hyprctl reload` 不会把已平铺的旧窗口变成浮动，**重开该窗口才会浮动**。所以改完规则要新开一次才生效。

## 十、插件职责区分（scrolloverview vs Omarchy shell 插件）

scrolloverview 是 **Hyprland 原生插件**（yayuuu/hyprland-scroll-overview，由 `hyprpm` 管理），**不是** Omarchy shell 插件，判定/加载方式完全不同：

| 维度 | scrolloverview | Omarchy shell 插件 |
| --- | --- | --- |
| 管理机制 | `hyprpm` / `hyprctl plugins` | `omarchy plugin` / `shell.json` |
| 加载方式 | `hyprpm reload`（重启不自动，需 autostart.lua） | `omarchy restart shell` / rescan |
| 典型例子 | 总览网格卡片 | bar widget、菜单、OSD |

区分不清时的典型症状：scrolloverview 相关 `hl.plugin.*` 报 `unknown config key` = 插件没加载（`hyprpm reload`）；而 shell 插件不生效先查 `omarchy plugin list` 状态和是否被 update 覆盖。

> 若 bar 上同时有「工作区指示器」和 scrolloverview：二者互补不冲突——指示器只做外观，scrolloverview 只做切换交互。

## 总结

**要做四件事**：

1. **装插件** — `hyprpm add <url>` → `hyprpm enable scrolloverview`。注意重启后插件不会自动加载，要靠在 `autostart.lua` 里 `hyprpm reload`（详见第二节）。
2. **配插件** — 在 `plugins.lua` 写 `plugin.scrolloverview`，外面套一层 `if hl.plugin.scrolloverview ~= nil` 守卫（见第五节，否则每次开机闪 "unknown config key"）。
3. **开纵向动画** — `looknfeel.lua` 里把 `workspaces` 动画打开、`style = "slidevert"`（默认关着，所以现在是硬切）。
4. **配键位** — `bindings.lua` 按第六节的表配好 Super+Tab / PageUp / PageDown / Super+滚轮 / Super+Ctrl+↑↓ 等。

**最容易踩的七个坑**：

1. **触发总览必须用 Lua 函数**：`hl.plugin.scrolloverview.overview("toggle all")`。写成字符串 `"scrolloverview:overview toggle all"` 会走 `exec_cmd`，看着像成功，实际按了毫无反应。
2. `workspaces` 动画默认关闭 —— 这就是切工作区"傻快"的原因。
3. `cycle_next` 天生循环（`cyclic=false` 不生效），所以滚轮切窗用**空间方向聚焦**，滚到边缘就停。
4. `hyprctl getoption animation:*` 查不到动画、`hyprctl dispatch` 只认 Lua 表达式 —— 都是这版的正常现象，别当故障。
5. 查某个键有没被占用，用 `hyprctl -j binds` 解析，**别用 `grep -B`**（上下文会串行，看串）。
6. 移窗到工作区：`e+n` 只跳已打开的（只有一个工作区时静默无效）、`+n` 会无限连环建空工作区。要"停在空边界"得自写 Lua 判断 —— 前进卡窗口数、回退只守下限。
7. **多屏会废掉第 6 条那套**：Hyprland 工作区 ID 全局唯一且绑在各自屏上，`focus({workspace=N})` 是"去 N 所在的屏"。所以接第二块屏后必须给绑定加**屏守卫 + 范围钳制**（第六节「多显示器适配」），否则焦点乱跳。**原生出路**：`focus({workspace="r+1"/"r-1"})` = 相对本屏、不跨屏（但无边界）；布局层则有已上游化的 `scrolling`。

---

## 附录 A · 本机实施差异（参考，非通用步骤）

> 以下为原部署机的实施细节与历史，仅供排查/复刻参考，不随通用教程迁移。

- **原 Hyprland 版本**：0.56.2（tag 版）。插件仓库 `hyprland-scroll-overview`(yayuuu) 当时 commit `5e96ae20ec73`（`/var/cache/hyprpm/jianlongliu/hyprland-scroll-overview/state.toml` 可查）。换机器以你实际版本为准。
- **本机多屏选择**：用**分段 + 屏守卫**（主屏 `MAIN_MONITOR="DP-2"`、`MAIN_WS_MIN/MAX=1/3`；便携屏 `HDMI-A-1` 钉 ws6 看片），**没用**原生的 `r±1`——因为要"有边界 + 副屏完全不响应"。原生 `r` 与 `scrolling` 布局本机**均未启用**。
- **本机工作区指示器**：克隆 `omarchy.workspaces` → `jianlongliu.workspaces`（GNOME 45 圆点/胶囊），见 `omarchy-visual-tweaks.md` §3.1。
- **本机 bar 菜单**：出厂 `omarchy.menu`（面板仍由 `keepLoaded` 挂载，apps 正常），bar 上的按钮换成自建插件 `jianlongliu.arch-logo`（Arch logo 染成前景色），见 `omarchy-visual-tweaks.md` §4.1。
- **角落热区**：曾自研 Hyprland 插件 `hyprcorner`，**已删除且不恢复**，现用第三方 `abdul.hotcorners`（macOS 风格，rest pointer 触发命令，可配四角动作触发 scrolloverview 总览）。
- **历史**：曾装 `io.github.sirmenef.workspace-overview`，已移除（Super+Grave 绑定一并删除），总览只保留 scrolloverview。
- 克隆插件的命名与 centerAnchor 隐患见 `omarchy-visual-tweaks.md` 〇(公共前置)与 §2。
- **通知/勿扰**：系统 `omarchy.notifications` 启用，bar 中央 `jianlongliu.indicators` 一排 5 颗，其 Dnd 铃铛直接绑系统通知服务做唯一勿扰入口。
- **bar 中央 indicators 字号**：6 个 indicator 字号统一 `Style.bar.iconFont`（原基类缩到 caption 偏小），见 `omarchy-visual-tweaks.md` §1；克隆插件清单见 `omarchy-plugins.md`。
