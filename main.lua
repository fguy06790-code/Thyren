--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    THYREN - BLADE BALL                         ║
    ║            Maximum Anti-Detection System v2.2                 ║
    ║          [HORIZONTAL - TALL - SEPARATE ACTIVATE - 2500 MAX]   ║
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

--------------------------------------------------------------------------------
-- ENVIRONMENT DETECTION
--------------------------------------------------------------------------------
local Env = {
    Executor = "Unknown", HasProtectGui = false, HasGetHui = false,
    HasKeypress = false, HasSendInput = false, HasMouse1Press = false,
}
if syn and syn.protect_gui then Env.HasProtectGui = true; Env.Executor = "Synapse" end
if protect_gui then Env.HasProtectGui = true end
if gethui then Env.HasGetHui = true end
if keypress and keyrelease then Env.HasKeypress = true end
if sendinput then Env.HasSendInput = true end
if mouse1press and mouse1release then Env.HasMouse1Press = true end

--------------------------------------------------------------------------------
-- CLEANUP
--------------------------------------------------------------------------------
if CoreGui:FindFirstChild("ThyrenUI") then CoreGui:FindFirstChild("ThyrenUI"):Destroy() end
if LocalPlayer.PlayerGui:FindFirstChild("ThyrenUI") then LocalPlayer.PlayerGui:FindFirstChild("ThyrenUI"):Destroy() end
for _, obj in pairs(workspace:GetChildren()) do if obj.Name:find("Thyren") then obj:Destroy() end end

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
    if Env.HasProtectGui and syn and syn.protect_gui then pcall(function() syn.protect_gui(gui); gui.Parent = CoreGui end) end
    if not gui.Parent and Env.HasProtectGui then pcall(function() protect_gui(gui); gui.Parent = CoreGui end) end
    if not gui.Parent and Env.HasGetHui then pcall(function() gui.Parent = gethui() end) end
    if not gui.Parent then pcall(function() gui.Parent = CoreGui end) end
    if not gui.Parent then pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end) end
end
SecureParent(ScreenGui)

--------------------------------------------------------------------------------
-- STATE (Defined early to prevent dependency errors)
--------------------------------------------------------------------------------
local State = {
    Running = false, Speed = 10, Mode = "KPS",
    Hotkey = nil, Binding = false, Activation = "Manual",
    AutoParry = false, Threshold = 28, Predictive = true,
    VizEnabled = true, VizActive = false, Visible = true,
}
local Connections = {}
local LastFireTime = 0
local CachedBall = nil
local LastBallCheckTime = 0

--------------------------------------------------------------------------------
-- ANTI-DETECTION SYSTEM (Timing functions defined first)
--------------------------------------------------------------------------------
local AntiDetect = {
    ParryHistory = {}, MaxHistorySize = 30, LastParryTime = 0,
    BaseReactionTime = 0.045, ReactionVariance = 0.025,
    MinParryInterval = 0.12, ConsecutiveParries = 0, MaxConsecutive = 8,
    MissChance = 0.015, StreakCounter = 0,
    KeyHoldTimeMin = 0.015, KeyHoldTimeMax = 0.035,
    AverageInterval = 0.2, IntervalVariance = 0.05, PatternScore = 0,
}

local function GetHumanDelay()
    return AntiDetect.KeyHoldTimeMin + math.random() * (AntiDetect.KeyHoldTimeMax - AntiDetect.KeyHoldTimeMin)
end

local function GetReactionDelay()
    local base = AntiDetect.BaseReactionTime
    local variance = (math.random() * 2 - 1) * AntiDetect.ReactionVariance
    if AntiDetect.PatternScore > 50 then variance = variance + (math.random() * 0.03) end
    return math.max(0.01, base + variance)
end

local function ShouldIntentionalMiss()
    AntiDetect.ConsecutiveParries = AntiDetect.ConsecutiveParries + 1
    AntiDetect.StreakCounter = AntiDetect.StreakCounter + 1
    if AntiDetect.ConsecutiveParries >= AntiDetect.MaxConsecutive then
        AntiDetect.ConsecutiveParries = 0; return true
    end
    local chance = math.min(AntiDetect.MissChance + (AntiDetect.StreakCounter * 0.002), 0.05)
    if math.random() < chance then AntiDetect.ConsecutiveParries = 0; return true end
    return false
end

