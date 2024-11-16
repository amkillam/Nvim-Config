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

return utils
