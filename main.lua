--[[
    =============================================================================
    THYREN - Blade Ball
    
    A lightweight, executor-friendly auto-parry and macro utility
    designed for Blade Ball on Roblox.
    
    Features:
        - Predictive auto-parry with no cooldown
        - Distance-based fallback parry mode
        - Configurable KPS/CPS macro spammer
        - Modern dark UI with UICorner styling
        - Hotkey binding system
        - Real-time ball tracking diagnostics
    
    Repository: https://github.com/yourname/thyren
    =============================================================================

    MIT License

    Copyright (c) 2024 Thyren

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
--]]

--------------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------------
local Players            = game:GetService("Players")
local CoreGui            = game:GetService("CoreGui")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

--------------------------------------------------------------------------------
-- Player References
--------------------------------------------------------------------------------
local LocalPlayer = Players.LocalPlayer
local PlayerName  = LocalPlayer.Name

--------------------------------------------------------------------------------
-- Cleanup: Remove any existing instance
--------------------------------------------------------------------------------
if CoreGui:FindFirstChild("ThyrenUI") then
    CoreGui:FindFirstChild("ThyrenUI"):Destroy()
end

--------------------------------------------------------------------------------
-- ScreenGui Setup (CoreGui only)
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name              = "ThyrenUI"
ScreenGui.ResetOnSpawn      = false
ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset    = true
ScreenGui.DisplayOrder      = 9999
ScreenGui.Enabled           = true
ScreenGui.Parent            = CoreGui

--------------------------------------------------------------------------------
-- Configuration State
--------------------------------------------------------------------------------
local Config = {
    -- Macro
    IsRunning    = false,
    TargetSpeed  = 10,
    Mode         = "KPS",   -- "KPS" or "CPS"
    Activation   = "Manual", -- "Manual", "Hotkey", or "Binding"
    Hotkey       = nil,
    
    -- Parry
    AutoParry    = false,
    Predictive   = true,
    Threshold    = 28,
    Buffer       = 0.05,
    
    -- UI
    Visible      = true,
    ToggleKey    = Enum.KeyCode.RightShift,
}

--------------------------------------------------------------------------------
-- Runtime Variables
--------------------------------------------------------------------------------
local MacroConnection   = nil
local ParryConnection   = nil
local LastFireTime      = 0
local CachedBall        = nil
local LastBallCheckTime = 0

--------------------------------------------------------------------------------
-- Color Palette
--------------------------------------------------------------------------------
local Palette = {
    Background    = Color3.fromRGB(15, 15, 20),
    Surface       = Color3.fromRGB(22, 22, 28),
    Raised        = Color3.fromRGB(32, 32, 40),
    Hover         = Color3.fromRGB(42, 42, 52),
    Pressed       = Color3.fromRGB(28, 28, 35),
    Accent        = Color3.fromRGB(120, 120, 145),
    AccentLight   = Color3.fromRGB(160, 160, 185),
    TextPrimary   = Color3.fromRGB(225, 225, 235),
    TextSecondary = Color3.fromRGB(135, 135, 155),
    TextMuted     = Color3.fromRGB(85, 85, 105),
    Border        = Color3.fromRGB(45, 45, 60),
    Success       = Color3.fromRGB(75, 195, 115),
    Warning       = Color3.fromRGB(225, 165, 55),
    ParryActive   = Color3.fromRGB(25, 45, 30),
}

--------------------------------------------------------------------------------
-- UI Utility Functions
--------------------------------------------------------------------------------

--- Adds rounded corners to a GUI element
---@param instance Instance
---@param radius number?
---@return UICorner
local function ApplyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

--- Adds a stroke border to a GUI element
---@param instance Instance
---@param color Color3?
---@param thickness number?
---@return UIStroke
local function ApplyStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color    = color or Palette.Border
    stroke.Thickness = thickness or 1
    stroke.Parent   = instance
    return stroke
end

--- Creates a simple hover effect for a button
---@param button TextButton
---@param baseColor Color3
local function ApplyHoverEffect(button, baseColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {
            BackgroundColor3 = Palette.Hover
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {
            BackgroundColor3 = baseColor
        }):Play()
    end)
end

--------------------------------------------------------------------------------
-- Macro System
--------------------------------------------------------------------------------

--- Fires a single key/mouse input based on current mode
local function FireInput()
    if Config.Mode == "KPS" then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    else
        local mousePos = UserInputService:GetMouseLocation()
        VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
    end
