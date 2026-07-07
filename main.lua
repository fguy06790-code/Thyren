-- =============================================================================
-- THYREN DECOUPLED REPOSITORY DASHBOARD (HIGH-PRECISION GITHUB THEME)
-- TARGET: Roblox Executor Environment (Ultra-Accurate Asynchronous Spammer)
-- LAYOUT: Open-Source Dashboard Layout & Embedded Badge Metrics
-- TOGGLE: Press RIGHT SHIFT to Hide/Show the Configuration Control Panel
-- =============================================================================

local uiName = "ThyrenEngineUI"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 1. CLEANUP PREVIOUS INSTANCES
pcall(function()
    if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end
end)
pcall(function()
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(uiName) then 
        LocalPlayer.PlayerGui[uiName]:Destroy() 
    end
end)

-- 2. DETERMINING SAFE EXECUTOR STORAGE
local TargetParent = nil
local successCore, _ = pcall(function()
    local test = Instance.new("Folder")
    test.Parent = CoreGui
    test:Destroy()
    TargetParent = CoreGui
end)
if not successCore or not TargetParent then
    TargetParent = LocalPlayer:WaitForChild("PlayerGui")
end

-- 3. SYSTEM STATE CONFIGURATION
local EngineState = {
    IsRunning = false,
    TargetSpeed = 10,
    ModeSelection = "KPS",
    LowEndMode = false,
    AutoParryActive = false,
    ParryThreshold = 45,
    SpamKey = Enum.KeyCode.F,
    ParryConnection = nil,
    ConfigVisible = true
}

-- 4. HIGH-PRECISION INPUT SIMULATION ENGINE
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function fireInput()
    if EngineState.ModeSelection == "KPS" then
        VirtualInputManager:SendKeyEvent(true, EngineState.SpamKey, false, game)
        VirtualInputManager:SendKeyEvent(false, EngineState.SpamKey, false, game)
    else
        local mousePos = UserInputService:GetMouseLocation()
        VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
    end
end

-- Asynchronous high-frequency thread loop for precise execution intervals
local function RunSpamThread()
    while EngineState.IsRunning do
        local delayInterval = 1.0 / EngineState.TargetSpeed
        fireInput()
        
        if delayInterval > 0 then
            task.wait(delayInterval)
        else
            task.wait() -- Absolute hardware cap safeguard
        end
    end
end

local function StartLoop()
    EngineState.IsRunning = true
    task.spawn(RunSpamThread)
end

local function StopLoop()
    EngineState.IsRunning = false
end

-- 5. DEFENSIVE BALL DETECTION SYSTEM
local function FindActiveBall()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "Ball" or obj:FindFirstChild("Ball") or obj:GetAttribute("Ball") then
            return obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
        end
    end
    return nil
end

local function StartParryTracking()
    if EngineState.ParryConnection then EngineState.ParryConnection:Disconnect() end
    
    EngineState.ParryConnection = RunService.PostSimulation:Connect(function()
        if not EngineState.AutoParryActive then return end
        
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local ball = FindActiveBall()
        if ball then
            local distance = (ball.Position - rootPart.Position).Magnitude
            local relativeVelocity = ball.AssemblyLinearVelocity - rootPart.AssemblyLinearVelocity
            local isMovingToward = relativeVelocity:Dot(rootPart.Position - ball.Position) > 0
            
            if isMovingToward and distance <= EngineState.ParryThreshold then
                fireInput()
            end
        end
    end)
end

local function StopParryTracking()
    if EngineState.ParryConnection then
        EngineState.ParryConnection:Disconnect()
        EngineState.ParryConnection = nil
    end
end

-- -----------------------------------------------------------------------------
-- GLOBAL ROOT SCREEN CONTAINER
-- -----------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = uiName
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = TargetParent

local function ApplyRadius(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

-- =============================================================================
-- PANEL MODULE 1: MAIN DASHBOARD (GITHUB REPOSITORY FLAT THEME)
-- =============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 360)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
ApplyRadius(MainFrame, 8)

-- Header Title Label
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 460, 0, 40)
TitleLabel.Position = UDim2.new(0.5, -230, 0.5, -200)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "📦 thyren-engine / core-dashboard"
TitleLabel.TextColor3 = Color3.fromRGB(201, 209, 217)
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 5
TitleLabel.Parent = ScreenGui

-- Mode Selection Switcher Button
local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 215, 0, 42)
ModeBtn.Position = UDim2.new(0.5, -230, 0.5, -150)
ModeBtn.BackgroundColor3 = Color3.fromRGB(33, 38, 45)
ModeBtn.BorderSizePixel = 0
ModeBtn.Text = "⚙️ Mode: Keyboard (KPS)"
ModeBtn.TextColor3 = Color3.fromRGB(240, 246, 252)
ModeBtn.Font = Enum.Font.SourceSansBold
ModeBtn.TextSize = 13
ModeBtn.ZIndex = 5
ModeBtn.Parent = ScreenGui
ApplyRadius(ModeBtn, 6)

