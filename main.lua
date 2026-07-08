-- =============================================================================
-- THYREN REPOSITORY DASHBOARD (BLADE BALL OPTIMIZED - NO PARRY COOLDOWN)
-- TARGET: Roblox Executor Environment
-- =============================================================================

local uiName = "ThyrenUI"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- 1. PURGE PREVIOUS INSTANCES
pcall(function() local oldUI = CoreGui:FindFirstChild(uiName) if oldUI then oldUI:Destroy() end end)
pcall(function() if LocalPlayer then local pGui = LocalPlayer:FindFirstChild("PlayerGui") local oldUI = pGui and pGui:FindFirstChild(uiName) if oldUI then oldUI:Destroy() end end end)

-- 2. ALLOCATE SECURE STORAGE
local TargetParent = nil
local successCore = pcall(function() local test = Instance.new("Folder"); test.Parent = CoreGui; test:Destroy(); TargetParent = CoreGui end)
if not successCore or not TargetParent then TargetParent = LocalPlayer:WaitForChild("PlayerGui") end

-- 3. UNIFIED CONFIGURATION STATE
local EngineState = {
    IsRunning = false,
    TargetSpeed = 10,
    ModeSelection = "KPS",
    LowEndMode = false,
    ActivationMode = "Manual Spam",
    RuntimeHotkey = nil,
    IsBinding = false,
    AutoParryActive = false,
    ParryThreshold = 28,
    SpamKey = Enum.KeyCode.Space,
    ParryConnection = nil,
    ConfigVisible = true,
    Collapsed = false,
    PredictiveParry = true,
    ParryBuffer = 0.05
}

local sendKeyEvent = VirtualInputManager.SendKeyEvent
local sendMouseButtonEvent = VirtualInputManager.SendMouseButtonEvent
local getMouseLocation = UserInputService.GetMouseLocation
local osClock = os.clock
local clamp = math.clamp
local round = math.round
local ipairs = ipairs
local sqrt = math.sqrt

local MacroConnection = nil
local lastFireTime = 0

-- 4. OPTIMIZED STEPPING PIPELINE
local function RunSpamIteration()
    if not EngineState.IsRunning then return end
    local targetSpeed = EngineState.TargetSpeed
    local currentMode = EngineState.ModeSelection
    local spamKey = EngineState.SpamKey
    
    if targetSpeed >= 60 then
        if currentMode == "KPS" then
            sendKeyEvent(VirtualInputManager, true, spamKey, false, game)
            sendKeyEvent(VirtualInputManager, false, spamKey, false, game)
            sendKeyEvent(VirtualInputManager, true, spamKey, false, game)
            sendKeyEvent(VirtualInputManager, false, spamKey, false, game)
        else
            local mousePos = getMouseLocation(UserInputService)
            local mx, my = mousePos.X, mousePos.Y
            sendMouseButtonEvent(VirtualInputManager, mx, my, 0, true, game, 0)
            sendMouseButtonEvent(VirtualInputManager, mx, my, 0, false, game, 0)
            sendMouseButtonEvent(VirtualInputManager, mx, my, 0, true, game, 0)
            sendMouseButtonEvent(VirtualInputManager, mx, my, 0, false, game, 0)
        end
    else
        local currentTime = osClock()
        if (currentTime - lastFireTime) >= (1.0 / targetSpeed) then
            lastFireTime = currentTime
            if currentMode == "KPS" then
                sendKeyEvent(VirtualInputManager, true, spamKey, false, game)
                sendKeyEvent(VirtualInputManager, false, spamKey, false, game)
            else
                local mousePos = getMouseLocation(UserInputService)
                sendMouseButtonEvent(VirtualInputManager, mousePos.X, mousePos.Y, 0, true, game, 0)
                sendMouseButtonEvent(VirtualInputManager, mousePos.X, mousePos.Y, 0, false, game, 0)
            end
        end
    end
end

local function StartLoop()
    EngineState.IsRunning = true
    lastFireTime = osClock()
    if MacroConnection then MacroConnection:Disconnect() end
    MacroConnection = RunService.PreRender:Connect(RunSpamIteration)
end

local function StopLoop()
    EngineState.IsRunning = false
    if MacroConnection then MacroConnection:Disconnect(); MacroConnection = nil end
end

local function ToggleEngine()
    if EngineState.IsRunning then StopLoop() else StartLoop() end
end

-- 5. BLADE BALL OPTIMIZED BALL SCANNER
local cachedBall = nil
local lastBallCheck = 0

local function FindActiveBall()
    local currentTime = osClock()
    
    if cachedBall and (currentTime - lastBallCheck) < 0.1 then
        if cachedBall.Parent and cachedBall:IsA("BasePart") then
            return cachedBall
        end
        cachedBall = nil
    end
    
    lastBallCheck = currentTime
    local playerName = LocalPlayer.Name
    
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("BasePart") and (obj.Name:lower() == "ball" or obj.Name:lower() == "sphereball") then
            local target = obj:GetAttribute("target")
            if not target then target = obj:GetAttribute("Target") end
            if not target then target = obj:GetAttribute("TargetPlayer") end
            if not target then
                local targetVal = obj:FindFirstChild("target") or obj:FindFirstChild("Target")
                if targetVal and targetVal:IsA("StringValue") then
                    target = targetVal.Value
                elseif targetVal and targetVal:IsA("ObjectValue") then
                    target = targetVal.Value and targetVal.Value.Name
                end
            end
            
            if target == nil or target == playerName then
                cachedBall = obj
                return obj
            end
        end
    end
    
    local ballFolder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("Projectiles")
    if ballFolder then
        for _, obj in ipairs(ballFolder:GetChildren()) do
            if obj:IsA("BasePart") then
                local target = obj:GetAttribute("target") or obj:GetAttribute("Target")
                if not target then
                    local targetVal = obj:FindFirstChild("target") or obj:FindFirstChild("Target")
                    if targetVal and targetVal:IsA("StringValue") then
                        target = targetVal.Value
                    end
                end
                if target == nil or target == playerName then
                    cachedBall = obj
                    return obj
                end
            end
        end
    end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("ball") or obj.Name:lower():find("projectile")) then
            local target = obj:GetAttribute("target") or obj:GetAttribute("Target")
            if target == nil or target == playerName then
                cachedBall = obj
                return obj
            end
        end
    end
    
    return nil
