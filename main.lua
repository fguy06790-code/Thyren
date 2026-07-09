--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    THYREN - BLADE BALL                         ║
    ║            Maximum Anti-Detection System v4.0                 ║
    ║       [EXACT IMAGE LAYOUT - ULTRA ZERO-LAG ENGINE]            ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

--------------------------------------------------------------------------------
-- PRE-CACHED GLOBALS (Zero table lookups in hot loops)
--------------------------------------------------------------------------------
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui             = game:GetService("CoreGui")

local clamp   = math.clamp
local floor   = math.floor
local clock   = os.clock
local insert  = table.insert
local remove  = table.remove

local LocalPlayer = Players.LocalPlayer
local PlayerName  = LocalPlayer.Name
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
for _, obj in pairs(workspace:GetChildren()) do if obj.Name:find("Thyren") then obj:Destroy() end end

--------------------------------------------------------------------------------
-- SCREENGUI
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThyrenUI"; ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; ScreenGui.IgnoreGuiInset = true; ScreenGui.DisplayOrder = 9999

if Env.HasProtectGui and syn and syn.protect_gui then pcall(function() syn.protect_gui(ScreenGui); ScreenGui.Parent = CoreGui end) end
if not ScreenGui.Parent and Env.HasProtectGui then pcall(function() protect_gui(ScreenGui); ScreenGui.Parent = CoreGui end) end
if not ScreenGui.Parent and Env.HasGetHui then pcall(function() ScreenGui.Parent = gethui() end) end
if not ScreenGui.Parent then pcall(function() ScreenGui.Parent = CoreGui end) end
if not ScreenGui.Parent then pcall(function() ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end) end

--------------------------------------------------------------------------------
-- STATE & CACHE
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

local UICache = {
    SpeedText = "", ModeText = "", BindText = "", ActText = "", ActColor = nil, ActDotColor = nil,
    ParryColor = nil, ParryDotColor = nil, PredColor = nil, VizColor = nil,
    ThreshText = "", StreakText = "", 
    DmText = "", DmColor = nil, DmTColor = nil,
    DpText = "", DpColor = nil, DpTColor = nil,
    DbText = "", DbColor = nil, DbTColor = nil,
    DvText = "", DvColor = nil, DpatText = "", DpatColor = nil,
}

