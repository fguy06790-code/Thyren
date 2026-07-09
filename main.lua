-- =============================================================================
-- THYREN ULTIMATE (PART 1 OF 2)
-- CORE: HIGH-PERFORMANCE ENGINE & AUTO-PARRY
-- =============================================================================

local uiName = "ThyrenUltra_Final_V5"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- [[ 1. PURGE PREVIOUS ]]
pcall(function() if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end end)

-- [[ 2. CORE ENGINE STATE ]]
local EngineState = { 
    IsRunning = false, 
    TargetSpeed = 10, 
    InputMode = "Button", 
    AutoParryActive = true, 
    ParryThreshold = 45, 
    SpamKey = Enum.KeyCode.F,
    ToggleKey = Enum.KeyCode.F9, 
    LastFireTime = 0, 
    MacroToggle = false
}

local sendKeyEvent = VirtualInputManager.SendKeyEvent
local osClock = os.clock
local mathRandom = math.random
local MacroConnection = nil

-- [[ 3. STEALTH MACRO ENGINE ]]
local function ExecuteRawInput()
    if not EngineState.MacroToggle then return end
    
    local targetSpeed = EngineState.TargetSpeed
    local currentTime = osClock()
    local jitter = (mathRandom(-50, 50) / 10000) 
    
    if (currentTime - EngineState.LastFireTime) >= ((1.0 / targetSpeed) + jitter) then
        EngineState.LastFireTime = currentTime
        
        -- Physical Emulation
        sendKeyEvent(VirtualInputManager, true, EngineState.SpamKey, false, game)
        task.wait(0.001)
        sendKeyEvent(VirtualInputManager, false, EngineState.SpamKey, false, game)
    end
end

-- [[ 4. UNIVERSAL PARRY SCANNER ]]
local function FindActiveBall()
    local BallFolder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")
    if BallFolder then 
        for _, ball in ipairs(BallFolder:GetChildren()) do
            local target = ball:GetAttribute("target") or ball:GetAttribute("Target")
            if target == LocalPlayer.Name then 
                return ball:IsA("BasePart") and ball or ball:FindFirstChildOfClass("BasePart") 
            end 
        end 
    end
    return nil
end

_G.StartParry = function()
    RunService.PreSimulation:Connect(function()
        if not EngineState.AutoParryActive then return end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local ball = FindActiveBall()
        if root and ball then 
            local dist = (ball.Position - root.Position).Magnitude
            local vel = ball.AssemblyLinearVelocity.Magnitude
            if dist <= (EngineState.ParryThreshold + (vel * 0.12)) then 
                sendKeyEvent(VirtualInputManager, true, EngineState.SpamKey, false, game)
                sendKeyEvent(VirtualInputManager, false, EngineState.SpamKey, false, game)
            end
        end
    end)
end
-- =============================================================================
-- THYREN ULTIMATE (PART 2 OF 2) - PRODUCTION ADVERTISING EDITION
-- =============================================================================

local function IsKeyValid(input)
    return input == "kifHpqTzfWd5rM"
end

local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = uiName
ScreenGui.ResetOnSpawn = false; ScreenGui.DisplayOrder = 999; ScreenGui.IgnoreGuiInset = true

local function MakeDraggable(obj)
    local dragToggle, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragToggle = true; dragStart = input.Position; startPos = obj.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end)
        end
    end)
    obj.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragToggle then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- [[ MAIN PRODUCTION CONTAINER ]]
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -80)
MainFrame.Size = UDim2.new(0, 300, 0, 160)
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
MakeDraggable(MainFrame)

-- NEON ACCENT BORDER
local Accent = Instance.new("Frame", MainFrame)
Accent.Size = UDim2.new(1, 0, 0, 2); Accent.BackgroundColor3 = Color3.fromRGB(130, 130, 145); Accent.BorderSizePixel = 0; Accent.ZIndex = 10

-- DEPTH SHADOW
local Shadow = Instance.new("ImageLabel", MainFrame); Shadow.Size = UDim2.new(1, 40, 1, 40); Shadow.Position = UDim2.new(0, -20, 0, -20); Shadow.BackgroundTransparency = 1; Shadow.Image = "rbxassetid://6015667342"; Shadow.ImageColor3 = Color3.fromRGB(0,0,0); Shadow.ImageTransparency = 0.4; Shadow.ZIndex = 4

