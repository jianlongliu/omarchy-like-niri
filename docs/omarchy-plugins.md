# Omarchy 本机插件参考

> 更新：2026-09-11 · 系统：Omarchy 4.0.3 / Hyprland 0.56.2
> 作用：记录本机**主动安装/克隆且当前启用**的 Omarchy shell 插件清单、目录结构与常用管理命令。此文档按真实 `shell.json` + `omarchy plugin list` 同步。系统自带的 first-party `omarchy.*` 为只读内置，禁用/移除项均不在此文档。
> 注意：niri 化的 scrolloverview 是 **Hyprland 原生插件**（`hyprpm` 管理），**不在此文档**（Omarchy shell 插件）范围内，详见 `omarchy-nirification.md`。

## 一、插件管理常用命令

### ⚠️ 改这份文档前先核对（AI agent 必做）

本文件的 **§四 bar 布局 / §五 插件清单 / §六 shell.json 关键段** 是抄来的快照，会漂移。**每次改动本文件前，先跑下面三条把真实状态打出来，以命令输出为准，别照旧文改**：

```bash
omarchy plugin list --json | python3 -c "import sys,json;[print(p['id'],'enabled' if p['enabled'] else 'disabled','first-party' if p['firstParty'] else 'third-party','clone-of='+p['clonedFrom'] if p['clonedFrom'] else '',sep='\t') for p in sorted(json.load(sys.stdin),key=lambda x:x['id'])]"
python3 -c 'import json, os;d=json.load(open(os.path.expanduser("~/.config/omarchy/shell.json")));[print(k.upper(),[w.get("id") if isinstance(w,dict) else w for w in d["bar"]["layout"].get(k,[])]) for k in ("left","center","right")]'
python3 -c 'import json, os;d=json.load(open(os.path.expanduser("~/.config/omarchy/shell.json")));print({k:d.get(k) for k in ("disabledPlugins","cloneSourceRestores","idle")});print(d["bar"])'
```

核对要点：
- **bar 布局**：三段必须逐项对得上（含顺序）。`omarchy.osd` vs `jianlongliu.osd` 这类**差一个前缀**的最容易抄错。
- **§五 清单**：`enabled` 与文档标注一致；已卸载的插件不许留在表里；已装未启用的要在表外单独注明。
- **§六**：`disabledPlugins` / `cloneSourceRestores` 逐字对；启用了克隆时源插件会自动进 disabled，属正常。

```bash
omarchy plugin list                          # 列出全部已发现插件
omarchy plugin list --json                   # 机器可读
omarchy plugin add <git-url> [--enable]      # 从 git 添加第三方插件
omarchy plugin clone <source-id> [--edit]    # 克隆内置插件到用户目录(可编辑,可存续更新)
omarchy plugin enable <id> [placement]       # 启用插件
omarchy plugin disable <id>                  # 禁用插件
omarchy plugin remove [id] [--yes]           # 移除已安装插件
omarchy plugin update [id] [--yes]           # 更新 git 管理的插件
omarchy plugin validate <plugin-folder>      # 按 manifest schema 校验插件目录
```

### Bar 布局调整

```bash
omarchy bar move <widget-id> --section left|center|right   # 移动 bar 控件
omarchy restart shell      # 重启 shell(改动未生效时用)
omarchy refresh shell      # 恢复默认 shell 配置(自动备份)
```

## 二、目录结构

| 位置                                  | 说明                         |
| ----------------------------------- | -------------------------- |
| `~/.config/omarchy/shell.json`      | 用户覆盖:bar 布局、插件、idle(改后热重载) |
| `~/.config/omarchy/plugins/<id>/`   | **用户自有/第三方插件**(可编辑,存续更新)   |
| `/usr/share/omarchy/shell/plugins/` | **只读**内置插件(勿改,更新会被覆盖)      |

⚠️ 改内置插件前先 `omarchy plugin clone <id>` 再编辑克隆版,不要动 `/usr/share/omarchy/`。

