-- =============================================================================
-- THYREN REPOSITORY DASHBOARD [INTEGRATED & OPTIMIZED]
-- TARGET: Universal Roblox Environment
-- =============================================================================

local uiName = "ThyrenUI"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- 1. UTILITY: DRAGGABLE LOGIC (Replaces deprecated .Draggable)
local function MakeDraggable(gui)
    local dragging, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- 2. CLEANUP & PARENTING
pcall(function() local oldUI = CoreGui:FindFirstChild(uiName) if oldUI then oldUI:Destroy() end end)
local TargetParent = CoreGui
local success, err = pcall(function() local test = Instance.new("Folder"); test.Parent = CoreGui; test:Destroy() end)
if not success then TargetParent = LocalPlayer:WaitForChild("PlayerGui") end

-- 3. STATE MANAGEMENT
local EngineState = { IsRunning = false, TargetSpeed = 10, ModeSelection = "KPS", LowEndMode = false, ActivationMode = "Manual Spam", RuntimeHotkey = nil, IsBinding = false, AutoParryActive = false, ParryThreshold = 45, SpamKey = Enum.KeyCode.F, ParryConnection = nil, ConfigVisible = true, Collapsed = false }
local lastFireTime = 0
local MacroConnection = nil

-- 4. CORE ENGINE FUNCTIONS
local function RunSpamIteration()
    if not EngineState.IsRunning then return end
    local targetSpeed = EngineState.TargetSpeed; local currentMode = EngineState.ModeSelection; local spamKey = EngineState.SpamKey
    if targetSpeed >= 60 then
        if currentMode == "KPS" then 
            VirtualInputManager:SendKeyEvent(true, spamKey, false, game); VirtualInputManager:SendKeyEvent(false, spamKey, false, game)
            VirtualInputManager:SendKeyEvent(true, spamKey, false, game); VirtualInputManager:SendKeyEvent(false, spamKey, false, game)
        else 
            local mp = UserInputService:GetMouseLocation(); VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 0); VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 0)
            VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 0); VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 0)
        end
    else 
        local currentTime = os.clock() 
        if (currentTime - lastFireTime) >= (1.0 / targetSpeed) then 
            lastFireTime = currentTime
            if currentMode == "KPS" then VirtualInputManager:SendKeyEvent(true, spamKey, false, game); VirtualInputManager:SendKeyEvent(false, spamKey, false, game) 
            else local mp = UserInputService:GetMouseLocation(); VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 0); VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 0) end 
        end 
    end
end

local function StartLoop() EngineState.IsRunning = true; lastFireTime = os.clock(); if MacroConnection then MacroConnection:Disconnect() end; MacroConnection = RunService.PreRender:Connect(RunSpamIteration) end
local function StopLoop() EngineState.IsRunning = false; if MacroConnection then MacroConnection:Disconnect(); MacroConnection = nil end end
local function ToggleEngine() if EngineState.IsRunning then StopLoop() else StartLoop() end end

-- 5. TARGETING (Universal)
local function FindActiveBall()
    local BallFolder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")
    if BallFolder then for _, ball in ipairs(BallFolder:GetChildren()) do if (ball:GetAttribute("target") or "") == LocalPlayer.Name then return ball:IsA("BasePart") and ball or ball:FindFirstChildOfClass("BasePart") end end end
    for _, obj in ipairs(workspace:GetChildren()) do if obj.Name == "Ball" and obj:GetAttribute("target") == LocalPlayer.Name then return obj end end
    return nil
end

local function StartParryTracking()
    if EngineState.ParryConnection then EngineState.ParryConnection:Disconnect() end
    EngineState.ParryConnection = RunService.PreSimulation:Connect(function()
        if not EngineState.AutoParryActive then return end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local ball = FindActiveBall()
        if ball then 
            local dist = (ball.Position - root.Position).Magnitude
            if dist <= (EngineState.ParryThreshold + (ball.AssemblyLinearVelocity.Magnitude * 0.12)) then
                if EngineState.ModeSelection == "KPS" then VirtualInputManager:SendKeyEvent(true, EngineState.SpamKey, false, game); VirtualInputManager:SendKeyEvent(false, EngineState.SpamKey, false, game)
                else local mp = UserInputService:GetMouseLocation(); VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 0); VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 0) end
            end
        end
    end)
end

-- 6. UI STYLING & DEPTH UTILITIES
local Colors = { Background = Color3.fromRGB(22, 22, 24), Surface = Color3.fromRGB(28, 28, 32), SurfaceRaised = Color3.fromRGB(38, 38, 44), SurfaceOverlay = Color3.fromRGB(45, 45, 52), Interactive = Color3.fromRGB(52, 52, 60), InteractiveHover = Color3.fromRGB(62, 62, 72), InteractivePressed = Color3.fromRGB(42, 42, 48), TrackBackground = Color3.fromRGB(35, 35, 40), TrackFill = Color3.fromRGB(140, 140, 155), TrackThumb = Color3.fromRGB(185, 185, 200), TrackThumbHover = Color3.fromRGB(210, 210, 220), ToggleOff = Color3.fromRGB(55, 55, 62), ToggleOn = Color3.fromRGB(140, 140, 155), ToggleThumb = Color3.fromRGB(220, 220, 230), TextPrimary = Color3.fromRGB(235, 235, 245), TextSecondary = Color3.fromRGB(165, 165, 180), TextMuted = Color3.fromRGB(110, 110, 125), BorderSubtle = Color3.fromRGB(60, 60, 70), BorderMedium = Color3.fromRGB(80, 80, 95), ShadowDark = Color3.fromRGB(8, 8, 10), ActiveGlow = Color3.fromRGB(150, 150, 170), ActiveText = Color3.fromRGB(200, 200, 215) }

