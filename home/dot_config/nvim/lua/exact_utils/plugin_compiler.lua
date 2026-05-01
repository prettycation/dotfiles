local M = {}

local uv = vim.uv or vim.loop
local sep = package.config:sub(1, 1)

local function join(...)
  local parts = { ... }

  for i, part in ipairs(parts) do
    parts[i] = tostring(part)
  end

  return table.concat(parts, sep)
end

local function normalize_lf(text)
  return text:gsub("\r\n", "\n"):gsub("\r", "\n")
end

local function ensure_final_newline(text)
  if text ~= "" and text:sub(-1) ~= "\n" then
    return text .. "\n"
  end

  return text
end

local function read_file(path)
  local f, err = io.open(path, "rb")
  if not f then
    error(("failed to read %s: %s"):format(path, err))
  end

  local text = f:read("*a")
  f:close()

  return ensure_final_newline(normalize_lf(text))
end

local function write_file(path, text)
  local f, err = io.open(path, "wb")
  if not f then
    error(("failed to write %s: %s"):format(path, err))
  end

  f:write(text)
  f:close()
end

local function module_to_path(config, module)
  -- string.gsub returns two values: new_string, replacement_count.
  -- Store it first, otherwise the replacement_count leaks into join().
  local relative = module:gsub("%.", sep)
  return join(config, "lua", relative)
end