end

local function GetBallSpeed(ball)
    if not ball or not ball.AssemblyLinearVelocity then return 0 end
    local vel = ball.AssemblyLinearVelocity
    return sqrt(vel.X * vel.X + vel.Y * vel.Y + vel.Z * vel.Z)
end

local function GetTimeToImpact(ball, characterRoot)
    if not ball or not characterRoot then return math.huge end
    
    local ballPos = ball.Position
    local ballVel = ball.AssemblyLinearVelocity
    local rootPos = characterRoot.Position
    local speed = GetBallSpeed(ball)
    
    if speed < 1 then return math.huge end
    
    local direction = (rootPos - ballPos)
    local distance = direction.Magnitude
    
    local velDot = ballVel.X * direction.X + ballVel.Y * direction.Y + ballVel.Z * direction.Z
    if velDot <= 0 then return math.huge end
    
    return distance / (velDot / distance)
end

-- NO COOLDOWN - fires every single frame when conditions met
local function StartParryTracking()
    if EngineState.ParryConnection then EngineState.ParryConnection:Disconnect() end
    
    EngineState.ParryConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not EngineState.AutoParryActive then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not rootPart or not humanoid or humanoid.Health <= 0 then return end
        
        local ball = FindActiveBall()
        if not ball then return end
        
        local distance = (ball.Position - rootPart.Position).Magnitude
        local ballSpeed = GetBallSpeed(ball)
        
        local shouldParry = false
        
        if EngineState.PredictiveParry then
            local timeToImpact = GetTimeToImpact(ball, rootPart)
            local reactionWindow = EngineState.ParryBuffer + (0.02 / (ballSpeed * 0.01 + 1))
            
            if timeToImpact <= reactionWindow then
                shouldParry = true
            end
        else
            local dynamicThreshold = EngineState.ParryThreshold
            if ballSpeed > 50 then
                dynamicThreshold = dynamicThreshold + (ballSpeed * 0.15)
            end
            dynamicThreshold = clamp(dynamicThreshold, 20, 65)
            
            if distance <= dynamicThreshold then
                shouldParry = true
            end
        end
        
        if shouldParry then
            -- Fire immediately, no cooldown check
            sendKeyEvent(VirtualInputManager, true, Enum.KeyCode.Space, false, game)
            task.delay(0.03, function()
                sendKeyEvent(VirtualInputManager, false, Enum.KeyCode.Space, false, game)
            end)
        end
    end)
end

local function StopParryTracking()
    if EngineState.ParryConnection then
        EngineState.ParryConnection:Disconnect()
        EngineState.ParryConnection = nil
    end
end

-- =============================================================================
-- DEPTH ENHANCEMENT UTILITIES
-- =============================================================================

local Colors = {
    Background = Color3.fromRGB(22, 22, 24),
    Surface = Color3.fromRGB(28, 28, 32),
    SurfaceRaised = Color3.fromRGB(38, 38, 44),
    SurfaceOverlay = Color3.fromRGB(45, 45, 52),
    Interactive = Color3.fromRGB(52, 52, 60),
    InteractiveHover = Color3.fromRGB(62, 62, 72),
    InteractivePressed = Color3.fromRGB(42, 42, 48),
    TrackBackground = Color3.fromRGB(35, 35, 40),
    TrackFill = Color3.fromRGB(140, 140, 155),
    TrackThumb = Color3.fromRGB(185, 185, 200),
    TrackThumbHover = Color3.fromRGB(210, 210, 220),
    ToggleOff = Color3.fromRGB(55, 55, 62),
    ToggleOn = Color3.fromRGB(140, 140, 155),
    ToggleThumb = Color3.fromRGB(220, 220, 230),
    TextPrimary = Color3.fromRGB(235, 235, 245),
    TextSecondary = Color3.fromRGB(165, 165, 180),
    TextMuted = Color3.fromRGB(110, 110, 125),
    BorderSubtle = Color3.fromRGB(60, 60, 70),
    BorderMedium = Color3.fromRGB(80, 80, 95),
    BorderHighlight = Color3.fromRGB(100, 100, 120),
    ShadowDark = Color3.fromRGB(8, 8, 10),
    ShadowMedium = Color3.fromRGB(12, 12, 15),
    ShadowLight = Color3.fromRGB(18, 18, 22),
    ActiveGlow = Color3.fromRGB(150, 150, 170),
    ActiveText = Color3.fromRGB(200, 200, 215),
    SuccessGreen = Color3.fromRGB(80, 180, 100),
    WarningOrange = Color3.fromRGB(220, 160, 60),
}

local function ApplyRadius(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function CreateShadow(parent, sizeOffset, positionOffset, shadowColor, blurSize)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = parent.Size + UDim2.new(sizeOffset.X, sizeOffset.Y, sizeOffset.X, sizeOffset.Y)
    shadow.Position = parent.Position + UDim2.new(positionOffset.X, positionOffset.Y, positionOffset.X + 0.005, positionOffset.Y + 2)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = shadowColor or Colors.ShadowDark
    shadow.ImageTransparency = 0.4
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent.Parent
    ApplyRadius(shadow, 12)
    return shadow
end

local function CreateInnerBorder(parent, color, transparency)
    local inner = Instance.new("UIStroke")
    inner.Name = "InnerBorder"
    inner.Color = color or Color3.fromRGB(15, 15, 18)
    inner.Thickness = 1
    inner.Transparency = transparency or 0.5
    inner.Parent = parent
    return inner
end

local function CreateOuterBorder(parent, color, thickness)
    local outer = Instance.new("UIStroke")
    outer.Name = "OuterBorder"
    outer.Color = color or Colors.BorderSubtle
    outer.Thickness = thickness or 1
    outer.Transparency = 0.2
    outer.Parent = parent
    return outer
end

local function CreateDepthGradient(parent, direction)
    local gradient = Instance.new("UIGradient")
    gradient.Name = "DepthGradient"
    gradient.Rotation = direction or 180
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.97),
        NumberSequenceKeypoint.new(0.4, 0.98),
        NumberSequenceKeypoint.new(1, 0.92)
    })
    gradient.Parent = parent
    return gradient
