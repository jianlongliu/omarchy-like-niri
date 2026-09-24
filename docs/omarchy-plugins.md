# Omarchy 本机插件参考

> 最后核对：2026-09-15 · Omarchy 4.0.3 / Hyprland 0.56.2
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

**right**：`omarchy.agents` → `srozen.ufw` → `omarchy.microphone` → `io.github.majesticio.clipboard-button` → `jrmmhm.pocket` → `omarchy.tray`(pinned/hidden) → `ronald.input-sources` → `omarchy.bluetooth` → `omarchy.network` → `omarchy.audio` → `omarchy.monitor` → `omarchy-system-menu`
（原 `charlieras262.omablur` 位于 pocket 之前，2026-09-16 已卸载 + 从 `jrmmhm.pocket` 的 `members` 里手工删除）

## 五、非 first-party 插件清单

> 含克隆自 first-party 的 `jianlongliu.*` / `charlieras262.*`；原 first-party 只读在 `/usr/share/omarchy/`。**表中已标注当前 disabled 的几个**（留档原因，勿当启用项）。

| 插件 ID | 名称 | 类型 | 备注 |
| --- | --- | --- | --- |
| `charlieras262.floating-bar` | Floating Bar | bar | 第三方浮动栏（克隆风格，`bar.id`） |
| `charlieras262.omablur` | ~~Omablur~~ | bar-widget | **已卸载（2026-09-16）**：原是 bar 圆角+blur 的 chip 调节面板；它的 `Style.shellOpacity` 机制 + 配套 4 文件 root patch 一并废弃（磨砂现靠 layer_rule + `shell.toml` alpha）→ 见 `omarchy-visual-tweaks.md` §3.3、存档 `archive/omablur-shellopacity-patch.md` |
| `jianlongliu.indicators` | My Indicators | bar-widget | **克隆自 omarchy.indicators**（上游现位于 `bar/widgets/`）；6 图标字号统一 `Style.bar.iconFont`；Dnd 绑系统通知 |
| `jianlongliu.keyboard-layout` | My Keyboard layout | bar-widget | **克隆自 omarchy.keyboard-layout**（上游现位于 `bar/widgets/`） |
| `jianlongliu.arch-logo` | Arch Logo Menu | bar-widget | **自建、非克隆**（不带 `clonedFrom`，故不连累源插件）；Arch logo 染成前景色，点击 toggle 出厂 `omarchy.menu`。做法 + 两个坑见 `omarchy-visual-tweaks.md` §4.1 |
| `jianlongliu.menu` | ~~My Omarchy menu~~ | menu,bar-widget | **已移除**（目录改名 `.jianlongliu.menu.removed-*`）：克隆自 omarchy.menu。**为什么菜单不能克隆**：克隆带非 `bar-widget` kind 的插件会自动禁用源插件（`PluginRegistry.qml:548`，克隆即替代）→ 只剩克隆那份面板，而它的 Apps 分类因 scoped 注入缺陷是空的。禁用克隆可 `restoreCloneSource` 还原 |
| `jianlongliu.osd` | My On-screen display | panel | **克隆自 omarchy.osd**，卡片式小 surface（绕全屏 `ignore_alpha` 失效）；出厂 `omarchy.osd` 已 disabled |
| `jianlongliu.system-update` | My Omarchy update | bar-widget | **克隆自 omarchy.system-update**（上游现位于 `bar/widgets/`） |
| `jianlongliu.workspaces` | My Workspaces | bar-widget | **克隆自 omarchy.workspaces**（上游现位于 `bar/widgets/`），GNOME 45 圆点/胶囊指示器；2026-09-10 修 hovered undefined 警告（补丁清单见 §8.1） |
| `io.github.sirjul1337.lock-explorer` | Lock Screen Explorer | service,overlay | **克隆自 omarchy.lock**，design=`my-splitjianlong`（split 的用户设计副本，只改显示名为 "Jianlong Liu"）、`boot=follow`（开机解密屏= `snapshot:my-splitjianlong`，见 §8.6）；头像走 `lock-avatar.png`；`plymouth/custom/generate.sh` 有本地定制补丁（清单见 §8.1）；boot 预览图由 `plymouth/previews.sh` 生成（启动日志判读见 §8.2） |
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
| `meviusisback.ai-subs` | AI Subs | bar-widget | **AI 订阅用量**（OpenCode / Claude / Codex / Command Code / DeepSeek / Copilot…）；bar 现显示 **Command Code GOAT** 的 `5h/W/M` + 剩余美元。接线与图标补丁见 **§8.4** |
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