end

--- Main macro loop, called every frame
local function MacroTick()
    if not Config.IsRunning then return end
    
    local currentTime = os.clock()
    
    -- High speed: double tap per frame
    if Config.TargetSpeed >= 60 then
        FireInput()
        FireInput()
    -- Normal: rate limited
    elseif (currentTime - LastFireTime) >= (1 / Config.TargetSpeed) then
        LastFireTime = currentTime
        FireInput()
    end
end

--- Starts the macro
local function StartMacro()
    Config.IsRunning = true
    LastFireTime = os.clock()
    
    if MacroConnection then
        MacroConnection:Disconnect()
    end
    
    MacroConnection = RunService.PreRender:Connect(MacroTick)
end

--- Stops the macro
local function StopMacro()
    Config.IsRunning = false
    
    if MacroConnection then
        MacroConnection:Disconnect()
        MacroConnection = nil
    end
end

--- Toggles macro on/off
local function ToggleMacro()
    if Config.IsRunning then
        StopMacro()
    else
        StartMacro()
    end
end

--------------------------------------------------------------------------------
-- Ball Detection System
--------------------------------------------------------------------------------

--- Finds the active ball targeting the local player
---@return BasePart?
local function FindActiveBall()
    local currentTime = os.clock()
    
    -- Use cached ball if recent and valid
    if CachedBall and CachedBall.Parent and (currentTime - LastBallCheckTime) < 0.08 then
        return CachedBall
    end
    
    LastBallCheckTime = currentTime
    CachedBall = nil
    
    -- Method 1: Direct workspace scan
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("BasePart") and obj.Name:lower() == "ball" then
            local target = obj:GetAttribute("target") or obj:GetAttribute("Target")
            
            if not target then
                local targetValue = obj:FindFirstChild("target") or obj:FindFirstChild("Target")
                if targetValue then
                    target = targetValue.Value
                end
            end
            
            -- Ball is untargeted or targeting us
            if target == nil or target == PlayerName then
                CachedBall = obj
                return obj
            end
        end
    end
    
    -- Method 2: Check common folder names
    local folderNames = { "Balls", "Projectiles" }
    for _, folderName in ipairs(folderNames) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                if obj:IsA("BasePart") then
                    local target = obj:GetAttribute("target") or obj:GetAttribute("Target")
                    if target == nil or target == PlayerName then
                        CachedBall = obj
                        return obj
                    end
                end
            end
        end
    end
    
    return nil
end

--- Calculates the speed of a ball in studs per second
---@param ball BasePart
---@return number
local function GetBallSpeed(ball)
    if not ball then return 0 end
    local velocity = ball.AssemblyLinearVelocity
    return (velocity.X * velocity.X + velocity.Y * velocity.Y + velocity.Z * velocity.Z) ^ 0.5
end

--- Calculates estimated time until ball reaches target
---@param ball BasePart
---@param rootPart BasePart
---@return number
local function CalculateTimeToImpact(ball, rootPart)
    if not ball or not rootPart then return math.huge end
    
    local speed = GetBallSpeed(ball)
    if speed < 1 then return math.huge end
    
    local direction = rootPart.Position - ball.Position
    local distance  = direction.Magnitude
    local velocity  = ball.AssemblyLinearVelocity
    
    -- Project velocity onto direction vector
    local dotProduct = velocity.X * direction.X 
                     + velocity.Y * direction.Y 
                     + velocity.Z * direction.Z
    
    -- Ball moving away
    if dotProduct <= 0 then return math.huge end
    
    return distance / (dotProduct / distance)
end

--------------------------------------------------------------------------------
-- Auto Parry System
--------------------------------------------------------------------------------

--- Starts the auto-parry tracking loop
local function StartAutoParry()
    if ParryConnection then
        ParryConnection:Disconnect()
    end
    
    ParryConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoParry then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if not rootPart or not humanoid or humanoid.Health <= 0 then return end
        
        local ball = FindActiveBall()
        if not ball then return end
        
        local distance     = (ball.Position - rootPart.Position).Magnitude
        local ballSpeed    = GetBallSpeed(ball)
        local shouldParry  = false
        
        if Config.Predictive then
            -- Predictive mode: parry based on time-to-impact
            local timeToImpact  = CalculateTimeToImpact(ball, rootPart)
            local reactionWindow = Config.Buffer + (0.02 / (ballSpeed * 0.01 + 1))
            shouldParry = timeToImpact <= reactionWindow
        else
            -- Distance mode: parry when ball enters threshold range
            local dynamicThreshold = Config.Threshold
            if ballSpeed > 50 then
                dynamicThreshold = dynamicThreshold + (ballSpeed * 0.15)
            end
            dynamicThreshold = math.clamp(dynamicThreshold, 20, 65)
            shouldParry = distance <= dynamicThreshold
        end
        
        if shouldParry then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.delay(0.03, function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
        end
    end)
