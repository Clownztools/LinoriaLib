--[[
    SaveManager for Woodie UI
    Handles saving and loading configurations
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager.new(ui, options)
    local self = setmetatable({}, SaveManager)
    
    self.UI = ui
    self.Folder = options.Folder or "WoodieScript/Configs"
    self.AutoSave = options.AutoSave or true
    self.CurrentConfig = nil
    self.IgnoreList = {}
    
    self:CreateFolder()
    
    return self
end

function SaveManager:CreateFolder()
    if not isfolder then return end
    
    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
end

function SaveManager:GetConfigList()
    if not isfolder then return {} end
    
    local files = listfiles(self.Folder)
    local configs = {}
    
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    
    table.sort(configs)
    return configs
end

function SaveManager:Save(name)
    if not name or name == "" then
        return false, "No config name provided"
    end
    
    local data = {
        version = "1.0",
        date = os.date("%Y-%m-%d %H:%M:%S"),
        toggles = {},
        options = {},
    }
    
    -- Save toggles
    for id, toggle in pairs(self.UI.Toggles) do
        if not self.IgnoreList[id] then
            data.toggles[id] = toggle.Value
        end
    end
    
    -- Save options
    for id, option in pairs(self.UI.Options) do
        if not self.IgnoreList[id] then
            if option.Type == "Slider" then
                data.options[id] = option.Value
            elseif option.Type == "Dropdown" then
                data.options[id] = option.Value
            elseif option.Type == "Input" then
                data.options[id] = option.Value
            elseif option.Type == "Keybind" then
                data.options[id] = option.Value
            elseif option.Type == "ColorPicker" then
                data.options[id] = {
                    R = option.Value.R,
                    G = option.Value.G,
                    B = option.Value.B,
                }
            end
        end
    end
    
    local filePath = self.Folder .. "/" .. name .. ".json"
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    
    if not success then
        return false, "Failed to encode data"
    end
    
    writefile(filePath, encoded)
    self.CurrentConfig = name
    return true
end

function SaveManager:Load(name)
    if not name or name == "" then
        return false, "No config name provided"
    end
    
    local filePath = self.Folder .. "/" .. name .. ".json"
    if not isfile(filePath) then
        return false, "Config not found"
    end
    
    local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(filePath))
    if not success then
        return false, "Failed to decode config"
    end
    
    -- Load toggles
    for id, value in pairs(decoded.toggles or {}) do
        if self.UI.Toggles[id] then
            self.UI.Toggles[id]:SetValue(value)
        end
    end
    
    -- Load options
    for id, value in pairs(decoded.options or {}) do
        if self.UI.Options[id] then
            if type(value) == "table" and value.R then
                -- ColorPicker
                self.UI.Options[id]:SetValueRGB(Color3.new(value.R, value.G, value.B))
            else
                self.UI.Options[id]:SetValue(value)
            end
        end
    end
    
    self.CurrentConfig = name
    self.UI:Notify(string.format('Loaded config "%s"', name), "success")
    return true
end

function SaveManager:Delete(name)
    if not name or name == "" then
        return false, "No config name provided"
    end
    
    local filePath = self.Folder .. "/" .. name .. ".json"
    if not isfile(filePath) then
        return false, "Config not found"
    end
    
    delfile(filePath)
    
    if self.CurrentConfig == name then
        self.CurrentConfig = nil
    end
    
    return true
end

function SaveManager:AutoSave()
    if self.AutoSave and self.CurrentConfig then
        self:Save(self.CurrentConfig)
    end
end

function SaveManager:SetIgnoreIndexes(list)
    for _, id in ipairs(list) do
        self.IgnoreList[id] = true
    end
end

function SaveManager:CreateConfigSection(tab)
    local groupbox = tab:AddRightGroupbox("Configuration")
    
    -- Config name input
    local configName = groupbox.AddInput("SaveConfigName", "Config Name", "Enter config name...", function() end)
    
    -- Config list dropdown
    local configList = groupbox.AddDropdown("SaveConfigList", "Config List", self:GetConfigList(), nil, function(value)
        if value then
            configName:SetValue(value)
        end
    end)
    
    groupbox.AddDivider()
    
    -- Buttons
    groupbox.AddButton("Save Config", function()
        local name = configName.Value
        if name == "" then
            self.UI:Notify("Please enter a config name", "error")
            return
        end
        
        local success, err = self:Save(name)
        if success then
            self.UI:Notify(string.format('Saved config "%s"', name), "success")
            configList:SetValues(self:GetConfigList())
            configList:SetValue(name)
        else
            self.UI:Notify("Failed to save: " .. err, "error")
        end
    end)
    
    groupbox.AddButton("Load Config", function()
        local name = configList.Value
        if not name then
            self.UI:Notify("Please select a config", "error")
            return
        end
        
        self:Load(name)
    end)
    
    groupbox.AddButton("Overwrite Config", function()
        local name = configList.Value
        if not name then
            self.UI:Notify("Please select a config", "error")
            return
        end
        
        local success, err = self:Save(name)
        if success then
            self.UI:Notify(string.format('Overwrote "%s"', name), "success")
        else
            self.UI:Notify("Failed to overwrite: " .. err, "error")
        end
    end)
    
    groupbox.AddButton("Delete Config", function()
        local name = configList.Value
        if not name then
            self.UI:Notify("Please select a config", "error")
            return
        end
        
        self:Delete(name)
        configList:SetValues(self:GetConfigList())
        configList:SetValue(nil)
        configName:SetValue("")
        self.UI:Notify(string.format('Deleted "%s"', name), "success")
    end)
    
    groupbox.AddButton("Refresh List", function()
        configList:SetValues(self:GetConfigList())
        self.UI:Notify("Config list refreshed", "info")
    end)
    
    groupbox.AddDivider()
    
    -- Auto-save toggle
    local autoSaveToggle = groupbox.AddToggle("AutoSave", "Auto Save", self.AutoSave, function(value)
        self.AutoSave = value
    end)
    
    -- Set ignore list for UI elements
    self:SetIgnoreIndexes({
        "SaveConfigName",
        "SaveConfigList",
        "AutoSave",
        "ThemeList",
        "CustomThemeName",
        "CustomThemeList",
    })
    
    return groupbox
end

return SaveManager
