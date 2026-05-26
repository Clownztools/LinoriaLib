--[[
    Modern UI Library v2.0
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

-- Library table
local Library = {
    Version = "2.0.0",
    ScreenGui = ScreenGui,
    Toggles = Toggles,
    Options = Options,
    
    -- Default theme (enhanced)
    Theme = {
        Background = Color3.fromRGB(15, 15, 20),
        Surface = Color3.fromRGB(25, 25, 32),
        Primary = Color3.fromRGB(98, 114, 255),
        PrimaryDark = Color3.fromRGB(78, 94, 235),
        PrimaryLight = Color3.fromRGB(138, 154, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(160, 160, 175),
        TextMuted = Color3.fromRGB(120, 120, 135),
        Border = Color3.fromRGB(40, 40, 48),
        BorderLight = Color3.fromRGB(55, 55, 65),
        Danger = Color3.fromRGB(255, 85, 85),
        DangerDark = Color3.fromRGB(220, 60, 60),
        Success = Color3.fromRGB(80, 220, 120),
        SuccessDark = Color3.fromRGB(60, 200, 100),
        Warning = Color3.fromRGB(255, 180, 70),
        WarningDark = Color3.fromRGB(235, 160, 50),
        Info = Color3.fromRGB(65, 170, 255),
    },
    
    -- Enhanced fonts
    Fonts = {
        UI = Enum.Font.Gotham,
        Monospace = Enum.Font.Code,
        Bold = Enum.Font.GothamBold,
    },
    
    -- Settings
    Settings = {
        NotificationDuration = 3,
        AnimationSpeed = 0.2,
        CornerRadius = 8,
        ShadowSize = 12,
    },
    
    -- Internal
    Windows = {},
    ActiveWindow = nil,
    OpenedFrames = {},
    Signals = {},
    NotifyArea = nil,
    KeybindFrame = nil,
    KeybindContainer = nil,
    UIScale = 1,
}

-- Utility functions
local function GetTextBounds(Text, Font, Size)
    return TextService:GetTextSize(Text, Size, Font, Vector2.new(1920, 1080))
end

-- Create rounded corner helper
local function AddRoundedCorners(frame, radius)
    radius = radius or Library.Settings.CornerRadius
    local corners = Instance.new("UICorner")
    corners.CornerRadius = UDim.new(0, radius)
    corners.Parent = frame
    return corners
end

-- Create shadow effect
local function AddShadow(frame, size)
    size = size or Library.Settings.ShadowSize
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://13160452192" -- Soft shadow
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.Position = UDim2.new(0, -size/2, 0, -size/2)
    shadow.Size = UDim2.new(1, size, 1, size)
    shadow.ZIndex = -1
    shadow.Parent = frame
    return shadow
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
            if self.Theme[colorKey] then
                item.Instance[prop] = self.Theme[colorKey]
            end
        end
    end
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

-- Enhanced notification system
function Library:Notify(message, type, duration)
    type = type or "info"
    duration = duration or self.Settings.NotificationDuration
    
    if not self.NotifyArea then
        self.NotifyArea = self:Create("Frame", {
            Name = "NotificationArea",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -340, 0, 50),
            Size = UDim2.new(0, 320, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = ScreenGui,
        })
        
        self:Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = self.NotifyArea,
        })
    end
    
    -- Get color based on type
    local accentColor = self.Theme.Primary
    local icon = "ℹ"
    
    if type == "error" then
        accentColor = self.Theme.Danger
        icon = "✕"
    elseif type == "success" then
        accentColor = self.Theme.Success
        icon = "✓"
    elseif type == "warning" then
        accentColor = self.Theme.Warning
        icon = "⚠"
    end
    
    -- Create notification
    local notification = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        BorderColor3 = self.Theme.BorderLight,
        BorderSizePixel = 1,
        Size = UDim2.new(0, 320, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent = self.NotifyArea,
    })
    
    AddRoundedCorners(notification, 10)
    
    -- Accent bar
    local accentBar = self:Create("Frame", {
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 4, 1, 0),
        Parent = notification,
    })
    AddRoundedCorners(accentBar, 10)
    accentBar.UICorner.CornerRadius = UDim.new(0, 10)
    
    -- Icon
    local iconLabel = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(0, 24, 1, 0),
        Font = self.Fonts.UI,
        Text = icon,
        TextColor3 = accentColor,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = notification,
    })
    
    -- Message text
    local textLabel = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0, 12),
        Size = UDim2.new(1, -90, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = self.Fonts.UI,
        Text = message,
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification,
    })
    
    -- Progress bar
    local progressBar = self:Create("Frame", {
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = notification,
    })
    
    -- Close button
    local closeButton = self:Create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -35, 0, 8),
        Size = UDim2.new(0, 24, 0, 24),
        Font = self.Fonts.UI,
        Text = "✕",
        TextColor3 = self.Theme.TextSecondary,
        TextSize = 14,
        Parent = notification,
    })
    
    closeButton.MouseEnter:Connect(function()
        closeButton.TextColor3 = self.Theme.Danger
    end)
    
    closeButton.MouseLeave:Connect(function()
        closeButton.TextColor3 = self.Theme.TextSecondary
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        notification:Destroy()
    end)
    
    -- Animate in
    notification.Position = UDim2.new(1, 50, 0, 0)
    notification.BackgroundTransparency = 1
    
    local inTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -330, 0, 0),
        BackgroundTransparency = 0
    })
    inTween:Play()
    
    -- Progress bar animation
    local progressTween = TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    })
    progressTween:Play()
    
    -- Auto remove
    task.delay(duration, function()
        if notification and notification.Parent then
            local outTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 50, 0, 0),
                BackgroundTransparency = 1
            })
            outTween:Play()
            outTween.Completed:Connect(function()
                notification:Destroy()
            end)
        end
    end)
    
    return notification