end

--- Stops the auto-parry tracking loop
local function StopAutoParry()
    if ParryConnection then
        ParryConnection:Disconnect()
        ParryConnection = nil
    end
end

--------------------------------------------------------------------------------
-- UI Construction
--------------------------------------------------------------------------------

-- Main container (for toggle visibility)
local Container = Instance.new("Frame")
Container.Name                 = "Container"
Container.Size                 = UDim2.new(1, 0, 1, 0)
Container.BackgroundTransparency = 1
Container.Parent               = ScreenGui

-- Main panel
local MainPanel = Instance.new("Frame")
MainPanel.Name                 = "MainPanel"
MainPanel.Size                 = UDim2.new(0, 400, 0, 320)
MainPanel.Position             = UDim2.new(0.5, -200, 0.5, -160)
MainPanel.BackgroundColor3     = Palette.Background
MainPanel.BorderSizePixel      = 0
MainPanel.Active               = true
MainPanel.Draggable            = true
MainPanel.Parent               = Container
ApplyCorner(MainPanel, 12)
ApplyStroke(MainPanel, Palette.Border, 1)

-- Title bar background
local TitleBar = Instance.new("Frame")
TitleBar.Size                 = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3     = Palette.Surface
TitleBar.BorderSizePixel      = 0
TitleBar.Parent               = MainPanel
ApplyCorner(TitleBar, 12)

-- Fix bottom corners of title bar
local TitleBarFix = Instance.new("Frame")
TitleBarFix.Size                 = UDim2.new(1, 0, 0, 10)
TitleBarFix.Position             = UDim2.new(0, 0, 1, -10)
TitleBarFix.BackgroundColor3     = Palette.Surface
TitleBarFix.BorderSizePixel      = 0
TitleBarFix.Parent               = TitleBar

-- Title text
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size                 = UDim2.new(0, 100, 1, 0)
TitleLabel.Position             = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text                 = "THYREN"
TitleLabel.TextColor3           = Palette.TextPrimary
TitleLabel.TextSize             = 14
TitleLabel.Font                 = Enum.Font.GothamBold
TitleLabel.TextXAlignment       = Enum.TextXAlignment.Left
TitleLabel.Parent               = TitleBar

-- Game identifier
local GameLabel = Instance.new("TextLabel")
GameLabel.Size                 = UDim2.new(0, 80, 1, 0)
GameLabel.Position             = UDim2.new(1, -85, 0, 0)
GameLabel.BackgroundTransparency = 1
GameLabel.Text                 = "BLADE BALL"
GameLabel.TextColor3           = Palette.TextMuted
GameLabel.TextSize             = 9
GameLabel.Font                 = Enum.Font.GothamMedium
GameLabel.TextXAlignment       = Enum.TextXAlignment.Right
GameLabel.Parent               = TitleBar

-- Content area
local ContentFrame = Instance.new("Frame")
ContentFrame.Size                 = UDim2.new(1, -16, 1, -42)
ContentFrame.Position             = UDim2.new(0, 8, 0, 38)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent               = MainPanel

--------------------------------------------------------------------------------
-- Mode Button
--------------------------------------------------------------------------------
local ModeButton = Instance.new("TextButton")
ModeButton.Size                 = UDim2.new(0.48, 0, 0, 30)
ModeButton.Position             = UDim2.new(0, 0, 0, 0)
ModeButton.BackgroundColor3     = Palette.Raised
ModeButton.BorderSizePixel      = 0
ModeButton.Text                 = "MODE: KPS"
ModeButton.TextColor3           = Palette.TextPrimary
ModeButton.TextSize             = 11
ModeButton.Font                 = Enum.Font.GothamBold
ModeButton.AutoButtonColor      = false
ModeButton.Parent               = ContentFrame
ApplyCorner(ModeButton, 8)
ApplyHoverEffect(ModeButton, Palette.Raised)

