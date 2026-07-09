-- =============================================================================
-- THYREN PRO ELITE (PART 1 OF 2)
-- CORE: KERNEL-LEVEL HID SIMULATION & BLADE BALL STEALTH
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

-- Localizing globals for high-speed upvalue protection
local sendKeyEvent = VirtualInputManager.SendKeyEvent
local osClock = os.clock
local mathRandom = math.random
local MacroConnection = nil

-- [[ 3. BLADE BALL ANTI-DETECTION ENGINE ]]
local function ExecuteHIDInput()
    if not EngineState.MacroToggle then return end
    
    local targetSpeed = EngineState.TargetSpeed
    local currentTime = osClock()
    
    -- HEURISTIC PATTERN BREAKER
    local timingVariance = (mathRandom(-150, 150) / 1000000) 
    local baseDelay = (1.0 / targetSpeed)
    
    if (currentTime - EngineState.LastFireTime) >= (baseDelay + timingVariance) then
        EngineState.LastFireTime = currentTime
        
        -- HID SIGNAL: Pressed
        sendKeyEvent(VirtualInputManager, true, EngineState.ActionKey, false, game)
        
        -- HARDWARE SWITCH EMULATION (1.2ms - 3.5ms hold time)
        task.wait(mathRandom(12, 35) / 10000) 
        
        -- HID SIGNAL: Released
        sendKeyEvent(VirtualInputManager, false, EngineState.ActionKey, false, game)
    end
end

-- [[ 4. BLADE BALL UNIVERSAL P-SYSTEM ]]
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
            if dist <= (EngineState.ParryThreshold + (vel * 0.125)) then 
                sendKeyEvent(VirtualInputManager, true, EngineState.ActionKey, false, game)
                sendKeyEvent(VirtualInputManager, false, EngineState.ActionKey, false, game)
            end
        end
    end)
end
-- =============================================================================
-- THYREN PRO ULTIMATE (PART 2 OF 2) - FIXED SLIDER BUILD
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
Main.Size = UDim2.new(0, 320, 0, 180); Main.Position = UDim2.new(0.5, -160, 0.5, -90)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 12); Main.BorderSizePixel = 0; Main.Active = true; Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
MakeDraggable(Main)

local Glow = Instance.new("Frame", Main)
Glow.Size = UDim2.new(1, 0, 0, 1); Glow.BackgroundColor3 = Color3.fromRGB(0, 220, 255); Glow.BorderSizePixel = 0; Glow.ZIndex = 20; Glow.BackgroundTransparency = 0.4

-- [[ AUTH ]]
local Auth = Instance.new("Frame", Main); Auth.Size = UDim2.new(1, 0, 1, 0); Auth.BackgroundTransparency = 1; Auth.ZIndex = 50
local KeyInput = Instance.new("TextBox", Auth); KeyInput.Size = UDim2.new(0, 260, 0, 42); KeyInput.Position = UDim2.new(0.5, -130, 0.35, -21); KeyInput.BackgroundColor3 = Color3.fromRGB(5, 5, 7); KeyInput.TextColor3 = Color3.fromRGB(220, 220, 230); KeyInput.PlaceholderText = "MASTER ACCESS KEY"; KeyInput.Text = ""; KeyInput.Font = Enum.Font.Michroma; KeyInput.TextSize = 10; KeyInput.ZIndex = 51; Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 12)
local Submit = Instance.new("TextButton", Auth); Submit.Size = UDim2.new(0, 260, 0, 42); Submit.Position = UDim2.new(0.5, -130, 0.7, -21); Submit.BackgroundColor3 = Color3.fromRGB(0, 180, 255); Submit.Text = "AUTHENTICATE"; Submit.TextColor3 = Color3.fromRGB(255, 255, 255); Submit.Font = Enum.Font.Michroma; Submit.TextSize = 11; Submit.ZIndex = 51; Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 12)

-- [[ DASHBOARD ]]
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 140, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 18); Sidebar.Visible = false; Sidebar.ZIndex = 5; Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 16)
local SideTitle = Instance.new("TextLabel", Sidebar); SideTitle.Size = UDim2.new(1, 0, 0, 60); SideTitle.Text = "THYREN PRO"; SideTitle.TextColor3 = Color3.fromRGB(255, 255, 255); SideTitle.BackgroundTransparency = 1; SideTitle.Font = Enum.Font.Michroma; SideTitle.TextSize = 14; SideTitle.ZIndex = 6

local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -155, 1, -30); Container.Position = UDim2.new(0, 155, 0, 15); Container.BackgroundTransparency = 1; Container.Visible = false; Container.ZIndex = 5

local function CreateTab(name, pos, page)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(0.9, 0, 0, 40); btn.Position = UDim2.new(0.05, 0, 0, pos); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30); btn.Text = name; btn.TextColor3 = Color3.fromRGB(140, 140, 150); btn.Font = Enum.Font.Michroma; btn.TextSize = 8; btn.ZIndex = 6; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(function() page.Visible = true; for _,p in pairs(Container:GetChildren()) do if p ~= page then p.Visible = false end end end)
    return btn
