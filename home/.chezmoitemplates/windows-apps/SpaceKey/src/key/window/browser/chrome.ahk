; for helium
#HotIf Winactive("ahk_exe chrome.exe") && GetKeyState("h", "p")
; 新建标签页
Space & t::^t

; 聚焦地址栏
Space & l::^l

; 聚焦搜索框
Space & f::^f

; 切换 Tabs 状态
Space & s::^s

#HotIf

#HotIf WinActive("ahk_exe chrome.exe")

; 单独按 Alt 时，取消 Helium 顶部工具栏焦点
~LAlt Up::
{
    if (A_PriorKey = "LAlt")
        Send "{Esc}"
}

~RAlt Up::
{
    if (A_PriorKey = "RAlt")
        Send "{Esc}"
}

; 禁用 Alt+D (for STranslate)
!d::return

#HotIf