--------------------------------------------------------------------------------
-- Keybind Button
--------------------------------------------------------------------------------
local BindButton = Instance.new("TextButton")
BindButton.Size                 = UDim2.new(0.48, 0, 0, 30)
BindButton.Position             = UDim2.new(0.52, 0, 0, 0)
BindButton.BackgroundColor3     = Palette.Raised
BindButton.BorderSizePixel      = 0
BindButton.Text                 = "KEYBIND"
BindButton.TextColor3           = Palette.TextPrimary
BindButton.TextSize             = 11
BindButton.Font                 = Enum.Font.GothamBold
BindButton.AutoButtonColor      = false
BindButton.Parent               = ContentFrame
ApplyCorner(BindButton, 8)
ApplyHoverEffect(BindButton, Palette.Raised)

--------------------------------------------------------------------------------
-- Speed Display
--------------------------------------------------------------------------------
local SpeedDisplay = Instance.new("TextLabel")
SpeedDisplay.Size                 = UDim2.new(0, 80, 0, 18)
SpeedDisplay.Position             = UDim2.new(1, -80, 0, 36)
SpeedDisplay.BackgroundTransparency = 1
SpeedDisplay.Text                 = "10 KPS"
SpeedDisplay.TextColor3           = Palette.TextSecondary
SpeedDisplay.TextSize             = 11
SpeedDisplay.Font                 = Enum.Font.GothamBold
SpeedDisplay.TextXAlignment       = Enum.TextXAlignment.Right
SpeedDisplay.Parent               = ContentFrame

--------------------------------------------------------------------------------
-- Speed Slider
--------------------------------------------------------------------------------
local SpeedTrack = Instance.new("Frame")
SpeedTrack.Size                 = UDim2.new(1, 0, 0, 6)
SpeedTrack.Position             = UDim2.new(0, 0, 0, 45)
SpeedTrack.BackgroundColor3     = Color3.fromRGB(28, 28, 36)
SpeedTrack.BorderSizePixel      = 0
SpeedTrack.Parent               = ContentFrame
ApplyCorner(SpeedTrack, 3)

local SpeedFill = Instance.new("Frame")
SpeedFill.Size                 = UDim2.new(0.004, 0, 1, 0)
SpeedFill.BackgroundColor3     = Palette.Accent
SpeedFill.BorderSizePixel      = 0
SpeedFill.Parent               = SpeedTrack
ApplyCorner(SpeedFill, 3)

local SpeedHandle = Instance.new("TextButton")
SpeedHandle.Size                 = UDim2.new(0, 14, 0, 14)
SpeedHandle.Position             = UDim2.new(0.004, -7, 0.5, -7)
SpeedHandle.BackgroundColor3     = Palette.AccentLight
SpeedHandle.BorderSizePixel      = 0
SpeedHandle.Text                 = ""
SpeedHandle.AutoButtonColor      = false
SpeedHandle.Parent               = SpeedTrack
ApplyCorner(SpeedHandle, 7)

--------------------------------------------------------------------------------
-- Auto Parry Button
--------------------------------------------------------------------------------
local ParryButton = Instance.new("TextButton")
ParryButton.Size                 = UDim2.new(1, 0, 0, 34)
ParryButton.Position             = UDim2.new(0, 0, 0, 65)
ParryButton.BackgroundColor3     = Palette.Raised
ParryButton.BorderSizePixel      = 0
ParryButton.Text                 = "AUTO PARRY: OFF"
ParryButton.TextColor3           = Palette.TextMuted
ParryButton.TextSize             = 12
ParryButton.Font                 = Enum.Font.GothamBold
ParryButton.AutoButtonColor      = false
ParryButton.Parent               = ContentFrame
ApplyCorner(ParryButton, 8)
ApplyHoverEffect(ParryButton, Palette.Raised)

--------------------------------------------------------------------------------
-- Predictive Button
--------------------------------------------------------------------------------
local PredictButton = Instance.new("TextButton")
PredictButton.Size                 = UDim2.new(0.55, 0, 0, 28)
PredictButton.Position             = UDim2.new(0, 0, 0, 107)
PredictButton.BackgroundColor3     = Palette.Raised
PredictButton.BorderSizePixel      = 0
PredictButton.Text                 = "PREDICTIVE: ON"
PredictButton.TextColor3           = Palette.Success
PredictButton.TextSize             = 10
PredictButton.Font                 = Enum.Font.GothamBold
PredictButton.AutoButtonColor      = false
PredictButton.Parent               = ContentFrame
ApplyCorner(PredictButton, 8)
ApplyHoverEffect(PredictButton, Palette.Raised)

