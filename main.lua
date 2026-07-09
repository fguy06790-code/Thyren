-- =============================================================================
-- THYREN ULTIMATE (PART 1 OF 2)
-- CORE: ULTRA-EFFICIENT STEALTH ENGINE
-- =============================================================================

local uiName = "Thyren_Pro_Final"
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
    InputMode = "Button", -- "Button" or "Keybind"
    AutoParryActive = true, 
    ParryThreshold = 45, 
    ActionKey = Enum.KeyCode.F,
    ToggleKey = Enum.KeyCode.F9, 
    LastFireTime = 0, 
    MacroToggle = false
}

local sendKeyEvent = VirtualInputManager.SendKeyEvent
local osClock = os.clock
local mathRandom = math.random
local MacroConnection = nil

-- [[ 3. HEURISTIC ANTI-DETECTION ENGINE ]]
local function ExecuteRawInput()
    if not EngineState.MacroToggle then return end
    
    local targetSpeed = EngineState.TargetSpeed
    local currentTime = osClock()
    
    -- Polymorphic Micro-Jitter (Breaks pattern recognition)
    local jitter = (mathRandom(-90, 90) / 1000000) 
    local baseDelay = (1.0 / targetSpeed)
    
    if (currentTime - EngineState.LastFireTime) >= (baseDelay + jitter) then
        EngineState.LastFireTime = currentTime
        
        -- Raw Action Signal (F)
        sendKeyEvent(VirtualInputManager, true, EngineState.ActionKey, false, game)
        -- Dynamic Hardware Hold-Time Simulation
        task.wait(mathRandom(12, 28) / 10000) 
        sendKeyEvent(VirtualInputManager, false, EngineState.ActionKey, false, game)
    end
end

-- [[ 4. PARRY LOGIC ]]
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
                sendKeyEvent(VirtualInputManager, true, EngineState.ActionKey, false, game)
                sendKeyEvent(VirtualInputManager, false, EngineState.ActionKey, false, game)
            end
        end
    end)
end
-- THYREN ULTIMATE (PART 2 OF 2) - THE "PRO" CLEAN DASHBOARD
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

-- [[ MAIN UI ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 300, 0, 160); Main.Position = UDim2.new(0.5, -150, 0.5, -80)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18); Main.BorderSizePixel = 0; Main.Active = true; Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
MakeDraggable(Main)

-- CLEAN ACCENT
local Accent = Instance.new("Frame", Main)
Accent.Size = UDim2.new(1, 0, 0, 2); Accent.BackgroundColor3 = Color3.fromRGB(0, 160, 255); Accent.BorderSizePixel = 0; Accent.ZIndex = 10

-- [[ AUTH OVERLAY ]]
local Auth = Instance.new("Frame", Main); Auth.Size = UDim2.new(1, 0, 1, 0); Auth.BackgroundTransparency = 1; Auth.ZIndex = 50
local KeyInput = Instance.new("TextBox", Auth); KeyInput.Size = UDim2.new(0, 240, 0, 35); KeyInput.Position = UDim2.new(0.5, -120, 0.35, -17); KeyInput.BackgroundColor3 = Color3.fromRGB(10, 10, 12); KeyInput.TextColor3 = Color3.fromRGB(200, 200, 210); KeyInput.PlaceholderText = "License Key..."; KeyInput.Text = ""; KeyInput.Font = Enum.Font.Michroma; KeyInput.TextSize = 10; KeyInput.ZIndex = 51; Instance.new("UICorner", KeyInput)
local Submit = Instance.new("TextButton", Auth); Submit.Size = UDim2.new(0, 240, 0, 35); Submit.Position = UDim2.new(0.5, -120, 0.7, -17); Submit.BackgroundColor3 = Color3.fromRGB(0, 160, 255); Submit.Text = "INITIALIZE"; Submit.TextColor3 = Color3.fromRGB(255, 255, 255); Submit.Font = Enum.Font.Michroma; Submit.TextSize = 10; Submit.ZIndex = 51; Instance.new("UICorner", Submit)