## 三、bar 用 `charlieras262.floating-bar`（克隆自 omarchy.bar）

> `bar.id = "charlieras262.floating-bar"`，即 Omarchy 默认 bar 已被换成 user 克隆版；原 `omarchy.bar` 状态为 disabled。

## 四、Bar 布局（`shell.json` 的 `bar.layout`，只列你装的控件）

> `bar.id = charlieras262.floating-bar`（克隆自 `omarchy.bar`），`centerAnchor = omarchy.clock`。内置控件（`omarchy.weather`/`power`/`media`/`tray`/`network` 等）未逐一列出；`omarchy.indicators` 已于 2026-09-06 克隆为 `jianlongliu.indicators`（见下）。

**left**：`jianlongliu.arch-logo` → `jianlongliu.workspaces` → `io.github.sahzudin.omarchy-screenshot-manager` → `omarchy.active-window` → `meviusisback.ai-subs`

> bar 最左是**自建插件** `jianlongliu.arch-logo`（Arch logo 染成前景色），点击 toggle 出厂的 `omarchy.menu`。出厂菜单虽不在 bar 上，但靠 `keepLoaded` **面板仍常驻挂载**，apps 正常。
> ⚠️ 因此 `omarchy plugin list` 会把 `omarchy.menu` 标成 `DISABLED`——那栏按 bar 布局算，**不是真禁用**（验证：截图开关差分）。做法见 `omarchy-visual-tweaks.md` §4.1。

### 4.0.3 菜单 Apps 分类为空的根因（一句话）

4.0.3 把插件注入从「直接塞 host shell」改成窄代理 `PluginShellApi`，而该 scoped 代理对**一切第三方菜单**（含官方 clone、含无 clonedFrom 的非克隆插件）的 `appLibrary` 运行时为 `null` → `mergeAppRows()` 静默返回 → Apps 空。**出厂 first-party 菜单直连 host shell，不受影响**——所以现在用出厂菜单，apps 正常。

> 已绕开（方案 A）。**未修根因**；要根治（报上游）需改 shell.qml 的 `manifestHasKind` 取值时机。完整证据链、候选修法、回归清单见 本机归档笔记（未随本仓库发布）。

**center**（锚定 `omarchy.clock` 居中）：`jianlongliu.indicators` → `omarchy.spacer`(16px，隔离 indicators↔CPU) → `coding-sparrow.systempulse` → `omarchy.clock` → `jianlongliu.keyboard-layout` → `omarchy.weather` → `omarchy.power` → `omarchy.spacer` → `omarchy.media` → `jianlongliu.system-update`

> 系统通知已启用（`omarchy.notifications`），勿扰由 `jianlongliu.indicators` 的 Dnd 铃铛体现（直接绑系统服务）。

**right**：`omarchy.agents` → `srozen.ufw` → `omarchy.microphone` → `io.github.majesticio.clipboard-button` → `charlieras262.omablur` → `jrmmhm.pocket` → `omarchy.tray`(pinned/hidden) → `ronald.input-sources` → `omarchy.bluetooth` → `omarchy.network` → `omarchy.audio` → `omarchy.monitor` → `omarchy-system-menu`

## 五、非 first-party 插件清单

> 含克隆自 first-party 的 `jianlongliu.*` / `charlieras262.*`；原 first-party 只读在 `/usr/share/omarchy/`。**表中已标注当前 disabled 的几个**（留档原因，勿当启用项）。

