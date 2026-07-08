--[[
    Thyren - Blade Ball
    Invisible Visualizer + HID Emulation
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerName = LocalPlayer.Name

if game.CoreGui:FindFirstChild("ThyrenUI") then
    game.CoreGui:FindFirstChild("ThyrenUI"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThyrenUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

local function SecureParent(gui)
    if syn and syn.protect_gui then syn.protect_gui(gui) gui.Parent = game.CoreGui return true end
    if protect_gui then protect_gui(gui) gui.Parent = game.CoreGui return true end
    if gethui then local s, _ = pcall(function() gui.Parent = gethui() end) if s then return true end end
    local ok, _ = pcall(function() gui.Parent = game.CoreGui end) if ok then return true end
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    return true
end
SecureParent(ScreenGui)

-- ═══════════════════════════════════════════════
-- HID SYSTEM
-- ═══════════════════════════════════════════════

local HID = { Supported = false, Method = "VirtualInput" }

local function DetectHID()
    if keypress and keyrelease then
        HID.Method = "keypress"
        HID.Supported = true
        HID.Press = function(key)
            keypress(key)
            task.delay(0.01 + math.random() * 0.02, keyrelease, key)
        end
        return
    end
    if sendinput then
        HID.Method = "sendinput"
        HID.Supported = true
        HID.Press = function(key)
            sendinput({Type = "KeyDown", Key = key})
            task.delay(0.01 + math.random() * 0.02, function()
                sendinput({Type = "KeyUp", Key = key})
            end)
        end
        return
    end
    HID.Method = "VirtualInput"
    HID.Supported = true
    HID.Press = function(keyCode)
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.delay(0.01 + math.random() * 0.02, function()
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end)
    end
end
DetectHID()

local function SimInput(keyCode)
    local v = math.random(-6, 6) / 1000
    task.delay(math.max(0, v), function()
        HID.Press(keyCode)
    end)
end

-- ═══════════════════════════════════════════════
-- INVISIBLE VISUALIZER
-- ═══════════════════════════════════════════════

local Viz = {
    Parts = {},
    Active = false,
}

local function CreateVizPart(properties)
    local part = Instance.new("Part")
    part.Name = properties.Name or "VizPart"
    part.Anchored = true
    part.CanCollide = false
    part.Massless = true
    part.Size = properties.Size or Vector3.new(1, 1, 1)
    part.Position = properties.Position or Vector3.new(0, 0, 0)
    part.Shape = properties.Shape or Enum.PartType.Ball
    part.Material = Enum.Material.ForceField
    part.Color = properties.Color or Color3.new(1, 1, 1)
    part.Transparency = 1 -- FULLY INVISIBLE
    part.CastShadow = false
    part.ReceiveShadow = false
    part.Parent = workspace
    table.insert(Viz.Parts, part)
    return part
end

local function InitVisualizer()
    if Viz.Active then return end
    Viz.Active = true
    
    -- Range ring (invisible cylinder around player)
    Viz.RangeRing = CreateVizPart({
        Name = "ThyrenRange",
        Size = Vector3.new(1, 0.1, 1),
        Shape = Enum.PartType.Cylinder,
        Position = Vector3.new(0, -1000, 0),
    })
    Viz.RangeRing.Orientation = Vector3.new(0, 0, 90)
    
    -- Ball tracker (follows ball position)
    Viz.BallTracker = CreateVizPart({
        Name = "ThyrenTracker",
        Size = Vector3.new(0.5, 0.5, 0.5),
        Shape = Enum.PartType.Ball,
        Position = Vector3.new(0, -1000, 0),
    })
    
    -- Trajectory line (invisible part between ball and player)
    Viz.TrajectoryLine = CreateVizPart({
        Name = "ThyrenTrajectory",
        Size = Vector3.new(0.1, 0.1, 1),
        Shape = Enum.PartType.Block,
        Position = Vector3.new(0, -1000, 0),
    })
    
    -- Prediction point (where ball will be)
    Viz.PredictionPoint = CreateVizPart({
        Name = "ThyrenPrediction",
        Size = Vector3.new(1, 1, 1),
        Shape = Enum.PartType.Ball,
        Position = Vector3.new(0, -1000, 0),
    })
    
    -- Parry zone indicator
    Viz.ParryZone = CreateVizPart({
        Name = "ThyrenParryZone",
        Size = Vector3.new(1, 1, 1),
        Shape = Enum.PartType.Ball,
        Position = Vector3.new(0, -1000, 0),
    })
end

local function UpdateVisualizer(ball, root, dist, tti, shouldParry)
    if not Viz.Active or not root then return end
    
    local thresh = State.Threshold
    if ball then
        local spd = BSpd(ball)
        if spd > 40 then thresh = thresh + (spd * 0.18) end
        thresh = math.clamp(thresh, 15, 70)
    end
    
    -- Update range ring around player
    local ringSize = thresh * 2
    Viz.RangeRing.Size = Vector3.new(0.1, ringSize, ringSize)
    Viz.RangeRing.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
    
    if ball then
        -- Ball tracker follows ball
        Viz.BallTracker.Position = ball.Position
        
        -- Trajectory line from ball to player
        local dir = root.Position - ball.Position
        local dist2 = dir.Magnitude
        if dist2 > 0 then
            local mid = ball.Position + dir * 0.5
            Viz.TrajectoryLine.Size = Vector3.new(0.1, 0.1, dist2)
            Viz.TrajectoryLine.CFrame = CFrame.lookAt(mid, root.Position)
        end
        
        -- Prediction point (future ball position)
        if ball.AssemblyLinearVelocity then
            local predPos = ball.Position + ball.AssemblyLinearVelocity * math.min(tti, 0.5)
            Viz.PredictionPoint.Position = predPos
        end
        
        -- Parry zone at threshold distance
        if dist > 0 then
            local zonePos = ball.Position + (root.Position - ball.Position).Unit * thresh
            Viz.ParryZone.Position = zonePos
        end
    else
        -- Hide when no ball
        Viz.BallTracker.Position = Vector3.new(0, -1000, 0)
        Viz.TrajectoryLine.Position = Vector3.new(0, -1000, 0)
        Viz.PredictionPoint.Position = Vector3.new(0, -1000, 0)
        Viz.ParryZone.Position = Vector3.new(0, -1000, 0)
    end
end

local function CleanupVisualizer()
    for _, part in ipairs(Viz.Parts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    Viz.Parts = {}
    Viz.Active = false
end

-- ═══════════════════════════════════════════════
-- ANTI-DETECTION
-- ═══════════════════════════════════════════════

local AD = {
    History = {},
    MaxHist = 20,
    LastParry = 0,
    MinInterval = 0.08,
    Jitter = 0.012,
}

local function GetJitter()
    return (math.random() * 2 - 1) * AD.Jitter
end

local function CheckConsistency()
    local now = os.clock()
    local since = now - AD.LastParry
    table.insert(AD.History, since)
    if #AD.History > AD.MaxHist then table.remove(AD.History, 1) end
    
    local avg = 0
    for _, v in ipairs(AD.History) do avg = avg + v end
    avg = avg / #AD.History
    
    local variance = 0
    for _, v in ipairs(AD.History) do variance = variance + (v - avg)^2 end
    variance = (variance / #AD.History)^0.5
    
    if variance < 0.01 and #AD.History > 5 then
        return true, GetJitter() * 3
    end
    return false, 0
end

local function HumanParry()
    local now = os.clock()
    if (now - AD.LastParry) < AD.MinInterval then return end
    
    local consistent, extra = CheckConsistency()
    local delay = GetJitter() + (consistent and extra or 0)
    
    task.delay(math.max(0, delay), function()
        SimInput(Enum.KeyCode.Space)
        AD.LastParry = os.clock()
    end)
end

-- ═══════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════

local State = {
    Running = false,
    Speed = 10,
    Mode = "KPS",
    Hotkey = nil,
    Binding = false,
    AutoParry = false,
    Threshold = 28,
    Predictive = true,
    Visible = true,
    VizEnabled = true,
}

local Conn = {}
local LastFire = 0
local CachedBall = nil
local LastCheck = 0

-- ═══════════════════════════════════════════════
-- BALL DETECTION
-- ═══════════════════════════════════════════════

local function FindBall()
    local now = os.clock()
    if CachedBall and CachedBall.Parent and (now - LastCheck) < 0.05 then
        return CachedBall
    end
    LastCheck = now
    CachedBall = nil
    
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n == "ball" or n == "sphereball" or n == "projectile" then
                local t = v:GetAttribute("target") or v:GetAttribute("Target") or v:GetAttribute("TargetPlayer")
                if not t then
                    local tv = v:FindFirstChild("target") or v:FindFirstChild("Target") or v:FindFirstChild("TargetPlayer")
                    if tv then
                        if tv:IsA("StringValue") then t = tv.Value
                        elseif tv:IsA("ObjectValue") and tv.Value then t = tv.Value.Name end
                    end
                end
                if t == nil or t == PlayerName then
                    CachedBall = v
                    return v
                end
            end
        end
    end
    
    for _, fn in {"Balls", "Projectiles", "ball", "ProjectilesFolder"} do
        local f = workspace:FindFirstChild(fn)
        if f then
            for _, v in pairs(f:GetChildren()) do
                if v:IsA("BasePart") then
                    local t = v:GetAttribute("target") or v:GetAttribute("Target")
                    if not t then
                        local tv = v:FindFirstChild("target") or v:FindFirstChild("Target")
                        if tv and tv.Value then t = typeof(tv.Value) == "string" and tv.Value or tv.Value.Name end
                    end
                    if t == nil or t == PlayerName then
                        CachedBall = v
                        return v
                    end
                end
            end
        end
    end
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("ball") or n:find("projectile") then
                local t = v:GetAttribute("target") or v:GetAttribute("Target")
                if t == nil or t == PlayerName then
                    CachedBall = v
                    return v
                end
            end
        end
    end
    
    return nil
end

local function BSpd(b)
    if not b then return 0 end
    local v = b.AssemblyLinearVelocity
    return (v.X*v.X + v.Y*v.Y + v.Z*v.Z)^0.5
end

local function TTI(ball, root)
    if not ball or not root then return 999 end
    local spd = BSpd(ball)
    if spd < 1 then return 999 end
    
    local ballPos = ball.Position
    local rootPos = root.Position
    local vel = ball.AssemblyLinearVelocity
    
    local predictTime = 0.1
    local futurePos = ballPos + vel * predictTime
    local dir = rootPos - futurePos
    local dist = dir.Magnitude
    
    local dot = vel.X*dir.X + vel.Y*dir.Y + vel.Z*dir.Z
    if dot <= 0 then return 999 end
    
    return dist / (dot / dir.Magnitude)
end

-- ═══════════════════════════════════════════════
-- MACRO
-- ═══════════════════════════════════════════════

local function MacroTick()
    if not State.Running then return end
    local now = os.clock()
    if State.Speed >= 60 then
        SimInput(Enum.KeyCode.Space)
        SimInput(Enum.KeyCode.Space)
    elseif (now - LastFire) >= (1 / State.Speed) then
        LastFire = now
        SimInput(Enum.KeyCode.Space)
    end
end

local function StartMacro()
    State.Running = true
    LastFire = os.clock()
    if Conn.Macro then Conn.Macro:Disconnect() end
    Conn.Macro = RunService.PreRender:Connect(MacroTick)
end

local function StopMacro()
    State.Running = false
    if Conn.Macro then Conn.Macro:Disconnect() Conn.Macro = nil end
end

-- ═══════════════════════════════════════════════
-- AUTO PARRY WITH VISUALIZER
-- ═══════════════════════════════════════════════

local function StartParry()
    InitVisualizer()
    if Conn.Parry then Conn.Parry:Disconnect() end
    
    Conn.Parry = RunService.Heartbeat:Connect(function(dt)
        if not State.AutoParry then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then
            if Viz.Active then
                for _, p in ipairs(Viz.Parts) do
                    if p.Parent then p.Position = Vector3.new(0, -1000, 0) end
                end
            end
            return
        end
        
        local ball = FindBall()
        local dist = ball and (ball.Position - root.Position).Magnitude or 999
        local spd = ball and BSpd(ball) or 0
        local tti = ball and TTI(ball, root) or 999
        local doParry = false
        
        if ball then
            if State.Predictive then
                local window = 0.06 + (0.03 / (spd * 0.015 + 1))
                doParry = tti <= window
            else
                local thresh = State.Threshold
                if spd > 40 then thresh = thresh + (spd * 0.18) end
                thresh = math.clamp(thresh, 15, 70)
                doParry = dist <= thresh
            end
        end
        
        -- Update visualizer
        if State.VizEnabled and Viz.Active then
            UpdateVisualizer(ball, root, dist, tti, doParry)
        end
        
        if doParry then
            HumanParry()
        end
    end)
end

local function StopParry()
    if Conn.Parry then Conn.Parry:Disconnect() Conn.Parry = nil end
    CleanupVisualizer()
end

-- ═══════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════

local T = {
    BG = Color3.fromRGB(12, 12, 16),
    Surface = Color3.fromRGB(20, 20, 26),
    Card = Color3.fromRGB(28, 28, 36),
    Hover = Color3.fromRGB(38, 38, 48),
    Accent = Color3.fromRGB(95, 95, 115),
    AccentLit = Color3.fromRGB(135, 135, 160),
    Text = Color3.fromRGB(210, 210, 222),
    TextDim = Color3.fromRGB(115, 115, 135),
    TextOff = Color3.fromRGB(65, 65, 85),
    Border = Color3.fromRGB(38, 38, 52),
    On = Color3.fromRGB(60, 180, 100),
    Warn = Color3.fromRGB(210, 150, 40),
    HID = Color3.fromRGB(100, 140, 220),
    Viz = Color3.fromRGB(140, 100, 200),
}

-- ═══════════════════════════════════════════════
-- UI HELPERS
-- ═══════════════════════════════════════════════

local function R(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = inst
end

local function S(inst, col, a)
    local s = Instance.new("UIStroke")
    s.Color = col or T.Border
    s.Thickness = 1
    s.Transparency = a or 0.4
    s.Parent = inst
end

local function Hov(btn, base)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = T.Hover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = base}):Play()
    end)
end

local function Prs(btn)
    local p
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            p = true
            TweenService:Create(btn, TweenInfo.new(0.04), {BackgroundColor3 = Color3.fromRGB(22, 22, 28)}):Play()
        end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 and p then
            p = false
            TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = T.Hover}):Play()
        end
    end)