end

local MacroP = Instance.new("Frame", Container); MacroP.Size = UDim2.new(1, 0, 1, 0); MacroP.BackgroundTransparency = 1; MacroP.ZIndex = 6
local ParryP = Instance.new("Frame", Container); ParryP.Size = UDim2.new(1, 0, 1, 0); ParryP.BackgroundTransparency = 1; ParryP.Visible = false; ParryP.ZIndex = 6
CreateTab("CORE MACRO", 70, MacroP); CreateTab("SYSTEM PARRY", 115, ParryP)

-- SLIDER (FIXED STICKING)
local SpeedLbl = Instance.new("TextLabel", MacroP); SpeedLbl.Size = UDim2.new(1, 0, 0, 30); SpeedLbl.Text = "10 KPS"; SpeedLbl.TextColor3 = Color3.fromRGB(255, 255, 255); SpeedLbl.BackgroundTransparency = 1; SpeedLbl.Font = Enum.Font.Michroma; SpeedLbl.TextSize = 14
local Slider = Instance.new("Frame", MacroP); Slider.Size = UDim2.new(0.95, 0, 0, 2); Slider.Position = UDim2.new(0.025, 0, 0.35, 0); Slider.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Slider.BorderSizePixel = 0
local Fill = Instance.new("Frame", Slider); Fill.Size = UDim2.new(0.01, 0, 1, 0); Fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255); Fill.BorderSizePixel = 0
local Dot = Instance.new("TextButton", Slider); Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, -7, 0.5, -7); Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Dot.Text = ""; Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local SwFrame = Instance.new("Frame", MacroP); SwFrame.Size = UDim2.new(0, 44, 0, 24); SwFrame.Position = UDim2.new(0.7, 0, 0.55, 0); SwFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Instance.new("UICorner", SwFrame).CornerRadius = UDim.new(1, 0)
local SwThumb = Instance.new("Frame", SwFrame); SwThumb.Size = UDim2.new(0, 20, 0, 20); SwThumb.Position = UDim2.new(0, 2, 0.5, -10); SwThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", SwThumb).CornerRadius = UDim.new(1, 0)
local SwBtn = Instance.new("TextButton", SwFrame); SwBtn.Size = UDim2.new(1, 0, 1, 0); SwBtn.BackgroundTransparency = 1; SwBtn.Text = ""

local Bind = Instance.new("TextButton", MacroP); Bind.Size = UDim2.new(1, 0, 0, 38); Bind.Position = UDim2.new(0, 0, 0.8, 0); Bind.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Bind.Text = "TOGGLE: F9"; Bind.TextColor3 = Color3.fromRGB(255, 255, 255); Bind.Font = Enum.Font.Michroma; Bind.TextSize = 10; Instance.new("UICorner", Bind).CornerRadius = UDim.new(0, 12)

-- FLOAT ACTIVATE
local Act = Instance.new("TextButton", ScreenGui); Act.Size = UDim2.new(0, 140, 0, 56); Act.Position = UDim2.new(0.5, -70, 0.88, 0); Act.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Act.BackgroundTransparency = 0.9; Act.Text = "ACTIVATE"; Act.TextColor3 = Color3.fromRGB(255, 255, 255); Act.Font = Enum.Font.Michroma; Act.TextSize = 10; Act.Visible = false; Instance.new("UICorner", Act).CornerRadius = UDim.new(0, 14); MakeDraggable(Act)

-- [[ PRO LOGIC ]]
local function UpdateUI()
    Act.Text = EngineState.MacroToggle and "SYSTEM HALT" or "ACTIVATE HID"
    SpeedLbl.Text = EngineState.TargetSpeed .. " KPS"
    Bind.Text = "TOGGLE BIND: " .. EngineState.ToggleKey.Name
    local isKey = (EngineState.InputMode == "Keybind"); TweenService:Create(SwThumb, TweenInfo.new(0.3), {Position = isKey and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}):Play(); TweenService:Create(SwFrame, TweenInfo.new(0.3), {BackgroundColor3 = isKey and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(30, 30, 35)}):Play(); Act.Visible = (EngineState.InputMode == "Button") and Sidebar.Visible
end

local function Toggle()
    EngineState.MacroToggle = not EngineState.MacroToggle; UpdateUI()
    if EngineState.MacroToggle then MacroConnection = RunService.PreRender:Connect(ExecuteHIDInput) elseif MacroConnection then MacroConnection:Disconnect() end
end

SwBtn.MouseButton1Click:Connect(function() EngineState.InputMode = (EngineState.InputMode == "Keybind") and "Button" or "Keybind"; EngineState.MacroToggle = false; UpdateUI() end)
Act.MouseButton1Click:Connect(Toggle)

local dragging = false
Dot.MouseButton1Down:Connect(function() dragging = true end)
-- GLOBAL LISTENER FIX: Mouse cursor will no longer stick to the slider
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
