-- =============================================================================
-- THYREN PRO ULTIMATE (PART 1 OF 2)
-- CORE: HID EMULATION & HEURISTIC STEALTH
-- =============================================================================

local uiName = "Thyren_Pro_Exhibition"
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

-- Localizing globals for upvalue protection
local sendKeyEvent = VirtualInputManager.SendKeyEvent
local osClock = os.clock
local mathRandom = math.random
local MacroConnection = nil

-- [[ 3. HID HARDWARE EMULATION ENGINE ]]
-- Simulates physical USB-HID packet behavior to bypass pattern detection
local function ExecuteHIDInput()
    if not EngineState.MacroToggle then return end
    
    local targetSpeed = EngineState.TargetSpeed
    local currentTime = osClock()
    
    -- Heuristic Pattern Breaker (Polymorphic Jitter)
    -- Varies by micro-increments to emulate human/hardware inconsistency
    local jitter = (mathRandom(-120, 120) / 1000000) 
    local baseDelay = (1.0 / targetSpeed)
    
    if (currentTime - EngineState.LastFireTime) >= (baseDelay + jitter) then
        EngineState.LastFireTime = currentTime
        
        -- HID State: Pressed (Simulating Kernel Interrupt)
        sendKeyEvent(VirtualInputManager, true, EngineState.ActionKey, false, game)
        
        -- HID Latency Emulation: Physical switch travel time
        task.wait(mathRandom(14, 32) / 10000) 
        
        -- HID State: Released
        sendKeyEvent(VirtualInputManager, false, EngineState.ActionKey, false, game)
    end
end

-- [[ 4. UNIVERSAL P-SYSTEM ]]
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
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local ball = FindActiveBall()
        
        if root and ball then 
            local dist = (ball.Position - root.Position).Magnitude
            local vel = ball.AssemblyLinearVelocity.Magnitude
            -- Dynamic calculation based on velocity buffer
            if dist <= (EngineState.ParryThreshold + (vel * 0.125)) then 
                sendKeyEvent(VirtualInputManager, true, EngineState.ActionKey, false, game)
                sendKeyEvent(VirtualInputManager, false, EngineState.ActionKey, false, game)
            end
        end
    end)
end
-- =============================================================================
-- THYREN PRO ULTIMATE (PART 2 OF 2) - LUXURY DARK EXHIBITION UI
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

-- [[ THE LUXURY CONTAINER ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 320, 0, 180); Main.Position = UDim2.new(0.5, -160, 0.5, -90)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12); Main.BorderSizePixel = 0; Main.Active = true; Main.ClipsDescendants = true
local MainCorner = Instance.new("UICorner", Main); MainCorner.CornerRadius = UDim.new(0, 16)
MakeDraggable(Main)

-- PRO GLOW ACCENT
local Glow = Instance.new("Frame", Main)
Glow.Size = UDim2.new(1, 0, 0, 1); Glow.BackgroundColor3 = Color3.fromRGB(0, 220, 255); Glow.BorderSizePixel = 0; Glow.ZIndex = 20; Glow.BackgroundTransparency = 0.4

-- OBSIDIAN SHADOW
local Shadow = Instance.new("ImageLabel", Main); Shadow.Size = UDim2.new(1, 80, 1, 80); Shadow.Position = UDim2.new(0, -40, 0, -40); Shadow.BackgroundTransparency = 1; Shadow.Image = "rbxassetid://6015667342"; Shadow.ImageColor3 = Color3.fromRGB(0,0,0); Shadow.ImageTransparency = 0.3; Shadow.ZIndex = 4

-- [[ INITIAL AUTH ]]
local Auth = Instance.new("Frame", Main); Auth.Size = UDim2.new(1, 0, 1, 0); Auth.BackgroundTransparency = 1; Auth.ZIndex = 50
local KeyInput = Instance.new("TextBox", Auth); KeyInput.Size = UDim2.new(0, 260, 0, 42); KeyInput.Position = UDim2.new(0.5, -130, 0.35, -21); KeyInput.BackgroundColor3 = Color3.fromRGB(5, 5, 7); KeyInput.TextColor3 = Color3.fromRGB(220, 220, 230); KeyInput.PlaceholderText = "MASTER ACCESS KEY"; KeyInput.Text = ""; KeyInput.Font = Enum.Font.Michroma; KeyInput.TextSize = 10; KeyInput.ZIndex = 51; Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 12)
local Submit = Instance.new("TextButton", Auth); Submit.Size = UDim2.new(0, 260, 0, 42); Submit.Position = UDim2.new(0.5, -130, 0.7, -21); Submit.BackgroundColor3 = Color3.fromRGB(0, 180, 255); Submit.Text = "AUTHENTICATE"; Submit.TextColor3 = Color3.fromRGB(255, 255, 255); Submit.Font = Enum.Font.Michroma; Submit.TextSize = 11; Submit.ZIndex = 51; Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 12)

