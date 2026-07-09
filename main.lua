--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    THYREN - BLADE BALL                         ║
    ║            Maximum Anti-Detection System v3.0                 ║
    ║       [FOOLPROOF UI + ZERO LAG BACKEND ENGINE]                ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

--------------------------------------------------------------------------------
-- SERVICES
--------------------------------------------------------------------------------
local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local VirtualInputManager  = game:GetService("VirtualInputManager")
local TweenService         = game:GetService("TweenService")
local CoreGui              = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerName  = LocalPlayer.Name

-- ZERO-LAG: Pre-cache global lookups for the hot loop
local VIM_SendKeyEvent = VirtualInputManager.SendKeyEvent
local KeyCode_F = Enum.KeyCode.F

--------------------------------------------------------------------------------
-- ENVIRONMENT DETECTION
--------------------------------------------------------------------------------
local Env = { HasProtectGui = false, HasGetHui = false, HasKeypress = false, HasSendInput = false }
if syn and syn.protect_gui then Env.HasProtectGui = true end
if protect_gui then Env.HasProtectGui = true end
if gethui then Env.HasGetHui = true end
if keypress and keyrelease then Env.HasKeypress = true end
if sendinput then Env.HasSendInput = true end

--------------------------------------------------------------------------------
-- CLEANUP
--------------------------------------------------------------------------------
if CoreGui:FindFirstChild("ThyrenUI") then CoreGui:FindFirstChild("ThyrenUI"):Destroy() end
if LocalPlayer.PlayerGui:FindFirstChild("ThyrenUI") then LocalPlayer.PlayerGui:FindFirstChild("ThyrenUI"):Destroy() end
for _, obj in pairs(workspace:GetChildren()) do
    if obj.Name:find("Thyren") then obj:Destroy() end
end

--------------------------------------------------------------------------------
-- SCREENGUI
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThyrenUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999

local function SecureParent(gui)
    if Env.HasProtectGui and syn and syn.protect_gui then
        pcall(function() syn.protect_gui(gui); gui.Parent = CoreGui end)
    end
    if not gui.Parent and Env.HasProtectGui then
        pcall(function() protect_gui(gui); gui.Parent = CoreGui end)
    end
    if not gui.Parent and Env.HasGetHui then
        pcall(function() gui.Parent = gethui() end)
    end
    if not gui.Parent then pcall(function() gui.Parent = CoreGui end) end
    if not gui.Parent then pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end) end
end
SecureParent(ScreenGui)

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local State = {
    Running = false, Speed = 10, Mode = "KPS",
    Hotkey = nil, Binding = false, AutoParry = false, 
    Threshold = 28, Predictive = true,
    VizEnabled = true, VizActive = false, Visible = true,
}
local Connections = {}
local CachedBall = nil
local LastBallCheckTime = 0
local LastFoundBallForUI = nil

-- ZERO-LAG: UI Dirty-Check Cache (Prevents 99% of string/gc lag)
local UICache = {
    SpeedText = "", ModeText = "", BindText = "", ActText = "", ActColor = nil, ActDotColor = nil,
    ParryColor = nil, ParryDotColor = nil, PredColor = nil, VizColor = nil,
    ThreshText = "", StreakText = "", 
    DmText = "", DmColor = nil, DmTColor = nil,
    DpText = "", DpColor = nil, DpTColor = nil,
    DbText = "", DbColor = nil, DbTColor = nil,
    DvText = "", DvColor = nil,
    DpatText = "", DpatColor = nil,
}

--------------------------------------------------------------------------------
-- ANTI-DETECTION SYSTEM
--------------------------------------------------------------------------------
local AntiDetect = {
    ParryHistory = {}, MaxHistorySize = 30, LastParryTime = 0,
    ConsecutiveParries = 0, MaxConsecutive = 8, MissChance = 0.015, StreakCounter = 0,
    KeyHoldTimeMin = 0.015, KeyHoldTimeMax = 0.035, PatternScore = 0,
}

local function GetHumanDelay()
    return AntiDetect.KeyHoldTimeMin + math.random() * (AntiDetect.KeyHoldTimeMax - AntiDetect.KeyHoldTimeMin)
end
local function ResetStreak() AntiDetect.StreakCounter = 0 end

