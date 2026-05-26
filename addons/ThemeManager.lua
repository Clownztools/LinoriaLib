--[[
    ThemeManager Module
    Handles themes and color customization
]]

local HttpService = game:GetService("HttpService")

local ThemeManager = {}
ThemeManager.__index = ThemeManager

function ThemeManager.new(library)
    local self = setmetatable({}, ThemeManager)
    
    self.Library = library
    self.Folder = library.Config.Folder or "ModernUISettings"
    self.CurrentTheme = "Dark"
    
    -- Built-in themes
    self.BuiltInThemes = {
        Dark = {
            Background = Color3.fromRGB(18, 18, 22),
            Surface = Color3.fromRGB(28, 28, 35),
            Primary = Color3.fromRGB(88, 101, 242),
            PrimaryDark = Color3.fromRGB(71, 82, 196),
            Text = Color3.fromRGB(255, 255, 255),
            TextSecondary = Color3.fromRGB(160, 160, 170),
            Border = Color3.fromRGB(45, 45, 55),
            Danger = Color3.fromRGB(237, 66, 69),
            Success = Color3.fromRGB(60, 200, 100),
            Warning = Color3.fromRGB(250, 160, 50),
        },
        Light = {
            Background = Color3.fromRGB(240, 240, 245),
            Surface = Color3.fromRGB(255, 255, 255),
            Primary = Color3.fromRGB(88, 101, 242),
            PrimaryDark = Color3.fromRGB(71, 82, 196),
            Text = Color3.fromRGB(30, 30, 35),
            TextSecondary = Color3.fromRGB(100, 100, 110),
            Border = Color3.fromRGB(220, 220, 225),
            Danger = Color3.fromRGB(237, 66, 69),
            Success = Color3.fromRGB(60, 200, 100),
            Warning = Color3.fromRGB(250, 160, 50),
        },
        Dracula = {
            Background = Color3.fromRGB(40, 42, 54),
            Surface = Color3.fromRGB(50, 52, 64),
            Primary = Color3.fromRGB(189, 147, 249),
            PrimaryDark = Color3.fromRGB(139, 97, 199),
            Text = Color3.fromRGB(248, 248, 242),
            TextSecondary = Color3.fromRGB(180, 180, 170),
            Border = Color3.fromRGB(68, 71, 90),
            Danger = Color3.fromRGB(255, 85, 85),
            Success = Color3.fromRGB(80, 250, 123),
            Warning = Color3.fromRGB(241, 250, 140),
        },
        Nord = {
            Background = Color3.fromRGB(46, 52, 64),
            Surface = Color3.fromRGB(59, 66, 82),
            Primary = Color3.fromRGB(136, 192, 208),
            PrimaryDark = Color3.fromRGB(94, 129, 172),
            Text = Color3.fromRGB(216, 222, 233),
            TextSecondary = Color3.fromRGB(180, 185, 195),
            Border = Color3.fromRGB(67, 76, 94),
            Danger = Color3.fromRGB(191, 97, 106),
            Success = Color3.fromRGB(163, 190, 140),
            Warning = Color3.fromRGB(235, 203, 139),
        },
        Catppuccin = {
            Background = Color3.fromRGB(30, 30, 46),
            Surface = Color3.fromRGB(49, 50, 68),
            Primary = Color3.fromRGB(203, 166, 247),
            PrimaryDark = Color3.fromRGB(153, 116, 197),
            Text = Color3.fromRGB(205, 214, 244),
            TextSecondary = Color3.fromRGB(166, 173, 200),
            Border = Color3.fromRGB(69, 71, 90),
            Danger = Color3.fromRGB(243, 139, 168),
            Success = Color3.fromRGB(166, 218, 149),
            Warning = Color3.fromRGB(249, 226, 175),
        },
        TokyoNight = {
            Background = Color3.fromRGB(26, 27, 38),
            Surface = Color3.fromRGB(31, 33, 46),
            Primary = Color3.fromRGB(122, 162, 247),
            PrimaryDark = Color3.fromRGB(89, 126, 200),
            Text = Color3.fromRGB(169, 177, 214),
            TextSecondary = Color3.fromRGB(130, 140, 180),
            Border = Color3.fromRGB(57, 60, 80),
            Danger = Color3.fromRGB(247, 118, 142),
            Success = Color3.fromRGB(158, 206, 106),
            Warning = Color3.fromRGB(224, 175, 104),
        },
    }
    
    self:BuildFolderTree()
    self:LoadCustomThemes()
    
    return self
end

function ThemeManager:BuildFolderTree()
    local themesPath = self.Folder .. "/Themes"
    if not isfolder(themesPath) then
        makefolder(themesPath)
    end
end

function ThemeManager:LoadCustomThemes()
    self.CustomThemes = {}
    local themesPath = self.Folder .. "/Themes"
    local files = listfiles(themesPath)
    
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local success, data = pcall(function()
                return HttpService:JSONDecode(readfile(file))
            end)
            
            if success and data and data.name then
                self.CustomThemes[data.name] = data
            end
        end
    end
end

function ThemeManager:GetThemeList()
    local themes = {}
    
    for name in pairs(self.BuiltInThemes) do
        table.insert(themes, name)
    end
    
    for name in pairs(self.CustomThemes) do
        table.insert(themes, name)
    end
    
    table.sort(themes)
    return themes
end

