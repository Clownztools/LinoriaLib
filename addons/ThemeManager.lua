--[[
    ThemeManager for Woodie UI
    Handles theme switching and custom themes
]]

local HttpService = game:GetService("HttpService")

local ThemeManager = {}
ThemeManager.__index = ThemeManager

function ThemeManager.new(ui, options)
    local self = setmetatable({}, ThemeManager)
    
    self.UI = ui
    self.Folder = options.Folder or "WoodieScript/Themes"
    self.CurrentTheme = options.DefaultTheme or "Dark"
    
    -- Built-in themes
    self.BuiltInThemes = {
        Dark = {
            Background = Color3.fromRGB(30, 30, 35),
            Surface = Color3.fromRGB(40, 40, 45),
            Primary = Color3.fromRGB(88, 101, 242),
            PrimaryDark = Color3.fromRGB(71, 82, 196),
            Text = Color3.fromRGB(255, 255, 255),
            TextSecondary = Color3.fromRGB(160, 160, 170),
            Border = Color3.fromRGB(55, 55, 65),
            Danger = Color3.fromRGB(237, 66, 69),
            Success = Color3.fromRGB(60, 200, 100),
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
        },
    }
    
    self.CustomThemes = {}
    self:LoadCustomThemes()
    
    return self
end

function ThemeManager:LoadCustomThemes()
    if not isfolder then return end
    
    local themesPath = self.Folder
    if not isfolder(themesPath) then
        makefolder(themesPath)
    end
    
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
    if not theme then return false end
    
    self.UI:ApplyTheme(theme)
    self.CurrentTheme = themeName
    return true
end

function ThemeManager:SaveCustomTheme(name)
    if not name or name == "" then
        self.UI:Notify("Please enter a theme name", "error")
        return false
    end
    
    if self.BuiltInThemes[name] then
        self.UI:Notify("Cannot overwrite built-in themes", "error")
        return false
    end
    
    local themeData = {
        name = name,
        Background = RGBToHex(self.UI.Theme.Background),
        Surface = RGBToHex(self.UI.Theme.Surface),
        Primary = RGBToHex(self.UI.Theme.Primary),
        PrimaryDark = RGBToHex(self.UI.Theme.PrimaryDark),
        Text = RGBToHex(self.UI.Theme.Text),
        TextSecondary = RGBToHex(self.UI.Theme.TextSecondary),
        Border = RGBToHex(self.UI.Theme.Border),
        Danger = RGBToHex(self.UI.Theme.Danger),
        Success = RGBToHex(self.UI.Theme.Success),
    }
    
    local filePath = self.Folder .. "/" .. name .. ".json"
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, themeData)
    
    if not success then
        self.UI:Notify("Failed to save theme", "error")
        return false
    end
    
    writefile(filePath, encoded)
    self.CustomThemes[name] = themeData
    self.UI:Notify(string.format('Saved theme "%s"', name), "success")
    return true
end

function ThemeManager:DeleteCustomTheme(name)
    if not self.CustomThemes[name] then
        return false
    end
    
    local filePath = self.Folder .. "/" .. name .. ".json"
    if isfile(filePath) then
        delfile(filePath)
    end
    
    self.CustomThemes[name] = nil
    return true
end

function ThemeManager:CreateThemeSection(tab)
    local groupbox = tab:AddLeftGroupbox("Themes")
    
    local themeList = groupbox.AddDropdown("ThemeList", "Theme", self:GetThemeList(), self.CurrentTheme, function(value)
        self:ApplyTheme(value)
    end)
    
    groupbox.AddDivider()
    
    local customName = groupbox.AddInput("CustomThemeName", "Theme Name", "Enter theme name...", function() end)
    
    groupbox.AddButton("Save Current Theme", function()
        self:SaveCustomTheme(customName.Value)
        themeList:SetValues(self:GetThemeList())
        customName:SetValue("")
    end)
    
    local customThemes = {}
    for name in pairs(self.CustomThemes) do
        table.insert(customThemes, name)
    end
    table.sort(customThemes)
    
    local customList = groupbox.AddDropdown("CustomThemeList", "Custom Themes", customThemes, nil, function(value)
        if value then self:ApplyTheme(value) end
    end)
    
    groupbox.AddButton("Delete Custom Theme", function()
        local name = customList.Value
        if not name then
            self.UI:Notify("Select a theme to delete", "error")
            return
        end
        self:DeleteCustomTheme(name)
        themeList:SetValues(self:GetThemeList())
        customList:SetValues(self:GetCustomThemeNames())
        customList:SetValue(nil)
        self.UI:Notify(string.format('Deleted "%s"', name), "success")
    end)
    
    groupbox.AddButton("Refresh Themes", function()
        self:LoadCustomThemes()
        themeList:SetValues(self:GetThemeList())
        customList:SetValues(self:GetCustomThemeNames())
        self.UI:Notify("Theme list refreshed", "info")
    end)
    
    return groupbox
end

function ThemeManager:GetCustomThemeNames()
    local names = {}
    for name in pairs(self.CustomThemes) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

local function RGBToHex(color)
    return string.format("#%02x%02x%02x",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

return ThemeManager