end

-- ═══════════════════════════════════════════════
-- BUILD UI
-- ═══════════════════════════════════════════════

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, 0, 1, 0)
Container.BackgroundTransparency = 1
Container.Parent = ScreenGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 240, 0, 245)
Main.Position = UDim2.new(0.5, -120, 0.5, -122)
Main.BackgroundColor3 = T.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = Container
R(Main, 10)
S(Main, T.Border, 0.5)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 26)
Header.BackgroundColor3 = T.Surface
Header.BorderSizePixel = 0
Header.Parent = Main
R(Header, 10)

local HF = Instance.new("Frame")
HF.Size = UDim2.new(1, 0, 0, 5)
HF.Position = UDim2.new(0, 0, 1, -5)
HF.BackgroundColor3 = T.Surface
HF.BorderSizePixel = 0
HF.Parent = Header

local TL = Instance.new("TextLabel")
TL.Size = UDim2.new(0, 55, 1, 0)
TL.Position = UDim2.new(0, 8, 0, 0)
TL.BackgroundTransparency = 1
TL.Text = "THYREN"
TL.TextColor3 = T.Text
TL.TextSize = 11
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left
TL.Parent = Header

local HD = Instance.new("Frame")
HD.Size = UDim2.new(0, 4, 0, 4)
HD.Position = UDim2.new(0, 65, 0.5, -2)
HD.BackgroundColor3 = T.HID
HD.BorderSizePixel = 0
HD.Parent = Header
R(HD, 2)