* 改 `~/.config/omarchy/shell.json` 或 `plugins/` 下任何文件 → 保存即自动热重载；未生效可用 `omarchy-shell shell rescanPlugins` 强制重扫。⚠️ **但插件代码被 `omarchy plugin update` / `git pull` 重写后不一定被运行中的 shell 认到**——"代码明明改了却不生效"先 `omarchy restart shell`，细节见 §8.5。
* 内置插件源码一律只读 `/usr/share/omarchy/`,要定制先克隆。
* 官方更新可能改动默认行为,个人覆盖都在 `~/.config/omarchy/` 下,更新不覆盖。
* **两类插件机制别混淆**：Omarchy shell 插件(本文档,`omarchy plugin`/`shell.json`) vs Hyprland 原生插件(scrolloverview,`hyprpm`/`hyprctl plugins`)。

### 8.1 ⚠️ 本地补丁清单（update / 插件 pull 会覆盖，需重打）

下表都是**改第三方插件源码**的本地补丁，不在上游；分**防御补丁**（上游 bug 的本地兜底）与**定制补丁**（有意改外观/行为）。`omarchy update` 或对相应插件 `git pull` 后**可能被冲掉**，届时按需重打（防御补丁的原诊断见 本机归档笔记（未随本仓库发布））：

| 插件 | 文件 | 补丁作用 |
|---|---|---|
| `io.github.lijiawei0305-pixel.mihomo` | `ProxiesPage.qml` | 防御：引擎未连接时 `svc` 为 null，原代码仍调 `svc.t()` 崩溃；改为先判 `root.svc` 再取文本 |
| `charlieras262.floating-bar` | `Bar.qml` | 定制：Omablur 卸载（2026-09-16）后 `Style.shellOpacity` 彻底废弃，而上游写法是"背景强制 alpha=1 × shellOpacity（缺失回落 1）"→ **bar 会变实心**；改为 `color: root.background`（直接吃主题 `[bar] background-alpha` 0.5）+ `opacity: 1` |
| `charlieras262.floating-bar` | `Bar.qml` `injectProps()` | 防御：早期实例化时 `root` 未就绪，`target.bar = root` 抛 "Cannot assign undefined to QObject*"；加 `&& root` 守卫 |
| `jianlongliu.workspaces` | `Workspaces.qml` | 防御：`hovered` 原为 readonly 绑定、在 MouseArea 创建前求值报 undefined；改普通属性 + onEntered/onExited 驱动（此项在配置仓库，非插件仓库） |
| `meviusisback.ai-subs` | `assets/icons/commandcode.svg` | 定制：Command Code 品牌图原是「黑圆角方块 + 白 ⌘」，换成**裸 ⌘**（只留白色 ⌘ path，viewBox 收紧到占图标位 20/24）→ 见 §8.4 的重打脚本 |
| `io.github.claudsondouglas.arcdock` | `ArcSlot.qml`（图标 `Image`，约 388 行） | 定制：图标**取图尺寸 = 显示尺寸 × 悬停放大 × DPR**，`magnifyScale 200` 时 ≈166px 却只显示在 83px 上（**2 倍缩小**）→ 双线性缩小丢掉 SVG 抗锯齿，细线图标（Zen 的同心环最明显）出硬台阶。加 `mipmap: true` 让缩小走 mipmap 采样。**实测**环区中间灰(AA)像素 752 → **936（+24%）**。⚠️ 放大倍率 ≤150% 时只缩 1.25 倍、mipmap 不触发 → 等于没加（2026-09-16 首次尝试就是这么"无效"的） |
| `io.github.sirjul1337.lock-explorer` | `plymouth/custom/generate.sh` | 定制：开机解密屏「等待动画」从 22px 圆弧改为**面板边界竖线**（新增 conf 键 `wait_line`/`wait_line_width` + `panel_edge_x()` 自动找边界，找不到自动回退旧圆弧）；细节、重贴与回退见 §8.6 |

### 8.2 看 shell 启动日志的正确姿势

