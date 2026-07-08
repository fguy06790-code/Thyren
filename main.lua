-- =============================================================================
-- THYREN REPOSITORY DASHBOARD (COLLAPSIBLE LOGO MODULE)
-- TARGET: Roblox Executor Environment (Zero-Allocation Micro-Loops)
-- THEME: Slate & Graphite (Minimalist Gray)
-- =============================================================================

local uiName = "ThyrenUI"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- 1. PURGE PREVIOUS INSTANCES
pcall(function() local oldUI = CoreGui:FindFirstChild(uiName) if oldUI then oldUI:Destroy() end end)
pcall(function() if LocalPlayer then local pGui = LocalPlayer:FindFirstChild("PlayerGui") local oldUI = pGui and pGui:FindFirstChild(uiName) if oldUI then oldUI:Destroy() end end end)

-- 2. ALLOCATE SECURE STORAGE
local TargetParent = nil
local successCore = pcall(function() local test = Instance.new("Folder"); test.Parent = CoreGui; test:Destroy(); TargetParent = CoreGui end)
if not successCore or not TargetParent then TargetParent = LocalPlayer:WaitForChild("PlayerGui") end

-- 3. UNIFIED CONFIGURATION STATE
local EngineState = { IsRunning = false, TargetSpeed = 10, ModeSelection = "KPS", LowEndMode = false, ActivationMode = "Manual Spam", RuntimeHotkey = nil, IsBinding = false, AutoParryActive = false, ParryThreshold = 45, SpamKey = Enum.KeyCode.F, ParryConnection = nil, ConfigVisible = true, Collapsed = false }

local sendKeyEvent = VirtualInputManager.SendKeyEvent
local sendMouseButtonEvent = VirtualInputManager.SendMouseButtonEvent
local getMouseLocation = UserInputService.GetMouseLocation
local osClock = os.clock
local clamp = math.clamp
local round = math.round
local ipairs = ipairs

local MacroConnection = nil
local lastFireTime = 0

-- 4. OPTIMIZED STEPPING PIPELINE
local function RunSpamIteration()
    if not EngineState.IsRunning then return end
    local targetSpeed = EngineState.TargetSpeed; local currentMode = EngineState.ModeSelection; local spamKey = EngineState.SpamKey
    if targetSpeed >= 60 then
        if currentMode == "KPS" then sendKeyEvent(VirtualInputManager, true, spamKey, false, game); sendKeyEvent(VirtualInputManager, false, spamKey, false, game); sendKeyEvent(VirtualInputManager, true, spamKey, false, game); sendKeyEvent(VirtualInputManager, false, spamKey, false, game)
        else local mousePos = getMouseLocation(UserInputService); local mx, my = mousePos.X, mousePos.Y; sendMouseButtonEvent(VirtualInputManager, mx, my, 0, true, game, 0); sendMouseButtonEvent(VirtualInputManager, mx, my, 0, false, game, 0); sendMouseButtonEvent(VirtualInputManager, mx, my, 0, true, game, 0); sendMouseButtonEvent(VirtualInputManager, mx, my, 0, false, game, 0) end
    else local currentTime = osClock() if (currentTime - lastFireTime) >= (1.0 / targetSpeed) then lastFireTime = currentTime; if currentMode == "KPS" then sendKeyEvent(VirtualInputManager, true, spamKey, false, game); sendKeyEvent(VirtualInputManager, false, spamKey, false, game) else local mousePos = getMouseLocation(UserInputService); sendMouseButtonEvent(VirtualInputManager, mousePos.X, mousePos.Y, 0, true, game, 0); sendMouseButtonEvent(VirtualInputManager, mousePos.X, mousePos.Y, 0, false, game, 0) end end end
end