local HT = Instance.new("TextLabel")
HT.Size = UDim2.new(0, 40, 1, 0)
HT.Position = UDim2.new(0, 71, 0, 0)
HT.BackgroundTransparency = 1
HT.Text = HID.Method
HT.TextColor3 = T.TextOff
HT.TextSize = 7
HT.Font = Enum.Font.GothamMedium
HT.TextXAlignment = Enum.TextXAlignment.Left
HT.Parent = Header

local CH = Instance.new("TextLabel")
CH.Size = UDim2.new(0, 45, 1, 0)
CH.Position = UDim2.new(1, -50, 0, 0)
CH.BackgroundTransparency = 1
CH.Text = "RShift ▾"
CH.TextColor3 = T.TextOff
CH.TextSize = 7
CH.Font = Enum.Font.GothamMedium
CH.TextXAlignment = Enum.TextXAlignment.Right
CH.Parent = Header

local Ctn = Instance.new("Frame")
Ctn.Size = UDim2.new(1, -12, 1, -30)
Ctn.Position = UDim2.new(0, 6, 0, 28)
Ctn.BackgroundTransparency = 1
Ctn.Parent = Main

-- Row 1
local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0.47, 0, 0, 22)
ModeBtn.BackgroundColor3 = T.Card
ModeBtn.BorderSizePixel = 0
ModeBtn.Text = "KPS"
ModeBtn.TextColor3 = T.Text
ModeBtn.TextSize = 9
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.AutoButtonColor = false
ModeBtn.Parent = Ctn
R(ModeBtn, 5) Hov(ModeBtn, T.Card) Prs(ModeBtn)