```bash
omarchy restart shell && sleep 8
journalctl --user --since "1 min ago" | grep "WARN scene" | sed -E 's/.*WARN scene: //' | sort | uniq -c
```

- **干净的启动 = 8 条**（2026-09-11 实测）：**7 条** `lock-explorer/Explorer.qml: Cannot open: .../lock-explorer-boot-previews/*.png`（插件空编辑态的固有尝试，**非错误，忽略**）+ **1 条** `@plugins/bar/Bar.qml: Handler was registered but will not be used because another handler is registered for target omarchy.bar`（浮栏与内建 bar 的 IpcHandler 抢注册，无害）。其余应为 0。
- **别用 `journalctl --user -b` 当判据**：它含整次登录会话的所有 shell 进程。长跑过、或被热重载过的 shell 进程会累积**数百条** `TypeError: Cannot read property 'foreground'/'fontFamily' of null`（各 panel 在 `bar` 注入前早求值），实测约 **300 条/分钟**持续刷——**但重启后新进程只有 8 条且不涨**。看到这类刷屏先 `omarchy restart shell` 再判断，别去改代码。

### 8.3 误点 `omarchy refresh shell`（shell.json 被重置）怎么救

一句话：**它只重置 `~/.config/omarchy/shell.json`，且每次都先自动留 `.bak`——去备份里捞回来就行，别手撸重配。**

`omarchy-refresh-shell` 就干三件事（源码 `$(which omarchy-refresh-shell)`）：

1. `omarchy-refresh-config omarchy/shell.json` —— 备份你的版本 → 拷入出厂默认
2. `omarchy-bar defaults` —— bar 恢复成出厂控件集
3. `omarchy-restart-shell`

| 受影响 | 不受影响（实测 2026-09-15） |
|---|---|
| `shell.json`（bar 布局 + 插件启用状态） | `shell.toml`（当天没有新 `.bak`，mtime 仍是旧的） |
| —— | `~/.config/hypr/*`（`git diff` 只有你自己的新增行） |
| —— | 主题 `colors.toml`（重置后重渲过一次，内容逐字节相同） |

**副作用**：出厂插件重新启用、克隆 `jianlongliu.*` 全落回 disabled——因为非 first-party 插件必须被 shell.json 的 `bar.layout` / `plugins` 引用才算启用（同源记录见 `omarchy-visual-tweaks.md` §2.2 的「复发排查」）。

**救援步骤**：

```bash
cd ~/.config/omarchy
cp -p shell.json "shell.json.bak.prerestore-$(date +%s)"   # 先把现状留一份（小文件，别跟真身搞混）
ls -lt shell.json.bak.* | head -5              # 挑「重置前」那份
python3 -m json.tool shell.json.bak.<ts> >/dev/null && echo JSON_OK
cp -p shell.json.bak.<ts> shell.json
omarchy restart shell
```

**怎么一眼认出哪份是真身**：看体积。本机出厂默认 **1191 B**，你的完整配置 **约 3.3 KB**——`3KB+` 的就是要的那份；同一分钟出现两个 `.bak` 时选大的。

**验证基线**（2026-09-15 实测）：

```bash
omarchy plugin list | grep jianlongliu   # 该 enabled 的都回来了，omarchy.osd 回 disabled
hyprctl layers | grep omarchy-bar        # xywh: 10 10 2380 47（本机浮栏几何，非全宽 2400）
```

**别指望 git**：`~/.config/omarchy` 虽是 git 仓库，但 `shell.json` 长期处于**未提交**状态，重置后 `git diff` 只能显示"变回旧版"，救不回最新布局。真正的兜底就是 `shell.json.bak.*` 这一串——**别手删它**。

### 8.4 `meviusisback.ai-subs`：bar 显示 Command Code GOAT 用量

插件**本来就支持** `commandcode` provider（`fetch_usage.py` 的 `PROVIDER_SPECS`，且带 `COMMANDCODE_PLAN_ALLOWANCES["individual-goat"] = 70` 的档位额度）。数据来自 `api.commandcode.ai/alpha/billing/credits` + `/billing/subscriptions`，出 `5h / W / M` 三窗口百分比 + 剩余美元。

**接线三处**（都在用户配置，不在插件里）：