local function ApplyRadius(i, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = i; return c end
local function CreateDepthPanel(props)
    local p = Instance.new("Frame"); p.Name = props.Name or "DepthPanel"; p.Size = props.Size; p.Position = props.Position; p.BackgroundColor3 = props.Color or Colors.Surface; p.Parent = props.Parent; ApplyRadius(p, props.Radius or 8)
    local str = Instance.new("UIStroke"); str.Color = props.BorderColor or Colors.BorderSubtle; str.Thickness = props.BorderThickness or 1; str.Transparency = 0.2; str.Parent = p
    return p
end

-- 7. UI CONSTRUCTION
local ScreenGui = Instance.new("ScreenGui", TargetParent)
ScreenGui.Name = uiName
ScreenGui.DisplayOrder = 999 -- Force on top
local ConfigCanvas = Instance.new("Frame", ScreenGui); ConfigCanvas.Size = UDim2.new(1,0,1,0); ConfigCanvas.BackgroundTransparency = 1
local MainFrame = CreateDepthPanel({Name="Main", Parent=ConfigCanvas, Size=UDim2.new(0,500,0,360), Position=UDim2.new(0.5,-250,0.5,-210), Color=Colors.Surface, Radius=10})
MainFrame.Active = true
MakeDraggable(MainFrame)

-- 8. UI ELEMENTS CONTINUATION
local InnerContent = Instance.new("Frame", MainFrame)
InnerContent.Name = "InnerContent"; InnerContent.Size = UDim2.new(1,-8,1,-8); InnerContent.Position = UDim2.new(0,4,0,4); InnerContent.BackgroundTransparency = 1; InnerContent.ZIndex = 2

local TitleLabel = Instance.new("TextLabel", MainFrame)
TitleLabel.Name = "Logo"; TitleLabel.Size = UDim2.new(0,160,0,40); TitleLabel.Position = UDim2.new(0,20,0,10); TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = "THYREN"; TitleLabel.TextColor3 = Colors.TextPrimary; TitleLabel.Font = Enum.Font.Michroma; TitleLabel.TextSize = 18; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local ModeBtn = Instance.new("TextButton", MainFrame)
ModeBtn.Size = UDim2.new(0,215,0,42); ModeBtn.Position = UDim2.new(0,20,0,60); ModeBtn.BackgroundColor3 = Colors.Interactive; ModeBtn.Text = "MODE: KPS"; ModeBtn.TextColor3 = Colors.TextPrimary; ModeBtn.Font = Enum.Font.Michroma; ApplyRadius(ModeBtn, 6)

local SwitchContainer = Instance.new("Frame", MainFrame)
SwitchContainer.Size = UDim2.new(0,215,0,42); SwitchContainer.Position = UDim2.new(0,265,0,60); SwitchContainer.BackgroundColor3 = Colors.Interactive; ApplyRadius(SwitchContainer, 6)
local SwitchLabel = Instance.new("TextLabel", SwitchContainer); SwitchLabel.Size = UDim2.new(0,140,1,0); SwitchLabel.Position = UDim2.new(0,12,0,0); SwitchLabel.BackgroundTransparency = 1; SwitchLabel.Text = "KEYBIND"; SwitchLabel.TextColor3 = Colors.TextPrimary; SwitchLabel.Font = Enum.Font.Michroma

local ToggleTrack = Instance.new("TextButton", SwitchContainer); ToggleTrack.Size = UDim2.new(0,46,0,26); ToggleTrack.Position = UDim2.new(1,-56,0.5,-13); ToggleTrack.BackgroundColor3 = Colors.ToggleOff; ToggleTrack.Text = ""; ApplyRadius(ToggleTrack, 13)
local ToggleThumb = Instance.new("Frame", ToggleTrack); ToggleThumb.Size = UDim2.new(0,22,0,22); ToggleThumb.Position = UDim2.new(0,2,0.5,-11); ToggleThumb.BackgroundColor3 = Colors.ToggleThumb; ApplyRadius(ToggleThumb, 11)

local SliderTrack = Instance.new("Frame", MainFrame); SliderTrack.Size = UDim2.new(0,460,0,8); SliderTrack.Position = UDim2.new(0,20,0,120); SliderTrack.BackgroundColor3 = Colors.TrackBackground; ApplyRadius(SliderTrack, 4)
local SliderFill = Instance.new("Frame", SliderTrack); SliderFill.Size = UDim2.new(0.01,0,1,0); SliderFill.BackgroundColor3 = Colors.TrackFill; ApplyRadius(SliderFill, 4)
local SliderButton = Instance.new("TextButton", SliderTrack); SliderButton.Size = UDim2.new(0,16,0,16); SliderButton.Position = UDim2.new(0.01,-8,0.5,-8); SliderButton.BackgroundColor3 = Colors.TrackThumb; SliderButton.Text = ""; ApplyRadius(SliderButton, 8)

local SpeedDisplay = Instance.new("TextLabel", MainFrame); SpeedDisplay.Size = UDim2.new(0,120,0,30); SpeedDisplay.Position = UDim2.new(0,360,0,105); SpeedDisplay.BackgroundTransparency = 1; SpeedDisplay.Text = "10 KPS"; SpeedDisplay.TextColor3 = Colors.TextSecondary; SpeedDisplay.Font = Enum.Font.Michroma; SpeedDisplay.TextSize = 14

local ParryBtn = Instance.new("TextButton", MainFrame); ParryBtn.Size = UDim2.new(0,460,0,40); ParryBtn.Position = UDim2.new(0,20,0,150); ParryBtn.BackgroundColor3 = Colors.Interactive; ParryBtn.Text = "AUTO PARRY: DISABLED"; ParryBtn.TextColor3 = Colors.TextMuted; ParryBtn.Font = Enum.Font.Michroma; ApplyRadius(ParryBtn, 6)

local DiagPanel = Instance.new("Frame", MainFrame); DiagPanel.Size = UDim2.new(0,460,0,110); DiagPanel.Position = UDim2.new(0,20,0,210); DiagPanel.BackgroundColor3 = Colors.SurfaceRaised; ApplyRadius(DiagPanel, 6)
local DiagMacroLabel = Instance.new("TextLabel", DiagPanel); DiagMacroLabel.Size = UDim2.new(1,-30,0,20); DiagMacroLabel.Position = UDim2.new(0,15,0,35); DiagMacroLabel.BackgroundTransparency = 1; DiagMacroLabel.Text = "STATUS: STANDBY"; DiagMacroLabel.TextColor3 = Colors.TextMuted; DiagMacroLabel.Font = Enum.Font.Michroma

-- 9. CONTROL POD & ACTION
local ControlPod = CreateDepthPanel({Name="ControlPod", Parent=ScreenGui, Size=UDim2.new(0,260,0,75), Position=UDim2.new(0.5,-130,0.8,0), Color=Colors.Surface, Radius=8})
MakeDraggable(ControlPod)
local ActionButton = Instance.new("TextButton", ControlPod); ActionButton.Size = UDim2.new(0,230,0,38); ActionButton.Position = UDim2.new(0.5,-115,0.5,-19); ActionButton.BackgroundColor3 = Colors.SurfaceOverlay; ActionButton.Text = "ACTIVATE"; ActionButton.TextColor3 = Colors.TextPrimary; ActionButton.Font = Enum.Font.Michroma; ApplyRadius(ActionButton, 6)

-- 10. UPDATER LOGIC
local function UpdateUI()
    local labelMode = EngineState.ModeSelection == "KPS" and "KPS" or "CPS"
    SpeedDisplay.Text = string.format("%d %s", EngineState.TargetSpeed, labelMode)
    if EngineState.IsRunning then
        ActionButton.Text = "HALT CORE"; DiagMacroLabel.Text = "STATUS: RUNNING CORE"; DiagMacroLabel.TextColor3 = Colors.ActiveText
    else
        ActionButton.Text = "ACTIVATE"; DiagMacroLabel.Text = "STATUS: STANDBY"; DiagMacroLabel.TextColor3 = Colors.TextMuted
    end
end

-- 11. EVENT CONNECTIONS
local IsDragging = false
SliderButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then IsDragging = true end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then IsDragging = false end end)
UserInputService.InputChanged:Connect(function(input)
    if IsDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local fraction = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        EngineState.TargetSpeed = math.round(1 + (fraction * 2499))
        SliderFill.Size = UDim2.new(fraction, 0, 1, 0); SliderButton.Position = UDim2.new(fraction, -8, 0.5, -8)
        UpdateUI()
    end
end)

ActionButton.MouseButton1Click:Connect(function() ToggleEngine(); UpdateUI() end)
ModeBtn.MouseButton1Click:Connect(function() EngineState.ModeSelection = (EngineState.ModeSelection == "KPS" and "CPS" or "KPS"); ModeBtn.Text = "MODE: "..EngineState.ModeSelection; UpdateUI() end)
ParryBtn.MouseButton1Click:Connect(function() 
    EngineState.AutoParryActive = not EngineState.AutoParryActive
    ParryBtn.Text = EngineState.AutoParryActive and "AUTO PARRY: ACTIVE" or "AUTO PARRY: DISABLED"
    if EngineState.AutoParryActive then StartParryTracking() else StopParryTracking() end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then ScreenGui.Enabled = not ScreenGui.Enabled end
end)

UpdateUI()
