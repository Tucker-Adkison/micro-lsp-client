local go_os = import("os")
local home, _ = go_os.UserHomeDir()
local pluginPath = home .. '/.config/micro/plug/lspClient/'
package.path = package.path .. ";" .. pluginPath .. "?.lua"

local micro = import("micro")
local config = import("micro/config")
local util = import("micro/util")
local buffer = import("micro/buffer")

local command = ''
local side_view = nil
local settings = nil
local lsps = {}
local enabled = false
local Completion = require 'completion'
local completion = Completion.new()
local Logger = require 'logger'
local logger = Logger.new()

local server = require 'server'
local lsp = require 'lsp'

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
    if side_view == nil then
        micro.CurPane():HSplitIndex(buffer.NewBuffer("", "dropdownMenu"), true)

        side_view = micro.CurPane()
        side_view.Buf.Type.Scratch = true
        side_view.Buf.Type.Readonly = true
        side_view.Buf:SetOptionNative("ruler", false)
        side_view.Buf:SetOptionNative("autosave", false)
        side_view.Buf:SetOptionNative("statusformatr", "")
        side_view.Buf:SetOptionNative("statusformatl", "filemanager")
        side_view.Buf:SetOptionNative("scrollbar", false)

        micro.CurPane():NextSplit()
    end
end

local closeDropdownMenu = function()
	if side_view ~= nil then
		side_view:Quit()
		side_view = nil
	end
end

local arrowKeyCommands = function()
    if side_view ~= nil then
        if micro.CurPane() ~= side_view then
            micro.CurPane():NextSplit()
            side_view.Buf:GetActiveCursor():GotoLoc(buffer.Loc(0, -1))
        end

        side_view.Cursor:Relocate()
        side_view.Cursor:SelectLine()
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

    if server ~= nil then
        lsp.shutdown(server)
    end
end

function preInsertNewline()
    if side_view ~= nil and side_view == micro.CurPane() then
        if Completion:autoComplete() then
            closeDropdownMenu()
        end
    end
end

function preinit()
    config.RegisterCommonOption("lsp", "server",'')
    settings = config.GetGlobalOption("lsp.server")

    local fileAndLsps = mysplit(settings, ',')
    for _, fileAndLsp in pairs(fileAndLsps) do
        local fileLspSplit = mysplit(fileAndLsp, '=')
        lsps[fileLspSplit[1]] = fileLspSplit[2]
    end
end

function onRune(bp, _)
    if enabled == true then
        command = 'didChange'
        lsp.didChange(server, bp)

        command = 'completion'
        lsp.completion(server, bp)

        if (micro.CurPane() == side_view) then
            micro.CurPane():NextSplit()
        end
    end
end

local onStdout = function(output_string)
    micro.Log('Command', command)
    for outputs in output_string:gmatch("[^\r\n]+") do
        if not Logger:fromJson(outputs) then 
            if command == 'completion' then
                Completion:fromJson(outputs)

                if next(completion.items) == nil then
                    closeDropdownMenu()
                else
                    openDropdownMenu()

                    Completion:displayText(side_view)
                end
            end
        end
    end
end

local onStderr = function(output)
    micro.Log("Stderr", output)
end

local onExit = function()
    micro.Log("Exit")
end

function onBufferOpen(buf)
    local fileType = buf:FileType()

    if lsps[fileType] ~= nil and not server.server then
        enabled = true

        server.startServer(onStdout, onStderr, onExit)

        local fileText = util.String(buf:Bytes()):gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub('"', '\\"'):gsub("\t", "\\t")

        command = 'initialize'
        lsp.initialize(server, lsps[fileType])

        command = 'didOpen'
        lsp.didOpen(server, buf, fileText)
    end
end