-- Hardware Low End Performance Guard
local GuardBtn = Instance.new("TextButton")
GuardBtn.Size = UDim2.new(0, 215, 0, 42)
GuardBtn.Position = UDim2.new(0.5, 15, 0.5, -150)
GuardBtn.BackgroundColor3 = Color3.fromRGB(33, 38, 45)
GuardBtn.BorderSizePixel = 0
GuardBtn.Text = "🛡️ Profile: Uncapped"
GuardBtn.TextColor3 = Color3.fromRGB(240, 246, 252)
GuardBtn.Font = Enum.Font.SourceSansBold
GuardBtn.TextSize = 13
GuardBtn.ZIndex = 5
GuardBtn.Parent = ScreenGui
ApplyRadius(GuardBtn, 6)

-- INTERACTIVE SLIDER COMPONENT
local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(0, 340, 0, 6)
SliderTrack.Position = UDim2.new(0.5, -230, 0.5, -85)
SliderTrack.BackgroundColor3 = Color3.fromRGB(48, 54, 61)
SliderTrack.BorderSizePixel = 0
SliderTrack.ZIndex = 5
SliderTrack.Parent = ScreenGui
ApplyRadius(SliderTrack, 3)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.01, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(31, 111, 235)
SliderFill.BorderSizePixel = 0
SliderFill.ZIndex = 6
SliderFill.Parent = SliderTrack
ApplyRadius(SliderFill, 3)

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 14, 0, 14)
SliderButton.Position = UDim2.new(0.01, -7, 0.5, -7)
SliderButton.BackgroundColor3 = Color3.fromRGB(240, 246, 252)
SliderButton.BorderSizePixel = 0
SliderButton.Text = ""
SliderButton.ZIndex = 7
SliderButton.Parent = SliderTrack
ApplyRadius(SliderButton, 7)

-- Numerical KPS Metric Output Display Text Label
local SpeedDisplay = Instance.new("TextLabel")
SpeedDisplay.Size = UDim2.new(0, 100, 0, 30)
SpeedDisplay.Position = UDim2.new(0.5, 130, 0.5, -97)
SpeedDisplay.BackgroundTransparency = 1
SpeedDisplay.Text = "10 KPS"
SpeedDisplay.TextColor3 = Color3.fromRGB(56, 139, 253)
SpeedDisplay.Font = Enum.Font.Code
SpeedDisplay.TextSize = 14
SpeedDisplay.TextXAlignment = Enum.TextXAlignment.Right
SpeedDisplay.ZIndex = 5
SpeedDisplay.Parent = ScreenGui

-- AUTO PARRY TOGGLE INTERFACE UTILITY
local ParryBtn = Instance.new("TextButton")
ParryBtn.Size = UDim2.new(0, 460, 0, 40)
ParryBtn.Position = UDim2.new(0.5, -230, 0.5, -55)
ParryBtn.BackgroundColor3 = Color3.fromRGB(33, 38, 45)
ParryBtn.BorderSizePixel = 0
ParryBtn.Text = "⚔️ Auto Parry: Disabled"
ParryBtn.TextColor3 = Color3.fromRGB(248, 81, 73)
ParryBtn.Font = Enum.Font.SourceSansBold
ParryBtn.TextSize = 14
ParryBtn.ZIndex = 5
ParryBtn.Parent = ScreenGui
ApplyRadius(ParryBtn, 6)

-- =============================================================================
-- REPOSITORY VIEW: REPO METRICS DICTIONARY FRAME
-- =============================================================================
local DiagPanel = Instance.new("Frame")
DiagPanel.Name = "DiagPanel"
DiagPanel.Size = UDim2.new(0, 460, 0, 110)
DiagPanel.Position = UDim2.new(0.5, -230, 0.5, 5)
DiagPanel.BackgroundColor3 = Color3.fromRGB(22, 27, 34)
DiagPanel.BorderSizePixel = 0
DiagPanel.ZIndex = 4
DiagPanel.Parent = ScreenGui
ApplyRadius(DiagPanel, 6)

local DiagHeader = Instance.new("TextLabel")
DiagHeader.Size = UDim2.new(1, -20, 0, 25)
DiagHeader.Position = UDim2.new(0, 15, 0, 8)
DiagHeader.BackgroundTransparency = 1
DiagHeader.Text = "📄 README.md"
DiagHeader.TextColor3 = Color3.fromRGB(201, 209, 217)
DiagHeader.Font = Enum.Font.Code
DiagHeader.TextSize = 13
DiagHeader.TextXAlignment = Enum.TextXAlignment.Left
DiagHeader.ZIndex = 5
DiagHeader.Parent = DiagPanel