-- [[ PRO SIDEBAR (ULTRA SLEEK) ]]
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 140, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 18); Sidebar.Visible = false; Sidebar.ZIndex = 5; Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 16)
local SideTitle = Instance.new("TextLabel", Sidebar); SideTitle.Size = UDim2.new(1, 0, 0, 60); SideTitle.Text = "THYREN PRO"; SideTitle.TextColor3 = Color3.fromRGB(255, 255, 255); SideTitle.BackgroundTransparency = 1; SideTitle.Font = Enum.Font.Michroma; SideTitle.TextSize = 14; SideTitle.ZIndex = 6

local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -155, 1, -30); Container.Position = UDim2.new(0, 155, 0, 15); Container.BackgroundTransparency = 1; Container.Visible = false; Container.ZIndex = 5

local function CreateTab(name, pos, page)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(0.9, 0, 0, 40); btn.Position = UDim2.new(0.05, 0, 0, pos); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); btn.Text = name; btn.TextColor3 = Color3.fromRGB(140, 140, 150); btn.Font = Enum.Font.Michroma; btn.TextSize = 8; btn.ZIndex = 6; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(function() 
        page.Visible = true; btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        for _,p in pairs(Container:GetChildren()) do if p ~= page then p.Visible = false end end 
    end)
    return btn
end

local MacroP = Instance.new("Frame", Container); MacroP.Size = UDim2.new(1, 0, 1, 0); MacroP.BackgroundTransparency = 1; MacroP.ZIndex = 6
local ParryP = Instance.new("Frame", Container); ParryP.Size = UDim2.new(1, 0, 1, 0); ParryP.BackgroundTransparency = 1; ParryP.Visible = false; ParryP.ZIndex = 6
CreateTab("CORE MACRO", 70, MacroP); CreateTab("SYSTEM PARRY", 115, ParryP)

-- CLEAN MACRO CONTROLS
local SpeedLbl = Instance.new("TextLabel", MacroP); SpeedLbl.Size = UDim2.new(1, 0, 0, 30); SpeedLbl.Text = "10 KPS"; SpeedLbl.TextColor3 = Color3.fromRGB(255, 255, 255); SpeedLbl.BackgroundTransparency = 1; SpeedLbl.Font = Enum.Font.Michroma; SpeedLbl.TextSize = 14
local Slider = Instance.new("Frame", MacroP); Slider.Size = UDim2.new(0.95, 0, 0, 2); Slider.Position = UDim2.new(0.025, 0, 0.35, 0); Slider.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Slider.BorderSizePixel = 0
local Fill = Instance.new("Frame", Slider); Fill.Size = UDim2.new(0.01, 0, 1, 0); Fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255); Fill.BorderSizePixel = 0
local Dot = Instance.new("TextButton", Slider); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, -7, 0.5, -7); Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Dot.Text = ""; Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local SwFrame = Instance.new("Frame", MacroP); SwFrame.Size = UDim2.new(0, 44, 0, 24); SwFrame.Position = UDim2.new(0.7, 0, 0.55, 0); SwFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Instance.new("UICorner", SwFrame).CornerRadius = UDim.new(1, 0)
local SwThumb = Instance.new("Frame", SwFrame); SwThumb.Size = UDim2.new(0, 20, 0, 20); SwThumb.Position = UDim2.new(0, 2, 0.5, -10); SwThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", SwThumb).CornerRadius = UDim.new(1, 0)
local SwBtn = Instance.new("TextButton", SwFrame); SwBtn.Size = UDim2.new(1, 0, 1, 0); SwBtn.BackgroundTransparency = 1; SwBtn.Text = ""

local Bind = Instance.new("TextButton", MacroP); Bind.Size = UDim2.new(1, 0, 0, 38); Bind.Position = UDim2.new(0, 0, 0.8, 0); Bind.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Bind.Text = "TOGGLE: F9"; Bind.TextColor3 = Color3.fromRGB(255, 255, 255); Bind.Font = Enum.Font.Michroma; Bind.TextSize = 10; Instance.new("UICorner", Bind).CornerRadius = UDim.new(0, 12)