local BindBtn = Instance.new("TextButton")
BindBtn.Size = UDim2.new(0.47, 0, 0, 22)
BindBtn.Position = UDim2.new(0.53, 0, 0, 0)
BindBtn.BackgroundColor3 = T.Card
BindBtn.BorderSizePixel = 0
BindBtn.Text = "BIND"
BindBtn.TextColor3 = T.Text
BindBtn.TextSize = 9
BindBtn.Font = Enum.Font.GothamBold
BindBtn.AutoButtonColor = false
BindBtn.Parent = Ctn
R(BindBtn, 5) Hov(BindBtn, T.Card) Prs(BindBtn)

-- Speed
local SpdL = Instance.new("TextLabel")
SpdL.Size = UDim2.new(0, 28, 0, 12)
SpdL.Position = UDim2.new(0, 0, 0, 26)
SpdL.BackgroundTransparency = 1
SpdL.Text = "10"
SpdL.TextColor3 = T.TextDim
SpdL.TextSize = 9
SpdL.Font = Enum.Font.GothamBold
SpdL.Parent = Ctn

local SpdU = Instance.new("TextLabel")
SpdU.Size = UDim2.new(0, 22, 0, 12)
SpdU.Position = UDim2.new(0, 28, 0, 26)
SpdU.BackgroundTransparency = 1
SpdU.Text = "KPS"
SpdU.TextColor3 = T.TextOff
SpdU.TextSize = 8
SpdU.Font = Enum.Font.GothamMedium
SpdU.Parent = Ctn

