/* GTK4 / libadwaita 主题色 —— 由 Omarchy 主题模板生成，请勿直接编辑。
   要改配色请改 ~/.config/omarchy/themed/gtk.css.tpl 后重跑 omarchy theme set。
   变量名取自 libadwaita 官方 CSS Variables 文档（1.9.3 下划线形态实测有效）：
   https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html
   层级关系对齐 Adwaita 惯例：window=底、view=更暗(内容区)、headerbar/sidebar=更亮(凸起)。
   生效前提：会话内不得有 GTK_THEME（它会压死本文件的 @define-color）。 */

/* --- 基础表面 --- */
@define-color window_bg_color {{ background }};
@define-color window_fg_color {{ foreground }};
@define-color view_bg_color {{ dark_background }};
@define-color view_fg_color {{ foreground }};

/* --- 窗口装饰（凸起） --- */
@define-color headerbar_bg_color {{ lighter_background }};
@define-color headerbar_fg_color {{ foreground }};
@define-color headerbar_backdrop_color {{ background }};
@define-color headerbar_border_color {{ muted }};

@define-color sidebar_bg_color {{ lighter_background }};
@define-color sidebar_fg_color {{ foreground }};
@define-color sidebar_backdrop_color {{ background }};

@define-color secondary_sidebar_bg_color {{ background }};
@define-color secondary_sidebar_fg_color {{ foreground }};
@define-color secondary_sidebar_backdrop_color {{ darker_background }};

/* --- 浮层 / 卡片（凸起） --- */
@define-color popover_bg_color {{ lighter_background }};
@define-color popover_fg_color {{ foreground }};
@define-color dialog_bg_color {{ lighter_background }};
@define-color dialog_fg_color {{ foreground }};
@define-color card_bg_color {{ lighter_background }};
@define-color card_fg_color {{ foreground }};
@define-color thumbnail_bg_color {{ lighter_background }};
@define-color thumbnail_fg_color {{ foreground }};
@define-color overview_bg_color {{ background }};
@define-color overview_fg_color {{ foreground }};
@define-color active_toggle_bg_color {{ lighter_background }};
@define-color active_toggle_fg_color {{ foreground }};

/* --- 强调色：镜映 Hyprland 激活边框，保持与桌面同源 --- */
@define-color accent_bg_color {{ accent }};
@define-color accent_fg_color {{ darker_background }};
@define-color accent_color {{ accent }};

/* --- 语义色 --- */
@define-color destructive_bg_color {{ red }};
@define-color destructive_fg_color {{ darker_background }};
@define-color destructive_color {{ red }};
@define-color success_bg_color {{ green }};
@define-color success_fg_color {{ darker_background }};
@define-color success_color {{ green }};
@define-color warning_bg_color {{ yellow }};
@define-color warning_fg_color {{ darker_background }};
@define-color warning_color {{ yellow }};
@define-color error_bg_color {{ red }};
@define-color error_fg_color {{ darker_background }};
@define-color error_color {{ red }};
