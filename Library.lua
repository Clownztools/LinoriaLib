--[[
    Modern UI Library v2.0 - LinoriaLib Compatible
    A clean, modern UI framework for Roblox exploits
]]

-- Services
local InputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Protect GUI
local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ProtectGui(ScreenGui)
ScreenGui.Name = "ModernUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

-- Global stores
local Toggles = {}
local Options = {}

getgenv().Toggles = Toggles
getgenv().Options = Options

-- Helper function for rounded corners
local function AddRoundedCorners(frame, radius)
    radius = radius or 8
    local corners = Instance.new("UICorner")
    corners.CornerRadius = UDim.new(0, radius)
    corners.Parent = frame
end

-- Library table
local Library = {
    Version = "2.0.0",
    ScreenGui = ScreenGui,
    Toggles = Toggles,
    Options = Options,
    
    -- Default theme (enhanced colors)
    BackgroundColor = Color3.fromRGB(18, 18, 22),
    MainColor = Color3.fromRGB(28, 28, 35),
    AccentColor = Color3.fromRGB(98, 114, 255),
    OutlineColor = Color3.fromRGB(45, 45, 55),
    FontColor = Color3.fromRGB(255, 255, 255),
    
    -- Fonts
    Fonts = {
        UI = Enum.Font.Gotham,
        Monospace = Enum.Font.Code,
    },
    
    -- Settings
    Settings = {
        NotificationDuration = 3,
        AnimationSpeed = 0.2,
    },
    
    -- Internal
    Windows = {},
    ActiveWindow = nil,
    OpenedFrames = {},
    Signals = {},
    NotifyArea = nil,
    KeybindFrame = nil,
    KeybindContainer = nil,
}

-- Utility functions
local function GetTextBounds(Text, Font, Size)
    return TextService:GetTextSize(Text, Size, Font, Vector2.new(1920, 1080))
end

function Library:Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        instance[prop] = value
    end
    return instance
end

function Library:GetDarkerColor(color, factor)
    factor = factor or 0.7
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s, v * factor)
end

function Library:GetLighterColor(color, factor)
    factor = factor or 1.3
    local h, s, v = Color3.toHSV(color)
    return Color3.fromHSV(h, s, math.min(1, v * factor))
end

function Library:AddToRegistry(instance, properties)
    if not self.Registry then
        self.Registry = {}
        self.RegistryMap = {}
    end
    
    local data = {
        Instance = instance,
        Properties = properties,
    }
    
    table.insert(self.Registry, data)
    self.RegistryMap[instance] = data
end

function Library:UpdateColors()
    if not self.Registry then return end
    
    for _, item in ipairs(self.Registry) do
        for prop, colorKey in pairs(item.Properties) do
            if self[colorKey] then
                item.Instance[prop] = self[colorKey]
            end
        end
    end
end

function Library:UpdateColorsUsingRegistry()
    self:UpdateColors()
end

function Library:MakeDraggable(frame, dragHandle, offset)
    dragHandle = dragHandle or frame
    offset = offset or 40
    
    local dragging = false
    local dragStart = Vector2.new()
    local frameStart = frame.Position
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local framePos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
            
            if mousePos.Y - framePos.Y <= offset then
                dragging = true
                dragStart = mousePos
                frameStart = frame.Position
            end
        end
    end)
    
    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    InputService.InputChanged:Connect(function(input)
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
end

function Library:Notify(message, type, duration)
    type = type or "info"
    duration = duration or self.Settings.NotificationDuration
    
    if not self.NotifyArea then
        self.NotifyArea = self:Create("Frame", {
            Name = "NotificationArea",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -320, 0, 50),
            Size = UDim2.new(0, 300, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = ScreenGui,
        })
        
        self:Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = self.NotifyArea,
        })
    end
    
    -- Get color based on type
    local accentColor = self.AccentColor
    if type == "error" then
        accentColor = Color3.fromRGB(255, 85, 85)
    elseif type == "success" then
        accentColor = Color3.fromRGB(80, 220, 120)
    elseif type == "warning" then
        accentColor = Color3.fromRGB(255, 180, 70)
    end
    
    -- Create notification
    local notification = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BorderColor3 = self.OutlineColor,
        BorderSizePixel = 1,
        Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = self.NotifyArea,
    })
    AddRoundedCorners(notification, 8)
    
    -- Accent bar
    self:Create("Frame", {
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0),
        Parent = notification,
    })
    
    -- Message text
    local textLabel = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 10),
        Size = UDim2.new(1, -40, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = self.Fonts.UI,
        Text = message,
        TextColor3 = self.FontColor,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification,
    })
    
    -- Close button
    local closeButton = self:Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 5),
        Size = UDim2.new(0, 24, 0, 24),
        Font = self.Fonts.UI,
        Text = "✕",
        TextColor3 = self.FontColor,
        TextSize = 14,
        Parent = notification,
    })
    
    closeButton.MouseButton1Click:Connect(function()
        notification:Destroy()
    end)
    
    -- Animate in
    notification.Position = UDim2.new(1, 0, 0, 0)
    local tween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, -310, 0, 0)
    })
    tween:Play()
    
    -- Auto remove
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
    
    return notification
