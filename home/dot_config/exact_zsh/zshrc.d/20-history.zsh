# -----------------------------------------------------------------
# 行为细节控制
# -----------------------------------------------------------------

# 历史记录

# 文件目录
export HISTFILE="$XDG_STATE_HOME/zsh/history"

export HISTSIZE=10000
export SAVEHIST=10000

# 追加写入历史，而不是退出时覆盖
setopt APPEND_HISTORY

# 每条命令立刻写入历史文件
setopt INC_APPEND_HISTORY

# 不共享多个 zsh 会话的历史
unsetopt SHARE_HISTORY

# 忽略以空格开头的命令
setopt HIST_IGNORE_SPACE

# 去掉重复命令的老记录
setopt HIST_IGNORE_ALL_DUPS

# 添加历史前先删掉旧的重复项
setopt HIST_SAVE_NO_DUPS

# 展开历史时不立刻执行
setopt HIST_VERIFY

# 历史中记录执行时间（zsh 原生）
setopt EXTENDED_HISTORY

# 禁用自动更新检查
zstyle ':zim' disable-version-check yes