--------------------------------------------------------------------------------
-- Threshold Controls
--------------------------------------------------------------------------------
local ThresholdLabel = Instance.new("TextLabel")
ThresholdLabel.Size                 = UDim2.new(0, 50, 0, 18)
ThresholdLabel.Position             = UDim2.new(0.57, 0, 0, 112)
ThresholdLabel.BackgroundTransparency = 1
ThresholdLabel.Text                 = tostring(Config.Threshold)
ThresholdLabel.TextColor3           = Palette.TextMuted
ThresholdLabel.TextSize             = 10
ThresholdLabel.Font                 = Enum.Font.GothamMedium
ThresholdLabel.Parent               = ContentFrame

local ThresholdTrack = Instance.new("Frame")
ThresholdTrack.Size                 = UDim2.new(0.35, 0, 0, 4)
ThresholdTrack.Position             = UDim2.new(0.72, 0, 0, 120)
ThresholdTrack.BackgroundColor3     = Color3.fromRGB(28, 28, 36)
ThresholdTrack.BorderSizePixel      = 0
ThresholdTrack.Parent               = ContentFrame
ApplyCorner(ThresholdTrack, 2)

local ThresholdFill = Instance.new("Frame")
ThresholdFill.Size                 = UDim2.new(0.3, 0, 1, 0)
ThresholdFill.BackgroundColor3     = Palette.Accent
ThresholdFill.BorderSizePixel      = 0
ThresholdFill.Parent               = ThresholdTrack
ApplyCorner(ThresholdFill, 2)

local ThresholdHandle = Instance.new("TextButton")
ThresholdHandle.Size                 = UDim2.new(0, 10, 0, 10)
ThresholdHandle.Position             = UDim2.new(0.3, -5, 0.5, -5)
ThresholdHandle.BackgroundColor3     = Palette.AccentLight
ThresholdHandle.BorderSizePixel      = 0
ThresholdHandle.Text                 = ""
ThresholdHandle.AutoButtonColor      = false
ThresholdHandle.Parent               = ThresholdTrack
ApplyCorner(ThresholdHandle, 5)

--------------------------------------------------------------------------------
-- Diagnostics Panel
--------------------------------------------------------------------------------
local DiagPanel = Instance.new("Frame")
DiagPanel.Size                 = UDim2.new(1, 0, 0, 80)
DiagPanel.Position             = UDim2.new(0, 0, 0, 145)
DiagPanel.BackgroundColor3     = Palette.Surface
DiagPanel.BorderSizePixel      = 0
DiagPanel.Parent               = ContentFrame
ApplyCorner(DiagPanel, 8)
ApplyStroke(DiagPanel, Palette.Border, 1)

local DiagStatusLabel = Instance.new("TextLabel")
DiagStatusLabel.Size                 = UDim2.new(1, -16, 0, 18)
DiagStatusLabel.Position             = UDim2.new(0, 8, 0, 10)
DiagStatusLabel.BackgroundTransparency = 1
DiagStatusLabel.Text                 = "MACRO: IDLE"
DiagStatusLabel.TextColor3           = Palette.TextMuted
DiagStatusLabel.TextSize             = 10
DiagStatusLabel.Font                 = Enum.Font.GothamMedium
DiagStatusLabel.TextXAlignment       = Enum.TextXAlignment.Left
DiagStatusLabel.Parent               = DiagPanel

local DiagBindLabel = Instance.new("TextLabel")
DiagBindLabel.Size                 = UDim2.new(1, -16, 0, 18)
DiagBindLabel.Position             = UDim2.new(0, 8, 0, 30)
DiagBindLabel.BackgroundTransparency = 1
DiagBindLabel.Text                 = "BIND: NONE"
DiagBindLabel.TextColor3           = Palette.TextMuted
DiagBindLabel.TextSize             = 10
DiagBindLabel.Font                 = Enum.Font.GothamMedium
DiagBindLabel.TextXAlignment       = Enum.TextXAlignment.Left
DiagBindLabel.Parent               = DiagPanel

