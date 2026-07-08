-- =============================================================================
-- THYREN BLADE BALL - GUARANTEED VISIBLE VERSION
-- =============================================================================

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Destroy old
pcall(function() game.CoreGui:FindFirstChild("ThyrenUI"):Destroy() end)
pcall(function() LocalPlayer.PlayerGui:FindFirstChild("ThyrenUI"):Destroy() end)

-- Create ScreenGui with ALL properties that help visibility
local Gui = Instance.new("ScreenGui")
Gui.Name = "ThyrenUI"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 9999
Gui.Enabled = true

-- Try PlayerGui first (most executors allow this)
local success, err = pcall(function()
    Gui.Parent = LocalPlayer.PlayerGui
end)

-- Fallback to CoreGui
if not success or not Gui.Parent then
    pcall(function()
        Gui.Parent = game.CoreGui
    end)
end

-- Final fallback - create a new folder in PlayerGui
if not Gui.Parent then
    local folder = Instance.new("Folder")
    folder.Parent = LocalPlayer.PlayerGui
    Gui.Parent = folder
end

-- If STILL not parented, something is very wrong - abort
if not Gui.Parent then
    return
end

-- =============================================================================
-- STATE
-- =============================================================================
local State = {
    Running = false,
    Speed = 10,
    Mode = "KPS",
    Activation = "Manual",
    Hotkey = nil,
    Binding = false,
    AutoParry = false,
    Threshold = 28,
    Predictive = true,
    Buffer = 0.05,
    Visible = true,
    Collapsed = false
}

local MacroConn = nil
local ParryConn = nil
local LastFire = 0
local CachedBall = nil
local LastBallCheck = 0

-- =============================================================================
-- MACRO SYSTEM
-- =============================================================================
local function FireKey()
    if State.Mode == "KPS" then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    else
        local m = UserInputService:GetMouseLocation()
        VirtualInputManager:SendMouseButtonEvent(m.X, m.Y, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(m.X, m.Y, 0, false, game, 0)
    end
end

local function MacroLoop()
    if not State.Running then return end
    local now = os.clock()
    if State.Speed >= 60 then
        FireKey()
        FireKey()
    elseif (now - LastFire) >= (1 / State.Speed) then
        LastFire = now
        FireKey()
    end
end

local function StartMacro()
    State.Running = true
    LastFire = os.clock()
    if MacroConn then MacroConn:Disconnect() end
    MacroConn = RunService.PreRender:Connect(MacroLoop)
end

local function StopMacro()
    State.Running = false
    if MacroConn then MacroConn:Disconnect() MacroConn = nil end
end

-- =============================================================================
-- BALL FINDER
-- =============================================================================
local function FindBall()
    local now = os.clock()
    if CachedBall and CachedBall.Parent and (now - LastBallCheck) < 0.08 then
        return CachedBall
    end
    LastBallCheck = now
    CachedBall = nil
    
    local name = LocalPlayer.Name
    
    -- Check workspace directly
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("BasePart") and v.Name:lower() == "ball" then
            local t = v:GetAttribute("target") or v:GetAttribute("Target")
            if not t then
                local tv = v:FindFirstChild("target") or v:FindFirstChild("Target")
                if tv then t = tv.Value end
            end
            if t == nil or t == name then
                CachedBall = v
                return v
            end
        end
    end
    
    -- Check folders
    for _, folderName in {"Balls", "Projectiles"} do
        local f = workspace:FindFirstChild(folderName)
        if f then
            for _, v in pairs(f:GetChildren()) do
                if v:IsA("BasePart") then
                    local t = v:GetAttribute("target") or v:GetAttribute("Target")
                    if t == nil or t == name then
                        CachedBall = v
                        return v
                    end
                end
            end
        end
    end
    
    return nil
end

local function BallSpeed(ball)
    if not ball then return 0 end
    local v = ball.AssemblyLinearVelocity
    return (v.X*v.X + v.Y*v.Y + v.Z*v.Z)^0.5
end

local function TimeToImpact(ball, root)
    if not ball or not root then return 999 end
    local spd = BallSpeed(ball)
    if spd < 1 then return 999 end
    local dir = root.Position - ball.Position
    local dist = dir.Magnitude
    local dot = ball.AssemblyLinearVelocity.X*dir.X + ball.AssemblyLinearVelocity.Y*dir.Y + ball.AssemblyLinearVelocity.Z*dir.Z
    if dot <= 0 then return 999 end
    return dist / (dot / dist)
end

-- =============================================================================
-- AUTO PARRY
-- =============================================================================
local function StartParry()
    if ParryConn then ParryConn:Disconnect() end
    ParryConn = RunService.Heartbeat:Connect(function()
        if not State.AutoParry then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return end
        
        local ball = FindBall()
        if not ball then return end
        
        local dist = (ball.Position - root.Position).Magnitude
        local spd = BallSpeed(ball)
        local doParry = false
        
        if State.Predictive then
            local tti = TimeToImpact(ball, root)
            local window = State.Buffer + (0.02 / (spd * 0.01 + 1))
            doParry = tti <= window
        else
            local thresh = math.clamp(State.Threshold + (spd > 50 and spd * 0.15 or 0), 20, 65)
            doParry = dist <= thresh
        end
        
        if doParry then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.delay(0.03, function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
        end
    end)
end

local function StopParry()
    if ParryConn then ParryConn:Disconnect() ParryConn = nil end
end

-- =============================================================================
-- COLORS
-- =============================================================================
local C = {
    BG = Color3.fromRGB(18, 18, 22),
    Surface = Color3.fromRGB(25, 25, 30),
    Raised = Color3.fromRGB(35, 35, 42),
    Hover = Color3.fromRGB(45, 45, 55),
    Press = Color3.fromRGB(30, 30, 36),
    Accent = Color3.fromRGB(130, 130, 150),
    AccentBright = Color3.fromRGB(170, 170, 190),
    Text = Color3.fromRGB(230, 230, 240),
    TextDim = Color3.fromRGB(140, 140, 160),
    TextMuted = Color3.fromRGB(90, 90, 110),
    Border = Color3.fromRGB(50, 50, 65),
    Green = Color3.fromRGB(80, 200, 120),
    Orange = Color3.fromRGB(230, 170, 60),
}

-- =============================================================================
-- UI HELPERS
-- =============================================================================
local function Corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or C.Border
    s.Thickness = thick or 1
    s.Transparency = 0.3
    s.Parent = parent
    return s
end

local function Gradient(parent, rot)
    local g = Instance.new("UIGradient")
    g.Rotation = rot or 180
    g.Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0,0,0))
    g.Transparency = NumberSequence.new(0.96, 0.9)
    g.Parent = parent
    return g
end

local function Hover(btn, base, hov, prs)
    local b = base or btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = hov or C.Hover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = b}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.06), {BackgroundColor3 = prs or C.Press}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = hov or C.Hover}):Play()
    end)
end

local function MakeFrame(props)
    local f = Instance.new("Frame")
    f.Name = props.Name or "Frame"
    f.Size = props.Size or UDim2.new(1,0,1,0)
    f.Position = props.Position or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = props.Color or C.Surface
    f.BackgroundTransparency = props.Transparency or 0
    f.ZIndex = props.Z or 1
    f.Visible = true
    f.Parent = props.Parent or Gui
    if props.Radius then Corner(f, props.Radius) end
    if props.Border then Stroke(f, props.Border) end
    if props.Gradient then Gradient(f) end
    return f
end

local function MakeButton(props)
    local b = Instance.new("TextButton")
    b.Name = props.Name or "Button"
    b.Size = props.Size or UDim2.new(0,100,0,30)
    b.Position = props.Position or UDim2.new(0,0,0,0)
    b.BackgroundColor3 = props.Color or C.Raised
    b.Text = props.Text or ""
    b.TextColor3 = props.TextColor or C.Text
    b.Font = props.Font or Enum.Font.GothamBold
    b.TextSize = props.TextSize or 12
    b.ZIndex = props.Z or 2
    b.Visible = true
    b.AutoButtonColor = false
    b.Parent = props.Parent or Gui
    if props.Radius then Corner(b, props.Radius) end
    if props.Border then Stroke(b, props.Border) end
    if props.Hover ~= false then Hover(b, props.Color) end
    return b
end

local function MakeLabel(props)
    local l = Instance.new("TextLabel")
    l.Name = props.Name or "Label"
    l.Size = props.Size or UDim2.new(0,100,0,20)
    l.Position = props.Position or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1
    l.Text = props.Text or ""
    l.TextColor3 = props.TextColor or C.Text
    l.Font = props.Font or Enum.Font.GothamBold
    l.TextSize = props.TextSize or 12
    l.TextXAlignment = props.XAlign or Enum.TextXAlignment.Left
    l.ZIndex = props.Z or 3
    l.Visible = true
    l.Parent = props.Parent or Gui
    return l
end

-- =============================================================================
-- BUILD UI
-- =============================================================================

-- Main container - holds everything, can be hidden
local Container = MakeFrame({
    Name = "Container",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Parent = Gui
})

-- Main panel
local Main = MakeFrame({
    Name = "Main",
    Size = UDim2.new(0, 420, 0, 340),
    Position = UDim2.new(0.5, -210, 0.5, -170),
    Color = C.BG,
    Radius = 12,
    Border = C.Border,
    Gradient = true,
    Parent = Container
})
Main.Active = true
Main.Draggable = true

-- Inner glow border
local InnerStroke = Stroke(Main, Color3.fromRGB(60, 60, 80), 1)
InnerStroke.Transparency = 0.5

-- Title bar
local TitleBar = MakeFrame({
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 36),
    Position = UDim2.new(0, 0, 0, 0),
    Color = C.Surface,
    Radius = 12,
    Parent = Main
})
Gradient(TitleBar)

-- Cover bottom corners of title bar
local TitleCover = MakeFrame({
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    Color = C.Surface,
    Parent = TitleBar
})

-- Title text
local Title = MakeLabel({
    Name = "Title",
    Size = UDim2.new(0, 100, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    Text = "THYREN",
    TextColor = C.Text,
    Font = Enum.Font.GothamBlack,
    TextSize = 14,
    Parent = TitleBar
})

-- Game label
local GameTag = MakeLabel({
    Name = "GameTag",
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(1, -90, 0, 0),
    Text = "BLADE BALL",
    TextColor = C.TextMuted,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    XAlign = Enum.TextXAlignment.Right,
    Parent = TitleBar
})

-- Content frame
local Content = MakeFrame({
    Name = "Content",
    Size = UDim2.new(1, -20, 1, -46),
    Position = UDim2.new(0, 10, 0, 40),
    BackgroundTransparency = 1,
    Parent = Main
})

-- Mode button
local ModeBtn = MakeButton({
    Name = "ModeBtn",
    Size = UDim2.new(0.48, 0, 0, 32),
    Position = UDim2.new(0, 0, 0, 0),
    Color = C.Raised,
    Text = "MODE: KPS",
    TextColor = C.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Radius = 8,
    Parent = Content
})

-- Keybind button
local BindBtn = MakeButton({
    Name = "BindBtn",
    Size = UDim2.new(0.48, 0, 0, 32),
    Position = UDim2.new(0.52, 0, 0, 0),
    Color = C.Raised,
    Text = "KEYBIND",
    TextColor = C.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Radius = 8,
    Parent = Content
})

-- Speed slider track
local SpeedTrack = MakeFrame({
    Name = "SpeedTrack",
    Size = UDim2.new(1, 0, 0, 6),
    Position = UDim2.new(0, 0, 0, 48),
    Color = Color3.fromRGB(30, 30, 38),
    Radius = 3,
    Parent = Content
})

-- Speed fill
local SpeedFill = MakeFrame({
    Name = "SpeedFill",
    Size = UDim2.new(0.004, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    Color = C.Accent,
    Radius = 3,
    Parent = SpeedTrack
})

-- Speed handle
local SpeedHandle = MakeButton({
    Name = "SpeedHandle",
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(0.004, -7, 0.5, -7),
    Color = C.AccentBright,
    Text = "",
    Radius = 7,
    Hover = false,
    Parent = SpeedTrack
})
Stroke(SpeedHandle, Color3.fromRGB(200, 200, 220), 1)

-- Speed label
local SpeedLabel = MakeLabel({
    Name = "SpeedLabel",
    Size = UDim2.new(0, 80, 0, 20),
    Position = UDim2.new(1, -80, 0, 38),
    Text = "10 KPS",
    TextColor = C.TextDim,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    XAlign = Enum.TextXAlignment.Right,
    Parent = Content
})

-- Auto Parry button
local ParryBtn = MakeButton({
    Name = "ParryBtn",
    Size = UDim2.new(1, 0, 0, 36),
    Position = UDim2.new(0, 0, 0, 70),
    Color = C.Raised,
    Text = "AUTO PARRY: OFF",
    TextColor = C.TextMuted,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Radius = 8,
    Parent = Content
})

-- Predictive + Threshold row
local PredBtn = MakeButton({
    Name = "PredBtn",
    Size = UDim2.new(0.45, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 116),
    Color = C.Raised,
    Text = "PREDICTIVE: ON",
    TextColor = C.Green,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    Radius = 8,
    Parent = Content
})

local ThreshLabel = MakeLabel({
    Name = "ThreshLabel",
    Size = UDim2.new(0, 70, 0, 20),
    Position = UDim2.new(0.48, 0, 0, 118),
    Text = "DIST: 28",
    TextColor = C.TextMuted,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    Parent = Content
})

-- Threshold slider
local ThreshTrack = MakeFrame({
    Name = "ThreshTrack",
    Size = UDim2.new(0.3, 0, 0, 4),
    Position = UDim2.new(0.7, 0, 0, 128),
    Color = Color3.fromRGB(30, 30, 38),
    Radius = 2,
    Parent = Content
})

local ThreshFill = MakeFrame({
    Name = "ThreshFill",
    Size = UDim2.new(0.3, 0, 1, 0),
    Color = C.Accent,
    Radius = 2,
    Parent = ThreshTrack
})

local ThreshHandle = MakeButton({
    Name = "ThreshHandle",
    Size = UDim2.new(0, 10, 0, 10),
    Position = UDim2.new(0.3, -5, 0.5, -5),
    Color = C.AccentBright,
    Text = "",
    Radius = 5,
    Hover = false,
    Parent = ThreshTrack
})

-- Diagnostics panel
local DiagPanel = MakeFrame({
    Name = "DiagPanel",
    Size = UDim2.new(1, 0, 0, 90),
    Position = UDim2.new(0, 0, 0, 156),
    Color = C.Surface,
    Radius = 8,
    Border = C.Border,
    Parent = Content
})
Gradient(DiagPanel)

local DiagTitle = MakeLabel({
    Size = UDim2.new(0, 80, 0, 16),
    Position = UDim2.new(0, 10, 0, 6),
    Text = "STATUS",
    TextColor = C.TextMuted,
    Font = Enum.Font.GothamBlack,
    TextSize = 9,
    Parent = DiagPanel
})

local DiagLine = MakeFrame({
    Size = UDim2.new(1, -20, 0, 1),
    Position = UDim2.new(0, 10, 0, 22),
    Color = C.Border,
    Parent = DiagPanel
})
DiagLine.BackgroundTransparency = 0.5

local DiagStatus = MakeLabel({
    Name = "DiagStatus",
    Size = UDim2.new(1, -20, 0, 16),
    Position = UDim2.new(0, 10, 0, 28),
    Text = "● MACRO: IDLE",
    TextColor = C.TextMuted,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    Parent = DiagPanel
})

local DiagBind = MakeLabel({
    Name = "DiagBind",
    Size = UDim2.new(1, -20, 0, 16),
    Position = UDim2.new(0, 10, 0, 46),
    Text = "● BIND: NONE",
    TextColor = C.TextMuted,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    Parent = DiagPanel
})

local DiagParry = MakeLabel({
    Name = "DiagParry",
    Size = UDim2.new(1, -20, 0, 16),
    Position = UDim2.new(0, 10, 0, 64),
    Text = "● PARRY: OFF",
    TextColor = C.TextMuted,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    Parent = DiagPanel
})

-- Activate button (separate from main for dragging)
local ActivateBtn = MakeButton({
    Name = "ActivateBtn",
    Size = UDim2.new(0, 380, 0, 38),
    Position = UDim2.new(0.5, -190, 0.5, 180),
    Color = C.Surface,
    Text = "ACTIVATE",
    TextColor = C.Text,
    Font = Enum.Font.GothamBlack,
    TextSize = 13,
    Radius = 10,
    Border = C.Border,
    Gradient = true,
    Parent = Container
})

-- =============================================================================
-- UPDATE UI
-- =============================================================================
local function Update()
    local m = State.Mode == "KPS" and "KPS" or "CPS"
    SpeedLabel.Text = State.Speed .. " " .. m
    
    local showActivate = State.Activation == "Manual"
    ActivateBtn.Visible = showActivate
    
    if State.Running then
        ActivateBtn.Text = "STOP"
        ActivateBtn.BackgroundColor3 = C.Raised
        DiagStatus.Text = "● MACRO: RUNNING"
        DiagStatus.TextColor = C.Green
    else
        ActivateBtn.Text = "ACTIVATE"
        ActivateBtn.BackgroundColor3 = C.Surface
        DiagStatus.Text = "● MACRO: IDLE"
        DiagStatus.TextColor = C.TextMuted
    end
end

-- Ball diag loop
task.spawn(function()
    while task.wait(0.3) do
        if State.AutoParry then
            local ball = FindBall()
            if ball then
                DiagParry.Text = "● PARRY: LOCKED (" .. math.floor(BallSpeed(ball)) .. " spd)"
                DiagParry.TextColor = C.Green
            else
                DiagParry.Text = "● PARRY: SEARCHING"
                DiagParry.TextColor = C.Orange
            end
        end
    end
end)

-- =============================================================================
-- EVENTS
-- =============================================================================

-- Mode toggle
ModeBtn.MouseButton1Click:Connect(function()
    State.Mode = State.Mode == "KPS" and "CPS" or "KPS"
    ModeBtn.Text = "MODE: " .. State.Mode
    Update()
end)

-- Keybind toggle
BindBtn.MouseButton1Click:Connect(function()
    if State.Activation == "Manual" then
        State.Binding = true
        State.Activation = "Binding"
        BindBtn.Text = "PRESS KEY..."
        BindBtn.TextColor3 = C.Orange
    else
        if State.Running then StopMacro() end
        State.Activation = "Manual"
        State.Hotkey = nil
        State.Binding = false
        BindBtn.Text = "KEYBIND"
        BindBtn.TextColor3 = C.Text
        DiagBind.Text = "● BIND: NONE"
        DiagBind.TextColor = C.TextMuted
        Update()
    end
end)

-- Parry toggle
ParryBtn.MouseButton1Click:Connect(function()
    State.AutoParry = not State.AutoParry
    if State.AutoParry then
        ParryBtn.Text = "AUTO PARRY: ON"
        ParryBtn.TextColor3 = C.Green
        ParryBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 35)
        StartParry()
    else
        ParryBtn.Text = "AUTO PARRY: OFF"
        ParryBtn.TextColor3 = C.TextMuted
        ParryBtn.BackgroundColor3 = C.Raised
        StopParry()
    end
    Update()
end)

-- Predictive toggle
PredBtn.MouseButton1Click:Connect(function()
    State.Predictive = not State.Predictive
    PredBtn.Text = "PREDICTIVE: " .. (State.Predictive and "ON" or "OFF")
    PredBtn.TextColor3 = State.Predictive and C.Green or C.TextMuted
end)

-- Activate button
ActivateBtn.MouseButton1Click:Connect(function()
    if State.Activation == "Manual" then
        if State.Running then StopMacro() else StartMacro() end
        Update()
    end
end)

-- Speed slider
local DraggingSpeed = false
SpeedHandle.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        DraggingSpeed = true
    end
end)
SpeedTrack.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        DraggingSpeed = true
        local f = math.clamp((i.Position.X - SpeedTrack.AbsolutePosition.X) / SpeedTrack.AbsoluteSize.X, 0, 1)
        State.Speed = math.floor(1 + f * 2499)
        SpeedFill.Size = UDim2.new(f, 0, 1, 0)
        SpeedHandle.Position = UDim2.new(f, -7, 0.5, -7)
        Update()
    end
end)

-- Threshold slider
local DraggingThresh = false
ThreshHandle.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        DraggingThresh = true
    end
end)
ThreshTrack.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        DraggingThresh = true
        local f = math.clamp((i.Position.X - ThreshTrack.AbsolutePosition.X) / ThreshTrack.AbsoluteSize.X, 0, 1)
        State.Threshold = math.floor(10 + f * 60)
        ThreshFill.Size = UDim2.new(f, 0, 1, 0)
        ThreshHandle.Position = UDim2.new(f, -5, 0.5, -5)
        ThreshLabel.Text = "DIST: " .. State.Threshold
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if DraggingSpeed and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local f = math.clamp((i.Position.X - SpeedTrack.AbsolutePosition.X) / SpeedTrack.AbsoluteSize.X, 0, 1)
        State.Speed = math.floor(1 + f * 2499)
        SpeedFill.Size = UDim2.new(f, 0, 1, 0)
        SpeedHandle.Position = UDim2.new(f, -7, 0.5, -7)
        Update()
    end
    if DraggingThresh and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local f = math.clamp((i.Position.X - ThreshTrack.AbsolutePosition.X) / ThreshTrack.AbsoluteSize.X, 0, 1)
        State.Threshold = math.floor(10 + f * 60)
        ThreshFill.Size = UDim2.new(f, 0, 1, 0)
        ThreshHandle.Position = UDim2.new(f, -5, 0.5, -5)
        ThreshLabel.Text = "DIST: " .. State.Threshold
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        DraggingSpeed = false
        DraggingThresh = false
    end
end)

-- Keybind input
UserInputService.InputBegan:Connect(function(i, gp)
    if State.Binding then
        if i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode ~= Enum.KeyCode.RightShift then
            State.Hotkey = i.KeyCode
            State.Activation = "Hotkey"
            State.Binding = false
            BindBtn.Text = "[" .. i.KeyCode.Name .. "]"
            BindBtn.TextColor3 = C.Green
            DiagBind.Text = "● BIND: " .. i.KeyCode.Name
            DiagBind.TextColor = C.TextDim
            Update()
        end
        return
    end
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        State.Visible = not State.Visible
        Container.Visible = State.Visible
    end
    if State.Hotkey and i.KeyCode == State.Hotkey and State.Activation == "Hotkey" then
        if State.Running then StopMacro() else StartMacro() end
        Update()
    end
end)

Update()