local function StartLoop() EngineState.IsRunning = true; lastFireTime = osClock(); if MacroConnection then MacroConnection:Disconnect() end; MacroConnection = RunService.PreRender:Connect(RunSpamIteration) end
local function StopLoop() EngineState.IsRunning = false; if MacroConnection then MacroConnection:Disconnect(); MacroConnection = nil end end
local function ToggleEngine() if EngineState.IsRunning then StopLoop() else StartLoop() end end

-- 5. CACHED TARGETING SCANNER
local function FindActiveBall()
    local BallFolder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")
    if BallFolder then for i = 1, #BallFolder:GetChildren() do local ball = BallFolder:GetChildren()[i]; if ball:IsA("BasePart") or ball:FindFirstChildOfClass("BasePart") then local realPart = ball:IsA("BasePart") and ball or ball:FindFirstChildOfClass("BasePart"); local targetAttr = ball:GetAttribute("target") or ball:GetAttribute("Target"); if targetAttr == LocalPlayer.Name then return realPart end end end end
    for i = 1, #workspace:GetChildren() do local obj = workspace:GetChildren()[i]; if obj.Name == "Ball" and obj:IsA("BasePart") and obj:GetAttribute("target") == LocalPlayer.Name then return obj end end
    return nil
end

local function StartParryTracking()
    if EngineState.ParryConnection then EngineState.ParryConnection:Disconnect() end
    EngineState.ParryConnection = RunService.PreSimulation:Connect(function()
        if not EngineState.AutoParryActive then return end
        local character = LocalPlayer.Character; local rootPart = character and character:FindFirstChild("HumanoidRootPart"); if not rootPart then return end
        local ball = FindActiveBall()
        if ball then local distance = (ball.Position - rootPart.Position).Magnitude; local ballVelocity = ball.AssemblyLinearVelocity.Magnitude; local dynamicTriggerRange = EngineState.ParryThreshold + (ballVelocity * 0.12)
            if distance <= dynamicTriggerRange then if EngineState.ModeSelection == "KPS" then sendKeyEvent(VirtualInputManager, true, EngineState.SpamKey, false, game); sendKeyEvent(VirtualInputManager, false, EngineState.SpamKey, false, game) else local mousePos = getMouseLocation(UserInputService); sendMouseButtonEvent(VirtualInputManager, mousePos.X, mousePos.Y, 0, true, game, 0); sendMouseButtonEvent(VirtualInputManager, mousePos.X, mousePos.Y, 0, false, game, 0) end end
        end
    end)
end

local function StopParryTracking() if EngineState.ParryConnection then EngineState.ParryConnection:Disconnect(); EngineState.ParryConnection = nil end end

-- 6. INTERFACE ENVIRONMENT ARCHITECTURE (THYREN GRAY THEME)
local ScreenGui = Instance.new("ScreenGui", TargetParent); ScreenGui.Name = uiName; ScreenGui.ResetOnSpawn = false
local ConfigCanvas = Instance.new("Frame", ScreenGui); ConfigCanvas.Name = "ConfigCanvas"; ConfigCanvas.Size = UDim2.new(1, 0, 1, 0); ConfigCanvas.BackgroundTransparency = 1

local function ApplyRadius(instance, radius) local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius); corner.Parent = instance; return corner end

local MainFrame = Instance.new("Frame", ConfigCanvas); MainFrame.Name = "MainFrame"; MainFrame.Size = UDim2.new(0, 500, 0, 360); MainFrame.Position = UDim2.new(0.5, -250, 0.5, -210); MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); MainFrame.Active = true; MainFrame.Draggable = true; ApplyRadius(MainFrame, 8)
local UIStroke = Instance.new("UIStroke", MainFrame); UIStroke.Color = Color3.fromRGB(160, 160, 160); UIStroke.Thickness = 1; UIStroke.Transparency = 0.3

