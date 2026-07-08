--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    THYREN - BLADE BALL                         ║
    ║            Maximum Anti-Detection System v2.0                 ║
    ║                  [HORIZONTAL LAYOUT]                          ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

--------------------------------------------------------------------------------
-- SERVICES
--------------------------------------------------------------------------------
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService       = game:GetService("TweenService")
local StarterGui         = game:GetService("StarterGui")
local CoreGui            = game:GetService("CoreGui")

--------------------------------------------------------------------------------
-- PLAYER REFERENCES
--------------------------------------------------------------------------------
local LocalPlayer = Players.LocalPlayer
local PlayerName  = LocalPlayer.Name

--------------------------------------------------------------------------------
-- ENVIRONMENT DETECTION
--------------------------------------------------------------------------------
local Env = {
    Executor = "Unknown",
    IsSynapse = false,
    IsFluxus = false,
    IsKrnl = false,
    IsScriptWare = false,
    HasProtectGui = false,
    HasGetHui = false,
    HasKeypress = false,
    HasSendInput = false,
    HasMouse1Press = false,
}

if syn then
    Env.IsSynapse = true
    Env.Executor = "Synapse"
    if syn.protect_gui then Env.HasProtectGui = true end
end

if protect_gui then
    Env.HasProtectGui = true
    if not Env.IsSynapse then Env.Executor = "Script-Ware/Fluxus" end
end

if gethui then
    Env.HasGetHui = true
    if not Env.IsSynapse then Env.Executor = "Krnl/Other" end
end

if keypress and keyrelease then
    Env.HasKeypress = true
end

if sendinput then
    Env.HasSendInput = true
end

if mouse1press and mouse1release then
    Env.HasMouse1Press = true
end

if fluxus then
    Env.IsFluxus = true
    Env.Executor = "Fluxus"
end

if krnl then
    Env.IsKrnl = true
    Env.Executor = "Krnl"
end

--------------------------------------------------------------------------------
-- CLEANUP OLD INSTANCES
--------------------------------------------------------------------------------
if CoreGui:FindFirstChild("ThyrenUI") then
    CoreGui:FindFirstChild("ThyrenUI"):Destroy()
end
if LocalPlayer.PlayerGui:FindFirstChild("ThyrenUI") then
    LocalPlayer.PlayerGui:FindFirstChild("ThyrenUI"):Destroy()
end

for _, obj in pairs(workspace:GetChildren()) do
    if obj.Name:find("Thyren") then
        obj:Destroy()
    end
end

--------------------------------------------------------------------------------
-- SCREENGUI CREATION
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ThyrenUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999

local function SecureParent(gui)
    if Env.HasProtectGui and syn and syn.protect_gui then
        local ok, _ = pcall(function()
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        end)
        if ok then return true end
    end
    if Env.HasProtectGui then
        local ok, _ = pcall(function()
            protect_gui(gui)
            gui.Parent = CoreGui
        end)
        if ok then return true end
    end
    if Env.HasGetHui then
        local ok, _ = pcall(function()
            gui.Parent = gethui()
        end)
        if ok then return true end
    end
    local ok, _ = pcall(function()
        gui.Parent = CoreGui
    end)
    if ok then return true end
    local ok2, _ = pcall(function()
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
    if ok2 then return true end
    return false
end

local GuiParented = SecureParent(ScreenGui)

--------------------------------------------------------------------------------
-- HID EMULATION SYSTEM
--------------------------------------------------------------------------------
local HID = {
    Method = "VirtualInput",
    PressCount = 0,
    ReleaseCount = 0,
    LastInputTime = 0,
}

local function GetHumanDelay()
    return 0.015 + math.random() * (0.035 - 0.015)
end

local function InitializeHID()
    if Env.HasKeypress then
        HID.Method = "keypress"
        HID.Press = function(keyCode)
            local keyName = keyCode.Name
            HID.PressCount = HID.PressCount + 1
            HID.LastInputTime = os.clock()
            local ok, _ = pcall(function()
                keypress(keyName)
                task.delay(GetHumanDelay(), function()
                    keyrelease(keyName)
                    HID.ReleaseCount = HID.ReleaseCount + 1
                end)
            end)
            if not ok then
                pcall(function()
                    keypress(keyCode)
                    task.delay(GetHumanDelay(), function()
                        keyrelease(keyCode)
                        HID.ReleaseCount = HID.ReleaseCount + 1
                    end)
                end)
            end
        end
        return
    end
    if Env.HasSendInput then
        HID.Method = "sendinput"
        HID.Press = function(keyCode)
            HID.PressCount = HID.PressCount + 1
            HID.LastInputTime = os.clock()
            pcall(function()
                sendinput({Type = "KeyDown", Key = keyCode.Name})
                task.delay(GetHumanDelay(), function()
                    sendinput({Type = "KeyUp", Key = keyCode.Name})
                    HID.ReleaseCount = HID.ReleaseCount + 1
                end)
            end)
        end
        return
    end
    HID.Method = "VirtualInput"
    HID.Press = function(keyCode)
        HID.PressCount = HID.PressCount + 1
        HID.LastInputTime = os.clock()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.delay(GetHumanDelay(), function()
                VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
                HID.ReleaseCount = HID.ReleaseCount + 1
            end)
        end)
    end
end

local function MousePress()
    HID.PressCount = HID.PressCount + 1
    HID.LastInputTime = os.clock()
    if Env.HasMouse1Press then
        pcall(function()
            mouse1press()
            task.delay(GetHumanDelay(), function()
                mouse1release()
                HID.ReleaseCount = HID.ReleaseCount + 1
            end)
        end)
    else
        local m = UserInputService:GetMouseLocation()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(m.X, m.Y, 0, true, game, 0)
            task.delay(GetHumanDelay(), function()
                VirtualInputManager:SendMouseButtonEvent(m.X, m.Y, 0, false, game, 0)
                HID.ReleaseCount = HID.ReleaseCount + 1
            end)
        end)
    end
end

InitializeHID()

