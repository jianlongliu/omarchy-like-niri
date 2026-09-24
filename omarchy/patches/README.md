# 本地补丁

改**第三方插件源码**的补丁存档。插件目录（`~/.config/omarchy/plugins/*`）被仓库根 `.gitignore` 排除、且各自带独立 git 仓，所以补丁以 diff 形式单独存放，而非直接放插件文件。

**`omarchy update` 不会碰它们**（它只换 `/usr/share/omarchy`，不动 `~/.config/`）；会冲掉补丁的是 `omarchy plugin update` 或对该插件仓 `git pull` / `reset`，届时按下面步骤重打。补丁清单与作用说明见 [`docs/omarchy-plugins.md`](../../docs/omarchy-plugins.md) §8.1。

## `lock-explorer-generate.sh.patch`

**插件**：`io.github.sirjul1337.lock-explorer`
**基准版本**：**v1.8.1**（`93717da`）——补丁已针对该版本 rebase，更早/更晚的版本可能不适用
**作用**：LUKS 开机解密屏的等待动画，从上游的圆弧改为**面板边界竖线**。

| 项 | 内容 |
| --- | --- |
| 上游行为 | 回车后画一个按输入框比例缩放的圆弧转圈（v1.8.1 起为 96px 绘制再缩放） |
| 本补丁行为 | accent 竖线，6px 宽、自上而下填满、12 帧 ÷8 ≈ 1.6s 一轮，末两帧淡出 |
| 新增配置键 | `wait_line`（`auto` / `off` / 宽度百分比）、`wait_line_width` |
| 边界探测 | `panel_edge_x()` 用上中下三条横带投票，找画面里最强的竖直边缘（本机自动算出 76.67%）；找不到边界的设计自动回退**上游的圆弧** |
| 关闭方式 | `wait_line=off` 显式回到上游圆弧 |

> **与上游的关系**：上游 v1.8.1 独立修了同一个问题（旧版 22px 圆弧在 4K 上「缩成一个小点」），解法是**按比例放大圆弧**；本补丁的解法不同——**沿面板边界画满高竖线**。两者观感不同，故未采纳上游方案；本地补丁的回退分支已采用上游的 96px 画法，即找不到边界时得到的就是上游效果。上游 issue [#40](https://github.com/SirJul1337/omarchy-lock-explorer/issues/40) 仍开着。

### 重打

```bash
cd ~/.config/omarchy/plugins/io.github.sirjul1337.lock-explorer

# 1. 确认补丁能干净应用（只检查不改）
git apply --check -p1 ~/.config/omarchy/patches/lock-explorer-generate.sh.patch

# 2. 应用
git apply -p1 ~/.config/omarchy/patches/lock-explorer-generate.sh.patch

# 3. 重新贴一次开机屏（补丁改了生成脚本，必须重跑才生效）
#    见 docs/omarchy-plugins.md §8.6
```

> 本机 `/boot` 是 `0700 root`，插件的 `addon_capable()` 在提权前以普通用户身份探测 → 恒判 false → **每次重贴都走 UKI 重建**（两个 UKI，约 30–60s），不是上游 README 说的「写 ESP addon、不重建」。

### 回退

```bash
cd ~/.config/omarchy/plugins/io.github.sirjul1337.lock-explorer
git checkout plymouth/custom/generate.sh
# 再重贴一次开机屏；或开机屏选 Untouched + Apply 回 stock 主题
```

### 上游状态

已提 [SirJul1337/omarchy-lock-explorer#40](https://github.com/SirJul1337/omarchy-lock-explorer/issues/40)。上游若合并，可撤下本补丁。