local SpdT = Instance.new("Frame")
SpdT.Size = UDim2.new(0.55, 0, 0, 3)
SpdT.Position = UDim2.new(0.45, 0, 0, 31)
SpdT.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
SpdT.BorderSizePixel = 0
SpdT.Parent = Ctn
R(SpdT, 2)

local SpdF = Instance.new("Frame")
SpdF.Size = UDim2.new(0.004, 0, 1, 0)
SpdF.BackgroundColor3 = T.Accent
SpdF.BorderSizePixel = 0
SpdF.Parent = SpdT
R(SpdF, 2)

local SpdH = Instance.new("TextButton")
SpdH.Size = UDim2.new(0, 9, 0, 9)
SpdH.Position = UDim2.new(0.004, -4.5, 0.5, -4.5)
SpdH.BackgroundColor3 = T.AccentLit
SpdH.BorderSizePixel = 0
SpdH.Text = ""
SpdH.AutoButtonColor = false
SpdH.Parent = SpdT
R(SpdH, 5)

-- Parry
local ParryBtn = Instance.new("TextButton")
ParryBtn.Size = UDim2.new(1, 0, 0, 24)
ParryBtn.Position = UDim2.new(0, 0, 0, 40)
ParryBtn.BackgroundColor3 = T.Card
ParryBtn.BorderSizePixel = 0
ParryBtn.Text = "AUTO PARRY"
ParryBtn.TextColor3 = T.TextOff
ParryBtn.TextSize = 9
ParryBtn.Font = Enum.Font.GothamBold
ParryBtn.AutoButtonColor = false
ParryBtn.Parent = Ctn
R(ParryBtn, 5) Hov(ParryBtn, T.Card) Prs(ParryBtn)

