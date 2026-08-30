# omarchy-like-niri

在 **Hyprland** 上把 [Omarchy](https://github.com/basecamp/omarchy) 的工作区体验改造成 **niri 风格**的配置合集——滚动总览 + 纵向平滑切换动画。

> ⚠️ 和笔记本的 [omarchy-on-niri](https://github.com/jianlongliu/omarchy-on-niri)（真 niri 移植）不同：本仓库跑在 **Hyprland** 上，只是"操作风格像 niri"，不是 niri 移植。

## 目录结构

```
omarchy-like-niri/
├── hypr/     <- Hyprland 配置（~/.config/hypr）
└── omarchy/  <- Omarchy 配置 + 自改克隆插件（~/.config/omarchy）
```

- `hypr/`：ScrollOverview 插件、`workspaces` 纵向动画、niri 化快捷键、有界工作区/移窗函数
- `omarchy/`：shell 配置 + 自改 `jianlongliu.*` 克隆插件（clock/menu/osd/keyboard-layout/system-update/workspaces）

## 安装方式

完整可移植教程 + 分步安装（每步带验证/回退）：**`hypr/CHANGELOG.md`** 与本地归档文档 `~/Documents/AI Agents/omarchy-nirification.md`（含文首「〇执行顺序总览」）。

### 给 AI agent 的安装提示词

> 以下提示词可直接交给 AI agent 执行安装：

```
按 ~/Documents/AI Agents/omarchy-nirification.md 的「〇、执行顺序总览」逐步安装 niri 化配置。

要求：
1. 每步先读对应章节再动手，做完一步用文档里的「验证」确认过了再下一步。
2. 步骤 1-7 是核心（ScrollOverview 安装、插件配置、自加载、纵向动画、快捷键、有界工作区、有界移窗）；8-9 可选/总验证。
3. 每改一个 hypr 配置文件先备份，出问题按该步骤「回退」还原。
4. 全部完成后跑一遍「七、验证命令」，hyprctl configerrors 必须为空。
5. 目标机必须是 Omarchy（配置依赖 o.*/hl.* 助手），否则不适用。
```

## 来源与授权

- **配置与文档由 AI agent 生成/整理**（改动含 AI 协助调参、排障）。
- 各插件版权归原作者；自改 `jianlongliu.*` 克隆插件基于 Omarchy 内建插件。

## Changelog

见 `hypr/CHANGELOG.md` 与 `omarchy/CHANGELOG.md`。
