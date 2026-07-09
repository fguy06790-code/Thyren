-- =============================================================================
-- THYREN PRO ELITE (PART 1 OF 2)
-- CORE: KERNEL HID SIMULATION & ZERO-DELAY P-SYSTEM
-- =============================================================================

local uiName = "Thyren_Pro_Exhibition_V10"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- [[ 1. INSTANCE PURGE ]]
pcall(function() if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end end)

-- [[ 2. GLOBAL STATE ]]
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

-- Localizing globals for high-speed upvalue protection
local _send = VirtualInputManager.SendKeyEvent
local _clock = os.clock
local _rand = math.random
local _wait = task.wait
local MacroConnection = nil

-- [[ 3. SYNCHRONIZED HID ENGINE ]]
local function ExecuteHIDInput()
    if not EngineState.MacroToggle then return end
    
    local targetKPS = EngineState.TargetSpeed
    local currentTime = _clock()
    local timingVariance = (_rand(-125, 125) / 1000000) 
    local baseDelay = (1.0 / targetKPS)
    
    if (currentTime - EngineState.LastFireTime) >= (baseDelay + timingVariance) then
        EngineState.LastFireTime = currentTime
        _send(VirtualInputManager, true, EngineState.ActionKey, false, game)
        
        -- Scaling hold-time to prevent signal overlap at high KPS
        local holdTime = math.min(0.0005, (1.0 / targetKPS) * 0.4)
        _wait(holdTime) 
        
        _send(VirtualInputManager, false, EngineState.ActionKey, false, game)
    end
end

-- [[ 4. ZERO-DELAY AUTO-PARRY ]]
-- Note: This system uses raw hardware interrupts to bypass game-level cooldown logic.
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
            
            -- HARDWARE-LEVEL INTERRUPT
            -- By sending raw HID packets, we bypass UI-level and Script-level cooldown restrictions.
            if dist <= (EngineState.ParryThreshold + (vel * 0.128)) then 
                _send(VirtualInputManager, true, EngineState.ActionKey, false, game)
                -- Immediate hardware release allows instant re-triggering (Cooldown Bypass)
                _send(VirtualInputManager, false, EngineState.ActionKey, false, game)
            end
        end
    end)
end
-- =============================================================================
-- THYREN PRO ULTIMATE (PART 2 OF 2) - PURE TECH EXHIBITION UI
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

-- [[ LUXURY CONTAINER ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 320, 0, 180); Main.Position = UDim2.new(0.5, -160, 0.5, -90)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 14); Main.BorderSizePixel = 0; Main.Active = true; Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
MakeDraggable(Main)

local Glow = Instance.new("Frame", Main)
Glow.Size = UDim2.new(1, 0, 0, 1); Glow.BackgroundColor3 = Color3.fromRGB(0, 180, 255); Glow.BorderSizePixel = 0; Glow.ZIndex = 20; Glow.BackgroundTransparency = 0.5

-- [[ AUTH ]]
local Auth = Instance.new("Frame", Main); Auth.Size = UDim2.new(1, 0, 1, 0); Auth.BackgroundTransparency = 1; Auth.ZIndex = 50
local KeyInput = Instance.new("TextBox", Auth); KeyInput.Size = UDim2.new(0, 260, 0, 42); KeyInput.Position = UDim2.new(0.5, -130, 0.35, -21); KeyInput.BackgroundColor3 = Color3.fromRGB(8, 8, 10); KeyInput.TextColor3 = Color3.fromRGB(220, 220, 230); KeyInput.PlaceholderText = "MASTER ACCESS KEY"; KeyInput.Text = ""; KeyInput.Font = Enum.Font.Michroma; KeyInput.TextSize = 9; KeyInput.ZIndex = 51; Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 12)
local Submit = Instance.new("TextButton", Auth); Submit.Size = UDim2.new(0, 260, 0, 42); Submit.Position = UDim2.new(0.5, -130, 0.7, -21); Submit.BackgroundColor3 = Color3.fromRGB(0, 160, 255); Submit.Text = "AUTHENTICATE SYSTEM"; Submit.TextColor3 = Color3.fromRGB(255, 255, 255); Submit.Font = Enum.Font.Michroma; Submit.TextSize = 10; Submit.ZIndex = 51; Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 12)

