--[[ TO DO

	-- Update filter header directly

]]

local fonts = require("fonts")
local imgui = require("imgui")

function init_boxes()
	for box,__ in pairs(settings.display) do
		create_text(box)
	end
end

local fontsSettings = T{
    visible = true,
    color = 0xFFFFFFFF,
    font_family = "consolas",
    font_height = 10,
	bold = true,
	color_outline = 0xC8000000,
    draw_flags = FontDrawFlags.Outlined,
	background = T{
		visible = true,
		color = 0x32000000,
	}
}

function create_text(stat_type)
	text_box[stat_type] = fonts.new(settings.display[stat_type].fontsSettings)

	update_text(stat_type)
end

function update_text(stat_type)    
	-- Don't update if box wasn't properly added, there are no settings, or it is not set to visible
	-- FIXME!!! check for logged in on ashita
	if
		not text_box[stat_type]
		or not settings.display[stat_type]
		or not settings.display[stat_type].fontsSettings
		or not settings.display[stat_type].fontsSettings.visible
	then
		return
	end
	
	local info = {}
	local head = T{}
	local to_be_sorted = {}
	local sorted_players = T{}
	local all_damage = 0
	
	if settings.display[stat_type]["type"] == "offense" then 
		sort_type = "damage" 
	else 
		sort_type = "defense" 
	end

	-- add data to info table
	for __,player_name in pairs(get_players()) do
		if (settings.display and settings.display[stat_type]) then
			to_be_sorted[player_name] = get_player_stat_tally('parry',player_name) + get_player_stat_tally('hit',player_name) + get_player_stat_tally('evade',player_name)
			info[player_name] = ''..label_colors('player')..string.format('%-13s',player_name..' ')..'|r' 
			for _, stat in ipairs(settings.display[stat_type].order) do
				if settings.display[stat_type].data_types[stat] then
					local d = {}
					for _, report_type in ipairs(settings.display[stat_type].data_types[stat]) do
						if report_type=="total" then
							local total = get_player_damage(player_name) -- getting player's damage
							d[report_type] = total or "--"
							all_damage = all_damage + total
							if sort_type=='damage' then to_be_sorted[player_name] = total end
						elseif report_type=="total-percent" then
							d[report_type] = get_player_stat_percent(stat,player_name) or "--"
							--d[report_type] = (total or get_player_damage(player_name)) / get_player_damage() or "--"
						elseif report_type=="avg" then
							d[report_type] = get_player_stat_avg(stat,player_name) or "--"
						elseif report_type=="percent" then
							d[report_type] = get_player_stat_percent(stat,player_name) or "--"
						elseif report_type=="tally" then
							d[report_type] = get_player_stat_tally(stat,player_name) or "--"
						elseif report_type=="damage" then
							d[report_type] = get_player_stat_damage(player_name) or "--"
						else
							d[report_type] = "--"
						end
					end

					info[player_name] = info[player_name] .. (format_display_data(d))
				end
			end
		end
	end
	
	-- sort players
	for i=1,settings.display[stat_type].max,1 do
		p_name = nil
		top_result = 0
		for player_name,sort_num in pairs(to_be_sorted) do
			if sort_num > top_result and not sorted_players:contains(player_name) then
				top_result = sort_num
				p_name = player_name					
			end						
		end	
		if p_name then sorted_players:append(p_name) end		
	end

	head:append('[ ${title} ] ${filters} ${pause}')
	info['title'] = stat_type

	info['filters'] = update_filters()
	
	if pause then
		info['pause'] = "- PARSE PAUSED -"
	end

	head:append('${header}')
	info['header'] = format_display_head(stat_type)

	if sorted_players:length() == 0 then
		head:append('No data found')
	end
	
	if text_box[stat_type] then
		local newtext = ""
		newtext = newtext .. string.format('[ %s ] %s %s\n', stat_type, update_filters(), pause and "- PARSE PAUSED -" or "") -- header
		newtext = newtext .. format_display_head(stat_type)
		newtext = newtext ..'\n'
		
		for _, player in pairs(sorted_players) do
			newtext = newtext .. info[player] ..'\n'
		end
		
		--text_box[stat_type]:text = text .. sorted_players:concat('\n')
		--text_box[stat_type]:update(info)
		
		text_box[stat_type].text = newtext
		if settings.display[stat_type].visible then
			text_box[stat_type].visible = true
		end
	end