local PD = Instance.new("Frame")
PD.Size = UDim2.new(0, 5, 0, 5)
PD.Position = UDim2.new(1, -14, 0.5, -2.5)
PD.BackgroundColor3 = T.TextOff
PD.BorderSizePixel = 0
PD.Parent = ParryBtn
R(PD, 3)

-- Row 3
local PredBtn = Instance.new("TextButton")
PredBtn.Size = UDim2.new(0.47, 0, 0, 20)
PredBtn.Position = UDim2.new(0, 0, 0, 70)
PredBtn.BackgroundColor3 = T.Card
PredBtn.BorderSizePixel = 0
PredBtn.Text = "PREDICT"
PredBtn.TextColor3 = T.On
PredBtn.TextSize = 8
PredBtn.Font = Enum.Font.GothamBold
PredBtn.AutoButtonColor = false
PredBtn.Parent = Ctn
R(PredBtn, 5) Hov(PredBtn, T.Card) Prs(PredBtn)

-- Viz toggle
local VizBtn = Instance.new("TextButton")
VizBtn.Size = UDim2.new(0.47, 0, 0, 20)
VizBtn.Position = UDim2.new(0.53, 0, 0, 70)
VizBtn.BackgroundColor3 = T.Card
VizBtn.BorderSizePixel = 0
VizBtn.Text = "VIZ"
VizBtn.TextColor3 = T.Viz
VizBtn.TextSize = 8
VizBtn.Font = Enum.Font.GothamBold
VizBtn.AutoButtonColor = false
VizBtn.Parent = Ctn
R(VizBtn, 5) Hov(VizBtn, T.Card) Prs(VizBtn)

-- Threshold
local ThL = Instance.new("TextLabel")
ThL.Size = UDim2.new(0, 18, 0, 12)
ThL.Position = UDim2.new(0, 0, 0, 96)
ThL.BackgroundTransparency = 1
ThL.Text = "28"
ThL.TextColor3 = T.TextOff
ThL.TextSize = 8
ThL.Font = Enum.Font.GothamMedium
ThL.Parent = Ctn

local ThT = Instance.new("Frame")
ThT.Size = UDim2.new(0.35, 0, 0, 3)
ThT.Position = UDim2.new(0.2, 0, 0, 100)
ThT.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ThT.BorderSizePixel = 0
ThT.Parent = Ctn
R(ThT, 2)

local ThF = Instance.new("Frame")
ThF.Size = UDim2.new(0.3, 0, 1, 0)
ThF.BackgroundColor3 = T.Accent
ThF.BorderSizePixel = 0
ThF.Parent = ThT
R(ThF, 2)

local ThH = Instance.new("TextButton")
ThH.Size = UDim2.new(0, 7, 0, 7)
ThH.Position = UDim2.new(0.3, -3.5, 0.5, -3.5)
ThH.BackgroundColor3 = T.AccentLit
ThH.BorderSizePixel = 0
ThH.Text = ""
ThH.AutoButtonColor = false
ThH.Parent = ThT
R(ThH, 4)

