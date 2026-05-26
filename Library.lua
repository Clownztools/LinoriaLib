--[[
    Woodie UI Library
    Complete UI system with Theme and Save management
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WoodieUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end
end)

ScreenGui.Parent = CoreGui

-- UI Elements storage
local UI = {
    Windows = {},
    Toggles = {},
    Options = {},
    ScreenGui = ScreenGui,
    ActiveWindow = nil,
    Theme = {
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
    SaveManager = nil,
    ThemeManager = nil,
}

-- Helper functions
local function GetTextBounds(text, size)
    local textService = game:GetService("TextService")
    local bounds = textService:GetTextSize(text, size, Enum.Font.Gotham, Vector2.new(1920, 1080))
    return bounds.X, bounds.Y
end

-- Create window
function UI:CreateWindow(title, options)
    options = options or {}
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Name = title
    frame.BackgroundColor3 = self.Theme.Background
    frame.BorderColor3 = self.Theme.Border
    frame.BorderSizePixel = 1
    frame.Position = options.Position or UDim2.fromOffset(100, 100)
    frame.Size = options.Size or UDim2.fromOffset(550, 500)
    frame.Visible = false
    frame.ClipsDescendants = true
    frame.Parent = ScreenGui
    
    -- Shadow
    local shadow = Instance.new("Frame")
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.6
    shadow.BorderSizePixel = 0
    shadow.Position = UDim2.new(0, 5, 0, 5)
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.ZIndex = -1
    shadow.Parent = frame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.BackgroundColor3 = self.Theme.Surface
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.Parent = frame
    
    -- Accent line
    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = self.Theme.Primary
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(1, 0, 0, 2)
    accent.Parent = titleBar
    
    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.Text = title
    titleLabel.TextColor3 = self.Theme.Text
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundTransparency = 1
    closeBtn.Position = UDim2.new(1, -35, 0, 0)
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = self.Theme.TextSecondary
    closeBtn.TextSize = 14
    closeBtn.Parent = titleBar
    
    closeBtn.MouseEnter:Connect(function()
        closeBtn.TextColor3 = self.Theme.Danger
    end)
    
    closeBtn.MouseLeave:Connect(function()
        closeBtn.TextColor3 = self.Theme.TextSecondary
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
        UI.ActiveWindow = nil
    end)
    
    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.BackgroundColor3 = self.Theme.Surface
    tabBar.BorderSizePixel = 0
    tabBar.Position = UDim2.new(0, 0, 0, 35)
    tabBar.Size = UDim2.new(1, 0, 0, 35)
    tabBar.Parent = frame
    
    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.BackgroundTransparency = 1
    contentArea.Position = UDim2.new(0, 12, 0, 70)
    contentArea.Size = UDim2.new(1, -24, 1, -82)
    contentArea.Parent = frame
    
    -- Left column
    local leftColumn = Instance.new("ScrollingFrame")
    leftColumn.BackgroundTransparency = 1
    leftColumn.Position = UDim2.new(0, 0, 0, 0)
    leftColumn.Size = UDim2.new(0.5, -6, 1, 0)
    leftColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
    leftColumn.ScrollBarThickness = 4
    leftColumn.ScrollBarImageColor3 = self.Theme.Primary
    leftColumn.Parent = contentArea
    
    -- Right column
    local rightColumn = Instance.new("ScrollingFrame")
    rightColumn.BackgroundTransparency = 1
    rightColumn.Position = UDim2.new(0.5, 6, 0, 0)
    rightColumn.Size = UDim2.new(0.5, -6, 1, 0)
    rightColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
    rightColumn.ScrollBarThickness = 4
    rightColumn.ScrollBarImageColor3 = self.Theme.Primary
    rightColumn.Parent = contentArea
    
    -- Layouts
    local leftLayout = Instance.new("UIListLayout")
    leftLayout.Padding = UDim.new(0, 8)
    leftLayout.FillDirection = Enum.FillDirection.Vertical
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Parent = leftColumn
    
    local rightLayout = Instance.new("UIListLayout")
    rightLayout.Padding = UDim.new(0, 8)
    rightLayout.FillDirection = Enum.FillDirection.Vertical
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.Parent = rightColumn
    
    -- Update canvas sizes
    leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        leftColumn.CanvasSize = UDim2.new(0, 0, 0, leftLayout.AbsoluteContentSize.Y)
    end)
    
    rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        rightColumn.CanvasSize = UDim2.new(0, 0, 0, rightLayout.AbsoluteContentSize.Y)
    end)
    
    -- Dragging functionality
    local dragging = false
    local dragStart = Vector2.new()
    local frameStart = frame.Position
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = Vector2.new(Mouse.X, Mouse.Y)
            frameStart = frame.Position
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = Vector2.new(Mouse.X, Mouse.Y) - dragStart
            frame.Position = UDim2.new(
                frameStart.X.Scale,
                frameStart.X.Offset + delta.X,
                frameStart.Y.Scale,
                frameStart.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Tab management
    local tabs = {}
    local activeTab = nil
    
    -- Window API
    local windowAPI = {
        Frame = frame,
        LeftColumn = leftColumn,
        RightColumn = rightColumn,
        Tabs = tabs,
        
        AddTab = function(name)
            -- Tab button
            local button = Instance.new("TextButton")
            button.BackgroundTransparency = 1
            button.Size = UDim2.new(0, 100, 1, 0)
            button.Font = Enum.Font.Gotham
            button.Text = name
            button.TextColor3 = self.Theme.TextSecondary
            button.TextSize = 13
            button.Parent = tabBar
            
            -- Tab content
            local tabFrame = Instance.new("Frame")
            tabFrame.BackgroundTransparency = 1
            tabFrame.Size = UDim2.new(1, 0, 1, 0)
            tabFrame.Visible = false
            tabFrame.Parent = contentArea
            
            local tabLeft = Instance.new("ScrollingFrame")
            tabLeft.BackgroundTransparency = 1
            tabLeft.Size = UDim2.new(0.5, -6, 1, 0)
            tabLeft.CanvasSize = UDim2.new(0, 0, 0, 0)
            tabLeft.ScrollBarThickness = 4
            tabLeft.ScrollBarImageColor3 = self.Theme.Primary
            tabLeft.Parent = tabFrame
            
            local tabRight = Instance.new("ScrollingFrame")
            tabRight.BackgroundTransparency = 1
            tabRight.Position = UDim2.new(0.5, 6, 0, 0)
            tabRight.Size = UDim2.new(0.5, -6, 1, 0)
            tabRight.CanvasSize = UDim2.new(0, 0, 0, 0)
            tabRight.ScrollBarThickness = 4
            tabRight.ScrollBarImageColor3 = self.Theme.Primary
            tabRight.Parent = tabFrame
            
            local tabLeftLayout = Instance.new("UIListLayout")
            tabLeftLayout.Padding = UDim.new(0, 8)
            tabLeftLayout.FillDirection = Enum.FillDirection.Vertical
            tabLeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
            tabLeftLayout.Parent = tabLeft
            
            local tabRightLayout = Instance.new("UIListLayout")
            tabRightLayout.Padding = UDim.new(0, 8)
            tabRightLayout.FillDirection = Enum.FillDirection.Vertical
            tabRightLayout.SortOrder = Enum.SortOrder.LayoutOrder
            tabRightLayout.Parent = tabRight
            
            tabLeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                tabLeft.CanvasSize = UDim2.new(0, 0, 0, tabLeftLayout.AbsoluteContentSize.Y)
            end)
            
            tabRightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                tabRight.CanvasSize = UDim2.new(0, 0, 0, tabRightLayout.AbsoluteContentSize.Y)
            end)
            
            local tabAPI = {
                Name = name,
                Frame = tabFrame,
                Button = button,
                LeftColumn = tabLeft,
                RightColumn = tabRight,
                
                AddLeftGroupbox = function(title)
                    return windowAPI.AddGroupbox(tabAPI, "left", title)
                end,
                
                AddRightGroupbox = function(title)
                    return windowAPI.AddGroupbox(tabAPI, "right", title)
                end,
            }
            
            button.MouseButton1Click:Connect(function()
                if activeTab then
                    activeTab.Button.TextColor3 = self.Theme.TextSecondary
                    activeTab.Frame.Visible = false
                end
                activeTab = tabAPI
                button.TextColor3 = self.Theme.Primary
                tabFrame.Visible = true
            end)
            
            table.insert(tabs, tabAPI)
            
            if #tabs == 1 then
                button.TextColor3 = self.Theme.Primary
                tabFrame.Visible = true
                activeTab = tabAPI
            end
            
            return tabAPI
        end,
        
        AddGroupbox = function(tab, side, title)
            local groupbox = Instance.new("Frame")
            groupbox.BackgroundColor3 = self.Theme.Surface
            groupbox.BorderColor3 = self.Theme.Border
            groupbox.BorderSizePixel = 1
            groupbox.Size = UDim2.new(1, 0, 0, 0)
            groupbox.AutomaticSize = Enum.AutomaticSize.Y
            groupbox.Parent = (side == "left" and tab.LeftColumn or tab.RightColumn)
            
            local header = Instance.new("Frame")
            header.BackgroundColor3 = self.Theme.Background
            header.BorderSizePixel = 0
            header.Size = UDim2.new(1, 0, 0, 30)
            header.Parent = groupbox
            
            local headerAccent = Instance.new("Frame")
            headerAccent.BackgroundColor3 = self.Theme.Primary
            headerAccent.BorderSizePixel = 0
            headerAccent.Size = UDim2.new(0, 3, 1, 0)
            headerAccent.Parent = header
            
            local titleLabel = Instance.new("TextLabel")
            titleLabel.BackgroundTransparency = 1
            titleLabel.Position = UDim2.new(0, 12, 0, 0)
            titleLabel.Size = UDim2.new(1, -24, 1, 0)
            titleLabel.Font = Enum.Font.Gotham
            titleLabel.Text = title
            titleLabel.TextColor3 = self.Theme.Text
            titleLabel.TextSize = 12
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = header
            
            local container = Instance.new("Frame")
            container.BackgroundTransparency = 1
            container.Position = UDim2.new(0, 10, 0, 38)
            container.Size = UDim2.new(1, -20, 0, 0)
            container.AutomaticSize = Enum.AutomaticSize.Y
            container.Parent = groupbox
            
            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 6)
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = container
            
            local groupboxAPI = {
                Frame = groupbox,
                Container = container,
                
                AddButton = function(text, callback, doubleClick)
                    local button = Instance.new("TextButton")
                    button.BackgroundColor3 = self.Theme.Background
                    button.BorderColor3 = self.Theme.Border
                    button.BorderSizePixel = 1
                    button.Size = UDim2.new(1, 0, 0, 32)
                    button.Font = Enum.Font.Gotham
                    button.Text = text
                    button.TextColor3 = self.Theme.Text
                    button.TextSize = 13
                    button.Parent = container
                    
                    button.MouseEnter:Connect(function()
                        TweenService:Create(button, TweenInfo.new(0.2), {
                            BackgroundColor3 = self.Theme.Primary
                        }):Play()
                    end)
                    
                    button.MouseLeave:Connect(function()
                        TweenService:Create(button, TweenInfo.new(0.2), {
                            BackgroundColor3 = self.Theme.Background
                        }):Play()
                    end)
                    
                    button.MouseButton1Click:Connect(function()
                        if doubleClick then
                            if not button.DoubleClickReady then
                                button.DoubleClickReady = true
                                local originalText = button.Text
                                button.Text = "Confirm?"
                                task.delay(1.5, function()
                                    if button then
                                        button.DoubleClickReady = false
                                        button.Text = originalText
                                    end
                                end)
                            else
                                button.DoubleClickReady = false
                                if callback then callback() end
                                button.Text = text
                            end
                        else
                            if callback then callback() end
                        end
                    end)
                    
                    return button
                end,
                
                AddToggle = function(id, text, default, callback)
                    local toggle = {
                        Value = default or false,
                        Id = id,
                        Callback = callback or function() end,
                    }
                    
                    local frame = Instance.new("Frame")
                    frame.BackgroundTransparency = 1
                    frame.Size = UDim2.new(1, 0, 0, 32)
                    frame.Parent = container
                    
                    local button = Instance.new("TextButton")
                    button.BackgroundColor3 = toggle.Value and self.Theme.Primary or self.Theme.Background
                    button.BorderColor3 = self.Theme.Border
                    button.BorderSizePixel = 1
                    button.Position = UDim2.new(0, 0, 0, 4)
                    button.Size = UDim2.new(0, 24, 0, 24)
                    button.Font = Enum.Font.Gotham
                    button.Text = toggle.Value and "✓" or ""
                    button.TextColor3 = self.Theme.Text
                    button.TextSize = 14
                    button.Parent = frame
                    
                    local label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.Position = UDim2.new(0, 32, 0, 0)
                    label.Size = UDim2.new(1, -32, 1, 0)
                    label.Font = Enum.Font.Gotham
                    label.Text = text
                    label.TextColor3 = self.Theme.Text
                    label.TextSize = 13
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.Parent = frame
                    
                    function toggle:SetValue(value)
                        toggle.Value = value
                        button.Text = value and "✓" or ""
                        button.BackgroundColor3 = value and self.Theme.Primary or self.Theme.Background
                        if callback then callback(value) end
                        if UI.SaveManager then UI.SaveManager:AutoSave() end
                    end
                    
                    button.MouseButton1Click:Connect(function()
                        toggle:SetValue(not toggle.Value)
                    end)
                    
                    UI.Toggles[id] = toggle
                    return toggle
                end,
                
                AddSlider = function(id, text, min, max, default, suffix, callback)
                    local slider = {
                        Value = default or min,
                        Min = min or 0,
                        Max = max or 100,
                        Id = id,
                        Callback = callback or function() end,
                    }
                    
                    local frame = Instance.new("Frame")
                    frame.BackgroundTransparency = 1
                    frame.Size = UDim2.new(1, 0, 0, 55)
                    frame.Parent = container
                    
                    local label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(1, 0, 0, 20)
                    label.Font = Enum.Font.Gotham
                    label.Text = text
                    label.TextColor3 = self.Theme.Text
                    label.TextSize = 13
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.Parent = frame
                    
                    local valueLabel = Instance.new("TextLabel")
                    valueLabel.BackgroundTransparency = 1
                    valueLabel.Size = UDim2.new(1, -10, 0, 20)
                    valueLabel.Font = Enum.Font.Gotham
                    valueLabel.Text = tostring(slider.Value) .. (suffix or "")
                    valueLabel.TextColor3 = self.Theme.Primary
                    valueLabel.TextSize = 12
                    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    valueLabel.Parent = frame
                    
                    local bg = Instance.new("Frame")
                    bg.BackgroundColor3 = self.Theme.Background
                    bg.BorderColor3 = self.Theme.Border
                    bg.BorderSizePixel = 1
                    bg.Position = UDim2.new(0, 0, 0, 25)
                    bg.Size = UDim2.new(1, 0, 0, 4)
                    bg.Parent = frame
                    
                    local fill = Instance.new("Frame")
                    fill.BackgroundColor3 = self.Theme.Primary
                    fill.BorderSizePixel = 0
                    fill.Size = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), 0, 1, 0)
                    fill.Parent = bg
                    
                    local handle = Instance.new("TextButton")
                    handle.BackgroundColor3 = self.Theme.Primary
                    handle.BorderColor3 = self.Theme.PrimaryDark
                    handle.BorderSizePixel = 1
                    handle.Position = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), -6, 0, -4)
                    handle.Size = UDim2.new(0, 12, 0, 12)
                    handle.Text = ""
                    handle.Parent = bg
                    
                    local function updateSlider(value)
                        value = math.clamp(value, slider.Min, slider.Max)
                        slider.Value = value
                        local percent = (value - slider.Min) / (slider.Max - slider.Min)
                        fill.Size = UDim2.new(percent, 0, 1, 0)
                        handle.Position = UDim2.new(percent, -6, 0, -4)
                        valueLabel.Text = tostring(math.floor(value)) .. (suffix or "")
                        if callback then callback(value) end
                        if UI.SaveManager then UI.SaveManager:AutoSave() end
                    end
                    
                    local dragging = false
                    handle.MouseButton1Down:Connect(function()
                        dragging = true
                        while dragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            local percent = math.clamp((Mouse.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
                            local value = slider.Min + (slider.Max - slider.Min) * percent
                            updateSlider(value)
                            RunService.RenderStepped:Wait()
                        end
                        dragging = false
                    end)
                    
                    function slider:SetValue(value)
                        updateSlider(value)
                    end
                    
                    UI.Options[id] = slider
                    return slider
                end,
                
                AddDropdown = function(id, text, values, default, callback)
                    local dropdown = {
                        Values = values,
                        Value = default or values[1],
                        Id = id,
                        Callback = callback or function() end,
                        Open = false,
                    }
                    
                    local frame = Instance.new("Frame")
                    frame.BackgroundTransparency = 1
                    frame.Size = UDim2.new(1, 0, 0, 0)
                    frame.AutomaticSize = Enum.AutomaticSize.Y
                    frame.Parent = container
                    
                    local label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(1, 0, 0, 20)
                    label.Font = Enum.Font.Gotham
                    label.Text = text
                    label.TextColor3 = self.Theme.Text
                    label.TextSize = 13
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.Parent = frame
                    
                    local button = Instance.new("TextButton")
                    button.BackgroundColor3 = self.Theme.Background
                    button.BorderColor3 = self.Theme.Border
                    button.BorderSizePixel = 1
                    button.Position = UDim2.new(0, 0, 0, 22)
                    button.Size = UDim2.new(1, 0, 0, 30)
                    button.Font = Enum.Font.Gotham
                    button.Text = dropdown.Value
                    button.TextColor3 = self.Theme.Text
                    button.TextSize = 13
                    button.TextXAlignment = Enum.TextXAlignment.Left
                    button.Parent = frame
                    
                    local arrow = Instance.new("TextLabel")
                    arrow.BackgroundTransparency = 1
                    arrow.Position = UDim2.new(1, -25, 0, 0)
                    arrow.Size = UDim2.new(0, 20, 1, 0)
                    arrow.Font = Enum.Font.Gotham
                    arrow.Text = "▼"
                    arrow.TextColor3 = self.Theme.TextSecondary
                    arrow.TextSize = 12
                    arrow.Parent = button
                    
                    local list = Instance.new("Frame")
                    list.BackgroundColor3 = self.Theme.Surface
                    list.BorderColor3 = self.Theme.Border
                    list.BorderSizePixel = 1
                    list.Position = UDim2.new(0, 0, 1, 2)
                    list.Size = UDim2.new(1, 0, 0, 0)
                    list.Visible = false
                    list.ClipsDescendants = true
                    list.ZIndex = 10
                    list.Parent = button
                    
                    local listLayout = Instance.new("UIListLayout")
                    listLayout.Padding = UDim.new(0, 0)
                    listLayout.FillDirection = Enum.FillDirection.Vertical
                    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    listLayout.Parent = list
                    
                    local function updateList()
                        for _, child in ipairs(list:GetChildren()) do
                            if child:IsA("TextButton") then child:Destroy() end
                        end
                        
                        for _, value in ipairs(values) do
                            local item = Instance.new("TextButton")
                            item.BackgroundColor3 = (dropdown.Value == value) and self.Theme.Primary or self.Theme.Surface
                            item.BorderSizePixel = 0
                            item.Size = UDim2.new(1, 0, 0, 30)
                            item.Font = Enum.Font.Gotham
                            item.Text = value
                            item.TextColor3 = self.Theme.Text
                            item.TextSize = 13
                            item.Parent = list
                            
                            item.MouseEnter:Connect(function()
                                if dropdown.Value ~= value then
                                    item.BackgroundColor3 = self.Theme.Primary
                                end
                            end)
                            
                            item.MouseLeave:Connect(function()
                                if dropdown.Value ~= value then
                                    item.BackgroundColor3 = self.Theme.Surface
                                end
                            end)
                            
                            item.MouseButton1Click:Connect(function()
                                dropdown.Value = value
                                button.Text = value
                                dropdown.Open = false
                                list.Visible = false
                                arrow.Text = "▼"
                                updateList()
                                if callback then callback(value) end
                                if UI.SaveManager then UI.SaveManager:AutoSave() end
                            end)
                        end
                        
                        local count = #values
                        list.Size = UDim2.new(1, 0, 0, math.min(count * 30, 150))
                    end
                    
                    button.MouseButton1Click:Connect(function()
                        dropdown.Open = not dropdown.Open
                        list.Visible = dropdown.Open
                        arrow.Text = dropdown.Open and "▲" or "▼"
                        if dropdown.Open then updateList() end
                    end)
                    
                    function dropdown:SetValue(value)
                        dropdown.Value = value
                        button.Text = value
                        if callback then callback(value) end
                        if UI.SaveManager then UI.SaveManager:AutoSave() end
                    end
                    
                    function dropdown:SetValues(newValues)
                        dropdown.Values = newValues
                        updateList()
                    end
                    
                    UI.Options[id] = dropdown
                    return dropdown
                end,
                
                AddInput = function(id, text, placeholder, callback)
                    local input = {
                        Value = "",
                        Id = id,
                        Callback = callback or function() end,
                    }
                    
                    local frame = Instance.new("Frame")
                    frame.BackgroundTransparency = 1
                    frame.Size = UDim2.new(1, 0, 0, 55)
                    frame.Parent = container
                    
                    local label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(1, 0, 0, 20)
                    label.Font = Enum.Font.Gotham
                    label.Text = text
                    label.TextColor3 = self.Theme.Text
                    label.TextSize = 13
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.Parent = frame
                    
                    local box = Instance.new("TextBox")
                    box.BackgroundColor3 = self.Theme.Background
                    box.BorderColor3 = self.Theme.Border
                    box.BorderSizePixel = 1
                    box.Position = UDim2.new(0, 0, 0, 22)
                    box.Size = UDim2.new(1, 0, 0, 30)
                    box.Font = Enum.Font.Gotham
                    box.PlaceholderColor3 = self.Theme.TextSecondary
                    box.PlaceholderText = placeholder or ""
                    box.Text = ""
                    box.TextColor3 = self.Theme.Text
                    box.TextSize = 13
                    box.TextXAlignment = Enum.TextXAlignment.Left
                    box.Parent = frame
                    
                    box:GetPropertyChangedSignal("Text"):Connect(function()
                        input.Value = box.Text
                        if callback then callback(box.Text) end
                        if UI.SaveManager then UI.SaveManager:AutoSave() end
                    end)
                    
                    function input:SetValue(value)
                        input.Value = value
                        box.Text = value
                        if callback then callback(value) end
                        if UI.SaveManager then UI.SaveManager:AutoSave() end
                    end
                    
                    UI.Options[id] = input
                    return input
                end,
                
                AddColorPicker = function(id, text, default, callback)
                    local colorPicker = {
                        Value = default or Color3.fromRGB(255, 255, 255),
                        Id = id,
                        Callback = callback or function() end,
                        Open = false,
                    }
                    
                    local r, g, b = colorPicker.Value.R, colorPicker.Value.G, colorPicker.Value.B
                    
                    local frame = Instance.new("Frame")
                    frame.BackgroundTransparency = 1
                    frame.Size = UDim2.new(1, 0, 0, 55)
                    frame.Parent = container
                    
                    local label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(0.5, 0, 0, 20)
                    label.Font = Enum.Font.Gotham
                    label.Text = text
                    label.TextColor3 = self.Theme.Text
                    label.TextSize = 13
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.Parent = frame
                    
                    local display = Instance.new("TextButton")
                    display.BackgroundColor3 = colorPicker.Value
                    display.BorderColor3 = self.Theme.Border
                    display.BorderSizePixel = 1
                    display.Position = UDim2.new(0.5, 10, 0, 22)
                    display.Size = UDim2.new(0.5, -20, 0, 30)
                    display.Text = ""
                    display.Parent = frame
                    
                    local function updateDisplay()
                        colorPicker.Value = Color3.new(r, g, b)
                        display.BackgroundColor3 = colorPicker.Value
                        if callback then callback(colorPicker.Value) end
                        if UI.SaveManager then UI.SaveManager:AutoSave() end
                    end
                    
                    display.MouseButton1Click:Connect(function()
                        if colorPicker.Open then
                            if colorPicker.Popup then colorPicker.Popup:Destroy() end
                            colorPicker.Open = false
                            return
                        end
                        
                        colorPicker.Open = true
                        local popup = Instance.new("Frame")
                        popup.BackgroundColor3 = self.Theme.Surface
                        popup.BorderColor3 = self.Theme.Border
                        popup.BorderSizePixel = 1
                        popup.Position = UDim2.fromOffset(Mouse.X + 10, Mouse.Y + 10)
                        popup.Size = UDim2.fromOffset(200, 130)
                        popup.ZIndex = 100
                        popup.Parent = ScreenGui
                        
                        local title = Instance.new("Frame")
                        title.BackgroundColor3 = self.Theme.Background
                        title.Size = UDim2.new(1, 0, 0, 30)
                        title.Parent = popup
                        
                        local titleText = Instance.new("TextLabel")
                        titleText.BackgroundTransparency = 1
                        titleText.Size = UDim2.new(1, -30, 1, 0)
                        titleText.Font = Enum.Font.Gotham
                        titleText.Text = "Color Picker"
                        titleText.TextColor3 = self.Theme.Text
                        titleText.TextSize = 12
                        titleText.TextXAlignment = Enum.TextXAlignment.Left
                        titleText.Parent = title
                        
                        local closeBtn = Instance.new("TextButton")
                        closeBtn.BackgroundTransparency = 1
                        closeBtn.Position = UDim2.new(1, -30, 0, 0)
                        closeBtn.Size = UDim2.new(0, 30, 0, 30)
                        closeBtn.Font = Enum.Font.Gotham
                        closeBtn.Text = "✕"
                        closeBtn.TextColor3 = self.Theme.TextSecondary
                        closeBtn.TextSize = 12
                        closeBtn.Parent = title
                        
                        local content = Instance.new("Frame")
                        content.BackgroundTransparency = 1
                        content.Position = UDim2.new(0, 10, 0, 40)
                        content.Size = UDim2.new(1, -20, 1, -50)
                        content.Parent = popup
                        
                        local rSlider, gSlider, bSlider
                        
                        rSlider = groupboxAPI.AddSlider(nil, "Red", 0, 1, r, 2, "", function(val)
                            r = val
                            updateDisplay()
                            if rSlider then rSlider:SetValue(r) end
                        end)
                        
                        gSlider = groupboxAPI.AddSlider(nil, "Green", 0, 1, g, 2, "", function(val)
                            g = val
                            updateDisplay()
                            if gSlider then gSlider:SetValue(g) end
                        end)
                        
                        bSlider = groupboxAPI.AddSlider(nil, "Blue", 0, 1, b, 2, "", function(val)
                            b = val
                            updateDisplay()
                            if bSlider then bSlider:SetValue(b) end
                        end)
                        
                        if rSlider and rSlider.Frame then rSlider.Frame.Parent = content end
                        if gSlider and gSlider.Frame then gSlider.Frame.Parent = content end
                        if bSlider and bSlider.Frame then bSlider.Frame.Parent = content end
                        
                        local contentLayout = Instance.new("UIListLayout")
                        contentLayout.Padding = UDim.new(0, 5)
                        contentLayout.FillDirection = Enum.FillDirection.Vertical
                        contentLayout.Parent = content
                        
                        closeBtn.MouseButton1Click:Connect(function()
                            popup:Destroy()
                            colorPicker.Open = false
                        end)
                        
                        colorPicker.Popup = popup
                    end)
                    
                    function colorPicker:SetValueRGB(color)
                        r, g, b = color.R, color.G, color.B
                        updateDisplay()
                    end
                    
                    UI.Options[id] = colorPicker
                    return colorPicker
                end,
                
                AddKeybind = function(id, text, default, callback)
                    local keybind = {
                        Value = default or "None",
                        Id = id,
                        Callback = callback or function() end,
                        Listening = false,
                    }
                    
                    local frame = Instance.new("Frame")
                    frame.BackgroundTransparency = 1
                    frame.Size = UDim2.new(1, 0, 0, 32)
                    frame.Parent = container
                    
                    local label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.Position = UDim2.new(0, 0, 0, 0)
                    label.Size = UDim2.new(0.6, -5, 1, 0)
                    label.Font = Enum.Font.Gotham
                    label.Text = text
                    label.TextColor3 = self.Theme.Text
                    label.TextSize = 13
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.Parent = frame
                    
                    local button = Instance.new("TextButton")
                    button.BackgroundColor3 = self.Theme.Background
                    button.BorderColor3 = self.Theme.Border
                    button.BorderSizePixel = 1
                    button.Position = UDim2.new(0.6, 0, 0, 0)
                    button.Size = UDim2.new(0.4, -5, 1, 0)
                    button.Font = Enum.Font.Gotham
                    button.Text = keybind.Value
                    button.TextColor3 = self.Theme.Text
                    button.TextSize = 12
                    button.Parent = frame
                    
                    local connection
                    
                    button.MouseButton1Click:Connect(function()
                        if keybind.Listening then return end
                        keybind.Listening = true
                        button.Text = "..."
                        button.BackgroundColor3 = self.Theme.Primary
                        
                        connection = UserInputService.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                local key = input.KeyCode.Name
                                keybind.Value = key
                                button.Text = key
                                button.BackgroundColor3 = self.Theme.Background
                                keybind.Listening = false
                                if callback then callback(key) end
                                if UI.SaveManager then UI.SaveManager:AutoSave() end
                                connection:Disconnect()
                            end
                        end)
                        
                        task.delay(5, function()
                            if keybind.Listening then
                                button.Text = keybind.Value
                                button.BackgroundColor3 = self.Theme.Background
                                keybind.Listening = false
                                if connection then connection:Disconnect() end
                            end
                        end)
                    end)
                    
                    function keybind:GetState()
                        return UserInputService:IsKeyDown(Enum.KeyCode[keybind.Value])
                    end
                    
                    function keybind:SetValue(key)
                        keybind.Value = key
                        button.Text = key
                        if callback then callback(key) end
                        if UI.SaveManager then UI.SaveManager:AutoSave() end
                    end
                    
                    UI.Options[id] = keybind
                    return keybind
                end,
                
                AddDivider = function()
                    local divider = Instance.new("Frame")
                    divider.BackgroundColor3 = self.Theme.Border
                    divider.BorderSizePixel = 0
                    divider.Size = UDim2.new(1, 0, 0, 1)
                    divider.Parent = container
                    return divider
                end,
                
                AddLabel = function(text, centered)
                    local label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.Size = UDim2.new(1, 0, 0, 20)
                    label.Font = Enum.Font.Gotham
                    label.Text = text
                    label.TextColor3 = self.Theme.TextSecondary
                    label.TextSize = 12
                    label.TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
                    label.Parent = container
                    return label
                end,
            }
            
            return groupboxAPI
        end,
        
        Show = function()
            frame.Visible = true
            UI.ActiveWindow = windowAPI
        end,
        
        Hide = function()
            frame.Visible = false
            UI.ActiveWindow = nil
        end,
        
        Destroy = function()
            frame:Destroy()
        end,
        
        SetTitle = function(newTitle)
            titleLabel.Text = newTitle
        end,
    }
    
    table.insert(UI.Windows, windowAPI)
    return windowAPI
