-- =============================================================================
-- GRAPHITE MINIMAL PANEL (SUPER LAG-EFFICIENT)
-- =============================================================================

-- DELETE PREVIOUS INSTANCES
pcall(function()
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("GraphiteMinimalUI") then
        pg.GraphiteMinimalUI:Destroy()
    end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

-- ENGINE STATE
local EngineState = {
    IsRunning = false,
    TargetSpeed = 10,
    ModeSelection = "KPS",

    ToggleKey = Enum.KeyCode.G,   -- MACRO TOGGLE KEY
    SpamKey = Enum.KeyCode.F,     -- ALWAYS SPAM F

    IsBinding = false,
    AutoParryActive = false,
    LowEndMode = false
}

-- UI ROOT
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GraphiteMinimalUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local function ApplyRadius(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
end
local function fireParry()
    VirtualInputManager:SendKeyEvent(true, EngineState.SpamKey, false, nil)
    VirtualInputManager:SendKeyEvent(false, EngineState.SpamKey, false, nil)
end

local function FindBall()
    local folder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")
    if folder then
        for _, ball in ipairs(folder:GetChildren()) do
            if ball:GetAttribute("target") == LocalPlayer.Name then
                return ball
            end
        end
    end
    return nil
end

local AntiCurve = false
local ParryDist = 8
local parried_balls = {}

local function StartParry()
    if EngineState.ParryConnection then EngineState.ParryConnection:Disconnect() end

    EngineState.ParryConnection = RunService.PreSimulation:Connect(function()
        if not EngineState.AutoParryActive then return end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local ball = FindBall()
        if not ball then return end

        local dist = (ball.Position - hrp.Position).Magnitude
        local speed = ball.AssemblyLinearVelocity.Magnitude

        local Ping = StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000

        local id = ball:GetDebugId()
        if parried_balls[id] then return end

        local shouldParry = dist <= ParryDist and speed > 0.5

        if shouldParry then
            fireParry()
            parried_balls[id] = true

            task.spawn(function()
                ball:GetAttributeChangedSignal("target"):Wait()
                parried_balls[id] = nil
            end)
        end
    end)
end

local function StopParry()
    if EngineState.ParryConnection then
        EngineState.ParryConnection:Disconnect()
        EngineState.ParryConnection = nil
    end
end
-- UNIVERSAL MACRO ENGINE (SPAMS F USING VIM)
local MacroConnection = nil
local lastFire = 0

local function RunMacro()
    if not EngineState.IsRunning then return end

    local speed = EngineState.TargetSpeed
    local key = EngineState.SpamKey  -- ALWAYS F

    local now = os.clock()
    if now - lastFire >= 1 / speed then
        lastFire = now

        VirtualInputManager:SendKeyEvent(true, key, false, nil)
        VirtualInputManager:SendKeyEvent(false, key, false, nil)
    end
end

local function StartMacro()
    EngineState.IsRunning = true
    lastFire = os.clock()

    if MacroConnection then MacroConnection:Disconnect() end
    MacroConnection = RunService.Heartbeat:Connect(RunMacro)
end

local function StopMacro()
    EngineState.IsRunning = false
    if MacroConnection then MacroConnection:Disconnect() end
end

local function ToggleMacro()
    if EngineState.IsRunning then StopMacro() else StartMacro() end
end
local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 260, 0, 210)
Panel.Position = UDim2.new(0.5, -130, 0.5, -105)
Panel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Panel.Active = true
Panel.Draggable = true
Panel.Parent = ScreenGui
ApplyRadius(Panel, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 28)
Title.BackgroundTransparency = 1
Title.Text = "GRAPHITE PANEL"
Title.TextColor3 = Color3.fromRGB(220, 220, 230)
Title.Font = Enum.Font.Michroma
Title.TextSize = 16
Title.Parent = Panel

local MacroBtn = Instance.new("TextButton")
MacroBtn.Size = UDim2.new(1, -20, 0, 28)
MacroBtn.Position = UDim2.new(0, 10, 0, 35)
MacroBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
MacroBtn.Text = "MACRO: OFF"
MacroBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
MacroBtn.Font = Enum.Font.Michroma
MacroBtn.TextSize = 14
MacroBtn.Parent = Panel
ApplyRadius(MacroBtn, 6)

local BindBtn = Instance.new("TextButton")
BindBtn.Size = UDim2.new(1, -20, 0, 28)
BindBtn.Position = UDim2.new(0, 10, 0, 70)
BindBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
BindBtn.Text = "BIND KEY: [" .. EngineState.ToggleKey.Name .. "]"
BindBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
BindBtn.Font = Enum.Font.Michroma
BindBtn.TextSize = 14
BindBtn.Parent = Panel
ApplyRadius(BindBtn, 6)

local ParryBtn = Instance.new("TextButton")
ParryBtn.Size = UDim2.new(1, -20, 0, 28)
ParryBtn.Position = UDim2.new(0, 10, 0, 105)
ParryBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ParryBtn.Text = "AUTO PARRY: OFF"
ParryBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ParryBtn.Font = Enum.Font.Michroma
ParryBtn.TextSize = 14
ParryBtn.Parent = Panel
ApplyRadius(ParryBtn, 6)

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(1, -20, 0, 28)
ModeBtn.Position = UDim2.new(0, 10, 0, 140)
ModeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ModeBtn.Text = "MODE: KPS"
ModeBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ModeBtn.Font = Enum.Font.Michroma
ModeBtn.TextSize = 14
ModeBtn.Parent = Panel
ApplyRadius(ModeBtn, 6)
local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, -20, 0, 6)
SliderTrack.Position = UDim2.new(0, 10, 0, 175)
SliderTrack.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
SliderTrack.Parent = Panel
ApplyRadius(SliderTrack, 3)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.01, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
SliderFill.Parent = SliderTrack
ApplyRadius(SliderFill, 3)

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 14, 0, 14)
SliderButton.Position = UDim2.new(0.01, -7, 0.5, -7)
SliderButton.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
SliderButton.Text = ""
SliderButton.Parent = SliderTrack
ApplyRadius(SliderButton, 7)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, 0, 0, 20)
SpeedLabel.Position = UDim2.new(0, 0, 0, 190)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "10 KPS"
SpeedLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
SpeedLabel.Font = Enum.Font.Michroma
SpeedLabel.TextSize = 14
SpeedLabel.Parent = Panel