--------------------------------------------------------------------------------
-- ANTI-DETECTION SYSTEM
--------------------------------------------------------------------------------
local AntiDetect = {
    ParryHistory = {},
    MaxHistorySize = 30,
    LastParryTime = 0,
    BaseReactionTime = 0.045,
    ReactionVariance = 0.025,
    MinParryInterval = 0.12,
    MaxParryInterval = 0.8,
    ConsecutiveParries = 0,
    MaxConsecutive = 8,
    MissChance = 0.015,
    StreakCounter = 0,
    KeyHoldTimeMin = 0.015,
    KeyHoldTimeMax = 0.035,
    AverageInterval = 0.2,
    IntervalVariance = 0.05,
    PatternScore = 0,
}

local function GetReactionDelay()
    local base = AntiDetect.BaseReactionTime
    local variance = (math.random() * 2 - 1) * AntiDetect.ReactionVariance
    if AntiDetect.PatternScore > 50 then
        variance = variance + (math.random() * 0.03)
    end
    return math.max(0.01, base + variance)
end

local function ShouldIntentionalMiss()
    AntiDetect.ConsecutiveParries = AntiDetect.ConsecutiveParries + 1
    AntiDetect.StreakCounter = AntiDetect.StreakCounter + 1
    if AntiDetect.ConsecutiveParries >= AntiDetect.MaxConsecutive then
        AntiDetect.ConsecutiveParries = 0
        return true
    end
    local dynamicMissChance = AntiDetect.MissChance + (AntiDetect.StreakCounter * 0.002)
    dynamicMissChance = math.min(dynamicMissChance, 0.05)
    if math.random() < dynamicMissChance then
        AntiDetect.ConsecutiveParries = 0
        return true
    end
    return false
end

