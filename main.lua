-- =============================================================================
-- THYREN ULTRA STEALTH (PART 1 OF 2)
-- CORE: POLYMORPHIC SIGNAL ENGINE & ENVIRONMENT CLOAKING
-- =============================================================================

local uiName = "Thyren_Ultra_Exhibition_V11"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

pcall(function() if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end end)

local EngineState = { 
    TargetSpeed = 10, 
    InputMode = "Button",
    AutoParryActive = true, 
    ParryThreshold = 45, 
    ActionKey = Enum.KeyCode.F,
    ToggleKey = Enum.KeyCode.F9, 
    LastFireTime = 0, 
    MacroToggle = false
}

local _VIM = VirtualInputManager
local _send = _VIM.SendKeyEvent
local _clock = os.clock
local _rand = math.random
local _wait = task.wait
local MacroConnection = nil

local function ExecuteStealthInput()
    if not EngineState.MacroToggle then return end
    local targetKPS = EngineState.TargetSpeed
    local currentTime = _clock()
    local timingVariance = (_rand(-140, 140) / 10000000) 
    local baseDelay = (1.0 / targetKPS)
    
    if (currentTime - EngineState.LastFireTime) >= (baseDelay + timingVariance) then
        EngineState.LastFireTime = currentTime
        _send(_VIM, true, EngineState.ActionKey, false, game)
        _wait(_rand(12, 32) / 100000) 
        _send(_VIM, false, EngineState.ActionKey, false, game)
    end
end

_G.StartParry = function()
    RunService.PreSimulation:Connect(function()
        if not EngineState.AutoParryActive then return end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local ball = (function()
            local folder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")
            if folder then 
                for _, b in ipairs(folder:GetChildren()) do
                    local t = b:GetAttribute("target") or b:GetAttribute("Target")
                    if t == LocalPlayer.Name then return b:IsA("BasePart") and b or b:FindFirstChildOfClass("BasePart") end 
                end 
            end
            return nil
        end)()
        
        if root and ball then 
            local dist = (ball.Position - root.Position).Magnitude
            local vel = ball.AssemblyLinearVelocity.Magnitude
            if dist <= (EngineState.ParryThreshold + (vel * 0.13)) then 
                _send(_VIM, true, EngineState.ActionKey, false, game)
                _send(_VIM, false, EngineState.ActionKey, false, game)
            end
        end
    end)
end
-- =============================================================================
-- THYREN ULTRA STEALTH (PART 2 OF 2) - LARGE FONT PRO UI
-- =============================================================================

local function IsKeyValid(input) return input == "kifHpqTzfWd5rM" end

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

-- [[ CONTAINER ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 360, 0, 200); Main.Position = UDim2.new(0.5, -180, 0.5, -100)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 14); Main.BorderSizePixel = 0; Main.Active = true; Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
MakeDraggable(Main)

local Glow = Instance.new("Frame", Main)
Glow.Size = UDim2.new(1, 0, 0, 2); Glow.BackgroundColor3 = Color3.fromRGB(0, 180, 255); Glow.BorderSizePixel = 0; Glow.ZIndex = 20

-- [[ AUTH ]]
local Auth = Instance.new("Frame", Main); Auth.Size = UDim2.new(1, 0, 1, 0); Auth.BackgroundTransparency = 1; Auth.ZIndex = 50
local KeyInput = Instance.new("TextBox", Auth); KeyInput.Size = UDim2.new(0, 280, 0, 45); KeyInput.Position = UDim2.new(0.5, -140, 0.35, -22); KeyInput.BackgroundColor3 = Color3.fromRGB(8, 8, 10); KeyInput.TextColor3 = Color3.fromRGB(220, 220, 230); KeyInput.PlaceholderText = "MASTER ACCESS KEY"; KeyInput.Text = ""; KeyInput.Font = Enum.Font.Michroma; KeyInput.TextSize = 12; KeyInput.ZIndex = 51; Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 12)
local Submit = Instance.new("TextButton", Auth); Submit.Size = UDim2.new(0, 280, 0, 45); Submit.Position = UDim2.new(0.5, -140, 0.7, -22); Submit.BackgroundColor3 = Color3.fromRGB(0, 160, 255); Submit.Text = "AUTHENTICATE SYSTEM"; Submit.TextColor3 = Color3.fromRGB(255, 255, 255); Submit.Font = Enum.Font.Michroma; Submit.TextSize = 12; Submit.ZIndex = 51; Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 12)

-- [[ SIDEBAR & DASHBOARD ]]
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 150, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 22); Sidebar.Visible = false; Sidebar.ZIndex = 5; Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 16)
local SideTitle = Instance.new("TextLabel", Sidebar); SideTitle.Size = UDim2.new(1, 0, 0, 60); SideTitle.Text = "THYREN ULTRA"; SideTitle.TextColor3 = Color3.fromRGB(255, 255, 255); SideTitle.BackgroundTransparency = 1; SideTitle.Font = Enum.Font.Michroma; SideTitle.TextSize = 15; SideTitle.ZIndex = 6

