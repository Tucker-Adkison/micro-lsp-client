local go_os = import("os")
local home, _ = go_os.UserHomeDir()
local pluginPath = home .. '/.config/micro/plug/lspClient/'
package.path = package.path .. ";" .. pluginPath .. "?.lua"

local fmt = import("fmt")
local shell = import("micro/shell")
local micro = import("micro")
local json = require "json"

local Server = {}
Server.__index = Server

function Server.new()
    return setmetatable({}, Server)
end

function Server:sendMessage(id, method, params)
    local bodyJson = {
        jsonrpc = "2.0",
        method = method,
        params = params,
    }

    if id ~= nil then
        bodyJson["id"] = id 
    end

    local body = json.encode(bodyJson)
    local content = "Content-Length: " .. #body .. "\r\n\r\n" .. body

    micro.Log("Sending message:\n" .. content)
    shell.JobSend(self.server, content)
end

function Server:startServer(lsp, args, onStdout, onStderr, onExit)
    micro.Log("Starting server", lsp, args)
    
    self.lsp = lsp
    self.server = shell.JobSpawn(lsp, args, onStdout, onStderr, onExit, {})
end

function Server:getServer() 
    return self.server
end

return Server