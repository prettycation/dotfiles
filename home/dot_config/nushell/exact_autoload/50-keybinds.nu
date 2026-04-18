# -----------------------------------------------------------------
# Vi 模式
# -----------------------------------------------------------------

$env.config.edit_mode = "vi"

# vi 模式下的光标形状
$env.config.cursor_shape = {
  emacs: line
  vi_insert: line
  vi_normal: block
}

$env.config.keybindings ++= [
  # ide_completion_menu 风格
  # - 第一次 Tab：打开小补全菜单
  # - 菜单已打开时再次按 Tab：接受当前补全
  {
    name: ide_completion_menu_on_tab
    modifier: none
    keycode: tab
    mode: [vi_insert vi_normal emacs]
    event: {
      until: [
        { send: menu name: ide_completion_menu }
        { send: enter }
      ]
    }
  }

  # Ctrl+j：
  # - 第一次按下：打开小补全菜单
  # - 菜单已打开时：移动到下一项
  {
    name: ide_completion_menu_next_on_ctrl_j
    modifier: control
    keycode: char_j
    mode: [vi_insert emacs]
    event: {
      until: [
        { send: menu name: ide_completion_menu }
        { send: menunext }
      ]
    }
  }

  # Ctrl+k：
  # - 第一次按下：打开小补全菜单
  # - 菜单已打开时：移动到上一项
  {
    name: ide_completion_menu_prev_on_ctrl_k
    modifier: control
    keycode: char_k
    mode: [vi_insert emacs]
    event: {
      until: [
        { send: menu name: ide_completion_menu }
        { send: menuprevious }
      ]
    }
  }

  # history hint 快捷键：
  # - Alt+A 接受整条 hint
  # - RightArrow 接受一个词；如果当前没有 hint，则退回普通右移
  {
    name: unbind_default_right_accept_hint
    modifier: none
    keycode: right
    mode: [vi_insert]
    event: null
  }
  {
    name: accept_hint_word_on_right
    modifier: none
    keycode: right
    mode: [vi_insert]
    event: {
      until: [
        { send: historyhintwordcomplete }
        { send: right }
      ]
    }
  }
  {
    name: accept_full_hint_on_alt_a
    modifier: alt
    keycode: char_a
    mode: [vi_insert]
    event: { send: historyhintcomplete }
  }
]