function ThemeManager:ApplyTheme(themeName)
    local theme = self.BuiltInThemes[themeName] or self.CustomThemes[themeName]
    
    if not theme then
        return false
    end
    
    -- Apply theme to library
    for key, value in pairs(theme) do
        if self.Library.Theme[key] then
            self.Library.Theme[key] = value
        end
    end
    
    -- Update all UI elements
    self.Library:UpdateColors()
    self.CurrentTheme = themeName
    
    return true
end

function ThemeManager:SaveCustomTheme(name)
    if not name or name == "" then
        self.Library:Notify("Please enter a theme name", "error")
        return false
    end
    
    -- Create theme data from current colors
    local themeData = {
        name = name,
        Background = self.Library.Theme.Background,
        Surface = self.Library.Theme.Surface,
        Primary = self.Library.Theme.Primary,
        PrimaryDark = self.Library.Theme.PrimaryDark,
        Text = self.Library.Theme.Text,
        TextSecondary = self.Library.Theme.TextSecondary,
        Border = self.Library.Theme.Border,
        Danger = self.Library.Theme.Danger,
        Success = self.Library.Theme.Success,
        Warning = self.Library.Theme.Warning,
    }
    
    -- Convert colors to hex for saving
    for key, color in pairs(themeData) do
        if type(color) == "Color3" then
            themeData[key] = RGBToHex(color)
        end
    end
    
    local filePath = self.Folder .. "/Themes/" .. name .. ".json"
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, themeData)
    
    if not success then
        self.Library:Notify("Failed to save theme", "error")
        return false
    end
    
    writefile(filePath, encoded)
    self.CustomThemes[name] = themeData
    self.Library:Notify(string.format('Saved theme "%s"', name), "success")
    
    return true
end

function ThemeManager:DeleteCustomTheme(name)
    if not self.CustomThemes[name] then
        return false
    end
    
    local filePath = self.Folder .. "/Themes/" .. name .. ".json"
    if isfile(filePath) then
        delfile(filePath)
    end
    
    self.CustomThemes[name] = nil
    return true
end

function ThemeManager:CreateThemeSection(tab)
    local library = self.Library
    local groupbox = tab:AddRightGroupbox("Themes")
    
    -- Theme selector
    local themeList = groupbox.AddDropdown(nil, "Theme", self:GetThemeList(), false, self.CurrentTheme, function(value)
        self:ApplyTheme(value)
    end)
    
    groupbox.AddDivider()
    
    -- Custom theme section
    local customNameInput = groupbox.AddInput(nil, "Theme Name", "Enter theme name...", false, nil)
    
    groupbox.AddButton("Save Current as Theme", function()
        local name = customNameInput.Value
        if name == "" then
            library:Notify("Please enter a theme name", "error")
            return
        end
        
        if self.BuiltInThemes[name] then
            library:Notify("Cannot overwrite built-in themes", "error")
            return
        end
        
        self:SaveCustomTheme(name)
        themeList:SetValues(self:GetThemeList())
        customNameInput:SetValue("")
    end)
    
    -- Custom theme list (for loading/deleting)
    local customThemeList = groupbox.AddDropdown(nil, "Custom Themes", {}, false, nil, function(value)
        if value then
            self:ApplyTheme(value)
        end
    end)
    
    local function updateCustomThemeList()
        local customThemes = {}
        for name in pairs(self.CustomThemes) do
            table.insert(customThemes, name)
        end
        table.sort(customThemes)
        customThemeList:SetValues(customThemes)
    end
    
    updateCustomThemeList()
    
    groupbox.AddButton("Delete Custom Theme", function()
        local name = customThemeList.Value
        if not name then
            library:Notify("Please select a custom theme to delete", "error")
            return
        end
        
        self:DeleteCustomTheme(name)
        updateCustomThemeList()
        customThemeList:SetValue(nil)
        library:Notify(string.format('Deleted theme "%s"', name), "success")
    end)
    
    groupbox.AddButton("Refresh List", function()
        self:LoadCustomThemes()
        themeList:SetValues(self:GetThemeList())
        updateCustomThemeList()
        library:Notify("Theme list refreshed", "info")
    end)
    
    groupbox.AddDivider()
    
    -- Color customization
    local colorGroup = groupbox.AddLabel("Custom Colors", false)
    
    -- Color pickers for each theme color
    local colorPickers = {}
    
    local colorOptions = {
        { id = "Primary", text = "Primary Color" },
        { id = "Surface", text = "Surface Color" },
        { id = "Background", text = "Background Color" },
        { id = "Text", text = "Text Color" },
        { id = "TextSecondary", text = "Secondary Text" },
        { id = "Border", text = "Border Color" },
    }
    
    for _, opt in ipairs(colorOptions) do
        local picker = groupbox.AddColorPicker(nil, opt.text, library.Theme[opt.id], function(color)
            library.Theme[opt.id] = color
            library:UpdateColors()
        end)
        colorPickers[opt.id] = picker
    end
    
    -- Reset to default button
    groupbox.AddButton("Reset to Default Theme", function()
        self:ApplyTheme("Dark")
        -- Update color pickers
        for id, picker in pairs(colorPickers) do
            if picker then
                picker:SetValueRGB(library.Theme[id])
            end
        end
        themeList:SetValue("Dark")
        library:Notify("Reset to default theme", "success")
    end)
end

-- Helper function for RGB to hex
local function RGBToHex(color)
    return string.format("#%02x%02x%02x",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

return ThemeManager
