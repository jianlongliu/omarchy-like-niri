# Omarchy 的 niri 化配置笔记（可移植版）

> 目标：把 Omarchy 的工作区切换做成 niri 风格——滚动总览(ScrollOverview) + 纵向平滑切换动画。记录完整配置、验证命令与踩坑点，可直接套用到任何 Omarchy/Hyprland 环境。
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
| 8 | （可选）nautilus 默认浮动 | 九 | 重开 nautilus 为浮动 | 删 `o.window` 行 |
| 9 | 总验证 | 七 | `configerrors` 空 + 插件加载 | 逐节回退 |

> 键盘冲突：换机器先 `hyprctl -j binds` 查 Super+Tab 等是否已被占，再决定要不要覆盖。
> 笔记本/有触控板：可额外启用第八节触控板手势（桌面机默认不启用）。

## 二、ScrollOverview 插件安装

```bash
hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git   # 用仓库默认分支即可
hyprpm update
hyprpm enable scrolloverview
```

> 插件用仓库**默认分支**即可。若插件编译/加载因 Hyprland 版本不匹配失败，用 `hyprpm add <url> <git-rev>` 锁定适配你 Hyprland 版本的提交——先用默认、失败再锁 rev。
> 验证：`hyprpm add` 还可追加 `[git rev]` 参数（见 `hyprpm --help`）。

验证已加载：`hyprctl plugins list` 应含 `Plugin scrolloverview`；`hyprpm list` 里 `scrolloverview enabled: true`。

> ⚠️ **重启后插件不会自动加载（踩坑）**：hyprpm 的 `enabled` 只是持久化"状态"，真正把插件注入 Hyprland 靠 `hyprpm reload`。重启后没人跑它，`hyprctl plugins list` 会显示 `no plugins loaded`，`plugins.lua` 里的 `plugin.scrolloverview.*` 全部报 `unknown config key`。
> **启动自加载**（`~/.config/hypr/autostart.lua`）：
> ```lua
> hl.on("hyprland.start", function()
>   hl.exec_cmd("sleep 2 && hyprpm reload")
> end)
> ```
> `sleep 2` 给 Hyprland socket 就绪时间（hyprpm reload 要调 hyprland）。此坑对**任何 hyprpm 插件**都成立。
> 诊断：`hyprctl plugins list`（实际加载）vs `hyprpm list`（enabled 状态）二者不一致 = 插件没加载 → config unknown key。即时修复 = `hyprpm reload` + `hyprctl reload`。

## 三、ScrollOverview 配置（`~/.config/hypr/plugins.lua`）

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
| `Alt + 滚轮` | 聚焦右/左窗(空间, 非循环) | `hl.dsp.focus({ direction = "r"/"l" })` |

> 原 Omarchy 默认 `SUPER + W` = Close window，此处 `hl.unbind` 挪到 `SUPER + Q` / `Alt + F4`。
> 滚轮切窗用**单 Alt**（原 Super+Alt 挪走，改绑到 Alt）。空间左右聚焦而非 `cycle_next`(Alt+Tab)，因后者**天生循环，`cyclic=false` 不生效**——滚轮是线性动作，疯狂滚会绕回打转；空间聚焦到边缘就停，不循环，适合"玩命滚"。

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

hl.unbind("SUPER + ALT + mouse_down")
hl.unbind("SUPER + ALT + mouse_up")
o.bind("ALT + mouse_down", "Focus window right", hl.dsp.focus({ direction = "r" }))
o.bind("ALT + mouse_up",   "Focus window left",  hl.dsp.focus({ direction = "l" }))
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
  if not current or current.windows == 0 then return end   -- 已在空工作区 → 停
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
  if not current or current.windows == 0 then return end
  if current.windows > 1 then
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(current.id + 1) }))
  end
end

-- 移回上一个工作区：只守规则 A(不低于工作区 1)，不受窗口数限制。
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

**关键坑：回退方向不能也卡 `windows>1`**。若窗口被推到工作区后仅剩它自己，回退再卡窗口数会**把窗口锁死回不来**。所以前进卡（停空边界）、回退只守下限。

**边界行为**：某工作区只剩这一扇窗口时，按 ↓ 不会把它推进空白工作区——这是"停在空"边界（niri 一致）。如需"独窗也能推一步"，要加状态跟踪；当前 `hl` 无按 id 查窗口数的 API，只能靠**当前工作区**窗口数判定。

**验证**：`hyprctl reload` + `hyprctl configerrors` 空；底层 `move { workspace = "2" }` 实测窗口移到新建 ws2、ws1 3→2，复原后 ws1=3。停边界的 Lua 判定无法用 hyprctl 模拟按键触发，需实按一步终验。

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

## 一句话总结

想让 Omarchy 像 niri：装 ScrollOverview(`hyprpm enable scrolloverview`)→ `plugins.lua` 配 `plugin.scrolloverview` 并**用 `hl.plugin.scrolloverview.overview("toggle all")` Lua 函数绑定 Super+Tab** → `looknfeel.lua` 打开 `workspaces` 动画并设 `style = "slidevert"` 实现纵向平滑切换 → `bindings.lua` 按上面快捷键表配好 Super+Tab/PageUp/PageDown/Super+滚轮/Super+Ctrl+↑/↓/Q/Alt+F4/Alt+滚轮；nautilus 用 `o.window(..., { float = true, opacity = ... })` 默认浮动。踩过的坑：ScrollOverview 的 dispatcher 字符串走 exec_cmd 会静默空操作；`workspaces` 动画默认关闭导致硬切；`cycle_next` 天生循环(cyclic=false 无效)要用空间聚焦；getoption 查不了动画、hyprctl dispatch 只认 Lua 表达式；查绑定要用 `hyprctl -j binds` 解析而非 grep 上下文；移动窗口到工作区用 `e+n` 只跳已打开(单区会空操作)、`+n` 会无限连环建，有界要用 `current.windows>1` 卡前进、回退只守下限。

---

## 附录 A · 本机实施差异（参考，非通用步骤）

> 以下为原部署机的实施细节与历史，仅供排查/复刻参考，不随通用教程迁移。

- **原 Hyprland 版本**：0.56.2（tag 版），默认分支 commit `f9248ab` 正常加载。换机器以你实际版本为准。
- **本机工作区指示器**：克隆 `omarchy.workspaces` → `jianlongliu.workspaces`（GNOME 45 圆点/胶囊），见 `omarchy-gnome-workspace-pill.md`。
- **本机 bar 菜单**：克隆 `omarchy.menu` → `jianlongliu.menu`（加圆形头像），见 `omarchy-lock-avatar.md`。
- **角落热区**：曾自研 Hyprland 插件 `hyprcorner`，**已删除且不恢复**，现用第三方 `abdul.hotcorners`（macOS 风格，rest pointer 触发命令，可配四角动作触发 scrolloverview 总览）。
- **历史**：曾装 `io.github.sirmenef.workspace-overview`，已移除（Super+Grave 绑定一并删除），总览只保留 scrolloverview。
- 克隆插件的命名与 centerAnchor 隐患见 `omarchy-clone-plugin-naming.md`。