-- SYSTEM PARRY UI
local PStatus = Instance.new("TextLabel", ParryP); PStatus.Size = UDim2.new(1, 0, 0, 40); PStatus.Position = UDim2.new(0,0,0.2,0); PStatus.Text = "PARRY SYSTEM"; PStatus.TextColor3 = Color3.fromRGB(150, 150, 160); PStatus.BackgroundTransparency = 1; PStatus.Font = Enum.Font.Michroma; PStatus.TextSize = 10
local PSwFrame = Instance.new("Frame", ParryP); PSwFrame.Size = UDim2.new(0, 50, 0, 26); PSwFrame.Position = UDim2.new(0.5, -25, 0.45, 0); PSwFrame.BackgroundColor3 = Color3.fromRGB(0, 180, 255); Instance.new("UICorner", PSwFrame).CornerRadius = UDim.new(1, 0)
local PSwThumb = Instance.new("Frame", PSwFrame); PSwThumb.Size = UDim2.new(0, 22, 0, 22); PSwThumb.Position = UDim2.new(1, -24, 0.5, -11); PSwThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", PSwThumb).CornerRadius = UDim.new(1, 0)
local PSwBtn = Instance.new("TextButton", PSwFrame); PSwBtn.Size = UDim2.new(1, 0, 1, 0); PSwBtn.BackgroundTransparency = 1; PSwBtn.Text = ""

-- LUXURY ACTIVATE BUTTON (GLASSMORPHISM)
local Act = Instance.new("TextButton", ScreenGui); Act.Size = UDim2.new(0, 140, 0, 56); Act.Position = UDim2.new(0.5, -70, 0.88, 0); Act.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Act.BackgroundTransparency = 0.9; Act.Text = "ACTIVATE"; Act.TextColor3 = Color3.fromRGB(255, 255, 255); Act.Font = Enum.Font.Michroma; Act.TextSize = 10; Act.Visible = false; Instance.new("UICorner", Act).CornerRadius = UDim.new(0, 14); MakeDraggable(Act)
local ActGlow = Instance.new("Frame", Act); ActGlow.Size = UDim2.new(1, 4, 1, 4); ActGlow.Position = UDim2.new(0,-2,0,-2); ActGlow.BackgroundColor3 = Color3.fromRGB(0, 180, 255); ActGlow.BackgroundTransparency = 0.8; ActGlow.ZIndex = -1; Instance.new("UICorner", ActGlow).CornerRadius = UDim.new(0, 16)

-- [[ PRO LOGIC SYNC ]]
local function UpdateUI()
    Act.Text = EngineState.MacroToggle and "SYSTEM HALT" or "INITIALIZE HID"
    SpeedLbl.Text = EngineState.TargetSpeed .. " KPS"
    Bind.Text = "TOGGLE BIND: " .. EngineState.ToggleKey.Name
    local p = EngineState.AutoParryActive; TweenService:Create(PSwThumb, TweenInfo.new(0.3), {Position = p and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)}):Play(); TweenService:Create(PSwFrame, TweenInfo.new(0.3), {BackgroundColor3 = p and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(30, 30, 35)}):Play()
    local k = (EngineState.InputMode == "Keybind"); TweenService:Create(SwThumb, TweenInfo.new(0.3), {Position = k and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}):Play(); TweenService:Create(SwFrame, TweenInfo.new(0.3), {BackgroundColor3 = k and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(30, 30, 35)}):Play(); Act.Visible = (EngineState.InputMode == "Button") and Sidebar.Visible
end

local function Toggle()
    EngineState.MacroToggle = not EngineState.MacroToggle; UpdateUI()
    if EngineState.MacroToggle then MacroConnection = RunService.PreRender:Connect(ExecuteHIDInput) elseif MacroConnection then MacroConnection:Disconnect() end
end

SwBtn.MouseButton1Click:Connect(function() EngineState.InputMode = (EngineState.InputMode == "Keybind") and "Button" or "Keybind"; EngineState.MacroToggle = false; UpdateUI() end)
Act.MouseButton1Click:Connect(Toggle); PSwBtn.MouseButton1Click:Connect(function() EngineState.AutoParryActive = not EngineState.AutoParryActive; UpdateUI() end)

local listen = false
Bind.MouseButton1Click:Connect(function() listen = true; Bind.Text = "LISTENING..." end)
UserInputService.InputBegan:Connect(function(i, g)
    if listen and i.UserInputType == Enum.UserInputType.Keyboard then EngineState.ToggleKey = i.KeyCode; listen = false; UpdateUI()
    elseif not g and EngineState.InputMode == "Keybind" and i.KeyCode == EngineState.ToggleKey then Toggle() end
end)

local dragging = false
Dot.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.Position.X) then
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
