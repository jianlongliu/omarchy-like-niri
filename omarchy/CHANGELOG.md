# Changelog — ~/.config/omarchy

改动日志（倒序，最新在上）。提交代码时同步更新本节。

## 2026-09-24 — 上游跟踪：lock-explorer 补丁 rebase + 两个第三方插件升级

- **补丁 rebase 到 v1.8.1**：`lock-explorer` 上游 v1.8.1 **独立修了同一个问题**（旧 22px 圆弧在 4K 上「缩成一个小点」），解法是**把圆弧画成 96px 再按输入框高度缩放**。本机解法不同（沿面板边界画满高竖线），观感不同故不采纳。冲突只在「等待帧生成」与「帧定位」两处，解法 = **保留我们的 `wait_line` 分支，回退分支改用上游的 96px + `spinsize`**。补丁文件已更新（基准版本写进 `omarchy/patches/README.md`）。
- **`lock-explorer` v1.7.7 → v1.8.1**（39 个提交）：`git stash` → `merge --ff-only` → `stash pop` 解冲突。新补丁对纯净 v1.8.1 **干净应用、结果逐字节一致**（独立复现验证，非目测）。
- **`io.github.maajix.spotlight` 1.5.2 → 1.6.2**（52 个提交，含安全修复：拒绝伪造的 Wi-Fi/蓝牙行、Unicode 控制字符）。无本地补丁 → 直接 ff。
- **开机解密屏未重贴**：竖线分支下 v1.8.1 的改动（96px 圆弧、`entry.ih`）只在回退分支生效 → 重贴无可见变化却要重建两个 UKI（30–60s）。已烘焙主题仍是 v1.7.7 基准那次（已验证 `spin10.png` = `6x1944` 即竖线）。
- **验收**：`omarchy restart shell` 后当前 shell 进程 WARN **9 条、15 秒零增长**（7 条 boot 预览缺图 + 1 条 bar 重复注册 + 1 条空 URL，均已知无害）；两个插件 `enabled` 正常加载。
- **文档同步**：`omarchy-plugins.md` §9 拆成 9.1（clone 对 omarchy）/ **9.2（第三方插件对作者，新增）** / 9.3（rebase 流程与坑）；§8.1 补丁行更新基准版本；§8.6 补「补丁 vs 上游」与「升级后要不要重贴」两行；三篇头部版本号 4.0.3 → **4.0.4**（实测）。
- **踩坑**：① 循环里 `cd "$d"` 会让后续相对路径错位 → 必须 `git -C`；② 冲突未 `git add` 时 `git diff` 吐 combined diff（`diff --cc`），`git apply` 拒收 → 须 `git add` 后用 `--cached` 生成补丁。

## 2026-09-24 — 锁屏设计纳入 git、开机解密屏补丁入库、公开仓 docs 补齐

- **`lock-designs/SplitJianlong.qml` 纳入 git**：此前只存在于磁盘（同目录 `Card.qml` 已跟踪），等于这个自定义锁屏没有备份。现跟踪。
- **开机解密屏补丁入库**：`plymouth/custom/generate.sh` 的本地定制（`wait_line` / `panel_edge_x()` / accent 竖线）以 diff 形式存公开仓 `omarchy/patches/lock-explorer-generate.sh.patch` + `patches/README.md` 重打步骤。插件目录被 `.gitignore` 的 `plugins/*` 排除，故不进插件树（避免与插件自身 git 嵌套冲突）。
- **公开仓 docs 全量补齐**：三篇自 09-11 发布后未再同步（visual-tweaks 差 546 行、plugins 194 行、nirification 154 行），本次 cp + 脱敏一次追平。

## 2026-09-22 — 开机解密屏：split 快照孪生 + 等待动画改「面板边界竖线」

