-- =============================================================================
-- THYREN DECOUPLED REPOSITORY DASHBOARD (BLAZE MACRO EDITION / HIDING ACTION BUTTON)
-- TARGET: Roblox Executor Environment (Ultra-Accurate Asynchronous Spammer)
-- LAYOUT: Deep Obsidian & Neon Green Aesthetics // Blade Precision Geometry
-- TOGGLE: Press RIGHT SHIFT to toggle the settings panel while keeping workspace clean
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

-- 3. GLOBAL UNIFIED SYSTEM STATE CONFIGURATION
local EngineState = {
    IsRunning = false,
    TargetSpeed = 10,
    ModeSelection = "KPS",
    LowEndMode = false,
    ActivationMode = "Manual Spam", 
    RuntimeHotkey = nil,            
    IsBinding = false,
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

local function RunSpamThread()
    while EngineState.IsRunning do
        if EngineState.TargetSpeed >= 60 then
            fireInput()
            RunService.Heartbeat:Wait()
        else
            local delayInterval = 1.0 / EngineState.TargetSpeed
            fireInput()
            if delayInterval > 0 then
                task.wait(delayInterval)
            else
                task.wait()
            end
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

local function ToggleEngine()
    if not EngineState.IsRunning then
        StartLoop()
    else
        StopLoop()
    end
end

-- 5. DEDICATED BLADE BALL TARGET MATCHING ENGINE WITH SINGLE-HIT DEBOUNCE
local function FindActiveBall()
    local BallFolder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")
    
    if BallFolder then
        for _, ball in ipairs(BallFolder:GetChildren()) do
            if ball:IsA("BasePart") or ball:FindFirstChildOfClass("BasePart") then
                local realPart = ball:IsA("BasePart") and ball or ball:FindFirstChildOfClass("BasePart")
                local currentTarget = ball:GetAttribute("target") or ball:GetAttribute("Target")
                
                if currentTarget == LocalPlayer.Name then
                    return realPart
                end
            end
        end
    end
    
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "Ball" and obj:IsA("BasePart") then
            if obj:GetAttribute("target") == LocalPlayer.Name then
                return obj
            end
        end
    end
    
    return nil
end

local LastParriedBall = nil

local function StartParryTracking()
    if EngineState.ParryConnection then EngineState.ParryConnection:Disconnect() end
    
    EngineState.ParryConnection = RunService.PreSimulation:Connect(function()
        if not EngineState.AutoParryActive then return end
        
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local ball = FindActiveBall()
        if ball then
            if LastParriedBall ~= ball then
                LastParriedBall = ball
                ball:SetAttribute("HasBeenParriedByMe", false)
            end
            
            if ball:GetAttribute("HasBeenParriedByMe") == true then 
                return 
            end
            
            local distance = (ball.Position - rootPart.Position).Magnitude
            local ballVelocity = ball.AssemblyLinearVelocity.Magnitude
            local dynamicTriggerRange = EngineState.ParryThreshold + (ballVelocity * 0.12)
            
            if distance <= dynamicTriggerRange then
                ball:SetAttribute("HasBeenParriedByMe", true)
                fireInput()
            end
        else
            LastParriedBall = nil
        end
    end)
end

local function StopParryTracking()
    if EngineState.ParryConnection then
        EngineState.ParryConnection:Disconnect()
        EngineState.ParryConnection = nil
    end
    LastParriedBall = nil
end

-- -----------------------------------------------------------------------------
-- GLOBAL ROOT SCREEN CONTAINER
-- -----------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = uiName
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = TargetParent

local ConfigCanvas = Instance.new("Frame")
ConfigCanvas.Name = "ConfigCanvas"
ConfigCanvas.Size = UDim2.new(1, 0, 1, 0)
ConfigCanvas.BackgroundTransparency = 1
ConfigCanvas.Visible = true
ConfigCanvas.Parent = ScreenGui

local function ApplyRadius(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

-- =============================================================================
-- PANEL MODULE 1: MAIN BLAZE DASHBOARD (GREEN MATRIX ACCENTS)
-- =============================================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 360)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 10, 6) 
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ConfigCanvas
ApplyRadius(MainFrame, 8)

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 200, 90)
UIStroke.Thickness = 1
UIStroke.Transparency = 0.4
UIStroke.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 460, 0, 40)
TitleLabel.Position = UDim2.new(0.5, -230, 0.5, -200)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ ｂｌａｚｅ － ｍａｃｒｏ ／ ｃｏｒｅ v2.0"
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 120) 
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 5
TitleLabel.Parent = ConfigCanvas

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 215, 0, 42)
ModeBtn.Position = UDim2.new(0.5, -230, 0.5, -150)
ModeBtn.BackgroundColor3 = Color3.fromRGB(10, 24, 13) 
ModeBtn.BorderSizePixel = 0
ModeBtn.Text = "⚙️ Mode: Keyboard (KPS)"
ModeBtn.TextColor3 = Color3.fromRGB(200, 255, 210)
ModeBtn.Font = Enum.Font.SourceSansBold
ModeBtn.TextSize = 13
ModeBtn.ZIndex = 5
ModeBtn.Parent = ConfigCanvas
ApplyRadius(ModeBtn, 4)

