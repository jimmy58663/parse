--[[ TO DO

	-- Update filter header directly

]]

local fonts = require("fonts")
local imgui = require("imgui")
local chat = require('chat')
local settingsLib = require('settings')
local display = {}
display.editor = T{
	is_open = T{false},
}

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

local function format_tab(stat_type)
	local info = {}
	local to_be_sorted = {}
	local sorted_players = T{}
	local all_damage = 0
	local sort_type = "damage"
	if (stat_type == 'defense') then
		sort_type = 'defense'
	end
	local display_settings = settings.imgui_display
	local stat_columns = display_settings[stat_type].columns
	local num_of_col = 1

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

			if (display_settings.use_job_colors[1]) then
				if (job_db[player]) then
					local color = display_settings.colors[job_db[player]]
					color = imgui.ColorConvertFloat4ToU32(color)
					imgui.TableSetBgColor(ImGuiTableBgTarget_RowBg0, color)
				else
					local color = display_settings.colors[24]
					color = imgui.ColorConvertFloat4ToU32(color)
					imgui.TableSetBgColor(ImGuiTableBgTarget_RowBg0, color)
				end
			end
			for col = 0, num_of_col - 1 do
				imgui.TableSetColumnIndex(col)
				--Filter still needs testing
				if (imgui.Selectable('', selected == col, bit.bor(ImGuiSelectableFlags_SpanAllColumns, ImGuiSelectableFlags_AllowItemOverlap))) then
					if (filters['player'] == nil or filters['player'] == {}) then
						filters['player'] = {player}
					else
						filters['player'] = {}
					end
				end
				imgui.SameLine()
				if (display_settings.use_job_colors[1]) then
					imgui.TextColored(display_settings.font_color, tostring(info[player][col+1]))
				else
					imgui.Text(tostring(info[player][col+1]))
				end
			end
		end
		imgui.EndTable()
	end
end