--------------------------------------------------------------------------------
-- ANTI-DETECTION SYSTEM
--------------------------------------------------------------------------------
local AntiDetect = {
    ParryHistory = {}, MaxHistorySize = 30, LastParryTime = 0,
    ConsecutiveParries = 0, MaxConsecutive = 8, MissChance = 0.015, StreakCounter = 0,
    KeyHoldTimeMin = 0.015, KeyHoldTimeMax = 0.035, PatternScore = 0,
}
local function GetHumanDelay() return AntiDetect.KeyHoldTimeMin + math.random() * (AntiDetect.KeyHoldTimeMax - AntiDetect.KeyHoldTimeMin) end
local function ResetStreak() AntiDetect.StreakCounter = 0 end
local function AnalyzePatterns()
    local h = AntiDetect.ParryHistory; if #h < 5 then return end
    local sum, variance = 0, 0
    for i = 1, #h do sum = sum + h[i] end
    local avg = sum / #h
    for i = 1, #h do local d = h[i] - avg; variance = variance + (d * d) end
    AntiDetect.PatternScore = clamp((1 - ((variance / #h) ^ 0.5) / avg) * 100, 0, 100)
end
local function RecordParryTiming()
    local now = clock(); local interval = now - AntiDetect.LastParryTime
    if interval > 0.05 and interval < 5 then insert(AntiDetect.ParryHistory, interval); if #AntiDetect.ParryHistory > AntiDetect.MaxHistorySize then remove(AntiDetect.ParryHistory, 1) end end
    AntiDetect.LastParryTime = now; AnalyzePatterns()
end
local function GetAdaptiveDelay()
    local base = 0.045 + (math.random() * 2 - 1) * 0.025
    if AntiDetect.PatternScore > 50 then base = base + (math.random() * 0.04) end
    local timeSince = clock() - AntiDetect.LastParryTime
    if timeSince < 0.12 then base = base + (0.12 - timeSince) end
    return math.max(0, base)
end
local function ShouldIntentionalMiss()
    AntiDetect.ConsecutiveParries = AntiDetect.ConsecutiveParries + 1; AntiDetect.StreakCounter = AntiDetect.StreakCounter + 1
    if AntiDetect.ConsecutiveParries >= 8 then AntiDetect.ConsecutiveParries = 0; return true end
    if math.random() < math.min(0.015 + (AntiDetect.StreakCounter * 0.002), 0.05) then AntiDetect.ConsecutiveParries = 0; return true end
    return false
end

--------------------------------------------------------------------------------
-- HID SYSTEM (Parry Only)
--------------------------------------------------------------------------------
local HID = { Method = "VirtualInput" }
if Env.HasKeypress then
    HID.Method = "keypress"
    HID.Press = function(kc) pcall(function() keypress(kc.Name); task.delay(GetHumanDelay(), function() keyrelease(kc.Name) end) end) end
elseif Env.HasSendInput then
    HID.Method = "sendinput"
    HID.Press = function(kc) pcall(function() sendinput({Type="KeyDown", Key=kc.Name}); task.delay(GetHumanDelay(), function() sendinput({Type="KeyUp", Key=kc.Name}) end) end) end
else
    HID.Press = function(kc) pcall(function() VirtualInputManager:SendKeyEvent(true, kc, false, game); task.delay(GetHumanDelay(), function() VirtualInputManager:SendKeyEvent(false, kc, false, game) end) end) end
end
local function HumanParry()
    if ShouldIntentionalMiss() then return end
    local delay = GetAdaptiveDelay()
    task.delay(delay, function() if not State.AutoParry then return end; HID.Press(Enum.KeyCode.Space); RecordParryTiming() end)
end

--------------------------------------------------------------------------------
-- BALL DETECTION (ZERO STRING ALLOCATION)
--------------------------------------------------------------------------------
local function FindBall()
    local now = clock()
    if CachedBall and CachedBall.Parent and (now - LastBallCheckTime) < 0.05 then return CachedBall end
    LastBallCheckTime = now; CachedBall = nil
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("BasePart") then
            local n = obj.Name
            if n == "ball" or n == "Ball" or n == "BALL" or n == "sphereball" or n == "SphereBall" or n == "projectile" or n == "Projectile" then
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
local function BallSpeed(ball) if not ball then return 0 end; local v = ball.AssemblyLinearVelocity; return (v.X * v.X + v.Y * v.Y + v.Z * v.Z) ^ 0.5 end
local function CalculateTimeToImpact(ball, rootPart)
    if not ball or not rootPart then return 999 end; local speed = BallSpeed(ball); if speed < 1 then return 999 end
    local dir = rootPart.Position - (ball.Position + ball.AssemblyLinearVelocity * 0.08)
    local vel = ball.AssemblyLinearVelocity; local dot = vel.X * dir.X + vel.Y * dir.Y + vel.Z * dir.Z
    if dot <= 0 then return 999 end; return dir.Magnitude / (dot / dir.Magnitude)
end

--------------------------------------------------------------------------------
-- VISUALIZER
--------------------------------------------------------------------------------
local Viz = { Parts = {} }
local function CreateInvisiblePart(config)
    local p = Instance.new("Part"); p.Name = config.Name; p.Anchored = true; p.CanCollide = false; p.Massless = true
    p.Size = config.Size; p.Position = Vector3.new(0, -5000, 0); p.Shape = config.Shape or Enum.PartType.Ball
    p.Material = Enum.Material.ForceField; p.Transparency = 1; p.CastShadow = false; p.ReceiveShadow = false; p.Parent = workspace
    insert(Viz.Parts, p); return p
end
local function InitializeVisualizer()
    if State.VizActive then return end; State.VizActive = true
    Viz.RangeRing = CreateInvisiblePart({ Name = "Thyren_Range", Size = Vector3.new(0.2, 1, 1), Shape = Enum.PartType.Cylinder })
    Viz.BallTracker = CreateInvisiblePart({ Name = "Thyren_BallTracker", Size = Vector3.new(0.1, 0.1, 0.1) })
    Viz.Trajectory = CreateInvisiblePart({ Name = "Thyren_Trajectory", Size = Vector3.new(0.05, 0.05, 1), Shape = Enum.PartType.Block })
    Viz.Prediction = CreateInvisiblePart({ Name = "Thyren_Prediction", Size = Vector3.new(0.3, 0.3, 0.3) })
    Viz.TriggerZone = CreateInvisiblePart({ Name = "Thyren_TriggerZone", Size = Vector3.new(0.5, 0.5, 0.5) })
end
local function CleanupVisualizer()
    for i = 1, #Viz.Parts do if Viz.Parts[i] and Viz.Parts[i].Parent then Viz.Parts[i]:Destroy() end end
    Viz.Parts = {}; State.VizActive = false
end

--------------------------------------------------------------------------------
-- ULTRA OPTIMIZED MACRO ENGINE
--------------------------------------------------------------------------------
local Accumulator = 0; local OrganicPressCount = 0
local function StartMacro()
    State.Running = true; ResetStreak(); Accumulator = 0; OrganicPressCount = 0
    Connections.Macro = RunService.Heartbeat:Connect(function(dt)
        local acc = Accumulator + (dt * State.Speed); local count = OrganicPressCount + 1; OrganicPressCount = count
        if count % 47 == 0 then acc = acc * 0.85 elseif count % 103 == 0 then acc = acc * 1.15 end
        if acc > 15 then acc = 15 end 
        if State.Mode == "KPS" then
            local vim = VirtualInputManager; local send = VIM_SendKeyEvent; local kf = KeyCode_F
            while acc >= 1 do send(vim, true, kf, false, game); send(vim, false, kf, false, game); acc = acc - 1 end
        else
            local m = UserInputService:GetMouseLocation(); local mx, my = m.X, m.Y; local vim = VirtualInputManager
            while acc >= 1 do vim:SendMouseButtonEvent(mx, my, 0, true, game, 0); vim:SendMouseButtonEvent(mx, my, 0, false, game, 0); acc = acc - 1 end
        end
        Accumulator = acc
    end)
end
local function StopMacro()
    State.Running = false; ResetStreak(); Accumulator = 0
    if Connections.Macro then Connections.Macro:Disconnect(); Connections.Macro = nil end
end
local function ToggleMacro() if State.Running then StopMacro() else StartMacro() end end

local function StartAutoParry()
    if State.VizEnabled then InitializeVisualizer() end
    if Connections.Parry then Connections.Parry:Disconnect() end
    Connections.Parry = RunService.Heartbeat:Connect(function()
        if not State.AutoParry then return end
        local char = LocalPlayer.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then LastFoundBallForUI = nil; return end
        local ball = FindBall(); LastFoundBallForUI = ball
        if not ball then return end
        local dist = (ball.Position - root.Position).Magnitude; local spd = BallSpeed(ball); local shouldParry = false
        if State.Predictive then shouldParry = CalculateTimeToImpact(ball, root) <= (0.06 + (0.03 / (spd * 0.015 + 1)))
        else shouldParry = dist <= clamp(State.Threshold + (spd > 40 and spd * 0.18 or 0), 15, 70) end
        if shouldParry then HumanParry() end
    end)
end
local function StopAutoParry()
    if Connections.Parry then Connections.Parry:Disconnect(); Connections.Parry = nil end
    LastFoundBallForUI = nil; CleanupVisualizer()
end

--------------------------------------------------------------------------------
-- THEME & SAFE UI BUILDERS
--------------------------------------------------------------------------------
local Theme = {
    Background = Color3.fromRGB(12, 12, 16), Surface = Color3.fromRGB(20, 20, 26), Card = Color3.fromRGB(28, 28, 36),
    Hover = Color3.fromRGB(40, 40, 52), Accent = Color3.fromRGB(90, 90, 110), AccentLight = Color3.fromRGB(130, 130, 155),
    Success = Color3.fromRGB(55, 175, 95), Warning = Color3.fromRGB(205, 145, 35), Error = Color3.fromRGB(200, 65, 65),
    Info = Color3.fromRGB(95, 135, 215), Purple = Color3.fromRGB(135, 95, 195), TextPrimary = Color3.fromRGB(210, 210, 222),
    TextSecondary = Color3.fromRGB(140, 140, 158), TextMuted = Color3.fromRGB(80, 80, 100), TextDisabled = Color3.fromRGB(50, 50, 65),
    Border = Color3.fromRGB(35, 35, 48), ActiveRed = Color3.fromRGB(40, 18, 18), ActiveGreen = Color3.fromRGB(18, 35, 22),
}
local function MakeCorner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p end
local function MakeStroke(p) local s = Instance.new("UIStroke"); s.Color = Theme.Border; s.Thickness = 1; s.Transparency = 0.2; s.Parent = p end
local function MakeLabel(p)
    local l = Instance.new("TextLabel"); l.Name = p.Name; l.Size = p.Size; l.Position = p.Position; l.BackgroundTransparency = 1
    l.Text = p.Text or ""; l.TextColor3 = p.Color or Theme.TextSecondary; l.TextSize = p.TextSize or 11
    l.Font = p.Font or Enum.Font.GothamMedium; l.TextXAlignment = p.XAlign or Enum.TextXAlignment.Left; l.Parent = p.Parent; return l
end
local function MakeButton(p)
    local b = Instance.new("TextButton"); b.Name = p.Name; b.Size = p.Size; b.Position = p.Position
    b.BackgroundColor3 = p.Color or Theme.Card; b.BorderSizePixel = 0; b.Text = p.Text or ""
    b.TextColor3 = p.TextColor or Theme.TextPrimary; b.TextSize = p.TextSize or 11
    b.Font = p.Font or Enum.Font.GothamBold; b.AutoButtonColor = false; b.Parent = p.Parent
    if p.Corner then MakeCorner(b, p.Corner) end; if p.Stroke then MakeStroke(b) end
    local col = p.Color or Theme.Card
    b.MouseEnter:Connect(function() b.BackgroundColor3 = Theme.Hover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = col end)
    return b
end
local function MakeFrame(p)
    local f = Instance.new("Frame"); f.Name = p.Name; f.Size = p.Size; f.Position = p.Position
    f.BackgroundColor3 = p.Color or Theme.Surface; f.BorderSizePixel = 0; f.BackgroundTransparency = p.Transparency or 0
    f.Parent = p.Parent; if p.Corner then MakeCorner(f, p.Corner) end; if p.Stroke then MakeStroke(f) end; return f
end
local function MakeSlider(p)
    local t = MakeFrame({Name=p.Name, Size=p.Size, Position=p.Position, Color=Color3.fromRGB(28,28,38), Parent=p.Parent, Corner=2})
    local fill = MakeFrame({Name="Fill", Size=UDim2.new(p.FillFraction or 0.004, 0, 1, 0), Color=Theme.Accent, Parent=t, Corner=2})
    local h = Instance.new("TextButton"); h.Name="Handle"; local hs = p.HandleSize or 10
    h.Size = UDim2.new(0, hs, 0, hs); h.Position = UDim2.new(p.FillFraction or 0.004, -hs/2, 0.5, -hs/2)
    h.BackgroundColor3 = Theme.AccentLight; h.BorderSizePixel = 0; h.Text = ""; h.AutoButtonColor = false; h.Parent = t
    MakeCorner(h, hs/2); return t, fill, h
end
local function MakeDot(p)
    local d = Instance.new("Frame"); d.Name = p.Name; local s = p.Size or 6
    d.Size = UDim2.new(0, s, 0, s); d.Position = p.Position; d.BackgroundColor3 = p.Color or Theme.TextDisabled
    d.BorderSizePixel = 0; d.Parent = p.Parent; MakeCorner(d, s/2); return d
end

--------------------------------------------------------------------------------
-- BUILD EXACT IMAGE LAYOUT
--------------------------------------------------------------------------------
local Container = Instance.new("Frame"); Container.Name = "Container"; Container.Size = UDim2.new(1, 0, 1, 0); Container.BackgroundTransparency = 1; Container.Parent = ScreenGui
local PANEL_W, PANEL_H = 600, 280
local MainPanel = MakeFrame({Name="MainPanel", Size=UDim2.new(0,PANEL_W,0,PANEL_H), Position=UDim2.new(0.5,-PANEL_W/2,0.5,-PANEL_H/2 - 30), Color=Theme.Background, Corner=10, Stroke=true, Parent=Container})
MainPanel.Active = true; MainPanel.Draggable = true

-- TOP AREA: THYREN + MACRO
local TopArea = MakeFrame({Name="TopArea", Size=UDim2.new(1, -20, 0, 130), Position=UDim2.new(0, 10, 0, 10), Transparency=1, Parent=MainPanel})
MakeLabel({Name="Title", Size=UDim2.new(0,70,0,20), Position=UDim2.new(0,0,0,0), Text="THYREN", Color=Theme.TextPrimary, TextSize=16, Font=Enum.Font.GothamBlack, Parent=TopArea})
MakeDot({Name="TitleDot", Size=6, Position=UDim2.new(0,74,0,7), Color=Theme.Info, Parent=TopArea}) -- Blue dot from image
MakeLabel({Name="MacroTitle", Size=UDim2.new(0,50,0,14), Position=UDim2.new(0,0,0,24), Text="MACRO", Color=Theme.TextDisabled, TextSize=9, Font=Enum.Font.GothamBold, Parent=TopArea})

local ModeButton = MakeButton({Name="ModeBtn", Size=UDim2.new(0.3,0,0,28), Position=UDim2.new(0,0,0,44), Text="KPS", TextSize=10, Corner=6, Parent=TopArea})
local BindButton = MakeButton({Name="BindBtn", Size=UDim2.new(0.3,0,0,28), Position=UDim2.new(0.32,0,0,44), Text="KEYBIND", TextColor=Theme.TextSecondary, TextSize=10, Corner=6, Parent=TopArea})
local SpeedVal = MakeLabel({Size=UDim2.new(0,60,0,22), Position=UDim2.new(0,0,0,78), Text="10 KPS", Color=Theme.TextPrimary, TextSize=16, Font=Enum.Font.GothamBold, Parent=TopArea})
MakeLabel({Size=UDim2.new(0,40,0,12), Position=UDim2.new(0,0,0,100), Text="SPEED", Color=Theme.TextDisabled, TextSize=7, Font=Enum.Font.GothamBold, Parent=TopArea})
local SpeedTrack, SpeedFill, SpeedHandle = MakeSlider({Name="SpeedSlider", Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,115), HandleSize=12, Parent=TopArea})

-- HORIZONTAL SEPARATOR
local SepH = Instance.new("Frame"); SepH.Size = UDim2.new(1, 0, 0, 1); SepH.Position = UDim2.new(0, 10, 0, 145); SepH.BackgroundColor3 = Theme.Border; SepH.BackgroundTransparency = 0.4; SepH.BorderSizePixel = 0; SepH.Parent = MainPanel

-- BOTTOM AREA: LEFT (AUTO PARRY) & RIGHT (DIAGNOSTICS)
local BottomArea = MakeFrame({Name="BottomArea", Size=UDim2.new(1, -20, 0, 120), Position=UDim2.new(0, 10, 0, 150), Transparency=1, Parent=MainPanel})

-- Left Column: Auto Parry
local LeftCol = MakeFrame({Size=UDim2.new(0.55, 0, 1, 0), Transparency=1, Parent=BottomArea})
MakeLabel({Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,0), Text="AUTO PARRY", Color=Theme.TextDisabled, TextSize=9, Font=Enum.Font.GothamBold, Parent=LeftCol})

local ParryButton = MakeButton({Name="ParryBtn", Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,18), Text="AUTO PARRY", TextColor=Theme.TextMuted, TextSize=11, Corner=8, Parent=LeftCol})
local ParryDot = MakeDot({Size=5, Position=UDim2.new(1,-15,0.5,-2.5), Color=Theme.TextDisabled, Parent=ParryButton})

local PredictBtn = MakeButton({Size=UDim2.new(0.48,0,0,24), Position=UDim2.new(0,0,0,54), Text="PREDICT", TextColor=Theme.Success, TextSize=8, Corner=5, Parent=LeftCol})
local VizBtn = MakeButton({Size=UDim2.new(0.48,0,0,24), Position=UDim2.new(0.52,0,0,54), Text="VISUAL", TextColor=Theme.Purple, TextSize=8, Corner=5, Parent=LeftCol})

local ThreshVal = MakeLabel({Size=UDim2.new(0,20,0,16), Position=UDim2.new(0,0,0,84), Text="28", Color=Theme.TextSecondary, TextSize=13, Font=Enum.Font.GothamBold, Parent=LeftCol})
MakeLabel({Size=UDim2.new(0,55,0,12), Position=UDim2.new(0,0,0,100), Text="THRESHOLD", Color=Theme.TextDisabled, TextSize=7, Font=Enum.Font.GothamBold, Parent=LeftCol})
local ThreshTrack, ThreshFill, ThreshHandle = MakeSlider({Name="ThreshSlider", Size=UDim2.new(1,0,0,4), Position=UDim2.new(0,0,0,114), HandleSize=8, Parent=LeftCol})

-- VERTICAL SEPARATOR
local SepV = Instance.new("Frame"); SepV.Size = UDim2.new(0, 1, 1, 0); SepV.Position = UDim2.new(0.55, 0, 0, 0); SepV.BackgroundColor3 = Theme.Border; SepV.BackgroundTransparency = 0.4; SepV.BorderSizePixel = 0; SepV.Parent = BottomArea

-- Right Column: Diagnostics
local RightCol = MakeFrame({Size=UDim2.new(0.45, -10, 1, 0), Position=UDim2.new(0.55, 10, 0, 0), Transparency=1, Parent=BottomArea})
MakeLabel({Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,0), Text="DIAGNOSTICS", Color=Theme.TextDisabled, TextSize=9, Font=Enum.Font.GothamBold, Parent=RightCol})