-- [[ DASHBOARD (HIDDEN) ]]
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 130, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 15); Sidebar.Visible = false; Sidebar.ZIndex = 5; Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 14)
local SideTitle = Instance.new("TextLabel", Sidebar); SideTitle.Size = UDim2.new(1, 0, 0, 50); SideTitle.Text = "THYREN"; SideTitle.TextColor3 = Color3.fromRGB(0, 160, 255); SideTitle.BackgroundTransparency = 1; SideTitle.Font = Enum.Font.Michroma; SideTitle.TextSize = 14; SideTitle.ZIndex = 6

local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -140, 1, -20); Container.Position = UDim2.new(0, 140, 0, 10); Container.BackgroundTransparency = 1; Container.Visible = false; Container.ZIndex = 5

local function CreateTab(name, pos, page)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(0.9, 0, 0, 35); btn.Position = UDim2.new(0.05, 0, 0, pos); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25); btn.Text = name; btn.TextColor3 = Color3.fromRGB(150, 150, 160); btn.Font = Enum.Font.Michroma; btn.TextSize = 8; btn.ZIndex = 6; Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(function() page.Visible = true; for _,p in pairs(Container:GetChildren()) do if p ~= page then p.Visible = false end end end)
    return btn
end

local MacroP = Instance.new("Frame", Container); MacroP.Size = UDim2.new(1, 0, 1, 0); MacroP.BackgroundTransparency = 1; MacroP.ZIndex = 6
local ParryP = Instance.new("Frame", Container); ParryP.Size = UDim2.new(1, 0, 1, 0); ParryP.BackgroundTransparency = 1; ParryP.Visible = false; ParryP.ZIndex = 6
CreateTab("MACRO", 60, MacroP); CreateTab("PARRY", 100, ParryP)

-- MACRO UI (ULTRA NEAT)
local SpeedLbl = Instance.new("TextLabel", MacroP); SpeedLbl.Size = UDim2.new(1, 0, 0, 30); SpeedLbl.Text = "10 KPS"; SpeedLbl.TextColor3 = Color3.fromRGB(255, 255, 255); SpeedLbl.BackgroundTransparency = 1; SpeedLbl.Font = Enum.Font.Michroma; SpeedLbl.TextSize = 12
local Slider = Instance.new("Frame", MacroP); Slider.Size = UDim2.new(0.9, 0, 0, 4); Slider.Position = UDim2.new(0.05, 0, 0.35, 0); Slider.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Slider.BorderSizePixel = 0
local Fill = Instance.new("Frame", Slider); Fill.Size = UDim2.new(0.01, 0, 1, 0); Fill.BackgroundColor3 = Color3.fromRGB(0, 160, 255); Fill.BorderSizePixel = 0
local Dot = Instance.new("TextButton", Slider); Dot.Size = UDim2.new(0, 12, 0, 12); Dot.Position = UDim2.new(0, -6, 0.5, -6); Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Dot.Text = ""; Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local SwFrame = Instance.new("Frame", MacroP); SwFrame.Size = UDim2.new(0, 40, 0, 22); SwFrame.Position = UDim2.new(0.7, 0, 0.55, 0); SwFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Instance.new("UICorner", SwFrame).CornerRadius = UDim.new(1, 0)
local SwThumb = Instance.new("Frame", SwFrame); SwThumb.Size = UDim2.new(0, 18, 0, 18); SwThumb.Position = UDim2.new(0, 2, 0.5, -9); SwThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", SwThumb).CornerRadius = UDim.new(1, 0)
local SwBtn = Instance.new("TextButton", SwFrame); SwBtn.Size = UDim2.new(1, 0, 1, 0); SwBtn.BackgroundTransparency = 1; SwBtn.Text = ""

local Bind = Instance.new("TextButton", MacroP); Bind.Size = UDim2.new(0.9, 0, 0, 30); Bind.Position = UDim2.new(0.05, 0, 0.8, 0); Bind.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Bind.Text = "TOGGLE: F9"; Bind.TextColor3 = Color3.fromRGB(200, 200, 210); Bind.Font = Enum.Font.Michroma; Bind.TextSize = 8; Instance.new("UICorner", Bind)