end

function format_display_head(box_name)
	local text = string.format('%-13s',' ')
	for _, stat in ipairs(settings.display[box_name].order) do
		if settings.display[box_name].data_types[stat] then
			characters = 0
			for i,v in ipairs(settings.display[box_name].data_types[stat]) do
				characters = characters + 7
				if i=='total' then characters = characters +1 end
			end
			text = text .. ''.. label_colors('stat') .. string.format('%-'..characters..'s',stat) .. '|r'
		end
	end
	return text
end

function label_colors(label)
	local r, b, g = 255, 255, 255
	
	if settings.label[label] then
		r = settings.label[label].red or 255
		b = settings.label[label].blue or 255
		g = settings.label[label].green or 255
	end
	
	return string.format("|cFF%02x%02x%02x|",r,g,b)
end

function format_display_data(data)
	line = ""
	
	if data["total-percent"] then
		line = line .. string.format('%-7s',data["total-percent"] .. '% ')
	end
	
	if data["percent"] then
		line = line .. string.format('%-7s',data["percent"] .. '% ')
	end
	
	if data["total"] then
		line = line .. string.format('%-7s',data["total"] .. ' ')
	end

	if data["avg"] then
		line = line .. string.format('%-7s','~' .. data["avg"] .. ' ')
	end

	if data["tally"] then
		if data["damage"] then
			line = line .. string.format('%-7s',data["damage"] ..' ')
		end
		line = line .. string.format('%-7s','#' .. data["tally"])
	elseif data["damage"] then
		line = line .. string.format('%-7s',data["damage"])
	end

	return line
end

function update_texts()
	for v,__ in pairs(text_box) do
		update_text(v)
	end
end

function update_filters()
	local text = ""

	if filters['mob'] and getTableLength(filters['mob']) > 0 then
		text = text .. 'Monsters:'
		for k, v in pairs(filters['mob']) do
			text = text .. ' ' .. v
		end
	end

	if filters['player'] and getTableLength(filters['player']) > 0 then
		text = text .. '\nPlayers:'
		for k, v in pairs(filters['player']) do
			text = text .. ' ' .. v
		end
	end
	return text
end

--Copyright (c) 2013~2016, F.R
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of <addon name> nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
local function get_color_float(value)
	if (value >= 255) then
		return 1.0
	elseif (value < 0) then
		return 0.0
	else
		return (value / 256)
	end
end