local DiagDots, DiagTexts = {}, {}
for i, d in ipairs({{id="Macro", t="MACRO: IDLE"}, {id="Parry", t="PARRY: OFF"}, {id="Ball", t="TARGET: NONE"}, {id="Viz", t="VIZ: OFF"}, {id="HID", t="INPUT: ULTRA"}, {id="Pattern", t="BOT: 0%"}}) do
    local xo, yo = 0, 18 + ((i-1)%3)*30
    if i > 3 then xo = 0.5; yo = 18 + ((i-4)%3)*30 end
    DiagDots[d.id] = MakeDot({Name="DD_"..d.id, Size=4, Position=UDim2.new(xo, 4, 0, yo+2), Color=Theme.TextDisabled, Parent=RightCol})
    DiagTexts[d.id] = MakeLabel({Name="DT_"..d.id, Size=UDim2.new(0.5, -16, 0, 18), Position=UDim2.new(xo, 14, 0, yo), Text=d.t, Color=Theme.TextMuted, TextSize=9, Parent=RightCol})
end

-- Separate Draggable Activate Button
local ActivateFrame = MakeFrame({Name="ActivateFrame", Size=UDim2.new(0,150,0,32), Position=UDim2.new(0.5,-75,0.5,PANEL_H/2 - 30 + 10), Color=Theme.Surface, Corner=8, Stroke=true, Parent=Container})
local ActivateButton = MakeButton({Name="ActivateButton", Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,0), Color=Theme.Surface, Text="ACTIVATE", TextColor=Theme.TextPrimary, TextSize=11, Corner=8, Parent=ActivateFrame})
local ActDot = MakeDot({Name="ActDot", Size=5, Position=UDim2.new(1,-14,0.5,-2.5), Color=Theme.TextDisabled, Parent=ActivateButton})