end

function Library:AddTooltip(text, instance)
    local tooltip = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BorderColor3 = self.OutlineColor,
        BorderSizePixel = 1,
        Size = UDim2.new(0, 0, 0, 0),
        Visible = false,
        ZIndex = 1000,
        Parent = ScreenGui,
    })
    AddRoundedCorners(tooltip, 6)
    
    local label = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 4),
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = self.Fonts.UI,
        Text = text,
        TextColor3 = self.FontColor,
        TextSize = 12,
        TextWrapped = true,
        Parent = tooltip,
    })
    
    local active = false
    
    instance.MouseEnter:Connect(function()
        local textSize = GetTextBounds(text, self.Fonts.UI, 12)
        tooltip.Size = UDim2.new(0, textSize.X + 16, 0, textSize.Y + 8)
        active = true
        tooltip.Visible = true
        
        while active and tooltip.Visible do
            tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 15)
            RunService.Heartbeat:Wait()
        end
    end)
    
    instance.MouseLeave:Connect(function()
        active = false
        tooltip.Visible = false
    end)
    
    return tooltip
end

function Library:CreateWindow(title, options)
    options = options or {}
    
    -- Main window frame
    local window = self:Create("Frame", {
        BackgroundColor3 = self.BackgroundColor,
        BorderColor3 = self.OutlineColor,
        BorderSizePixel = 1,
        Position = options.Position or UDim2.fromOffset(100, 100),
        Size = options.Size or UDim2.fromOffset(600, 500),
        Visible = false,
        ClipsDescendants = true,
        Parent = ScreenGui,
    })
    AddRoundedCorners(window, 10)
    
    -- Shadow effect
    local shadow = self:Create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 6, 0, 6),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = -1,
        Parent = window,
    })
    AddRoundedCorners(shadow, 10)
    
    -- Title bar
    local titleBar = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 45),
        Parent = window,
    })
    
    -- Accent line
    self:Create("Frame", {
        BackgroundColor3 = self.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Parent = titleBar,
    })
    
    -- Title text
    local titleLabel = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        Font = self.Fonts.UI,
        Text = title,
        TextColor3 = self.FontColor,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })
    
    -- Close button
    if options.Closable ~= false then
        local closeButton = self:Create("TextButton", {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -45, 0, 0),
            Size = UDim2.new(0, 45, 0, 45),
            Font = self.Fonts.UI,
            Text = "✕",
            TextColor3 = self.FontColor,
            TextSize = 16,
            Parent = titleBar,
        })
        
        closeButton.MouseEnter:Connect(function()
            closeButton.TextColor3 = Color3.fromRGB(255, 85, 85)
        end)
        
        closeButton.MouseLeave:Connect(function()
            closeButton.TextColor3 = self.FontColor
        end)
        
        closeButton.MouseButton1Click:Connect(function()
            window.Visible = false
        end)
    end
    
    -- Tab bar
    local tabBar = self:Create("Frame", {
        BackgroundColor3 = self.MainColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 45),
        Size = UDim2.new(1, 0, 0, 40),
        Parent = window,
    })
    
    -- Tab container (scrolling)
    local tabContainer = self:Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        ScrollDirection = Enum.ScrollDirection.X,
        Parent = tabBar,
    })
    
    -- Tab layout
    local tabLayout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabContainer,
    })
    
    -- Content area
    local contentArea = self:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 97),
        Size = UDim2.new(1, -24, 1, -109),
        Parent = window,
    })
    
    -- Make draggable
    self:MakeDraggable(window, titleBar, 45)
    
    -- Tab management
    local tabs = {}
    local activeTab = nil
    
    local function updateTabScroll()
        task.wait()
        local totalWidth = 0
        for _, child in ipairs(tabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                totalWidth = totalWidth + child.Size.X.Offset
            end
        end
        tabContainer.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
    end
    
    -- Window API
    local windowAPI = {
        Frame = window,
        Tabs = tabs,
        
        AddTab = function(name)
            -- Create tab button
            local button = self:Create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 120, 1, 0),
                Font = self.Fonts.UI,
                Text = name,
                TextColor3 = self.FontColor,
                TextSize = 14,
                Parent = tabContainer,
            })
            
            -- Tab content frame
            local tabFrame = self:Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Visible = false,
                Parent = contentArea,
            })
            
            -- Left and right content for this tab
            local tabLeftColumn = self:Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0.5, -8, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = self.AccentColor,
                Parent = tabFrame,
            })
            
            local tabRightColumn = self:Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 8, 0, 0),
                Size = UDim2.new(0.5, -8, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = self.AccentColor,
                Parent = tabFrame,
            })
            
            local tabLeftLayout = self:Create("UIListLayout", {
                Padding = UDim.new(0, 12),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = tabLeftColumn,
            })
            
            local tabRightLayout = self:Create("UIListLayout", {
                Padding = UDim.new(0, 12),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = tabRightColumn,
            })
            
            tabLeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                tabLeftColumn.CanvasSize = UDim2.new(0, 0, 0, tabLeftLayout.AbsoluteContentSize.Y)
            end)
            
            tabRightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                tabRightColumn.CanvasSize = UDim2.new(0, 0, 0, tabRightLayout.AbsoluteContentSize.Y)
            end)
            
            local tabAPI = {
                Name = name,
                Frame = tabFrame,
                Button = button,
                LeftColumn = tabLeftColumn,
                RightColumn = tabRightColumn,
                LeftLayout = tabLeftLayout,
                RightLayout = tabRightLayout,
                
                AddLeftGroupbox = function(title)
                    return windowAPI.AddGroupbox(tabAPI, "left", title)
                end,
                
                AddRightGroupbox = function(title)
                    return windowAPI.AddGroupbox(tabAPI, "right", title)
                end,
            }
            
            button.MouseButton1Click:Connect(function()
                if activeTab then
                    activeTab.Button.TextColor3 = Library.FontColor
                    activeTab.Frame.Visible = false
                end
                activeTab = tabAPI
                button.TextColor3 = Library.AccentColor
                tabFrame.Visible = true
                updateTabScroll()
            end)
            
            table.insert(tabs, tabAPI)
            updateTabScroll()
            
            -- Activate first tab
            if #tabs == 1 then
                button.TextColor3 = Library.AccentColor
                tabFrame.Visible = true
                activeTab = tabAPI
            end
            
            return tabAPI
        end,
        
        AddGroupbox = function(tab, side, title)
            -- Create groupbox frame
            local groupbox = self:Create("Frame", {
                BackgroundColor3 = self.MainColor,
                BorderColor3 = self.OutlineColor,
                BorderSizePixel = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = side == "left" and tab.LeftColumn or tab.RightColumn,
            })
            AddRoundedCorners(groupbox, 8)
            
            -- Header
            local header = self:Create("Frame", {
                BackgroundColor3 = self.BackgroundColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 35),
                Parent = groupbox,
            })
            
            -- Header accent
            self:Create("Frame", {
                BackgroundColor3 = self.AccentColor,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 3, 1, 0),
                Parent = header,
            })
            
            -- Title
            local titleLabel = self:Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 16, 0, 0),
                Size = UDim2.new(1, -32, 1, 0),
                Font = self.Fonts.UI,
                Text = title,
                TextColor3 = self.FontColor,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = header,
            })
            
            -- Content container
            local container = self:Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 35),
                Size = UDim2.new(1, -24, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = groupbox,
            })
            
            local contentLayout = self:Create("UIListLayout", {
                Padding = UDim.new(0, 8),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = container,
            })
            
            -- Groupbox API
            local groupboxAPI = {
                Frame = groupbox,
                Container = container,
                Layout = contentLayout,
                
                AddButton = function(text, callback, doubleClick)
                    local button = self:Create("TextButton", {
                        BackgroundColor3 = self.BackgroundColor,
                        BorderColor3 = self.OutlineColor,
                        BorderSizePixel = 1,
                        Size = UDim2.new(1, 0, 0, 32),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.FontColor,
                        TextSize = 14,
                        Parent = container,
                    })
                    AddRoundedCorners(button, 6)
                    
                    button.Callback = callback
                    
                    button.MouseEnter:Connect(function()
                        TweenService:Create(button, TweenInfo.new(0.2), {
                            BackgroundColor3 = self.AccentColor
                        }):Play()
                    end)
                    
                    button.MouseLeave:Connect(function()
                        TweenService:Create(button, TweenInfo.new(0.2), {
                            BackgroundColor3 = self.BackgroundColor
                        }):Play()
                    end)
                    
                    if doubleClick then
                        button.MouseButton1Click:Connect(function()
                            if not button.DoubleClickReady then
                                button.DoubleClickReady = true
                                local originalText = button.Text
                                button.Text = "Are you sure?"
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
                        end)
                    else
                        button.MouseButton1Click:Connect(function()
                            if callback then callback() end
                        end)
                    end
                    
                    return button
                end,
                
                AddToggle = function(id, text, default, callback)
                    local toggle = {
                        Value = default or false,
                        Type = "Toggle",
                        Callback = callback or function() end,
                    }
                    
                    local toggleFrame = self:Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 32),
                        Parent = container,
                    })
                    
                    local toggleButton = self:Create("TextButton", {
                        BackgroundColor3 = toggle.Value and self.AccentColor or self.BackgroundColor,
                        BorderColor3 = self.OutlineColor,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 0, 4),
                        Size = UDim2.new(0, 24, 0, 24),
                        Font = self.Fonts.UI,
                        Text = toggle.Value and "✓" or "",
                        TextColor3 = self.FontColor,
                        TextSize = 14,
                        Parent = toggleFrame,
                    })
                    AddRoundedCorners(toggleButton, 12)
                    
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 32, 0, 0),
                        Size = UDim2.new(1, -32, 1, 0),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.FontColor,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = toggleFrame,
                    })
                    
                    function toggle:SetValue(value)
                        toggle.Value = value
                        toggleButton.Text = value and "✓" or ""
                        TweenService:Create(toggleButton, TweenInfo.new(0.2), {
                            BackgroundColor3 = value and Library.AccentColor or Library.BackgroundColor
                        }):Play()
                        if callback then callback(value) end
                    end
                    
                    toggleButton.MouseButton1Click:Connect(function()
                        toggle:SetValue(not toggle.Value)
                    end)
                    
                    Toggles[id] = toggle
                    return toggle
                end,
                
                AddSlider = function(id, text, min, max, default, rounding, suffix, callback)
                    local slider = {
                        Value = default or min,
                        Min = min or 0,
                        Max = max or 100,
                        Rounding = rounding or 0,
                        Type = "Slider",
                        Callback = callback or function() end,
                    }
                    
                    local sliderFrame = self:Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 50),
                        Parent = container,
                    })
                    
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.FontColor,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = sliderFrame,
                    })
                    
                    local valueLabel = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -16, 0, 20),
                        Font = self.Fonts.Monospace,
                        Text = tostring(slider.Value) .. (suffix or ""),
                        TextColor3 = self.AccentColor,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Parent = sliderFrame,
                    })
                    
                    local sliderBg = self:Create("Frame", {
                        BackgroundColor3 = self.BackgroundColor,
                        BorderColor3 = self.OutlineColor,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 0, 25),
                        Size = UDim2.new(1, 0, 0, 4),
                        Parent = sliderFrame,
                    })
                    AddRoundedCorners(sliderBg, 2)
                    
                    local sliderFill = self:Create("Frame", {
                        BackgroundColor3 = self.AccentColor,
                        BorderSizePixel = 0,
                        Size = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), 0, 1, 0),
                        Parent = sliderBg,
                    })
                    AddRoundedCorners(sliderFill, 2)
                    
                    local sliderHandle = self:Create("TextButton", {
                        BackgroundColor3 = self.AccentColor,
                        BorderColor3 = self.OutlineColor,
                        BorderSizePixel = 1,
                        Position = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), -6, 0, -4),
                        Size = UDim2.new(0, 12, 0, 12),
                        Text = "",
                        Parent = sliderBg,
                    })
                    AddRoundedCorners(sliderHandle, 6)
                    
                    local function updateSlider(value)
                        value = math.clamp(value, slider.Min, slider.Max)
                        if slider.Rounding > 0 then
                            value = tonumber(string.format("%." .. slider.Rounding .. "f", value))
                        else
                            value = math.floor(value)
                        end
                        slider.Value = value
                        local percent = (value - slider.Min) / (slider.Max - slider.Min)
                        sliderFill:TweenSize(UDim2.new(percent, 0, 1, 0), "Out", "Quad", 0.1, true)
                        sliderHandle:TweenPosition(UDim2.new(percent, -6, 0, -4), "Out", "Quad", 0.1, true)
                        valueLabel.Text = tostring(value) .. (suffix or "")
                        if callback then callback(value) end
                    end
                    
                    local dragging = false
                    sliderHandle.MouseButton1Down:Connect(function()
                        dragging = true
                        while dragging and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            local percent = math.clamp((Mouse.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                            local value = slider.Min + (slider.Max - slider.Min) * percent
                            updateSlider(value)
                            RunService.RenderStepped:Wait()
                        end
                        dragging = false
                    end)
                    
                    sliderHandle.MouseButton1Up:Connect(function()
                        dragging = false
                    end)
                    
                    function slider:SetValue(value)
                        updateSlider(value)
                    end
                    
                    Options[id] = slider
                    return slider
                end,
                
                AddDropdown = function(id, text, values, default, callback, multi)
                    local dropdown = {
                        Values = values,
                        Multi = multi or false,
                        Value = nil,
                        Type = "Dropdown",
                        Callback = callback or function() end,
                        Open = false,
                    }
                    
                    if multi then
                        dropdown.Value = {}
                        if default then
                            for _, v in ipairs(default) do
                                dropdown.Value[v] = true
                            end
                        end
                    else
                        dropdown.Value = default or values[1]
                    end
                    
                    local dropdownFrame = self:Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Parent = container,
                    })
                    
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.FontColor,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = dropdownFrame,
                    })
                    
                    local displayText = ""
                    if not multi and dropdown.Value then
                        displayText = dropdown.Value
                    elseif multi then
                        local selected = {}
                        for k, v in pairs(dropdown.Value) do
                            if v then table.insert(selected, k) end
                        end
                        displayText = #selected > 0 and table.concat(selected, ", ") or "Select..."
                    end
                    
                    local selectButton = self:Create("TextButton", {
                        BackgroundColor3 = self.BackgroundColor,
                        BorderColor3 = self.OutlineColor,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 0, 22),
                        Size = UDim2.new(1, 0, 0, 30),
                        Font = self.Fonts.UI,
                        Text = displayText,
                        TextColor3 = self.FontColor,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = dropdownFrame,
                    })
                    AddRoundedCorners(selectButton, 6)
                    
                    local arrow = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -25, 0, 0),
                        Size = UDim2.new(0, 20, 1, 0),
                        Font = self.Fonts.UI,
                        Text = "▼",
                        TextColor3 = self.FontColor,
                        TextSize = 12,
                        Parent = selectButton,
                    })
                    
                    local dropdownList = self:Create("Frame", {
                        BackgroundColor3 = self.MainColor,
                        BorderColor3 = self.OutlineColor,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 1, 2),
                        Size = UDim2.new(1, 0, 0, 0),
                        Visible = false,
                        ClipsDescendants = true,
                        ZIndex = 10,
                        Parent = selectButton,
                    })
                    AddRoundedCorners(dropdownList, 6)
                    
                    local listLayout = self:Create("UIListLayout", {
                        Padding = UDim.new(0, 0),
                        FillDirection = Enum.FillDirection.Vertical,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = dropdownList,
                    })
                    
                    local function updateDropdownList()
                        for _, child in ipairs(dropdownList:GetChildren()) do
                            if child:IsA("TextButton") then
                                child:Destroy()
                            end
                        end
                        
                        for _, value in ipairs(values) do
                            local isSelected = multi and dropdown.Value[value] or dropdown.Value == value
                            
                            local item = self:Create("TextButton", {
                                BackgroundColor3 = isSelected and self.AccentColor or self.MainColor,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, 0, 0, 30),
                                Font = self.Fonts.UI,
                                Text = value,
                                TextColor3 = self.FontColor,
                                TextSize = 13,
                                Parent = dropdownList,
                            })
                            
                            item.MouseEnter:Connect(function()
                                if not (multi and dropdown.Value[value]) and dropdown.Value ~= value then
                                    item.BackgroundColor3 = self.AccentColor
                                end
                            end)
                            
                            item.MouseLeave:Connect(function()
                                local stillSelected = multi and dropdown.Value[value] or dropdown.Value == value
                                item.BackgroundColor3 = stillSelected and self.AccentColor or self.MainColor
                            end)
                            
                            item.MouseButton1Click:Connect(function()
                                if multi then
                                    dropdown.Value[value] = not dropdown.Value[value]
                                    local selectedText = {}
                                    for k, v in pairs(dropdown.Value) do
                                        if v then table.insert(selectedText, k) end
                                    end
                                    selectButton.Text = #selectedText > 0 and table.concat(selectedText, ", ") or "Select..."
                                else
                                    dropdown.Value = value
                                    selectButton.Text = value
                                    dropdown.Open = false
                                    dropdownList.Visible = false
                                    arrow.Text = "▼"
                                end
                                
                                updateDropdownList()
                                if callback then callback(dropdown.Value) end
                            end)
                        end
                        
                        local count = #values
                        local height = math.min(count * 30, 200)
                        dropdownList.Size = UDim2.new(1, 0, 0, height)
                    end
                    
                    selectButton.MouseButton1Click:Connect(function()
                        dropdown.Open = not dropdown.Open
                        dropdownList.Visible = dropdown.Open
                        arrow.Text = dropdown.Open and "▲" or "▼"
                        if dropdown.Open then
                            updateDropdownList()
                        end
                    end)
                    
                    function dropdown:SetValue(value)
                        if multi then
                            dropdown.Value = value or {}
                            local selectedText = {}
                            for k, v in pairs(dropdown.Value) do
                                if v then table.insert(selectedText, k) end
                            end
                            selectButton.Text = #selectedText > 0 and table.concat(selectedText, ", ") or "Select..."
                        else
                            dropdown.Value = value
                            selectButton.Text = value or "Select..."
                        end
                        updateDropdownList()
                        if callback then callback(dropdown.Value) end
                    end
                    
                    Options[id] = dropdown
                    return dropdown
                end,
                
                AddInput = function(id, text, placeholder, numeric, callback)
                    local input = {
                        Value = "",
                        Type = "Input",
                        Callback = callback or function() end,
                    }
                    
                    local inputFrame = self:Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 50),
                        Parent = container,
                    })
                    
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.FontColor,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = inputFrame,
                    })
                    
                    local textBox = self:Create("TextBox", {
                        BackgroundColor3 = self.BackgroundColor,
                        BorderColor3 = self.OutlineColor,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 0, 22),
                        Size = UDim2.new(1, 0, 0, 28),
                        Font = self.Fonts.UI,
                        PlaceholderColor3 = self.FontColor,
                        PlaceholderText = placeholder or "",
                        Text = "",
                        TextColor3 = self.FontColor,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = inputFrame,
                    })
                    AddRoundedCorners(textBox, 6)
                    
                    local function updateValue()
                        local newValue = textBox.Text
                        if numeric then
                            local num = tonumber(newValue)
                            if num then
                                input.Value = num
                                if callback then callback(num) end
                            end
                        else
                            input.Value = newValue
                            if callback then callback(newValue) end
                        end
                    end
                    
                    textBox:GetPropertyChangedSignal("Text"):Connect(updateValue)
                    
                    function input:SetValue(value)
                        input.Value = value
                        textBox.Text = tostring(value)
                        if callback then callback(value) end
                    end
                    
                    Options[id] = input
                    return input
                end,
                
                AddColorPicker = function(id, text, default, callback)
                    local colorPicker = {
                        Value = default or Color3.new(1, 1, 1),
                        Type = "ColorPicker",
                        Callback = callback or function() end,
                        Open = false,
                    }
                    
                    local pickerFrame = self:Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 50),
                        Parent = container,
                    })
                    
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.FontColor,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = pickerFrame,
                    })
                    
                    local colorDisplay = self:Create("TextButton", {
                        BackgroundColor3 = colorPicker.Value,
                        BorderColor3 = self.OutlineColor,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 0, 22),
                        Size = UDim2.new(1, 0, 0, 28),
                        Text = "",
                        Parent = pickerFrame,
                    })
                    AddRoundedCorners(colorDisplay, 6)
                    
                    local function updateDisplay()
                        if callback then callback(colorPicker.Value) end
                    end
                    
                    colorDisplay.MouseButton1Click:Connect(function()
                        colorPicker.Open = not colorPicker.Open
                        if colorPicker.Open then
                            -- Simple color picker popup
                            local popup = self:Create("Frame", {
                                BackgroundColor3 = self.MainColor,
                                BorderColor3 = self.OutlineColor,
                                BorderSizePixel = 1,
                                Position = UDim2.fromOffset(Mouse.X + 10, Mouse.Y + 10),
                                Size = UDim2.fromOffset(180, 100),
                                ZIndex = 100,
                                Parent = ScreenGui,
                            })
                            AddRoundedCorners(popup, 8)
                            
                            local hueSlider = groupboxAPI.AddSlider(nil, "Hue", 0, 1, 1, 2, "", function(val)
                                colorPicker.Value = Color3.fromHSV(val, 1, 1)
                                colorDisplay.BackgroundColor3 = colorPicker.Value
                                updateDisplay()
                            end)
                            
                            if hueSlider and hueSlider.Frame then
                                hueSlider.Frame.Parent = popup
                                hueSlider.Frame.Size = UDim2.new(1, -16, 0, 40)
                                hueSlider.Frame.Position = UDim2.new(0, 8, 0, 8)
                            end
                            
                            local closeBtn = self:Create("TextButton", {
                                BackgroundTransparency = 1,
                                Position = UDim2.new(1, -25, 0, 0),
                                Size = UDim2.new(0, 25, 0, 25),
                                Font = self.Fonts.UI,
                                Text = "✕",
                                TextColor3 = self.FontColor,
                                TextSize = 12,
                                Parent = popup,
                            })
                            
                            closeBtn.MouseButton1Click:Connect(function()
                                popup:Destroy()
                                colorPicker.Open = false
                            end)
                        end
                    end)
                    
                    function colorPicker:SetValueRGB(color)
                        colorPicker.Value = color
                        colorDisplay.BackgroundColor3 = color
                        updateDisplay()
                    end
                    
                    Options[id] = colorPicker
                    return colorPicker
                end,
                
                AddDivider = function()
                    self:Create("Frame", {
                        BackgroundColor3 = self.OutlineColor,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 1),
                        Parent = container,
                    })
                end,
                
                AddLabel = function(text, centered)
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.FontColor,
                        TextSize = 12,
                        TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
                        Parent = container,
                    })
                    
                    function label:SetText(newText)
                        label.Text = newText
                    end
                    
                    return label
                end,
                
                AddKeyPicker = function(id, text, default, callback)
                    -- KeyPicker acts like a toggle for now
                    return groupboxAPI.AddToggle(id, text, default, callback)
                end,
            }
            
            return groupboxAPI
        end,
        
        Show = function()
            window.Visible = true
            TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 0
            }):Play()
        end,
        
        Hide = function()
            TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 1
            }):Play()
            task.wait(0.2)
            window.Visible = false
        end,
        
        Destroy = function()
            window:Destroy()
        end,
        
        SetTitle = function(newTitle)
            titleLabel.Text = newTitle
        end,
    }
    
    table.insert(self.Windows, windowAPI)
    return windowAPI
end

function Library:Unload()
    ScreenGui:Destroy()
    if self.OnUnload then
        self.OnUnload()
    end
end

function Library:OnUnload(callback)
    self.OnUnload = callback
end

return Library