local function AnalyzePatterns()
    local h = AntiDetect.ParryHistory
    if #h < 5 then return end
    local sum, variance = 0, 0
    for _, v in ipairs(h) do sum = sum + v end
    local avg = sum / #h
    for _, v in ipairs(h) do local d = v - avg; variance = variance + (d * d) end
    AntiDetect.PatternScore = math.clamp((1 - ((variance / #h) ^ 0.5) / avg) * 100, 0, 100)
end

local function RecordParryTiming()
    local now = os.clock()
    local interval = now - AntiDetect.LastParryTime
    if interval > 0.05 and interval < 5 then
        table.insert(AntiDetect.ParryHistory, interval)
        if #AntiDetect.ParryHistory > AntiDetect.MaxHistorySize then table.remove(AntiDetect.ParryHistory, 1) end
    end
    AntiDetect.LastParryTime = now
    AnalyzePatterns()
end

local function GetAdaptiveDelay()
    local base = 0.045 + (math.random() * 2 - 1) * 0.025
    if AntiDetect.PatternScore > 50 then base = base + (math.random() * 0.04) end
    local timeSince = os.clock() - AntiDetect.LastParryTime
    if timeSince < 0.12 then base = base + (0.12 - timeSince) end
    return math.max(0, base)
end

local function ShouldIntentionalMiss()
    AntiDetect.ConsecutiveParries = AntiDetect.ConsecutiveParries + 1
    AntiDetect.StreakCounter = AntiDetect.StreakCounter + 1
    if AntiDetect.ConsecutiveParries >= 8 then
        AntiDetect.ConsecutiveParries = 0
        return true
    end
    if math.random() < math.min(0.015 + (AntiDetect.StreakCounter * 0.002), 0.05) then
        AntiDetect.ConsecutiveParries = 0
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- HID SYSTEM (Parry Only)
--------------------------------------------------------------------------------
local HID = { Method = "VirtualInput" }

local function InitializeHID()
    if Env.HasKeypress then
        HID.Method = "keypress"
        HID.Press = function(kc)
            pcall(function()
                keypress(kc.Name)
                task.delay(GetHumanDelay(), function() keyrelease(kc.Name) end)
            end)
        end
    elseif Env.HasSendInput then
        HID.Method = "sendinput"
        HID.Press = function(kc)
            pcall(function()
                sendinput({Type="KeyDown", Key=kc.Name})
                task.delay(GetHumanDelay(), function() sendinput({Type="KeyUp", Key=kc.Name}) end)
            end)
        end
    else
        HID.Method = "VirtualInput"
        HID.Press = function(kc)
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, kc, false, game)
                task.delay(GetHumanDelay(), function() VirtualInputManager:SendKeyEvent(false, kc, false, game) end)
            end)
        end
    end
end
InitializeHID()

local function HumanParry()
    if ShouldIntentionalMiss() then return end
    local delay = GetAdaptiveDelay()
    task.delay(delay, function()
        if not State.AutoParry then return end
        HID.Press(Enum.KeyCode.Space)
        RecordParryTiming()
    end)
end

--------------------------------------------------------------------------------
-- BALL DETECTION ENGINE
--------------------------------------------------------------------------------
local function FindBall()
    local now = os.clock()
    if CachedBall and CachedBall.Parent and (now - LastBallCheckTime) < 0.05 then
        return CachedBall
    end
    LastBallCheckTime = now
    CachedBall = nil
    
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n == "ball" or n == "sphereball" or n == "projectile" then
                local target = obj:GetAttribute("target") or obj:GetAttribute("Target") or obj:GetAttribute("TargetPlayer")
                if not target then
                    local tv = obj:FindFirstChild("target") or obj:FindFirstChild("Target") or obj:FindFirstChild("TargetPlayer")
                    if tv and tv.Value then target = typeof(tv.Value) == "string" and tv.Value or tv.Value.Name end
                end
                if target == nil or target == PlayerName then
                    CachedBall = obj
                    return obj
                end
            end
        end
    end
    
    for _, fName in ipairs({"Balls", "Projectiles", "ball", "ProjectilesFolder", "Entities"}) do
        local folder = workspace:FindFirstChild(fName)
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                if obj:IsA("BasePart") then
                    local target = obj:GetAttribute("target") or obj:GetAttribute("Target")
                    if not target then
                        local tv = obj:FindFirstChild("target") or obj:FindFirstChild("Target")
                        if tv and tv.Value then target = typeof(tv.Value) == "string" and tv.Value or tv.Value.Name end
                    end
                    if target == nil or target == PlayerName then
                        CachedBall = obj
                        return obj
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
    return (v.X * v.X + v.Y * v.Y + v.Z * v.Z) ^ 0.5
end

local function CalculateTimeToImpact(ball, rootPart)
    if not ball or not rootPart then return 999 end
    local speed = BallSpeed(ball)
    if speed < 1 then return 999 end
    local dir = rootPart.Position - (ball.Position + ball.AssemblyLinearVelocity * 0.08)
    local dot = ball.AssemblyLinearVelocity.X * dir.X + ball.AssemblyLinearVelocity.Y * dir.Y + ball.AssemblyLinearVelocity.Z * dir.Z
    if dot <= 0 then return 999 end
    return dir.Magnitude / (dot / dir.Magnitude)
end

--------------------------------------------------------------------------------
-- INVISIBLE VISUALIZER
--------------------------------------------------------------------------------
local Viz = { Parts = {} }

local function CreateInvisiblePart(config)
    local p = Instance.new("Part")
    p.Name = config.Name or "ThyrenViz"
    p.Anchored = true
    p.CanCollide = false
    p.Massless = true
    p.Size = config.Size or Vector3.new(1, 1, 1)
    p.Position = config.Position or Vector3.new(0, -5000, 0)
    p.Shape = config.Shape or Enum.PartType.Ball
    p.Material = Enum.Material.ForceField
    p.Transparency = 1
    p.CastShadow = false
    p.ReceiveShadow = false
    p.Parent = workspace
    table.insert(Viz.Parts, p)
    return p
end

local function InitializeVisualizer()
    if State.VizActive then return end
    State.VizActive = true
    Viz.RangeRing = CreateInvisiblePart({ Name = "Thyren_Range", Size = Vector3.new(0.2, 1, 1), Shape = Enum.PartType.Cylinder })
    Viz.BallTracker = CreateInvisiblePart({ Name = "Thyren_BallTracker", Size = Vector3.new(0.1, 0.1, 0.1) })
    Viz.Trajectory = CreateInvisiblePart({ Name = "Thyren_Trajectory", Size = Vector3.new(0.05, 0.05, 1), Shape = Enum.PartType.Block })
    Viz.Prediction = CreateInvisiblePart({ Name = "Thyren_Prediction", Size = Vector3.new(0.3, 0.3, 0.3) })
    Viz.TriggerZone = CreateInvisiblePart({ Name = "Thyren_TriggerZone", Size = Vector3.new(0.5, 0.5, 0.5) })
end

local function CleanupVisualizer()
    for _, p in ipairs(Viz.Parts) do
        if p and p.Parent then p:Destroy() end
    end
    Viz.Parts = {}
    State.VizActive = false
end

--------------------------------------------------------------------------------
-- MACRO ENGINE (ORGANIC VARIANCE + ZERO PCALL LAG)
--------------------------------------------------------------------------------
local Accumulator = 0
local OrganicPressCount = 0

local function MacroTick(dt)
    if not State.Running then
        Accumulator = 0
        return 
    end
    
    OrganicPressCount = OrganicPressCount + 1
    
    -- Simulates human finger inconsistencies to bypass timing graphs
    local variance = 1.0
    if OrganicPressCount % 47 == 0 then variance = 0.85 end
    if OrganicPressCount % 103 == 0 then variance = 1.15 end
    
    Accumulator = Accumulator + (dt * State.Speed * variance)
    
    -- Lag spike immunity: Don't "catch up" by firing 100 times in 1 frame
    if Accumulator > 15 then Accumulator = 15 end 
    
    if State.Mode == "KPS" then
        -- PURE VIM F SPAM (Zero pcall for max performance)
        while Accumulator >= 1 do
            VIM_SendKeyEvent(VirtualInputManager, true, KeyCode_F, false, game)
            VIM_SendKeyEvent(VirtualInputManager, false, KeyCode_F, false, game)
            Accumulator = Accumulator - 1
        end
    else
        local m = UserInputService:GetMouseLocation()
        local mX, mY = m.X, m.Y
        while Accumulator >= 1 do
            VirtualInputManager:SendMouseButtonEvent(mX, mY, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(mX, mY, 0, false, game, 0)
            Accumulator = Accumulator - 1
        end
    end
end

local function StartMacro()
    State.Running = true
    ResetStreak()
    Accumulator = 0
    OrganicPressCount = 0
    if Connections.Macro then Connections.Macro:Disconnect() end
    Connections.Macro = RunService.Heartbeat:Connect(MacroTick)
end

local function StopMacro()
    State.Running = false
    ResetStreak()
    if Connections.Macro then Connections.Macro:Disconnect(); Connections.Macro = nil end
end

local function ToggleMacro()
    if State.Running then StopMacro() else StartMacro() end
end

local function StartAutoParry()
    if State.VizEnabled then InitializeVisualizer() end
    if Connections.Parry then Connections.Parry:Disconnect() end
    Connections.Parry = RunService.Heartbeat:Connect(function(dt)
        if not State.AutoParry then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then
            if State.VizActive then
                local h = Vector3.new(0, -5000, 0)
                for _, p in ipairs(Viz.Parts) do if p.Parent then p.Position = h end end
            end
            LastFoundBallForUI = nil
            return
        end
        local ball = FindBall()
        LastFoundBallForUI = ball
        if not ball then return end
        local dist = (ball.Position - root.Position).Magnitude
        local spd = BallSpeed(ball)
        local tti = CalculateTimeToImpact(ball, root)
        local shouldParry = false
        if State.Predictive then
            shouldParry = tti <= (0.06 + (0.03 / (spd * 0.015 + 1)))
        else
            shouldParry = dist <= math.clamp(State.Threshold + (spd > 40 and spd * 0.18 or 0), 15, 70)
        end
        if shouldParry then HumanParry() end
    end)
end

local function StopAutoParry()
    if Connections.Parry then Connections.Parry:Disconnect(); Connections.Parry = nil end
    LastFoundBallForUI = nil
    CleanupVisualizer()
end

--------------------------------------------------------------------------------
-- THEME
--------------------------------------------------------------------------------
local Theme = {
    Background = Color3.fromRGB(10, 10, 14),
    Surface = Color3.fromRGB(18, 18, 24),
    Card = Color3.fromRGB(26, 26, 34),
    Hover = Color3.fromRGB(40, 40, 52),
    Accent = Color3.fromRGB(90, 90, 110),
    AccentLight = Color3.fromRGB(130, 130, 155),
    Success = Color3.fromRGB(55, 175, 95),
    Warning = Color3.fromRGB(205, 145, 35),
    Error = Color3.fromRGB(200, 65, 65),
    Info = Color3.fromRGB(95, 135, 215),
    Purple = Color3.fromRGB(135, 95, 195),
    TextPrimary = Color3.fromRGB(210, 210, 222),
    TextSecondary = Color3.fromRGB(140, 140, 158),
    TextMuted = Color3.fromRGB(80, 80, 100),
    TextDisabled = Color3.fromRGB(50, 50, 65),
    Border = Color3.fromRGB(35, 35, 48),
    ActiveRed = Color3.fromRGB(40, 18, 18),
    ActiveGreen = Color3.fromRGB(18, 35, 22),
}

--------------------------------------------------------------------------------
-- SAFE UI BUILDERS (Expanded to prevent parsing errors on all executors)
--------------------------------------------------------------------------------
local function MakeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
end

local function MakeStroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thick or 1
    s.Transparency = 0.4
    s.Parent = parent
end

local function MakeLabel(props)
    local l = Instance.new("TextLabel")
    l.Name = props.Name or "Label"
    l.Size = props.Size or UDim2.new(1, 0, 0, 20)
    l.Position = props.Position or UDim2.new(0, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = props.Text or ""
    l.TextColor3 = props.Color or Theme.TextSecondary
    l.TextSize = props.TextSize or 11
    l.Font = props.Font or Enum.Font.GothamMedium
    l.TextXAlignment = props.XAlign or Enum.TextXAlignment.Left
    l.Parent = props.Parent
    return l
end

local function MakeButton(props)
    local b = Instance.new("TextButton")
    b.Name = props.Name or "Button"
    b.Size = props.Size or UDim2.new(0, 100, 0, 30)
    b.Position = props.Position or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3 = props.Color or Theme.Card
    b.BorderSizePixel = 0
    b.Text = props.Text or ""
    b.TextColor3 = props.TextColor or Theme.TextPrimary
    b.TextSize = props.TextSize or 11
    b.Font = props.Font or Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.Parent = props.Parent
    if props.Corner then MakeCorner(b, props.Corner) end
    if props.Stroke then MakeStroke(b) end
    
    -- Safe Hover logic
    local baseCol = props.Color or Theme.Card
    b.MouseEnter:Connect(function() b.BackgroundColor3 = Theme.Hover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = baseCol end)
    return b
end

local function MakeFrame(props)
    local f = Instance.new("Frame")
    f.Name = props.Name or "Frame"
    f.Size = props.Size or UDim2.new(1, 0, 1, 0)
    f.Position = props.Position or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3 = props.Color or Theme.Surface
    f.BorderSizePixel = 0
    f.BackgroundTransparency = props.Transparency or 0
    f.Parent = props.Parent
    if props.Corner then MakeCorner(f, props.Corner) end
    if props.Stroke then MakeStroke(f) end
    return f
end

local function MakeSlider(props)
    local track = MakeFrame({
        Name = props.Name,
        Size = props.Size or UDim2.new(1, 0, 0, 4),
        Position = props.Position,
        Color = Color3.fromRGB(28, 28, 38),
        Parent = props.Parent,
        Corner = 2
    })
    local fill = MakeFrame({
        Name = "Fill",
        Size = UDim2.new(props.FillFraction or 0.004, 0, 1, 0),
        Color = Theme.Accent,
        Parent = track,
        Corner = 2
    })
    local handle = Instance.new("TextButton")
    handle.Name = "Handle"
    local hs = props.HandleSize or 10
    handle.Size = UDim2.new(0, hs, 0, hs)
    handle.Position = UDim2.new(props.FillFraction or 0.004, -hs/2, 0.5, -hs/2)
    handle.BackgroundColor3 = Theme.AccentLight
    handle.BorderSizePixel = 0
    handle.Text = ""
    handle.AutoButtonColor = false
    handle.Parent = track
    MakeCorner(handle, hs/2)
    return track, fill, handle
end

local function MakeDot(props)
    local d = Instance.new("Frame")
    d.Name = props.Name or "Dot"
    local s = props.Size or 6
    d.Size = UDim2.new(0, s, 0, s)
    d.Position = props.Position or UDim2.new(0, 0, 0, 0)
    d.BackgroundColor3 = props.Color or Theme.TextDisabled
    d.BorderSizePixel = 0
    d.Parent = props.Parent
    MakeCorner(d, s/2)
    return d
end

--------------------------------------------------------------------------------
-- BUILD GUI LAYOUT (Explicitly expanded for maximum compatibility)
--------------------------------------------------------------------------------
local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(1, 0, 1, 0)
Container.BackgroundTransparency = 1
Container.Parent = ScreenGui

local PANEL_W = 680
local PANEL_H = 265

local MainPanel = MakeFrame({
    Name = "MainPanel",
    Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
    Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2 - 30),
    Color = Theme.Background,
    Corner = 12,
    Stroke = true,
    Parent = Container
})
MainPanel.Active = true
MainPanel.Draggable = true

-- Header
local HeaderBar = MakeFrame({
    Name = "HeaderBar",
    Size = UDim2.new(1, 0, 0, 36),
    Color = Theme.Surface,
    Corner = 12,
    Parent = MainPanel
})
local HeaderFix = MakeFrame({
    Size = UDim2.new(1, 0, 0, 8),
    Position = UDim2.new(0, 0, 1, -8),
    Color = Theme.Surface,
    Parent = HeaderBar
})
MakeLabel({Name="Title", Size=UDim2.new(0,70,1,0), Position=UDim2.new(0,12,0,0), Text="THYREN", Color=Theme.TextPrimary, TextSize=13, Font=Enum.Font.GothamBlack, Parent=HeaderBar})
MakeDot({Name="VDot", Size=4, Position=UDim2.new(0,86,0.5,-2), Color=Theme.Success, Parent=HeaderBar})
MakeLabel({Size=UDim2.new(0,25,1,0), Position=UDim2.new(0,93,0,0), Text="v3.0", Color=Theme.TextDisabled, TextSize=8, Parent=HeaderBar})
MakeDot({Size=4, Position=UDim2.new(0,124,0.5,-2), Color=Theme.Info, Parent=HeaderBar})
MakeLabel({Size=UDim2.new(0,60,1,0), Position=UDim2.new(0,131,0,0), Text="STEALTH", Color=Theme.TextDisabled, TextSize=8, Parent=HeaderBar})
MakeLabel({Size=UDim2.new(0,55,1,0), Position=UDim2.new(1,-62,0,0), Text="RShift ▾", Color=Theme.TextDisabled, TextSize=8, XAlign=Enum.TextXAlignment.Right, Parent=HeaderBar})

local ContentArea = MakeFrame({
    Name = "Content",
    Size = UDim2.new(1, -20, 1, -42),
    Position = UDim2.new(0, 10, 0, 40),
    Transparency = 1,
    Parent = MainPanel
})

-- Column 1
local C1W = 185
local Col1 = MakeFrame({Size=UDim2.new(0,C1W,1,0), Transparency=1, Parent=ContentArea})
MakeLabel({Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,4), Text="MACRO [RAW F]", Color=Theme.TextDisabled, TextSize=8, Font=Enum.Font.GothamBold, Parent=Col1})

local ModeButton = MakeButton({Name="ModeBtn", Size=UDim2.new(0.48,0,0,32), Position=UDim2.new(0,0,0,22), Text="KPS", TextSize=10, Corner=6, Parent=Col1})
local BindButton = MakeButton({Name="BindBtn", Size=UDim2.new(0.48,0,0,32), Position=UDim2.new(0.52,0,0,22), Text="KEYBIND", TextColor=Theme.TextSecondary, TextSize=10, Corner=6, Parent=Col1})

local SpeedVal = MakeLabel({Size=UDim2.new(0,60,0,22), Position=UDim2.new(0,0,0,62), Text="10 KPS", Color=Theme.TextPrimary, TextSize=16, Font=Enum.Font.GothamBold, Parent=Col1})
MakeLabel({Size=UDim2.new(0,40,0,12), Position=UDim2.new(0,0,0,86), Text="SPEED", Color=Theme.TextDisabled, TextSize=7, Font=Enum.Font.GothamBold, Parent=Col1})
local SpeedTrack, SpeedFill, SpeedHandle = MakeSlider({Name="SpeedSlider", Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,102), HandleSize=12, Parent=Col1})

local Sep1 = Instance.new("Frame")
Sep1.Size = UDim2.new(0, 1, 1, -20)
Sep1.Position = UDim2.new(0, C1W + 4, 0, 10)
Sep1.BackgroundColor3 = Theme.Border
Sep1.BackgroundTransparency = 0.5
Sep1.BorderSizePixel = 0
Sep1.Parent = ContentArea

-- Column 2
local C2X = C1W + 12
local C2W = 190
local Col2 = MakeFrame({Size=UDim2.new(0,C2W,1,0), Position=UDim2.new(0,C2X,0,0), Transparency=1, Parent=ContentArea})
MakeLabel({Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,4), Text="AUTO PARRY", Color=Theme.TextDisabled, TextSize=8, Font=Enum.Font.GothamBold, Parent=Col2})

local ParryButton = MakeButton({Name="ParryBtn", Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,22), Text="AUTO PARRY", TextColor=Theme.TextMuted, TextSize=11, Corner=8, Parent=Col2})
local ParryDot = MakeDot({Size=5, Position=UDim2.new(1,-15,0.5,-2.5), Color=Theme.TextDisabled, Parent=ParryButton})

local PredictBtn = MakeButton({Size=UDim2.new(0.48,0,0,28), Position=UDim2.new(0,0,0,62), Text="PREDICT", TextColor=Theme.Success, TextSize=8, Corner=5, Parent=Col2})
local VizBtn = MakeButton({Size=UDim2.new(0.48,0,0,28), Position=UDim2.new(0.52,0,0,62), Text="VISUAL", TextColor=Theme.Purple, TextSize=8, Corner=5, Parent=Col2})

local ThreshVal = MakeLabel({Size=UDim2.new(0,25,0,18), Position=UDim2.new(0,0,0,98), Text="28", Color=Theme.TextSecondary, TextSize=14, Font=Enum.Font.GothamBold, Parent=Col2})
MakeLabel({Size=UDim2.new(0,55,0,12), Position=UDim2.new(0,0,0,116), Text="THRESHOLD", Color=Theme.TextDisabled, TextSize=7, Font=Enum.Font.GothamBold, Parent=Col2})
local ThreshTrack, ThreshFill, ThreshHandle = MakeSlider({Name="ThreshSlider", Size=UDim2.new(1,0,0,5), Position=UDim2.new(0,0,0,132), HandleSize=9, Parent=Col2})

local StreakLabel = MakeLabel({Size=UDim2.new(0,90,0,16), Position=UDim2.new(0,0,0,150), Text="STREAK: 0", Color=Theme.TextMuted, TextSize=9, Parent=Col2})

local Sep2 = Instance.new("Frame")
Sep2.Size = UDim2.new(0, 1, 1, -20)
Sep2.Position = UDim2.new(0, C2X + C2W + 4, 0, 10)
Sep2.BackgroundColor3 = Theme.Border
Sep2.BackgroundTransparency = 0.5
Sep2.BorderSizePixel = 0
Sep2.Parent = ContentArea

-- Column 3
local C3X = C2X + C2W + 12
local Col3 = MakeFrame({Size=UDim2.new(1,-C3X,1,0), Position=UDim2.new(0,C3X,0,0), Transparency=1, Parent=ContentArea})
MakeLabel({Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,4), Text="DIAGNOSTICS", Color=Theme.TextDisabled, TextSize=8, Font=Enum.Font.GothamBold, Parent=Col3})

local DiagDots = {}
local DiagTexts = {}
local diagData = {
    {id="Macro", t="MACRO: IDLE"}, {id="Parry", t="PARRY: OFF"}, {id="Ball", t="TARGET: NONE"},
    {id="Viz", t="VIZ: OFF"}, {id="HID", t="INPUT: STEALTH"}, {id="Pattern", t="BOT: 0%"}
}

for i, d in ipairs(diagData) do
    local xo = 0
    local yo = 22 + ((i-1)%3)*28
    if i > 3 then
        xo = 0.5
        yo = 22 + ((i-4)%3)*28
    end
    DiagDots[d.id] = MakeDot({Name="DD_"..d.id, Size=4, Position=UDim2.new(xo, 8, 0, yo+2), Color=Theme.TextDisabled, Parent=Col3})
    DiagTexts[d.id] = MakeLabel({Name="DT_"..d.id, Size=UDim2.new(0.48, -20, 0, 18), Position=UDim2.new(xo, 18, 0, yo), Text=d.t, Color=Theme.TextMuted, TextSize=9, Parent=Col3})
end

-- Separate Draggable Button
local ActivateFrame = MakeFrame({
    Name = "ActivateFrame",
    Size = UDim2.new(0, 160, 0, 34),
    Position = UDim2.new(0.5, -80, 0.5, PANEL_H/2 - 30 + 10),
    Color = Theme.Surface,
    Corner = 10,
    Stroke = true,
    Parent = Container
})

local ActivateButton = MakeButton({
    Name = "ActivateButton",
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    Color = Theme.Surface,
    Text = "ACTIVATE",
    TextColor = Theme.TextPrimary,
    TextSize = 12,
    Corner = 10,
    Parent = ActivateFrame
})
local ActDot = MakeDot({Name="ActDot", Size=5, Position=UDim2.new(1,-15,0.5,-2.5), Color=Theme.TextDisabled, Parent=ActivateButton})

-- Safe Drag Logic
local actDragging = false
local actMoved = false
local actStart = nil
local actInitialPos = nil

ActivateButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        actDragging = true
        actMoved = false
        actStart = input.Position
        actInitialPos = ActivateFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if actDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - actStart
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
            actMoved = true
            ActivateFrame.Position = UDim2.new(
                actInitialPos.X.Scale, actInitialPos.X.Offset + delta.X,
                actInitialPos.Y.Scale, actInitialPos.Y.Offset + delta.Y
            )
        end
    end
end)

ActivateButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        actDragging = false
    end
end)

--------------------------------------------------------------------------------
-- ZERO LAG UI UPDATE (Dirty-Check System)
--------------------------------------------------------------------------------
local UIUpdateCounter = 0

local function UpdateUI()
    UIUpdateCounter = UIUpdateCounter + 1
    -- Run UI updates at 15 FPS max to eliminate lag
    if UIUpdateCounter % 4 ~= 0 then return end

    -- Instant color assignments (0% lag compared to TweenService)
    local aColor = State.Running and Theme.ActiveRed or Theme.Surface
    if UICache.ActColor ~= aColor then
        ActivateButton.BackgroundColor3 = aColor
        UICache.ActColor = aColor
    end
    
    local aText = State.Running and "STOP" or "ACTIVATE"
    if UICache.ActText ~= aText then
        ActivateButton.Text = aText
        UICache.ActText = aText
    end
    
    local aDotColor = State.Running and Theme.Success or Theme.TextDisabled
    if UICache.ActDotColor ~= aDotColor then
        ActDot.BackgroundColor3 = aDotColor
        UICache.ActDotColor = aDotColor
    end

    local pColor = State.AutoParry and Theme.ActiveGreen or Theme.Card
    if UICache.ParryColor ~= pColor then
        ParryButton.BackgroundColor3 = pColor
        UICache.ParryColor = pColor
    end
    
    local pDotColor = State.AutoParry and Theme.Success or Theme.TextDisabled
    if UICache.ParryDotColor ~= pDotColor then
        ParryDot.BackgroundColor3 = pDotColor
        UICache.ParryDotColor = pDotColor
    end

    local predColor = State.Predictive and Theme.Success or Theme.TextMuted
    if UICache.PredColor ~= predColor then
        PredictBtn.TextColor3 = predColor
        UICache.PredColor = predColor
    end
    
    local vizColor = State.VizEnabled and Theme.Purple or Theme.TextMuted
    if UICache.VizColor ~= vizColor then
        VizBtn.TextColor3 = vizColor
        UICache.VizColor = vizColor
    end

    -- Text Updates (Only updates string if value changed)
    local sText = State.Speed .. " " .. State.Mode
    if UICache.SpeedText ~= sText then
        SpeedVal.Text = sText
        UICache.SpeedText = sText
    end
    
    local mText = State.Mode
    if UICache.ModeText ~= mText then
        ModeButton.Text = mText
        UICache.ModeText = mText
    end
    
    local bText = State.Binding and "..." or (State.Hotkey and State.Hotkey.Name or "KEYBIND")
    if UICache.BindText ~= bText then
        BindButton.Text = bText
        UICache.BindText = bText
    end
    
    local tText = tostring(State.Threshold)
    if UICache.ThreshText ~= tText then
        ThreshVal.Text = tText
        UICache.ThreshText = tText
    end
    
    local stText = "STREAK: " .. AntiDetect.StreakCounter
    if UICache.StreakText ~= stText then
        StreakLabel.Text = stText
        UICache.StreakText = stText
    end

    -- Sliders
    local sf = math.clamp((State.Speed - 1) / 2499, 0.004, 1)
    SpeedFill.Size = UDim2.new(sf, 0, 1, 0)
    SpeedHandle.Position = UDim2.new(sf, -6, 0.5, -6)
    
    local tf = math.clamp((State.Threshold - 5) / 65, 0.004, 1)
    ThreshFill.Size = UDim2.new(tf, 0, 1, 0)
    ThreshHandle.Position = UDim2.new(tf, -4.5, 0.5, -4.5)

    -- Diagnostics
    local dmText = State.Running and ("MACRO: F @"..State.Speed) or "MACRO: IDLE"
    local dmColor = State.Running and Theme.Success or Theme.TextDisabled
    local dmTColor = State.Running and Theme.TextSecondary or Theme.TextMuted
    if UICache.DmText ~= dmText then DiagTexts.Macro.Text = dmText; UICache.DmText = dmText end
    if UICache.DmColor ~= dmColor then DiagDots.Macro.BackgroundColor3 = dmColor; UICache.DmColor = dmColor end
    if UICache.DmTColor ~= dmTColor then DiagTexts.Macro.TextColor3 = dmTColor; UICache.DmTColor = dmTColor end

    local dpText = State.AutoParry and "PARRY: ON" or "PARRY: OFF"
    local dpColor = State.AutoParry and Theme.Success or Theme.TextDisabled
    local dpTColor = State.AutoParry and Theme.TextSecondary or Theme.TextMuted
    if UICache.DpText ~= dpText then DiagTexts.Parry.Text = dpText; UICache.DpText = dpText end
    if UICache.DpColor ~= dpColor then DiagDots.Parry.BackgroundColor3 = dpColor; UICache.DpColor = dpColor end
    if UICache.DpTColor ~= dpTColor then DiagTexts.Parry.TextColor3 = dpTColor; UICache.DpTColor = dpTColor end

    local ball = LastFoundBallForUI
    if ball and ball.Parent then
        local dist = 999
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then dist = (ball.Position - root.Position).Magnitude end
        local dbText = "TARGET: " .. math.floor(dist) .. "s"
        if UICache.DbText ~= dbText then DiagTexts.Ball.Text = dbText; UICache.DbText = dbText end
        if UICache.DbColor ~= Theme.Warning then DiagDots.Ball.BackgroundColor3 = Theme.Warning; UICache.DbColor = Theme.Warning end
        if UICache.DbTColor ~= Theme.TextSecondary then DiagTexts.Ball.TextColor3 = Theme.TextSecondary; UICache.DbTColor = Theme.TextSecondary end
    else
        if UICache.DbText ~= "TARGET: NONE" then DiagTexts.Ball.Text = "TARGET: NONE"; UICache.DbText = "TARGET: NONE" end
        if UICache.DbColor ~= Theme.TextDisabled then DiagDots.Ball.BackgroundColor3 = Theme.TextDisabled; UICache.DbColor = Theme.TextDisabled end
        if UICache.DbTColor ~= Theme.TextMuted then DiagTexts.Ball.TextColor3 = Theme.TextMuted; UICache.DbTColor = Theme.TextMuted end
    end

    local dvText = State.VizActive and "VIZ: ACTIVE" or "VIZ: OFF"
    local dvColor = State.VizActive and Theme.Purple or Theme.TextDisabled
    if UICache.DvText ~= dvText then DiagTexts.Viz.Text = dvText; UICache.DvText = dvText end
    if UICache.DvColor ~= dvColor then DiagDots.Viz.BackgroundColor3 = dvColor; UICache.DvColor = dvColor end

    local ps = math.floor(AntiDetect.PatternScore)
    local dpatText = "BOT: " .. ps .. "%"
    local dpatColor = ps > 60 and Theme.Error or (ps > 30 and Theme.Warning or Theme.Success)
    if UICache.DpatText ~= dpatText then DiagTexts.Pattern.Text = dpatText; UICache.DpatText = dpatText end
    if UICache.DpatColor ~= dpatColor then DiagDots.Pattern.BackgroundColor3 = dpatColor; UICache.DpatColor = dpatColor end