local DiagParryLabel = Instance.new("TextLabel")
DiagParryLabel.Size                 = UDim2.new(1, -16, 0, 18)
DiagParryLabel.Position             = UDim2.new(0, 8, 0, 50)
DiagParryLabel.BackgroundTransparency = 1
DiagParryLabel.Text                 = "PARRY: OFF"
DiagParryLabel.TextColor3           = Palette.TextMuted
DiagParryLabel.TextSize             = 10
DiagParryLabel.Font                 = Enum.Font.GothamMedium
DiagParryLabel.TextXAlignment       = Enum.TextXAlignment.Left
DiagParryLabel.Parent               = DiagPanel

--------------------------------------------------------------------------------
-- Activate Button (Outside main panel for independent dragging)
--------------------------------------------------------------------------------
local ActivateButton = Instance.new("TextButton")
ActivateButton.Size                 = UDim2.new(0, 360, 0, 36)
ActivateButton.Position             = UDim2.new(0.5, -180, 0.5, 170)
ActivateButton.BackgroundColor3     = Palette.Surface
ActivateButton.BorderSizePixel      = 0
ActivateButton.Text                 = "ACTIVATE"
ActivateButton.TextColor3           = Palette.TextPrimary
ActivateButton.TextSize             = 13
ActivateButton.Font                 = Enum.Font.GothamBold
ActivateButton.AutoButtonColor      = false
ActivateButton.Parent               = Container
ApplyCorner(ActivateButton, 10)
ApplyStroke(ActivateButton, Palette.Border, 1)
ApplyHoverEffect(ActivateButton, Palette.Surface)

--------------------------------------------------------------------------------
-- UI Update Function
--------------------------------------------------------------------------------
local function UpdateUI()
    -- Speed display
    local modeSuffix = Config.Mode == "KPS" and "KPS" or "CPS"
    SpeedDisplay.Text = Config.TargetSpeed .. " " .. modeSuffix
    
    -- Show/hide activate button based on activation mode
    ActivateButton.Visible = (Config.Activation == "Manual")
    
    -- Update macro status
    if Config.IsRunning then
        ActivateButton.Text = "STOP"
        ActivateButton.BackgroundColor3 = Palette.Raised
        DiagStatusLabel.Text = "MACRO: RUNNING"
        DiagStatusLabel.TextColor3 = Palette.Success
    else
        ActivateButton.Text = "ACTIVATE"
        ActivateButton.BackgroundColor3 = Palette.Surface
        DiagStatusLabel.Text = "MACRO: IDLE"
        DiagStatusLabel.TextColor3 = Palette.TextMuted
    end
end

--------------------------------------------------------------------------------
-- Diagnostics Loop
--------------------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.3) do
        if Config.AutoParry then
            local ball = FindActiveBall()
            if ball then
                local speed = math.floor(GetBallSpeed(ball))
                DiagParryLabel.Text = "PARRY: LOCKED " .. speed .. " spd"
                DiagParryLabel.TextColor3 = Palette.Success
            else
                DiagParryLabel.Text = "PARRY: SEARCHING"
                DiagParryLabel.TextColor3 = Palette.Warning
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

-- Mode toggle
ModeButton.MouseButton1Click:Connect(function()
    Config.Mode = Config.Mode == "KPS" and "CPS" or "KPS"
    ModeButton.Text = "MODE: " .. Config.Mode
    UpdateUI()
end)

-- Keybind toggle
BindButton.MouseButton1Click:Connect(function()
    if Config.Activation == "Manual" then
        Config.Activation = "Binding"
        BindButton.Text = "PRESS KEY..."
        BindButton.TextColor3 = Palette.Warning
    else
        if Config.IsRunning then
            StopMacro()
        end
        Config.Activation = "Manual"
        Config.Hotkey = nil
        BindButton.Text = "KEYBIND"
        BindButton.TextColor3 = Palette.TextPrimary
        DiagBindLabel.Text = "BIND: NONE"
        DiagBindLabel.TextColor3 = Palette.TextMuted
        UpdateUI()
    end
end)

-- Auto parry toggle
ParryButton.MouseButton1Click:Connect(function()
    Config.AutoParry = not Config.AutoParry
    
    if Config.AutoParry then
        ParryButton.Text = "AUTO PARRY: ON"
        ParryButton.TextColor3 = Palette.Success
        ParryButton.BackgroundColor3 = Palette.ParryActive
        StartAutoParry()
    else
        ParryButton.Text = "AUTO PARRY: OFF"
        ParryButton.TextColor3 = Palette.TextMuted
        ParryButton.BackgroundColor3 = Palette.Raised
        StopAutoParry()
    end
    
    UpdateUI()
end)

