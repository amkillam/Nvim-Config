function OS()
  local BinaryFormat = package.cpath:match "%p[" .. package.config:sub(1, 1) .. "]?%p(%a+)"
  if BinaryFormat == "dll" then
    function os.name() return "Windows" end
  elseif BinaryFormat == "so" then
    function os.name() return "Linux" end
  elseif BinaryFormat == "dylib" then
    function os.name() return "MacOS" end
  end
  return nil
end
