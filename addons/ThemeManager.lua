local httpService = game:GetService('HttpService')

local ThemeManager = {} do
	ThemeManager.Folder = 'ModernUISettings'
	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		['Default'] 		= { 1, {
			FontColor = "ffffff",
			MainColor = "1c1c1c",
			AccentColor = "6272ff",
			BackgroundColor = "141414",
			OutlineColor = "323232"
		}},
		['Dark'] 			= { 2, {
			FontColor = "ffffff",
			MainColor = "1a1a1a",
			AccentColor = "7289da",
			BackgroundColor = "111111",
			OutlineColor = "2a2a2a"
		}},
		['Tokyo Night'] 	= { 3, {
			FontColor = "ffffff",
			MainColor = "16161f",
			AccentColor = "6759b3",
			BackgroundColor = "111118",
			OutlineColor = "252535"
		}},
		['Mint'] 			= { 4, {
			FontColor = "ffffff",
			MainColor = "1a2a1a",
			AccentColor = "3db488",
			BackgroundColor = "0f1a0f",
			OutlineColor = "2a3a2a"
		}},
	}

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then return end

		local scheme = data[2] or data
		
		-- Apply colors to library
		for idx, col in next, scheme do
			if idx == "FontColor" then
				self.Library.FontColor = Color3.fromHex(col)
			elseif idx == "MainColor" then
				self.Library.MainColor = Color3.fromHex(col)
			elseif idx == "AccentColor" then
				self.Library.AccentColor = Color3.fromHex(col)
			elseif idx == "BackgroundColor" then
				self.Library.BackgroundColor = Color3.fromHex(col)
			elseif idx == "OutlineColor" then
				self.Library.OutlineColor = Color3.fromHex(col)
			end
			
			if Options[idx] then
				Options[idx]:SetValueRGB(Color3.fromHex(col))
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value
			end
		end

		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()		
		local theme = 'Default'
		local content = isfile(self.Folder .. '/themes/default.txt') and readfile(self.Folder .. '/themes/default.txt')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false;
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
		 	theme = self.DefaultTheme
		end

		if isDefault then
			if Options.ThemeManager_ThemeList then
				Options.ThemeManager_ThemeList:SetValue(theme)
			end
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. '/themes/default.txt', theme)
	end

	function ThemeManager:CreateThemeManager(groupbox)
		groupbox:AddLabel('Background color')
		local bgPicker = groupbox:AddColorPicker('BackgroundColor', 'Background Color', self.Library.BackgroundColor)
		groupbox:AddLabel('Main color')
		local mainPicker = groupbox:AddColorPicker('MainColor', 'Main Color', self.Library.MainColor)
		groupbox:AddLabel('Accent color')
		local accentPicker = groupbox:AddColorPicker('AccentColor', 'Accent Color', self.Library.AccentColor)
		groupbox:AddLabel('Outline color')
		local outlinePicker = groupbox:AddColorPicker('OutlineColor', 'Outline Color', self.Library.OutlineColor)
		groupbox:AddLabel('Font color')
		local fontPicker = groupbox:AddColorPicker('FontColor', 'Font Color', self.Library.FontColor)

		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		groupbox:AddDivider()
		local themeDropdown = groupbox:AddDropdown('ThemeManager_ThemeList', 'Theme list', ThemesArray, ThemesArray[1], nil, false)

		groupbox:AddButton('Set as default', function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format('Set default theme to "%s"', Options.ThemeManager_ThemeList.Value), 'success')
		end)

		themeDropdown:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		groupbox:AddDivider()
		local customNameInput = groupbox:AddInput('ThemeManager_CustomThemeName', 'Custom theme name', 'Enter name...', false)
		local customDropdown = groupbox:AddDropdown('ThemeManager_CustomThemeList', 'Custom themes', self:ReloadCustomThemes(), nil, nil, false)
		groupbox:AddDivider()
		
		local saveBtn = groupbox:AddButton('Save theme', function() 
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)
			customDropdown:SetValues(self:ReloadCustomThemes())
			customDropdown:SetValue(nil)
		end)
		
		local loadBtn = groupbox:AddButton('Load theme', function() 
			self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value) 
		end)

		local refreshBtn = groupbox:AddButton('Refresh list', function()
			customDropdown:SetValues(self:ReloadCustomThemes())
			customDropdown:SetValue(nil)
		end)

		local setDefaultBtn = groupbox:AddButton('Set as default', function()
			if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format('Set default theme to "%s"', Options.ThemeManager_CustomThemeList.Value), 'success')
			end
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		if bgPicker then bgPicker:OnChanged(UpdateTheme) end
		if mainPicker then mainPicker:OnChanged(UpdateTheme) end
		if accentPicker then accentPicker:OnChanged(UpdateTheme) end
		if outlinePicker then outlinePicker:OnChanged(UpdateTheme) end
		if fontPicker then fontPicker:OnChanged(UpdateTheme) end
	end

	function ThemeManager:GetCustomTheme(file)
		if not file then return nil end
		local path = self.Folder .. '/themes/' .. file .. '.json'
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)
		
		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:SaveCustomTheme(file)
		if not file or file:gsub(' ', '') == '' then
			return self.Library:Notify('Invalid file name for theme (empty)', 'error')
		end

		local theme = {}
		local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

		for _, field in next, fields do
			theme[field] = self.Library[field]:ToHex()
		end

		writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder .. '/themes')

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == '.json' then
				local pos = file:find('.json', 1, true)
				local char = file:sub(pos, pos)

				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1, -6))
				end
			end
		end

		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree()
		local paths = {
			self.Folder,
			self.Folder .. '/themes',
			self.Folder .. '/settings'
		}

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		return tab:AddLeftGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must set ThemeManager.Library first!')
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager
