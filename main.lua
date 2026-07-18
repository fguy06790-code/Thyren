-- =============================================================================
-- GRAPHITE GRAY MACRO + DEFENSE DASHBOARD (SAFE GITHUB VERSION)
-- =============================================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

-- ENGINE STATE
local EngineState = {
    IsRunning = false,
    TargetSpeed = 10,
    ModeSelection = "KPS",
    ActivationMode = "Manual Spam",
    RuntimeHotkey = nil,
    IsBinding = false,
    AutoParryActive = false,
    SpamKey = Enum.KeyCode.F,
    Collapsed = false,
    LowEndMode = false
}

-- SAFE UI ROOT
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GraphiteMacroUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- UTILS
local function ApplyRadius(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
end

local function fireParry()
    VirtualInputManager:SendKeyEvent(true, EngineState.SpamKey, false, game)
    VirtualInputManager:SendKeyEvent(false, EngineState.SpamKey, false, game)

    task.defer(function()
        VirtualInputManager:SendKeyEvent(true, EngineState.SpamKey, false, game)
        VirtualInputManager:SendKeyEvent(false, EngineState.SpamKey, false, game)
    end)

    task.spawn(function()
        task.wait(0.0005)
        VirtualInputManager:SendKeyEvent(true, EngineState.SpamKey, false, game)
        VirtualInputManager:SendKeyEvent(false, EngineState.SpamKey, false, game)
    end)
end

-- BALL SCANNER
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

-- MACRO ENGINE
local MacroConnection = nil
local lastFire = 0

local function RunMacro()
    if not EngineState.IsRunning then return end

    local speed = EngineState.TargetSpeed
    local key = EngineState.SpamKey

    if speed >= 60 then
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    else
        local now = os.clock()
        if now - lastFire >= 1 / speed then
            lastFire = now
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end
    end
end

local function StartMacro()
    EngineState.IsRunning = true
    lastFire = os.clock()
    if MacroConnection then MacroConnection:Disconnect() end
    MacroConnection = RunService.PreRender:Connect(RunMacro)
end

local function StopMacro()
    EngineState.IsRunning = false
    if MacroConnection then MacroConnection:Disconnect() end
end

local function ToggleMacro()
    if EngineState.IsRunning then StopMacro() else StartMacro() end
end
-- ADVANCED AUTO PARRY
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

        local Ping = 0.08
        pcall(function()
            Ping = StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
        end)

        local id = ball:GetDebugId()
        if parried_balls[id] then return end

        local Zoomies = ball:FindFirstChild("zoomies")
        local shouldParry = false

        if Zoomies then
            local Vel = Zoomies.VectorVelocity
            local Dir = (hrp.Position - ball.Position).Unit
            local Dot = Dir:Dot(Vel.Unit)

            if AntiCurve then
                if dist <= ParryDist then shouldParry = true end
            else
                if Dot >= (0.15 - Ping * 0.3) then
                    local threshold = speed * (Ping + 0.016) * 3
                    if dist <= threshold or dist <= ParryDist then
                        shouldParry = true
                    end
                end
            end
        else
            if dist <= ParryDist and speed > 0.5 then
                shouldParry = true
            end
        end

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
-- ============================
-- SAFE UI CREATION (STAGED)
-- ============================

local MainFrame
local ModeBtn
local SwitchContainer
local SliderTrack
local SliderFill
local SliderButton
local SpeedDisplay
local ParryBtn
local DiagPanel
local DiagMacroLabel
local DiagKeyLabel
local DiagParryLabel
local ActionButton
local StatusBar

task.wait(0.1)

-- MAIN FRAME
MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 500, 0, 360)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.Parent = ScreenGui
ApplyRadius(MainFrame, 8)

task.wait(0.05)

-- TITLE
local TitleLabel = Instance.new("TextButton")
TitleLabel.Size = UDim2.new(0, 200, 0, 40)
TitleLabel.Position = UDim2.new(0, 20, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "GRAPHITE CORE"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
TitleLabel.Font = Enum.Font.Michroma
TitleLabel.TextSize = 18
TitleLabel.Parent = MainFrame

task.wait(0.05)

-- MODE BUTTON
ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0, 200, 0, 40)
ModeBtn.Position = UDim2.new(0, 20, 0, 60)
ModeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
ModeBtn.Text = "MODE: KPS"
ModeBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
ModeBtn.Font = Enum.Font.Michroma
ModeBtn.TextSize = 14
ModeBtn.Parent = MainFrame
ApplyRadius(ModeBtn, 6)

task.wait(0.05)