local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -165, 1, -30); Container.Position = UDim2.new(0, 165, 0, 15); Container.BackgroundTransparency = 1; Container.Visible = false; Container.ZIndex = 5

local function CreateTab(name, pos, page)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(0.9, 0, 0, 45); btn.Position = UDim2.new(0.05, 0, 0, pos); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); btn.Text = name; btn.TextColor3 = Color3.fromRGB(150, 150, 160); btn.Font = Enum.Font.Michroma; btn.TextSize = 10; btn.ZIndex = 6; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(function() page.Visible = true; for _,p in pairs(Container:GetChildren()) do if p ~= page then p.Visible = false end end end)
    return btn
end

local MacroP = Instance.new("Frame", Container); MacroP.Size = UDim2.new(1, 0, 1, 0); MacroP.BackgroundTransparency = 1; MacroP.ZIndex = 6
local ParryP = Instance.new("Frame", Container); ParryP.Size = UDim2.new(1, 0, 1, 0); ParryP.BackgroundTransparency = 1; ParryP.Visible = false; ParryP.ZIndex = 6
CreateTab("STEALTH CORE", 70, MacroP); CreateTab("SYSTEM PARRY", 120, ParryP)

-- MACRO UI (ENLARGED)
local SpeedLbl = Instance.new("TextLabel", MacroP); SpeedLbl.Size = UDim2.new(1, 0, 0, 40); SpeedLbl.Text = "10 KPS"; SpeedLbl.TextColor3 = Color3.fromRGB(255, 255, 255); SpeedLbl.BackgroundTransparency = 1; SpeedLbl.Font = Enum.Font.Michroma; SpeedLbl.TextSize = 18
local Slider = Instance.new("Frame", MacroP); Slider.Size = UDim2.new(0.95, 0, 0, 4); Slider.Position = UDim2.new(0.025, 0, 0.3, 0); Slider.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Slider.BorderSizePixel = 0
local Fill = Instance.new("Frame", Slider); Fill.Size = UDim2.new(0.01, 0, 1, 0); Fill.BackgroundColor3 = Color3.fromRGB(0, 180, 255); Fill.BorderSizePixel = 0
local Dot = Instance.new("TextButton", Slider); Dot.Size = UDim2.new(0, 18, 0, 18); Dot.Position = UDim2.new(0, -9, 0.5, -9); Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Dot.Text = ""; Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

-- KEYBIND TOGGLE LABELED
local ModeLbl = Instance.new("TextLabel", MacroP); ModeLbl.Size = UDim2.new(0, 100, 0, 20); ModeLbl.Position = UDim2.new(0, 0, 0.45, 0); ModeLbl.Text = "KEYBIND MODE"; ModeLbl.TextColor3 = Color3.fromRGB(150, 150, 160); ModeLbl.BackgroundTransparency = 1; ModeLbl.Font = Enum.Font.Michroma; ModeLbl.TextSize = 8; ModeLbl.TextXAlignment = Enum.TextXAlignment.Left
local SwFrame = Instance.new("Frame", MacroP); SwFrame.Size = UDim2.new(0, 50, 0, 26); SwFrame.Position = UDim2.new(0.7, 0, 0.45, 0); SwFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Instance.new("UICorner", SwFrame).CornerRadius = UDim.new(1, 0)
local SwThumb = Instance.new("Frame", SwFrame); SwThumb.Size = UDim2.new(0, 22, 0, 22); SwThumb.Position = UDim2.new(0, 2, 0.5, -11); SwThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", SwThumb).CornerRadius = UDim.new(1, 0)
local SwBtn = Instance.new("TextButton", SwFrame); SwBtn.Size = UDim2.new(1, 0, 1, 0); SwBtn.BackgroundTransparency = 1; SwBtn.Text = ""

local Bind = Instance.new("TextButton", MacroP); Bind.Size = UDim2.new(1, 0, 0, 45); Bind.Position = UDim2.new(0, 0, 0.75, 0); Bind.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Bind.Text = "BIND: F9"; Bind.TextColor3 = Color3.fromRGB(255, 255, 255); Bind.Font = Enum.Font.Michroma; Bind.TextSize = 12; Instance.new("UICorner", Bind).CornerRadius = UDim.new(0, 12)