-- [UI ELEMENTS]
local TitleLabel = Instance.new("TextButton", ConfigCanvas); TitleLabel.Name = "LogoButton"; TitleLabel.Size = UDim2.new(0, 160, 0, 40); TitleLabel.Position = UDim2.new(0.5, -230, 0.5, -200); TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = "THYREN"; TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200); TitleLabel.Font = Enum.Font.Michroma; TitleLabel.TextSize = 16; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.ZIndex = 5

local ModeBtn = Instance.new("TextButton", ConfigCanvas); ModeBtn.Size = UDim2.new(0, 215, 0, 42); ModeBtn.Position = UDim2.new(0.5, -230, 0.5, -150); ModeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); ModeBtn.Text = "MODE: KPS"; ModeBtn.TextColor3 = Color3.fromRGB(230, 230, 230); ModeBtn.Font = Enum.Font.Michroma; ModeBtn.ZIndex = 5; ApplyRadius(ModeBtn, 4)
local ModeStroke = Instance.new("UIStroke", ModeBtn); ModeStroke.Color = Color3.fromRGB(120, 120, 120); ModeStroke.Thickness = 1

local SwitchContainer = Instance.new("Frame", ConfigCanvas); SwitchContainer.Size = UDim2.new(0, 215, 0, 42); SwitchContainer.Position = UDim2.new(0.5, 15, 0.5, -150); SwitchContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 50); SwitchContainer.ZIndex = 5; ApplyRadius(SwitchContainer, 4)
local SwitchStroke = Instance.new("UIStroke", SwitchContainer); SwitchStroke.Color = Color3.fromRGB(120, 120, 120); SwitchStroke.Thickness = 1
local SwitchLabel = Instance.new("TextLabel", SwitchContainer); SwitchLabel.Size = UDim2.new(0, 140, 1, 0); SwitchLabel.Position = UDim2.new(0, 12, 0, 0); SwitchLabel.BackgroundTransparency = 1; SwitchLabel.Text = "KEYBIND"; SwitchLabel.TextColor3 = Color3.fromRGB(230, 230, 230); SwitchLabel.Font = Enum.Font.Michroma; SwitchLabel.ZIndex = 6
local ToggleTrack = Instance.new("TextButton", SwitchContainer); ToggleTrack.Size = UDim2.new(0, 46, 0, 26); ToggleTrack.Position = UDim2.new(1, -56, 0.5, -13); ToggleTrack.BackgroundColor3 = Color3.fromRGB(65, 65, 65); ToggleTrack.Text = ""; ToggleTrack.ZIndex = 6; ApplyRadius(ToggleTrack, 13)
local ToggleThumb = Instance.new("Frame", ToggleTrack); ToggleThumb.Size = UDim2.new(0, 22, 0, 22); ToggleThumb.Position = UDim2.new(0, 2, 0.5, -11); ToggleThumb.BackgroundColor3 = Color3.fromRGB(230, 230, 230); ToggleThumb.ZIndex = 7; ApplyRadius(ToggleThumb, 11)

local SliderTrack = Instance.new("Frame", ConfigCanvas); SliderTrack.Size = UDim2.new(0, 340, 0, 6); SliderTrack.Position = UDim2.new(0.5, -230, 0.5, -85); SliderTrack.BackgroundColor3 = Color3.fromRGB(70, 70, 70); SliderTrack.ZIndex = 5; ApplyRadius(SliderTrack, 3)
local SliderFill = Instance.new("Frame", SliderTrack); SliderFill.Size = UDim2.new(0.01, 0, 1, 0); SliderFill.BackgroundColor3 = Color3.fromRGB(160, 160, 160); SliderFill.ZIndex = 6; ApplyRadius(SliderFill, 3)
local SliderButton = Instance.new("TextButton", SliderTrack); SliderButton.Size = UDim2.new(0, 14, 0, 14); SliderButton.Position = UDim2.new(0.01, -7, 0.5, -7); SliderButton.BackgroundColor3 = Color3.fromRGB(180, 180, 180); SliderButton.Text = ""; SliderButton.ZIndex = 7; ApplyRadius(SliderButton, 7)
local SpeedDisplay = Instance.new("TextLabel", ConfigCanvas); SpeedDisplay.Size = UDim2.new(0, 120, 0, 30); SpeedDisplay.Position = UDim2.new(0.5, 110, 0.5, -97); SpeedDisplay.BackgroundTransparency = 1; SpeedDisplay.Text = "10 KPS"; SpeedDisplay.TextColor3 = Color3.fromRGB(160, 160, 160); SpeedDisplay.Font = Enum.Font.Michroma; SpeedDisplay.TextSize = 14; SpeedDisplay.ZIndex = 5