local function relpath(path, base)
  local rel = path:sub(#base + 2)
  return rel:gsub("\\", "/")
end

local function should_skip(rel)
  return rel == "compiled.lua" or rel == "init.lua"
end

local function q(s)
  return string.format("%q", s)
end

local function is_identifier(s)
  return type(s) == "string" and s:match("^[%a_][%w_]*$") ~= nil
end

local function sorted_keys(t)
  local keys = {}

  for k in pairs(t) do
    if type(k) ~= "number" or k < 1 or k > #t or math.floor(k) ~= k then
      keys[#keys + 1] = k
    end
  end

  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)

  return keys
end

local function serialize_simple(value, indent)
  indent = indent or ""

  local typ = type(value)

  if typ == "nil" then
    return "nil"
  end

  if typ == "boolean" or typ == "number" then
    return tostring(value)
  end

  if typ == "string" then
    return q(value)
  end

  if typ ~= "table" then
    error(("cannot serialize value of type %s"):format(typ))
  end

  local next_indent = indent .. "  "
  local parts = { "{" }

  for i = 1, #value do
    parts[#parts + 1] = next_indent .. serialize_simple(value[i], next_indent) .. ","
  end

  for _, key in ipairs(sorted_keys(value)) do
    local key_repr

    if is_identifier(key) then
      key_repr = key
    else
      key_repr = "[" .. serialize_simple(key, next_indent) .. "]"
    end

    parts[#parts + 1] = next_indent .. key_repr .. " = " .. serialize_simple(value[key], next_indent) .. ","
  end

  parts[#parts + 1] = indent .. "}"

  return table.concat(parts, "\n")
end

local function compile_import_cond(cond, import)
  local typ = type(cond)

  if typ == "nil" then
    return nil
  end

  if typ == "boolean" then
    -- true is redundant in the compiled output.
    -- false means this import should not be expanded at all.
    if cond == true then
      return nil
    end

    return false
  end

  error(("unsupported cond type %s on import %s; only boolean/nil import cond can be compiled"):format(typ, import))
end

local function serialize_parent_cond(cond)
  if cond == nil then
    return "nil"
  end

  if type(cond) == "boolean" then
    return tostring(cond)
  end

  error(("unsupported parent cond type %s"):format(type(cond)))
end

local function add_file(path, owner_import, files, seen, owners)
  if seen[path] then
    local prev = owners[path]

    if prev == nil or #owner_import > #prev then
      owners[path] = owner_import
    end

    return
  end

  seen[path] = true
  owners[path] = owner_import
  files[#files + 1] = path
end

local function scandir(dir, owner_import, files, seen, owners)
  local handle = uv.fs_scandir(dir)
  if not handle then
    return
  end

  while true do
    local name, typ = uv.fs_scandir_next(handle)
    if not name then
      break
    end

    local path = join(dir, name)

    if typ == "directory" then
      scandir(path, owner_import, files, seen, owners)
    elseif typ == "file" and name:match("%.lua$") then
      add_file(path, owner_import, files, seen, owners)
    end
  end
end

local function collect_files_from_import(config, import, files, seen, owners)
  local path = module_to_path(config, import)

  local file = path .. ".lua"
  local stat = uv.fs_stat(file)

  if stat and stat.type == "file" then
    add_file(file, import, files, seen, owners)
  end

  stat = uv.fs_stat(path)

  if stat and stat.type == "directory" then
    scandir(path, import, files, seen, owners)
  end
end

local function load_manifest()
  package.loaded["plugins.init"] = nil

  local ok, ret = pcall(require, "plugins.init")
  if not ok then
    error(("failed to load plugins/init.lua: %s"):format(ret))
  end

  if type(ret) ~= "table" then
    error("plugins/init.lua must return a table")
  end

  return ret
end

function M.run()
  local config = vim.fn.stdpath("config")
  local plugin_dir = join(config, "lua", "plugins")
  local output = join(plugin_dir, "compiled.lua")

  local manifest = load_manifest()

  local root_specs = {}
  local imports = {}
  local import_conds = {}
  local seen_imports = {}
  local skipped_imports = {}

  for _, spec in ipairs(manifest) do
    if type(spec) == "table" and type(spec.import) == "string" then
      local import = spec.import
      local parent_cond = compile_import_cond(spec.cond, import)

      if parent_cond == false then
        skipped_imports[#skipped_imports + 1] = import
      else
        if not seen_imports[import] then
          seen_imports[import] = true
          imports[#imports + 1] = import
        end

        import_conds[import] = parent_cond
      end
    else
      root_specs[#root_specs + 1] = spec
    end
  end

  local files = {}
  local seen_files = {}
  local owners = {}

  for _, import in ipairs(imports) do
    collect_files_from_import(config, import, files, seen_files, owners)
  end

  table.sort(files)

  local out = {}

  out[#out + 1] = "-- This file is generated. Do not edit by hand."
  out[#out + 1] = "-- Regenerate with: :lua require('utils.plugin_compiler').run()"
  out[#out + 1] = ""
  out[#out + 1] = "local specs = {}"
  out[#out + 1] = ""
  out[#out + 1] = "local function is_plugin_spec(t)"
  out[#out + 1] = "  return type(t) == 'table'"
  out[#out + 1] = "    and (type(t[1]) == 'string' or t.dir or t.url or t.name or t.import)"
  out[#out + 1] = "end"
  out[#out + 1] = ""
  out[#out + 1] = "local function eval_cond(cond, plugin)"
  out[#out + 1] = "  if cond == nil then"
  out[#out + 1] = "    return true"
  out[#out + 1] = "  end"
  out[#out + 1] = ""
  out[#out + 1] = "  if type(cond) == 'boolean' then"
  out[#out + 1] = "    return cond"
  out[#out + 1] = "  end"
  out[#out + 1] = ""
  out[#out + 1] = "  if type(cond) == 'function' then"
  out[#out + 1] = "    return cond(plugin)"
  out[#out + 1] = "  end"
  out[#out + 1] = ""
  out[#out + 1] = "  return true"
  out[#out + 1] = "end"
  out[#out + 1] = ""
  out[#out + 1] = "local function apply_parent_cond(spec, parent_cond)"
  out[#out + 1] = "  if parent_cond == nil then"
  out[#out + 1] = "    return spec"
  out[#out + 1] = "  end"
  out[#out + 1] = ""
  out[#out + 1] = "  local child_cond = spec.cond"
  out[#out + 1] = ""
  out[#out + 1] = "  if child_cond == nil then"
  out[#out + 1] = "    spec.cond = parent_cond"
  out[#out + 1] = "    return spec"
  out[#out + 1] = "  end"
  out[#out + 1] = ""
  out[#out + 1] = "  spec.cond = function(plugin)"
  out[#out + 1] = "    return eval_cond(parent_cond, plugin) and eval_cond(child_cond, plugin)"
  out[#out + 1] = "  end"
  out[#out + 1] = ""
  out[#out + 1] = "  return spec"
  out[#out + 1] = "end"
  out[#out + 1] = ""
  out[#out + 1] = "local function add(ret, source, parent_cond)"
  out[#out + 1] = "  if ret == nil then"
  out[#out + 1] = "    return"
  out[#out + 1] = "  end"
  out[#out + 1] = ""
  out[#out + 1] = "  if type(ret) ~= 'table' then"
  out[#out + 1] = "    error(('plugin spec file %s did not return a table'):format(source))"
  out[#out + 1] = "  end"
  out[#out + 1] = ""
  out[#out + 1] = "  if is_plugin_spec(ret) then"
  out[#out + 1] = "    specs[#specs + 1] = apply_parent_cond(ret, parent_cond)"
  out[#out + 1] = "    return"
  out[#out + 1] = "  end"
  out[#out + 1] = ""
  out[#out + 1] = "  for _, spec in ipairs(ret) do"
  out[#out + 1] = "    specs[#specs + 1] = apply_parent_cond(spec, parent_cond)"
  out[#out + 1] = "  end"
  out[#out + 1] = "end"
  out[#out + 1] = ""

  for _, spec in ipairs(root_specs) do
    out[#out + 1] = ("add(%s, %s, nil)"):format(serialize_simple(spec), q("plugins/init.lua"))
    out[#out + 1] = ""
  end

  local count = 0

  for _, path in ipairs(files) do
    local rel = relpath(path, plugin_dir)

    if not should_skip(rel) then
      local text = read_file(path)
      local owner_import = owners[path]
      local parent_cond = serialize_parent_cond(import_conds[owner_import])

      count = count + 1

      out[#out + 1] = ("-- source: lua/plugins/%s"):format(rel)
      out[#out + 1] = "do"
      out[#out + 1] = ("  local parent_cond = %s"):format(parent_cond)
      out[#out + 1] = "  local ok, ret = pcall(function()"
      out[#out + 1] = text
      out[#out + 1] = "  end)"
      out[#out + 1] = "  if not ok then"
      out[#out + 1] = ("    error(('failed to load %%s: %%s'):format(%s, ret))"):format(q(rel))
      out[#out + 1] = "  end"
      out[#out + 1] = ("  add(ret, %s, parent_cond)"):format(q(rel))
      out[#out + 1] = "end"
      out[#out + 1] = ""
    end
  end

  out[#out + 1] = "return specs"
  out[#out + 1] = ""

  write_file(output, table.concat(out, "\n"))

  vim.notify(
    ("generated lua/plugins/compiled.lua from %d plugin files, %d imports, %d root specs, skipped %d imports"):format(
      count,
      #imports,
      #root_specs,
      #skipped_imports
    ),
    vim.log.levels.INFO
  )
end

return M
