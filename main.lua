local go_os = import("os")
local home, _ = go_os.UserHomeDir()
local pluginPath = home .. "/.config/micro/plug/lspClient/"
package.path = package.path .. ";" .. pluginPath .. "?.lua"

local micro = import("micro")
local config = import("micro/config")
local util = import("micro/util")
local buffer = import("micro/buffer")

local sideView = nil
local settings = nil
local lsps = {}
local utils = require 'utils'
local pid = nil
local lspInitialized = false
local didOpen = false

-- initializing all of our classes 
local Completion = require "completion"
local completion = Completion.new()
-- local Logger = require 'logger'
-- local logger = Logger.new()
local Server = require "server"
local server = Server.new()
local Lsp = require "lsp"
local lsp = Lsp.new(server)

local mysplit = function(inputstr, sep)
    if sep == nil then
      sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
    end
    return t
end

local openDropdownMenu = function()
    if sideView == nil then
        micro.CurPane():HSplitIndex(buffer.NewBuffer("", "dropdownMenu"), true)

        sideView = micro.CurPane()
        sideView.Buf.Type.Scratch = true
        sideView.Buf.Type.Readonly = true
        sideView.Buf:SetOptionNative("ruler", false)
        sideView.Buf:SetOptionNative("autosave", false)
        sideView.Buf:SetOptionNative("statusformatr", "")
        sideView.Buf:SetOptionNative("statusformatl", "filemanager")
        sideView.Buf:SetOptionNative("scrollbar", false)

        micro.CurPane():NextSplit()
    end
end

local closeDropdownMenu = function()
	if sideView ~= nil then
		sideView:Quit()
		sideView = nil
	end
end

local arrowKeyCommands = function()
    if sideView ~= nil then
        if micro.CurPane() ~= sideView then
            micro.CurPane():NextSplit()
            sideView.Buf:GetActiveCursor():GotoLoc(buffer.Loc(0, -1))
        end

        sideView.Cursor:Relocate()
        sideView.Cursor:SelectLine()
    end
end

function onCursorUp(_)
	arrowKeyCommands()
end

function onCursorDown(_)
	arrowKeyCommands()
end

function preQuit()
    closeDropdownMenu()

    --TODO remove this iff
    if server.server ~= nil then
        lsp:shutdown(server)
    end
end

function preInsertNewline()
    if sideView ~= nil and sideView == micro.CurPane() then
        if completion:autoComplete() then
            closeDropdownMenu()
        end
    end
end

function preinit()
    config.RegisterCommonOption("lsp", "server",'')
    settings = config.GetGlobalOption("lsp.server")

    micro.Log(settings)

    local fileAndLsps = mysplit(settings, ',')
    for _, fileAndLsp in pairs(fileAndLsps) do
        local fileLspSplit = mysplit(fileAndLsp, '=')
        lsps[fileLspSplit[1]] = fileLspSplit[2]
    end

    micro.Log(lsps)
end

function onRune(bp, _)
    if not lspInitialized then
        lspInitialized = true
        lsp:initialize()
    end

    if lspInitialized then
        if not didOpen then 
            lsp:didOpen(bp)
            
            didOpen = true
        end

        lsp:didChange(bp)

        completion.id = lsp:completion(bp)

        if (micro.CurPane() == sideView) then
            micro.CurPane():NextSplit()
        end
    end
end

local completionRequestId = nil

local onStdout = function(output)
    micro.Log("Stdout", output)
    
    -- Filter notifications
    if output:find('"method":') then
        micro.Log("Ignoring LSP notification")
        return
    end

    local responseId = output:match('"id"%s*:%s*(%d+)')
    micro.Log("responseId", responseId, completion.id)
    if responseId then
        responseId = tonumber(responseId)
        -- Only process if it matches our completion request ID
        if responseId ~= completion.id then
            return
        end
    end
    
    completion:fromJson(output)
    
    if completion.didHaveCompletions then
        openDropdownMenu()
        completion:displayText(sideView)
        command = ""
    elseif completion.jsonBuffer == "" then
        closeDropdownMenu()
    end
end

local onStderr = function(output)
    -- micro.Log("Stderr", output)

    -- local startIndex, endIndex = string.find(output, "PID")
    -- if startIndex then 
    --     pid = output:match("PID:%s*(%d+)")
    -- end
    
    
end

local onExit = function(output)
    micro.Log("Exit", output)
end

function onBufferOpen(buf)
    local fileType = buf:FileType()
    local lspClient = lsps[fileType]

    if lspClient ~= nil and not server:getServer() then
        local wd, _ = go_os.Getwd()
        local args = utils.getLspArgs(lspClient, wd)

        server:startServer(lspClient, args, onStdout, onStderr, onExit)
    end
end