-- [[ AUTH OVERLAY ]]
local AuthFrame = Instance.new("Frame", MainFrame); AuthFrame.Size = UDim2.new(1, 0, 1, 0); AuthFrame.BackgroundTransparency = 1; AuthFrame.ZIndex = 50
local KeyInput = Instance.new("TextBox", AuthFrame); KeyInput.Size = UDim2.new(0, 240, 0, 35); KeyInput.Position = UDim2.new(0.5, -120, 0.35, -17); KeyInput.BackgroundColor3 = Color3.fromRGB(20, 20, 22); KeyInput.TextColor3 = Color3.fromRGB(200, 200, 210); KeyInput.PlaceholderText = "Master Key..."; KeyInput.Text = ""; KeyInput.Font = Enum.Font.Code; KeyInput.ZIndex = 51
Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 8)
local SubmitBtn = Instance.new("TextButton", AuthFrame); SubmitBtn.Size = UDim2.new(0, 240, 0, 35); SubmitBtn.Position = UDim2.new(0.5, -120, 0.75, -17); SubmitBtn.BackgroundColor3 = Color3.fromRGB(130, 130, 145); SubmitBtn.Text = "INITIALIZE"; SubmitBtn.TextColor3 = Color3.fromRGB(20, 20, 25); SubmitBtn.Font = Enum.Font.Michroma; SubmitBtn.ZIndex = 51
Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 8)

-- [[ SIDEBAR ]]
local Sidebar = Instance.new("Frame", MainFrame); Sidebar.Size = UDim2.new(0, 140, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 22); Sidebar.ZIndex = 6; Sidebar.Visible = false
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 16)
local SideTitle = Instance.new("TextLabel", Sidebar); SideTitle.Size = UDim2.new(1, 0, 0, 60); SideTitle.Text = "THYREN"; SideTitle.TextColor3 = Color3.fromRGB(255, 255, 255); SideTitle.BackgroundTransparency = 1; SideTitle.Font = Enum.Font.Michroma; SideTitle.TextSize = 16; SideTitle.ZIndex = 7

local TabContainer = Instance.new("Frame", Sidebar); TabContainer.Size = UDim2.new(1, 0, 1, -60); TabContainer.Position = UDim2.new(0, 0, 0, 60); TabContainer.BackgroundTransparency = 1; TabContainer.ZIndex = 7
local function CreateTab(name, pos)
    local btn = Instance.new("TextButton", TabContainer); btn.Size = UDim2.new(0.9, 0, 0, 40); btn.Position = UDim2.new(0.05, 0, 0, pos); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40); btn.Text = name; btn.TextColor3 = Color3.fromRGB(200, 200, 210); btn.Font = Enum.Font.Michroma; btn.TextSize = 8; btn.ZIndex = 8
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8); return btn
end
local MacroTabBtn = CreateTab("MACRO ENGINE", 10); local ParryTabBtn = CreateTab("AUTO PARRY", 55)

local PageContainer = Instance.new("Frame", MainFrame); PageContainer.Size = UDim2.new(1, -150, 1, -20); PageContainer.Position = UDim2.new(0, 150, 0, 10); PageContainer.BackgroundTransparency = 1; PageContainer.ZIndex = 6; PageContainer.Visible = false
local function CreatePage()
    local p = Instance.new("Frame", PageContainer); p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.Visible = false; p.ZIndex = 6; return p
end
local MacroPage = CreatePage(); local ParryPage = CreatePage()

-- [[ MACRO PAGE ]]
local SpeedDisplay = Instance.new("TextLabel", MacroPage); SpeedDisplay.Size = UDim2.new(0, 200, 0, 30); SpeedDisplay.Position = UDim2.new(0.5, -100, 0.1, 0); SpeedDisplay.Text = "10 KPS"; SpeedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255); SpeedDisplay.BackgroundTransparency = 1; SpeedDisplay.Font = Enum.Font.Michroma; SpeedDisplay.ZIndex = 7
local SliderFrame = Instance.new("Frame", MacroPage); SliderFrame.Size = UDim2.new(0, 300, 0, 20); SliderFrame.Position = UDim2.new(0.5, -150, 0.25, 0); SliderFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40); SliderFrame.ZIndex = 7
local SliderFill = Instance.new("Frame", SliderFrame); SliderFill.Size = UDim2.new(0.01, 0, 1, 0); SliderFill.BackgroundColor3 = Color3.fromRGB(130, 130, 145); SliderFill.ZIndex = 8
local SliderHandle = Instance.new("TextButton", SliderFrame); SliderHandle.Size = UDim2.new(0, 15, 1, 0); SliderHandle.Position = UDim2.new(0.01, -7, 0, 0); SliderHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); SliderHandle.Text = ""; SliderHandle.ZIndex = 9; Instance.new("UICorner", SliderHandle).CornerRadius = UDim.new(1, 0)