end

local function CreateTopHighlight(parent)
    local highlight = Instance.new("Frame")
    highlight.Name = "TopHighlight"
    highlight.Size = UDim2.new(1, -4, 0, 1)
    highlight.Position = UDim2.new(0, 2, 0, 0.5)
    highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    highlight.BackgroundTransparency = 0.88
    highlight.ZIndex = parent.ZIndex + 1
    highlight.Parent = parent
    ApplyRadius(highlight, 1)
    return highlight
end

local function CreateBottomShadow(parent)
    local shadow = Instance.new("Frame")
    shadow.Name = "BottomShadow"
    shadow.Size = UDim2.new(1, -4, 0, 1)
    shadow.Position = UDim2.new(0, 2, 1, -1.5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.ZIndex = parent.ZIndex + 1
    shadow.Parent = parent
    ApplyRadius(shadow, 1)
    return shadow
end

local function AddHoverEffect(button, baseColor, hoverColor, pressedColor)
    local originalColor = baseColor or button.BackgroundColor3
    local hoverCol = hoverColor or Colors.InteractiveHover
    local pressCol = pressedColor or Colors.InteractivePressed
    
    button.MouseEnter:Connect(function()
        if not button:GetAttribute("IsPressed") then
            TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = hoverCol
            }):Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        if not button:GetAttribute("IsPressed") then
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = originalColor
            }):Play()
        end
    end)
    
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            button:SetAttribute("IsPressed", true)
            TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = pressCol
            }):Play()
        end
    end)
    
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            button:SetAttribute("IsPressed", false)
            TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = hoverCol
            }):Play()
        end
    end)
end

local function CreateDepthPanel(properties)
    local panel = Instance.new("Frame")
    panel.Name = properties.Name or "DepthPanel"
    panel.Size = properties.Size or UDim2.new(1, 0, 1, 0)
    panel.Position = properties.Position or UDim2.new(0, 0, 0, 0)
    panel.BackgroundColor3 = properties.Color or Colors.Surface
    panel.ZIndex = properties.ZIndex or 1
    panel.Parent = properties.Parent
    ApplyRadius(panel, properties.Radius or 8)
    
    if properties.Shadow ~= false then
        CreateShadow(panel, 
            properties.ShadowSize or {X = 0.02, Y = 4}, 
            properties.ShadowPos or {X = 0.005, Y = 3},
            properties.ShadowColor or Colors.ShadowDark
        )
    end
    
    CreateOuterBorder(panel, properties.BorderColor or Colors.BorderSubtle, properties.BorderThickness or 1)
    
    if properties.Gradient ~= false then
        CreateDepthGradient(panel, properties.GradientDirection or 180)
    end
    
    if properties.Raised then
        CreateTopHighlight(panel)
        CreateBottomShadow(panel)
    end
    
    return panel
end

-- =============================================================================
-- 6. INTERFACE ARCHITECTURE (BLADE BALL EDITION)
-- =============================================================================

local ScreenGui = Instance.new("ScreenGui", TargetParent)
ScreenGui.Name = uiName
ScreenGui.ResetOnSpawn = false

local ConfigCanvas = Instance.new("Frame", ScreenGui)
ConfigCanvas.Name = "ConfigCanvas"
ConfigCanvas.Size = UDim2.new(1, 0, 1, 0)
ConfigCanvas.BackgroundTransparency = 1

local MainFrame = CreateDepthPanel({
    Name = "MainFrame",
    Parent = ConfigCanvas,
    Size = UDim2.new(0, 500, 0, 400),
    Position = UDim2.new(0.5, -250, 0.5, -230),
    Color = Colors.Surface,
    Radius = 10,
    Shadow = true,
    ShadowSize = {X = 0.03, Y = 8},
    ShadowPos = {X = 0.008, Y = 6},
    ShadowColor = Colors.ShadowDark,
    Raised = true,
    BorderColor = Colors.BorderSubtle,
    GradientDirection = 180,
    ZIndex = 1
})
MainFrame.Active = true
MainFrame.Draggable = true

local InnerContent = Instance.new("Frame", MainFrame)
InnerContent.Name = "InnerContent"
InnerContent.Size = UDim2.new(1, -8, 1, -8)
InnerContent.Position = UDim2.new(0, 4, 0, 4)
InnerContent.BackgroundTransparency = 1
InnerContent.ZIndex = 2

CreateInnerBorder(MainFrame, Color3.fromRGB(10, 10, 12), 0.6)

local TitleLabel = Instance.new("TextButton", ConfigCanvas)
TitleLabel.Name = "LogoButton"
TitleLabel.Size = UDim2.new(0, 160, 0, 40)
TitleLabel.Position = UDim2.new(0.5, -230, 0.5, -220)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "THYREN"
TitleLabel.TextColor3 = Colors.TextPrimary
TitleLabel.Font = Enum.Font.Michroma
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 5

local LogoShadow = Instance.new("TextLabel", ConfigCanvas)
LogoShadow.Name = "LogoShadow"
LogoShadow.Size = UDim2.new(0, 160, 0, 40)
LogoShadow.Position = UDim2.new(0.5, -229, 0.5, -219)
LogoShadow.BackgroundTransparency = 1
LogoShadow.Text = "THYREN"
LogoShadow.TextColor3 = Colors.ShadowDark
LogoShadow.Font = Enum.Font.Michroma
LogoShadow.TextSize = 16
LogoShadow.TextXAlignment = Enum.TextXAlignment.Left
LogoShadow.TextTransparency = 0.5
LogoShadow.ZIndex = 4