local ModeStroke = Instance.new("UIStroke")
ModeStroke.Color = Color3.fromRGB(0, 150, 70)
ModeStroke.Thickness = 1
ModeStroke.Parent = ModeBtn

-- Click-To-Bind Toggle Mode Switcher Button
local ControlModeBtn = Instance.new("TextButton")
ControlModeBtn.Size = UDim2.new(0, 215, 0, 42)
ControlModeBtn.Position = UDim2.new(0.5, 15, 0.5, -150)
ControlModeBtn.BackgroundColor3 = Color3.fromRGB(10, 24, 13)
ControlModeBtn.BorderSizePixel = 0
ControlModeBtn.Text = "🕹️ Trigger: [ Click to Bind ]"
ControlModeBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
ControlModeBtn.Font = Enum.Font.SourceSansBold
ControlModeBtn.TextSize = 13
ControlModeBtn.ZIndex = 5
ControlModeBtn.Parent = ConfigCanvas
ApplyRadius(ControlModeBtn, 4)

local ControlStroke = Instance.new("UIStroke")
ControlStroke.Color = Color3.fromRGB(0, 150, 70)
ControlStroke.Thickness = 1
ControlStroke.Parent = ControlModeBtn

local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(0, 340, 0, 6)
SliderTrack.Position = UDim2.new(0.5, -230, 0.5, -85)
SliderTrack.BackgroundColor3 = Color3.fromRGB(15, 40, 20) 
SliderTrack.BorderSizePixel = 0
SliderTrack.ZIndex = 5
SliderTrack.Parent = ConfigCanvas
ApplyRadius(SliderTrack, 3)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.01, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 120) 
SliderFill.BorderSizePixel = 0
SliderFill.ZIndex = 6
SliderFill.Parent = SliderTrack
ApplyRadius(SliderFill, 3)

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 14, 0, 14)
SliderButton.Position = UDim2.new(0.01, -7, 0.5, -7)
SliderButton.BackgroundColor3 = Color3.fromRGB(100, 255, 160)
SliderButton.BorderSizePixel = 0
SliderButton.Text = ""
SliderButton.ZIndex = 7
SliderButton.Parent = SliderTrack
ApplyRadius(SliderButton, 7)

local SpeedDisplay = Instance.new("TextLabel")
SpeedDisplay.Size = UDim2.new(0, 100, 0, 30)
SpeedDisplay.Position = UDim2.new(0.5, 130, 0.5, -97)
SpeedDisplay.BackgroundTransparency = 1
SpeedDisplay.Text = "10 KPS"
SpeedDisplay.TextColor3 = Color3.fromRGB(0, 255, 120)
SpeedDisplay.Font = Enum.Font.Code
SpeedDisplay.TextSize = 14
SpeedDisplay.TextXAlignment = Enum.TextXAlignment.Right
SpeedDisplay.ZIndex = 5
SpeedDisplay.Parent = ConfigCanvas

local ParryBtn = Instance.new("TextButton")
ParryBtn.Size = UDim2.new(0, 460, 0, 40)
ParryBtn.Position = UDim2.new(0.5, -230, 0.5, -55)
ParryBtn.BackgroundColor3 = Color3.fromRGB(10, 24, 13)
ParryBtn.BorderSizePixel = 0
ParryBtn.Text = "⚔️ Auto Parry: Disabled"
ParryBtn.TextColor3 = Color3.fromRGB(0, 150, 70)
ParryBtn.Font = Enum.Font.SourceSansBold
ParryBtn.TextSize = 14
ParryBtn.ZIndex = 5
ParryBtn.Parent = ConfigCanvas
ApplyRadius(ParryBtn, 4)

local ParryStroke = Instance.new("UIStroke")
ParryStroke.Color = Color3.fromRGB(0, 150, 70)
ParryStroke.Thickness = 1
ParryStroke.Parent = ParryBtn