| 插件 ID | 名称 | 类型 | 备注 |
| --- | --- | --- | --- |
| `charlieras262.floating-bar` | Floating Bar | bar | 第三方浮动栏（克隆风格，`bar.id`） |
| `charlieras262.omablur` | Omablur | bar-widget | **接管 bar 圆角+blur**，右侧 chip 调节（2026-09-06） |
| `jianlongliu.indicators` | My Indicators | bar-widget | **克隆自 omarchy.indicators**（上游现位于 `bar/widgets/`）；6 图标字号统一 `Style.bar.iconFont`；Dnd 绑系统通知 |
| `jianlongliu.keyboard-layout` | My Keyboard layout | bar-widget | **克隆自 omarchy.keyboard-layout**（上游现位于 `bar/widgets/`） |
| `jianlongliu.arch-logo` | Arch Logo Menu | bar-widget | **自建、非克隆**（不带 `clonedFrom`，故不连累源插件）；Arch logo 染成前景色，点击 toggle 出厂 `omarchy.menu`。做法 + 两个坑见 `omarchy-visual-tweaks.md` §4.1 |
| `jianlongliu.menu` | ~~My Omarchy menu~~ | menu,bar-widget | **已移除**（目录改名 `.jianlongliu.menu.removed-*`）：克隆自 omarchy.menu。**为什么菜单不能克隆**：克隆带非 `bar-widget` kind 的插件会自动禁用源插件（`PluginRegistry.qml:548`，克隆即替代）→ 只剩克隆那份面板，而它的 Apps 分类因 scoped 注入缺陷是空的。禁用克隆可 `restoreCloneSource` 还原 |
| `jianlongliu.osd` | My On-screen display | panel | **克隆自 omarchy.osd**，卡片式小 surface（绕全屏 `ignore_alpha` 失效）；出厂 `omarchy.osd` 已 disabled |
| `jianlongliu.system-update` | My Omarchy update | bar-widget | **克隆自 omarchy.system-update**（上游现位于 `bar/widgets/`） |
| `jianlongliu.workspaces` | My Workspaces | bar-widget | **克隆自 omarchy.workspaces**（上游现位于 `bar/widgets/`），GNOME 45 圆点/胶囊指示器；2026-09-10 修 hovered undefined 警告（补丁清单见 §8.1） |
| `io.github.sirjul1337.lock-explorer` | Lock Screen Explorer | service,overlay | **克隆自 omarchy.lock**，design=split；头像走 `lock-avatar.png`（2026-09-06 已合上游新版）；2026-09-10 已跑 `plymouth/previews.sh` 生成 boot 预览图（启动日志判读见 §8.2） |
| `coding-sparrow.systempulse` | System Pulse | bar-widget | CPU/状态 |
| `andreconde.quick-look` | Quick Look | overlay | 快速预览 |
| `io.github.jonhenshaw.voxtype-prism` | Voxtype Prism | service,panel | 语音 |
| `io.github.lijiawei0305-pixel.mihomo` | Mihomo | service,bar-widget | 代理；**当前 disabled**（bar 未挂载）。本地 svc null 判空防御补丁（清单见 §8.1） |
| `io.github.sahzudin.omarchy-screenshot-manager` | Screenshot Manager | bar-widget | 截图管理 |
| `io.github.majesticio.clipboard-button` | Clipboard Button | bar-widget | 剪贴板 |
| `srozen.ufw` | Firewall | bar-widget | ufw 防火墙 |
| `ronald.input-sources` | Input Sources | bar-widget | 输入源 |
| `jrmmhm.pocket` | Pocket | bar-widget | 收纳组 |
| `omarchy-system-menu` | System Menu Button | bar-widget | 系统菜单按钮 |
| `meviusisback.ai-subs` | AI Subs | bar-widget | AI 字幕 |
| `abdul.hotcorners` | Hot Corners | service,overlay | 热角 |
| `io.github.ellion369.omagent` | Omagent | overlay | Agent |
| `io.github.maajix.spotlight` | Spotlight | overlay,menu | Raycast 风格命令面板（`maajix/omarchy-spotlight`）；`Alt+Space` 唤起（`bindings.lua`），毛玻璃层规则见 `omarchy-visual-tweaks.md` §3.3⑤（2026-09-10） |

> **4.0.3 插件沙箱约束（装任何第三方 service 类插件前先看）**：`firstPartyServiceFor(...)` 只发给 `kinds` 含 `bar` 的插件；即便拿到 `PluginFirstPartyServiceApi`，也只暴露 `stayAwake/enabled/doNotDisturb/activePlayer/sourcePlayers`——**拿不到 notifications/media 的 `popupModel`/`hasMedia`/`playerForKey` 等完整接口**。照内部宽松 API 写的插件在公开版会「装上但功能失效」。

