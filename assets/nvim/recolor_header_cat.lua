-- script -q -c "lolcat -F 0.3 neovim.txt" > header.cat
-- 读取现有的 header.cat
-- 提取 ANSI truecolor 前景色
-- 重映射
-- 再写回同一个 header.cat

local input = vim.fn.stdpath("config") .. "/lua/plugins/preview/header.cat"
local output = input

local function read_all(path)
  local f = assert(io.open(path, "rb"))
  local s = f:read("*a")
  f:close()
  return s
end

local function write_all(path, content)
  local f = assert(io.open(path, "wb"))
  f:write(content)
  f:close()
end

local function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return {
    tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16),
  }
end

local function rgb_to_hex(rgb)
  return string.format("#%02x%02x%02x", rgb[1], rgb[2], rgb[3])
end

local function blend(c1, c2, t)
  local a = hex_to_rgb(c1)
  local b = hex_to_rgb(c2)
  return rgb_to_hex({
    math.floor(a[1] + (b[1] - a[1]) * t + 0.5),
    math.floor(a[2] + (b[2] - a[2]) * t + 0.5),
    math.floor(a[3] + (b[3] - a[3]) * t + 0.5),
  })
end

-- 多段渐变：按 stops 平滑插值，生成 n 个颜色
local function build_gradient(stops, n)
  if n <= 0 then
    return {}
  end
  if n == 1 then
    return { stops[1] }
  end
  if #stops == 1 then
    local out = {}
    for i = 1, n do
      out[i] = stops[1]
    end
    return out
  end

  local out = {}
  for i = 0, n - 1 do
    local t = i / (n - 1)
    local segf = t * (#stops - 1)
    local seg = math.floor(segf) + 1
    if seg >= #stops then
      out[#out + 1] = stops[#stops]
    else
      local local_t = segf - math.floor(segf)
      out[#out + 1] = blend(stops[seg], stops[seg + 1], local_t)
    end
  end
  return out
end

local target_stops = {
  -- 蓝
  "#5c82b6",
  "#6388bf",
  "#6a8fc8",
  "#7196d1",
  "#789dda",
  "#7fa4e2",
  "#86abeb",
  "#8db2f3",
  "#94b9fb",

  -- 粉
  "#a2b9f8",
  "#b0b9f5",
  "#bebaf2",
  "#d7c2ec", -- 靠蓝区的冷粉
  "#e8bde9", -- 过渡粉
  "#f5c2e7", -- 主粉色
  "#e7b0ee", -- 靠紫区的偏紫粉
  "#e0a6f1",
  "#daa0f2",
  "#d49af3",
  "#ce94f4",

  -- 紫
  "#d097f3",
  "#c88ef5",
  "#c289f6",
  "#bc84f5",
  "#b67ff3",
  "#b07af0",
  "#aa75ed",
}

local text = read_all(input)

-- 收集现有 ANSI truecolor 前景色（按首次出现顺序）
local seen = {}
local ordered = {}

for r, g, b in text:gmatch("\27%[38;2;(%d+);(%d+);(%d+)m") do
  local hex = string.format("#%02x%02x%02x", tonumber(r), tonumber(g), tonumber(b))
  if not seen[hex] then
    seen[hex] = true
    ordered[#ordered + 1] = hex
  end
end

if #ordered == 0 then
  error("header.cat 里没有找到 ANSI truecolor（38;2;r;g;bm）。请先确认它是 truecolor ANSI 文件。")
end

-- 为“现有颜色总数”生成同样数量的新渐变
local replacement_palette = build_gradient(target_stops, #ordered)

local map = {}
for i, old_hex in ipairs(ordered) do
  map[old_hex] = replacement_palette[i]
end

-- 替换所有 ANSI truecolor 前景色
local rewritten = text:gsub("\27%[38;2;(%d+);(%d+);(%d+)m", function(r, g, b)
  local old_hex = string.format("#%02x%02x%02x", tonumber(r), tonumber(g), tonumber(b))
  local new_hex = map[old_hex] or old_hex
  local rgb = hex_to_rgb(new_hex)
  return string.format("\27[38;2;%d;%d;%dm", rgb[1], rgb[2], rgb[3])
end)

write_all(output, rewritten)

print("Recolored ANSI header: " .. output)
print("Mapped " .. #ordered .. " colors.")