local DiagPanel = Instance.new("Frame")
DiagPanel.Name = "DiagPanel"
DiagPanel.Size = UDim2.new(0, 460, 0, 110)
DiagPanel.Position = UDim2.new(0.5, -230, 0.5, 5)
DiagPanel.BackgroundColor3 = Color3.fromRGB(6, 14, 8)
DiagPanel.BorderSizePixel = 0
DiagPanel.ZIndex = 4
DiagPanel.Parent = ConfigCanvas
ApplyRadius(DiagPanel, 4)

local DiagStroke = Instance.new("UIStroke")
DiagStroke.Color = Color3.fromRGB(0, 100, 50)
DiagStroke.Thickness = 1
DiagStroke.Parent = DiagPanel

local DiagHeader = Instance.new("TextLabel")
DiagHeader.Size = UDim2.new(1, -20, 0, 25)
DiagHeader.Position = UDim2.new(0, 15, 0, 8)
DiagHeader.BackgroundTransparency = 1
DiagHeader.Text = "📄 CONSOLE_LOG.txt"
DiagHeader.TextColor3 = Color3.fromRGB(150, 255, 180)
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
DiagMacroLabel.TextColor3 = Color3.fromRGB(100, 140, 110)
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
DiagKeyLabel.TextColor3 = Color3.fromRGB(100, 140, 110)
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
DiagParryLabel.TextColor3 = Color3.fromRGB(100, 140, 110)
DiagParryLabel.Font = Enum.Font.SourceSans
DiagParryLabel.TextSize = 13
DiagParryLabel.TextXAlignment = Enum.TextXAlignment.Left
DiagParryLabel.ZIndex = 5
DiagParryLabel.Parent = DiagPanel

-- =============================================================================
-- PANEL MODULE 2: COMPACT CONTROLLER POD (OUTSIDE THE TOGGLE CANVAS)
-- =============================================================================
local ControlPod = Instance.new("Frame")
ControlPod.Name = "ControlPod"
ControlPod.Size = UDim2.new(0, 260, 0, 75)
ControlPod.Position = UDim2.new(0.5, -130, 0.5, 160)
ControlPod.BackgroundColor3 = Color3.fromRGB(5, 10, 6)
ControlPod.BorderSizePixel = 0
ControlPod.Active = true
ControlPod.Draggable = true
ControlPod.Parent = ScreenGui 
ApplyRadius(ControlPod, 6)

local PodStroke = Instance.new("UIStroke")
PodStroke.Color = Color3.fromRGB(0, 200, 90)
PodStroke.Thickness = 1
PodStroke.Transparency = 0.4
PodStroke.Parent = ControlPod

local ActionButton = Instance.new("TextButton")
ActionButton.Name = "ActionButton"
ActionButton.Size = UDim2.new(0, 230, 0, 36)
ActionButton.Position = UDim2.new(0.5, -115, 0.5, 175)
ActionButton.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
ActionButton.BorderSizePixel = 0
ActionButton.Text = "▶ Run Macro"
ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ActionButton.Font = Enum.Font.SourceSansBold
ActionButton.TextSize = 14
ActionButton.AutoButtonColor = false
ActionButton.ZIndex = 5
ActionButton.Parent = ScreenGui 
ApplyRadius(ActionButton, 4)

local StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(0, 230, 0, 18)
StatusBar.Position = UDim2.new(0.5, -115, 0.5, 213)
StatusBar.BackgroundTransparency = 1
StatusBar.Text = "Status: Workflow Idle"
StatusBar.TextColor3 = Color3.fromRGB(100, 140, 110)
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
    
    -- FORCE THE ENTIRE MANUAL INTERACTION POD STACK TO DISAPPEAR/REAPPEAR
    if EngineState.ActivationMode == "Manual Spam" then
        ControlPod.Visible = true
        ActionButton.Visible = true
        StatusBar.Visible = true
    else
        ControlPod.Visible = false
        ActionButton.Visible = false
        StatusBar.Visible = false
    end
    
    if EngineState.IsRunning then
        StatusBar.Text = "Status: Macro Firing"
        StatusBar.TextColor3 = Color3.fromRGB(0, 255, 120)
        ActionButton.Text = "■ Stop Macro"
        ActionButton.BackgroundColor3 = Color3.fromRGB(150, 10, 30) 
        DiagMacroLabel.Text = "● Engine Status: Running Core Tasks"
        DiagMacroLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
    else
        StatusBar.Text = "Status: Workflow Idle"
        StatusBar.TextColor3 = Color3.fromRGB(100, 140, 110)
        ActionButton.Text = "▶ Run Macro"
        ActionButton.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        DiagMacroLabel.Text = "● Engine Status: Standing By"
        DiagMacroLabel.TextColor3 = Color3.fromRGB(100, 140, 110)
    end