local function AnalyzePatterns()
    local history = AntiDetect.ParryHistory
    if #history < 5 then return end
    local sum = 0
    for _, v in ipairs(history) do
        sum = sum + v
    end
    AntiDetect.AverageInterval = sum / #history
    local variance = 0
    for _, v in ipairs(history) do
        local diff = v - AntiDetect.AverageInterval
        variance = variance + (diff * diff)
    end
    AntiDetect.IntervalVariance = (variance / #history) ^ 0.5
    local cv = AntiDetect.IntervalVariance / AntiDetect.AverageInterval
    AntiDetect.PatternScore = math.clamp((1 - cv) * 100, 0, 100)
end

local function RecordParryTiming()
    local now = os.clock()
    local interval = now - AntiDetect.LastParryTime
    if interval > 0.05 and interval < 5 then
        table.insert(AntiDetect.ParryHistory, interval)
        if #AntiDetect.ParryHistory > AntiDetect.MaxHistorySize then
            table.remove(AntiDetect.ParryHistory, 1)
        end
    end
    AntiDetect.LastParryTime = now
    AnalyzePatterns()
end

local function GetAdaptiveDelay()
    local baseDelay = GetReactionDelay()
    if AntiDetect.PatternScore > 60 then
        baseDelay = baseDelay + (math.random() * 0.04)
    elseif AntiDetect.PatternScore > 40 then
        baseDelay = baseDelay + (math.random() * 0.02)
    end
    local timeSinceLast = os.clock() - AntiDetect.LastParryTime
    if timeSinceLast < AntiDetect.MinParryInterval then
        baseDelay = baseDelay + (AntiDetect.MinParryInterval - timeSinceLast)
    end
    return math.max(0, baseDelay)
end

local function HumanParry()
    if ShouldIntentionalMiss() then
        return
    end
    local delay = GetAdaptiveDelay()
    task.delay(delay, function()
        if not State.AutoParry then return end
        HID.Press(Enum.KeyCode.Space)
        RecordParryTiming()
    end)
end

local function ResetStreak()
    AntiDetect.StreakCounter = 0
end

--------------------------------------------------------------------------------
-- APPLICATION STATE
--------------------------------------------------------------------------------
local State = {
    Running = false,
    Speed = 10,
    Mode = "KPS",
    Hotkey = nil,
    Binding = false,
    Activation = "Manual",
    AutoParry = false,
    Threshold = 28,
    Predictive = true,
    VizEnabled = true,
    VizActive = false,
    Visible = true,
    Tab = "Main",
}

local Connections = {}
local LastFireTime = 0
local CachedBall = nil
local LastBallCheckTime = 0

--------------------------------------------------------------------------------
-- INVISIBLE VISUALIZER SYSTEM
--------------------------------------------------------------------------------
local Viz = {
    Parts = {},
    UpdateCounter = 0,
}

local function CreateInvisiblePart(config)
    local part = Instance.new("Part")
    part.Name = config.Name or "ThyrenViz"
    part.Anchored = true
    part.CanCollide = false
    part.Massless = true
    part.Size = config.Size or Vector3.new(1, 1, 1)
    part.Position = config.Position or Vector3.new(0, -5000, 0)
    part.Shape = config.Shape or Enum.PartType.Ball
    part.Material = Enum.Material.ForceField
    part.Color = config.Color or Color3.new(1, 1, 1)
    part.Transparency = 1
    part.CastShadow = false
    part.ReceiveShadow = false
    part.Parent = workspace
    table.insert(Viz.Parts, part)
    return part
end

local function InitializeVisualizer()
    if State.VizActive then return end
    State.VizActive = true
    Viz.RangeRing = CreateInvisiblePart({
        Name = "Thyren_Range",
        Size = Vector3.new(0.2, 1, 1),
        Shape = Enum.PartType.Cylinder,
    })
    Viz.BallTracker = CreateInvisiblePart({
        Name = "Thyren_BallTracker",
        Size = Vector3.new(0.1, 0.1, 0.1),
        Shape = Enum.PartType.Ball,
    })
    Viz.Trajectory = CreateInvisiblePart({
        Name = "Thyren_Trajectory",
        Size = Vector3.new(0.05, 0.05, 1),
        Shape = Enum.PartType.Block,
    })
    Viz.Prediction = CreateInvisiblePart({
        Name = "Thyren_Prediction",
        Size = Vector3.new(0.3, 0.3, 0.3),
        Shape = Enum.PartType.Ball,
    })
    Viz.TriggerZone = CreateInvisiblePart({
        Name = "Thyren_TriggerZone",
        Size = Vector3.new(0.5, 0.5, 0.5),
        Shape = Enum.PartType.Ball,
    })
end

local function UpdateVisualizer(ball, root, distance, timeToImpact)
    if not State.VizActive or not root then return end
    Viz.UpdateCounter = Viz.UpdateCounter + 1
    if Viz.UpdateCounter % 3 ~= 0 then return end
    local thresh = State.Threshold
    if ball then
        local spd = BallSpeed(ball)
        if spd > 40 then thresh = thresh + (spd * 0.18) end
        thresh = math.clamp(thresh, 15, 70)
    end
    local ringDiameter = thresh * 2
    Viz.RangeRing.Size = Vector3.new(0.2, ringDiameter, ringDiameter)
    Viz.RangeRing.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
    if ball then
        Viz.BallTracker.Position = ball.Position
        local direction = root.Position - ball.Position
        local dist = direction.Magnitude
        if dist > 0.1 then
            local midPoint = ball.Position + direction * 0.5
            Viz.Trajectory.Size = Vector3.new(0.05, 0.05, dist)
            Viz.Trajectory.CFrame = CFrame.lookAt(midPoint, root.Position)
        end
        local vel = ball.AssemblyLinearVelocity
        if vel then
            local predictTime = math.min(timeToImpact, 0.5)
            local futurePos = ball.Position + vel * predictTime
            Viz.Prediction.Position = futurePos
        end
        if dist > 0.1 then
            local triggerPos = ball.Position + direction.Unit * thresh
            Viz.TriggerZone.Position = triggerPos
        end
    else
        local hidePos = Vector3.new(0, -5000, 0)
        Viz.BallTracker.Position = hidePos
        Viz.Trajectory.Position = hidePos
        Viz.Prediction.Position = hidePos
        Viz.TriggerZone.Position = hidePos
    end
end

local function CleanupVisualizer()
    for _, part in ipairs(Viz.Parts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    Viz.Parts = {}
    State.VizActive = false
end

--------------------------------------------------------------------------------
-- BALL DETECTION ENGINE
--------------------------------------------------------------------------------
local function FindBall()
    local now = os.clock()
    if CachedBall and CachedBall.Parent and (now - LastBallCheckTime) < 0.04 then
        return CachedBall
    end
    LastBallCheckTime = now
    CachedBall = nil
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("BasePart") then
            local nameLower = obj.Name:lower()
            if nameLower == "ball" or nameLower == "sphereball" or nameLower == "projectile" then
                local target = obj:GetAttribute("target")
                    or obj:GetAttribute("Target")
                    or obj:GetAttribute("TargetPlayer")
                if not target then
                    local targetObj = obj:FindFirstChild("target")
                        or obj:FindFirstChild("Target")
                        or obj:FindFirstChild("TargetPlayer")
                    if targetObj then
                        if targetObj:IsA("StringValue") then
                            target = targetObj.Value
                        elseif targetObj:IsA("ObjectValue") and targetObj.Value then
                            target = targetObj.Value.Name
                        end
                    end
                end
                if target == nil or target == PlayerName then
                    CachedBall = obj
                    return obj
                end
            end
        end
    end
    local folderNames = {"Balls", "Projectiles", "ball", "ProjectilesFolder", "Entities"}
    for _, folderName in ipairs(folderNames) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, obj in pairs(folder:GetChildren()) do
                if obj:IsA("BasePart") then
                    local target = obj:GetAttribute("target") or obj:GetAttribute("Target")
                    if not target then
                        local tv = obj:FindFirstChild("target") or obj:FindFirstChild("Target")
                        if tv and tv.Value then
                            target = typeof(tv.Value) == "string" and tv.Value or tv.Value.Name
                        end
                    end
                    if target == nil or target == PlayerName then
                        CachedBall = obj
                        return obj
                    end
                end
            end
        end
    end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nameLower = obj.Name:lower()
            if nameLower:find("ball") or nameLower:find("projectile") then
                local target = obj:GetAttribute("target") or obj:GetAttribute("Target")
                if target == nil or target == PlayerName then
                    CachedBall = obj
                    return obj
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
    local ballPos = ball.Position
    local rootPos = rootPart.Position
    local velocity = ball.AssemblyLinearVelocity
    local predictionTime = 0.08
    local futureBallPos = ballPos + velocity * predictionTime
    local direction = rootPos - futureBallPos
    local distance = direction.Magnitude
    local dotProduct = velocity.X * direction.X
                    + velocity.Y * direction.Y
                    + velocity.Z * direction.Z
    if dotProduct <= 0 then return 999 end
    return distance / (dotProduct / direction.Magnitude)
end

--------------------------------------------------------------------------------
-- MACRO SYSTEM
--------------------------------------------------------------------------------
local function ExecuteMacroInput()
    if State.Mode == "KPS" then
        HID.Press(Enum.KeyCode.Space)
    else
        MousePress()
    end
end

local function MacroTick()
    if not State.Running then return end
    local currentTime = os.clock()
    local targetInterval = 1 / State.Speed
    if State.Speed >= 60 then
        ExecuteMacroInput()
        ExecuteMacroInput()
    elseif (currentTime - LastFireTime) >= targetInterval then
        LastFireTime = currentTime
        ExecuteMacroInput()
    end
end

local function StartMacro()
    State.Running = true
    LastFireTime = os.clock()
    ResetStreak()
    if Connections.Macro then Connections.Macro:Disconnect() end
    Connections.Macro = RunService.PreRender:Connect(MacroTick)
end

local function StopMacro()
    State.Running = false
    ResetStreak()
    if Connections.Macro then
        Connections.Macro:Disconnect()
        Connections.Macro = nil
    end
end

local function ToggleMacro()
    if State.Running then
        StopMacro()
    else
        StartMacro()
    end
end

--------------------------------------------------------------------------------
-- AUTO PARRY SYSTEM
--------------------------------------------------------------------------------
local function StartAutoParry()
    if State.VizEnabled then
        InitializeVisualizer()
    end
    if Connections.Parry then Connections.Parry:Disconnect() end
    Connections.Parry = RunService.Heartbeat:Connect(function(deltaTime)
        if not State.AutoParry then return end
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not rootPart or not humanoid or humanoid.Health <= 0 then
            if State.VizActive then
                local hidePos = Vector3.new(0, -5000, 0)
                for _, part in ipairs(Viz.Parts) do
                    if part.Parent then part.Position = hidePos end
                end
            end
            return
        end
        local ball = FindBall()
        if not ball then
            if State.VizEnabled and State.VizActive then
                UpdateVisualizer(nil, rootPart, 999, 999)
            end
            return
        end
        local distance = (ball.Position - rootPart.Position).Magnitude
        local speed = BallSpeed(ball)
        local timeToImpact = CalculateTimeToImpact(ball, rootPart)
        local shouldParry = false
        if State.Predictive then
            local reactionWindow = 0.06 + (0.03 / (speed * 0.015 + 1))
            shouldParry = timeToImpact <= reactionWindow
        else
            local dynamicThreshold = State.Threshold
            if speed > 40 then
                dynamicThreshold = dynamicThreshold + (speed * 0.18)
            end
            dynamicThreshold = math.clamp(dynamicThreshold, 15, 70)
            shouldParry = distance <= dynamicThreshold
        end
        if State.VizEnabled and State.VizActive then
            UpdateVisualizer(ball, rootPart, distance, timeToImpact)
        end
        if shouldParry then
            HumanParry()
        end
    end)
end

local function StopAutoParry()
    if Connections.Parry then
        Connections.Parry:Disconnect()
        Connections.Parry = nil
    end
    CleanupVisualizer()
end

--------------------------------------------------------------------------------
-- THEME & COLORS
--------------------------------------------------------------------------------
local Theme = {
    Background = Color3.fromRGB(10, 10, 14),
    Surface = Color3.fromRGB(18, 18, 24),
    Card = Color3.fromRGB(26, 26, 34),
    CardRaised = Color3.fromRGB(32, 32, 42),
    Hover = Color3.fromRGB(40, 40, 52),
    Pressed = Color3.fromRGB(22, 22, 28),
    Accent = Color3.fromRGB(90, 90, 110),
    AccentLight = Color3.fromRGB(130, 130, 155),
    AccentBright = Color3.fromRGB(160, 160, 185),
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
    BorderLight = Color3.fromRGB(45, 45, 60),
    BorderHighlight = Color3.fromRGB(60, 60, 78),
}

--------------------------------------------------------------------------------
-- UI UTILITY FUNCTIONS
--------------------------------------------------------------------------------
local function ApplyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

local function ApplyStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.4
    stroke.Parent = instance
    return stroke
end

local function ApplyHoverEffect(button, baseColor)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Theme.Hover
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = baseColor
        }):Play()
    end)