end

--------------------------------------------------------------------------------
-- SLIDERS & EVENTS
--------------------------------------------------------------------------------
local function MakeSliderWork(track, fill, handle, minVal, maxVal, callback)
    local dragging = false
    local function update(input)
        local frac = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = math.floor(minVal + frac * (maxVal - minVal))
        callback(math.clamp(value, minVal, maxVal))
        UpdateUI()
    end
    handle.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end end)
end

MakeSliderWork(SpeedTrack, SpeedFill, SpeedHandle, 1, 2500, function(v) State.Speed = v end)
MakeSliderWork(ThreshTrack, ThreshFill, ThreshHandle, 5, 70, function(v) State.Threshold = v end)

ModeButton.MouseButton1Click:Connect(function()
    State.Mode = State.Mode == "KPS" and "CPS" or "KPS"
    UpdateUI()
end)

BindButton.MouseButton1Click:Connect(function()
    State.Binding = true
    UpdateUI()
end)

ActivateButton.MouseButton1Click:Connect(function()
    if actMoved then actMoved = false; return end
    ToggleMacro()
    UpdateUI()
end)

ParryButton.MouseButton1Click:Connect(function()
    State.AutoParry = not State.AutoParry
    if State.AutoParry then StartAutoParry() else StopAutoParry() end
    UpdateUI()
end)

PredictBtn.MouseButton1Click:Connect(function()
    State.Predictive = not State.Predictive
    UpdateUI()
end)

VizBtn.MouseButton1Click:Connect(function()
    State.VizEnabled = not State.VizEnabled
    if not State.VizEnabled and State.VizActive then CleanupVisualizer() end
    if State.VizEnabled and State.AutoParry then InitializeVisualizer() end
    UpdateUI()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if State.Binding then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            State.Hotkey = input.KeyCode
            State.Binding = false
            UpdateUI()
        end
        return
    end
    if State.Hotkey and input.KeyCode == State.Hotkey then
        ToggleMacro()
        UpdateUI()
        return
    end
    if input.KeyCode == Enum.KeyCode.RightShift then
        State.Visible = not State.Visible
        MainPanel.Visible = State.Visible
        ActivateFrame.Visible = State.Visible
    end
end)

RunService.Heartbeat:Connect(UpdateUI)
UpdateUI()
