# Changelog — ~/.config/omarchy

改动日志（倒序，最新在上）。提交代码时同步更新本节。

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
- **Liquid Glass 修复（blur 恢复）**: Omablur blur 开关恢复正常工作。根因：Omablur 上游 v1.4.0+（`bf8b25d` security 提交）移除自动 patch 脚本，`Style.shellOpacity` 需手动注入系统 4 文件，4.0.3 后未注入→ `typeof` 防御静默降级→ blur 只作用于窗口圆角。**方案 A 全套 patch 4 个系统文件**（`Style.qml` / `KeyboardPanel.qml` / `NotificationCard.qml` / `Menu.qml`，pkexec root 操作，备份（临时目录）。效果：blur 开=全 shell 0.62 半透明透出模糊壁纸，关=不透明。⚠️ `omarchy update` 覆盖系统文件会静默还原，需重打（详见 `omarchy-visual-tweaks.md` §3.3）。
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
