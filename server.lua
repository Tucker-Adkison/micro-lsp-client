local fmt = import("fmt")
local shell = import("micro/shell")
local micro = import("micro")

local go_os = import("os")
local home, _ = go_os.UserHomeDir()
local pluginPath = home .. '/.config/micro/plug/lspClient/'
local server = nil

local function sendMessage(method, params)
    shell.JobSend(server, fmt.Sprintf('{"method":"%s","params":%s}\n', method, params))
end

local function startServer(onStdout, onStderr, onExit)
    server = shell.JobStart(pluginPath .. 'lsp_client', onStdout, onStderr, onExit, {})
    micro.Log("Started server", server)
end

return {
    sendMessage = sendMessage,
    startServer = startServer,
    server = server
}