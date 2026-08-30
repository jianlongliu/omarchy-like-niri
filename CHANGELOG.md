# Changelog — ~/.config/omarchy

改动日志（倒序，最新在上）。提交代码时同步更新本节。

## 2026-08-30
- **git rice**: 建立独立 git 仓库，纳入配置 + 自改 `jianlongliu.*` 插件；`.gitignore` 排除第三方插件嵌套 git 与 `.bak` 备份。首次提交 `59f4a4b`。
- **osd**: 克隆 `omarchy.osd` → `jianlongliu.osd`，改成卡片大小 surface（居中贴底、半透明），绕开全屏透明 layer 的 ignore_alpha 失效（详见 `~/Documents/AI Agents/omarchy-osd-card-clone.md`）。
- **hyprcorner**: 移除自研角落热区插件，改第三方 `abdul.hotcorners`。
