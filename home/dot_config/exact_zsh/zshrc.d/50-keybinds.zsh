# -----------------------------------------------------------------
# 后置配置 (必须在 Zim 加载后定义)
# -----------------------------------------------------------------

# [Vi 模式与按键绑定]

# 开启 Vi 模式
bindkey -v

# insert mode 基本恢复为默认/emacs 行为
bindkey -A emacs viins
bindkey -A emacs main

# 保留 ESC 从 insert 切到 normal
bindkey -M viins '^[' vi-cmd-mode

# 采纳建议的快捷键
bindkey -M viins '\ea' autosuggest-accept
bindkey -M main  '\ea' autosuggest-accept