-- Predictive toggle
PredictButton.MouseButton1Click:Connect(function()
    Config.Predictive = not Config.Predictive
    PredictButton.Text = "PREDICTIVE: " .. (Config.Predictive and "ON" or "OFF")
    PredictButton.TextColor3 = Config.Predictive and Palette.Success or Palette.TextMuted
end)

-- Activate button
ActivateButton.MouseButton1Click:Connect(function()
    if Config.Activation == "Manual" then
        ToggleMacro()
        UpdateUI()
    end
end)

--------------------------------------------------------------------------------
-- Slider Interaction
--------------------------------------------------------------------------------
local IsDraggingSpeed     = false
local IsDraggingThreshold = false

-- Helper to update speed slider visuals
local function UpdateSpeedSlider(fraction)
    fraction = math.clamp(fraction, 0, 1)
    Config.TargetSpeed = math.floor(1 + fraction * 2499)
    SpeedFill.Size = UDim2.new(fraction, 0, 1, 0)
    SpeedHandle.Position = UDim2.new(fraction, -7, 0.5, -7)
    UpdateUI()
end

-- Helper to update threshold slider visuals
local function UpdateThresholdSlider(fraction)
    fraction = math.clamp(fraction, 0, 1)
    Config.Threshold = math.floor(10 + fraction * 60)
    ThresholdFill.Size = UDim2.new(fraction, 0, 1, 0)
    ThresholdHandle.Position = UDim2.new(fraction, -5, 0.5, -5)
    ThresholdLabel.Text = tostring(Config.Threshold)
end

-- Speed handle input
SpeedHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingSpeed = true
    end
end)

-- Speed track click
SpeedTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingSpeed = true
        local fraction = (input.Position.X - SpeedTrack.AbsolutePosition.X) / SpeedTrack.AbsoluteSize.X
        UpdateSpeedSlider(fraction)
    end
end)

-- Threshold handle input
ThresholdHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingThreshold = true
    end
end)

-- Threshold track click
ThresholdTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingThreshold = true
        local fraction = (input.Position.X - ThresholdTrack.AbsolutePosition.X) / ThresholdTrack.AbsoluteSize.X
        UpdateThresholdSlider(fraction)
    end
end)

-- Mouse/touch movement for sliders
UserInputService.InputChanged:Connect(function(input)
    if IsDraggingSpeed and (input.UserInputType == Enum.UserInputType.MouseMovement 
    or input.UserInputType == Enum.UserInputType.Touch) then
        local fraction = (input.Position.X - SpeedTrack.AbsolutePosition.X) / SpeedTrack.AbsoluteSize.X
        UpdateSpeedSlider(fraction)
    end
    
    if IsDraggingThreshold and (input.UserInputType == Enum.UserInputType.MouseMovement 
    or input.UserInputType == Enum.UserInputType.Touch) then
        local fraction = (input.Position.X - ThresholdTrack.AbsolutePosition.X) / ThresholdTrack.AbsoluteSize.X
        UpdateThresholdSlider(fraction)
    end
end)

-- Release sliders
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 
    or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingSpeed = false
        IsDraggingThreshold = false
    end
end)

--------------------------------------------------------------------------------
-- Keyboard Input Handler
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Handle keybind assignment
    if Config.Activation == "Binding" then
        if input.KeyCode ~= Enum.KeyCode.Unknown 
        and input.KeyCode ~= Config.ToggleKey then
            Config.Hotkey = input.KeyCode
            Config.Activation = "Hotkey"
            BindButton.Text = "[" .. input.KeyCode.Name .. "]"
            BindButton.TextColor3 = Palette.Success
            DiagBindLabel.Text = "BIND: " .. input.KeyCode.Name
            DiagBindLabel.TextColor3 = Palette.TextSecondary
            UpdateUI()
        end
        return
    end
    
    -- Ignore UI inputs
    if gameProcessed then return end
    
    -- Toggle UI visibility
    if input.KeyCode == Config.ToggleKey then
        Config.Visible = not Config.Visible
        Container.Visible = Config.Visible
    end
    
    -- Hotkey activation
    if Config.Hotkey and input.KeyCode == Config.Hotkey and Config.Activation == "Hotkey" then
        ToggleMacro()
        UpdateUI()
    end
end)

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------
UpdateUI()