local function AnalyzePatterns()
    local h = AntiDetect.ParryHistory
    if #h < 5 then return end
    local sum = 0
    for _, v in ipairs(h) do sum = sum + v end
    AntiDetect.AverageInterval = sum / #h
    local variance = 0
    for _, v in ipairs(h) do local d = v - AntiDetect.AverageInterval; variance = variance + (d * d) end
    AntiDetect.IntervalVariance = (variance / #h) ^ 0.5
    local cv = AntiDetect.IntervalVariance / AntiDetect.AverageInterval
    AntiDetect.PatternScore = math.clamp((1 - cv) * 100, 0, 100)
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
    local baseDelay = GetReactionDelay()
    if AntiDetect.PatternScore > 60 then baseDelay = baseDelay + (math.random() * 0.04)
    elseif AntiDetect.PatternScore > 40 then baseDelay = baseDelay + (math.random() * 0.02) end
    local timeSinceLast = os.clock() - AntiDetect.LastParryTime
    if timeSinceLast < AntiDetect.MinParryInterval then baseDelay = baseDelay + (AntiDetect.MinParryInterval - timeSinceLast) end
    return math.max(0, baseDelay)
end

local function ResetStreak()
    AntiDetect.StreakCounter = 0
end

--------------------------------------------------------------------------------
-- HID EMULATION SYSTEM
--------------------------------------------------------------------------------
local HID = { Method = "VirtualInput", PressCount = 0, ReleaseCount = 0, LastInputTime = 0 }

local function InitializeHID()
    if Env.HasKeypress then
        HID.Method = "keypress"
        HID.Press = function(keyCode)
            local keyName = keyCode.Name
            HID.PressCount = HID.PressCount + 1; HID.LastInputTime = os.clock()
            pcall(function()
                keypress(keyName)
                task.delay(GetHumanDelay(), function() keyrelease(keyName); HID.ReleaseCount = HID.ReleaseCount + 1 end)
            end)
        end
        return
    end
    if Env.HasSendInput then
        HID.Method = "sendinput"
        HID.Press = function(keyCode)
            HID.PressCount = HID.PressCount + 1; HID.LastInputTime = os.clock()
            pcall(function()
                sendinput({Type = "KeyDown", Key = keyCode.Name})
                task.delay(GetHumanDelay(), function() sendinput({Type = "KeyUp", Key = keyCode.Name}); HID.ReleaseCount = HID.ReleaseCount + 1 end)
            end)
        end
        return
    end
    HID.Method = "VirtualInput"
    HID.Press = function(keyCode)
        HID.PressCount = HID.PressCount + 1; HID.LastInputTime = os.clock()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.delay(GetHumanDelay(), function() VirtualInputManager:SendKeyEvent(false, keyCode, false, game); HID.ReleaseCount = HID.ReleaseCount + 1 end)
        end)
    end
end

local function MousePress()
    HID.PressCount = HID.PressCount + 1; HID.LastInputTime = os.clock()
    if Env.HasMouse1Press then
        pcall(function()
            mouse1press()
            task.delay(GetHumanDelay(), function() mouse1release(); HID.ReleaseCount = HID.ReleaseCount + 1 end)
        end)
    else
        local m = UserInputService:GetMouseLocation()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(m.X, m.Y, 0, true, game, 0)
            task.delay(GetHumanDelay(), function() VirtualInputManager:SendMouseButtonEvent(m.X, m.Y, 0, false, game, 0); HID.ReleaseCount = HID.ReleaseCount + 1 end)
        end)
    end
end

InitializeHID()

-- HumanParry defined here because it needs HID and AntiDetect
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
-- BALL DETECTION ENGINE (Defined before Visualizer & AutoParry)
--------------------------------------------------------------------------------
local function FindBall()
    local now = os.clock()
    if CachedBall and CachedBall.Parent and (now - LastBallCheckTime) < 0.04 then return CachedBall end
    LastBallCheckTime = now; CachedBall = nil
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n == "ball" or n == "sphereball" or n == "projectile" then
                local target = obj:GetAttribute("target") or obj:GetAttribute("Target") or obj:GetAttribute("TargetPlayer")
                if not target then
                    local tv = obj:FindFirstChild("target") or obj:FindFirstChild("Target") or obj:FindFirstChild("TargetPlayer")
                    if tv and tv.Value then target = typeof(tv.Value) == "string" and tv.Value or tv.Value.Name end
                end
                if target == nil or target == PlayerName then CachedBall = obj; return obj end
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
                    if target == nil or target == PlayerName then CachedBall = obj; return obj end
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
    local futureBallPos = ball.Position + ball.AssemblyLinearVelocity * 0.08
    local direction = rootPart.Position - futureBallPos
    local distance = direction.Magnitude
    local dotProduct = ball.AssemblyLinearVelocity.X * direction.X + ball.AssemblyLinearVelocity.Y * direction.Y + ball.AssemblyLinearVelocity.Z * direction.Z
    if dotProduct <= 0 then return 999 end
    return distance / (dotProduct / direction.Magnitude)
