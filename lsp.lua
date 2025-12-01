local go_os = import("os")
local home, _ = go_os.UserHomeDir()
local pluginPath = home .. '/.config/micro/plug/lspClient/'
package.path = package.path .. ";" .. pluginPath .. "?.lua"

local fmt = import("fmt")
local utils = require "utils"

local Lsp = {
  id = -1,
  version = -1
}
Lsp.__index = Lsp

function Lsp.new(server)
    local self = setmetatable({}, Lsp)
    self.server = server 
    return self 
end

function Lsp:completion(bp)
    local filePath = bp.Buf.AbsPath
    local line = bp.Buf:GetActiveCursor().Y
    local char = bp.Buf:GetActiveCursor().X

    self.id = self.id + 1
    self.server:sendMessage(self.id, "textDocument/completion", {
      textDocument = {
        uri = utils.getRootUri(filePath),
      },
      position = {
        line = line,
        character = char,
      },
    })

    return self.id
end

function Lsp:didChange(bp)
    local filePath = bp.Buf.AbsPath
    local fileText = utils.getFileText(bp)

    self.version = self.version + 1
    self.server:sendMessage(nil, "textDocument/didChange", {
      textDocument = {
        uri = utils.getRootUri(filePath),
        version = self.version,
      },
      contentChanges = {{ text = fileText }},
    });

end

function Lsp:initialize()
    local wd, _ = go_os.Getwd()
    local pid = go_os.Getpid()
    local params = utils.getInitiaizeParams(utils.getRootUri(wd), pid)
    self.id = self.id + 1
    self.server:sendMessage(self.id, "initialize", params)
    self.server:sendMessage(nil, "initialized", {})
end

function Lsp:didOpen(bp)
    local fileType = bp.Buf:FileType()
    local filePath = bp.Buf.AbsPath
    local fileText = utils.getFileText(bp)

    self.version = self.version + 1
    self.server:sendMessage(nil, "textDocument/didOpen", {
        textDocument = {
            uri = utils.getRootUri(filePath),
            languageId = fileType,
            version = self.version,
            text = fileText,
        }
    })
end

function Lsp:shutdown()
    self.server:sendMessage(nil, 'shutdown', {})
end

return Lsp