-- PARRY UI LABELED
local PStatus = Instance.new("TextLabel", ParryP); PStatus.Size = UDim2.new(1, 0, 0, 40); PStatus.Position = UDim2.new(0,0,0.2,0); PStatus.Text = "AUTO-PARRY SYSTEM"; PStatus.TextColor3 = Color3.fromRGB(150, 150, 160); PStatus.BackgroundTransparency = 1; PStatus.Font = Enum.Font.Michroma; PStatus.TextSize = 12
local PModeLbl = Instance.new("TextLabel", ParryP); PModeLbl.Size = UDim2.new(0, 100, 0, 20); PModeLbl.Position = UDim2.new(0.1, 0, 0.45, 0); PModeLbl.Text = "ENABLE"; PModeLbl.TextColor3 = Color3.fromRGB(150, 150, 160); PModeLbl.BackgroundTransparency = 1; PModeLbl.Font = Enum.Font.Michroma; PModeLbl.TextSize = 10
local PSwFrame = Instance.new("Frame", ParryP); PSwFrame.Size = UDim2.new(0, 56, 0, 30); PSwFrame.Position = UDim2.new(0.6, 0, 0.45, 0); PSwFrame.BackgroundColor3 = Color3.fromRGB(0, 180, 255); Instance.new("UICorner", PSwFrame).CornerRadius = UDim.new(1, 0)
local PSwThumb = Instance.new("Frame", PSwFrame); PSwThumb.Size = UDim2.new(0, 26, 0, 26); PSwThumb.Position = UDim2.new(1, -28, 0.5, -13); PSwThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", PSwThumb).CornerRadius = UDim.new(1, 0)
local PSwBtn = Instance.new("TextButton", PSwFrame); PSwBtn.Size = UDim2.new(1, 0, 1, 0); PSwBtn.BackgroundTransparency = 1; PSwBtn.Text = ""

-- LUXURY ACTIVATE BUTTON (LARGE)
local Act = Instance.new("TextButton", ScreenGui); Act.Size = UDim2.new(0, 180, 0, 65); Act.Position = UDim2.new(0.5, -90, 0.85, 0); Act.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Act.BackgroundTransparency = 0.9; Act.Text = "ACTIVATE"; Act.TextColor3 = Color3.fromRGB(255, 255, 255); Act.Font = Enum.Font.Michroma; Act.TextSize = 14; Act.Visible = false; Instance.new("UICorner", Act).CornerRadius = UDim.new(0, 16); MakeDraggable(Act)
local ActGlow = Instance.new("Frame", Act); ActGlow.Size = UDim2.new(1, 6, 1, 6); ActGlow.Position = UDim2.new(0,-3,0,-3); ActGlow.BackgroundColor3 = Color3.fromRGB(0, 180, 255); ActGlow.BackgroundTransparency = 0.8; ActGlow.ZIndex = -1; Instance.new("UICorner", ActGlow).CornerRadius = UDim.new(0, 18)

-- [[ PRO LOGIC SYNC ]]
local function UpdateUI()
    Act.Text = EngineState.MacroToggle and "HALT CORE" or "INITIALIZE CORE"
    SpeedLbl.Text = EngineState.TargetSpeed .. " KPS"
    Bind.Text = "BIND: " .. EngineState.ToggleKey.Name
    local p = EngineState.AutoParryActive; TweenService:Create(PSwThumb, TweenInfo.new(0.3), {Position = p and UDim2.new(1, -28, 0.5, -13) or UDim2.new(0, 2, 0.5, -13)}):Play(); TweenService:Create(PSwFrame, TweenInfo.new(0.3), {BackgroundColor3 = p and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(30, 30, 35)}):Play()
    local k = (EngineState.InputMode == "Keybind"); TweenService:Create(SwThumb, TweenInfo.new(0.3), {Position = k and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)}):Play(); TweenService:Create(SwFrame, TweenInfo.new(0.3), {BackgroundColor3 = k and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(30, 30, 35)}):Play(); Act.Visible = (EngineState.InputMode == "Button") and Sidebar.Visible
end

local function Toggle()
    EngineState.MacroToggle = not EngineState.MacroToggle; UpdateUI()
    if EngineState.MacroToggle then MacroConnection = RunService.PreRender:Connect(ExecuteStealthInput) elseif MacroConnection then MacroConnection:Disconnect() end
end

SwBtn.MouseButton1Click:Connect(function() EngineState.InputMode = (EngineState.InputMode == "Keybind") and "Button" or "Keybind"; EngineState.MacroToggle = false; UpdateUI() end)
Act.MouseButton1Click:Connect(Toggle); PSwBtn.MouseButton1Click:Connect(function() EngineState.AutoParryActive = not EngineState.AutoParryActive; UpdateUI() end)

local listen = false
Bind.MouseButton1Click:Connect(function() listen = true; Bind.Text = "WAITING..." end)
UserInputService.InputBegan:Connect(function(i, g)
    if listen and i.UserInputType == Enum.UserInputType.Keyboard then EngineState.ToggleKey = i.KeyCode; listen = false; UpdateUI()
    elseif not g and EngineState.InputMode == "Keybind" and i.KeyCode == EngineState.ToggleKey then Toggle() end
end)

local dragging = false
Dot.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.Position.X) then
        local frac = math.clamp((i.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1)
        EngineState.TargetSpeed = math.round(1 + (frac * 2499)); Fill.Size = UDim2.new(frac, 0, 1, 0); Dot.Position = UDim2.new(frac, -9, 0.5, -9); UpdateUI()
    end
end)

Submit.MouseButton1Click:Connect(function()
    if IsKeyValid(KeyInput.Text) then
        Auth.Visible = false
        TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 520, 0, 320), Position = UDim2.new(0.5, -260, 0.5, -160)}):Play()
        task.wait(0.7); Sidebar.Visible = true; Container.Visible = true; UpdateUI()
        if _G.StartParry then _G.StartParry() end
    end
end)

UpdateUI()