end

--------------------------------------------------------------------------------
-- INVISIBLE VISUALIZER SYSTEM
--------------------------------------------------------------------------------
local Viz = { Parts = {}, UpdateCounter = 0 }

local function CreateInvisiblePart(config)
    local part = Instance.new("Part")
    part.Name = config.Name or "ThyrenViz"; part.Anchored = true; part.CanCollide = false
    part.Massless = true; part.Size = config.Size or Vector3.new(1, 1, 1)
    part.Position = config.Position or Vector3.new(0, -5000, 0)
    part.Shape = config.Shape or Enum.PartType.Ball; part.Material = Enum.Material.ForceField
    part.Color = config.Color or Color3.new(1, 1, 1); part.Transparency = 1
    part.CastShadow = false; part.ReceiveShadow = false; part.Parent = workspace
    table.insert(Viz.Parts, part); return part
end

local function InitializeVisualizer()
    if State.VizActive then return end; State.VizActive = true
    Viz.RangeRing = CreateInvisiblePart({ Name = "Thyren_Range", Size = Vector3.new(0.2, 1, 1), Shape = Enum.PartType.Cylinder })
    Viz.BallTracker = CreateInvisiblePart({ Name = "Thyren_BallTracker", Size = Vector3.new(0.1, 0.1, 0.1), Shape = Enum.PartType.Ball })
    Viz.Trajectory = CreateInvisiblePart({ Name = "Thyren_Trajectory", Size = Vector3.new(0.05, 0.05, 1), Shape = Enum.PartType.Block })
    Viz.Prediction = CreateInvisiblePart({ Name = "Thyren_Prediction", Size = Vector3.new(0.3, 0.3, 0.3), Shape = Enum.PartType.Ball })
    Viz.TriggerZone = CreateInvisiblePart({ Name = "Thyren_TriggerZone", Size = Vector3.new(0.5, 0.5, 0.5), Shape = Enum.PartType.Ball })
end

local function UpdateVisualizer(ball, root, distance, timeToImpact)
    if not State.VizActive or not root then return end
    Viz.UpdateCounter = Viz.UpdateCounter + 1
    if Viz.UpdateCounter % 3 ~= 0 then return end
    local thresh = State.Threshold
    if ball then local spd = BallSpeed(ball); if spd > 40 then thresh = thresh + (spd * 0.18) end; thresh = math.clamp(thresh, 15, 70) end
    Viz.RangeRing.Size = Vector3.new(0.2, thresh * 2, thresh * 2)
    Viz.RangeRing.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
    if ball then
        Viz.BallTracker.Position = ball.Position
        local dir = root.Position - ball.Position; local dist = dir.Magnitude
        if dist > 0.1 then
            Viz.Trajectory.Size = Vector3.new(0.05, 0.05, dist)
            Viz.Trajectory.CFrame = CFrame.lookAt(ball.Position + dir * 0.5, root.Position)
        end
        if ball.AssemblyLinearVelocity then Viz.Prediction.Position = ball.Position + ball.AssemblyLinearVelocity * math.min(timeToImpact, 0.5) end
        if dist > 0.1 then Viz.TriggerZone.Position = ball.Position + dir.Unit * thresh end
    else
        local hide = Vector3.new(0, -5000, 0)
        Viz.BallTracker.Position = hide; Viz.Trajectory.Position = hide; Viz.Prediction.Position = hide; Viz.TriggerZone.Position = hide
    end
end

local function CleanupVisualizer()
    for _, part in ipairs(Viz.Parts) do if part and part.Parent then part:Destroy() end end
    Viz.Parts = {}; State.VizActive = false
end

--------------------------------------------------------------------------------
-- MACRO & AUTO PARRY LOGIC
--------------------------------------------------------------------------------
local function ExecuteMacroInput()
    if State.Mode == "KPS" then HID.Press(Enum.KeyCode.Space) else MousePress() end
end

local function MacroTick()
    if not State.Running then return end
    local currentTime = os.clock()
    if State.Speed >= 60 then
        ExecuteMacroInput(); ExecuteMacroInput()
    elseif (currentTime - LastFireTime) >= (1 / State.Speed) then
        LastFireTime = currentTime; ExecuteMacroInput()
    end
end

local function StartMacro()
    State.Running = true; LastFireTime = os.clock(); ResetStreak()
    if Connections.Macro then Connections.Macro:Disconnect() end
    Connections.Macro = RunService.PreRender:Connect(MacroTick)
end