local SwitchFrame = Instance.new("Frame", MacroPage); SwitchFrame.Size = UDim2.new(0, 50, 0, 28); SwitchFrame.Position = UDim2.new(0.7, 0, 0.45, 0); SwitchFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 60); SwitchFrame.ZIndex = 7; Instance.new("UICorner", SwitchFrame).CornerRadius = UDim.new(1, 0)
local SwitchThumb = Instance.new("Frame", SwitchFrame); SwitchThumb.Size = UDim2.new(0, 24, 0, 24); SwitchThumb.Position = UDim2.new(0, 2, 0.5, -12); SwitchThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); SwitchThumb.ZIndex = 8; Instance.new("UICorner", SwitchThumb).CornerRadius = UDim.new(1, 0)
local SwitchBtn = Instance.new("TextButton", SwitchFrame); SwitchBtn.Size = UDim2.new(1, 0, 1, 0); SwitchBtn.BackgroundTransparency = 1; SwitchBtn.Text = ""; SwitchBtn.ZIndex = 9
local SwitchLabel = Instance.new("TextLabel", MacroPage); SwitchLabel.Size = UDim2.new(0, 120, 0, 28); SwitchLabel.Position = UDim2.new(0, 20, 0.45, 0); SwitchLabel.Text = "BIND MODE:"; SwitchLabel.TextColor3 = Color3.fromRGB(200, 200, 210); SwitchLabel.BackgroundTransparency = 1; SwitchLabel.Font = Enum.Font.Michroma; SwitchLabel.TextSize = 10; SwitchLabel.ZIndex = 7; SwitchLabel.TextXAlignment = Enum.TextXAlignment.Left

local BindBtn = Instance.new("TextButton", MacroPage); BindBtn.Size = UDim2.new(0, 160, 0, 35); BindBtn.Position = UDim2.new(0.5, -80, 0.7, 0); BindBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40); BindBtn.Text = "TOGGLE: F9"; BindBtn.TextColor3 = Color3.fromRGB(200, 200, 210); BindBtn.Font = Enum.Font.Michroma; BindBtn.TextSize = 9; BindBtn.ZIndex = 7; Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 10)

-- [[ PARRY PAGE ]]
local ParryLabel = Instance.new("TextLabel", ParryPage); ParryLabel.Size = UDim2.new(0, 200, 0, 30); ParryLabel.Position = UDim2.new(0.5, -100, 0.3, 0); ParryLabel.Text = "P-SYSTEM STATUS"; ParryLabel.TextColor3 = Color3.fromRGB(150, 150, 160); ParryLabel.BackgroundTransparency = 1; ParryLabel.Font = Enum.Font.Michroma; ParryLabel.TextSize = 10; ParryLabel.ZIndex = 7
local ParrySwitchFrame = Instance.new("Frame", ParryPage); ParrySwitchFrame.Size = UDim2.new(0, 60, 0, 32); ParrySwitchFrame.Position = UDim2.new(0.5, -30, 0.45, 0); ParrySwitchFrame.BackgroundColor3 = Color3.fromRGB(75, 215, 100); ParrySwitchFrame.ZIndex = 7; Instance.new("UICorner", ParrySwitchFrame).CornerRadius = UDim.new(1, 0)
local ParrySwitchThumb = Instance.new("Frame", ParrySwitchFrame); ParrySwitchThumb.Size = UDim2.new(0, 28, 0, 28); ParrySwitchThumb.Position = UDim2.new(1, -30, 0.5, -14); ParrySwitchThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); ParrySwitchThumb.ZIndex = 8; Instance.new("UICorner", ParrySwitchThumb).CornerRadius = UDim.new(1, 0)
local ParrySwitchBtn = Instance.new("TextButton", ParrySwitchFrame); ParrySwitchBtn.Size = UDim2.new(1, 0, 1, 0); ParrySwitchBtn.BackgroundTransparency = 1; ParrySwitchBtn.Text = ""; ParrySwitchBtn.ZIndex = 9