local GameLabel = Instance.new("TextLabel", ConfigCanvas)
GameLabel.Size = UDim2.new(0, 120, 0, 20)
GameLabel.Position = UDim2.new(0.5, -40, 0.5, -215)
GameLabel.BackgroundTransparency = 1
GameLabel.Text = "BLADE BALL"
GameLabel.TextColor3 = Colors.TextMuted
GameLabel.Font = Enum.Font.Michroma
GameLabel.TextSize = 10
GameLabel.ZIndex = 5

local ModeBtn = Instance.new("TextButton", ConfigCanvas)
ModeBtn.Size = UDim2.new(0, 215, 0, 42)
ModeBtn.Position = UDim2.new(0.5, -230, 0.5, -170)
ModeBtn.BackgroundColor3 = Colors.Interactive
ModeBtn.Text = "MODE: KPS"
ModeBtn.TextColor3 = Colors.TextPrimary
ModeBtn.Font = Enum.Font.Michroma
ModeBtn.ZIndex = 5
ApplyRadius(ModeBtn, 6)
CreateOuterBorder(ModeBtn, Colors.BorderMedium, 1)
CreateTopHighlight(ModeBtn)
CreateBottomShadow(ModeBtn)
CreateDepthGradient(ModeBtn, 180)
AddHoverEffect(ModeBtn, Colors.Interactive, Colors.InteractiveHover, Colors.InteractivePressed)

local SwitchContainer = Instance.new("Frame", ConfigCanvas)
SwitchContainer.Size = UDim2.new(0, 215, 0, 42)
SwitchContainer.Position = UDim2.new(0.5, 15, 0.5, -170)
SwitchContainer.BackgroundColor3 = Colors.Interactive
SwitchContainer.ZIndex = 5
ApplyRadius(SwitchContainer, 6)
CreateOuterBorder(SwitchContainer, Colors.BorderMedium, 1)
CreateTopHighlight(SwitchContainer)
CreateBottomShadow(SwitchContainer)
CreateDepthGradient(SwitchContainer, 180)

local SwitchLabel = Instance.new("TextLabel", SwitchContainer)
SwitchLabel.Size = UDim2.new(0, 140, 1, 0)
SwitchLabel.Position = UDim2.new(0, 12, 0, 0)
SwitchLabel.BackgroundTransparency = 1
SwitchLabel.Text = "KEYBIND"
SwitchLabel.TextColor3 = Colors.TextPrimary
SwitchLabel.Font = Enum.Font.Michroma
SwitchLabel.ZIndex = 6

local ToggleTrack = Instance.new("TextButton", SwitchContainer)
ToggleTrack.Size = UDim2.new(0, 46, 0, 26)
ToggleTrack.Position = UDim2.new(1, -56, 0.5, -13)
ToggleTrack.BackgroundColor3 = Colors.ToggleOff
ToggleTrack.Text = ""
ToggleTrack.ZIndex = 6
ApplyRadius(ToggleTrack, 13)
CreateInnerBorder(ToggleTrack, Color3.fromRGB(20, 20, 25), 0.4)
CreateDepthGradient(ToggleTrack, 180)

local ToggleThumb = Instance.new("Frame", ToggleTrack)
ToggleThumb.Size = UDim2.new(0, 22, 0, 22)
ToggleThumb.Position = UDim2.new(0, 2, 0.5, -11)
ToggleThumb.BackgroundColor3 = Colors.ToggleThumb
ToggleThumb.ZIndex = 7
ApplyRadius(ToggleThumb, 11)

local ThumbHighlight = Instance.new("Frame", ToggleThumb)
ThumbHighlight.Size = UDim2.new(1, -4, 0, 8)
ThumbHighlight.Position = UDim2.new(0, 2, 0, 1)
ThumbHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ThumbHighlight.BackgroundTransparency = 0.75
ThumbHighlight.ZIndex = 8
ApplyRadius(ThumbHighlight, 4)

local SliderTrack = Instance.new("Frame", ConfigCanvas)
SliderTrack.Size = UDim2.new(0, 340, 0, 8)
SliderTrack.Position = UDim2.new(0.5, -230, 0.5, -105)
SliderTrack.BackgroundColor3 = Colors.TrackBackground
SliderTrack.ZIndex = 5
ApplyRadius(SliderTrack, 4)
CreateInnerBorder(SliderTrack, Color3.fromRGB(15, 15, 18), 0.3)

local SliderFill = Instance.new("Frame", SliderTrack)
SliderFill.Size = UDim2.new(0.01, 0, 1, 0)
SliderFill.BackgroundColor3 = Colors.TrackFill
SliderFill.ZIndex = 6
ApplyRadius(SliderFill, 4)
CreateDepthGradient(SliderFill, 90)

local SliderButton = Instance.new("TextButton", SliderTrack)
SliderButton.Size = UDim2.new(0, 16, 0, 16)
SliderButton.Position = UDim2.new(0.01, -8, 0.5, -8)
SliderButton.BackgroundColor3 = Colors.TrackThumb
SliderButton.Text = ""
SliderButton.ZIndex = 7
ApplyRadius(SliderButton, 8)
CreateOuterBorder(SliderButton, Color3.fromRGB(200, 200, 210), 1)

local SliderThumbHighlight = Instance.new("Frame", SliderButton)
SliderThumbHighlight.Size = UDim2.new(1, -4, 0, 5)
SliderThumbHighlight.Position = UDim2.new(0, 2, 0, 1)
SliderThumbHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderThumbHighlight.BackgroundTransparency = 0.6
SliderThumbHighlight.ZIndex = 8
ApplyRadius(SliderThumbHighlight, 3)

SliderButton.MouseEnter:Connect(function()
    TweenService:Create(SliderButton, TweenInfo.new(0.12), {BackgroundColor3 = Colors.TrackThumbHover}):Play()
end)
SliderButton.MouseLeave:Connect(function()
    TweenService:Create(SliderButton, TweenInfo.new(0.15), {BackgroundColor3 = Colors.TrackThumb}):Play()
end)

