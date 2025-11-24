local micro = import("micro")
local fmt = import("fmt")
local util = import("micro/util")
local go_os = import("os")

local function completion(server, bp)
    local line = bp.Buf:GetActiveCursor().Y
    local char = bp.Buf:GetActiveCursor().X

    micro.Log(fmt.Sprintf("completion called"))

    server.sendMessage('completion', fmt.Sprintf('{"line": "%.0f", "character": "%.0f"}', line, char))
end

local function didChange(server, bp)
    local filePath = bp.Buf.AbsPath
    local fileText = util.String(bp.Buf:Bytes()):gsub("\\", "\\\\"):gsub("\n", "\\n")
    fileText = fileText:gsub("\r", "\\r"):gsub('"', '\\"'):gsub("\t", "\\t")

    micro.Log("didChange called")

    server.sendMessage('didChange', fmt.Sprintf('{"filePath":"%s","fileText":"%s"}', filePath, fileText))
end

local function initialize(server, lsp)
    local wd, _ = go_os.Getwd()

    micro.Log("initialized called")
    micro.Log("initialize " .. fmt.Sprintf('{"lsp":"%s", "rootUri":"%s"}', lsp, wd))

    server.sendMessage('initialize', fmt.Sprintf('{"lsp":"%s", "rootUri":"%s"}', lsp, wd))
end

local function didOpen(server, buf, fileText)
    local fileType = buf:FileType()
    local filePath = buf.AbsPath

    micro.Log("didOpen called")

    server.sendMessage('didOpen', fmt.Sprintf('{"filePath":"%s","fileText":"%s","languageId":"%s", "version": 1}', filePath, fileText, fileType))
end

local function shutdown(server)
    server.sendMessage('shutdown', '')
end

return {
    initialize = initialize,
    completion = completion,
    didChange = didChange,
    didOpen = didOpen,
    shutdown = shutdown
}