local function StopMacro()
    State.Running = false; ResetStreak()
    if Connections.Macro then Connections.Macro:Disconnect(); Connections.Macro = nil end
end

local function ToggleMacro() if State.Running then StopMacro() else StartMacro() end end

local function StartAutoParry()
    if State.VizEnabled then InitializeVisualizer() end
    if Connections.Parry then Connections.Parry:Disconnect() end
    Connections.Parry = RunService.Heartbeat:Connect(function()
        if not State.AutoParry then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then
            if State.VizActive then local h = Vector3.new(0,-5000,0) for _, p in ipairs(Viz.Parts) do if p.Parent then p.Position = h end end end
            return
        end
        local ball = FindBall()
        if not ball then if State.VizEnabled and State.VizActive then UpdateVisualizer(nil, root, 999, 999) end return end
        local dist = (ball.Position - root.Position).Magnitude
        local spd = BallSpeed(ball)
        local tti = CalculateTimeToImpact(ball, root)
        local shouldParry = false
        if State.Predictive then
            shouldParry = tti <= (0.06 + (0.03 / (spd * 0.015 + 1)))
        else
            local dt = math.clamp(State.Threshold + (spd > 40 and spd * 0.18 or 0), 15, 70)
            shouldParry = dist <= dt
        end
        if State.VizEnabled and State.VizActive then UpdateVisualizer(ball, root, dist, tti) end
        if shouldParry then HumanParry() end
    end)
end

local function StopAutoParry()
    if Connections.Parry then Connections.Parry:Disconnect(); Connections.Parry = nil end
    CleanupVisualizer()
end

--------------------------------------------------------------------------------
-- THEME & UI UTILITIES
--------------------------------------------------------------------------------
local Theme = {
    Background = Color3.fromRGB(10, 10, 14), Surface = Color3.fromRGB(18, 18, 24),
    Card = Color3.fromRGB(26, 26, 34), Hover = Color3.fromRGB(40, 40, 52), Pressed = Color3.fromRGB(22, 22, 28),
    Accent = Color3.fromRGB(90, 90, 110), AccentLight = Color3.fromRGB(130, 130, 155),
    Success = Color3.fromRGB(55, 175, 95), Warning = Color3.fromRGB(205, 145, 35),
    Error = Color3.fromRGB(200, 65, 65), Info = Color3.fromRGB(95, 135, 215), Purple = Color3.fromRGB(135, 95, 195),
    TextPrimary = Color3.fromRGB(210, 210, 222), TextSecondary = Color3.fromRGB(140, 140, 158),
    TextMuted = Color3.fromRGB(80, 80, 100), TextDisabled = Color3.fromRGB(50, 50, 65),
    Border = Color3.fromRGB(35, 35, 48),
}

local function ApplyCorner(inst, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = inst; return c end
local function ApplyStroke(inst, col, thick, trans) local s = Instance.new("UIStroke"); s.Color = col or Theme.Border; s.Thickness = thick or 1; s.Transparency = trans or 0.4; s.Parent = inst; return s end

local function ApplyHoverEffect(button, baseColor)
    button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Hover}):Play() end)
    button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = baseColor}):Play() end)
end

local function CreateLabel(config)
    local l = Instance.new("TextLabel"); l.Name = config.Name or "Label"; l.Size = config.Size or UDim2.new(1,0,0,20)
    l.Position = config.Position or UDim2.new(0,0,0,0); l.BackgroundTransparency = 1; l.Text = config.Text or ""
    l.TextColor3 = config.Color or Theme.TextSecondary; l.TextSize = config.Size2 or 11
    l.Font = config.Font or Enum.Font.GothamMedium; l.TextXAlignment = config.XAlign or Enum.TextXAlignment.Left
    l.Parent = config.Parent; return l
end

local function CreateButton(config)
    local b = Instance.new("TextButton"); b.Name = config.Name or "Button"; b.Size = config.Size or UDim2.new(0,100,0,30)
    b.Position = config.Position or UDim2.new(0,0,0,0); b.BackgroundColor3 = config.Color or Theme.Card; b.BorderSizePixel = 0
    b.Text = config.Text or ""; b.TextColor3 = config.TextColor or Theme.TextPrimary
    b.TextSize = config.TextSize or 11; b.Font = config.Font or Enum.Font.GothamBold; b.AutoButtonColor = false
    b.Parent = config.Parent
    if config.Corner then ApplyCorner(b, config.Corner) end
    if config.Stroke then ApplyStroke(b, config.StrokeColor, config.StrokeThickness) end
    if config.Hover ~= false then ApplyHoverEffect(b, config.Color or Theme.Card) end
    return b
