--[[
    SaveManager Module
    Handles saving and loading configurations
]]

local HttpService = game:GetService("HttpService")

local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager.new(library)
    local self = setmetatable({}, SaveManager)
    
    self.Library = library
    self.Folder = library.Config.Folder or "ModernUISettings"
    self.Ignore = {}
    self.CurrentConfig = nil
    
    -- Parser for different element types
    self.Parser = {
        Toggle = {
            Save = function(idx, object)
                return { type = "Toggle", id = idx, value = object.Value }
            end,
            Load = function(idx, data)
                if library.Toggles[idx] then
                    library.Toggles[idx]:SetValue(data.value)
                end
            end,
        },
        Slider = {
            Save = function(idx, object)
                return { type = "Slider", id = idx, value = object.Value }
            end,
            Load = function(idx, data)
                if library.Options[idx] then
                    library.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Dropdown = {
            Save = function(idx, object)
                return { type = "Dropdown", id = idx, value = object.Value, multi = object.Multi }
            end,
            Load = function(idx, data)
                if library.Options[idx] then
                    library.Options[idx]:SetValue(data.value)
                end
            end,
        },
        Input = {
            Save = function(idx, object)
                return { type = "Input", id = idx, value = object.Value }
            end,
            Load = function(idx, data)
                if library.Options[idx] then
                    library.Options[idx]:SetValue(data.value)
                end
            end,
        },
        ColorPicker = {
            Save = function(idx, object)
                return { 
                    type = "ColorPicker", 
                    id = idx, 
                    value = RGBToHex(object.Value),
                    r = object.Value.R,
                    g = object.Value.G,
                    b = object.Value.B,
                }
            end,
            Load = function(idx, data)
                if library.Options[idx] then
                    library.Options[idx]:SetValueRGB(Color3.new(data.r, data.g, data.b))
                end
            end,
        },
        KeyPicker = {
            Save = function(idx, object)
                return { type = "KeyPicker", id = idx, key = object.Value, mode = object.Mode }
            end,
            Load = function(idx, data)
                if library.Options[idx] then
                    library.Options[idx]:SetValue({ data.key, data.mode })
                end
            end,
        },
    }
    
    self:BuildFolderTree()
    
    return self
end

function SaveManager:SetIgnoreIndexes(list)
    for _, key in ipairs(list) do
        self.Ignore[key] = true
    end
end

function SaveManager:BuildFolderTree()
    local paths = {
        self.Folder,
        self.Folder .. "/Configs",
        self.Folder .. "/Themes",
    }
    
    for _, path in ipairs(paths) do
        if not isfolder(path) then
            makefolder(path)
        end
    end
end

function SaveManager:GetConfigList()
    local configPath = self.Folder .. "/Configs"
    local files = listfiles(configPath)
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
    
    local filePath = self.Folder .. "/Configs/" .. name .. ".json"
    local data = { objects = {}, version = self.Library.Version, date = os.date("%Y-%m-%d %H:%M:%S") }
    
    -- Save toggles
    for id, toggle in pairs(self.Library.Toggles) do
        if not self.Ignore[id] and self.Parser.Toggle then
            table.insert(data.objects, self.Parser.Toggle.Save(id, toggle))
        end
    end
    
    -- Save options
    for id, option in pairs(self.Library.Options) do
        if not self.Ignore[id] and self.Parser[option.Type] then
            table.insert(data.objects, self.Parser[option.Type].Save(id, option))
        end
    end
    
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
    
    local filePath = self.Folder .. "/Configs/" .. name .. ".json"
    if not isfile(filePath) then
        return false, "Config not found"
    end
    
    local success, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(filePath))
    if not success then
        return false, "Failed to decode config"
    end
    
    for _, object in ipairs(decoded.objects) do
        if self.Parser[object.type] then
            task.spawn(function()
                self.Parser[object.type].Load(object.id, object)
            end)
        end
    end
    
    self.CurrentConfig = name
    return true
end