local actDragging, actMoved, actStart, actInitialPos = false, false, nil, nil
ActivateButton.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then actDragging=true; actMoved=false; actStart=i.Position; actInitialPos=ActivateFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if actDragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-actStart; if math.abs(d.X)>5 or math.abs(d.Y)>5 then actMoved=true; ActivateFrame.Position=UDim2.new(actInitialPos.X.Scale,actInitialPos.X.Offset+d.X,actInitialPos.Y.Scale,actInitialPos.Y.Offset+d.Y) end end end)
ActivateButton.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then actDragging=false end end)

--------------------------------------------------------------------------------
-- ULTRA THROTTLED UI UPDATE (10 FPS Isolated Recursive Loop)
--------------------------------------------------------------------------------
local function UpdateUI()
    local aColor = State.Running and Theme.ActiveRed or Theme.Surface
    if UICache.ActColor ~= aColor then ActivateButton.BackgroundColor3 = aColor; UICache.ActColor = aColor end
    local aText = State.Running and "STOP" or "ACTIVATE"
    if UICache.ActText ~= aText then ActivateButton.Text = aText; UICache.ActText = aText end
    local aDotColor = State.Running and Theme.Success or Theme.TextDisabled
    if UICache.ActDotColor ~= aDotColor then ActDot.BackgroundColor3 = aDotColor; UICache.ActDotColor = aDotColor end

    local pColor = State.AutoParry and Theme.ActiveGreen or Theme.Card
    if UICache.ParryColor ~= pColor then ParryButton.BackgroundColor3 = pColor; UICache.ParryColor = pColor end
    local pDotColor = State.AutoParry and Theme.Success or Theme.TextDisabled
    if UICache.ParryDotColor ~= pDotColor then ParryDot.BackgroundColor3 = pDotColor; UICache.ParryDotColor = pDotColor end
    if UICache.PredColor ~= (State.Predictive and Theme.Success or Theme.TextMuted) then PredictBtn.TextColor3 = State.Predictive and Theme.Success or Theme.TextMuted; UICache.PredColor = PredictBtn.TextColor3 end
    if UICache.VizColor ~= (State.VizEnabled and Theme.Purple or Theme.TextMuted) then VizBtn.TextColor3 = State.VizEnabled and Theme.Purple or Theme.TextMuted; UICache.VizColor = VizBtn.TextColor3 end

    local sText = State.Speed .. " " .. State.Mode
    if UICache.SpeedText ~= sText then SpeedVal.Text = sText; UICache.SpeedText = sText end
    if UICache.ModeText ~= State.Mode then ModeButton.Text = State.Mode; UICache.ModeText = State.Mode end
    local bText = State.Binding and "..." or (State.Hotkey and State.Hotkey.Name or "KEYBIND")
    if UICache.BindText ~= bText then BindButton.Text = bText; UICache.BindText = bText end
    local tText = tostring(State.Threshold)
    if UICache.ThreshText ~= tText then ThreshVal.Text = tText; UICache.ThreshText = tText end
    local stText = "STREAK: " .. AntiDetect.StreakCounter
    if UICache.StreakText ~= stText then StreakLabel.Text = stText; UICache.StreakText = stText end

    SpeedFill.Size = UDim2.new(clamp((State.Speed - 1) / 2499, 0.004, 1), 0, 1, 0)
    SpeedHandle.Position = UDim2.new(clamp((State.Speed - 1) / 2499, 0.004, 1), -6, 0.5, -6)
    ThreshFill.Size = UDim2.new(clamp((State.Threshold - 5) / 65, 0.004, 1), 0, 1, 0)
    ThreshHandle.Position = UDim2.new(clamp((State.Threshold - 5) / 65, 0.004, 1), -4, 0.5, -4)

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
        local dist = 999; local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then dist = (ball.Position - root.Position).Magnitude end
        local dbText = "TARGET: " .. floor(dist) .. "s"
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

    local ps = floor(AntiDetect.PatternScore)
    local dpatText = "BOT: " .. ps .. "%"
    local dpatColor = ps > 60 and Theme.Error or (ps > 30 and Theme.Warning or Theme.Success)
    if UICache.DpatText ~= dpatText then DiagTexts.Pattern.Text = dpatText; UICache.DpatText = dpatText end
    if UICache.DpatColor ~= dpatColor then DiagDots.Pattern.BackgroundColor3 = dpatColor; UICache.DpatColor = dpatColor end

    task.delay(0.1, UpdateUI)