end

-- Enhanced tooltip system
function Library:AddTooltip(text, instance)
    local tooltip = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        BorderColor3 = self.Theme.BorderLight,
        BorderSizePixel = 1,
        Size = UDim2.new(0, 0, 0, 0),
        Visible = false,
        ZIndex = 1000,
        Parent = ScreenGui,
    })
    
    AddRoundedCorners(tooltip, 6)
    AddShadow(tooltip, 4)
    
    local label = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = self.Fonts.UI,
        Text = text,
        TextColor3 = self.Theme.Text,
        TextSize = 12,
        TextWrapped = true,
        Parent = tooltip,
    })
    
    local active = false
    
    instance.MouseEnter:Connect(function()
        local textSize = GetTextBounds(text, self.Fonts.UI, 12)
        tooltip.Size = UDim2.new(0, textSize.X + 20, 0, textSize.Y + 12)
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

-- Enhanced window creation
function Library:CreateWindow(title, options)
    options = options or {}
    
    -- Main window frame
    local window = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Background,
        BorderColor3 = self.Theme.BorderLight,
        BorderSizePixel = 1,
        Position = options.Position or UDim2.fromOffset(100, 100),
        Size = options.Size or UDim2.fromOffset(700, 550),
        Visible = false,
        ClipsDescendants = true,
        Parent = ScreenGui,
    })
    
    AddRoundedCorners(window, 12)
    AddShadow(window, 15)
    
    -- Title bar
    local titleBar = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 50),
        Parent = window,
    })
    AddRoundedCorners(titleBar, 12)
    titleBar.UICorner.CornerRadius = UDim.new(0, 12)
    
    -- Accent line
    local accentLine = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Primary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        Parent = titleBar,
    })
    
    -- Title text with gradient effect
    local titleLabel = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        Font = self.Fonts.Bold,
        Text = title,
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })
    
    -- Window controls
    local controlsFrame = self:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -120, 0, 0),
        Size = UDim2.new(0, 120, 1, 0),
        Parent = titleBar,
    })
    
    -- Minimize button
    if options.Minimizable ~= false then
        local minButton = self:Create("TextButton", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 45, 1, 0),
            Font = self.Fonts.UI,
            Text = "−",
            TextColor3 = self.Theme.TextSecondary,
            TextSize = 20,
            Parent = controlsFrame,
        })
        
        local minimized = false
        local originalHeight = window.Size.Y.Offset
        
        minButton.MouseEnter:Connect(function()
            minButton.TextColor3 = self.Theme.Warning
        end)
        
        minButton.MouseLeave:Connect(function()
            minButton.TextColor3 = self.Theme.TextSecondary
        end)
        
        minButton.MouseButton1Click:Connect(function()
            minimized = not minimized
            local targetHeight = minimized and 50 or originalHeight
            TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, window.Size.X.Offset, 0, targetHeight)
            }):Play()
        end)
    end
    
    -- Close button
    if options.Closable ~= false then
        local closeButton = self:Create("TextButton", {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -45, 0, 0),
            Size = UDim2.new(0, 45, 1, 0),
            Font = self.Fonts.UI,
            Text = "✕",
            TextColor3 = self.Theme.TextSecondary,
            TextSize = 16,
            Parent = controlsFrame,
        })
        
        closeButton.MouseEnter:Connect(function()
            closeButton.TextColor3 = self.Theme.Danger
        end)
        
        closeButton.MouseLeave:Connect(function()
            closeButton.TextColor3 = self.Theme.TextSecondary
        end)
        
        closeButton.MouseButton1Click:Connect(function()
            TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 1
            }):Play()
            task.wait(0.2)
            window.Visible = false
        end)
    end
    
    -- Tab bar with underline effect
    local tabBar = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 50),
        Size = UDim2.new(1, 0, 0, 45),
        Parent = window,
    })
    
    -- Tab container (scrolling)
    local tabContainer = self:Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        ScrollDirection = Enum.ScrollDirection.X,
        Parent = tabBar,
    })
    
    -- Tab layout
    local tabLayout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabContainer,
    })
    
    -- Underline indicator
    local underline = self:Create("Frame", {
        BackgroundColor3 = self.Theme.Primary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(0, 0, 0, 2),
        Parent = tabBar,
    })
    
    -- Content area with subtle gradient
    local contentArea = self:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 107),
        Size = UDim2.new(1, -30, 1, -122),
        Parent = window,
    })
    
    -- Make draggable
    self:MakeDraggable(window, titleBar, 50)
    
    -- Tab management
    local tabs = {}
    local activeTab = nil
    
    local function updateTabScroll()
        task.wait()
        local totalWidth = 0
        for _, child in ipairs(tabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                totalWidth = totalWidth + child.Size.X.Offset + 5
            end
        end
        tabContainer.CanvasSize = UDim2.new(0, math.max(totalWidth, tabContainer.AbsoluteSize.X), 0, 0)
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
                TextColor3 = self.Theme.TextSecondary,
                TextSize = 14,
                Parent = tabContainer,
            })
            
            -- Hover effect
            button.MouseEnter:Connect(function()
                if activeTab ~= button then
                    TweenService:Create(button, TweenInfo.new(0.2), {
                        TextColor3 = self.Theme.Text
                    }):Play()
                end
            end)
            
            button.MouseLeave:Connect(function()
                if activeTab ~= button then
                    TweenService:Create(button, TweenInfo.new(0.2), {
                        TextColor3 = self.Theme.TextSecondary
                    }):Play()
                end
            end)
            
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
                Size = UDim2.new(0.5, -10, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = self.Theme.Primary,
                ScrollBarImageTransparency = 0.5,
                Parent = tabFrame,
            })
            
            local tabRightColumn = self:Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 10, 0, 0),
                Size = UDim2.new(0.5, -10, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = self.Theme.Primary,
                ScrollBarImageTransparency = 0.5,
                Parent = tabFrame,
            })
            
            local tabLeftLayout = self:Create("UIListLayout", {
                Padding = UDim.new(0, 15),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = tabLeftColumn,
            })
            
            local tabRightLayout = self:Create("UIListLayout", {
                Padding = UDim.new(0, 15),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = tabRightColumn,
            })
            
            tabLeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                tabLeftColumn.CanvasSize = UDim2.new(0, 0, 0, tabLeftLayout.AbsoluteContentSize.Y + 10)
            end)
            
            tabRightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                tabRightColumn.CanvasSize = UDim2.new(0, 0, 0, tabRightLayout.AbsoluteContentSize.Y + 10)
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
                    TweenService:Create(activeTab.Button, TweenInfo.new(0.2), {
                        TextColor3 = Library.Theme.TextSecondary
                    }):Play()
                    activeTab.Frame.Visible = false
                end
                activeTab = tabAPI
                TweenService:Create(button, TweenInfo.new(0.2), {
                    TextColor3 = Library.Theme.Primary
                }):Play()
                
                -- Animate underline
                local buttonPos = button.AbsolutePosition.X - tabBar.AbsolutePosition.X
                TweenService:Create(underline, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(0, buttonPos, 1, -2),
                    Size = UDim2.new(0, button.AbsoluteSize.X, 0, 2)
                }):Play()
                
                tabFrame.Visible = true
                updateTabScroll()
            end)
            
            table.insert(tabs, tabAPI)
            updateTabScroll()
            
            -- Activate first tab
            if #tabs == 1 then
                activeTab = tabAPI
                TweenService:Create(button, TweenInfo.new(0.2), {
                    TextColor3 = Library.Theme.Primary
                }):Play()
                tabFrame.Visible = true
                
                task.wait()
                local buttonPos = button.AbsolutePosition.X - tabBar.AbsolutePosition.X
                underline.Position = UDim2.new(0, buttonPos, 1, -2)
                underline.Size = UDim2.new(0, button.AbsoluteSize.X, 0, 2)
            end
            
            return tabAPI
        end,
        
        AddGroupbox = function(tab, side, title)
            -- Create groupbox frame
            local groupbox = self:Create("Frame", {
                BackgroundColor3 = self.Theme.Surface,
                BorderColor3 = self.Theme.BorderLight,
                BorderSizePixel = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = side == "left" and tab.LeftColumn or tab.RightColumn,
            })
            
            AddRoundedCorners(groupbox, 10)
            
            -- Header
            local header = self:Create("Frame", {
                BackgroundColor3 = self.Theme.Background,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                Parent = groupbox,
            })
            AddRoundedCorners(header, 10)
            
            -- Header accent
            local headerAccent = self:Create("Frame", {
                BackgroundColor3 = self.Theme.Primary,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 10),
                Size = UDim2.new(0, 3, 0, 20),
                Parent = header,
            })
            
            -- Title
            local titleLabel = self:Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 20, 0, 0),
                Size = UDim2.new(1, -32, 1, 0),
                Font = self.Fonts.Bold,
                Text = title,
                TextColor3 = self.Theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = header,
            })
            
            -- Content container
            local container = self:Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 40),
                Size = UDim2.new(1, -30, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = groupbox,
            })
            
            local contentLayout = self:Create("UIListLayout", {
                Padding = UDim.new(0, 10),
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = container,
            })
            
            -- Groupbox API
            local groupboxAPI = {
                Frame = groupbox,
                Container = container,
                Layout = contentLayout,
                
                AddButton = function(text, callback, options)
                    options = options or {}
                    
                    local button = self:Create("TextButton", {
                        BackgroundColor3 = self.Theme.Background,
                        BorderColor3 = self.Theme.Border,
                        BorderSizePixel = 1,
                        Size = UDim2.new(1, 0, 0, 36),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.Theme.Text,
                        TextSize = 14,
                        Parent = container,
                    })
                    
                    AddRoundedCorners(button, 6)
                    
                    -- Store callback
                    button.Callback = callback
                    
                    -- Hover effect
                    button.MouseEnter:Connect(function()
                        TweenService:Create(button, TweenInfo.new(0.2), {
                            BackgroundColor3 = self.Theme.Primary
                        }):Play()
                        TweenService:Create(button, TweenInfo.new(0.2), {
                            TextColor3 = Color3.new(1, 1, 1)
                        }):Play()
                    end)
                    
                    button.MouseLeave:Connect(function()
                        TweenService:Create(button, TweenInfo.new(0.2), {
                            BackgroundColor3 = self.Theme.Background
                        }):Play()
                        TweenService:Create(button, TweenInfo.new(0.2), {
                            TextColor3 = self.Theme.Text
                        }):Play()
                    end)
                    
                    button.MouseButton1Click:Connect(function()
                        if options.DoubleClick then
                            if not button.DoubleClickReady then
                                button.DoubleClickReady = true
                                local originalText = button.Text
                                button.Text = "Are you sure?"
                                TweenService:Create(button, TweenInfo.new(0.2), {
                                    BackgroundColor3 = self.Theme.Danger
                                }):Play()
                                task.delay(1.5, function()
                                    if button then
                                        button.DoubleClickReady = false
                                        button.Text = originalText
                                        TweenService:Create(button, TweenInfo.new(0.2), {
                                            BackgroundColor3 = self.Theme.Background
                                        }):Play()
                                    end
                                end)
                            else
                                button.DoubleClickReady = false
                                if callback then callback() end
                                button.Text = text
                                TweenService:Create(button, TweenInfo.new(0.2), {
                                    BackgroundColor3 = self.Theme.Success
                                }):Play()
                                task.delay(0.2, function()
                                    if button then
                                        TweenService:Create(button, TweenInfo.new(0.2), {
                                            BackgroundColor3 = self.Theme.Background
                                        }):Play()
                                    end
                                end)
                            end
                        else
                            if callback then callback() end
                            TweenService:Create(button, TweenInfo.new(0.2), {
                                BackgroundColor3 = self.Theme.PrimaryDark
                            }):Play()
                            task.delay(0.1, function()
                                if button then
                                    TweenService:Create(button, TweenInfo.new(0.2), {
                                        BackgroundColor3 = self.Theme.Background
                                    }):Play()
                                end
                            end)
                        end
                    end)
                    
                    -- Add tooltip if provided
                    if options.Tooltip then
                        self:AddTooltip(options.Tooltip, button)
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
                        Size = UDim2.new(1, 0, 0, 36),
                        Parent = container,
                    })
                    
                    local toggleButton = self:Create("TextButton", {
                        BackgroundColor3 = toggle.Value and self.Theme.Primary or self.Theme.Background,
                        BorderColor3 = self.Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 0, 6),
                        Size = UDim2.new(0, 24, 0, 24),
                        Font = self.Fonts.UI,
                        Text = toggle.Value and "✓" or "",
                        TextColor3 = self.Theme.Text,
                        TextSize = 14,
                        Parent = toggleFrame,
                    })
                    AddRoundedCorners(toggleButton, 12)
                    
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 34, 0, 0),
                        Size = UDim2.new(1, -34, 1, 0),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = toggleFrame,
                    })
                    
                    function toggle:SetValue(value)
                        toggle.Value = value
                        toggleButton.Text = value and "✓" or ""
                        TweenService:Create(toggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                            BackgroundColor3 = value and Library.Theme.Primary or Library.Theme.Background
                        }):Play()
                        self:AttemptSave()
                        if callback then callback(value) end
                    end
                    
                    toggleButton.MouseButton1Click:Connect(function()
                        toggle:SetValue(not toggle.Value)
                        TweenService:Create(toggleButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                            Size = UDim2.new(0, 20, 0, 20)
                        }):Play()
                        task.wait(0.05)
                        TweenService:Create(toggleButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                            Size = UDim2.new(0, 24, 0, 24)
                        }):Play()
                    end)
                    
                    if options and options.Tooltip then
                        self:AddTooltip(options.Tooltip, label)
                    end
                    
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
                        Size = UDim2.new(1, 0, 0, 65),
                        Parent = container,
                    })
                    
                    local labelFrame = self:Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 25),
                        Parent = sliderFrame,
                    })
                    
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = labelFrame,
                    })
                    
                    local valueLabel = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Font = self.Fonts.Monospace,
                        Text = tostring(slider.Value) .. (suffix or ""),
                        TextColor3 = self.Theme.Primary,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Parent = labelFrame,
                    })
                    
                    local sliderBg = self:Create("Frame", {
                        BackgroundColor3 = self.Theme.Background,
                        BorderColor3 = self.Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 0, 30),
                        Size = UDim2.new(1, 0, 0, 6),
                        Parent = sliderFrame,
                    })
                    AddRoundedCorners(sliderBg, 3)
                    
                    local sliderFill = self:Create("Frame", {
                        BackgroundColor3 = self.Theme.Primary,
                        BorderSizePixel = 0,
                        Size = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), 0, 1, 0),
                        Parent = sliderBg,
                    })
                    AddRoundedCorners(sliderFill, 3)
                    
                    local sliderHandle = self:Create("TextButton", {
                        BackgroundColor3 = self.Theme.PrimaryLight,
                        BorderColor3 = self.Theme.Primary,
                        BorderSizePixel = 2,
                        Position = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), -8, 0, -5),
                        Size = UDim2.new(0, 16, 0, 16),
                        Text = "",
                        Parent = sliderBg,
                    })
                    AddRoundedCorners(sliderHandle, 8)
                    
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
                        sliderHandle:TweenPosition(UDim2.new(percent, -8, 0, -5), "Out", "Quad", 0.1, true)
                        valueLabel.Text = tostring(value) .. (suffix or "")
                        if callback then callback(value) end
                        self:AttemptSave()
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
                
                AddDropdown = function(id, text, values, multi, default, callback)
                    local dropdown = {
                        Values = values,
                        Multi = multi or false,
                        Value = multi and {} or nil,
                        Type = "Dropdown",
                        Callback = callback or function() end,
                        Open = false,
                    }
                    
                    if not multi and default then
                        dropdown.Value = default
                    elseif multi and default then
                        for _, v in ipairs(default) do
                            dropdown.Value[v] = true
                        end
                    end
                    
                    local dropdownFrame = self:Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Parent = container,
                    })
                    
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 25),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = dropdownFrame,
                    })
                    
                    -- Display text for selected value
                    local displayText = ""
                    if not multi and dropdown.Value then
                        displayText = dropdown.Value
                    elseif multi then
                        local selected = {}
                        for k, v in pairs(dropdown.Value) do
                            if v then table.insert(selected, k) end
                        end
                        displayText = #selected > 0 and table.concat(selected, ", ") or "Select options..."
                    else
                        displayText = "Select..."
                    end
                    
                    local selectButton = self:Create("TextButton", {
                        BackgroundColor3 = self.Theme.Background,
                        BorderColor3 = self.Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 0, 27),
                        Size = UDim2.new(1, 0, 0, 34),
                        Font = self.Fonts.UI,
                        Text = displayText,
                        TextColor3 = self.Theme.Text,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = dropdownFrame,
                    })
                    AddRoundedCorners(selectButton, 6)
                    
                    local arrow = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -30, 0, 0),
                        Size = UDim2.new(0, 25, 1, 0),
                        Font = self.Fonts.UI,
                        Text = "▼",
                        TextColor3 = self.Theme.TextSecondary,
                        TextSize = 14,
                        Parent = selectButton,
                    })
                    
                    local dropdownList = self:Create("ScrollingFrame", {
                        BackgroundColor3 = self.Theme.Surface,
                        BorderColor3 = self.Theme.BorderLight,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 1, 4),
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
                        -- Clear existing items
                        for _, child in ipairs(dropdownList:GetChildren()) do
                            if child:IsA("TextButton") then
                                child:Destroy()
                            end
                        end
                        
                        for _, value in ipairs(values) do
                            local isSelected = multi and dropdown.Value[value] or dropdown.Value == value
                            
                            local item = self:Create("TextButton", {
                                BackgroundColor3 = isSelected and self.Theme.Primary or self.Theme.Surface,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, 0, 0, 32),
                                Font = self.Fonts.UI,
                                Text = value,
                                TextColor3 = self.Theme.Text,
                                TextSize = 13,
                                Parent = dropdownList,
                            })
                            
                            item.MouseEnter:Connect(function()
                                if not (multi and dropdown.Value[value]) and dropdown.Value ~= value then
                                    item.BackgroundColor3 = self.Theme.Primary
                                end
                            end)
                            
                            item.MouseLeave:Connect(function()
                                local stillSelected = multi and dropdown.Value[value] or dropdown.Value == value
                                item.BackgroundColor3 = stillSelected and self.Theme.Primary or self.Theme.Surface
                            end)
                            
                            item.MouseButton1Click:Connect(function()
                                if multi then
                                    dropdown.Value[value] = not dropdown.Value[value]
                                    local selectedText = {}
                                    for k, v in pairs(dropdown.Value) do
                                        if v then table.insert(selectedText, k) end
                                    end
                                    selectButton.Text = #selectedText > 0 and table.concat(selectedText, ", ") or "Select options..."
                                else
                                    dropdown.Value = value
                                    selectButton.Text = value
                                    dropdown.Open = false
                                    dropdownList.Visible = false
                                    arrow.Text = "▼"
                                end
                                
                                updateDropdownList()
                                if callback then callback(dropdown.Value) end
                                self:AttemptSave()
                            end)
                        end
                        
                        local count = #values
                        local height = math.min(count * 32, 200)
                        dropdownList.Size = UDim2.new(1, 0, 0, height)
                        dropdownList.CanvasSize = UDim2.new(0, 0, 0, count * 32)
                    end
                    
                    selectButton.MouseButton1Click:Connect(function()
                        dropdown.Open = not dropdown.Open
                        dropdownList.Visible = dropdown.Open
                        arrow.Text = dropdown.Open and "▲" or "▼"
                        if dropdown.Open then
                            updateDropdownList()
                            
                            -- Close when clicking outside
                            local function onClickOutside(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                                    local absPos = selectButton.AbsolutePosition
                                    local absSize = selectButton.AbsoluteSize
                                    
                                    if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or
                                       mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y + dropdownList.AbsoluteSize.Y then
                                        dropdown.Open = false
                                        dropdownList.Visible = false
                                        arrow.Text = "▼"
                                        InputService.InputBegan:Disconnect(clickConnection)
                                    end
                                end
                            end
                            
                            local clickConnection = InputService.InputBegan:Connect(onClickOutside)
                        end
                    end)
                    
                    function dropdown:SetValue(value)
                        if multi then
                            dropdown.Value = value or {}
                            local selectedText = {}
                            for k, v in pairs(dropdown.Value) do
                                if v then table.insert(selectedText, k) end
                            end
                            selectButton.Text = #selectedText > 0 and table.concat(selectedText, ", ") or "Select options..."
                        else
                            dropdown.Value = value
                            selectButton.Text = value or "Select..."
                        end
                        updateDropdownList()
                        if callback then callback(dropdown.Value) end
                        self:AttemptSave()
                    end
                    
                    function dropdown:SetValues(newValues)
                        dropdown.Values = newValues
                        updateDropdownList()
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
                        Size = UDim2.new(1, 0, 0, 65),
                        Parent = container,
                    })
                    
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 25),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = inputFrame,
                    })
                    
                    local textBox = self:Create("TextBox", {
                        BackgroundColor3 = self.Theme.Background,
                        BorderColor3 = self.Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 0, 27),
                        Size = UDim2.new(1, 0, 0, 34),
                        Font = self.Fonts.UI,
                        PlaceholderColor3 = self.Theme.TextMuted,
                        PlaceholderText = placeholder or "",
                        Text = "",
                        TextColor3 = self.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = inputFrame,
                        ClearTextOnFocus = false,
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
                        self:AttemptSave()
                    end
                    
                    textBox:GetPropertyChangedSignal("Text"):Connect(updateValue)
                    
                    -- Focus effect
                    textBox.Focused:Connect(function()
                        TweenService:Create(textBox, TweenInfo.new(0.2), {
                            BorderColor3 = self.Theme.Primary
                        }):Play()
                    end)
                    
                    textBox.FocusLost:Connect(function()
                        TweenService:Create(textBox, TweenInfo.new(0.2), {
                            BorderColor3 = self.Theme.Border
                        }):Play()
                    end)
                    
                    function input:SetValue(value)
                        input.Value = value
                        textBox.Text = tostring(value)
                        if callback then callback(value) end
                        self:AttemptSave()
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
                        Size = UDim2.new(1, 0, 0, 65),
                        Parent = container,
                    })
                    
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 25),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = pickerFrame,
                    })
                    
                    local colorDisplay = self:Create("TextButton", {
                        BackgroundColor3 = colorPicker.Value,
                        BorderColor3 = self.Theme.Border,
                        BorderSizePixel = 1,
                        Position = UDim2.new(0, 0, 0, 27),
                        Size = UDim2.new(1, 0, 0, 34),
                        Text = "",
                        Parent = pickerFrame,
                    })
                    AddRoundedCorners(colorDisplay, 6)
                    
                    -- Store RGB values
                    local r, g, b = colorPicker.Value.R, colorPicker.Value.G, colorPicker.Value.B
                    
                    local function updateDisplay()
                        colorPicker.Value = Color3.new(r, g, b)
                        colorDisplay.BackgroundColor3 = colorPicker.Value
                        if callback then callback(colorPicker.Value) end
                        self:AttemptSave()
                    end
                    
                    -- Create enhanced color picker popup
                    local function showColorPicker()
                        local popup = self:Create("Frame", {
                            BackgroundColor3 = self.Theme.Surface,
                            BorderColor3 = self.Theme.BorderLight,
                            BorderSizePixel = 1,
                            Position = UDim2.fromOffset(Mouse.X + 10, Mouse.Y + 10),
                            Size = UDim2.fromOffset(260, 280),
                            ZIndex = 100,
                            Parent = ScreenGui,
                        })
                        AddRoundedCorners(popup, 10)
                        AddShadow(popup, 10)
                        
                        -- Title bar
                        local popupTitle = self:Create("Frame", {
                            BackgroundColor3 = self.Theme.Background,
                            Size = UDim2.new(1, 0, 0, 35),
                            Parent = popup,
                        })
                        AddRoundedCorners(popupTitle, 10)
                        popupTitle.UICorner.CornerRadius = UDim.new(0, 10)
                        
                        self:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 15, 0, 0),
                            Size = UDim2.new(1, -50, 1, 0),
                            Font = self.Fonts.Bold,
                            Text = "Color Picker",
                            TextColor3 = self.Theme.Text,
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = popupTitle,
                        })
                        
                        local closeBtn = self:Create("TextButton", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, -35, 0, 0),
                            Size = UDim2.new(0, 35, 1, 0),
                            Font = self.Fonts.UI,
                            Text = "✕",
                            TextColor3 = self.Theme.TextSecondary,
                            TextSize = 14,
                            Parent = popupTitle,
                        })
                        
                        closeBtn.MouseEnter:Connect(function()
                            closeBtn.TextColor3 = self.Theme.Danger
                        end)
                        
                        closeBtn.MouseLeave:Connect(function()
                            closeBtn.TextColor3 = self.Theme.TextSecondary
                        end)
                        
                        -- Content
                        local content = self:Create("Frame", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 15, 0, 45),
                            Size = UDim2.new(1, -30, 1, -60),
                            Parent = popup,
                        })
                        
                        -- Color preview
                        local preview = self:Create("Frame", {
                            BackgroundColor3 = colorPicker.Value,
                            BorderColor3 = self.Theme.Border,
                            BorderSizePixel = 1,
                            Size = UDim2.new(1, 0, 0, 50),
                            Parent = content,
                        })
                        AddRoundedCorners(preview, 6)
                        
                        -- RGB Sliders container
                        local slidersFrame = self:Create("Frame", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 0, 0, 60),
                            Size = UDim2.new(1, 0, 0, 150),
                            Parent = content,
                        })
                        
                        local rSlider, gSlider, bSlider
                        
                        rSlider = groupboxAPI.AddSlider(nil, "Red", 0, 1, r, 2, "", function(val)
                            r = val
                            updateDisplay()
                            preview.BackgroundColor3 = colorPicker.Value
                            if rSlider then rSlider:SetValue(r) end
                        end)
                        
                        gSlider = groupboxAPI.AddSlider(nil, "Green", 0, 1, g, 2, "", function(val)
                            g = val
                            updateDisplay()
                            preview.BackgroundColor3 = colorPicker.Value
                            if gSlider then gSlider:SetValue(g) end
                        end)
                        
                        bSlider = groupboxAPI.AddSlider(nil, "Blue", 0, 1, b, 2, "", function(val)
                            b = val
                            updateDisplay()
                            preview.BackgroundColor3 = colorPicker.Value
                            if bSlider then bSlider:SetValue(b) end
                        end)
                        
                        -- Reparent sliders
                        if rSlider and rSlider.Frame then rSlider.Frame.Parent = slidersFrame end
                        if gSlider and gSlider.Frame then gSlider.Frame.Parent = slidersFrame end
                        if bSlider and bSlider.Frame then bSlider.Frame.Parent = slidersFrame end
                        
                        -- Update slider heights
                        if rSlider and rSlider.Frame then
                            rSlider.Frame.Size = UDim2.new(1, 0, 0, 45)
                        end
                        if gSlider and gSlider.Frame then
                            gSlider.Frame.Size = UDim2.new(1, 0, 0, 45)
                        end
                        if bSlider and bSlider.Frame then
                            bSlider.Frame.Size = UDim2.new(1, 0, 0, 45)
                        end
                        
                        -- Close button action
                        closeBtn.MouseButton1Click:Connect(function()
                            popup:Destroy()
                        end)
                        
                        -- Close when clicking outside
                        local function onInputBegan(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                                local absPos = popup.AbsolutePosition
                                local absSize = popup.AbsoluteSize
                                
                                if mousePos.X < absPos.X or mousePos.X > absPos.X + absSize.X or
                                   mousePos.Y < absPos.Y or mousePos.Y > absPos.Y + absSize.Y then
                                    popup:Destroy()
                                    InputService.InputBegan:Disconnect(connection)
                                end
                            end
                        end
                        
                        local connection = InputService.InputBegan:Connect(onInputBegan)
                    end
                    
                    colorDisplay.MouseButton1Click:Connect(showColorPicker)
                    
                    function colorPicker:SetValueRGB(color)
                        r, g, b = color.R, color.G, color.B
                        updateDisplay()
                    end
                    
                    Options[id] = colorPicker
                    return colorPicker
                end,
                
                AddDivider = function()
                    local divider = self:Create("Frame", {
                        BackgroundColor3 = self.Theme.Border,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 1),
                        Parent = container,
                    })
                    return divider
                end,
                
                AddLabel = function(text, centered)
                    local label = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 25),
                        Font = self.Fonts.UI,
                        Text = text,
                        TextColor3 = self.Theme.TextSecondary,
                        TextSize = 12,
                        TextXAlignment = centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
                        Parent = container,
                    })
                    return label
                end,
                
                AddParagraph = function(title, content)
                    local paraFrame = self:Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Parent = container,
                    })
                    
                    if title and title ~= "" then
                        local titleLabel = self:Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 25),
                            Font = self.Fonts.Bold,
                            Text = title,
                            TextColor3 = self.Theme.Text,
                            TextSize = 14,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Parent = paraFrame,
                        })
                    end
                    
                    local contentLabel = self:Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Font = self.Fonts.UI,
                        Text = content,
                        TextColor3 = self.Theme.TextSecondary,
                        TextSize = 12,
                        TextWrapped = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = paraFrame,
                    })
                    
                    return paraFrame
                end,
            }
            
            return groupboxAPI
        end,
        
        Show = function()
            window.Visible = true
            TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0,
                Position = UDim2.fromOffset(window.Position.X.Offset, window.Position.Y.Offset)
            }):Play()
        end,
        
        Hide = function()
            TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
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
        
        SetSize = function(width, height)
            TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, width, 0, height)
            }):Play()
        end,
    }
    
    table.insert(self.Windows, windowAPI)
    return windowAPI
end

function Library:AttemptSave()
    if self.SaveManager then
        self.SaveManager:Save()
    end
end

function Library:Unload()
    for _, connection in ipairs(self.Signals) do
        connection:Disconnect()
    end
    ScreenGui:Destroy()
    
    if self.OnUnload then
        self.OnUnload()
    end
end

function Library:OnUnload(callback)
    self.OnUnload = callback
end

return Library