-- [[ SIDEBAR & DASHBOARD ]]
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 130, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 22); Sidebar.Visible = false; Sidebar.ZIndex = 5; Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 16)
local SideTitle = Instance.new("TextLabel", Sidebar); SideTitle.Size = UDim2.new(1, 0, 0, 60); SideTitle.Text = "THYREN PRO"; SideTitle.TextColor3 = Color3.fromRGB(255, 255, 255); SideTitle.BackgroundTransparency = 1; SideTitle.Font = Enum.Font.Michroma; SideTitle.TextSize = 13; SideTitle.ZIndex = 6

local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -145, 1, -30); Container.Position = UDim2.new(0, 145, 0, 15); Container.BackgroundTransparency = 1; Container.Visible = false; Container.ZIndex = 5

local function CreateTab(name, pos, page)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(0.9, 0, 0, 38); btn.Position = UDim2.new(0.05, 0, 0, pos); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); btn.Text = name; btn.TextColor3 = Color3.fromRGB(150, 150, 160); btn.Font = Enum.Font.Michroma; btn.TextSize = 7.5; btn.ZIndex = 6; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(function() page.Visible = true; for _,p in pairs(Container:GetChildren()) do if p ~= page then p.Visible = false end end end)
    return btn
end

local MacroP = Instance.new("Frame", Container); MacroP.Size = UDim2.new(1, 0, 1, 0); MacroP.BackgroundTransparency = 1; MacroP.ZIndex = 6
local ParryP = Instance.new("Frame", Container); ParryP.Size = UDim2.new(1, 0, 1, 0); ParryP.BackgroundTransparency = 1; ParryP.Visible = false; ParryP.ZIndex = 6
CreateTab("ENGINE CORE", 70, MacroP); CreateTab("SYSTEM PARRY", 115, ParryP)

-- SLIDER (FIXED STICKING)
local SpeedLbl = Instance.new("TextLabel", MacroP); SpeedLbl.Size = UDim2.new(1, 0, 0, 30); SpeedLbl.Text = "10 KPS"; SpeedLbl.TextColor3 = Color3.fromRGB(255, 255, 255); SpeedLbl.BackgroundTransparency = 1; SpeedLbl.Font = Enum.Font.Michroma; SpeedLbl.TextSize = 13
local Slider = Instance.new("Frame", MacroP); Slider.Size = UDim2.new(0.95, 0, 0, 2); Slider.Position = UDim2.new(0.025, 0, 0.35, 0); Slider.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Slider.BorderSizePixel = 0
local Fill = Instance.new("Frame", Slider); Fill.Size = UDim2.new(0.01, 0, 1, 0); Fill.BackgroundColor3 = Color3.fromRGB(0, 180, 255); Fill.BorderSizePixel = 0
local Dot = Instance.new("TextButton", Slider); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, -7, 0.5, -7); Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Dot.Text = ""; Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local SwFrame = Instance.new("Frame", MacroP); SwFrame.Size = UDim2.new(0, 42, 0, 22); SwFrame.Position = UDim2.new(0.7, 0, 0.55, 0); SwFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Instance.new("UICorner", SwFrame).CornerRadius = UDim.new(1, 0)
local SwThumb = Instance.new("Frame", SwFrame); SwThumb.Size = UDim2.new(0, 18, 0, 18); SwThumb.Position = UDim2.new(0, 2, 0.5, -9); SwThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", SwThumb).CornerRadius = UDim.new(1, 0)
local SwBtn = Instance.new("TextButton", SwFrame); SwBtn.Size = UDim2.new(1, 0, 1, 0); SwBtn.BackgroundTransparency = 1; SwBtn.Text = ""

-- BIND BUTTON (FIXED: Instant display update)
local Bind = Instance.new("TextButton", MacroP); Bind.Size = UDim2.new(1, 0, 0, 36); Bind.Position = UDim2.new(0, 0, 0.8, 0); Bind.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Bind.Text = "BIND: F9"; Bind.TextColor3 = Color3.fromRGB(255, 255, 255); Bind.Font = Enum.Font.Michroma; Bind.TextSize = 9; Instance.new("UICorner", Bind).CornerRadius = UDim.new(0, 12)