local function format_tab(stat_type)
	local info = {}
	local to_be_sorted = {}
	local sorted_players = T{}
	local all_damage = 0
	local sort_type = "damage"
	if (stat_type == 'defense') then
		sort_type = 'defense'
	end
	local display = settings.imgui_display
	local stat_columns = display[stat_type].columns
	local num_of_col = 1
	local player_label_color = {
		get_color_float(settings.label['player'].red),
		get_color_float(settings.label['player'].green),
		get_color_float(settings.label['player'].blue),
		1.0
	}

	local stat_label_color = {
		get_color_float(settings.label['stat'].red),
		get_color_float(settings.label['stat'].green),
		get_color_float(settings.label['stat'].blue),
		1.0
	}

	-- add data to info table
	for __,player_name in pairs(get_players()) do
		to_be_sorted[player_name] = get_player_stat_tally('parry',player_name) + get_player_stat_tally('hit',player_name) + get_player_stat_tally('evade',player_name)
		info[player_name] = T{}
		table.insert(info[player_name], string.format('%-13s',player_name))
		for header, _ in pairs(stat_columns) do
			num_of_col = num_of_col + 1
			local stat = stat_columns[header].stat
			local report_type = stat_columns[header].report_type
			if report_type=="total" then
				local total = get_player_damage(player_name)-- getting player's damage
				table.insert(info[player_name], total or "--")
				all_damage = all_damage + total
				if sort_type=='damage' then to_be_sorted[player_name] = total end
			elseif report_type=="total-percent" then
				table.insert(info[player_name], get_player_stat_percent(stat,player_name) or "--")
			elseif report_type=="avg" then
				table.insert(info[player_name], get_player_stat_avg(stat,player_name) or "--")
			elseif report_type=="percent" then
				table.insert(info[player_name], get_player_stat_percent(stat,player_name) or "--")
			elseif report_type=="tally" then
				table.insert(info[player_name], get_player_stat_tally(stat,player_name) or "--")
			elseif report_type=="damage" then
				table.insert(info[player_name], get_player_stat_damage(player_name) or "--")
			else
				table.insert(info[player_name], "--")
			end
		end
	end

	-- sort players
	for i=1,settings.display[stat_type].max,1 do
		local p_name = nil
		local top_result = 0
		for player_name,sort_num in pairs(to_be_sorted) do
			if sort_num > top_result and not sorted_players:contains(player_name) then
				top_result = sort_num
				p_name = player_name
			end
		end
		if p_name then sorted_players:append(p_name) end
	end

	if (imgui.BeginTable(stat_type .. '##Table', num_of_col, bit.bor(ImGuiTableFlags_BordersH,
															ImGuiTableFlags_NoBordersInBody,
															ImGuiTableFlags_Reorderable,
															ImGuiTableFlags_Sortable,
															ImGuiTableFlags_SizingFixedFit,
															ImGuiTableFlags_ScrollX,
															ImGuiTableFlags_ScrollY))) then
		imgui.TableSetupColumn('Name')
		for header, _ in pairs(stat_columns) do
			imgui.TableSetupColumn(header)
		end
		imgui.TableSetupScrollFreeze(1, 1) -- Column 1, Row 1
		imgui.TableHeadersRow()
		for row = 0, #sorted_players - 1 do
			imgui.TableNextRow()
			local player = sorted_players[row+1]
			local selected = -1
			for col = 0, num_of_col - 1 do
				imgui.TableSetColumnIndex(col)
				--Filter still needs testing
				if (imgui.Selectable('', selected == col, bit.bor(ImGuiSelectableFlags_SpanAllColumns, ImGuiSelectableFlags_AllowItemOverlap))) then
					if (filters['player'] == nil) then
						filters['player'] = player
					else
						filters['player'] = {}
					end
				end
				imgui.SameLine()
				imgui.Text(tostring(info[player][col+1]))
			end
		end
		imgui.EndTable()
	end
end

function update_display()
	local display = settings.imgui_display
	--Don't render display if it is set to not visible
	if (not display.visible[1]) then return; end

	--Don't render display if Ashita is currently hiding font objects
	if (not AshitaCore:GetFontManager():GetVisible()) then return; end

	imgui.SetNextWindowBgAlpha(display.opacity[1])
	imgui.SetNextWindowSize({display.width[1], display.height[1]}, ImGuiCond_Once)
	if (imgui.Begin('Parse', display.visible[1], bit.bor(ImGuiWindowFlags_NoTitleBar,
														ImGuiWindowFlags_NoScrollbar,
														ImGuiWindowFlags_NoCollapse,
														ImGuiWindowFlags_NoFocusOnAppearing,
														ImGuiWindowFlags_NoNav))) then
		imgui.SetWindowFontScale(display.font_scale[1])

		--Handle resizing window
		local width, height = imgui.GetWindowSize()
		if (width ~= display.width[1] or height ~= display.height[1]) then
			display.width[1] = width
			display.height[1] = height
		end

		--Handle positioning of window
		local posx, posy = imgui.GetWindowPos()
		if (posx ~= display.x[1] or posy ~= display.y[1]) then
			display.x[1] = posx
			display.y[1] = posy
		end

		if (imgui.BeginTabBar('##ParseTabBar', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then

			if (imgui.BeginTabItem('Melee', nil)) then
				display.active_tab = 'melee'
				format_tab('melee')
				imgui.EndTabItem()
			end
			if (imgui.BeginTabItem('Defense', nil)) then
				display.active_tab = 'defense'
				format_tab('defense')
				imgui.EndTabItem()
			end
			if (imgui.BeginTabItem('Ranged', nil)) then
				display.active_tab = 'ranged'
				format_tab('ranged')
				imgui.EndTabItem()
			end
			if (imgui.BeginTabItem('Magic', nil)) then
				display.active_tab = 'magic'
				format_tab('magic')
				imgui.EndTabItem()
			end
			imgui.EndTabBar()
		end
	end
	imgui.End()
end