end

local function CreateFrame(config)
    local f = Instance.new("Frame"); f.Name = config.Name or "Frame"; f.Size = config.Size or UDim2.new(1,0,1,0)
    f.Position = config.Position or UDim2.new(0,0,0,0); f.BackgroundColor3 = config.Color or Theme.Surface
    f.BorderSizePixel = 0; f.BackgroundTransparency = config.Transparency or 0; f.Parent = config.Parent
    if config.Corner then ApplyCorner(f, config.Corner) end
    if config.Stroke then ApplyStroke(f, config.StrokeColor, config.StrokeThickness, config.StrokeTransparency) end
    return f
end

local function CreateSlider(config)
    local t = CreateFrame({Name=config.Name, Size=config.Size or UDim2.new(1,0,0,4), Position=config.Position, Color=Color3.fromRGB(28,28,38), Parent=config.Parent, Corner=2})
    local fill = CreateFrame({Name="Fill", Size=UDim2.new(config.FillFraction or 0.004, 0, 1, 0), Color=Theme.Accent, Parent=t, Corner=2})
    local h = Instance.new("TextButton"); h.Name="Handle"; h.Size=UDim2.new(0,config.HandleSize or 10, 0,config.HandleSize or 10)
    h.Position=UDim2.new(config.FillFraction or 0.004, -(config.HandleSize or 10)/2, 0.5, -(config.HandleSize or 10)/2)
    h.BackgroundColor3=Theme.AccentLight; h.BorderSizePixel=0; h.Text=""; h.AutoButtonColor=false; h.Parent=t
    ApplyCorner(h, (config.HandleSize or 10)/2)
    return t, fill, h
end

local function CreateStatusDot(config)
    local d = Instance.new("Frame"); d.Name=config.Name or "Dot"; d.Size=UDim2.new(0,config.Size or 6, 0,config.Size or 6)
    d.Position=config.Position or UDim2.new(0,0,0,0); d.BackgroundColor3=config.Color or Theme.TextDisabled
    d.BorderSizePixel=0; d.Parent=config.Parent; ApplyCorner(d, (config.Size or 6)/2); return d
end

--------------------------------------------------------------------------------
-- BUILD HORIZONTAL GUI (Taller: 680x265)
--------------------------------------------------------------------------------
local Container = Instance.new("Frame")
Container.Name = "Container"; Container.Size = UDim2.new(1, 0, 1, 0)
Container.BackgroundTransparency = 1; Container.Parent = ScreenGui

local PANEL_W, PANEL_H = 680, 265

local MainPanel = CreateFrame({
    Name = "MainPanel", Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
    Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2 - 24), -- Offset up slightly to make room for separate button
    Color = Theme.Background, Corner = 12, Stroke = true, StrokeColor = Theme.Border, Parent = Container
})
MainPanel.Active = true; MainPanel.Draggable = true

-- Header
local HeaderBar = CreateFrame({Name="HeaderBar", Size=UDim2.new(1,0,0,36), Color=Theme.Surface, Corner=12, Parent=MainPanel})
local HeaderFix = CreateFrame({Size=UDim2.new(1,0,0,8), Position=UDim2.new(0,0,1,-8), Color=Theme.Surface, Parent=HeaderBar})
CreateLabel({Name="Title", Size=UDim2.new(0,70,1,0), Position=UDim2.new(0,12,0,0), Text="THYREN", Color=Theme.TextPrimary, Size2=13, Font=Enum.Font.GothamBlack, Parent=HeaderBar})
CreateStatusDot({Name="VDot", Size=4, Position=UDim2.new(0,86,0.5,-2), Color=Theme.Success, Parent=HeaderBar})
CreateLabel({Size=UDim2.new(0,25,1,0), Position=UDim2.new(0,93,0,0), Text="v2.0", Color=Theme.TextDisabled, Size2=8, Parent=HeaderBar})
CreateStatusDot({Name="HDot", Size=4, Position=UDim2.new(0,124,0.5,-2), Color=Theme.Info, Parent=HeaderBar})
CreateLabel({Size=UDim2.new(0,55,1,0), Position=UDim2.new(0,131,0,0), Text=HID.Method, Color=Theme.TextDisabled, Size2=8, Parent=HeaderBar})
CreateLabel({Size=UDim2.new(0,55,1,0), Position=UDim2.new(1,-62,0,0), Text="RShift ▾", Color=Theme.TextDisabled, Size2=8, XAlign=Enum.TextXAlignment.Right, Parent=HeaderBar})

local ContentArea = CreateFrame({Name="Content", Size=UDim2.new(1,-20,1,-42), Position=UDim2.new(0,10,0,40), Transparency=1, Parent=MainPanel})