| 位置 | 内容 | 为什么 |
|---|---|---|
| `~/.zshenv` | 多一行 `export COMMANDCODE_API_KEY=<key 字面值>` | 插件只认这个变量名；本机原本叫 `CMD_API_KEY`（Ante catalog 的 `env_key` 也是它） |
| `shell.json` 插件条目 | `"hermesEnvFile": "~/.zshenv"` | 插件默认读 `~/.hermes/.env`（作者是 Hermes 生态的，**不需要真用 Hermes**）；`~/.zshenv` 是纯 `export K=V`，插件解析器吃得下，顺带把 OpenCode / DeepSeek 也点亮 |
| 同上 | `"defaultSub": "commandcode"` | bar 的 `Data` 模式只显示 default sub（hover 面板里所有 provider 都在） |

**⚠️ 最坑一条：插件的 dotenv 解析器不展开变量。** `load_hermes_dotenv` 只做「去 `export` / 剥引号 / 去注释」，写 `export COMMANDCODE_API_KEY="$CMD_API_KEY"` 会把**字面量** `$CMD_API_KEY` 当 key 发出去（表现：`no-key` 或 401）。**必须写字面值**——代价是 key 在 `~/.zshenv` 里出现两份，将来轮换要改两处。

**验证**（不看 bar，直接看取数结果）：

```bash
python3 ~/.config/omarchy/plugins/meviusisback.ai-subs/fetch_usage.py --env ~/.zshenv \
  | python3 -c "import sys,json;[print(p['id'],p['configured'],p.get('detail') or p.get('label') or p.get('error','')) for p in json.load(sys.stdin)['providers']]"
```

期望形如：`commandcode True 5h 3% · W 1% · M 0% · $69.63 remaining`。

**两个实操细节**：
- `omarchy restart shell` 后**首屏可能仍显示上一个 provider 的数据**（实测先跳出 OpenCode 的 `5h 2% · W 2% · M 97%`），等几秒再截图才是新值——别急着以为没生效。
- `M` 那格的百分比是从 `credits.monthlyCredits` **反推**的（`used = 套餐额度 − 剩余`），所以 GOAT 刚用几天时 `M` 显示 0~1% 属正常，不是 bug。

**图标补丁重打**（`omarchy plugin update` / `git pull` 冲掉后跑一次）：

```bash
cd ~/.config/omarchy/plugins/meviusisback.ai-subs/assets/icons
python3 - <<'EOF'
import re
src = open("commandcode.svg").read()
ds = re.findall(r'd="([^"]+)"', src)
if len(ds) == 3:                      # 上游原图 = 黑方块 + 白外环 + ⌘
    open("commandcode.svg", "w").write(
        '<svg viewBox="17.71 17.71 100.68 100.68" xmlns="http://www.w3.org/2000/svg">'
        f'<path fill="#FFFFFF" d="{ds[-1]}"/></svg>')
    print("已重打：只留裸 ⌘")
else:
    print(f"已是补丁版或上游改版，请手工核对（{len(ds)} 条 path）")
EOF
```

- **数字怎么来的**：⌘ 那条 path 在原 137 框里占 `26.1→110.0`（宽 83.9）；viewBox 收到 `100.68` 框后，⌘ 正好占图标位的 **20/24 = 83.3%**，与 `opencode.svg` 里 r=10 的圆环同比例（实测两者都渲染成 **20×21 px**）。量法：`rsvg-convert` 光栅化 + `magick <png> -colorspace gray -threshold 80% -define connected-components:verbose=true -connected-components 8 null:` 读 bbox，**别靠肉眼估**。
- ⚠️ 改完**插件仓库是 dirty 状态** → `omarchy plugin update` 会失败或要你处理；原图随时可取回：`git -C ~/.config/omarchy/plugins/meviusisback.ai-subs show HEAD:assets/icons/commandcode.svg`。

> 待办：`~/.zshenv` 目前权限 `644`（明文 key，同机其他用户可读），可 `chmod 600`——尚未做。

### 8.5 插件代码更新后要 `omarchy restart shell`（`Portal` 槽位案例）

**规则**：磁盘上的插件代码 ≠ 运行中的代码。`omarchy plugin update`（或任何替换插件文件的操作）之后，**一律 `omarchy restart shell` 再验收**——没有单独的"重载某个插件"命令。

**案例（2026-09-17，`io.github.claudsondouglas.arcdock`）**：dock 尾段常驻一个叫 `Portal` 的灰齿轮槽位。