end

local IsDragging = false

local function UpdateSlider(inputObj)
    local fraction = math.clamp((inputObj.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
    local maxLimit = EngineState.LowEndMode and 200 or 2500
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

BindChassisPosition(MainFrame, {TitleLabel, ModeBtn, ControlModeBtn, SliderTrack, SpeedDisplay, ParryBtn, DiagPanel})
BindChassisPosition(ControlPod, {ActionButton, StatusBar})

-- 6. KEYBOARD GLOBAL INTERCEPT LISTENER
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if EngineState.IsBinding then
        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.RightShift then
            EngineState.RuntimeHotkey = input.KeyCode
            EngineState.ActivationMode = "Hotkey (" .. input.KeyCode.Name .. ")"
            EngineState.IsBinding = false
            ControlModeBtn.Text = "🕹️ Trigger: " .. EngineState.ActivationMode
            ControlModeBtn.TextColor3 = Color3.fromRGB(200, 255, 210)
            UpdateUI()
        end
        return
    end

    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        EngineState.ConfigVisible = not EngineState.ConfigVisible
        ConfigCanvas.Visible = EngineState.ConfigVisible
    end
    
    if EngineState.RuntimeHotkey and input.KeyCode == EngineState.RuntimeHotkey then
        ToggleEngine()
        UpdateUI()
    end
end)

-- GUI Execution Intercept
ActionButton.MouseButton1Click:Connect(function()
    ToggleEngine()
    UpdateUI()
end)

ModeBtn.MouseButton1Click:Connect(function()
    EngineState.ModeSelection = EngineState.ModeSelection == "KPS" and "CPS" or "KPS"
    ModeBtn.Text = EngineState.ModeSelection == "KPS" and "⚙️ Mode: Keyboard (KPS)" or "⚙️ Mode: Mouse (CPS)"
    UpdateUI()
end)

-- Click-To-Bind State Switching Loop Logic
ControlModeBtn.MouseButton1Click:Connect(function()
    if EngineState.ActivationMode == "Manual Spam" then
        EngineState.IsBinding = true
        ControlModeBtn.Text = "🕹️ Press any key..."
        ControlModeBtn.TextColor3 = Color3.fromRGB(255, 255, 100)
        
        -- Hide the manual trigger buttons right as the key capture starts
        ControlPod.Visible = false
        ActionButton.Visible = false
        StatusBar.Visible = false
    else
        EngineState.ActivationMode = "Manual Spam"
        EngineState.RuntimeHotkey = nil
        EngineState.IsBinding = false
        ControlModeBtn.Text = "🕹️ Trigger: Manual Spam"
        ControlModeBtn.TextColor3 = Color3.fromRGB(200, 255, 210)
        UpdateUI()
    end
end)

getgenv().ThyrenLowEndMode = function()
    EngineState.LowEndMode = not EngineState.LowEndMode
    if EngineState.LowEndMode and EngineState.TargetSpeed > 200 then 
        EngineState.TargetSpeed = 200 
    end
    local maxLimit = EngineState.LowEndMode and 200 or 2500
    local scale = math.clamp((EngineState.TargetSpeed - 1) / (maxLimit - 1), 0, 1)
    SliderFill.Size = UDim2.new(scale, 0, 1, 0)
    SliderButton.Position = UDim2.new(scale, -7, 0.5, -7)
    UpdateUI()
end

ParryBtn.MouseButton1Click:Connect(function()
    EngineState.AutoParryActive = not EngineState.AutoParryActive
    if EngineState.AutoParryActive then
        ParryBtn.Text = "⚔️ Auto Parry: Active"
        ParryBtn.TextColor3 = Color3.fromRGB(0, 255, 120)
        DiagParryLabel.Text = "● Defensive Matrix: Connected"
        DiagParryLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        StartParryTracking()
    else
        ParryBtn.Text = "⚔️ Auto Parry: Disabled"
        ParryBtn.TextColor3 = Color3.fromRGB(0, 150, 70)
        DiagParryLabel.Text = "● Defensive Matrix: Disengaged"
        DiagParryLabel.TextColor3 = Color3.fromRGB(100, 140, 110)
        StopParryTracking()
    end
end)

UpdateUI()