local ParryBtn = Instance.new("TextButton", ConfigCanvas); ParryBtn.Size = UDim2.new(0, 460, 0, 40); ParryBtn.Position = UDim2.new(0.5, -230, 0.5, -55); ParryBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); ParryBtn.Text = "AUTO PARRY: DISABLED"; ParryBtn.TextColor3 = Color3.fromRGB(120, 120, 120); ParryBtn.Font = Enum.Font.Michroma; ParryBtn.ZIndex = 5; ApplyRadius(ParryBtn, 4)
local ParryStroke = Instance.new("UIStroke", ParryBtn); ParryStroke.Color = Color3.fromRGB(120, 120, 120); ParryStroke.Thickness = 1
local DiagPanel = Instance.new("Frame", ConfigCanvas); DiagPanel.Size = UDim2.new(0, 460, 0, 110); DiagPanel.Position = UDim2.new(0.5, -230, 0.5, 5); DiagPanel.BackgroundColor3 = Color3.fromRGB(45, 45, 45); DiagPanel.ZIndex = 4; ApplyRadius(DiagPanel, 4)
local DiagStroke = Instance.new("UIStroke", DiagPanel); DiagStroke.Color = Color3.fromRGB(120, 120, 120); DiagStroke.Thickness = 1

local DiagMacroLabel = Instance.new("TextLabel", DiagPanel); DiagMacroLabel.Size = UDim2.new(1, -30, 0, 20); DiagMacroLabel.Position = UDim2.new(0, 15, 0, 35); DiagMacroLabel.BackgroundTransparency = 1; DiagMacroLabel.Text = "STATUS: STANDBY"; DiagMacroLabel.TextColor3 = Color3.fromRGB(150, 150, 150); DiagMacroLabel.Font = Enum.Font.Michroma; DiagMacroLabel.TextSize = 11; DiagMacroLabel.TextXAlignment = Enum.TextXAlignment.Left; DiagMacroLabel.ZIndex = 5
local DiagKeyLabel = Instance.new("TextLabel", DiagPanel); DiagKeyLabel.Size = UDim2.new(1, -30, 0, 20); DiagKeyLabel.Position = UDim2.new(0, 15, 0, 55); DiagKeyLabel.BackgroundTransparency = 1; DiagKeyLabel.Text = "BIND REGISTER: NONE"; DiagKeyLabel.TextColor3 = Color3.fromRGB(150, 150, 150); DiagKeyLabel.Font = Enum.Font.Michroma; DiagKeyLabel.TextSize = 11; DiagKeyLabel.TextXAlignment = Enum.TextXAlignment.Left; DiagKeyLabel.ZIndex = 5
local DiagParryLabel = Instance.new("TextLabel", DiagPanel); DiagParryLabel.Size = UDim2.new(1, -30, 0, 20); DiagParryLabel.Position = UDim2.new(0, 15, 0, 75); DiagParryLabel.BackgroundTransparency = 1; DiagParryLabel.Text = "DEFENSE MATRIX: DISENGAGED"; DiagParryLabel.TextColor3 = Color3.fromRGB(150, 150, 150); DiagParryLabel.Font = Enum.Font.Michroma; DiagParryLabel.TextSize = 11; DiagParryLabel.TextXAlignment = Enum.TextXAlignment.Left; DiagParryLabel.ZIndex = 5