end

--------------------------------------------------------------------------------
-- SLIDERS & EVENTS
--------------------------------------------------------------------------------
local function MakeSliderWork(track, fill, handle, minVal, maxVal, callback)
    local dragging = false
    local function update(input)
        local frac = clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        callback(clamp(floor(minVal + frac * (maxVal - minVal)), minVal, maxVal))
    end
    handle.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i) end end)
end

MakeSliderWork(SpeedTrack, SpeedFill, SpeedHandle, 1, 2500, function(v) State.Speed = v end)
MakeSliderWork(ThreshTrack, ThreshFill, ThreshHandle, 5, 70, function(v) State.Threshold = v end)

ModeButton.MouseButton1Click:Connect(function() State.Mode = State.Mode == "KPS" and "CPS" or "KPS" end)
BindButton.MouseButton1Click:Connect(function() State.Binding = true end)
ActivateButton.MouseButton1Click:Connect(function() if actMoved then actMoved=false; return end; ToggleMacro() end)
ParryButton.MouseButton1Click:Connect(function() State.AutoParry = not State.AutoParry; if State.AutoParry then StartAutoParry() else StopAutoParry() end end)
PredictBtn.MouseButton1Click:Connect(function() State.Predictive = not State.Predictive end)
VizBtn.MouseButton1Click:Connect(function() State.VizEnabled = not State.VizEnabled; if not State.VizEnabled and State.VizActive then CleanupVisualizer() end; if State.VizEnabled and State.AutoParry then InitializeVisualizer() end end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if State.Binding then
        if input.KeyCode ~= Enum.KeyCode.Unknown then State.Hotkey = input.KeyCode; State.Binding = false end; return
    end
    if State.Hotkey and input.KeyCode == State.Hotkey then ToggleMacro(); return end
    if input.KeyCode == Enum.KeyCode.RightShift then State.Visible = not State.Visible; MainPanel.Visible = State.Visible; ActivateFrame.Visible = State.Visible end
end)

UpdateUI()