> 目录里另有**已装未启用**的：`io.github.lijiawei0305-pixel.mihomo`、`local.opencode-go-usage`、`io.github.brukb.omarchy-zerotier`（不计入上表）。
> 另有**已移除的旧克隆**改名留守（`plugins/.jianlongliu.menu.removed-*`、`.jianlongliu.menu.bak-*`）：点号开头，rescan 不识别，不算已装。

## 六、`shell.json` 其它关键段（当前）

```json
disabledPlugins:   [ omarchy.lock, omarchy.nightlight, omarchy.osd ]
cloneSourceRestores: [ io.github.sirjul1337.lock-explorer, jianlongliu.osd ]   // 启用克隆时自动禁源
idle:              { screensaver: 86400, lock: 1200 }   // 20 分钟锁屏,24h 屏保
bar:               { position: top, transparent: false, id: charlieras262.floating-bar, centerAnchor: omarchy.clock }
```

> `omarchy.osd` 被禁用是**克隆机制的自动结果**（启用 `jianlongliu.osd` 时 source 自动进 disabledPlugins）。系统通知 `omarchy.notifications` 已启用，勿扰由 `jianlongliu.indicators` 的 Dnd 体现。

## 七、已移除（旧方案留档在 `archive/`）

- `io.github.sirmenef.workspace-overview`：总览改走 niri 化 scrolloverview（Super+Tab），`Super+Grave` 绑定已删。
- `njpatel.omapager`：通知接管收编方案回滚后卸载（本机归档笔记（未随本仓库发布））。
- `jesseburlamaque.omarchy-find`：文件搜索（本机归档笔记（未随本仓库发布））。
- `io.github.surfacedp.xmb-menu` + `jianlongliu.xmb-menu`：XMB 波浪菜单双份移除（本机归档笔记（未随本仓库发布））。
- 无留档（试过即弃）：`firstpick.keybindings`、`ssandys.colophon`、`io.github.jccl1706.localsend`、`halmylyseas.github-status`。

## 八、注意事项

* 改 `~/.config/omarchy/shell.json` 或 `plugins/` 下任何文件 → 保存即自动热重载；未生效可用 `omarchy-shell shell rescanPlugins` 强制重扫。
* 内置插件源码一律只读 `/usr/share/omarchy/`,要定制先克隆。
* 官方更新可能改动默认行为,个人覆盖都在 `~/.config/omarchy/` 下,更新不覆盖。
* **两类插件机制别混淆**：Omarchy shell 插件(本文档,`omarchy plugin`/`shell.json`) vs Hyprland 原生插件(scrolloverview,`hyprpm`/`hyprctl plugins`)。

### 8.1 ⚠️ 本地防御补丁清单（update / 插件 pull 会覆盖，需重打）

三处都是**改第三方插件源码**的本地补丁，不在上游。`omarchy update` 或对相应插件 `git pull` 后**可能被冲掉**，届时按需重打（原诊断见 本机归档笔记（未随本仓库发布））：

| 插件 | 文件 | 补丁作用 |
|---|---|---|
| `io.github.lijiawei0305-pixel.mihomo` | `ProxiesPage.qml` | 引擎未连接时 `svc` 为 null，原代码仍调 `svc.t()` 崩溃；改为先判 `root.svc` 再取文本 |
| `charlieras262.floating-bar` | `Bar.qml` | `Style.shellOpacity` 在 4.0.3 已删除，原代码直接赋值 → undefined 赋给 double；加 `typeof ... === "number"` 回落 1 |
| `charlieras262.floating-bar` | `Bar.qml` `injectProps()` | 早期实例化时 `root` 未就绪，`target.bar = root` 抛 "Cannot assign undefined to QObject*"；加 `&& root` 守卫 |
| `jianlongliu.workspaces` | `Workspaces.qml` | `hovered` 原为 readonly 绑定、在 MouseArea 创建前求值报 undefined；改普通属性 + onEntered/onExited 驱动（此项在配置仓库，非插件仓库） |