-- PARRY UI
local PLbl = Instance.new("TextLabel", ParryP); PLbl.Size = UDim2.new(1, 0, 0, 40); PLbl.Position = UDim2.new(0,0,0.2,0); PLbl.Text = "AUTO-PARRY ACTIVE"; PLbl.TextColor3 = Color3.fromRGB(180, 180, 190); PLbl.BackgroundTransparency = 1; PLbl.Font = Enum.Font.Michroma; PLbl.TextSize = 9
local PSwFrame = Instance.new("Frame", ParryP); PSwFrame.Size = UDim2.new(0, 40, 0, 22); PSwFrame.Position = UDim2.new(0.5, -20, 0.45, 0); PSwFrame.BackgroundColor3 = Color3.fromRGB(0, 160, 255); Instance.new("UICorner", PSwFrame).CornerRadius = UDim.new(1, 0)
local PSwThumb = Instance.new("Frame", PSwFrame); PSwThumb.Size = UDim2.new(0, 18, 0, 18); PSwThumb.Position = UDim2.new(1, -20, 0.5, -9); PSwThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", PSwThumb).CornerRadius = UDim.new(1, 0)
local PSwBtn = Instance.new("TextButton", PSwFrame); PSwBtn.Size = UDim2.new(1, 0, 1, 0); PSwBtn.BackgroundTransparency = 1; PSwBtn.Text = ""

-- FLOAT ACTIVATE
local Act = Instance.new("TextButton", ScreenGui); Act.Size = UDim2.new(0, 120, 0, 45); Act.Position = UDim2.new(0.5, -60, 0.9, 0); Act.BackgroundColor3 = Color3.fromRGB(0, 160, 255); Act.Text = "ACTIVATE"; Act.TextColor3 = Color3.fromRGB(255, 255, 255); Act.Font = Enum.Font.Michroma; Act.TextSize = 9; Act.Visible = false; Instance.new("UICorner", Act); MakeDraggable(Act)

-- [[ PRO SYNC LOGIC ]]
local function UpdateUI()
    Act.Text = EngineState.MacroToggle and "HALT" or "ACTIVATE"
    SpeedLbl.Text = EngineState.TargetSpeed .. " KPS"
    Bind.Text = "TOGGLE: " .. EngineState.ToggleKey.Name
    local p = EngineState.AutoParryActive; TweenService:Create(PSwThumb, TweenInfo.new(0.2), {Position = p and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play(); TweenService:Create(PSwFrame, TweenInfo.new(0.2), {BackgroundColor3 = p and Color3.fromRGB(0, 160, 255) or Color3.fromRGB(40, 40, 45)}):Play()
    local k = (EngineState.InputMode == "Keybind"); TweenService:Create(SwThumb, TweenInfo.new(0.2), {Position = k and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play(); TweenService:Create(SwFrame, TweenInfo.new(0.2), {BackgroundColor3 = k and Color3.fromRGB(0, 160, 255) or Color3.fromRGB(40, 40, 45)}):Play(); Act.Visible = (EngineState.InputMode == "Button")
end

local function Toggle()
    EngineState.MacroToggle = not EngineState.MacroToggle; UpdateUI()
    if EngineState.MacroToggle then MacroConnection = RunService.PreRender:Connect(ExecuteRawInput) elseif MacroConnection then MacroConnection:Disconnect() end
end

SwBtn.MouseButton1Click:Connect(function() EngineState.InputMode = (EngineState.InputMode == "Keybind") and "Button" or "Keybind"; EngineState.MacroToggle = false; UpdateUI() end)
Act.MouseButton1Click:Connect(Toggle); PSwBtn.MouseButton1Click:Connect(function() EngineState.AutoParryActive = not EngineState.AutoParryActive; UpdateUI() end)

local listen = false
Bind.MouseButton1Click:Connect(function() listen = true; Bind.Text = "..." end)
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
        EngineState.TargetSpeed = math.round(1 + (frac * 2499)); Fill.Size = UDim2.new(frac, 0, 1, 0); Dot.Position = UDim2.new(frac, -6, 0.5, -6); UpdateUI()
    end
end)

Submit.MouseButton1Click:Connect(function()
    if IsKeyValid(KeyInput.Text) then
        Auth.Visible = false
        TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 460, 0, 280), Position = UDim2.new(0.5, -230, 0.5, -140)}):Play()
        task.wait(0.6); Sidebar.Visible = true; Container.Visible = true; Act.Visible = (EngineState.InputMode == "Button")
        if _G.StartParry then _G.StartParry() end; UpdateUI()
    end
end)

UpdateUI()