end

local function ApplyPressEffect(button)
    local isPressed = false
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isPressed = true
            TweenService:Create(button, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Theme.Pressed
            }):Play()
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isPressed then
            isPressed = false
            TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Theme.Hover
            }):Play()
        end
    end)
end

local function CreateLabel(config)
    local label = Instance.new("TextLabel")
    label.Name = config.Name or "Label"
    label.Size = config.Size or UDim2.new(1, 0, 0, 20)
    label.Position = config.Position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = config.Text or ""
    label.TextColor3 = config.Color or Theme.TextSecondary
    label.TextSize = config.Size2 or 11
    label.Font = config.Font or Enum.Font.GothamMedium
    label.TextXAlignment = config.XAlign or Enum.TextXAlignment.Left
    label.TextYAlignment = config.YAlign or Enum.TextYAlignment.Center
    label.Parent = config.Parent
    return label
end

local function CreateButton(config)
    local button = Instance.new("TextButton")
    button.Name = config.Name or "Button"
    button.Size = config.Size or UDim2.new(0, 100, 0, 30)
    button.Position = config.Position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = config.Color or Theme.Card
    button.BorderSizePixel = 0
    button.Text = config.Text or ""
    button.TextColor3 = config.TextColor or Theme.TextPrimary
    button.TextSize = config.TextSize or 11
    button.Font = config.Font or Enum.Font.GothamBold
    button.AutoButtonColor = false
    button.Parent = config.Parent
    if config.Corner then ApplyCorner(button, config.Corner) end
    if config.Stroke then ApplyStroke(button, config.StrokeColor, config.StrokeThickness) end
    if config.Hover ~= false then ApplyHoverEffect(button, config.Color or Theme.Card) end
    if config.Press ~= false then ApplyPressEffect(button) end
    return button
end

local function CreateFrame(config)
    local frame = Instance.new("Frame")
    frame.Name = config.Name or "Frame"
    frame.Size = config.Size or UDim2.new(1, 0, 1, 0)
    frame.Position = config.Position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = config.Color or Theme.Surface
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = config.Transparency or 0
    frame.Parent = config.Parent
    if config.Corner then ApplyCorner(frame, config.Corner) end
    if config.Stroke then ApplyStroke(frame, config.StrokeColor, config.StrokeThickness, config.StrokeTransparency) end
    return frame
end

local function CreateSlider(config)
    local track = CreateFrame({
        Name = config.Name or "Slider",
        Size = config.Size or UDim2.new(1, 0, 0, 4),
        Position = config.Position,
        Color = Color3.fromRGB(28, 28, 38),
        Parent = config.Parent,
        Corner = 2,
    })
    local fill = CreateFrame({
        Name = "Fill",
        Size = UDim2.new(config.FillFraction or 0.004, 0, 1, 0),
        Color = Theme.Accent,
        Parent = track,
        Corner = 2,
    })
    local handle = Instance.new("TextButton")
    handle.Name = "Handle"
    handle.Size = UDim2.new(0, config.HandleSize or 10, 0, config.HandleSize or 10)
    handle.Position = UDim2.new(config.FillFraction or 0.004, -(config.HandleSize or 10) / 2, 0.5, -(config.HandleSize or 10) / 2)
    handle.BackgroundColor3 = Theme.AccentLight
    handle.BorderSizePixel = 0
    handle.Text = ""
    handle.AutoButtonColor = false
    handle.Parent = track
    ApplyCorner(handle, (config.HandleSize or 10) / 2)
    return track, fill, handle