local SpeedDisplay = Instance.new("TextLabel", ConfigCanvas)
SpeedDisplay.Size = UDim2.new(0, 120, 0, 30)
SpeedDisplay.Position = UDim2.new(0.5, 110, 0.5, -117)
SpeedDisplay.BackgroundTransparency = 1
SpeedDisplay.Text = "10 KPS"
SpeedDisplay.TextColor3 = Colors.TextSecondary
SpeedDisplay.Font = Enum.Font.Michroma
SpeedDisplay.TextSize = 14
SpeedDisplay.ZIndex = 5

local SpeedShadow = Instance.new("TextLabel", ConfigCanvas)
SpeedShadow.Size = UDim2.new(0, 120, 0, 30)
SpeedShadow.Position = UDim2.new(0.5, 111, 0.5, -116)
SpeedShadow.BackgroundTransparency = 1
SpeedShadow.Text = "10 KPS"
SpeedShadow.TextColor3 = Colors.ShadowDark
SpeedShadow.Font = Enum.Font.Michroma
SpeedShadow.TextSize = 14
SpeedShadow.TextTransparency = 0.6
SpeedShadow.ZIndex = 4

local ParryBtn = Instance.new("TextButton", ConfigCanvas)
ParryBtn.Size = UDim2.new(0, 460, 0, 40)
ParryBtn.Position = UDim2.new(0.5, -230, 0.5, -75)
ParryBtn.BackgroundColor3 = Colors.Interactive
ParryBtn.Text = "AUTO PARRY: DISABLED"
ParryBtn.TextColor3 = Colors.TextMuted
ParryBtn.Font = Enum.Font.Michroma
ParryBtn.ZIndex = 5
ApplyRadius(ParryBtn, 6)
CreateOuterBorder(ParryBtn, Colors.BorderMedium, 1)
CreateTopHighlight(ParryBtn)
CreateBottomShadow(ParryBtn)
CreateDepthGradient(ParryBtn, 180)
AddHoverEffect(ParryBtn, Colors.Interactive, Colors.InteractiveHover, Colors.InteractivePressed)

local PredictBtn = Instance.new("TextButton", ConfigCanvas)
PredictBtn.Size = UDim2.new(0, 220, 0, 36)
PredictBtn.Position = UDim2.new(0.5, -230, 0.5, -25)
PredictBtn.BackgroundColor3 = Colors.Interactive
PredictBtn.Text = "PREDICTIVE: ON"
PredictBtn.TextColor3 = Colors.SuccessGreen
PredictBtn.Font = Enum.Font.Michroma
PredictBtn.TextSize = 11
PredictBtn.ZIndex = 5
ApplyRadius(PredictBtn, 6)
CreateOuterBorder(PredictBtn, Colors.BorderMedium, 1)
CreateTopHighlight(PredictBtn)
CreateBottomShadow(PredictBtn)
AddHoverEffect(PredictBtn, Colors.Interactive, Colors.InteractiveHover, Colors.InteractivePressed)

local ThreshLabel = Instance.new("TextLabel", ConfigCanvas)
ThreshLabel.Size = UDim2.new(0, 100, 0, 20)
ThreshLabel.Position = UDim2.new(0.5, 10, 0.5, -30)
ThreshLabel.BackgroundTransparency = 1
ThreshLabel.Text = "THRESHOLD: 28"
ThreshLabel.TextColor3 = Colors.TextMuted
ThreshLabel.Font = Enum.Font.Michroma
ThreshLabel.TextSize = 10
ThreshLabel.ZIndex = 5

local ThreshSliderTrack = Instance.new("Frame", ConfigCanvas)
ThreshSliderTrack.Size = UDim2.new(0, 200, 0, 6)
ThreshSliderTrack.Position = UDim2.new(0.5, 10, 0.5, -8)
ThreshSliderTrack.BackgroundColor3 = Colors.TrackBackground
ThreshSliderTrack.ZIndex = 5
ApplyRadius(ThreshSliderTrack, 3)
CreateInnerBorder(ThreshSliderTrack, Color3.fromRGB(15, 15, 18), 0.3)

local ThreshSliderFill = Instance.new("Frame", ThreshSliderTrack)
ThreshSliderFill.Size = UDim2.new(0.28, 0, 1, 0)
ThreshSliderFill.BackgroundColor3 = Colors.TrackFill
ThreshSliderFill.ZIndex = 6
ApplyRadius(ThreshSliderFill, 3)

local ThreshSliderButton = Instance.new("TextButton", ThreshSliderTrack)
ThreshSliderButton.Size = UDim2.new(0, 14, 0, 14)
ThreshSliderButton.Position = UDim2.new(0.28, -7, 0.5, -7)
ThreshSliderButton.BackgroundColor3 = Colors.TrackThumb
ThreshSliderButton.Text = ""
ThreshSliderButton.ZIndex = 7
ApplyRadius(ThreshSliderButton, 7)

local DiagPanel = Instance.new("Frame", ConfigCanvas)
DiagPanel.Size = UDim2.new(0, 460, 0, 130)
DiagPanel.Position = UDim2.new(0.5, -230, 0.5, 10)
DiagPanel.BackgroundColor3 = Colors.SurfaceRaised
DiagPanel.ZIndex = 4
ApplyRadius(DiagPanel, 6)
CreateOuterBorder(DiagPanel, Colors.BorderSubtle, 1)
CreateInnerBorder(DiagPanel, Color3.fromRGB(15, 15, 18), 0.5)
CreateDepthGradient(DiagPanel, 180)

local DiagHeader = Instance.new("Frame", DiagPanel)
DiagHeader.Size = UDim2.new(1, -16, 0, 1)
DiagHeader.Position = UDim2.new(0, 8, 0, 22)
DiagHeader.BackgroundColor3 = Colors.BorderSubtle
DiagHeader.BackgroundTransparency = 0.5
DiagHeader.ZIndex = 5

