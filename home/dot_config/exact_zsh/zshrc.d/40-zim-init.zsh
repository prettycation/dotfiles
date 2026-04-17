# -----------------------------------------------------------------
# 初始化 Zimfw 框架
# -----------------------------------------------------------------

export ZIM_HOME="$HOME/.zim"
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
source ${ZIM_HOME}/init.zsh
