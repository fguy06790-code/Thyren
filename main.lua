-- =============================================================================
-- THYREN CONTROL PANEL (PING-SAFE + COLLAPSIBLE + CPS/KPS + VIM F)
-- =============================================================================

pcall(function()
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("ThyrenUI") then
        pg.ThyrenUI:Destroy()
    end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local EngineState = {
    IsRunning = false,
    TargetSpeed = 10, -- now supports up to 5000 safely
    ModeSelection = "KPS",
    ToggleKey = Enum.KeyCode.G,
    SpamKey = Enum.KeyCode.F,
    IsBinding = false,
    AutoParryActive = false,
    Collapsed = false
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThyrenUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local function Round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
end
local function FireParry()
    VIM:SendKeyEvent(true, EngineState.SpamKey, false, nil)
    VIM:SendKeyEvent(false, EngineState.SpamKey, false, nil)
end

local function GetBall()
    local folder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")
    if not folder then return nil end

    for _, ball in ipairs(folder:GetChildren()) do
        if ball:GetAttribute("target") == LocalPlayer.Name then
            return ball
        end
    end
    return nil
end

local ParryDist = 8
local parried = {}

local function StartParry()
    if EngineState.ParryConnection then EngineState.ParryConnection:Disconnect() end

    EngineState.ParryConnection = RS.PreSimulation:Connect(function()
        if not EngineState.AutoParryActive then return end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local ball = GetBall()
        if not ball then return end

        local id = ball:GetDebugId()
        if parried[id] then return end

        local dist = (ball.Position - hrp.Position).Magnitude
        local speed = ball.AssemblyLinearVelocity.Magnitude

        if dist <= ParryDist and speed > 0.5 then
            FireParry()
            parried[id] = true

            task.spawn(function()
                ball:GetAttributeChangedSignal("target"):Wait()
                parried[id] = nil
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
local MacroConnection = nil
local clickAccumulator = 0

-- Ping-safe limiter
local MAX_EVENTS_PER_HEARTBEAT = 40  -- prevents ping spikes

local function RunMacro(dt)
    if not EngineState.IsRunning then return end

    -- KPS MODE (1 click per tick)
    if EngineState.ModeSelection == "KPS" then
        VIM:SendKeyEvent(true, EngineState.SpamKey, false, nil)
        VIM:SendKeyEvent(false, EngineState.SpamKey, false, nil)
        return
    end

    -- CPS MODE (time-based accurate clicking)
    local cps = EngineState.TargetSpeed
    local clicksPerSecond = cps

    clickAccumulator += dt
    local expectedClicks = clicksPerSecond * clickAccumulator

    local eventsThisHeartbeat = 0

    while expectedClicks >= 1 do
        if eventsThisHeartbeat >= MAX_EVENTS_PER_HEARTBEAT then
            break -- prevents ping explosion
        end

        VIM:SendKeyEvent(true, EngineState.SpamKey, false, nil)
        VIM:SendKeyEvent(false, EngineState.SpamKey, false, nil)

        eventsThisHeartbeat += 1
        expectedClicks -= 1
        clickAccumulator -= (1 / clicksPerSecond)
    end
end

local function StartMacro()
    EngineState.IsRunning = true
    clickAccumulator = 0

    if MacroConnection then MacroConnection:Disconnect() end
    MacroConnection = RS.Heartbeat:Connect(RunMacro)
end

local function StopMacro()
    EngineState.IsRunning = false
    if MacroConnection then MacroConnection:Disconnect() end
end

local function ToggleMacro()
    if EngineState.IsRunning then StopMacro() else StartMacro() end
end
local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 420, 0, 300)
Panel.Position = UDim2.new(0.5, -210, 0.5, -150)
Panel.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Panel.Active = true
Panel.Draggable = true
Panel.Parent = ScreenGui
Round(Panel, 14)

local CollapseBtn = Instance.new("TextButton")
CollapseBtn.Size = UDim2.new(0, 40, 0, 40)
CollapseBtn.Position = UDim2.new(1, -50, 0, 0)
CollapseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
CollapseBtn.Text = "-"
CollapseBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
CollapseBtn.Font = Enum.Font.Michroma
CollapseBtn.TextSize = 24
CollapseBtn.Parent = Panel
Round(CollapseBtn, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "THYREN CONTROL PANEL"
Title.TextColor3 = Color3.fromRGB(230, 230, 240)
Title.Font = Enum.Font.Michroma
Title.TextSize = 22
Title.Parent = Panel

-- LEFT COLUMN
local MacroBtn = Instance.new("TextButton")
MacroBtn.Size = UDim2.new(0, 180, 0, 40)
MacroBtn.Position = UDim2.new(0, 20, 0, 60)
MacroBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
MacroBtn.Text = "MACRO: OFF"
MacroBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
MacroBtn.Font = Enum.Font.Michroma
MacroBtn.TextSize = 18
MacroBtn.Parent = Panel
Round(MacroBtn, 10)

local ParryBtn = Instance.new("TextButton")
ParryBtn.Size = UDim2.new(0, 180, 0, 40)
ParryBtn.Position = UDim2.new(0, 20, 0, 110)
ParryBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ParryBtn.Text = "AUTO PARRY: OFF"
ParryBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ParryBtn.Font = Enum.Font.Michroma
ParryBtn.TextSize = 18
ParryBtn.Parent = Panel
Round(ParryBtn, 10)

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 180, 0, 40)
ModeBtn.Position = UDim2.new(0, 20, 0, 160)
ModeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ModeBtn.Text = "MODE: KPS"
ModeBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ModeBtn.Font = Enum.Font.Michroma
ModeBtn.TextSize = 18
ModeBtn.Parent = Panel
Round(ModeBtn, 10)

local BindBtn = Instance.new("TextButton")
BindBtn.Size = UDim2.new(0, 180, 0, 40)
BindBtn.Position = UDim2.new(0, 20, 0, 210)
BindBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
BindBtn.Text = "BIND KEY: [" .. EngineState.ToggleKey.Name .. "]"
BindBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
BindBtn.Font = Enum.Font.Michroma
BindBtn.TextSize = 18
BindBtn.Parent = Panel
Round(BindBtn, 10)

-- RIGHT COLUMN
local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0, 180, 0, 40)
SpeedBox.Position = UDim2.new(0, 220, 0, 60)
SpeedBox.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
SpeedBox.Text = "10"
SpeedBox.PlaceholderText = "1 - 5000"
SpeedBox.TextColor3 = Color3.fromRGB(230, 230, 240)
SpeedBox.Font = Enum.Font.Michroma
SpeedBox.TextSize = 18
SpeedBox.Parent = Panel
Round(SpeedBox, 10)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 180, 0, 40)
SpeedLabel.Position = UDim2.new(0, 220, 0, 110)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "10 KPS"
SpeedLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
SpeedLabel.Font = Enum.Font.Michroma
SpeedLabel.TextSize = 18
SpeedLabel.Parent = Panel
local function UpdateUI()
    SpeedLabel.Text = EngineState.TargetSpeed .. " " .. EngineState.ModeSelection
    MacroBtn.Text = EngineState.IsRunning and "MACRO: ON" or "MACRO: OFF"
    ParryBtn.Text = EngineState.AutoParryActive and "AUTO PARRY: ON" or "AUTO PARRY: OFF"
    ModeBtn.Text = "MODE: " .. EngineState.ModeSelection
    BindBtn.Text = "BIND KEY: [" .. EngineState.ToggleKey.Name .. "]"
end

MacroBtn.MouseButton1Click:Connect(function()
    ToggleMacro()
    UpdateUI()
end)

ParryBtn.MouseButton1Click:Connect(function()
    EngineState.AutoParryActive = not EngineState.AutoParryActive
    if EngineState.AutoParryActive then StartParry() else StopParry() end
    UpdateUI()
end)

ModeBtn.MouseButton1Click:Connect(function()
    EngineState.ModeSelection = (EngineState.ModeSelection == "KPS") and "CPS" or "KPS"
    UpdateUI()
end)

BindBtn.MouseButton1Click:Connect(function()
    EngineState.IsBinding = true
    BindBtn.Text = "PRESS ANY KEY..."
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end

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

SpeedBox.FocusLost:Connect(function()
    local num = tonumber(SpeedBox.Text)
    if not num then return end

    num = math.clamp(num, 1, 5000)
    EngineState.TargetSpeed = num
    SpeedBox.Text = tostring(num)

    UpdateUI()
end)

CollapseBtn.MouseButton1Click:Connect(function()
    EngineState.Collapsed = not EngineState.Collapsed

    if EngineState.Collapsed then
        Panel:TweenSize(UDim2.new(0, 420, 0, 50), "Out", "Quad", 0.25, true)
        CollapseBtn.Text = "+"
    else
        Panel:TweenSize(UDim2.new(0, 420, 0, 300), "Out", "Quad", 0.25, true)
        CollapseBtn.Text = "-"
    end
end)

UpdateUI()