local DiagHeaderLabel = Instance.new("TextLabel", DiagPanel)
DiagHeaderLabel.Size = UDim2.new(0, 100, 0, 20)
DiagHeaderLabel.Position = UDim2.new(0, 12, 0, 8)
DiagHeaderLabel.BackgroundTransparency = 1
DiagHeaderLabel.Text = "DIAGNOSTICS"
DiagHeaderLabel.TextColor3 = Colors.TextMuted
DiagHeaderLabel.Font = Enum.Font.Michroma
DiagHeaderLabel.TextSize = 9
DiagHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
DiagHeaderLabel.ZIndex = 5

local DiagMacroLabel = Instance.new("TextLabel", DiagPanel)
DiagMacroLabel.Size = UDim2.new(1, -30, 0, 18)
DiagMacroLabel.Position = UDim2.new(0, 15, 0, 35)
DiagMacroLabel.BackgroundTransparency = 1
DiagMacroLabel.Text = "STATUS: STANDBY"
DiagMacroLabel.TextColor3 = Colors.TextMuted
DiagMacroLabel.Font = Enum.Font.Michroma
DiagMacroLabel.TextSize = 10
DiagMacroLabel.TextXAlignment = Enum.TextXAlignment.Left
DiagMacroLabel.ZIndex = 5

local DiagKeyLabel = Instance.new("TextLabel", DiagPanel)
DiagKeyLabel.Size = UDim2.new(1, -30, 0, 18)
DiagKeyLabel.Position = UDim2.new(0, 15, 0, 53)
DiagKeyLabel.BackgroundTransparency = 1
DiagKeyLabel.Text = "BIND REGISTER: NONE"
DiagKeyLabel.TextColor3 = Colors.TextMuted
DiagKeyLabel.Font = Enum.Font.Michroma
DiagKeyLabel.TextSize = 10
DiagKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
DiagKeyLabel.ZIndex = 5

local DiagParryLabel = Instance.new("TextLabel", DiagPanel)
DiagParryLabel.Size = UDim2.new(1, -30, 0, 18)
DiagParryLabel.Position = UDim2.new(0, 15, 0, 71)
DiagParryLabel.BackgroundTransparency = 1
DiagParryLabel.Text = "DEFENSE MATRIX: DISENGAGED"
DiagParryLabel.TextColor3 = Colors.TextMuted
DiagParryLabel.Font = Enum.Font.Michroma
DiagParryLabel.TextSize = 10
DiagParryLabel.TextXAlignment = Enum.TextXAlignment.Left
DiagParryLabel.ZIndex = 5

local DiagBallLabel = Instance.new("TextLabel", DiagPanel)
DiagBallLabel.Size = UDim2.new(1, -30, 0, 18)
DiagBallLabel.Position = UDim2.new(0, 15, 0, 89)
DiagBallLabel.BackgroundTransparency = 1
DiagBallLabel.Text = "BALL TRACKING: SEARCHING"
DiagBallLabel.TextColor3 = Colors.TextMuted
DiagBallLabel.Font = Enum.Font.Michroma
DiagBallLabel.TextSize = 10
DiagBallLabel.TextXAlignment = Enum.TextXAlignment.Left
DiagBallLabel.ZIndex = 5

local DiagSpeedLabel = Instance.new("TextLabel", DiagPanel)
DiagSpeedLabel.Size = UDim2.new(1, -30, 0, 18)
DiagSpeedLabel.Position = UDim2.new(0, 15, 0, 107)
DiagSpeedLabel.BackgroundTransparency = 1
DiagSpeedLabel.Text = "BALL VELOCITY: 0 STU/S"
DiagSpeedLabel.TextColor3 = Colors.TextMuted
DiagSpeedLabel.Font = Enum.Font.Michroma
DiagSpeedLabel.TextSize = 10
DiagSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
DiagSpeedLabel.ZIndex = 5

local function CreateStatusDot(parent, xPos, yPos, zIndex)
    local dot = Instance.new("Frame", parent)
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, xPos, 0, yPos)
    dot.BackgroundColor3 = Colors.TextMuted
    dot.ZIndex = zIndex or 6
    ApplyRadius(dot, 3)
    return dot
end

local StatusDot1 = CreateStatusDot(DiagPanel, 445, 40, 6)
local StatusDot2 = CreateStatusDot(DiagPanel, 445, 58, 6)
local StatusDot3 = CreateStatusDot(DiagPanel, 445, 76, 6)
local StatusDot4 = CreateStatusDot(DiagPanel, 445, 94, 6)

local ControlPod = CreateDepthPanel({
    Name = "ControlPod",
    Parent = ScreenGui,
    Size = UDim2.new(0, 260, 0, 75),
    Position = UDim2.new(0.5, -130, 0.5, 180),
    Color = Colors.Surface,
    Radius = 8,
    Shadow = true,
    ShadowSize = {X = 0.04, Y = 10},
    ShadowPos = {X = 0.01, Y = 8},
    ShadowColor = Colors.ShadowDark,
    Raised = true,
    BorderColor = Colors.BorderSubtle,
    GradientDirection = 180,
    ZIndex = 1
})
ControlPod.Active = true
ControlPod.Draggable = true
CreateInnerBorder(ControlPod, Color3.fromRGB(10, 10, 12), 0.5)

local ActionButton = Instance.new("TextButton", ScreenGui)
ActionButton.Size = UDim2.new(0, 230, 0, 38)
ActionButton.Position = UDim2.new(0.5, -115, 0.5, 194)
ActionButton.BackgroundColor3 = Colors.SurfaceOverlay
ActionButton.Text = "ACTIVATE"
ActionButton.TextColor3 = Colors.TextPrimary
ActionButton.Font = Enum.Font.Michroma
ActionButton.TextSize = 13
ActionButton.ZIndex = 5
ApplyRadius(ActionButton, 6)
CreateOuterBorder(ActionButton, Colors.BorderMedium, 1)
CreateTopHighlight(ActionButton)
CreateBottomShadow(ActionButton)
CreateDepthGradient(ActionButton, 180)