end

-- Notification system
function UI:Notify(message, type, duration)
    type = type or "info"
    duration = duration or 3
    
    local notifyArea = self.NotifyArea
    if not notifyArea then
        notifyArea = Instance.new("Frame")
        notifyArea.Name = "NotificationArea"
        notifyArea.BackgroundTransparency = 1
        notifyArea.Position = UDim2.new(1, -320, 0, 50)
        notifyArea.Size = UDim2.new(0, 300, 0, 0)
        notifyArea.AutomaticSize = Enum.AutomaticSize.Y
        notifyArea.Parent = ScreenGui
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = notifyArea
        
        self.NotifyArea = notifyArea
    end
    
    local notification = Instance.new("Frame")
    notification.BackgroundColor3 = self.Theme.Surface
    notification.BorderColor3 = self.Theme.Border
    notification.BorderSizePixel = 1
    notification.Size = UDim2.new(0, 300, 0, 0)
    notification.AutomaticSize = Enum.AutomaticSize.Y
    notification.ClipsDescendants = true
    notification.Parent = notifyArea
    
    local accentColor = self.Theme.Primary
    if type == "error" then
        accentColor = self.Theme.Danger
    elseif type == "success" then
        accentColor = self.Theme.Success
    end
    
    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = accentColor
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.Parent = notification
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 16, 0, 8)
    label.Size = UDim2.new(1, -40, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Font = Enum.Font.Gotham
    label.Text = message
    label.TextColor3 = self.Theme.Text
    label.TextSize = 13
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notification
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundTransparency = 1
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = self.Theme.TextSecondary
    closeBtn.TextSize = 12
    closeBtn.Parent = notification
    
    closeBtn.MouseButton1Click:Connect(function()
        notification:Destroy()
    end)
    
    notification.Position = UDim2.new(1, 0, 0, 0)
    local tween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, -310, 0, 0)
    })
    tween:Play()
    
    task.delay(duration, function()
        if notification and notification.Parent then
            local outTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Position = UDim2.new(1, 0, 0, 0)
            })
            outTween:Play()
            outTween.Completed:Connect(function()
                notification:Destroy()
            end)
        end
    end)
end

-- Set menu toggle key
function UI:SetToggleKey(key)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode[key] then
            if self.ActiveWindow and self.ActiveWindow.Frame.Visible then
                self.ActiveWindow:Hide()
            elseif self.Windows[1] then
                self.Windows[1]:Show()
            end
        end
    end)
end

-- Apply theme
function UI:ApplyTheme(theme)
    for key, value in pairs(theme) do
        if self.Theme[key] then
            self.Theme[key] = value
        end
    end
    
    -- Update colors on all UI elements
    for _, window in ipairs(self.Windows) do
        -- Update window colors
        if window.Frame then
            window.Frame.BackgroundColor3 = self.Theme.Background
            window.Frame.BorderColor3 = self.Theme.Border
        end
    end
end

-- Unload UI
function UI:Unload()
    ScreenGui:Destroy()
end

return UI
