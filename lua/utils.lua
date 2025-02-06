local utils = {}

function utils.cmd(cmd, raw)
  local f = assert(io.popen(cmd, "r"))
  local s = assert(f:read "*a")
  f:close()
  if raw then return s end
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  s = string.gsub(s, "[\n\r]+", " ")
  return s
end

function utils.OS()
  local BinaryFormat = package.cpath:match("%p[" .. package.config:sub(1, 1) .. "]?%p(%a+)")
  if BinaryFormat == "dll" then
    return "Windows"
  else
    return utils.cmd "uname -s"
  end
end

-- split("a,b,c", ",") => {"a", "b", "c"}
function utils.split(s, sep)
  local fields = {}

  local valid_sep = sep or " "
  local pattern = string.format("([^%s]+)", valid_sep)
  local _ = string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

  return fields
end

function utils.map(tbl, f)
  local t = {}
  for k, v in pairs(tbl) do
    t[k] = f(v)
  end
  return t
end

function utils.split_lines(s, sep)
  local line_fields = {}
  for line_num, line in ipairs(utils.split(s, "\n")) do
    for i, field in ipairs(utils.split(line, sep)) do
      if not line_fields[i] then line_fields[i] = {} end
      line_fields[i][line_num] = field
    end
  end
  return line_fields
end

function utils.remove_first_line(s) return s:gsub("^[^\n]*\n", "") end

return utils