-- COLUMN 1: MACRO
local C1W = 185
local Col1 = CreateFrame({Size=UDim2.new(0,C1W,1,0), Transparency=1, Parent=ContentArea})
CreateLabel({Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,4), Text="MACRO", Color=Theme.TextDisabled, Size2=8, Font=Enum.Font.GothamBold, Parent=Col1})

local ModeButton = CreateButton({Name="ModeBtn", Size=UDim2.new(0.48,0,0,32), Position=UDim2.new(0,0,0,22), Text="KPS", TextSize=10, Corner=6, Parent=Col1})
local BindButton = CreateButton({Name="BindBtn", Size=UDim2.new(0.48,0,0,32), Position=UDim2.new(0.52,0,0,22), Text="KEYBIND", TextColor=Theme.TextSecondary, TextSize=10, Corner=6, Parent=Col1})

local SpeedVal = CreateLabel({Size=UDim2.new(0,50,0,22), Position=UDim2.new(0,0,0,62), Text="10 KPS", Color=Theme.TextPrimary, Size2=16, Font=Enum.Font.GothamBold, Parent=Col1})
CreateLabel({Size=UDim2.new(0,40,0,12), Position=UDim2.new(0,0,0,86), Text="SPEED", Color=Theme.TextDisabled, Size2=7, Font=Enum.Font.GothamBold, Parent=Col1})
local SpeedTrack, SpeedFill, SpeedHandle = CreateSlider({Name="SpeedSlider", Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,102), HandleSize=12, Parent=Col1})

-- Separator 1
local Sep1 = Instance.new("Frame"); Sep1.Size=UDim2.new(0,1,1,-20); Sep1.Position=UDim2.new(0,C1W+4,0,10)
Sep1.BackgroundColor3=Theme.Border; Sep1.BackgroundTransparency=0.5; Sep1.BorderSizePixel=0; Sep1.Parent=ContentArea

-- COLUMN 2: AUTO PARRY
local C2X = C1W + 12
local C2W = 190
local Col2 = CreateFrame({Size=UDim2.new(0,C2W,1,0), Position=UDim2.new(0,C2X,0,0), Transparency=1, Parent=ContentArea})
CreateLabel({Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,4), Text="AUTO PARRY", Color=Theme.TextDisabled, Size2=8, Font=Enum.Font.GothamBold, Parent=Col2})

local ParryButton = CreateButton({Name="ParryBtn", Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,22), Text="AUTO PARRY", TextColor=Theme.TextMuted, TextSize=11, Corner=8, Parent=Col2})
local ParryDot = CreateStatusDot({Size=5, Position=UDim2.new(1,-15,0.5,-2.5), Color=Theme.TextDisabled, Parent=ParryButton})

local PredictBtn = CreateButton({Size=UDim2.new(0.48,0,0,28), Position=UDim2.new(0,0,0,62), Text="PREDICT", TextColor=Theme.Success, TextSize=8, Corner=5, Parent=Col2})
local VizBtn = CreateButton({Size=UDim2.new(0.48,0,0,28), Position=UDim2.new(0.52,0,0,62), Text="VISUAL", TextColor=Theme.Purple, TextSize=8, Corner=5, Parent=Col2})

local ThreshVal = CreateLabel({Size=UDim2.new(0,25,0,18), Position=UDim2.new(0,0,0,98), Text="28", Color=Theme.TextSecondary, Size2=14, Font=Enum.Font.GothamBold, Parent=Col2})
CreateLabel({Size=UDim2.new(0,55,0,12), Position=UDim2.new(0,0,0,116), Text="THRESHOLD", Color=Theme.TextDisabled, Size2=7, Font=Enum.Font.GothamBold, Parent=Col2})
local ThreshTrack, ThreshFill, ThreshHandle = CreateSlider({Name="ThreshSlider", Size=UDim2.new(1,0,0,5), Position=UDim2.new(0,0,0,132), HandleSize=9, Parent=Col2})

local StreakLabel = CreateLabel({Size=UDim2.new(0,90,0,16), Position=UDim2.new(0,0,0,150), Text="STREAK: 0", Color=Theme.TextMuted, Size2=9, Parent=Col2})

-- Separator 2
local Sep2 = Instance.new("Frame"); Sep2.Size=UDim2.new(0,1,1,-20); Sep2.Position=UDim2.new(0,C2X+C2W+4,0,10)
Sep2.BackgroundColor3=Theme.Border; Sep2.BackgroundTransparency=0.5; Sep2.BorderSizePixel=0; Sep2.Parent=ContentArea

-- COLUMN 3: DIAGNOSTICS
local C3X = C2X + C2W + 12
local Col3 = CreateFrame({Size=UDim2.new(1,-C3X,1,0), Position=UDim2.new(0,C3X,0,0), Transparency=1, Parent=ContentArea})
CreateLabel({Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,4), Text="DIAGNOSTICS", Color=Theme.TextDisabled, Size2=8, Font=Enum.Font.GothamBold, Parent=Col3})

local DiagDots, DiagTexts = {}, {}
local diagData = {
    {id="Macro", t="MACRO: IDLE"}, {id="Parry", t="PARRY: OFF"}, {id="Ball", t="TARGET: NONE"},
    {id="Viz", t="VIZ: OFF"}, {id="HID", t="HID: "..HID.Method}, {id="Pattern", t="BOT: 0%"}
}
for i, d in ipairs(diagData) do
    local xo, yo = 0, 22 + ((i-1)%3)*28
    if i > 3 then xo = 0.5; yo = 22 + ((i-4)%3)*28 end
    DiagDots[d.id] = CreateStatusDot({Name="DD_"..d.id, Size=4, Position=UDim2.new(xo, 8, 0, yo+2), Color=Theme.TextDisabled, Parent=Col3})
    DiagTexts[d.id] = CreateLabel({Name="DT_"..d.id, Size=UDim2.new(0.48, -20, 0, 18), Position=UDim2.new(xo, 18, 0, yo), Text=d.t, Color=Theme.TextMuted, Size2=9, Parent=Col3})
end

--------------------------------------------------------------------------------
-- SEPARATE ACTIVATE BUTTON
--------------------------------------------------------------------------------
local ActivateButton = CreateButton({
    Name = "ActivateButton", Size = UDim2.new(0, PANEL_W, 0, 42),
    Position = UDim2.new(0.5, -PANEL_W/2, 0.5, PANEL_H/2 - 24 + 8), -- Positioned directly below
    Color = Theme.Surface, Text = "ACTIVATE", TextColor = Theme.TextPrimary,
    TextSize = 14, Corner = 10, Stroke = true, StrokeColor = Theme.Border, Parent = Container
})
local ActDot = CreateStatusDot({Name="ActDot", Size=6, Position=UDim2.new(1,-18,0.5,-3), Color=Theme.TextDisabled, Parent=ActivateButton})

-- Sync Activate Button position when MainPanel is dragged
MainPanel:GetPropertyChangedSignal("Position"):Connect(function()
    local xPos = MainPanel.Position.X.Offset
    local yPos = MainPanel.Position.Y.Offset + PANEL_H + 8
    ActivateButton.Position = UDim2.new(0, xPos, 0, yPos)
end)