-- UI LOGIC
local function UpdateUI()
    SpeedLabel.Text = EngineState.TargetSpeed .. " KPS"
    MacroBtn.Text = EngineState.IsRunning and "MACRO: ON" or "MACRO: OFF"
    ParryBtn.Text = EngineState.AutoParryActive and "AUTO PARRY: ON" or "AUTO PARRY: OFF"
    ModeBtn.Text = "MODE: " .. EngineState.ModeSelection
    BindBtn.Text = "BIND KEY: [" .. EngineState.ToggleKey.Name .. "]"
end

-- MACRO BUTTON
MacroBtn.MouseButton1Click:Connect(function()
    ToggleMacro()
    UpdateUI()
end)

-- AUTO PARRY BUTTON
ParryBtn.MouseButton1Click:Connect(function()
    EngineState.AutoParryActive = not EngineState.AutoParryActive
    if EngineState.AutoParryActive then StartParry() else StopParry() end
    UpdateUI()
end)

-- MODE BUTTON
ModeBtn.MouseButton1Click:Connect(function()
    EngineState.ModeSelection = (EngineState.ModeSelection == "KPS") and "CPS" or "KPS"
    UpdateUI()
end)

-- KEYBIND BUTTON
BindBtn.MouseButton1Click:Connect(function()
    EngineState.IsBinding = true
    BindBtn.Text = "PRESS ANY KEY..."
end)

-- IGNORE VIM INPUT
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end  -- IGNORE VIM INPUT

    if EngineState.IsBinding then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            EngineState.ToggleKey = input.KeyCode
            EngineState.IsBinding = false
            UpdateUI()
        end
        return
    end

    if input.KeyCode == EngineState.ToggleKey then
        ToggleMacro()
        UpdateUI()
    end
end)

-- SLIDER DRAGGING
local dragging = false

SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = input.Position.X
        local base = SliderTrack.AbsolutePosition.X
        local size = SliderTrack.AbsoluteSize.X

        local fraction = math.clamp((pos - base) / size, 0, 1)
        local maxLimit = EngineState.LowEndMode and 200 or 2500
        local calculated = math.floor(1 + (fraction * (maxLimit - 1)))

        EngineState.TargetSpeed = calculated
        SliderFill.Size = UDim2.new(fraction, 0, 1, 0)
        SliderButton.Position = UDim2.new(fraction, -7, 0.5, -7)

        SpeedLabel.Text = calculated .. " KPS"
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

UpdateUI()