### 8.2 看 shell 启动日志的正确姿势

```bash
omarchy restart shell && sleep 8
journalctl --user --since "1 min ago" | grep "WARN scene" | sed -E 's/.*WARN scene: //' | sort | uniq -c
```

- **干净的启动 = 8 条**（2026-09-11 实测）：**7 条** `lock-explorer/Explorer.qml: Cannot open: .../lock-explorer-boot-previews/*.png`（插件空编辑态的固有尝试，**非错误，忽略**）+ **1 条** `@plugins/bar/Bar.qml: Handler was registered but will not be used because another handler is registered for target omarchy.bar`（浮栏与内建 bar 的 IpcHandler 抢注册，无害）。其余应为 0。
- **别用 `journalctl --user -b` 当判据**：它含整次登录会话的所有 shell 进程。长跑过、或被热重载过的 shell 进程会累积**数百条** `TypeError: Cannot read property 'foreground'/'fontFamily' of null`（各 panel 在 `bar` 注入前早求值），实测约 **300 条/分钟**持续刷——**但重启后新进程只有 8 条且不涨**。看到这类刷屏先 `omarchy restart shell` 再判断，别去改代码。

## 九、clone 上游跟踪

> 升级 omarchy 4.0.2→4.0.3 后逐对核对全部 clone 与上游，结论：**全部已同步**；与上游的差异均为**有意定制**，勿合并。
> 复验（2026-09-11）：`diff ~/.config/omarchy/plugins/<clone>/文件 /usr/share/omarchy/shell/plugins/<上游>/文件`。

| clone | 上游 4.0.3 位置 | 与上游差异 | 状态 |
| --- | --- | --- | --- |
| `jianlongliu.osd` | `shell/plugins/osd/` | Osd.qml 差异 22 行（新增/删除行合计；`diff` 输出 28 行含 hunk 头） = 卡片式 OSD 定制 | 同步 |
| `jianlongliu.workspaces` | **`shell/plugins/bar/widgets/`** | 差异 82 行 = GNOME 45 圆点/胶囊重写；2026-09-10 另修 hovered undefined（§8.1） | 同步 |
| `jianlongliu.indicators` | **`shell/plugins/bar/widgets/`** | 2 行 = 子目录路径适配 | 同步 |
| `jianlongliu.keyboard-layout` | **`shell/plugins/bar/widgets/`** | 2 行 = `fontSize: Style.font.body`（caption→body 统一） | 同步 |
| `jianlongliu.system-update` | **`shell/plugins/bar/widgets/`** | 2 行 = `fontSize: Style.font.body` | 同步 |

**关键认知**：
- `omarchy.workspaces/indicators/keyboard-layout/system-update` **并未消失**——早前已重构为 `omarchy.bar` 的内建 widget（`bar/widgets/*.qml`），4.0.1→4.0.3 均如此。查找上游请到 `bar/widgets/`，别只在 plugins 顶层找。
- **升级后同步检查**：`diff ~/.config/omarchy/plugins/<clone>/ /usr/share/omarchy/shell/plugins/<上游>/`。判别：**只有用户定制线的差异 = 已同步**；**出现上游侧新增/改动行 = 需 merge**（像 clock 这次）。
- **floating-bar 与 4.0.3**：内置 Bar.qml 4.0.3 引入 `PluginBarApi` + `fallbackBarWidgetRegistry`（专门兼容第三方完整 bar），浮栏无需等上游适配；升级后那次 ~1000 条 `foreground/fontFamily of null` = **rescan 瞬时噪声**（重载瞬间 bar 上下文未注入），非配置错误。2026-09-10 另修：`Bar.qml` 对已删的 `Style.shellOpacity` 加 `typeof` 防御回落 1（补丁清单见 §8.1）。