local ActionTextShadow = Instance.new("TextLabel", ScreenGui)
ActionTextShadow.Size = UDim2.new(0, 230, 0, 38)
ActionTextShadow.Position = UDim2.new(0.5, -114, 0.5, 195)
ActionTextShadow.BackgroundTransparency = 1
ActionTextShadow.Text = "ACTIVATE"
ActionTextShadow.TextColor3 = Colors.ShadowDark
ActionTextShadow.Font = Enum.Font.Michroma
ActionTextShadow.TextSize = 13
ActionTextShadow.TextTransparency = 0.6
ActionTextShadow.ZIndex = 4

AddHoverEffect(ActionButton, Colors.SurfaceOverlay, Colors.InteractiveHover, Colors.InteractivePressed)

local StatusBar = Instance.new("TextLabel", ScreenGui)
StatusBar.Size = UDim2.new(0, 230, 0, 18)
StatusBar.Position = UDim2.new(0.5, -115, 0.5, 235)
StatusBar.BackgroundTransparency = 1
StatusBar.Text = "WORKFLOW IDLE"
StatusBar.TextColor3 = Colors.TextMuted
StatusBar.Font = Enum.Font.Michroma
StatusBar.TextSize = 10
StatusBar.ZIndex = 5

-- =============================================================================
-- 7. SIGNAL HANDLING & EVENTS
-- =============================================================================

local function UpdateUI()
    local labelMode = EngineState.ModeSelection == "KPS" and "KPS" or "CPS"
    local speedText = string.format("%d %s", EngineState.TargetSpeed, labelMode)
    SpeedDisplay.Text = speedText
    SpeedShadow.Text = speedText
    
    local manualMode = EngineState.ActivationMode == "Manual Spam"
    ControlPod.Visible = manualMode
    ActionButton.Visible = manualMode
    StatusBar.Visible = manualMode
    ActionTextShadow.Visible = manualMode
    
    ThreshLabel.Text = "THRESHOLD: " .. tostring(EngineState.ParryThreshold)
    
    if EngineState.IsRunning then
        StatusBar.Text = "MACRO FIRING"
        StatusBar.TextColor3 = Colors.TextSecondary
        ActionButton.Text = "HALT CORE"
        ActionButton.BackgroundColor3 = Colors.Interactive
        ActionTextShadow.Text = "HALT CORE"
        DiagMacroLabel.Text = "STATUS: RUNNING CORE"
        DiagMacroLabel.TextColor3 = Colors.ActiveText
        StatusDot1.BackgroundColor3 = Colors.ActiveGlow
    else
        StatusBar.Text = "WORKFLOW IDLE"
        StatusBar.TextColor3 = Colors.TextMuted
        ActionButton.Text = "ACTIVATE"
        ActionButton.BackgroundColor3 = Colors.SurfaceOverlay
        ActionTextShadow.Text = "ACTIVATE"
        DiagMacroLabel.Text = "STATUS: STANDBY"
        DiagMacroLabel.TextColor3 = Colors.TextMuted
        StatusDot1.BackgroundColor3 = Colors.TextMuted
    end
end

task.spawn(function()
    while true do
        task.wait(0.25)
        local ball = FindActiveBall()
        if ball then
            DiagBallLabel.Text = "BALL TRACKING: LOCKED"
            DiagBallLabel.TextColor3 = Colors.SuccessGreen
            StatusDot4.BackgroundColor3 = Colors.SuccessGreen
            local speed = GetBallSpeed(ball)
            DiagSpeedLabel.Text = string.format("BALL VELOCITY: %d STU/S", round(speed))
        else
            DiagBallLabel.Text = "BALL TRACKING: SEARCHING"
            DiagBallLabel.TextColor3 = Colors.WarningOrange
            StatusDot4.BackgroundColor3 = Colors.WarningOrange
            DiagSpeedLabel.Text = "BALL VELOCITY: N/A"
        end
    end
end)

TitleLabel.MouseButton1Click:Connect(function()
    EngineState.Collapsed = not EngineState.Collapsed
    local targetSize = EngineState.Collapsed and UDim2.new(0, 180, 0, 42) or UDim2.new(0, 500, 0, 400)
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = targetSize}):Play()
    local v = not EngineState.Collapsed
    ModeBtn.Visible = v
    SwitchContainer.Visible = v
    SliderTrack.Visible = v
    SpeedDisplay.Visible = v
    SpeedShadow.Visible = v
    ParryBtn.Visible = v
    PredictBtn.Visible = v
    ThreshLabel.Visible = v
    ThreshSliderTrack.Visible = v
    DiagPanel.Visible = v
    GameLabel.Visible = v
end)

local function AnimateSwitch(isOn)
    local targetPos = isOn and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
    local targetColor = isOn and Colors.ToggleOn or Colors.ToggleOff
    TweenService:Create(ToggleThumb, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    TweenService:Create(ThumbHighlight, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos + UDim2.new(0, 2, 0, 1)}):Play()
    TweenService:Create(ToggleTrack, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()
end

local IsDragging = false
local IsThreshDragging = false

local function UpdateSlider(inputObj)
    local fraction = clamp((inputObj.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
    local maxLimit = EngineState.LowEndMode and 200 or 2500
    local calculated = round(1 + (fraction * (maxLimit - 1)))
    EngineState.TargetSpeed = calculated
    SliderFill.Size = UDim2.new(fraction, 0, 1, 0)
    SliderButton.Position = UDim2.new(fraction, -8, 0.5, -8)
    SliderThumbHighlight.Position = UDim2.new(0, 2, 0, 1)
    UpdateUI()
end

local function UpdateThreshSlider(inputObj)
    local fraction = clamp((inputObj.Position.X - ThreshSliderTrack.AbsolutePosition.X) / ThreshSliderTrack.AbsoluteSize.X, 0, 1)
    local calculated = round(10 + (fraction * 60))
    EngineState.ParryThreshold = calculated
    ThreshSliderFill.Size = UDim2.new(fraction, 0, 1, 0)
    ThreshSliderButton.Position = UDim2.new(fraction, -7, 0.5, -7)
    UpdateUI()
end

SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsDragging = true
        TweenService:Create(SliderButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 18, 0, 18), Position = SliderButton.Position + UDim2.new(0, -1, 0, -1)}):Play()
    end
end)

ThreshSliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        IsThreshDragging = true
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateSlider(input)
    end
    if IsThreshDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateThreshSlider(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if IsDragging then
            IsDragging = false
            TweenService:Create(SliderButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 16, 0, 16), Position = SliderButton.Position + UDim2.new(0, 1, 0, 1)}):Play()
        end
        IsThreshDragging = false
    end
end)

local function BindChassisPosition(chassisFrame, elementList)
    local offsets = {}
    for _, el in ipairs(elementList) do
        offsets[el] = el.Position - chassisFrame.Position
    end
    chassisFrame:GetPropertyChangedSignal("Position"):Connect(function()
        local basePos = chassisFrame.Position
        for el, originalOffset in pairs(offsets) do
            el.Position = basePos + originalOffset
        end
    end)
end

BindChassisPosition(MainFrame, {TitleLabel, LogoShadow, ModeBtn, SwitchContainer, SliderTrack, SpeedDisplay, SpeedShadow, ParryBtn, PredictBtn, ThreshLabel, ThreshSliderTrack, DiagPanel, GameLabel})
BindChassisPosition(ControlPod, {ActionButton, ActionTextShadow, StatusBar})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if EngineState.IsBinding then
        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.RightShift then
            EngineState.RuntimeHotkey = input.KeyCode
            EngineState.ActivationMode = "Hotkey"
            EngineState.IsBinding = false
            SwitchLabel.Text = "[" .. input.KeyCode.Name .. "]"
            DiagKeyLabel.Text = "BIND REGISTER: [" .. input.KeyCode.Name .. "]"
            DiagKeyLabel.TextColor3 = Colors.TextSecondary
            StatusDot2.BackgroundColor3 = Colors.ActiveGlow
            UpdateUI()
        end
        return
    end
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        EngineState.ConfigVisible = not EngineState.ConfigVisible
        ConfigCanvas.Visible = EngineState.ConfigVisible
    end
    if EngineState.RuntimeHotkey and input.KeyCode == EngineState.RuntimeHotkey then
        if EngineState.ActivationMode == "Hotkey" then
            ToggleEngine()
            UpdateUI()
        end
    end
end)

ActionButton.MouseButton1Click:Connect(function()
    if EngineState.ActivationMode == "Manual Spam" then
        ToggleEngine()
        UpdateUI()
    end
end)

ModeBtn.MouseButton1Click:Connect(function()
    EngineState.ModeSelection = EngineState.ModeSelection == "KPS" and "CPS" or "KPS"
    ModeBtn.Text = EngineState.ModeSelection == "KPS" and "MODE: KPS" or "MODE: CPS"
    UpdateUI()
end)

ToggleTrack.MouseButton1Click:Connect(function()
    if EngineState.ActivationMode == "Manual Spam" then
        EngineState.IsBinding = true
        EngineState.ActivationMode = "Hotkey"
        SwitchLabel.Text = "PRESS KEY"
        AnimateSwitch(true)
        UpdateUI()
    else
        if EngineState.IsRunning then StopLoop() end
        EngineState.ActivationMode = "Manual Spam"
        EngineState.RuntimeHotkey = nil
        EngineState.IsBinding = false
        SwitchLabel.Text = "KEYBIND"
        DiagKeyLabel.Text = "BIND REGISTER: NONE"
        DiagKeyLabel.TextColor3 = Colors.TextMuted
        StatusDot2.BackgroundColor3 = Colors.TextMuted
        AnimateSwitch(false)
        UpdateUI()
    end
end)

ParryBtn.MouseButton1Click:Connect(function()
    EngineState.AutoParryActive = not EngineState.AutoParryActive
    if EngineState.AutoParryActive then
        ParryBtn.Text = "AUTO PARRY: ACTIVE"
        ParryBtn.TextColor3 = Colors.ActiveText
        ParryBtn.BackgroundColor3 = Colors.SurfaceOverlay
        DiagParryLabel.Text = "DEFENSE MATRIX: ACTIVE"
        DiagParryLabel.TextColor3 = Colors.ActiveText
        StatusDot3.BackgroundColor3 = Colors.ActiveGlow
        local activeBorder = ParryBtn:FindFirstChild("OuterBorder")
        if activeBorder then
            TweenService:Create(activeBorder, TweenInfo.new(0.3), {Color = Colors.ActiveGlow, Transparency = 0.3}):Play()
        end
        StartParryTracking()
    else
        ParryBtn.Text = "AUTO PARRY: DISABLED"
        ParryBtn.TextColor3 = Colors.TextMuted
        ParryBtn.BackgroundColor3 = Colors.Interactive
        DiagParryLabel.Text = "DEFENSE MATRIX: DISENGAGED"
        DiagParryLabel.TextColor3 = Colors.TextMuted
        StatusDot3.BackgroundColor3 = Colors.TextMuted
        local activeBorder = ParryBtn:FindFirstChild("OuterBorder")
        if activeBorder then
            TweenService:Create(activeBorder, TweenInfo.new(0.3), {Color = Colors.BorderMedium, Transparency = 0.2}):Play()
        end
        StopParryTracking()
    end
end)

PredictBtn.MouseButton1Click:Connect(function()
    EngineState.PredictiveParry = not EngineState.PredictiveParry
    if EngineState.PredictiveParry then
        PredictBtn.Text = "PREDICTIVE: ON"
        PredictBtn.TextColor3 = Colors.SuccessGreen
    else
        PredictBtn.Text = "PREDICTIVE: OFF"
        PredictBtn.TextColor3 = Colors.TextMuted
    end
end)

UpdateUI()