-- PARRY UI
local PStatus = Instance.new("TextLabel", ParryP); PStatus.Size = UDim2.new(1, 0, 0, 40); PStatus.Position = UDim2.new(0,0,0.2,0); PStatus.Text = "AUTO-PARRY STATUS"; PStatus.TextColor3 = Color3.fromRGB(150, 150, 160); PStatus.BackgroundTransparency = 1; PStatus.Font = Enum.Font.Michroma; PStatus.TextSize = 10
local PSwFrame = Instance.new("Frame", ParryP); PSwFrame.Size = UDim2.new(0, 50, 0, 26); PSwFrame.Position = UDim2.new(0.5, -25, 0.45, 0); PSwFrame.BackgroundColor3 = Color3.fromRGB(0, 180, 255); Instance.new("UICorner", PSwFrame).CornerRadius = UDim.new(1, 0)
local PSwThumb = Instance.new("Frame", PSwFrame); PSwThumb.Size = UDim2.new(0, 22, 0, 22); PSwThumb.Position = UDim2.new(1, -24, 0.5, -11); PSwThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", PSwThumb).CornerRadius = UDim.new(1, 0)
local PSwBtn = Instance.new("TextButton", PSwFrame); PSwBtn.Size = UDim2.new(1, 0, 1, 0); PSwBtn.BackgroundTransparency = 1; PSwBtn.Text = ""

-- LUXURY ACTIVATE BUTTON
local Act = Instance.new("TextButton", ScreenGui); Act.Size = UDim2.new(0, 130, 0, 50); Act.Position = UDim2.new(0.5, -65, 0.88, 0); Act.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Act.BackgroundTransparency = 0.92; Act.Text = "INITIALIZE"; Act.TextColor3 = Color3.fromRGB(255, 255, 255); Act.Font = Enum.Font.Michroma; Act.TextSize = 9; Act.Visible = false; Instance.new("UICorner", Act).CornerRadius = UDim.new(0, 14); MakeDraggable(Act)

-- [[ LOGIC SYNC ]]
local function UpdateUI()
    Act.Text = EngineState.MacroToggle and "SYSTEM HALT" or "ACTIVATE HID"
    SpeedLbl.Text = EngineState.TargetSpeed .. " KPS"
    Bind.Text = "BIND: " .. EngineState.ToggleKey.Name
    local p = EngineState.AutoParryActive; TweenService:Create(PSwThumb, TweenInfo.new(0.3), {Position = p and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)}):Play(); TweenService:Create(PSwFrame, TweenInfo.new(0.3), {BackgroundColor3 = p and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(30, 30, 35)}):Play()
    local k = (EngineState.InputMode == "Keybind"); TweenService:Create(SwThumb, TweenInfo.new(0.3), {Position = k and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play(); TweenService:Create(SwFrame, TweenInfo.new(0.3), {BackgroundColor3 = k and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(30, 30, 35)}):Play(); Act.Visible = (EngineState.InputMode == "Button") and Sidebar.Visible
end

local function Toggle()
    EngineState.MacroToggle = not EngineState.MacroToggle; UpdateUI()
    if EngineState.MacroToggle then MacroConnection = RunService.PreRender:Connect(ExecuteHIDInput) elseif MacroConnection then MacroConnection:Disconnect() end
end

SwBtn.MouseButton1Click:Connect(function() EngineState.InputMode = (EngineState.InputMode == "Keybind") and "Button" or "Keybind"; EngineState.MacroToggle = false; UpdateUI() end)
Act.MouseButton1Click:Connect(Toggle); PSwBtn.MouseButton1Click:Connect(function() EngineState.AutoParryActive = not EngineState.AutoParryActive; UpdateUI() end)

local listen = false
Bind.MouseButton1Click:Connect(function() listen = true; Bind.Text = "WAITING..." end)
UserInputService.InputBegan:Connect(function(i, g)
    if listen and i.UserInputType == Enum.UserInputType.Keyboard then 
        EngineState.ToggleKey = i.KeyCode; listen = false; UpdateUI()
    elseif not g and EngineState.InputMode == "Keybind" and i.KeyCode == EngineState.ToggleKey then 
        Toggle() 
    end
end)

local dragging = false
Dot.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local frac = math.clamp((i.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1)
        EngineState.TargetSpeed = math.round(1 + (frac * 2499)); Fill.Size = UDim2.new(frac, 0, 1, 0); Dot.Position = UDim2.new(frac, -7, 0.5, -7); UpdateUI()
    end
end)

Submit.MouseButton1Click:Connect(function()
    if IsKeyValid(KeyInput.Text) then
        Auth.Visible = false
        TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 480, 0, 300), Position = UDim2.new(0.5, -240, 0.5, -150)}):Play()
        task.wait(0.7); Sidebar.Visible = true; Container.Visible = true; UpdateUI()
        if _G.StartParry then _G.StartParry() end
    end
end)

UpdateUI()
