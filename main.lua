-- =============================================================================
-- GRAPHITE RECTANGLE UI (CLEAN, LOW-LAG, TEXTBOX SPEED INPUT, VIM F)
-- =============================================================================

pcall(function()
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("GraphiteUI") then
        pg.GraphiteUI:Destroy()
    end
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Stats = game:GetService("Stats")

local EngineState = {
    IsRunning = false,
    TargetSpeed = 10,
    ModeSelection = "KPS",
    ToggleKey = Enum.KeyCode.G,
    SpamKey = Enum.KeyCode.F,
    IsBinding = false,
    AutoParryActive = false
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GraphiteUI"
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
local lastFire = 0

local function RunMacro()
    if not EngineState.IsRunning then return end

    local now = os.clock()
    if now - lastFire < 1/60 then return end
    lastFire = now

    if EngineState.ModeSelection == "KPS" then
        VIM:SendKeyEvent(true, EngineState.SpamKey, false, nil)
        VIM:SendKeyEvent(false, EngineState.SpamKey, false, nil)

    else
        local cps = EngineState.TargetSpeed
        local presses = math.clamp(math.floor(cps / 60), 1, 50)

        for i = 1, presses do
            VIM:SendKeyEvent(true, EngineState.SpamKey, false, nil)
            VIM:SendKeyEvent(false, EngineState.SpamKey, false, nil)
        end
    end
end

local function StartMacro()
    EngineState.IsRunning = true
    lastFire = os.clock()

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

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "GRAPHITE CONTROL PANEL"
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

-- RIGHT COLUMN (TEXTBOX SPEED INPUT)
local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0, 180, 0, 40)
SpeedBox.Position = UDim2.new(0, 220, 0, 60)
SpeedBox.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
SpeedBox.Text = "10"
SpeedBox.PlaceholderText = "1 - 2500"
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

    num = math.clamp(num, 1, 2500)
    EngineState.TargetSpeed = num
    SpeedBox.Text = tostring(num)

    UpdateUI()
end)

UpdateUI()