end

local function CreateStatusDot(config)
    local dot = Instance.new("Frame")
    dot.Name = config.Name or "Dot"
    dot.Size = UDim2.new(0, config.Size or 6, 0, config.Size or 6)
    dot.Position = config.Position or UDim2.new(0, 0, 0, 0)
    dot.BackgroundColor3 = config.Color or Theme.TextDisabled
    dot.BorderSizePixel = 0
    dot.Parent = config.Parent
    ApplyCorner(dot, (config.Size or 6) / 2)
    return dot
end

local function CreateSeparator(config)
    local sep = Instance.new("Frame")
    sep.Name = config.Name or "Separator"
    if config.Horizontal then
        -- Vertical separator for horizontal layout
        sep.Size = config.Size or UDim2.new(0, 1, 1, 0)
    else
        sep.Size = config.Size or UDim2.new(1, 0, 0, 1)
    end
    sep.Position = config.Position or UDim2.new(0, 0, 0, 0)
    sep.BackgroundColor3 = Theme.Border
    sep.BackgroundTransparency = config.Transparency or 0.6
    sep.BorderSizePixel = 0
    sep.Parent = config.Parent
    return sep
end

--------------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- BUILD HORIZONTAL GUI
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(1, 0, 1, 0)
Container.BackgroundTransparency = 1
Container.Parent = ScreenGui

-- ═══════════════════════════════════════════════════════════════════════════
-- MAIN PANEL — WIDE HORIZONTAL RECTANGLE
-- ═══════════════════════════════════════════════════════════════════════════

local PANEL_W = 680
local PANEL_H = 195

local MainPanel = CreateFrame({
    Name = "MainPanel",
    Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
    Position = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2),
    Color = Theme.Background,
    Corner = 12,
    Stroke = true,
    StrokeColor = Theme.Border,
    Parent = Container,
})
MainPanel.Active = true
MainPanel.Draggable = true

-- ═══════════════════════════════════════════════════════════════════════════
-- HEADER BAR (horizontal strip at top)
-- ═══════════════════════════════════════════════════════════════════════════

local HeaderBar = CreateFrame({
    Name = "HeaderBar",
    Size = UDim2.new(1, 0, 0, 34),
    Color = Theme.Surface,
    Corner = 12,
    Parent = MainPanel,
})

-- Fix bottom corners of header
local HeaderFix = CreateFrame({
    Size = UDim2.new(1, 0, 0, 8),
    Position = UDim2.new(0, 0, 1, -8),
    Color = Theme.Surface,
    Parent = HeaderBar,
})