-- Diag
local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(1, 0, 0, 1)
Sep.Position = UDim2.new(0, 0, 0, 108)
Sep.BackgroundColor3 = T.Border
Sep.BackgroundTransparency = 0.6
Sep.BorderSizePixel = 0
Sep.Parent = Ctn

local D1 = Instance.new("TextLabel")
D1.Size = UDim2.new(1, 0, 0, 12)
D1.Position = UDim2.new(0, 0, 0, 113)
D1.BackgroundTransparency = 1
D1.Text = "idle"
D1.TextColor3 = T.TextOff
D1.TextSize = 7
D1.Font = Enum.Font.GothamMedium
D1.Parent = Ctn

local D2 = Instance.new("TextLabel")
D2.Size = UDim2.new(1, 0, 0, 12)
D2.Position = UDim2.new(0, 0, 0, 127)
D2.BackgroundTransparency = 1
D2.Text = "no target"
D2.TextColor3 = T.TextOff
D2.TextSize = 7
D2.Font = Enum.Font.GothamMedium
D2.Parent = Ctn

local D3 = Instance.new("TextLabel")
D3.Size = UDim2.new(1, 0, 0, 12)
D3.Position = UDim2.new(0, 0, 0, 141)
D3.BackgroundTransparency = 1
D3.Text = "viz: off"
D3.TextColor3 = T.TextOff
D3.TextSize = 7
D3.Font = Enum.Font.GothamMedium
D3.Parent = Ctn

-- Activate
local Act = Instance.new("TextButton")
Act.Size = UDim2.new(0, 216, 0, 26)
Act.Position = UDim2.new(0.5, -108, 0.5, 125)
Act.BackgroundColor3 = T.Surface
Act.BorderSizePixel = 0
Act.Text = "ACTIVATE"
Act.TextColor3 = T.Text
Act.TextSize = 10
Act.Font = Enum.Font.GothamBold
Act.AutoButtonColor = false
Act.Parent = Container
R(Act, 7) S(Act, T.Border, 0.3) Hov(Act, T.Surface) Prs(Act)

-- ═══════════════════════════════════════════════
-- UPDATE
-- ═══════════════════════════════════════════════