function update_display()
	local display_settings = settings.imgui_display
	--Don't render display if it is set to not visible
	if (not display_settings.visible[1]) then return; end

	--Don't render display if Ashita is currently hiding font objects
	if (not AshitaCore:GetFontManager():GetVisible()) then return; end

	imgui.SetNextWindowBgAlpha(display_settings.opacity[1])
	imgui.SetNextWindowSize({display_settings.width[1], display_settings.height[1]}, ImGuiCond_Once)
	if (imgui.Begin('Parse##Display', display_settings.visible[1], bit.bor(ImGuiWindowFlags_NoTitleBar,
														ImGuiWindowFlags_NoScrollbar,
														ImGuiWindowFlags_NoCollapse,
														ImGuiWindowFlags_NoFocusOnAppearing,
														ImGuiWindowFlags_NoNav))) then
		imgui.SetWindowFontScale(display_settings.font_scale[1])

		--Handle resizing window
		local width, height = imgui.GetWindowSize()
		if (width ~= display_settings.width[1] or height ~= display_settings.height[1]) then
			display_settings.width[1] = width
			display_settings.height[1] = height
		end

		--Handle positioning of window
		local posx, posy = imgui.GetWindowPos()
		if (posx ~= display_settings.x[1] or posy ~= display_settings.y[1]) then
			display_settings.x[1] = posx
			display_settings.y[1] = posy
		end

		--Top row of buttons
		if (imgui.Button('\xef\x81\x9e')) then
			reset_parse()
		end

		--Tabs
		imgui.SetNextWindowBgAlpha(display_settings.opacity[1])
		if (imgui.BeginTabBar('##ParseTabBar', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then

			if (imgui.BeginTabItem('Melee', nil)) then
				display_settings.active_tab = 'melee'
				format_tab('melee')
				imgui.EndTabItem()
			end
			if (imgui.BeginTabItem('Defense', nil)) then
				display_settings.active_tab = 'defense'
				format_tab('defense')
				imgui.EndTabItem()
			end
			if (imgui.BeginTabItem('Ranged', nil)) then
				display_settings.active_tab = 'ranged'
				format_tab('ranged')
				imgui.EndTabItem()
			end
			if (imgui.BeginTabItem('Magic', nil)) then
				display_settings.active_tab = 'magic'
				format_tab('magic')
				imgui.EndTabItem()
			end
			imgui.EndTabBar()
		end
	end
	imgui.End()
end

----------------------------------------------------------------------------------------------------
-- Settings Editor
----------------------------------------------------------------------------------------------------
local function render_general_config()
	imgui.Text('General Settings')
	if (imgui.Checkbox('Enable Imgui Display', settings.imgui_display.enable_imgui)) then
		if (settings.imgui_display.enable_imgui[1]) then
			for _,box in pairs(text_box) do
				box.destroy(box)
			end
		else
			init_boxes()
		end
	end
	imgui.ShowHelp('Enables the new Imgui display. If unchecked defaults back to the fonts display.')
	imgui.Checkbox('Visible', settings.imgui_display.visible)
	imgui.ShowHelp('Toggles if Parse is visible or not.')
	imgui.SameLine()
	imgui.Checkbox('Enable Colors', settings.imgui_display.use_job_colors)
	imgui.ShowHelp('Enables custom colors.')
	imgui.SliderFloat('Opacity', settings.imgui_display.opacity, 0.125, 1.0, '%.3f')
	imgui.ShowHelp('The opacity of the Parse window')
	imgui.SliderFloat('Font Scale', settings.imgui_display.font_scale, 0.1, 2.0, '%.3f')
	imgui.ShowHelp('The scaling of the font size')
	local pos = {settings.imgui_display.x[1], settings.imgui_display.y[1]}
	if (imgui.InputInt2('Position', pos)) then
		imgui.SetWindowPos('Parse##Display', pos)
	end
end

local function render_color_config()
	imgui.Text('Color Settings')
	local colors = settings.imgui_display.colors
	imgui.ColorEdit4('Font', settings.imgui_display.font_color)
	imgui.ColorEdit4('Default', colors[24])
	imgui.ColorEdit4('WAR', colors[1])
	imgui.ColorEdit4('MNK', colors[2])
	imgui.ColorEdit4('WHM', colors[3])
	imgui.ColorEdit4('BLM', colors[4])
	imgui.ColorEdit4('RDM', colors[5])
	imgui.ColorEdit4('THF', colors[6])
	imgui.ColorEdit4('PLD', colors[7])
	imgui.ColorEdit4('DRK', colors[8])
	imgui.ColorEdit4('BST', colors[9])
	imgui.ColorEdit4('BRD', colors[10])
	imgui.ColorEdit4('RNG', colors[11])
	imgui.ColorEdit4('SAM', colors[12])
	imgui.ColorEdit4('NIN', colors[13])
	imgui.ColorEdit4('DRG', colors[14])
	imgui.ColorEdit4('SMN', colors[15])
	imgui.ColorEdit4('BLU', colors[16])
	imgui.ColorEdit4('COR', colors[17])
	imgui.ColorEdit4('PUP', colors[18])
	imgui.ColorEdit4('DNC', colors[19])
	imgui.ColorEdit4('SCH', colors[20])
	imgui.ColorEdit4('GEO', colors[21])
	imgui.ColorEdit4('RUN', colors[22])
end

function render_editor()
	if (not display.editor.is_open[1]) then
		return
	end

	imgui.SetNextWindowSize({0, 0}, ImGuiCond_Always)
	if (imgui.Begin('Parse##Config', display.editor.is_open, ImGuiWindowFlags_AlwaysAutoResize)) then
		if (imgui.Button('Save Settings')) then
			settingsLib.save(settings)
			print(chat.header(addon.name):append(chat.message('Settings saved.')))
		end
		imgui.SameLine()
		if (imgui.Button('Reload Settings')) then
			settingsLib.reload()
			print(chat.header(addon.name):append(chat.message('Settings reloaded.')))
		end
		imgui.SameLine()
		if (imgui.Button('Reset Settings')) then
			settingsLib.reset()
			print(chat.header(addon.name):append(chat.message('Settings reset to defaults.')))
		end
		if (imgui.Button('Clear Parse')) then
			reset_parse()
			print(chat.header(addon.name):append(chat.message('Parse database cleared.')))
		end
	end

	imgui.Separator()

	if (imgui.BeginTabBar('ParseEdit##TabBar', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then
		if (imgui.BeginTabItem('General', nil)) then
			render_general_config()
			imgui.EndTabItem()
		end
		if (imgui.BeginTabItem('Colors', nil)) then
			render_color_config()
			imgui.EndTabItem()
		end
	end
	imgui.End()
end

return display