local TitleText = CreateLabel({
    Name = "TitleText",
    Size = UDim2.new(0, 70, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    Text = "THYREN",
    Color = Theme.TextPrimary,
    Size2 = 13,
    Font = Enum.Font.GothamBlack,
    Parent = HeaderBar,
})

local VersionDot = CreateStatusDot({
    Name = "VersionDot",
    Size = 4,
    Position = UDim2.new(0, 86, 0.5, -2),
    Color = Theme.Success,
    Parent = HeaderBar,
})

local VersionText = CreateLabel({
    Name = "VersionText",
    Size = UDim2.new(0, 25, 1, 0),
    Position = UDim2.new(0, 93, 0, 0),
    Text = "v2.0",
    Color = Theme.TextDisabled,
    Size2 = 8,
    Font = Enum.Font.GothamMedium,
    Parent = HeaderBar,
})

local HIDDot = CreateStatusDot({
    Name = "HIDDot",
    Size = 4,
    Position = UDim2.new(0, 124, 0.5, -2),
    Color = Theme.Info,
    Parent = HeaderBar,
})

local HIDText = CreateLabel({
    Name = "HIDText",
    Size = UDim2.new(0, 55, 1, 0),
    Position = UDim2.new(0, 131, 0, 0),
    Text = HID.Method,
    Color = Theme.TextDisabled,
    Size2 = 8,
    Font = Enum.Font.GothamMedium,
    Parent = HeaderBar,
})

local ToggleHint = CreateLabel({
    Name = "ToggleHint",
    Size = UDim2.new(0, 55, 1, 0),
    Position = UDim2.new(1, -62, 0, 0),
    Text = "RShift ▾",
    Color = Theme.TextDisabled,
    Size2 = 8,
    Font = Enum.Font.GothamMedium,
    XAlign = Enum.TextXAlignment.Right,
    Parent = HeaderBar,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- CONTENT AREA (below header, full width)
-- ═══════════════════════════════════════════════════════════════════════════

local ContentArea = CreateFrame({
    Name = "ContentArea",
    Size = UDim2.new(1, -20, 1, -42),
    Position = UDim2.new(0, 10, 0, 36),
    Transparency = 1,
    Parent = MainPanel,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- COLUMN 1: MACRO CONTROLS (leftmost)
-- ═══════════════════════════════════════════════════════════════════════════

local COL1_W = 165

local MacroCol = CreateFrame({
    Name = "MacroCol",
    Size = UDim2.new(0, COL1_W, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    Transparency = 1,
    Parent = ContentArea,
})

local MacroSectionLabel = CreateLabel({
    Name = "MacroSectionLabel",
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 0, 2),
    Text = "MACRO",
    Color = Theme.TextDisabled,
    Size2 = 8,
    Font = Enum.Font.GothamBold,
    Parent = MacroCol,
})

-- Mode button
local ModeButton = CreateButton({
    Name = "ModeButton",
    Size = UDim2.new(0.48, 0, 0, 28),
    Position = UDim2.new(0, 0, 0, 18),
    Text = "KPS",
    TextColor = Theme.TextPrimary,
    TextSize = 10,
    Corner = 6,
    Parent = MacroCol,
})

-- Bind button
local BindButton = CreateButton({
    Name = "BindButton",
    Size = UDim2.new(0.48, 0, 0, 28),
    Position = UDim2.new(0.52, 0, 0, 18),
    Text = "KEYBIND",
    TextColor = Theme.TextSecondary,
    TextSize = 10,
    Corner = 6,
    Parent = MacroCol,
})

-- Speed value display
local SpeedValueLabel = CreateLabel({
    Name = "SpeedValue",
    Size = UDim2.new(0, 30, 0, 18),
    Position = UDim2.new(0, 0, 0, 52),
    Text = "10",
    Color = Theme.TextPrimary,
    Size2 = 16,
    Font = Enum.Font.GothamBold,
    Parent = MacroCol,
})

local SpeedUnitLabel = CreateLabel({
    Name = "SpeedUnit",
    Size = UDim2.new(0, 25, 0, 18),
    Position = UDim2.new(0, 30, 0, 52),
    Text = "KPS",
    Color = Theme.TextMuted,
    Size2 = 9,
    Font = Enum.Font.GothamMedium,
    Parent = MacroCol,
})

local SpeedLabel = CreateLabel({
    Name = "SpeedLabel",
    Size = UDim2.new(0, 40, 0, 12),
    Position = UDim2.new(0, 0, 0, 70),
    Text = "SPEED",
    Color = Theme.TextDisabled,
    Size2 = 7,
    Font = Enum.Font.GothamBold,
    Parent = MacroCol,
})

-- Speed slider (vertical-feel but still horizontal track, shorter width)
local SpeedTrack, SpeedFill, SpeedHandle = CreateSlider({
    Name = "SpeedSlider",
    Size = UDim2.new(1, 0, 0, 5),
    Position = UDim2.new(0, 0, 0, 84),
    HandleSize = 11,
    Parent = MacroCol,
})

-- Activate / Stop macro button
local ActivateButton = CreateButton({
    Name = "ActivateButton",
    Size = UDim2.new(1, 0, 0, 32),
    Position = UDim2.new(0, 0, 0, 100),
    Color = Theme.Surface,
    Text = "ACTIVATE",
    TextColor = Theme.TextPrimary,
    TextSize = 11,
    Corner = 8,
    Stroke = true,
    StrokeColor = Theme.Border,
    Parent = MacroCol,
})

-- Macro status dot on the activate button
local MacroStatusDot = CreateStatusDot({
    Name = "MacroStatusDot",
    Size = 5,
    Position = UDim2.new(1, -16, 0.5, -2.5),
    Color = Theme.TextDisabled,
    Parent = ActivateButton,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- VERTICAL SEPARATOR 1
-- ═══════════════════════════════════════════════════════════════════════════

CreateSeparator({
    Name = "Sep1",
    Size = UDim2.new(0, 1, 1, -10),
    Position = UDim2.new(0, COL1_W + 4, 0, 5),
    Transparency = 0.5,
    Parent = ContentArea,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- COLUMN 2: AUTO PARRY (center)
-- ═══════════════════════════════════════════════════════════════════════════

local COL2_X = COL1_W + 12
local COL2_W = 175

local ParryCol = CreateFrame({
    Name = "ParryCol",
    Size = UDim2.new(0, COL2_W, 1, 0),
    Position = UDim2.new(0, COL2_X, 0, 0),
    Transparency = 1,
    Parent = ContentArea,
})

local ParrySectionLabel = CreateLabel({
    Name = "ParrySectionLabel",
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 0, 2),
    Text = "AUTO PARRY",
    Color = Theme.TextDisabled,
    Size2 = 8,
    Font = Enum.Font.GothamBold,
    Parent = ParryCol,
})

-- Parry toggle (big button)
local ParryButton = CreateButton({
    Name = "ParryButton",
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 18),
    Text = "AUTO PARRY",
    TextColor = Theme.TextMuted,
    TextSize = 11,
    Corner = 8,
    Parent = ParryCol,
})

local ParryStatusDot = CreateStatusDot({
    Name = "ParryStatusDot",
    Size = 5,
    Position = UDim2.new(1, -15, 0.5, -2.5),
    Color = Theme.TextDisabled,
    Parent = ParryButton,
})

-- Row: Predictive + Visualizer
local PredictButton = CreateButton({
    Name = "PredictButton",
    Size = UDim2.new(0.48, 0, 0, 24),
    Position = UDim2.new(0, 0, 0, 54),
    Text = "PREDICT",
    TextColor = Theme.Success,
    TextSize = 8,
    Corner = 5,
    Parent = ParryCol,
})

local VizButton = CreateButton({
    Name = "VizButton",
    Size = UDim2.new(0.48, 0, 0, 24),
    Position = UDim2.new(0.52, 0, 0, 54),
    Text = "VISUAL",
    TextColor = Theme.Purple,
    TextSize = 8,
    Corner = 5,
    Parent = ParryCol,
})

-- Threshold controls
local ThresholdValueLabel = CreateLabel({
    Name = "ThresholdValue",
    Size = UDim2.new(0, 20, 0, 16),
    Position = UDim2.new(0, 0, 0, 84),
    Text = "28",
    Color = Theme.TextSecondary,
    Size2 = 13,
    Font = Enum.Font.GothamBold,
    Parent = ParryCol,
})

local ThresholdLabel = CreateLabel({
    Name = "ThresholdLabel",
    Size = UDim2.new(0, 55, 0, 12),
    Position = UDim2.new(0, 0, 0, 100),
    Text = "THRESHOLD",
    Color = Theme.TextDisabled,
    Size2 = 7,
    Font = Enum.Font.GothamBold,
    Parent = ParryCol,
})

local ThresholdTrack, ThresholdFill, ThresholdHandle = CreateSlider({
    Name = "ThresholdSlider",
    Size = UDim2.new(1, 0, 0, 4),
    Position = UDim2.new(0, 0, 0, 114),
    HandleSize = 8,
    Parent = ParryCol,
})

-- Streak info
local StreakLabel = CreateLabel({
    Name = "StreakLabel",
    Size = UDim2.new(0, 80, 0, 14),
    Position = UDim2.new(0, 0, 0, 126),
    Text = "STREAK: 0",
    Color = Theme.TextMuted,
    Size2 = 8,
    Font = Enum.Font.GothamMedium,
    Parent = ParryCol,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- VERTICAL SEPARATOR 2
-- ═══════════════════════════════════════════════════════════════════════════

CreateSeparator({
    Name = "Sep2",
    Size = UDim2.new(0, 1, 1, -10),
    Position = UDim2.new(0, COL2_X + COL2_W + 4, 0, 5),
    Transparency = 0.5,
    Parent = ContentArea,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- COLUMN 3: DIAGNOSTICS (rightmost)
-- ═══════════════════════════════════════════════════════════════════════════

local COL3_X = COL2_X + COL2_W + 12

local DiagCol = CreateFrame({
    Name = "DiagCol",
    Size = UDim2.new(1, -COL3_X, 1, 0),
    Position = UDim2.new(0, COL3_X, 0, 0),
    Transparency = 1,
    Parent = ContentArea,
})

local DiagSectionLabel = CreateLabel({
    Name = "DiagSectionLabel",
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 0, 2),
    Text = "DIAGNOSTICS",
    Color = Theme.TextDisabled,
    Size2 = 8,
    Font = Enum.Font.GothamBold,
    Parent = DiagCol,
})

-- Diagnostics grid — 2 columns of dot+text pairs
local diagEntries = {
    {name = "Macro",    dotY = 20,  text = "MACRO: IDLE",     id = "Macro"},
    {name = "Parry",    dotY = 40,  text = "PARRY: OFF",      id = "Parry"},
    {name = "Target",   dotY = 60,  text = "TARGET: NONE",    id = "Ball"},
    {name = "Visual",   dotY = 80,  text = "VIZ: OFF",        id = "Viz"},
    {name = "Input",    dotY = 100, text = "HID: " .. HID.Method, id = "HID"},
    {name = "Pattern",  dotY = 120, text = "BOT: 0%",         id = "Pattern"},
}

local DiagDots = {}
local DiagTexts = {}

for i, entry in ipairs(diagEntries) do
    local colOffset = 0
    local rowOffset = entry.dotY

    -- Split into 2 columns: first 3 left, last 3 right
    if i > 3 then
        colOffset = 0.5
        rowOffset = entry.dotY - 60
    end

    DiagDots[entry.id] = CreateStatusDot({
        Name = "DiagDot_" .. entry.id,
        Size = 4,
        Position = UDim2.new(colOffset, 8, 0, rowOffset),
        Color = Theme.TextDisabled,
        Parent = DiagCol,
    })

    DiagTexts[entry.id] = CreateLabel({
        Name = "DiagText_" .. entry.id,
        Size = UDim2.new(0.45, -22, 0, 16),
        Position = UDim2.new(colOffset, 18, 0, rowOffset - 2),
        Text = entry.text,
        Color = Theme.TextMuted,
        Size2 = 8,
        Font = Enum.Font.GothamMedium,
        Parent = DiagCol,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════
-- UI UPDATE FUNCTION
-- ═══════════════════════════════════════════════════════════════════════════

local function UpdateUI()
    -- Speed value
    SpeedValueLabel.Text = tostring(State.Speed)
    SpeedUnitLabel.Text = State.Mode

    -- Speed slider fill
    local speedFrac = math.clamp((State.Speed - 1) / 99, 0.004, 1)
    SpeedFill.Size = UDim2.new(speedFrac, 0, 1, 0)
    SpeedHandle.Position = UDim2.new(speedFrac, -5.5, 0.5, -5.5)

    -- Mode button
    ModeButton.Text = State.Mode

    -- Bind button text
    if State.Binding then
        BindButton.Text = "..."
    elseif State.Hotkey then
        BindButton.Text = State.Hotkey.Name
    else
        BindButton.Text = "KEYBIND"
    end

    -- Activate button
    if State.Running then
        ActivateButton.Text = "STOP"
        TweenService:Create(ActivateButton, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(30, 18, 18)
        }):Play()
        TweenService:Create(MacroStatusDot, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.Success
        }):Play()
    else
        ActivateButton.Text = "ACTIVATE"
        TweenService:Create(ActivateButton, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.Surface
        }):Play()
        TweenService:Create(MacroStatusDot, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.TextDisabled
        }):Play()
    end

    -- Parry button
    if State.AutoParry then
        ParryButton.Text = "AUTO PARRY"
        TweenService:Create(ParryButton, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(18, 30, 22)
        }):Play()
        TweenService:Create(ParryStatusDot, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.Success
        }):Play()
    else
        ParryButton.Text = "AUTO PARRY"
        TweenService:Create(ParryButton, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.Card
        }):Play()
        TweenService:Create(ParryStatusDot, TweenInfo.new(0.15), {
            BackgroundColor3 = Theme.TextDisabled
        }):Play()
    end

    -- Predictive button color
    if State.Predictive then
        PredictButton.TextColor3 = Theme.Success
    else
        PredictButton.TextColor3 = Theme.TextMuted
    end

    -- Visualizer button color
    if State.VizEnabled then
        VizButton.TextColor3 = Theme.Purple
    else
        VizButton.TextColor3 = Theme.TextMuted
    end

    -- Threshold
    ThresholdValueLabel.Text = tostring(State.Threshold)
    local threshFrac = math.clamp((State.Threshold - 5) / 65, 0.004, 1)
    ThresholdFill.Size = UDim2.new(threshFrac, 0, 1, 0)
    ThresholdHandle.Position = UDim2.new(threshFrac, -4, 0.5, -4)

    -- Streak
    StreakLabel.Text = "STREAK: " .. tostring(AntiDetect.StreakCounter)

    -- ── Diagnostics ──
    -- Macro
    if State.Running then
        DiagDots["Macro"].BackgroundColor3 = Theme.Success
        DiagTexts["Macro"].Text = "MACRO: " .. State.Mode .. " @" .. State.Speed
        DiagTexts["Macro"].TextColor3 = Theme.TextSecondary
    else
        DiagDots["Macro"].BackgroundColor3 = Theme.TextDisabled
        DiagTexts["Macro"].Text = "MACRO: IDLE"
        DiagTexts["Macro"].TextColor3 = Theme.TextMuted
    end

    -- Parry
    if State.AutoParry then
        DiagDots["Parry"].BackgroundColor3 = Theme.Success
        DiagTexts["Parry"].Text = "PARRY: ON"
        DiagTexts["Parry"].TextColor3 = Theme.TextSecondary
    else
        DiagDots["Parry"].BackgroundColor3 = Theme.TextDisabled
        DiagTexts["Parry"].Text = "PARRY: OFF"
        DiagTexts["Parry"].TextColor3 = Theme.TextMuted
    end

    -- Ball target
    local ball = FindBall()
    if ball then
        local dist = 999
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                dist = (ball.Position - root.Position).Magnitude
            end
        end
        DiagDots["Ball"].BackgroundColor3 = Theme.Warning
        DiagTexts["Ball"].Text = "TARGET: " .. math.floor(dist) .. "s"
        DiagTexts["Ball"].TextColor3 = Theme.TextSecondary
    else
        DiagDots["Ball"].BackgroundColor3 = Theme.TextDisabled
        DiagTexts["Ball"].Text = "TARGET: NONE"
        DiagTexts["Ball"].TextColor3 = Theme.TextMuted
    end

    -- Visualizer
    if State.VizActive then
        DiagDots["Viz"].BackgroundColor3 = Theme.Purple
        DiagTexts["Viz"].Text = "VIZ: ACTIVE"
        DiagTexts["Viz"].TextColor3 = Theme.TextSecondary
    else
        DiagDots["Viz"].BackgroundColor3 = Theme.TextDisabled
        DiagTexts["Viz"].Text = "VIZ: OFF"
        DiagTexts["Viz"].TextColor3 = Theme.TextMuted
    end

    -- HID
    DiagDots["HID"].BackgroundColor3 = Theme.Info
    DiagTexts["HID"].Text = "HID: " .. HID.Method
    DiagTexts["HID"].TextColor3 = Theme.TextSecondary

    -- Pattern / bot score
    local ps = math.floor(AntiDetect.PatternScore)
    if ps > 60 then
        DiagDots["Pattern"].BackgroundColor3 = Theme.Error
    elseif ps > 30 then
        DiagDots["Pattern"].BackgroundColor3 = Theme.Warning
    else
        DiagDots["Pattern"].BackgroundColor3 = Theme.Success
    end
    DiagTexts["Pattern"].Text = "BOT: " .. ps .. "%"
    DiagTexts["Pattern"].TextColor3 = Theme.TextSecondary
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SLIDER INTERACTIVITY
-- ═══════════════════════════════════════════════════════════════════════════

local function MakeSliderWork(track, fill, handle, minVal, maxVal, callback)
    local dragging = false

    local function update(input)
        local relX = input.Position.X - track.AbsolutePosition.X
        local frac = math.clamp(relX / track.AbsoluteSize.X, 0, 1)
        local value = math.floor(minVal + frac * (maxVal - minVal))
        value = math.clamp(value, minVal, maxVal)
        callback(value)
        UpdateUI()
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
end

MakeSliderWork(SpeedTrack, SpeedFill, SpeedHandle, 1, 100, function(val)
    State.Speed = val
end)

MakeSliderWork(ThresholdTrack, ThresholdFill, ThresholdHandle, 5, 70, function(val)
    State.Threshold = val
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- BUTTON EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

-- Mode toggle
ModeButton.MouseButton1Click:Connect(function()
    if State.Mode == "KPS" then
        State.Mode = "CPS"
    else
        State.Mode = "KPS"
    end
    UpdateUI()
end)

-- Keybind
BindButton.MouseButton1Click:Connect(function()
    State.Binding = true
    BindButton.Text = "..."
    UpdateUI()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Binding mode
    if State.Binding then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            State.Hotkey = input.KeyCode
            State.Binding = false
            State.Activation = "Hotkey"
            UpdateUI()
        end
        return
    end

    -- Hotkey activation
    if State.Hotkey and input.KeyCode == State.Hotkey then
        ToggleMacro()
        UpdateUI()
        return
    end

    -- Right Shift toggle visibility
    if input.KeyCode == Enum.KeyCode.RightShift then
        State.Visible = not State.Visible
        MainPanel.Visible = State.Visible
    end
end)

-- Activate/Stop
ActivateButton.MouseButton1Click:Connect(function()
    ToggleMacro()
    UpdateUI()
end)

-- Auto Parry toggle
ParryButton.MouseButton1Click:Connect(function()
    State.AutoParry = not State.AutoParry
    if State.AutoParry then
        StartAutoParry()
    else
        StopAutoParry()
    end
    UpdateUI()
end)

-- Predictive toggle
PredictButton.MouseButton1Click:Connect(function()
    State.Predictive = not State.Predictive
    UpdateUI()
end)

-- Visualizer toggle
VizButton.MouseButton1Click:Connect(function()
    State.VizEnabled = not State.VizEnabled
    if not State.VizEnabled and State.VizActive then
        CleanupVisualizer()
    end
    if State.VizEnabled and State.AutoParry then
        InitializeVisualizer()
    end
    UpdateUI()
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- PERIODIC UI REFRESH
-- ═══════════════════════════════════════════════════════════════════════════

RunService.Heartbeat:Connect(function()
    UpdateUI()
end)

-- Initial UI paint
UpdateUI()

--------------------------------------------------------------------------------
-- DONE
--------------------------------------------------------------------------------