function SaveManager:Delete(name)
    if not name or name == "" then
        return false, "No config name provided"
    end
    
    local filePath = self.Folder .. "/Configs/" .. name .. ".json"
    if not isfile(filePath) then
        return false, "Config not found"
    end
    
    delfile(filePath)
    
    if self.CurrentConfig == name then
        self.CurrentConfig = nil
    end
    
    return true
end

function SaveManager:CreateConfigSection(tab)
    local library = self.Library
    local groupbox = tab:AddLeftGroupbox("Configuration")
    
    -- Config name input
    local nameInput = groupbox.AddInput(nil, "Config Name", "Enter config name...", false, nil)
    
    -- Config list dropdown
    local configList = groupbox.AddDropdown(nil, "Config List", self:GetConfigList(), false, nil, nil)
    
    groupbox.AddDivider()
    
    -- Buttons
    groupbox.AddButton("Save Config", function()
        local name = nameInput.Value
        if name == "" then
            library:Notify("Please enter a config name", "error")
            return
        end
        
        local success, err = self:Save(name)
        if success then
            library:Notify(string.format('Saved config "%s"', name), "success")
            configList:SetValues(self:GetConfigList())
            nameInput:SetValue("")
        else
            library:Notify("Failed to save config: " .. err, "error")
        end
    end)
    
    groupbox.AddButton("Load Config", function()
        local name = configList.Value
        if not name then
            library:Notify("Please select a config to load", "error")
            return
        end
        
        local success, err = self:Load(name)
        if success then
            library:Notify(string.format('Loaded config "%s"', name), "success")
        else
            library:Notify("Failed to load config: " .. err, "error")
        end
    end)
    
    groupbox.AddButton("Overwrite Config", function()
        local name = configList.Value
        if not name then
            library:Notify("Please select a config to overwrite", "error")
            return
        end
        
        local success, err = self:Save(name)
        if success then
            library:Notify(string.format('Overwrote config "%s"', name), "success")
        else
            library:Notify("Failed to overwrite config: " .. err, "error")
        end
    end)
    
    groupbox.AddButton("Delete Config", function()
        local name = configList.Value
        if not name then
            library:Notify("Please select a config to delete", "error")
            return
        end
        
        local success, err = self:Delete(name)
        if success then
            library:Notify(string.format('Deleted config "%s"', name), "success")
            configList:SetValues(self:GetConfigList())
            configList:SetValue(nil)
        else
            library:Notify("Failed to delete config: " .. err, "error")
        end
    end)
    
    groupbox.AddButton("Refresh List", function()
        configList:SetValues(self:GetConfigList())
        library:Notify("Config list refreshed", "info")
    end)
    
    groupbox.AddDivider()
    
    -- Autoload section
    local autoloadLabel = groupbox.AddLabel("Current autoload: none", true)
    
    groupbox.AddButton("Set as Autoload", function()
        local name = configList.Value
        if not name then
            library:Notify("Please select a config to autoload", "error")
            return
        end
        
        local autoloadPath = self.Folder .. "/autoload.txt"
        writefile(autoloadPath, name)
        autoloadLabel.Text = "Current autoload: " .. name
        library:Notify(string.format('Set "%s" as autoload config', name), "success")
    end)
    
    -- Load autoload config if exists
    local autoloadPath = self.Folder .. "/autoload.txt"
    if isfile(autoloadPath) then
        local autoloadName = readfile(autoloadPath)
        autoloadLabel.Text = "Current autoload: " .. autoloadName
        task.spawn(function()
            self:Load(autoloadName)
        end)
    end
    
    -- Ignore UI elements from saving
    self:SetIgnoreIndexes({
        "SaveManager_ConfigName",
        "SaveManager_ConfigList",
        "ThemeManager_ThemeList",
        "ThemeManager_CustomThemeList",
    })
end

-- Helper function for RGB to hex (needed for color saving)
local function RGBToHex(color)
    return string.format("%02x%02x%02x",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

return SaveManager
