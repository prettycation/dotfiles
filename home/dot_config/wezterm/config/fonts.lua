local wezterm = require('wezterm')
local platform = require('utils.platform')

-- 预定义不同平台的配置
local config_settings = {}

if platform.is_win then
   -- Windows 平台配置
   config_settings = {
      families = {
         'FiraCode Nerd Font Mono', -- 英文/代码主字体
         'LXGW WenKai Mono GB', -- 中文/Fallback字体
      },
      weight = {
         450,
         -- 'Light',
      },
      size = 14.0,
   }
else
   -- Mac/Linux 默认配置 (保留原有逻辑)
   config_settings = {
      families = { 'JetBrainsMono Nerd Font' },
      weight = { 'Medium' },
      size = platform.is_mac and 12 or 9.75,
   }
end

-- 构建 font_with_fallback 所需的列表
-- 这样可以确保列表中的每个字体都应用相同的 weight
local font_list = {}
for i, name in ipairs(config_settings.families) do
   font_list[i] = {
      family = name,
      weight = config_settings.weight[i], -- 按索引取
   }
end

return {
   -- 使用 font_with_fallback 实现中英文混排
   font = wezterm.font_with_fallback(font_list),

   font_size = config_settings.size,

   --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html
   freetype_load_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
   freetype_render_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}
