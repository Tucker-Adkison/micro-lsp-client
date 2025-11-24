local micro = import("micro")
local json = require"json"

local Logger = {}
Logger.__index = Logger

function Logger.new()
    return setmetatable({}, Logger)
end

function Logger:fromJson(output_string)
  local status, output = pcall(json.decode, output_string)

  if status then
    if output.info ~= nil or output.error ~= nil then
      micro.Log(output_string)

      return true
    end
  end

  return false
end

return Logger