-- KEYBIND SWITCH
SwitchContainer = Instance.new("Frame")
SwitchContainer.Size = UDim2.new(0, 200, 0, 40)
SwitchContainer.Position = UDim2.new(0, 20, 0, 110)
SwitchContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
SwitchContainer.Parent = MainFrame
ApplyRadius(SwitchContainer, 6)

local SwitchLabel = Instance.new("TextLabel")
SwitchLabel.Size = UDim2.new(0, 120, 1, 0)
SwitchLabel.Position = UDim2.new(0, 10, 0, 0)
SwitchLabel.BackgroundTransparency = 1
SwitchLabel.Text = "KEYBIND"
SwitchLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
SwitchLabel.Font = Enum.Font.Michroma
SwitchLabel.TextSize = 12
SwitchLabel.Parent = SwitchContainer

local ToggleTrack = Instance.new("TextButton")
ToggleTrack.Size = UDim2.new(0, 40, 0, 22)
ToggleTrack.Position = UDim2.new(1, -50, 0.5, -11)
ToggleTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ToggleTrack.Text = ""
ToggleTrack.Parent = SwitchContainer
ApplyRadius(ToggleTrack, 11)

local ToggleThumb = Instance.new("Frame")
ToggleThumb.Size = UDim2.new(0, 18, 0, 18)
ToggleThumb.Position = UDim2.new(0, 2, 0.5, -9)
ToggleThumb.BackgroundColor3 = Color3.fromRGB(230, 230, 235)
ToggleThumb.Parent = ToggleTrack
ApplyRadius(ToggleThumb, 9)

task.wait(0.05)

-- SLIDER
SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(0, 300, 0, 6)
SliderTrack.Position = UDim2.new(0, 20, 0, 160)
SliderTrack.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
SliderTrack.Parent = MainFrame
ApplyRadius(SliderTrack, 3)

SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.01, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
SliderFill.Parent = SliderTrack
ApplyRadius(SliderFill, 3)

SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 14, 0, 14)
SliderButton.Position = UDim2.new(0.01, -7, 0.5, -7)
SliderButton.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
SliderButton.Text = ""
SliderButton.Parent = SliderTrack
ApplyRadius(SliderButton, 7)

SpeedDisplay = Instance.new("TextLabel")
SpeedDisplay.Size = UDim2.new(0, 120, 0, 30)
SpeedDisplay.Position = UDim2.new(0, 330, 0, 150)
SpeedDisplay.BackgroundTransparency = 1
SpeedDisplay.Text = "10 KPS"
SpeedDisplay.TextColor3 = Color3.fromRGB(200, 200, 210)
SpeedDisplay.Font = Enum.Font.Michroma
SpeedDisplay.TextSize = 14
SpeedDisplay.Parent = MainFrame
-- AUTO PARRY BUTTON
ParryBtn = Instance.new("TextButton")
ParryBtn.Size = UDim2.new(0, 300, 0, 40)
ParryBtn.Position = UDim2.new(0, 20, 0, 210)
ParryBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
ParryBtn.Text = "AUTO PARRY: DISABLED"
ParryBtn.TextColor3 = Color3.fromRGB(190, 190, 200)
ParryBtn.Font = Enum.Font.Michroma
ParryBtn.TextSize = 14
ParryBtn.Parent = MainFrame
ApplyRadius(ParryBtn, 6)

task.wait(0.05)

-- DIAGNOSTICS PANEL
DiagPanel = Instance.new("Frame")
DiagPanel.Size = UDim2.new(0, 300, 0, 100)
DiagPanel.Position = UDim2.new(0, 20, 0, 260)
DiagPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
DiagPanel.Parent = MainFrame
ApplyRadius(DiagPanel, 6)

local DiagHeader = Instance.new("TextLabel")
DiagHeader.Size = UDim2.new(1, 0, 0, 20)
DiagHeader.BackgroundTransparency = 1
DiagHeader.Text = "SYSTEM LOGS"
DiagHeader.TextColor3 = Color3.fromRGB(220, 220, 230)
DiagHeader.Font = Enum.Font.Michroma
DiagHeader.TextSize = 12
DiagHeader.Parent = DiagPanel

DiagMacroLabel = Instance.new("TextLabel")
DiagMacroLabel.Size = UDim2.new(1, -10, 0, 20)
DiagMacroLabel.Position = UDim2.new(0, 10, 0, 25)
DiagMacroLabel.BackgroundTransparency = 1
DiagMacroLabel.Text = "STATUS: STANDBY"
DiagMacroLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
DiagMacroLabel.Font = Enum.Font.Michroma
DiagMacroLabel.TextSize = 11
DiagMacroLabel.Parent = DiagPanel