--------------------------------------------------------------------------------
-- UI UPDATE LOGIC
--------------------------------------------------------------------------------
local function UpdateUI()
    SpeedVal.Text = tostring(State.Speed) .. " " .. State.Mode
    local sf = math.clamp((State.Speed - 1) / 2499, 0.004, 1)
    SpeedFill.Size = UDim2.new(sf, 0, 1, 0)
    SpeedHandle.Position = UDim2.new(sf, -6, 0.5, -6)

    ModeButton.Text = State.Mode
    BindButton.Text = State.Binding and "..." or (State.Hotkey and State.Hotkey.Name or "KEYBIND")

    if State.Running then
        ActivateButton.Text = "STOP"
        TweenService:Create(ActivateButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 18, 18)}):Play()
        TweenService:Create(ActDot, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Success}):Play()
    else
        ActivateButton.Text = "ACTIVATE"
        TweenService:Create(ActivateButton, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Surface}):Play()
        TweenService:Create(ActDot, TweenInfo.new(0.15), {BackgroundColor3 = Theme.TextDisabled}):Play()
    end

    if State.AutoParry then
        TweenService:Create(ParryButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(18, 35, 22)}):Play()
        TweenService:Create(ParryDot, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Success}):Play()
    else
        TweenService:Create(ParryButton, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Card}):Play()
        TweenService:Create(ParryDot, TweenInfo.new(0.15), {BackgroundColor3 = Theme.TextDisabled}):Play()
    end

    PredictBtn.TextColor3 = State.Predictive and Theme.Success or Theme.TextMuted
    VizBtn.TextColor3 = State.VizEnabled and Theme.Purple or Theme.TextMuted

    ThreshVal.Text = tostring(State.Threshold)
    local tf = math.clamp((State.Threshold - 5) / 65, 0.004, 1)
    ThreshFill.Size = UDim2.new(tf, 0, 1, 0)
    ThreshHandle.Position = UDim2.new(tf, -4.5, 0.5, -4.5)
    StreakLabel.Text = "STREAK: " .. AntiDetect.StreakCounter

    -- Diagnostics
    DiagDots.Macro.BackgroundColor3 = State.Running and Theme.Success or Theme.TextDisabled
    DiagTexts.Macro.Text = State.Running and ("MACRO: "..State.Mode.." @"..State.Speed) or "MACRO: IDLE"
    DiagTexts.Macro.TextColor3 = State.Running and Theme.TextSecondary or Theme.TextMuted

    DiagDots.Parry.BackgroundColor3 = State.AutoParry and Theme.Success or Theme.TextDisabled
    DiagTexts.Parry.Text = State.AutoParry and "PARRY: ON" or "PARRY: OFF"
    DiagTexts.Parry.TextColor3 = State.AutoParry and Theme.TextSecondary or Theme.TextMuted

    local ball = FindBall()
    if ball then
        local dist = 999
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then dist = (ball.Position - root.Position).Magnitude end
        DiagDots.Ball.BackgroundColor3 = Theme.Warning
        DiagTexts.Ball.Text = "TARGET: " .. math.floor(dist) .. "s"
        DiagTexts.Ball.TextColor3 = Theme.TextSecondary
    else
        DiagDots.Ball.BackgroundColor3 = Theme.TextDisabled
        DiagTexts.Ball.Text = "TARGET: NONE"
        DiagTexts.Ball.TextColor3 = Theme.TextMuted
    end

    DiagDots.Viz.BackgroundColor3 = State.VizActive and Theme.Purple or Theme.TextDisabled
    DiagTexts.Viz.Text = State.VizActive and "VIZ: ACTIVE" or "VIZ: OFF"
    DiagTexts.Viz.TextColor3 = State.VizActive and Theme.TextSecondary or Theme.TextMuted

    DiagDots.HID.BackgroundColor3 = Theme.Info
    DiagTexts.HID.Text = "HID: " .. HID.Method
    DiagTexts.HID.TextColor3 = Theme.TextSecondary

    local ps = math.floor(AntiDetect.PatternScore)
    DiagDots.Pattern.BackgroundColor3 = ps > 60 and Theme.Error or (ps > 30 and Theme.Warning or Theme.Success)
    DiagTexts.Pattern.Text = "BOT: " .. ps .. "%"
    DiagTexts.Pattern.TextColor3 = Theme.TextSecondary
end

--------------------------------------------------------------------------------
-- SLIDER INTERACTIVITY (MAX 2500 FOR SPEED)
--------------------------------------------------------------------------------
local function MakeSliderWork(track, fill, handle, minVal, maxVal, callback)
    local dragging = false
    local function update(input)
        local relX = input.Position.X - track.AbsolutePosition.X
        local frac = math.clamp(relX / track.AbsoluteSize.X, 0, 1)
        local value = math.floor(minVal + frac * (maxVal - minVal))
        callback(math.clamp(value, minVal, maxVal))
        UpdateUI()
    end
    handle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(input) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end end)
end

MakeSliderWork(SpeedTrack, SpeedFill, SpeedHandle, 1, 2500, function(val) State.Speed = val end)
MakeSliderWork(ThreshTrack, ThreshFill, ThreshHandle, 5, 70, function(val) State.Threshold = val end)

--------------------------------------------------------------------------------
-- BUTTON EVENTS
--------------------------------------------------------------------------------
ModeButton.MouseButton1Click:Connect(function()
    State.Mode = State.Mode == "KPS" and "CPS" or "KPS"; UpdateUI()
end)

BindButton.MouseButton1Click:Connect(function()
    State.Binding = true; UpdateUI()
end)

ActivateButton.MouseButton1Click:Connect(function()
    ToggleMacro(); UpdateUI()
end)

ParryButton.MouseButton1Click:Connect(function()
    State.AutoParry = not State.AutoParry
    if State.AutoParry then StartAutoParry() else StopAutoParry() end
    UpdateUI()
end)

PredictBtn.MouseButton1Click:Connect(function() State.Predictive = not State.Predictive; UpdateUI() end)

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
            State.Hotkey = input.KeyCode; State.Binding = false; State.Activation = "Hotkey"; UpdateUI()
        end
        return
    end
    if State.Hotkey and input.KeyCode == State.Hotkey then ToggleMacro(); UpdateUI(); return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        State.Visible = not State.Visible
        MainPanel.Visible = State.Visible
        ActivateButton.Visible = State.Visible
    end
end)

RunService.Heartbeat:Connect(UpdateUI)
UpdateUI()
