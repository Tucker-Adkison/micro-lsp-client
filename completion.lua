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
            local padding = repeatStr(" ", width - string.len(filter_text) - string.len(detail) - 1)
            table.insert(text_to_display, filter_text .. padding .. detail .. "\n")
        elseif filter_text ~= nil then
            local padding = repeatStr(" ", width - string.len(filter_text) - 1)
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
    
    if item == nil or item['textEdit'] == nil then
        return false
    end
    
    local text_edit = item['textEdit']
    local range = text_edit['range']
    local range_start = range['start']
    local range_end = range['end']
    
    micro.Log('New text before cleaning: ', text_edit['newText'])
    
    local original_text = text_edit['newText']
    
    local new_text = string.gsub(original_text, "%$%{%d+:?[^}]*%}", "")
    new_text = string.gsub(new_text, "%$%d+", "")
    
    local start_loc = buffer.Loc(range_start['character'], range_start['line'])
    local end_loc = buffer.Loc(range_end['character'], range_end['line'])
    
    micro.CurPane():NextSplit()
    local cur_pane = micro.CurPane()
    cur_pane.Buf.EventHandler:Remove(start_loc, end_loc)
    cur_pane.Buf.EventHandler:Insert(start_loc, new_text)
    
    local cursor_pos = self:findCursorPosition(original_text, new_text, range_start['character'], range_start['line'])
    cur_pane.Cursor:GotoLoc(cursor_pos)
    
    return true
end

function Completion:findCursorPosition(original_text, cleaned_text, base_char, base_line)
    local zero_pos = string.find(original_text, "%$0")
    if zero_pos then
        local prefix = string.sub(original_text, 1, zero_pos - 1)
        local cleaned_prefix = string.gsub(prefix, "%$%{%d+:?[^}]*%}", "")
        cleaned_prefix = string.gsub(cleaned_prefix, "%$%d+", "")
        return buffer.Loc(base_char + string.len(cleaned_prefix), base_line)
    end
    
    local match_start, match_end = string.find(original_text, "%$%{0:?[^}]*%}")
    if match_start then
        local prefix = string.sub(original_text, 1, match_start - 1)
        local cleaned_prefix = string.gsub(prefix, "%$%{%d+:?[^}]*%}", "")
        cleaned_prefix = string.gsub(cleaned_prefix, "%$%d+", "")
        return buffer.Loc(base_char + string.len(cleaned_prefix), base_line)
    end
    
    if string.len(cleaned_text) >= 2 then
        local last_two = string.sub(cleaned_text, -2)
        local pairs = {
            ["()"] = true,
            ["[]"] = true,
            ["{}"] = true,
            ["<>"] = true,
            ["''"] = true,
            ['""'] = true,
            ["``"] = true
        }
        
        if pairs[last_two] then
            return buffer.Loc(base_char + string.len(cleaned_text) - 1, base_line)
        end
    end
    
    return buffer.Loc(base_char + string.len(cleaned_text), base_line)
end

return Completion