DiagKeyLabel = Instance.new("TextLabel")
DiagKeyLabel.Size = UDim2.new(1, -10, 0, 20)
DiagKeyLabel.Position = UDim2.new(0, 10, 0, 45)
DiagKeyLabel.BackgroundTransparency = 1
DiagKeyLabel.Text = "BIND REGISTER: NONE"
DiagKeyLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
DiagKeyLabel.Font = Enum.Font.Michroma
DiagKeyLabel.TextSize = 11
DiagKeyLabel.Parent = DiagPanel

DiagParryLabel = Instance.new("TextLabel")
DiagParryLabel.Size = UDim2.new(1, -10, 0, 20)
DiagParryLabel.Position = UDim2.new(0, 10, 0, 65)
DiagParryLabel.BackgroundTransparency = 1
DiagParryLabel.Text = "DEFENSE MATRIX: DISENGAGED"
DiagParryLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
DiagParryLabel.Font = Enum.Font.Michroma
DiagParryLabel.TextSize = 11
DiagParryLabel.Parent = DiagPanel

task.wait(0.05)

-- CONTROL POD
ActionButton = Instance.new("TextButton")
ActionButton.Size = UDim2.new(0, 200, 0, 40)
ActionButton.Position = UDim2.new(0, 20, 0, 370)
ActionButton.BackgroundColor3 = Color3.fromRGB(110, 110, 125)
ActionButton.Text = "ACTIVATE"
ActionButton.TextColor3 = Color3.fromRGB(240, 240, 245)
ActionButton.Font = Enum.Font.Michroma
ActionButton.TextSize = 15
ActionButton.Parent = ScreenGui
ApplyRadius(ActionButton, 6)

StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(0, 200, 0, 20)
StatusBar.Position = UDim2.new(0, 20, 0, 415)
StatusBar.BackgroundTransparency = 1
StatusBar.Text = "WORKFLOW IDLE"
StatusBar.TextColor3 = Color3.fromRGB(180, 180, 190)
StatusBar.Font = Enum.Font.Michroma
StatusBar.TextSize = 12
StatusBar.Parent = ScreenGui

-- ============================
-- UI LOGIC
-- ============================

local function UpdateUI()
    SpeedDisplay.Text = EngineState.TargetSpeed .. " KPS"

    if EngineState.IsRunning then
        ActionButton.Text = "HALT CORE"
        ActionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 95)
        StatusBar.Text = "MACRO FIRING"
        DiagMacroLabel.Text = "STATUS: RUNNING CORE"
    else
        ActionButton.Text = "ACTIVATE"
        ActionButton.BackgroundColor3 = Color3.fromRGB(110, 110, 125)
        StatusBar.Text = "WORKFLOW IDLE"
        DiagMacroLabel.Text = "STATUS: STANDBY"
    end
end

-- MODE SWITCH
ModeBtn.MouseButton1Click:Connect(function()
    EngineState.ModeSelection = (EngineState.ModeSelection == "KPS") and "CPS" or "KPS"
    ModeBtn.Text = "MODE: " .. EngineState.ModeSelection
end)
-- KEYBIND SWITCH
ToggleTrack.MouseButton1Click:Connect(function()
    EngineState.IsBinding = true
    SwitchLabel.Text = "PRESS KEY"
end)

UserInputService.InputBegan:Connect(function(input)
    if EngineState.IsBinding then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            EngineState.RuntimeHotkey = input.KeyCode
            EngineState.IsBinding = false
            SwitchLabel.Text = "[" .. input.KeyCode.Name .. "]"
            DiagKeyLabel.Text = "BIND REGISTER: [" .. input.KeyCode.Name .. "]"
        end
        return
    end

    if EngineState.RuntimeHotkey and input.KeyCode == EngineState.RuntimeHotkey then
        ToggleMacro()
        UpdateUI()
    end
end)

-- SLIDER DRAGGING
local dragging = false

SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
    end
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

        SpeedDisplay.Text = calculated .. " KPS"
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- AUTO PARRY BUTTON
ParryBtn.MouseButton1Click:Connect(function()
    EngineState.AutoParryActive = not EngineState.AutoParryActive

    if EngineState.AutoParryActive then
        ParryBtn.Text = "AUTO PARRY: ACTIVE"
        ParryBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
        DiagParryLabel.Text = "DEFENSE MATRIX: ACTIVE"
        DiagParryLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
        StartParry()
    else
        ParryBtn.Text = "AUTO PARRY: DISABLED"
        ParryBtn.TextColor3 = Color3.fromRGB(190, 190, 200)
        DiagParryLabel.Text = "DEFENSE MATRIX: DISENGAGED"
        DiagParryLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
        StopParry()
    end
end)

-- MACRO BUTTON
ActionButton.MouseButton1Click:Connect(function()
    ToggleMacro()
    UpdateUI()
end)

-- FINAL UI UPDATE
UpdateUI()