-- [[ GLOBAL FLOATING ACTIVATE BUTTON ]]
local ActivateBtn = Instance.new("TextButton", ScreenGui); ActivateBtn.Size = UDim2.new(0, 140, 0, 50); ActivateBtn.Position = UDim2.new(0.5, -70, 0.9, 0); ActivateBtn.BackgroundColor3 = Color3.fromRGB(130, 130, 145); ActivateBtn.Text = "ACTIVATE"; ActivateBtn.TextColor3 = Color3.fromRGB(20, 20, 25); ActivateBtn.Font = Enum.Font.Michroma; ActivateBtn.Visible = false; ActivateBtn.ZIndex = 20; Instance.new("UICorner", ActivateBtn).CornerRadius = UDim.new(0, 12); MakeDraggable(ActivateBtn)

-- [[ LOGIC ]]
local function UpdateUI()
    ActivateBtn.Text = EngineState.MacroToggle and "HALT" or "ACTIVATE"
    SpeedDisplay.Text = EngineState.TargetSpeed .. " KPS"
    BindBtn.Text = "TOGGLE: " .. EngineState.ToggleKey.Name
    local pOn = EngineState.AutoParryActive; TweenService:Create(ParrySwitchThumb, TweenInfo.new(0.2), {Position = pOn and UDim2.new(1, -30, 0.5, -14) or UDim2.new(0, 2, 0.5, -14)}):Play(); TweenService:Create(ParrySwitchFrame, TweenInfo.new(0.2), {BackgroundColor3 = pOn and Color3.fromRGB(75, 215, 100) or Color3.fromRGB(55, 55, 60)}):Play()
    local isKey = (EngineState.InputMode == "Keybind"); TweenService:Create(SwitchThumb, TweenInfo.new(0.2), {Position = isKey and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)}):Play(); TweenService:Create(SwitchFrame, TweenInfo.new(0.2), {BackgroundColor3 = isKey and Color3.fromRGB(75, 215, 100) or Color3.fromRGB(55, 55, 60)}):Play(); ActivateBtn.Visible = (EngineState.InputMode == "Button")
end

local function ToggleMacro()
    EngineState.MacroToggle = not EngineState.MacroToggle; UpdateUI()
    if EngineState.MacroToggle then MacroConnection = RunService.PreRender:Connect(ExecuteRawInput) elseif MacroConnection then MacroConnection:Disconnect() end
end

SwitchBtn.MouseButton1Click:Connect(function() EngineState.InputMode = (EngineState.InputMode == "Keybind") and "Button" or "Keybind"; EngineState.MacroToggle = false; UpdateUI() end)
ActivateBtn.MouseButton1Click:Connect(ToggleMacro)
ParrySwitchBtn.MouseButton1Click:Connect(function() EngineState.AutoParryActive = not EngineState.AutoParryActive; UpdateUI() end)

local listening = false
BindBtn.MouseButton1Click:Connect(function() listening = true; BindBtn.Text = "..."; UpdateUI() end)
UserInputService.InputBegan:Connect(function(input, gpe)
    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
        EngineState.ToggleKey = input.KeyCode; listening = false; UpdateUI()
    elseif not gpe and EngineState.InputMode == "Keybind" and input.KeyCode == EngineState.ToggleKey then
        ToggleMacro()
    end
end)

local draggingSlider = false
SliderHandle.MouseButton1Down:Connect(function() draggingSlider = true end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end end)
UserInputService.InputChanged:Connect(function(i)
    if draggingSlider and (i.Position.X) then
        local frac = math.clamp((i.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
        EngineState.TargetSpeed = math.round(1 + (frac * 2499)); SliderFill.Size = UDim2.new(frac, 0, 1, 0); SliderHandle.Position = UDim2.new(frac, -7, 0, 0); UpdateUI()
    end
end)

MacroTabBtn.MouseButton1Click:Connect(function() MacroPage.Visible = true; ParryPage.Visible = false end)
ParryTabBtn.MouseButton1Click:Connect(function() MacroPage.Visible = false; ParryPage.Visible = true end)

SubmitBtn.MouseButton1Click:Connect(function()
    if IsKeyValid(KeyInput.Text) then
        AuthFrame.Visible = false; TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 520, 0, 360), Position = UDim2.new(0.5, -260, 0.5, -180)}):Play()
        task.wait(0.5); Sidebar.Visible = true; PageContainer.Visible = true; MacroPage.Visible = true; if _G.StartParry then _G.StartParry() end; UpdateUI()
    end
end)

UpdateUI()