| 环节 | 事实 |
|---|---|
| 身份 | `xdg-desktop-portal-gtk` 的桌面条目（`Name=Portal`、`Icon=applications-system-symbolic`、`NoDisplay=true`），GTK file-picker 一开就以该 appId 进 `ToplevelManager` |
| 上游是否已修 | 已修。0.4.1 的 `Arcdock.qml` 有 `ignoredAppIds` + `isIgnoredAppId()`，**窗口路径与 recents 路径都过滤**（5 处调用：`1233 / 1278 / 1341 / 1447 / 2168`），commit `22a930e` |
| 为什么还看得见 | 运行中的 shell 是更新前的进程（热重载未覆盖到插件代码） |

**判定"是代码没换"而不是"过滤写错"的两步**（都实测过）：

1. 手改 state 文件删掉该 recent → 槽位照旧。`~/.local/state/omarchy/arc-dock.json` 在 `Arcdock.qml:2218` 是 **`watchChanges: false`**，且 recents 只在 `onLoaded` 读一次。
2. 触发 `rebuildSlots`（开一个 probe 窗口再关）→ 槽位照旧。过滤就在 `rebuildSlots` 内（`Arcdock.qml:1278`），**若新代码已加载这一步就该消失** ⇒ 反证跑的是旧代码。

⇒ `omarchy restart shell`：槽位消失，dock 回到 7 固定（nala/nautilus/discord/colamd/mpv/qq/code-oss）+ zen/ghostty/zed/loupe + 启动按钮。**不需要任何本地补丁**（同插件的 `mipmap` 补丁是另一回事，见 §8.1）。

**顺带**：残留条目还在 state 的 `recent` 里（`~/.local/state/omarchy/arc-dock.json`），已清除，备份 `arc-dock.json.bak.1789670466`。

### dock 验收截图法（dock 平时 autoHide 抓不到）

```bash
cfg=~/.config/omarchy/arc-dock.json; bak=$(mktemp); cp "$cfg" "$bak"
trap 'cp "$bak" "$cfg"; rm -f "$bak"' EXIT
jq '.settings.printMode = true' "$bak" > "$cfg"    # dock 移到屏幕中央且不再隐藏
sleep 2
read -r x y w h < <(hyprctl layers -j | jq -r '..|objects|select(.namespace?=="arc-dock")|"\(.x) \(.y) \(.w) \(.h)"' | head -1)
grim -g "$((x-10)),$((y-10)) $((w+20))x$((h+20))" /tmp/dock.png
```

- `grim -g` 吃**逻辑**坐标，输出是**物理**像素（本机 ×1.6）；槽位等宽 → 按 `dock 逻辑宽 / 槽位数` 切片拼图比对，比整张硬看快。
- 认图标别凭记忆：`magick <主题里的 svg> -background none -resize 100x100` 与切片拼一张对比图。

### 8.6 开机解密屏（lock-explorer boot screen）

**现状**：开机解密屏 = lock-explorer 的 **snapshot 孪生**（把锁屏整屏截一张图当背景，密码圆点用主题画在**设计自己的输入框**里）。`shell.json` 该插件 `boot=follow`，实际应用 `snapshot:my-splitjianlong`；状态文件 `~/.local/state/omarchy/lock-explorer-boot`；截图 `~/.local/state/omarchy/lock-explorer-snapshots/{my-splitjianlong,my-splitjianlong-plain}.png`。

**为什么不是手写孪生**：插件手写 plymouth 孪生只有 `terminal / storm / eyes / river`（`Designs.js` 里 `boot: true` 的四个），split 走 snapshot 路线——`plymouth/apply.sh` 的 `snapshot:` 分支拿 explorer 量出的输入框几何生成主题。