local ControlPod = Instance.new("Frame", ScreenGui); ControlPod.Size = UDim2.new(0, 260, 0, 75); ControlPod.Position = UDim2.new(0.5, -130, 0.5, 160); ControlPod.BackgroundColor3 = Color3.fromRGB(30, 30, 30); ControlPod.Active = true; ControlPod.Draggable = true; ApplyRadius(ControlPod, 6)
local PodStroke = Instance.new("UIStroke", ControlPod); PodStroke.Color = Color3.fromRGB(160, 160, 160); PodStroke.Thickness = 1
local ActionButton = Instance.new("TextButton", ScreenGui); ActionButton.Size = UDim2.new(0, 230, 0, 36); ActionButton.Position = UDim2.new(0.5, -115, 0.5, 175); ActionButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120); ActionButton.Text = "ACTIVATE"; ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255); ActionButton.Font = Enum.Font.Michroma; ActionButton.ZIndex = 5; ApplyRadius(ActionButton, 4)
local StatusBar = Instance.new("TextLabel", ScreenGui); StatusBar.Size = UDim2.new(0, 230, 0, 18); StatusBar.Position = UDim2.new(0.5, -115, 0.5, 213); StatusBar.BackgroundTransparency = 1; StatusBar.Text = "WORKFLOW IDLE"; StatusBar.TextColor3 = Color3.fromRGB(150, 150, 150); StatusBar.Font = Enum.Font.Michroma; StatusBar.TextSize = 10; StatusBar.ZIndex = 5

-- 7. SIGNAL HANDLING & EVENTS
local function UpdateUI()
    local labelMode = EngineState.ModeSelection == "KPS" and "KPS" or "CPS"
    SpeedDisplay.Text = string.format("%d %s", EngineState.TargetSpeed, labelMode)
    local manualMode = EngineState.ActivationMode == "Manual Spam"
    ControlPod.Visible = manualMode; ActionButton.Visible = manualMode; StatusBar.Visible = manualMode
    if EngineState.IsRunning then StatusBar.Text = "MACRO FIRING"; StatusBar.TextColor3 = Color3.fromRGB(160, 160, 160); ActionButton.Text = "HALT CORE"; ActionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80); DiagMacroLabel.Text = "STATUS: RUNNING CORE"; DiagMacroLabel.TextColor3 = Color3.fromRGB(160, 160, 160) else StatusBar.Text = "WORKFLOW IDLE"; StatusBar.TextColor3 = Color3.fromRGB(150, 150, 150); ActionButton.Text = "ACTIVATE"; ActionButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120); DiagMacroLabel.Text = "STATUS: STANDBY"; DiagMacroLabel.TextColor3 = Color3.fromRGB(150, 150, 150) end
end

-- LOGIC CONNECTIONS
TitleLabel.MouseButton1Click:Connect(function()
    EngineState.Collapsed = not EngineState.Collapsed
    local targetSize = EngineState.Collapsed and UDim2.new(0, 180, 0, 42) or UDim2.new(0, 500, 0, 360)
    TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = targetSize}):Play()
    local v = not EngineState.Collapsed; ModeBtn.Visible = v; SwitchContainer.Visible = v; SliderTrack.Visible = v; SpeedDisplay.Visible = v; ParryBtn.Visible = v; DiagPanel.Visible = v
end)

