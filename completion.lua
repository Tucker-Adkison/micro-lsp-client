local micro = import("micro")
local buffer = import("micro/buffer")
local go_os = import("os")
local home, _ = go_os.UserHomeDir()
local pluginPath = home .. '/.config/micro/plug/lspClient/'
package.path = package.path .. ";" .. pluginPath .. "?.lua"
local json = require"json"

local Completion = {
    items = {}
}
Completion.__index = Completion

function Completion.new()
    return setmetatable({}, Completion)
end

function Completion:fromJson(output_string)
    self.items = {}
    local status, output = pcall(json.decode, output_string)

    if status and next(output) ~= nil then
        for k, v in pairs(output) do
            self.items[k] = v
        end

        micro.Log("Parsed completion response successfully")
    else
        micro.Log("Malformed json when calling completion")
    end
end

local function repeatStr(str, len)
    -- Do NOT try to concat in a loop, it freezes micro...
	-- instead, use a temporary table to hold values
	local string_table = {}
	for i = 1, len do
		string_table[i] = str
	end
	-- Return the single string of repeated characters
	return table.concat(string_table)
end

function Completion:displayText(side_view)
    local text_to_display = {}

    for k, v in pairs(self.items) do
        local filter_text = v['filterText']
        local detail = v['detail']

        local width = micro.CurPane():GetView().Width
        if filter_text ~= nil and detail ~= nil then
            local padding = repeatStr(" ", width - string.len(filter_text) - string.len(detail))
            table.insert(text_to_display, filter_text .. padding .. detail .. "\n")
        elseif filter_text ~= nil then
            local padding = repeatStr(" ", width - string.len(filter_text))
            table.insert(text_to_display, filter_text .. padding .. "\n")
        end
    end

    side_view.Buf.EventHandler:Remove(side_view.Buf:Start(), side_view.Buf:End())
    for k, v in pairs(text_to_display) do
        side_view.Buf.EventHandler:Insert(buffer.Loc(0, k - 1), v)
    end
end

function Completion:autoComplete()
    local item = self.items[micro.CurPane().Buf:GetActiveCursor().Y + 1]

    if item ~= nil and item['textEdit'] ~= nil then
        local text_edit = item['textEdit']
        local range = text_edit['range']
        local range_start = range['start']
        local range_end= range['end']

        micro.Log('New text before cleaning ', text_edit['newText'])

        local new_text =  string.gsub(text_edit['newText'], "%${%d+:[^}]-}", "")
        local start_loc = buffer.Loc(range_start['character'], range_start['line'])
        local end_loc = buffer.Loc(range_end['character'], range_end['line'])

        micro.CurPane():NextSplit()

        local cur_pane = micro.CurPane()

        cur_pane.Buf.EventHandler:Remove(start_loc, end_loc)
        cur_pane.Buf.EventHandler:Insert(start_loc, new_text)
        
        -- Position cursor at the end of inserted text
        local cursor_pos = buffer.Loc(range_start['character'] + string.len(new_text), range_start['line'])
        if (string.sub(new_text, -2, -1) == "()") then
            cursor_pos = buffer.Loc(range_start['character'] + string.len(new_text) - 1, range_start['line'])
        end
        cur_pane.Cursor:GotoLoc(cursor_pos)

        return true
    end

    return false
end

return Completion