local function Update()
    SpdL.Text = State.Speed
    SpdU.Text = State.Mode
    Act.Visible = State.Hotkey == nil
    
    if State.Running then
        Act.Text = "STOP"
        Act.BackgroundColor3 = T.Card
        D1.Text = "macro active"
        D1.TextColor3 = T.On
    else
        Act.Text = "ACTIVATE"
        Act.BackgroundColor3 = T.Surface
        D1.Text = "idle"
        D1.TextColor3 = T.TextOff
    end
    
    if State.AutoParry then
        ParryBtn.TextColor3 = T.On
        PD.BackgroundColor3 = T.On
        local ball = FindBall()
        if ball then
            local spd = math.floor(BSpd(ball))
            D2.Text = "locked • " .. spd .. " spd"
            D2.TextColor3 = T.On
        else
            D2.Text = "searching..."
            D2.TextColor3 = T.Warn
        end
    else
        ParryBtn.TextColor3 = T.TextOff
        PD.BackgroundColor3 = T.TextOff
        D2.Text = "no target"
        D2.TextColor3 = T.TextOff
    end
    
    D3.Text = "viz: " .. (State.VizEnabled and ("on • " .. #Viz.Parts .. " parts") or "off")
    D3.TextColor3 = State.VizEnabled and T.Viz or T.TextOff
end

task.spawn(function()
    while task.wait(0.15) do
        if State.AutoParry then Update() end
    end
end)

-- ═══════════════════════════════════════════════
-- EVENTS
-- ═══════════════════════════════════════════════

ModeBtn.MouseButton1Click:Connect(function()
    State.Mode = State.Mode == "KPS" and "CPS" or "KPS"
    ModeBtn.Text = State.Mode
    Update()
end)

BindBtn.MouseButton1Click:Connect(function()
    if not State.Hotkey then
        State.Binding = true
        BindBtn.Text = "..."
        BindBtn.TextColor3 = T.Warn
    else
        if State.Running then StopMacro() end
        State.Hotkey = nil
        State.Binding = false
        BindBtn.Text = "BIND"
        BindBtn.TextColor3 = T.Text
        Update()
    end
end)

ParryBtn.MouseButton1Click:Connect(function()
    State.AutoParry = not State.AutoParry
    if State.AutoParry then
        StartParry()
    else
        StopParry()
    end
    Update()
end)

PredBtn.MouseButton1Click:Connect(function()
    State.Predictive = not State.Predictive
    PredBtn.TextColor3 = State.Predictive and T.On or T.TextOff
end)

VizBtn.MouseButton1Click:Connect(function()
    State.VizEnabled = not State.VizEnabled
    VizBtn.TextColor3 = State.VizEnabled and T.Viz or T.TextOff
    
    if not State.VizEnabled then
        CleanupVisualizer()
    elseif State.AutoParry then
        InitVisualizer()
    end
    Update()
end)

Act.MouseButton1Click:Connect(function()
    if not State.Hotkey then
        if State.Running then StopMacro() else StartMacro() end
        Update()
    end
end)

-- Sliders
local DS, DT = false, false

SpdH.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then DS = true end
end)
SpdT.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        DS = true
        local f = math.clamp((i.Position.X - SpdT.AbsolutePosition.X) / SpdT.AbsoluteSize.X, 0, 1)
        State.Speed = math.floor(1 + f * 2499)
        SpdF.Size = UDim2.new(f, 0, 1, 0)
        SpdH.Position = UDim2.new(f, -4.5, 0.5, -4.5)
        Update()
    end
end)

ThH.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then DT = true end
end)
ThT.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        DT = true
        local f = math.clamp((i.Position.X - ThT.AbsolutePosition.X) / ThT.AbsoluteSize.X, 0, 1)
        State.Threshold = math.floor(10 + f * 60)
        ThF.Size = UDim2.new(f, 0, 1, 0)
        ThH.Position = UDim2.new(f, -3.5, 0.5, -3.5)
        ThL.Text = State.Threshold
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if DS and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local f = math.clamp((i.Position.X - SpdT.AbsolutePosition.X) / SpdT.AbsoluteSize.X, 0, 1)
        State.Speed = math.floor(1 + f * 2499)
        SpdF.Size = UDim2.new(f, 0, 1, 0)
        SpdH.Position = UDim2.new(f, -4.5, 0.5, -4.5)
        Update()
    end
    if DT and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local f = math.clamp((i.Position.X - ThT.AbsolutePosition.X) / ThT.AbsoluteSize.X, 0, 1)
        State.Threshold = math.floor(10 + f * 60)
        ThF.Size = UDim2.new(f, 0, 1, 0)
        ThH.Position = UDim2.new(f, -3.5, 0.5, -3.5)
        ThL.Text = State.Threshold
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        DS = false
        DT = false
    end
end)

UserInputService.InputBegan:Connect(function(i, gp)
    if State.Binding then
        if i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode ~= Enum.KeyCode.RightShift then
            State.Hotkey = i.KeyCode
            State.Binding = false
            BindBtn.Text = "[" .. i.KeyCode.Name .. "]"
            BindBtn.TextColor3 = T.On
            Update()
        end
        return
    end
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        State.Visible = not State.Visible
        Container.Visible = State.Visible
    end
    if State.Hotkey and i.KeyCode == State.Hotkey then
        if State.Running then StopMacro() else StartMacro() end
        Update()
    end
end)

-- Cleanup on character death
LocalPlayer.CharacterAdded:Connect(function()
    CleanupVisualizer()
    if State.AutoParry then
        task.delay(2, function()
            if State.AutoParry then StartParry() end
        end)
    end
end)

Update()