| 事项 | 做法 |
|---|---|
| 换设计 / 换主题后重贴 | `SNAPSHOT_ENTRY="88.33,55.78,13.83,4.30,left" bash <插件>/plymouth/apply.sh snapshot:my-splitjianlong`；或在 boot 页按 **Apply**（follow 模式下插件自己重抓快照并重贴，通常不必手动） |
| 改显示名 | 锁屏 `userName` 只认 `$USER`（`DesignBase.qml:53`，插件**无显示名设置**）；显示名靠**用户设计副本** `~/.config/omarchy/lock-designs/SplitJianlong.qml`（`text: "Jianlong Liu"` 字面量，需 `import "../plugins/io.github.sirjul1337.lock-explorer/designs"`） |
| 回退 | boot 页选 **Untouched** + Apply，或 `apply.sh stock`；limine 原背景色存 `/boot/limine.conf.omarchy-lock-explorer.colors` |
| 撤销等待动画补丁 | `git -C <插件> checkout plymouth/custom/generate.sh` 后重贴一次 |
| 等待动画（现状） | 回车后：**面板边界竖线**——accent `#ffb0cf`、6px 宽、自上而下填满、12 帧 ÷8 ≈ **1.6s 一圈**、末两帧淡出（循环无切点）；边界由 `panel_edge_x()` 三条横带投票自动找，本机算出 **76.67%（x2944）**；找不到边界的设计自动回退旧 22px 圆弧 |
| 实测可见窗口 | 「密码被接受 → 合成器接管」≈ **3.3s**（本机 NVMe + UKI）→ 约两圈 |

**⚠️ 两个坑**
- boot 页那行 **`Follow my lock screen` 是勾选框**：点一下 = 取消 follow → 立即回退成出厂主题（会真跑一次重建）。想重贴别点它，直接在 boot 页按 Apply。
- 本机 `/boot` 是 `drwx------ root:root`（fstab `fmask=0077`）→ `apply.sh` 的 `addon_capable()`（在 pkexec **之前、以普通用户身份**跑）恒判 false → **每次都走 `theme` 模式重建两个 UKI（30–60s）**，而不是 README 宣传的"写入 ESP addon、不重建"。副作用：插件硬编码的 `uki=/boot/EFI/Linux/omarchy_linux.efi` 是 **Arch fallback 内核**，默认引导的却是 `omarchy_linux-omarchy.efi`（两者都带主题，故不影响观感）。

**验证法**（量化，别只看图）
- **帧是否真烘进引导**：`pkexec bash -c 'objcopy -O binary --only-section=.initrd /boot/EFI/Linux/omarchy_linux-omarchy.efi /tmp/x.bin'` → `cd /tmp/initrd-x && lsinitcpio -x /tmp/x.bin` → `identify ./usr/share/plymouth/themes/omarchy-boot/spin10.png`（应为 `6x1944`）。
- **引导一致性**：limine.conf 里 `path: …#<128 hex>` 是 **blake2b-512**（`b2sum`；依据 `limine` 包 `/usr/share/doc/limine/CONFIG.md` 第 422 行），**不是 sha512**——比对前先拿不可变的历史条目验证算法。
- **等待时长怎么量**：`journalctl -b 0 -o short-monotonic`，锚点 = btrfs 根挂载（= 密码被接受）→ `Reached target Graphical Interface`（= splash 交棒）；initrd 段的 realtime 时间戳不可信，只有单调时钟可用。
- 预览类需求（不改系统看效果）：`apply.sh … --stage-only` 出 staging 目录 → `magick bg.png spin$i.png -geometry +2944+0 -composite` 逐帧合成 → `ffmpeg -framerate 7.5 -i f%02d.png …mp4` → `mpv --fs --loop-file=inf`。

> 证据链、被否方案、上游 issue 全文：`agent-scratch/lock-explorer-boot-wait-line.md`；**上游 issue 已提：[SirJul1337/omarchy-lock-explorer#40](https://github.com/SirJul1337/omarchy-lock-explorer/issues/40)**（含内嵌 GIF + 4K 片；素材 gist `948138214cf7b9fa92eda859d9cb5f45`）——上游若合并，即可撤 §8.1 那条本地补丁。

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
- **floating-bar 与 4.0.3**：内置 Bar.qml 4.0.3 引入 `PluginBarApi` + `fallbackBarWidgetRegistry`（专门兼容第三方完整 bar），浮栏无需等上游适配；升级后那次 ~1000 条 `foreground/fontFamily of null` = **rescan 瞬时噪声**（重载瞬间 bar 上下文未注入），非配置错误。2026-09-16 另修：Omablur 卸载后 `Style.shellOpacity` 彻底废弃，`Bar.qml` 改为直接吃主题 `[bar] background-alpha`（否则回落不透明 → 实心；补丁清单见 §8.1）。
