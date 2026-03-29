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