local DiagMacroLabel = Instance.new("TextLabel")
DiagMacroLabel.Size = UDim2.new(1, -30, 0, 20)
DiagMacroLabel.Position = UDim2.new(0, 15, 0, 35)
DiagMacroLabel.BackgroundTransparency = 1
DiagMacroLabel.Text = "● Engine Status: Standing By"
DiagMacroLabel.TextColor3 = Color3.fromRGB(139, 148, 158)
DiagMacroLabel.Font = Enum.Font.SourceSans
DiagMacroLabel.TextSize = 13
DiagMacroLabel.TextXAlignment = Enum.TextXAlignment.Left
DiagMacroLabel.ZIndex = 5
DiagMacroLabel.Parent = DiagPanel

local DiagKeyLabel = Instance.new("TextLabel")
DiagKeyLabel.Size = UDim2.new(1, -30, 0, 20)
DiagKeyLabel.Position = UDim2.new(0, 15, 0, 55)
DiagKeyLabel.BackgroundTransparency = 1
DiagKeyLabel.Text = "● Target Register Bind: [F]"
DiagKeyLabel.TextColor3 = Color3.fromRGB(139, 148, 158)
DiagKeyLabel.Font = Enum.Font.SourceSans
DiagKeyLabel.TextSize = 13
DiagKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
DiagKeyLabel.ZIndex = 5
DiagKeyLabel.Parent = DiagPanel

local DiagParryLabel = Instance.new("TextLabel")
DiagParryLabel.Size = UDim2.new(1, -30, 0, 20)
DiagParryLabel.Position = UDim2.new(0, 15, 0, 75)
DiagParryLabel.BackgroundTransparency = 1
DiagParryLabel.Text = "● Defensive Matrix: Disengaged"
DiagParryLabel.TextColor3 = Color3.fromRGB(139, 148, 158)
DiagParryLabel.Font = Enum.Font.SourceSans
DiagParryLabel.TextSize = 13
DiagParryLabel.TextXAlignment = Enum.TextXAlignment.Left
DiagParryLabel.ZIndex = 5
DiagParryLabel.Parent = DiagPanel


-- =============================================================================
-- PANEL MODULE 2: COMPACT CONTROLLER POD (GITHUB ACTIONS STYLE)
-- =============================================================================
local ControlPod = Instance.new("Frame")
ControlPod.Name = "ControlPod"
ControlPod.Size = UDim2.new(0, 260, 0, 75)
ControlPod.Position = UDim2.new(0.5, -130, 0.5, 160)
ControlPod.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
ControlPod.BorderSizePixel = 0
ControlPod.Active = true
ControlPod.Draggable = true
ControlPod.Parent = ScreenGui
ApplyRadius(ControlPod, 8)

-- Compact Operational Toggle Button
local ActionButton = Instance.new("TextButton")
ActionButton.Name = "ActionButton"
ActionButton.Size = UDim2.new(0, 230, 0, 36)
ActionButton.Position = UDim2.new(0.5, -115, 0.5, 175)
ActionButton.BackgroundColor3 = Color3.fromRGB(35, 134, 54)
ActionButton.BorderSizePixel = 0
ActionButton.Text = "▶ Run Action"
ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionButton.Font = Enum.Font.SourceSansBold
ActionButton.TextSize = 14
ActionButton.AutoButtonColor = false
ActionButton.ZIndex = 5
ActionButton.Parent = ScreenGui
ApplyRadius(ActionButton, 6)

-- Standalone Operation Status Readout Line Footer
local StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(0, 230, 0, 18)
StatusBar.Position = UDim2.new(0.5, -115, 0.5, 213)
StatusBar.BackgroundTransparency = 1
StatusBar.Text = "Status: Workflow Idle"
StatusBar.TextColor3 = Color3.fromRGB(139, 148, 158)
StatusBar.Font = Enum.Font.SourceSans
StatusBar.TextSize = 11
StatusBar.ZIndex = 5
StatusBar.Parent = ScreenGui


-- -----------------------------------------------------------------------------
-- RUNTIME UI HANDLER LOGIC
-- -----------------------------------------------------------------------------
local function UpdateUI()
    local labelMode = EngineState.ModeSelection == "KPS" and "KPS" or "CPS"
    SpeedDisplay.Text = string.format("%d %s", EngineState.TargetSpeed, labelMode)
    
    if EngineState.IsRunning then
        StatusBar.Text = "Status: Action Active"
        StatusBar.TextColor3 = Color3.fromRGB(46, 160, 67)
        ActionButton.Text = "■ Stop Action"
        ActionButton.BackgroundColor3 = Color3.fromRGB(248, 81, 73)
        DiagMacroLabel.Text = "● Engine Status: Running Core Tasks"
        DiagMacroLabel.TextColor3 = Color3.fromRGB(46, 160, 67)
    else
        StatusBar.Text = "Status: Workflow Idle"
        StatusBar.TextColor3 = Color3.fromRGB(139, 148, 158)
        ActionButton.Text = "▶ Run Action"
        ActionButton.BackgroundColor3 = Color3.fromRGB(35, 134, 54)
        DiagMacroLabel.Text = "● Engine Status: Standing By"
        DiagMacroLabel.TextColor3 = Color3.fromRGB(139, 148, 158)
    end