local function AnimateSwitch(isOn)
    local targetPos = isOn and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
    local targetColor = isOn and Color3.fromRGB(160, 160, 160) or Color3.fromRGB(65, 65, 65)
    TweenService:Create(ToggleThumb, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    TweenService:Create(ToggleTrack, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()
end

local IsDragging = false
local function UpdateSlider(inputObj)
    local fraction = clamp((inputObj.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
    local maxLimit = EngineState.LowEndMode and 200 or 2500
    local calculated = round(1 + (fraction * (maxLimit - 1)))
    EngineState.TargetSpeed = calculated
    SliderFill.Size = UDim2.new(fraction, 0, 1, 0)
    SliderButton.Position = UDim2.new(fraction, -7, 0.5, -7)
    UpdateUI()
end

SliderButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then IsDragging = true end end)
UserInputService.InputChanged:Connect(function(input) if IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateSlider(input) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then IsDragging = false end end)

-- [BINDING & EVENTS]
local function BindChassisPosition(chassisFrame, elementList)
    local offsets = {}
    for _, el in ipairs(elementList) do offsets[el] = el.Position - chassisFrame.Position end
    chassisFrame:GetPropertyChangedSignal("Position"):Connect(function() local basePos = chassisFrame.Position for el, originalOffset in pairs(offsets) do el.Position = basePos + originalOffset end end)
end

BindChassisPosition(MainFrame, {TitleLabel, ModeBtn, SwitchContainer, SliderTrack, SpeedDisplay, ParryBtn, DiagPanel})
BindChassisPosition(ControlPod, {ActionButton, StatusBar})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if EngineState.IsBinding then if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.RightShift then EngineState.RuntimeHotkey = input.KeyCode; EngineState.ActivationMode = "Hotkey"; EngineState.IsBinding = false; SwitchLabel.Text = "[" .. input.KeyCode.Name .. "]"; DiagKeyLabel.Text = "BIND REGISTER: [" .. input.KeyCode.Name .. "]"; UpdateUI() end return end
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then EngineState.ConfigVisible = not EngineState.ConfigVisible; ConfigCanvas.Visible = EngineState.ConfigVisible end
    if EngineState.RuntimeHotkey and input.KeyCode == EngineState.RuntimeHotkey then if EngineState.ActivationMode == "Hotkey" then ToggleEngine(); UpdateUI() end end
end)

ActionButton.MouseButton1Click:Connect(function() if EngineState.ActivationMode == "Manual Spam" then ToggleEngine(); UpdateUI() end end)
ModeBtn.MouseButton1Click:Connect(function() EngineState.ModeSelection = EngineState.ModeSelection == "KPS" and "CPS" or "KPS"; ModeBtn.Text = EngineState.ModeSelection == "KPS" and "MODE: KPS" or "MODE: CPS"; UpdateUI() end)
ToggleTrack.MouseButton1Click:Connect(function() if EngineState.ActivationMode == "Manual Spam" then EngineState.IsBinding = true; EngineState.ActivationMode = "Hotkey"; SwitchLabel.Text = "PRESS KEY"; AnimateSwitch(true); UpdateUI() else if EngineState.IsRunning then StopLoop() end; EngineState.ActivationMode = "Manual Spam"; EngineState.RuntimeHotkey = nil; EngineState.IsBinding = false; SwitchLabel.Text = "KEYBIND"; DiagKeyLabel.Text = "BIND REGISTER: NONE"; AnimateSwitch(false); UpdateUI() end end)
ParryBtn.MouseButton1Click:Connect(function() EngineState.AutoParryActive = not EngineState.AutoParryActive; if EngineState.AutoParryActive then ParryBtn.Text = "AUTO PARRY: ACTIVE"; ParryBtn.TextColor3 = Color3.fromRGB(160, 160, 160); DiagParryLabel.Text = "DEFENSE MATRIX: ACTIVE"; DiagParryLabel.TextColor3 = Color3.fromRGB(160, 160, 160); StartParryTracking() else ParryBtn.Text = "AUTO PARRY: DISABLED"; ParryBtn.TextColor3 = Color3.fromRGB(120, 120, 120); DiagParryLabel.Text = "DEFENSE MATRIX: DISENGAGED"; DiagParryLabel.TextColor3 = Color3.fromRGB(150, 150, 150); StopParryTracking() end end)

UpdateUI()
