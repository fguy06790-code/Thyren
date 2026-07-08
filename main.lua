--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    THYREN - BLADE BALL                         ║
    ║            Maximum Anti-Detection System v2.0                 ║
    ║                                                              ║
    ║  Features:                                                   ║
    ║    - Multi-layer HID Emulation                                ║
    ║    - Adaptive Timing Humanization                              ║
    ║    - Consistency Analysis & Correction                         ║
    ║    - Input Pattern Randomization                               ║
    ║    - Invisible Spatial Visualizer                              ║
    ║    - Predictive Ball Physics Engine                            ║
    ║    - Clean Modern UI                                          ║
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

-- Detect executor environment
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

-- Check for Fluxus specific
if fluxus then
    Env.IsFluxus = true
    Env.Executor = "Fluxus"
end

-- Check for Krnl specific
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

-- Cleanup old visualizer parts
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

-- Secure parenting with multiple fallbacks
local function SecureParent(gui)
    -- Method 1: Synapse protect_gui
    if Env.HasProtectGui and syn and syn.protect_gui then
        local ok, _ = pcall(function()
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        end)
        if ok then return true end
    end
    
    -- Method 2: Global protect_gui
    if Env.HasProtectGui then
        local ok, _ = pcall(function()
            protect_gui(gui)
            gui.Parent = CoreGui
        end)
        if ok then return true end
    end
    
    -- Method 3: gethui()
    if Env.HasGetHui then
        local ok, _ = pcall(function()
            gui.Parent = gethui()
        end)
        if ok then return true end
    end
    
    -- Method 4: Direct CoreGui
    local ok, _ = pcall(function()
        gui.Parent = CoreGui
    end)
    if ok then return true end
    
    -- Method 5: PlayerGui fallback
    local ok2, _ = pcall(function()
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
    if ok2 then return true end
    
    return false
end

local GuiParented = SecureParent(ScreenGui)

--------------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- HID EMULATION SYSTEM (MULTI-LAYER)
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

local HID = {
    Method = "VirtualInput",
    PressCount = 0,
    ReleaseCount = 0,
    LastInputTime = 0,
}

-- Initialize best available HID method
local function InitializeHID()
    -- Priority 1: keypress/keyrelease (most native-feeling)
    if Env.HasKeypress then
        HID.Method = "keypress"
        HID.Press = function(keyCode)
            local keyName = keyCode.Name
            HID.PressCount = HID.PressCount + 1
            HID.LastInputTime = os.clock()
            
            -- Use string or enum based on executor
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
    
    -- Priority 2: sendinput (some executors)
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
    
    -- Priority 3: VirtualInputManager (universal fallback)
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

-- Mouse input wrapper
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
-- ═══════════════════════════════════════════════════════════════════════════
-- ANTI-DETECTION SYSTEM (MAXIMUM)
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

local AntiDetect = {
    -- Timing Analysis
    ParryHistory = {},
    MaxHistorySize = 30,
    LastParryTime = 0,
    
    -- Humanization Parameters
    BaseReactionTime = 0.045,     -- Base reaction time (45ms)
    ReactionVariance = 0.025,      -- ±25ms random variance
    MinParryInterval = 0.12,      -- Minimum time between parries
    MaxParryInterval = 0.8,       -- Maximum (for slow balls)
    
    -- Pattern Detection
    ConsecutiveParries = 0,
    MaxConsecutive = 8,            -- Force "miss" after this many
    MissChance = 0.015,            -- 1.5% base miss chance
    StreakCounter = 0,
    
    -- Input Randomization
    KeyHoldTimeMin = 0.015,
    KeyHoldTimeMax = 0.035,
    
    -- Adaptive Learning
    AverageInterval = 0.2,
    IntervalVariance = 0.05,
    PatternScore = 0,              -- 0 = natural, 100 = bot-like
}

-- Generate human-like key hold duration
local function GetHumanDelay()
    return AntiDetect.KeyHoldTimeMin + math.random() * (AntiDetect.KeyHoldTimeMax - AntiDetect.KeyHoldTimeMin)
end

-- Generate reaction time with variance
local function GetReactionDelay()
    local base = AntiDetect.BaseReactionTime
    local variance = (math.random() * 2 - 1) * AntiDetect.ReactionVariance
    
    -- Add pattern correction if needed
    if AntiDetect.PatternScore > 50 then
        variance = variance + (math.random() * 0.03)
    end
    
    return math.max(0.01, base + variance)
end

-- Check if we should intentionally "miss" to appear human
local function ShouldIntentionalMiss()
    AntiDetect.ConsecutiveParries = AntiDetect.ConsecutiveParries + 1
    AntiDetect.StreakCounter = AntiDetect.StreakCounter + 1
    
    -- Force miss after too many consecutive
    if AntiDetect.ConsecutiveParries >= AntiDetect.MaxConsecutive then
        AntiDetect.ConsecutiveParries = 0
        return true
    end
    
    -- Random miss chance (increases with streak)
    local dynamicMissChance = AntiDetect.MissChance + (AntiDetect.StreakCounter * 0.002)
    dynamicMissChance = math.min(dynamicMissChance, 0.05) -- Cap at 5%
    
    if math.random() < dynamicMissChance then
        AntiDetect.ConsecutiveParries = 0
        return true
    end
    
    return false
end

-- Analyze timing patterns and calculate "bot score"
local function AnalyzePatterns()
    local history = AntiDetect.ParryHistory
    if #history < 5 then return end
    
    -- Calculate average interval
    local sum = 0
    for _, v in ipairs(history) do
        sum = sum + v
    end
    AntiDetect.AverageInterval = sum / #history
    
    -- Calculate standard deviation
    local variance = 0
    for _, v in ipairs(history) do
        local diff = v - AntiDetect.AverageInterval
        variance = variance + (diff * diff)
    end
    AntiDetect.IntervalVariance = (variance / #history) ^ 0.5
    
    -- Calculate pattern score (0-100)
    -- Lower variance = more bot-like = higher score
    local cv = AntiDetect.IntervalVariance / AntiDetect.AverageInterval -- Coefficient of variation
    AntiDetect.PatternScore = math.clamp((1 - cv) * 100, 0, 100)
end

-- Record parry timing for analysis
local function RecordParryTiming()
    local now = os.clock()
    local interval = now - AntiDetect.LastParryTime
    
    -- Only record if interval is reasonable
    if interval > 0.05 and interval < 5 then
        table.insert(AntiDetect.ParryHistory, interval)
        if #AntiDetect.ParryHistory > AntiDetect.MaxHistorySize then
            table.remove(AntiDetect.ParryHistory, 1)
        end
    end
    
    AntiDetect.LastParryTime = now
    AnalyzePatterns()
end

-- Get adaptive delay based on pattern analysis
local function GetAdaptiveDelay()
    local baseDelay = GetReactionDelay()
    
    -- If patterns are too consistent, add extra variance
    if AntiDetect.PatternScore > 60 then
        baseDelay = baseDelay + (math.random() * 0.04)
    elseif AntiDetect.PatternScore > 40 then
        baseDelay = baseDelay + (math.random() * 0.02)
    end
    
    -- Enforce minimum interval
    local timeSinceLast = os.clock() - AntiDetect.LastParryTime
    if timeSinceLast < AntiDetect.MinParryInterval then
        baseDelay = baseDelay + (AntiDetect.MinParryInterval - timeSinceLast)
    end
    
    return math.max(0, baseDelay)
end

-- Main humanized parry function
local function HumanParry()
    -- Check for intentional miss
    if ShouldIntentionalMiss() then
        -- Reset streak but don't parry
        return
    end
    
    -- Get adaptive delay
    local delay = GetAdaptiveDelay()
    
    -- Execute with delay
    task.delay(delay, function()
        -- Double-check we should still parry
        if not State.AutoParry then return end
        
        HID.Press(Enum.KeyCode.Space)
        RecordParryTiming()
    end)
end

-- Reset streak on manual actions (appears more natural)
local function ResetStreak()
    AntiDetect.StreakCounter = 0
end

--------------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- APPLICATION STATE
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

local State = {
    -- Macro
    Running = false,
    Speed = 10,
    Mode = "KPS",          -- "KPS" or "CPS"
    
    -- Keybind
    Hotkey = nil,
    Binding = false,
    Activation = "Manual",  -- "Manual", "Hotkey", "Binding"
    
    -- Parry
    AutoParry = false,
    Threshold = 28,
    Predictive = true,
    
    -- Visualizer
    VizEnabled = true,
    VizActive = false,
    
    -- UI
    Visible = true,
    Tab = "Main",           -- "Main", "Debug"
}

-- Runtime variables
local Connections = {}
local LastFireTime = 0
local CachedBall = nil
local LastBallCheckTime = 0

--------------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- INVISIBLE VISUALIZER SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════
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
    part.Transparency = 1               -- COMPLETELY INVISIBLE
    part.CastShadow = false
    part.ReceiveShadow = false
    part.Parent = workspace
    table.insert(Viz.Parts, part)
    return part
end

local function InitializeVisualizer()
    if State.VizActive then return end
    State.VizActive = true
    
    -- Range indicator (cylinder around player)
    Viz.RangeRing = CreateInvisiblePart({
        Name = "Thyren_Range",
        Size = Vector3.new(0.2, 1, 1),
        Shape = Enum.PartType.Cylinder,
    })
    
    -- Ball position tracker
    Viz.BallTracker = CreateInvisiblePart({
        Name = "Thyren_BallTracker",
        Size = Vector3.new(0.1, 0.1, 0.1),
        Shape = Enum.PartType.Ball,
    })
    
    -- Trajectory line
    Viz.Trajectory = CreateInvisiblePart({
        Name = "Thyren_Trajectory",
        Size = Vector3.new(0.05, 0.05, 1),
        Shape = Enum.PartType.Block,
    })
    
    -- Prediction point
    Viz.Prediction = CreateInvisiblePart({
        Name = "Thyren_Prediction",
        Size = Vector3.new(0.3, 0.3, 0.3),
        Shape = Enum.PartType.Ball,
    })
    
    -- Parry trigger zone
    Viz.TriggerZone = CreateInvisiblePart({
        Name = "Thyren_TriggerZone",
        Size = Vector3.new(0.5, 0.5, 0.5),
        Shape = Enum.PartType.Ball,
    })
end

local function UpdateVisualizer(ball, root, distance, timeToImpact)
    if not State.VizActive or not root then return end
    
    Viz.UpdateCounter = Viz.UpdateCounter + 1
    
    -- Only update every 3rd frame to reduce overhead
    if Viz.UpdateCounter % 3 ~= 0 then return end
    
    -- Calculate dynamic threshold
    local thresh = State.Threshold
    if ball then
        local spd = BallSpeed(ball)
        if spd > 40 then thresh = thresh + (spd * 0.18) end
        thresh = math.clamp(thresh, 15, 70)
    end
    
    -- Update range ring
    local ringDiameter = thresh * 2
    Viz.RangeRing.Size = Vector3.new(0.2, ringDiameter, ringDiameter)
    Viz.RangeRing.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
    
    if ball then
        -- Update ball tracker
        Viz.BallTracker.Position = ball.Position
        
        -- Update trajectory line
        local direction = root.Position - ball.Position
        local dist = direction.Magnitude
        if dist > 0.1 then
            local midPoint = ball.Position + direction * 0.5
            Viz.Trajectory.Size = Vector3.new(0.05, 0.05, dist)
            Viz.Trajectory.CFrame = CFrame.lookAt(midPoint, root.Position)
        end
        
        -- Update prediction point
        local vel = ball.AssemblyLinearVelocity
        if vel then
            local predictTime = math.min(timeToImpact, 0.5)
            local futurePos = ball.Position + vel * predictTime
            Viz.Prediction.Position = futurePos
        end
        
        -- Update trigger zone
        if dist > 0.1 then
            local triggerPos = ball.Position + direction.Unit * thresh
            Viz.TriggerZone.Position = triggerPos
        end
    else
        -- Hide parts when no ball
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
-- ═══════════════════════════════════════════════════════════════════════════
-- BALL DETECTION ENGINE
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

local function FindBall()
    local now = os.clock()
    
    -- Use cached ball if recent and valid
    if CachedBall and CachedBall.Parent and (now - LastBallCheckTime) < 0.04 then
        return CachedBall
    end
    
    LastBallCheckTime = now
    CachedBall = nil
    
    -- Method 1: Direct workspace scan for common ball names
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("BasePart") then
            local nameLower = obj.Name:lower()
            if nameLower == "ball" or nameLower == "sphereball" or nameLower == "projectile" then
                -- Check for target attribute (multiple formats)
                local target = obj:GetAttribute("target")
                    or obj:GetAttribute("Target")
                    or obj:GetAttribute("TargetPlayer")
                
                -- Check for target value object
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
                
                -- Ball is untargeted or targeting us
                if target == nil or target == PlayerName then
                    CachedBall = obj
                    return obj
                end
            end
        end
    end
    
    -- Method 2: Check common folder names
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
    
    -- Method 3: Deep descendant scan (slower, last resort)
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

-- Calculate ball speed in studs/second
local function BallSpeed(ball)
    if not ball then return 0 end
    local v = ball.AssemblyLinearVelocity
    return (v.X * v.X + v.Y * v.Y + v.Z * v.Z) ^ 0.5
end

-- Calculate time to impact with velocity prediction
local function CalculateTimeToImpact(ball, rootPart)
    if not ball or not rootPart then return 999 end
    
    local speed = BallSpeed(ball)
    if speed < 1 then return 999 end
    
    local ballPos = ball.Position
    local rootPos = rootPart.Position
    local velocity = ball.AssemblyLinearVelocity
    
    -- Predict ball position slightly ahead
    local predictionTime = 0.08
    local futureBallPos = ballPos + velocity * predictionTime
    
    -- Calculate direction and distance to player
    local direction = rootPos - futureBallPos
    local distance = direction.Magnitude
    
    -- Project velocity onto direction vector
    local dotProduct = velocity.X * direction.X
                    + velocity.Y * direction.Y
                    + velocity.Z * direction.Z
    
    -- Ball is moving away from player
    if dotProduct <= 0 then return 999 end
    
    -- Calculate time to reach player
    return distance / (dotProduct / direction.Magnitude)
end

--------------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- MACRO SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════
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
    
    -- High speed mode: double tap per frame
    if State.Speed >= 60 then
        ExecuteMacroInput()
        ExecuteMacroInput()
    -- Normal mode: rate limited with micro-variance
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
-- ═══════════════════════════════════════════════════════════════════════════
-- AUTO PARRY SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

local function StartAutoParry()
    if State.VizEnabled then
        InitializeVisualizer()
    end
    
    if Connections.Parry then Connections.Parry:Disconnect() end
    
    Connections.Parry = RunService.Heartbeat:Connect(function(deltaTime)
        if not State.AutoParry then return end
        
        -- Get character and validate
        local character = LocalPlayer.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if not rootPart or not humanoid or humanoid.Health <= 0 then
            -- Hide visualizer when dead
            if State.VizActive then
                local hidePos = Vector3.new(0, -5000, 0)
                for _, part in ipairs(Viz.Parts) do
                    if part.Parent then part.Position = hidePos end
                end
            end
            return
        end
        
        -- Find active ball
        local ball = FindBall()
        if not ball then
            if State.VizEnabled and State.VizActive then
                UpdateVisualizer(nil, rootPart, 999, 999)
            end
            return
        end
        
        -- Calculate metrics
        local distance = (ball.Position - rootPart.Position).Magnitude
        local speed = BallSpeed(ball)
        local timeToImpact = CalculateTimeToImpact(ball, rootPart)
        
        -- Determine if we should parry
        local shouldParry = false
        
        if State.Predictive then
            -- Predictive mode: parry based on time-to-impact
            local reactionWindow = 0.06 + (0.03 / (speed * 0.015 + 1))
            shouldParry = timeToImpact <= reactionWindow
        else
            -- Distance mode: parry when ball enters threshold
            local dynamicThreshold = State.Threshold
            if speed > 40 then
                dynamicThreshold = dynamicThreshold + (speed * 0.18)
            end
            dynamicThreshold = math.clamp(dynamicThreshold, 15, 70)
            shouldParry = distance <= dynamicThreshold
        end
        
        -- Update visualizer
        if State.VizEnabled and State.VizActive then
            UpdateVisualizer(ball, rootPart, distance, timeToImpact)
        end
        
        -- Execute humanized parry
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
-- ═══════════════════════════════════════════════════════════════════════════
-- THEME & COLORS
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

local Theme = {
    -- Background layers
    Background = Color3.fromRGB(10, 10, 14),
    Surface = Color3.fromRGB(18, 18, 24),
    Card = Color3.fromRGB(26, 26, 34),
    CardRaised = Color3.fromRGB(32, 32, 42),
    
    -- Interactive states
    Hover = Color3.fromRGB(40, 40, 52),
    Pressed = Color3.fromRGB(22, 22, 28),
    
    -- Accent colors
    Accent = Color3.fromRGB(90, 90, 110),
    AccentLight = Color3.fromRGB(130, 130, 155),
    AccentBright = Color3.fromRGB(160, 160, 185),
    
    -- Status colors
    Success = Color3.fromRGB(55, 175, 95),
    Warning = Color3.fromRGB(205, 145, 35),
    Error = Color3.fromRGB(200, 65, 65),
    Info = Color3.fromRGB(95, 135, 215),
    Purple = Color3.fromRGB(135, 95, 195),
    
    -- Text hierarchy
    TextPrimary = Color3.fromRGB(210, 210, 222),
    TextSecondary = Color3.fromRGB(140, 140, 158),
    TextMuted = Color3.fromRGB(80, 80, 100),
    TextDisabled = Color3.fromRGB(50, 50, 65),
    
    -- Borders
    Border = Color3.fromRGB(35, 35, 48),
    BorderLight = Color3.fromRGB(45, 45, 60),
    BorderHighlight = Color3.fromRGB(60, 60, 78),
}

--------------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- UI UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

--- Apply rounded corners to a GUI element
local function ApplyCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

--- Apply a border stroke to a GUI element
local function ApplyStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.4
    stroke.Parent = instance
    return stroke
end

--- Apply hover effect to a button
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

--- Apply press effect to a button
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

--- Create a text label with common properties
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

--- Create a button with common properties
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

--- Create a frame with common properties
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

--- Create a slider track
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

--- Create a status indicator dot
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

--- Create a section separator
local function CreateSeparator(config)
    local sep = Instance.new("Frame")
    sep.Name = config.Name or "Separator"
    sep.Size = config.Size or UDim2.new(1, 0, 0, 1)
    sep.Position = config.Position or UDim2.new(0, 0, 0, 0)
    sep.BackgroundColor3 = Theme.Border
    sep.BackgroundTransparency = config.Transparency or 0.6
    sep.BorderSizePixel = 0
    sep.Parent = config.Parent
    return sep
end

--------------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- BUILD MAIN UI
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

-- Main container (for visibility toggle)
local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(1, 0, 1, 0)
Container.BackgroundTransparency = 1
Container.Parent = ScreenGui

-- ═══════════════════════════════════════════════════════════════════════════
-- MAIN PANEL
-- ═══════════════════════════════════════════════════════════════════════════

local MainPanel = CreateFrame({
    Name = "MainPanel",
    Size = UDim2.new(0, 320, 0, 420),
    Position = UDim2.new(0.5, -160, 0.5, -210),
    Color = Theme.Background,
    Corner = 12,
    Stroke = true,
    StrokeColor = Theme.Border,
    Parent = Container,
})
MainPanel.Active = true
MainPanel.Draggable = true

-- ═══════════════════════════════════════════════════════════════════════════
-- HEADER BAR
-- ═══════════════════════════════════════════════════════════════════════════

local HeaderBar = CreateFrame({
    Name = "HeaderBar",
    Size = UDim2.new(1, 0, 0, 44),
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

-- Title text
local TitleText = CreateLabel({
    Name = "TitleText",
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    Text = "THYREN",
    Color = Theme.TextPrimary,
    Size2 = 15,
    Font = Enum.Font.GothamBlack,
    Parent = HeaderBar,
})

-- Version indicator
local VersionDot = CreateStatusDot({
    Name = "VersionDot",
    Size = 5,
    Position = UDim2.new(0, 98, 0.5, -2.5),
    Color = Theme.Success,
    Parent = HeaderBar,
})

local VersionText = CreateLabel({
    Name = "VersionText",
    Size = UDim2.new(0, 30, 1, 0),
    Position = UDim2.new(0, 106, 0, 0),
    Text = "v2.0",
    Color = Theme.TextDisabled,
    Size2 = 9,
    Font = Enum.Font.GothamMedium,
    Parent = HeaderBar,
})

-- HID method indicator
local HIDDot = CreateStatusDot({
    Name = "HIDDot",
    Size = 4,
    Position = UDim2.new(0, 145, 0.5, -2),
    Color = Theme.Info,
    Parent = HeaderBar,
})

local HIDText = CreateLabel({
    Name = "HIDText",
    Size = UDim2.new(0, 55, 1, 0),
    Position = UDim2.new(0, 152, 0, 0),
    Text = HID.Method,
    Color = Theme.TextDisabled,
    Size2 = 8,
    Font = Enum.Font.GothamMedium,
    Parent = HeaderBar,
})

-- Toggle hint
local ToggleHint = CreateLabel({
    Name = "ToggleHint",
    Size = UDim2.new(0, 55, 1, 0),
    Position = UDim2.new(1, -62, 0, 0),
    Text = "RShift ▾",
    Color = Theme.TextDisabled,
    Size2 = 9,
    Font = Enum.Font.GothamMedium,
    XAlign = Enum.TextXAlignment.Right,
    Parent = HeaderBar,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ═══════════════════════════════════════════════════════════════════════════

local ContentArea = CreateFrame({
    Name = "ContentArea",
    Size = UDim2.new(1, -20, 1, -54),
    Position = UDim2.new(0, 10, 0, 48),
    Transparency = 1,
    Parent = MainPanel,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION: MACRO CONTROLS
-- ═══════════════════════════════════════════════════════════════════════════

local MacroSectionLabel = CreateLabel({
    Name = "MacroSectionLabel",
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 0, 0),
    Text = "MACRO",
    Color = Theme.TextDisabled,
    Size2 = 9,
    Font = Enum.Font.GothamBold,
    Parent = ContentArea,
})

-- Row 1: Mode + Bind buttons
local ModeButton = CreateButton({
    Name = "ModeButton",
    Size = UDim2.new(0.47, 0, 0, 32),
    Position = UDim2.new(0, 0, 0, 20),
    Text = "MODE: KPS",
    TextColor = Theme.TextPrimary,
    TextSize = 11,
    Corner = 8,
    Parent = ContentArea,
})

local BindButton = CreateButton({
    Name = "BindButton",
    Size = UDim2.new(0.47, 0, 0, 32),
    Position = UDim2.new(0.53, 0, 0, 20),
    Text = "KEYBIND",
    TextColor = Theme.TextPrimary,
    TextSize = 11,
    Corner = 8,
    Parent = ContentArea,
})

-- Row 2: Speed slider
local SpeedValueLabel = CreateLabel({
    Name = "SpeedValue",
    Size = UDim2.new(0, 35, 0, 18),
    Position = UDim2.new(0, 0, 0, 60),
    Text = "10",
    Color = Theme.TextPrimary,
    Size2 = 14,
    Font = Enum.Font.GothamBold,
    Parent = ContentArea,
})

local SpeedUnitLabel = CreateLabel({
    Name = "SpeedUnit",
    Size = UDim2.new(0, 28, 0, 18),
    Position = UDim2.new(0, 35, 0, 60),
    Text = "KPS",
    Color = Theme.TextMuted,
    Size2 = 10,
    Font = Enum.Font.GothamMedium,
    Parent = ContentArea,
})

local SpeedLabel = CreateLabel({
    Name = "SpeedLabel",
    Size = UDim2.new(0, 40, 0, 14),
    Position = UDim2.new(0, 0, 0, 78),
    Text = "SPEED",
    Color = Theme.TextDisabled,
    Size2 = 8,
    Font = Enum.Font.GothamBold,
    Parent = ContentArea,
})

local SpeedTrack, SpeedFill, SpeedHandle = CreateSlider({
    Name = "SpeedSlider",
    Size = UDim2.new(1, 0, 0, 5),
    Position = UDim2.new(0, 0, 0, 94),
    HandleSize = 12,
    Parent = ContentArea,
})

-- Separator
CreateSeparator({
    Position = UDim2.new(0, 0, 0, 108),
    Parent = ContentArea,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION: AUTO PARRY
-- ═══════════════════════════════════════════════════════════════════════════

local ParrySectionLabel = CreateLabel({
    Name = "ParrySectionLabel",
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 0, 115),
    Text = "AUTO PARRY",
    Color = Theme.TextDisabled,
    Size2 = 9,
    Font = Enum.Font.GothamBold,
    Parent = ContentArea,
})

-- Parry toggle button (larger)
local ParryButton = CreateButton({
    Name = "ParryButton",
    Size = UDim2.new(1, 0, 0, 36),
    Position = UDim2.new(0, 0, 0, 135),
    Text = "AUTO PARRY",
    TextColor = Theme.TextMuted,
    TextSize = 12,
    Corner = 8,
    Parent = ContentArea,
})

-- Parry status dot
local ParryStatusDot = CreateStatusDot({
    Name = "ParryStatusDot",
    Size = 6,
    Position = UDim2.new(1, -18, 0.5, -3),
    Color = Theme.TextDisabled,
    Parent = ParryButton,
})

-- Row: Predictive + Visualizer toggles
local PredictButton = CreateButton({
    Name = "PredictButton",
    Size = UDim2.new(0.47, 0, 0, 28),
    Position = UDim2.new(0, 0, 0, 180),
    Text = "PREDICTIVE",
    TextColor = Theme.Success,
    TextSize = 9,
    Corner = 6,
    Parent = ContentArea,
})

local VizButton = CreateButton({
    Name = "VizButton",
    Size = UDim2.new(0.47, 0, 0, 28),
    Position = UDim2.new(0.53, 0, 0, 180),
    Text = "VISUALIZER",
    TextColor = Theme.Purple,
    TextSize = 9,
    Corner = 6,
    Parent = ContentArea,
})

-- Threshold slider
local ThresholdValueLabel = CreateLabel({
    Name = "ThresholdValue",
    Size = UDim2.new(0, 25, 0, 16),
    Position = UDim2.new(0, 0, 0, 215),
    Text = "28",
    Color = Theme.TextSecondary,
    Size2 = 12,
    Font = Enum.Font.GothamBold,
    Parent = ContentArea,
})

local ThresholdLabel = CreateLabel({
    Name = "ThresholdLabel",
    Size = UDim2.new(0, 55, 0, 14),
    Position = UDim2.new(0, 0, 0, 232),
    Text = "THRESHOLD",
    Color = Theme.TextDisabled,
    Size2 = 8,
    Font = Enum.Font.GothamBold,
    Parent = ContentArea,
})

local ThresholdTrack, ThresholdFill, ThresholdHandle = CreateSlider({
    Name = "ThresholdSlider",
    Size = UDim2.new(0.7, 0, 0, 4),
    Position = UDim2.new(0, 0, 0, 248),
    HandleSize = 8,
    Parent = ContentArea,
})

-- Separator
CreateSeparator({
    Position = UDim2.new(0, 0, 0, 262),
    Parent = ContentArea,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION: DIAGNOSTICS
-- ═══════════════════════════════════════════════════════════════════════════

local DiagSectionLabel = CreateLabel({
    Name = "DiagSectionLabel",
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 0, 0, 269),
    Text = "DIAGNOSTICS",
    Color = Theme.TextDisabled,
    Size2 = 9,
    Font = Enum.Font.GothamBold,
    Parent = ContentArea,
})

-- Diagnostics panel
local DiagPanel = CreateFrame({
    Name = "DiagPanel",
    Size = UDim2.new(1, 0, 0, 100),
    Position = UDim2.new(0, 0, 0, 289),
    Color = Theme.Surface,
    Corner = 8,
    Stroke = true,
    StrokeColor = Theme.Border,
    StrokeTransparency = 0.6,
    Parent = ContentArea,
})

-- Diagnostic labels with dots
local DiagMacroDot = CreateStatusDot({
    Name = "DiagMacroDot",
    Position = UDim2.new(0, 10, 0, 14),
    Color = Theme.TextDisabled,
    Parent = DiagPanel,
})

local DiagMacroText = CreateLabel({
    Name = "DiagMacroText",
    Size = UDim2.new(1, -30, 0, 16),
    Position = UDim2.new(0, 22, 0, 6),
    Text = "MACRO: IDLE",
    Color = Theme.TextMuted,
    Size2 = 9,
    Font = Enum.Font.GothamMedium,
    Parent = DiagPanel,
})

local DiagParryDot = CreateStatusDot({
    Name = "DiagParryDot",
    Position = UDim2.new(0, 10, 0, 34),
    Color = Theme.TextDisabled,
    Parent = DiagPanel,
})

local DiagParryText = CreateLabel({
    Name = "DiagParryText",
    Size = UDim2.new(1, -30, 0, 16),
    Position = UDim2.new(0, 22, 0, 26),
    Text = "PARRY: OFF",
    Color = Theme.TextMuted,
    Size2 = 9,
    Font = Enum.Font.GothamMedium,
    Parent = DiagPanel,
})

local DiagBallDot = CreateStatusDot({
    Name = "DiagBallDot",
    Position = UDim2.new(0, 10, 0, 54),
    Color = Theme.TextDisabled,
    Parent = DiagPanel,
})

local DiagBallText = CreateLabel({
    Name = "DiagBallText",
    Size = UDim2.new(1, -30, 0, 16),
    Position = UDim2.new(0, 22, 0, 46),
    Text = "TARGET: NONE",
    Color = Theme.TextMuted,
    Size2 = 9,
    Font = Enum.Font.GothamMedium,
    Parent = DiagPanel,
})

local DiagVizDot = CreateStatusDot({
    Name = "DiagVizDot",
    Position = UDim2.new(0, 10, 0, 74),
    Color = Theme.TextDisabled,
    Parent = DiagPanel,
})

local DiagVizText = CreateLabel({
    Name = "DiagVizText",
    Size = UDim2.new(1, -30, 0, 16),
    Position = UDim2.new(0, 22, 0, 66),
    Text = "VIZ: OFF",
    Color = Theme.TextMuted,
    Size2 = 9,
    Font = Enum.Font.GothamMedium,
    Parent = DiagPanel,
})

-- Pattern score display
local PatternScoreText = CreateLabel({
    Name = "PatternScoreText",
    Size = UDim2.new(0, 50, 0, 16),
    Position = UDim2.new(1, -55, 0, 78),
    Text = "BOT: 0%",
    Color = Theme.TextDisabled,
    Size2 = 8,
    Font = Enum.Font.GothamMedium,
    XAlign = Enum.TextXAlignment.Right,
    Parent = DiagPanel,
})

-- ═══════════════════════════════════════════════════════════════════════════
-- ACTIVATE BUTTON (Floating)
-- ═══════════════════════════════════════════════════════════════════════════

local ActivateButton = CreateButton({
    Name = "ActivateButton",
    Size = UDim2.new(0, 280, 0, 40),
    Position = UDim2.new(0.5, -140, 0.5, 220),
    Color = Theme.Surface,
    Text = "ACTIVATE",
    TextColor = Theme.TextPrimary,
    TextSize = 13,
    Corner = 10,
    Stroke = true,
    StrokeColor = Theme.Border,
    Parent = Container,
})

--------------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- UI UPDATE FUNCTION
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

local function UpdateUI()
    -- Speed display
    SpeedValueLabel.Text = State.Speed
    SpeedUnitLabel.Text = State.Mode
    
    -- Show/hide activate button
    ActivateButton.Visible = (State.Activation == "Manual")
    
    -- Macro status
    if State.Running then
        ActivateButton.Text = "STOP"
        ActivateButton.BackgroundColor3 = Theme.CardRaised
        DiagMacroText.Text = "MACRO: ACTIVE"
        DiagMacroText.TextColor3 = Theme.Success
        DiagMacroDot.BackgroundColor3 = Theme.Success
    else
        ActivateButton.Text = "ACTIVATE"
        ActivateButton.BackgroundColor3 = Theme.Surface
        DiagMacroText.Text = "MACRO: IDLE"
        DiagMacroText.TextColor3 = Theme.TextMuted
        DiagMacroDot.BackgroundColor3 = Theme.TextDisabled
    end
    
    -- Parry status
    if State.AutoParry then
        ParryButton.Text = "AUTO PARRY"
        ParryButton.TextColor3 = Theme.Success
        ParryStatusDot.BackgroundColor3 = Theme.Success
        DiagParryText.Text = "PARRY: ACTIVE"
        DiagParryText.TextColor3 = Theme.Success
        DiagParryDot.BackgroundColor3 = Theme.Success
        
        -- Ball tracking
        local ball = FindBall()
        if ball then
            local speed = math.floor(BallSpeed(ball))
            DiagBallText.Text = "TARGET: LOCKED • " .. speed .. " SPD"
            DiagBallText.TextColor3 = Theme.Success
            DiagBallDot.BackgroundColor3 = Theme.Success
        else
            DiagBallText.Text = "TARGET: SEARCHING"
            DiagBallText.TextColor3 = Theme.Warning
            DiagBallDot.BackgroundColor3 = Theme.Warning
        end
    else
        ParryButton.Text = "AUTO PARRY"
        ParryButton.TextColor3 = Theme.TextMuted
        ParryStatusDot.BackgroundColor3 = Theme.TextDisabled
        DiagParryText.Text = "PARRY: OFF"
        DiagParryText.TextColor3 = Theme.TextMuted
        DiagParryDot.BackgroundColor3 = Theme.TextDisabled
        DiagBallText.Text = "TARGET: NONE"
        DiagBallText.TextColor3 = Theme.TextMuted
        DiagBallDot.BackgroundColor3 = Theme.TextDisabled
    end
    
    -- Visualizer status
    if State.VizEnabled and State.VizActive then
        DiagVizText.Text = "VIZ: ACTIVE • " .. #Viz.Parts .. " PARTS"
        DiagVizText.TextColor3 = Theme.Purple
        DiagVizDot.BackgroundColor3 = Theme.Purple
    else
        DiagVizText.Text = "VIZ: OFF"
        DiagVizText.TextColor3 = Theme.TextMuted
        DiagVizDot.BackgroundColor3 = Theme.TextDisabled
    end
    
    -- Pattern score (anti-detection metric)
    local score = math.floor(AntiDetect.PatternScore)
    PatternScoreText.Text = "BOT: " .. score .. "%"
    if score < 30 then
        PatternScoreText.TextColor3 = Theme.Success
    elseif score < 60 then
        PatternScoreText.TextColor3 = Theme.Warning
    else
        PatternScoreText.TextColor3 = Theme.Error
    end
end

-- Background diagnostic update loop
task.spawn(function()
    while task.wait(0.2) do
        if State.AutoParry then
            UpdateUI()
        end
        -- Update pattern score display even when parry is off
        PatternScoreText.Text = "BOT: " .. math.floor(AntiDetect.PatternScore) .. "%"
        if AntiDetect.PatternScore < 30 then
            PatternScoreText.TextColor3 = Theme.Success
        elseif AntiDetect.PatternScore < 60 then
            PatternScoreText.TextColor3 = Theme.Warning
        else
            PatternScoreText.TextColor3 = Theme.Error
        end
    end
end)

--------------------------------------------------------------------------------
-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

-- Mode toggle
ModeButton.MouseButton1Click:Connect(function()
    State.Mode = State.Mode == "KPS" and "CPS" or "KPS"
    ModeButton.Text = "MODE: " .. State.Mode
    UpdateUI()
end)

-- Keybind toggle
BindButton.MouseButton1Click:Connect(function()
    if State.Activation == "Manual" then
        State.Activation = "Binding"
        State.Binding = true
        BindButton.Text = "PRESS KEY..."
        BindButton.TextColor3 = Theme.Warning
    else
        if State.Running then StopMacro() end
        State.Activation = "Manual"
        State.Hotkey = nil
        State.Binding = false
        BindButton.Text = "KEYBIND"
        BindButton.TextColor3 = Theme.TextPrimary
        UpdateUI()
    end
end)

-- Auto parry toggle
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
    PredictButton.TextColor3 = State.Predictive and Theme.Success or Theme.TextMuted
end)

-- Visualizer toggle
VizButton.MouseButton1Click:Connect(function()
    State.VizEnabled = not State.VizEnabled
    VizButton.TextColor3 = State.VizEnabled and Theme.Purple or Theme.TextMuted
    
    if not State.VizEnabled then
        CleanupVisualizer()
    elseif State.AutoParry then
        InitializeVisualizer()
    end
    
    UpdateUI()
end)

-- Activate button
ActivateButton.MouseButton1Click:Connect(function()
    if State.Activation == "Manual" then
        ToggleMacro()
        UpdateUI()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SLIDER INTERACTION
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

local IsDraggingSpeed = false
local IsDraggingThreshold = false

-- Speed slider helpers
local function UpdateSpeedSlider(fraction)
    fraction = math.clamp(fraction, 0, 1)
    State.Speed = math.floor(1 + fraction * 2499)
    SpeedFill.Size = UDim2.new(fraction, 0, 1, 0)
    SpeedHandle.Position = UDim2.new(fraction, -6, 0.5, -6)
    UpdateUI()
end

-- Threshold slider helpers
local function UpdateThresholdSlider(fraction)
    fraction = math.clamp(fraction, 0, 1)
    State.Threshold = math.floor(10 + fraction * 60)
    ThresholdFill.Size = UDim2.new(fraction, 0, 1, 0)
    ThresholdHandle.Position = UDim2.new(fraction, -4, 0.5, -4)
    ThresholdValueLabel.Text = State.Threshold
end

-- Speed handle input
SpeedHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingSpeed = true
    end
end)

-- Speed track click
SpeedTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingSpeed = true
        local fraction = (input.Position.X - SpeedTrack.AbsolutePosition.X) / SpeedTrack.AbsoluteSize.X
        UpdateSpeedSlider(fraction)
    end
end)

-- Threshold handle input
ThresholdHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingThreshold = true
    end
end)

-- Threshold track click
ThresholdTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingThreshold = true
        local fraction = (input.Position.X - ThresholdTrack.AbsolutePosition.X) / ThresholdTrack.AbsoluteSize.X
        UpdateThresholdSlider(fraction)
    end
end)

-- Mouse/touch movement
UserInputService.InputChanged:Connect(function(input)
    if IsDraggingSpeed and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local fraction = (input.Position.X - SpeedTrack.AbsolutePosition.X) / SpeedTrack.AbsoluteSize.X
        UpdateSpeedSlider(fraction)
    end
    
    if IsDraggingThreshold and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local fraction = (input.Position.X - ThresholdTrack.AbsolutePosition.X) / ThresholdTrack.AbsoluteSize.X
        UpdateThresholdSlider(fraction)
    end
end)

-- Release sliders
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsDraggingSpeed = false
        IsDraggingThreshold = false
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- KEYBOARD INPUT
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Handle keybind assignment
    if State.Binding then
        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.RightShift then
            State.Hotkey = input.KeyCode
            State.Activation = "Hotkey"
            State.Binding = false
            BindButton.Text = "[" .. input.KeyCode.Name .. "]"
            BindButton.TextColor3 = Theme.Success
            UpdateUI()
        end
        return
    end
    
    -- Ignore game-processed inputs
    if gameProcessed then
        ResetStreak() -- Natural behavior: game input resets streak
        return
    end
    
    -- Toggle UI visibility
    if input.KeyCode == Enum.KeyCode.RightShift then
        State.Visible = not State.Visible
        Container.Visible = State.Visible
    end
    
    -- Hotkey activation
    if State.Hotkey and input.KeyCode == State.Hotkey and State.Activation == "Hotkey" then
        ToggleMacro()
        UpdateUI()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CHARACTER DEATH HANDLER
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

LocalPlayer.CharacterAdded:Connect(function(character)
    -- Reset anti-detection state on death
    AntiDetect.ConsecutiveParries = 0
    AntiDetect.StreakCounter = 0
    AntiDetect.ParryHistory = {}
    AntiDetect.PatternScore = 0
    
    -- Stop running systems
    if State.Running then StopMacro() end
    
    -- Cleanup and restart visualizer after spawn
    CleanupVisualizer()
    
    if State.AutoParry then
        task.delay(2, function()
            if State.AutoParry then
                StartAutoParry()
            end
        end)
    end
    
    UpdateUI()
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZE
-- ═══════════════════════════════════════════════════════════════════════════
--------------------------------------------------------------------------------

UpdateUI()