end

-- Slider Axis Tracking Mechanics
local IsDragging = false

local function UpdateSlider(inputObj)
    local fraction = math.clamp((inputObj.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
    local maxLimit = EngineState.LowEndMode and 200 or 1000
    local calculated = math.round(1 + (fraction * (maxLimit - 1)))
    
    EngineState.TargetSpeed = calculated
    SliderFill.Size = UDim2.new(fraction, 0, 1, 0)
    SliderButton.Position = UDim2.new(fraction, -7, 0.5, -7)
    UpdateUI()
end

SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsDragging = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateSlider(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if IsDragging then
            IsDragging = false
        end
    end
end)

-- Structural Chassis Matrix Pinning Tracking
local function BindChassisPosition(chassisFrame, elementList)
    local offsets = {}
    for _, el in ipairs(elementList) do
        offsets[el] = el.Position - chassisFrame.Position
    end
    
    chassisFrame:GetPropertyChangedSignal("Position"):Connect(function()
        for el, originalOffset in pairs(offsets) do
            el.Position = chassisFrame.Position + originalOffset
        end
    end)
end

BindChassisPosition(MainFrame, {TitleLabel, ModeBtn, GuardBtn, SliderTrack, SpeedDisplay, ParryBtn, DiagPanel})
BindChassisPosition(ControlPod, {ActionButton, StatusBar})

-- 6. KEYBOARD VISIBILITY INPUT BIND (RIGHT SHIFT)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        EngineState.ConfigVisible = not EngineState.ConfigVisible
        
        MainFrame.Visible = EngineState.ConfigVisible
        TitleLabel.Visible = EngineState.ConfigVisible
        ModeBtn.Visible = EngineState.ConfigVisible
        GuardBtn.Visible = EngineState.ConfigVisible
        SliderTrack.Visible = EngineState.ConfigVisible
        SpeedDisplay.Visible = EngineState.ConfigVisible
        ParryBtn.Visible = EngineState.ConfigVisible
        DiagPanel.Visible = EngineState.ConfigVisible
    end
end)

-- Mapping Interactive Connections
ActionButton.MouseButton1Click:Connect(function()
    if not EngineState.IsRunning then
        StartLoop()
    else
        StopLoop()
    end
    UpdateUI()
end)

ModeBtn.MouseButton1Click:Connect(function()
    EngineState.ModeSelection = EngineState.ModeSelection == "KPS" and "CPS" or "KPS"
    ModeBtn.Text = EngineState.ModeSelection == "KPS" and "⚙️ Mode: Keyboard (KPS)" or "⚙️ Mode: Mouse (CPS)"
    UpdateUI()
end)

GuardBtn.MouseButton1Click:Connect(function()
    EngineState.LowEndMode = not EngineState.LowEndMode
    if EngineState.LowEndMode then
        GuardBtn.Text = "🛡️ Profile: Low-End"
        if EngineState.TargetSpeed > 200 then EngineState.TargetSpeed = 200 end
    else
        GuardBtn.Text = "🛡️ Profile: Uncapped"
    end
    
    local maxLimit = EngineState.LowEndMode and 200 or 1000
    local scale = math.clamp((EngineState.TargetSpeed - 1) / (maxLimit - 1), 0, 1)
    SliderFill.Size = UDim2.new(scale, 0, 1, 0)
    SliderButton.Position = UDim2.new(scale, -7, 0.5, -7)
    
    UpdateUI()
end)

ParryBtn.MouseButton1Click:Connect(function()
    EngineState.AutoParryActive = not EngineState.AutoParryActive
    if EngineState.AutoParryActive then
        ParryBtn.Text = "⚔️ Auto Parry: Active"
        ParryBtn.TextColor3 = Color3.fromRGB(46, 160, 67)
        DiagParryLabel.Text = "● Defensive Matrix: Connected"
        DiagParryLabel.TextColor3 = Color3.fromRGB(46, 160, 67)
        StartParryTracking()
    else
        ParryBtn.Text = "⚔️ Auto Parry: Disabled"
        ParryBtn.TextColor3 = Color3.fromRGB(248, 81, 73)
        DiagParryLabel.Text = "● Defensive Matrix: Disengaged"
        DiagParryLabel.TextColor3 = Color3.fromRGB(139, 148, 158)
        StopParryTracking()
    end
end)

UpdateUI()