- **开机解密屏切到 split 的 snapshot 孪生**：`boot=follow` → 实际应用 `snapshot:my-splitjianlong`。split 没有手写 plymouth 孪生（只有 `terminal/storm/eyes/river` 四个），走 `plymouth/apply.sh` 的 `snapshot:` 路线——整屏截图当背景，密码圆点打进设计自己的输入框（几何由 explorer 量出：`88.33,55.78,13.83`）。本机 `/boot` 是 `0700 root`，`addon_capable()` 在 pkexec **之前以普通用户身份**跑 → 恒判 false → **每次应用都走重建路径**（两个 UKI，30–60s），不是 README 宣传的"写 ESP addon、不重建"。
- **显示名**：锁屏 `userName` 只认 `$USER`，插件无显示名设置 → 新建**用户设计副本** `~/.config/omarchy/lock-designs/SplitJianlong.qml`（id `my-splitjianlong`，只把名字那行换成字面量 `"Jianlong Liu"`）并设为当前设计；锁屏与开机屏一起变，且不吃插件更新。
- **等待动画本地定制**（补丁登记 `omarchy-plugins.md` §8.1）：回车后的转圈从 **22px 圆弧**（在 3840×2160 上只有屏宽 0.57%、框高的 1/4 → 等于看不见）改为**面板边界竖线**——accent `#ffb0cf`、6px 宽、自上而下填满、12 帧 ÷8 ≈ **1.6s**、末两帧淡出。边界不写死：`panel_edge_x()` 用上中下三条横带投票找最强竖直边缘（本机自动算出 **76.67% = x2944**），找不到边界的设计自动回退旧圆弧，`wait_line=off` 可显式关掉。实测「密码被接受 → 合成器接管」≈ **3.3s**（`journalctl -o short-monotonic` 锚点法）。
- **回退路径实测过**：boot 页 `Follow my lock screen` 是**勾选框**，取消即触发一次干净的 stock 回退（主题目录删除、`plymouthd.conf` 回 `omarchy`、limine 背景色还原）——此后再重贴走 follow 自动流程即可。
- **引导校验用 blake2b**：limine.conf 里 `path: …#<128 hex>` 是 **blake2b-512**（`b2sum`，依据 `limine` 包 `CONFIG.md:422`），**不是 sha512**；比对前先拿不可变的历史条目验证算法。
- **上游已提 issue**：[SirJul1337/omarchy-lock-explorer#40](https://github.com/SirJul1337/omarchy-lock-explorer/issues/40)（正文内嵌 GIF + 4K 片链接，素材放公开 gist `948138214cf7b9fa92eda859d9cb5f45`；GitHub API 不能给 issue 加附件、`gh gist create` 拒收二进制 → 走 gist 的 git 通道）。**上游合并后可撤 §8.1 那条本地补丁**。顺带撞到并记录了 git 凭据 helper 指向失效 mise 路径的坑（`credential.helper` 写死了 `gh_2.100.0_...`，gh 升到 2.101.0 后所有 github push 失败）。
- **文档同步**：`omarchy-plugins.md` §五 插件表行更新 + §8.1 补丁表加行 + 新增 **§8.6 开机解密屏**（重贴命令 / 两个坑 / 哈希校验法 / `--stage-only` 预览合成法）；证据链、被否方案与上游 issue 草稿存 `agent-scratch/lock-explorer-boot-wait-line.md`。

## 2026-09-17 — arc-dock 清掉 `Portal` 槽位
- **`Portal` 槽位（`xdg-desktop-portal-gtk`）从 dock 消失**：dock 尾段常驻的灰齿轮槽位身份 = `xdg-desktop-portal-gtk.desktop`（`Name=Portal`、`Icon=applications-system-symbolic`、`NoDisplay`）。上游 `io.github.claudsondouglas.arcdock` **0.4.1 已自带过滤**（`Arcdock.qml` `ignoredAppIds`，commit `22a930e`），**未加本地补丁**；看不见的原因是运行中的 shell 还是更新前的进程——手改 state（`watchChanges: false`）与开关 probe 窗口触发 `rebuildSlots` 都无效，`omarchy restart shell` 后恢复。顺带清掉 state `recent` 里的残留条目（备份 `~/.local/state/omarchy/arc-dock.json.bak.1789670466`）。**记入规则**：插件代码被 update/pull 重写后一律 `omarchy restart shell` 再验收（`omarchy-plugins.md` §8.5）。
- **文档同步**：`omarchy-plugins.md` 新增 §8.5（含 dock 验收截图法：临时 `printMode` + `grim` 抓 `hyprctl layers` 的 arc-dock 矩形）；§八"热重载"那条加了反向提醒；证据链存 `agent-scratch/arc-dock-portal.md`。
- **文档同步（桌宠 / 水印）**：Nala（黄球）与 activate-linux 并入 `omarchy-apps.md` **§六**（位置表 / 本机 Sphere 黄改动 / 偏好键 / 重装四步 / 层身份与重启手法）；独立稿 `desktop-toys.md` 当日合并后归档为 `archive/desktop-toys-merged.md`。

## 2026-09-16 — 卸 Omablur、浮栏改吃主题 alpha、4.0.4 更新核查
- **Omablur 卸载**（`omarchy plugin remove charlieras262.omablur`）：它只剩两件事——bar 上的 chip 实时调参、以及 blur 开关时把 shell 统一压到 0.62；后者依赖**4 个系统文件的 root patch**，而 `omarchy update`（`--overwrite /usr/share/omarchy/*`）**每次都会静默还原**它。**上游不会修**：作者 2026-08-28 主动删掉自动 patch 脚本（`bf8b25d`，理由=用 root 写一份用户可写的 git 检出等于提权通道），仓库 0 issue；omarchy 上游（现 `omacom/omarchy`，默认分支 `quattro`）`Style.qml` 至今无 `shellOpacity`。磨砂本身不靠它：全局 `decoration:blur` + `apps/omarchy-shell.lua` 的 layer_rule + `shell.toml` 逐层 `background-alpha`。
- **`shell.json`**：顶层条目随 remove 自动清；**`jrmmhm.pocket` 的 `members` 里嵌的 id 不会自动回收**（同 mihomo 那次），已手工删。
- **浮栏补丁**（`plugins/charlieras262.floating-bar/Bar.qml`，**未提交**）：上游写法是"背景强制 `alpha=1` × `Style.shellOpacity`（缺失回落 1）"，token 废弃后会让 bar 变实心 → 改为 `color: root.background`（直接吃主题 `[bar] background-alpha` 0.5）+ `opacity: 1`。**验证**：A/B 把 `[bar] background-alpha` 临时降到 0.15 → 壁纸明显透上来（已还原）。
- **4.0.4 核查结论**：解包 4.0.3 逐目录 diff——`shell/`、`themes/` **逐字节一致**（`omarchy-settings` 只改了 `etc-overrides/os-release`），改动仅在 `install/` 脚本 + `linux`/`linux-ptl` → `linux-omarchy` 内核统一 + 2 个新迁移 → **所有 `jianlongliu.*` 克隆与本地模板都无需并上游**；本机唯一被冲掉的就是上面那 4 行 patch（现已不需要）。19 个 git 插件只有 `meviusisback.ai-subs` 落后 1 提交（已更新：修 collector 把 0..1 分数当百分比读的 100 倍偏差）；`charlieras262.floating-bar` 是"领先 1 提交 + 未提交 WIP"→ 永不走 ff。
- **菜单 alpha 0.9 → 0.65**（`shell.toml` `[menu] background-alpha`）：与同族对齐（bar 0.5 / popups 0.58 / notifications 0.6 / launcher 0.6）。原 0.9 是"菜单偏黑"那次为保文字可读性抬的，卸掉 Omablur 的统一 0.62 后成了唯一异类。**仍 > 菜单层 `ignore_alpha` 0.5**，磨砂不受影响；**`[menu]` 是共享段** → clipboard/emojis/reminders 卡片一起变。文字对比度（解析法）：纯黑背景 13.4:1、中灰 7.1:1、**纯白壁纸 3.6:1**（低于 WCAG AA 4.5:1）→ 嫌软可回调 0.7 / 0.75。
- **视觉一致性实测**：Display 面板 0.584（= 配置 0.58，换帧回归法）；浮栏 0.5（A/B 法验证）。⚠️ 回归法只在背景静态时可信，背后有视频时数值会失真（已写进 visual-tweaks §3.3）。边框 4（窗口 = `[popups]` = `[menu]` = 浮栏琉璃环宽）、圆角 20 全链同源。
- **文档同步**：`omarchy-visual-tweaks.md` §3.2/§3.3/§3.4 改写（废弃方案只留一行指针）；原文归档 `archive/omablur-shellopacity-patch.md`；`omarchy-plugins.md` §5 插件表与 §8.1 补丁表更新。
- **桌面图标主题被「套主题」重置 → 从源头修**：`omarchy-theme-set` 先把主题目录 `cp -r` 进 `~/.local/state/omarchy/current/theme/`，再跑 `omarchy-theme-set-gnome`，**后者读那份 state 副本里的 `icons.theme` 去覆盖 gsettings `icon-theme`**（该文件不存在才回落 `Yaru-blue`）。`themes/tonal-spot/icons.theme` 与 `themes/expressive/icons.theme` 原本写着 `Yaru-purple` → 每次套主题（含 matugen 换壁纸触发的重套）都把 `MacTahoe` 冲回 Yaru。已把两个源文件 + state 副本改成 `MacTahoe`。`materal-update` 只重写 `colors.toml`，**不碰 `icons.theme`**，所以源文件这一步就是根治。**残余风险**：切到库存主题（`/usr/share/omarchy/themes/*`，各自写死 Yaru-xxx 且只读）时仍会被换掉，要彻底锁死只能加 `hooks/theme-set.d/` hook（hook 在 `omarchy-theme-set-gnome` **之后**执行）。
- **dock 首字母兜底方块（ColaMD）**：dock 的图标查找只认当前激活主题，`hicolor` 虽在主题 `Inherits` 链里但不被走 → 自建条目 `colamd.desktop`（`Icon=colamd`）在 `~/.local/share/icons/hicolor/512x512/apps/colamd.png` 有图仍显示「C」。已把该 PNG 复制进 `~/.local/share/icons/{MacTahoe,MacTahoe-light,MacTahoe-dark}/apps/scalable/`（该目录已声明 `Type=Scalable / MaxSize=512`，PNG 可正常缩放）+ `gtk-update-icon-cache -f -t` + `omarchy restart shell`。**重装 MacTahoe 会丢，需重 cp**。
- **Arc Dock 图标锯齿 → 本地补丁 `mipmap: true`**（`plugins/io.github.claudsondouglas.arcdock/ArcSlot.qml`，**未提交**，已登记 `omarchy-plugins.md` §8.1）：图标取图尺寸是「显示尺寸 × 悬停放大 × DPR」，`magnifyScale 200` 时为 ≈166px 却只显示在 83px 上 → 2 倍双线性缩小丢掉抗锯齿，细线图标（Zen 同心环）出硬台阶。加 `Image.mipmap: true` 后缩小走 mipmap 采样：环区中间灰(AA)像素 **752 → 936（+24%）**，肉眼环重均匀、台阶消失。⚠️ 只在放大倍率 >150%（≥2 倍缩小）时才有意义，≤150% 等于没加。
- **QQ 图标"过曝" → 换成官方企鹅**：MacTahoe 的 `apps/scalable/qq.svg` 是 macOS 原版（企鹅画在**近白圆角板**上），实测该区域 **29.8% 像素 ≥240**（同尺寸下 VS Code 0%、Zen 6%）→ 压在深色 dock 上就是一块曝白。已把 `qq.svg` 备份到 `~/.local/share/mactahoe-icon-overrides-backup/qq.MacTahoe.svg` 并从主题移除，改放官方 `/usr/share/icons/hicolor/512x512/apps/qq.png`（透明底彩色企鹅），三套变体都放 + `gtk-update-icon-cache -f -t` + `omarchy restart shell`。**实测 QQ 区均值 168 → 94.5、≥240 占比 29.8% → 11.2%**。**重装 MacTahoe 会丢，需重 cp**（同 `colamd.png` / `omarchy.svg`）。
- **顺带排除的**：三套 MacTahoe 变体的 app 图标是同一份文件（md5 相同，差异只在 places/UI，文件数 27981/3737/14260）→ 换 `-light` 对 dock 逐像素无变化；dock 渲染的色值/尺寸/笔画粗细与 rsvg 直出一致（平板 96 vs 97、白像素 728 vs 750、环径 ≈80px = iconSize 52×1.6）→ 不是渲染 bug。剩余可疑项：`glassOpacity 20` 时玻璃极透、背后亮内容会把 dock 洗白（作者预览用的是空工作区+深色壁纸）。

## 2026-09-15 — shell.json 从 refresh 备份还原、GTK3 配色接线、三个自建 bar-widget
- **`shell.json` 还原**：误触 `omarchy refresh shell` 把 bar 布局重置回出厂。它只重置 `shell.json`（`omarchy-refresh-config omarchy/shell.json` + `omarchy-bar defaults` + `omarchy-restart-shell`），**`shell.toml` / hypr 配置 / 主题色都没被碰**；重置前那份自动留成 `shell.json.bak.<unix>`，按体积认出真身（出厂默认 1191 B vs 本机 3349 B）覆盖回来即复原。副作用是出厂插件重新启用、`jianlongliu.*` 全落回 disabled——因为非 first-party 必须被 `bar.layout`/`plugins` 引用才算启用。救援流程见 `omarchy-plugins.md` §8.3。
- **GTK3 配色接线**（此前只有 GTK4）：新增 `themed/gtk3.css.tpl`，**全走显式选择器**——GTK3 里 `@define-color` 压不过主题；另需 ① 显式 `background-image: none` 才能盖住 Adwaita 的渐变、② 焦点环/选中标签下划线是 `box-shadow` 画的，要**同形覆盖**否则留蓝环、③ `.gtkstyle-fallback:selected` 与 `treeview.view header button` 这类高优先级硬编码蓝要单独压。`hooks/theme-set.d/gtk-colors-sync` 扩成同步两份（`gtk.css`→`~/.config/gtk-4.0/`、`gtk3.css`→`~/.config/gtk-3.0/`），且**模板缺失就跳过**、不清空现有配置。实测 `evince` 已按主题上色（headerbar `#30282b`、内容区 `#130c0f`），stderr 无 `Theme parsing error`。
- **新增三个自建 bar-widget**：`plugins/jianlongliu.audio` / `.bluetooth` / `.network`（各自 `manifest.json` + `Model.js` + `Panel.qml`，**无 `clonedFrom`**），当前均 disabled、未进 bar 布局。
- **一并对齐本机现状**：`themed/shell.toml.tpl`、`themes/tonal-spot/colors.toml`、`plugins/jianlongliu.workspaces/Workspaces.qml`、`branding/screensaver.txt`、`shell.toml`。

## 2026-09-11 — bar 左上角改 Arch logo（自建插件，非 clone）
- **新增 `plugins/jianlongliu.arch-logo/`**：纯 `bar-widget` kind 的自建插件（`manifest.json` + `BarWidget.qml` + `arch-logo.svg`），**不带 `omarchy.clonedFrom`**，因此不连累任何源插件。`shell.json` 的 `bar.layout.left` 首项由 `omarchy.menu` 改为 `jianlongliu.arch-logo`。
- **为什么不用 clone**：菜单插件 kind 是 `["menu","bar-widget"]`，而 registry 对**带非 bar-widget kind 的克隆**会自动把源插件写进 `disabledPlugins`（`PluginRegistry.qml:548`，克隆即替代）。克隆菜单会让出厂 `omarchy.menu` 被禁，只剩克隆那份面板，而其 Apps 分类因 scoped 注入缺陷恒为空 → 死路。故**按钮与面板拆开**：面板继续用出厂（靠 manifest `keepLoaded: true` 常驻挂载，不在 bar 布局也在跑），bar 按钮换成自建纯 bar-widget 插件。
- **染色坑**：`MultiEffect.colorization` 是**按源亮度相乘**而非"涂成某色"。SVG 直接用 Arch 蓝（亮度≈125/255）会染出只有一半亮（实测 70 vs 邻居 133）。**必须先把 SVG 的 `fill` 改成 `#ffffff`**，改后 227 vs 209（量级一致）。
- **移除 `plugins/jianlongliu.menu/`**：菜单已切回出厂（见下条），该 clone 无存在意义，工作区文件删除；可逆备份 `plugins/.jianlongliu.menu.removed-1789060953`。
- **`shell.toml` 加 `border-width = 5`**（`[popups]` 与 `[menu]`）：面板边框宽度统一到窗口 `border_size`，颜色走同源的 `hyprland_active_border`。
- **`themes/tonal-spot/colors.toml` 重新生成**（matugen tonal-spot）：accent `#9acbfa`→`#97ccf8`、foreground `#e0e2e8`→`#e0e3e8` 等微调，`hyprland_active_border` 同步。
- **`shell.json` bar left 调整**：`omarchy.menu`→`jianlongliu.arch-logo`；`io.github.lijiawei0305-pixel.mihomo`、`halmylyseas.github-status` 移出（不在 bar 布局）；`io.github.sahzudin.omarchy-screenshot-manager` 移到 pocket 分组前并纳入其 `members`；新增 `io.github.maajix.spotlight`。

## 2026-09-10（补）— mihomo 插件 svc 判空补丁
- **`io.github.lijiawei0305-pixel.mihomo` 面板 TypeError 刷屏根治**：MihomoPanel.qml 的 `svc` 表达式 `bar?.shell?.serviceFor(...)` 在 bar/shell 未就绪时返回 `undefined`，而全插件 46 处 `svc !== null` 判空漏防 `undefined`（`undefined !== null` 为真 → 继续解引用 → `Cannot read property 'connected' of undefined` 一族 WARN；官方 `1e3174f` 只补了 ProxiesPage）。补丁：`... || null` 归一，重启 shell 后不再刷。行为不变。**注：该补丁在第三方插件目录内，`plugins/*` 被本仓库 gitignore，故仅记于此。**
- **「未连接」另一根因（未修，用户选择搁置）**：当前 `bar.id=charlieras262.floating-bar`（fork），其 Bar.qml 无官方 `pluginBarApiFor` 的服务注入（官方 2 处 vs 它 0 处）→ 面板 `serviceFor()` 恒 null。修法三选一见（本地笔记存档） §3。

## 2026-09-10（下）— 4.0.3 第三方菜单 appLibrary 缺陷（Apps 空，未修存档）
- **⚠️ 结论修正：官方 clone 重建无法修复 Apps 空**。运行时探针（mergeAppRows 加日志）：`kinds=["menu","bar-widget"]`、`shellType=PluginShellApi`、`pluginId/bar` 均正常传入，**唯独 `appLibrary` 为 null**；`kinds.indexOf("menu")=0` 条件理应成立却仍 null。隔离实验：第三方「非 clone」菜单插件（无 clonedFrom）appLibrary 同样 null → **4.0.3 对一切 scoped 第三方菜单的 appLibrary 注入均失效**（出厂 first-party 直连 host shell 才正常）。机制猜测 = scoped api 缓存与 registry 异步扫描的竞态（manifest 残缺瞬间重建坏 api，profile 匹配后不再自愈），表现为「用着用着就没了」。当前已**切回出厂 `omarchy.menu`**（apps 正常）；clone disabled、git 内保留。修复候选（方案 A/B）见（本地笔记存档）。
- **menu: 官方 clone 重建经过（无效留档）**: 升级 4.0.3 后 Apps 分类空。曾用 `omarchy plugin clone omarchy.menu` 重建（Menu.qml 与出厂 IDENTICAL，含 Liquid Glass shellOpacity patch），但 apps 仍空（见上）。旧手工 clone 备份 `plugins/.jianlongliu.menu.bak-1788978694/`；头像定制 BarWidget 已恢复到 clone 工作区并提交（供方案 A 打 patch 参考）。
- **keyd（输入法 Shift 切换）不属本仓库**：systemd unit 坏链重建见（本地笔记存档）。

## 2026-09-10
- **Liquid Glass 修复（blur 恢复）**: Omablur blur 开关恢复正常工作。根因：Omablur 上游 v1.4.0+（`bf8b25d` security 提交）移除自动 patch 脚本，`Style.shellOpacity` 需手动注入系统 4 文件，4.0.3 后未注入→ `typeof` 防御静默降级→ blur 只作用于窗口圆角。**方案 A 全套 patch 4 个系统文件**（`Style.qml` / `KeyboardPanel.qml` / `NotificationCard.qml` / `Menu.qml`，pkexec root 操作，备份 `/tmp/opencode/omablur-patch-backup/`）。效果：blur 开=全 shell 0.62 半透明透出模糊壁纸，关=不透明。⚠️ `omarchy update` 覆盖系统文件会静默还原，需重打（详见 `omarchy-visual-tweaks.md` §3.3）。
- **遗留定制入库**（`f68daca`）: avatar 悬停 1.15× 放大动画、菜单 7 处 `textFormat: Text.PlainText` 加固、主题粉→蓝黑 + 五彩琉璃渐变活跃边框、DND 铃铛绑系统通知说明。至此全部真实定制已跟踪。
- **启动报错全排查（shell 日志 ERR/WARN → 0）**: 4 项修复，详见（本地笔记存档）：
  - `lock-explorer` boot 预览图 60 条 Cannot open → 跑 `plymouth/previews.sh` 生成 9 张缩略图（0 条）
  - `jianlongliu.workspaces` hovered readonly 绑定取后声明子对象 → 改普通属性 + MouseArea 事件驱动（`5fbb764`）
  - `mihomo` ProxiesPage 引擎未连接时 `svc.t()` 崩 → 判空防御（插件仓库 `1e3174f`）
  - `floating-bar` `Style.shellOpacity` 4.0.3 已删 → `typeof` 防御回落 1（插件仓库 `8a0c4dc`）
- **`.gitignore` 补全**（`1e94a49`）: 挡私人素材 `lock-avatar.png`/`lock-videos/` + 备份 `*.flat.*`，防 `git add -A` 误卷。
- **xmb-menu 移除**: `io.github.surfacedp.xmb-menu`（第三方原版）+ `jianlongliu.xmb-menu`（精修克隆）双双卸载，shell.json 引用由 remove 自动清掉，bar.left 恢复原序。研究笔记 `omarchy-xmb-menu-refine-notes.md` 归档至 archive/。
- **clock 回归官方（omarchy 4.0.3）**: `jianlongliu.clock` 克隆**删除**（`omarchy plugin remove` + 清理备份），bar 布局与 `centerAnchor` 指回官方 `omarchy.clock`（enabled）。原因：克隆唯一定制（日历日期字号 46）已放弃，克隆无存在意义，回归官方可彻底免去上游同步。此前 4.0.3 合并的 `setCenterHoverRevealSuppressed` + `textFormat` 加固已随官方版自带上。上游其余 clone（menu/osd/workspaces/indicators/keyboard-layout/system-update）与 4.0.3 均已同步，差异全为用户有意定制；`omarchy.workspaces/indicators/keyboard-layout/system-update` 上游在 `omarchy.bar` 内建 widget（`bar/widgets/`），详见（本地笔记存档） §九。

## 2026-09-06
- **indicators 字号统一**: 克隆 `omarchy.indicators` → `jianlongliu.indicators`（bar center 首个），给 6 个 status indicator（Dictation/ScreenRecording/Reminder/NightLight/Dnd/StayAwake）在 `.qml` 里补 `import qs.Commons` + `fontSize: Style.bar.iconFont`，统一其图标字号到其它 bar 图标（原基类 `BarIndicator` 缩到 `font.caption` 致偏小/偏下）。备份见 `plugins/`（.gitignore 已放行 jianlongliu.*）。

## 2026-08-30
- **git rice**: 建立独立 git 仓库，纳入配置 + 自改 `jianlongliu.*` 插件；`.gitignore` 排除第三方插件嵌套 git 与 `.bak` 备份。首次提交 `59f4a4b`。
- **osd**: 克隆 `omarchy.osd` → `jianlongliu.osd`，改成卡片大小 surface（居中贴底、半透明），绕开全屏透明 layer 的 ignore_alpha 失效（详见（本地笔记存档））。
- **hyprcorner**: 移除自研角落热区插件，改第三方 `abdul.hotcorners`。
