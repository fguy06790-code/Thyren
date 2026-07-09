-- =============================================================================
-- THYREN ULTIMATE (PART 1 OF 2)
-- THEME: Slate & Graphite Ultra-Clean
-- COMPATIBILITY: PC & Mobile (Delta, Hydrogen, Fluxus, Wave, Solara)
-- SECURITY: Raw Input Emulation (Undetectable)
-- =============================================================================

local uiName = "ThyrenUltra_Universal_V2"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- [[ 1. PURGE PREVIOUS ]]
pcall(function() if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end end)

-- [[ 2. CORE ENGINE STATE ]]
local EngineState = { 
    IsRunning = false, 
    TargetSpeed = 10, 
    InputMode = "Button", -- "Button" or "Click"
    AutoParryActive = false, 
    ParryThreshold = 45, 
    SpamKey = Enum.KeyCode.F,
    LastFireTime = 0, 
    KeyValidated = false
}

local sendKeyEvent = VirtualInputManager.SendKeyEvent
local sendMouseButtonEvent = VirtualInputManager.SendMouseButtonEvent
local getMouseLocation = UserInputService.GetMouseLocation
local osClock = os.clock
local MacroConnection = nil

-- [[ 3. MACRO CORE ]]
local function ExecuteRawInput()
    if not EngineState.IsRunning then return end
    local targetSpeed = EngineState.TargetSpeed; local mode = EngineState.InputMode
    if targetSpeed >= 60 then
        if mode == "Button" then
            sendKeyEvent(VirtualInputManager, true, EngineState.SpamKey, false, game)
            sendKeyEvent(VirtualInputManager, false, EngineState.SpamKey, false, game)
        else
            local ml = getMouseLocation(UserInputService)
            sendMouseButtonEvent(VirtualInputManager, ml.X, ml.Y, 0, true, game, 0)
            sendMouseButtonEvent(VirtualInputManager, ml.X, ml.Y, 0, false, game, 0)
        end
    else
        local currentTime = osClock()
        if (currentTime - EngineState.LastFireTime) >= (1.0 / targetSpeed) then
            EngineState.LastFireTime = currentTime
            if mode == "Button" then
                sendKeyEvent(VirtualInputManager, true, EngineState.SpamKey, false, game)
                sendKeyEvent(VirtualInputManager, false, EngineState.SpamKey, false, game)
            else
                local ml = getMouseLocation(UserInputService)
                sendMouseButtonEvent(VirtualInputManager, ml.X, ml.Y, 0, true, game, 0)
                sendMouseButtonEvent(VirtualInputManager, ml.X, ml.Y, 0, false, game, 0)
            end
        end
    end
end

-- [[ 4. UNIVERSAL PARRY SCANNER ]]
local function FindActiveBall()
    local BallFolder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")
    if BallFolder then 
        local children = BallFolder:GetChildren()
        for i = 1, #children do 
            local ball = children[i]
            if ball:IsA("BasePart") or ball:FindFirstChildOfClass("BasePart") then 
                local target = ball:GetAttribute("target") or ball:GetAttribute("Target")
                if target == LocalPlayer.Name then return ball:IsA("BasePart") and ball or ball:FindFirstChildOfClass("BasePart") end 
            end 
        end 
    end
    return nil
end

local function StartParryTracking()
    if EngineState.ParryConnection then EngineState.ParryConnection:Disconnect() end
    EngineState.ParryConnection = RunService.PreSimulation:Connect(function()
        if not EngineState.AutoParryActive then return end
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local ball = FindActiveBall()
        if ball then 
            local distance = (ball.Position - rootPart.Position).Magnitude
            local ballVelocity = ball.AssemblyLinearVelocity.Magnitude
            local triggerRange = EngineState.ParryThreshold + (ballVelocity * 0.12)
            if distance <= triggerRange then 
                if EngineState.InputMode == "Button" then 
                    sendKeyEvent(VirtualInputManager, true, EngineState.SpamKey, false, game)
                    sendKeyEvent(VirtualInputManager, false, EngineState.SpamKey, false, game)
                else 
                    local ml = getMouseLocation(UserInputService)
                    sendMouseButtonEvent(VirtualInputManager, ml.X, ml.Y, 0, true, game, 0)
                    sendMouseButtonEvent(VirtualInputManager, ml.X, ml.Y, 0, false, game, 0)
                end 
            end
        end
    end)
end
-- =============================================================================
-- THYREN ULTIMATE (PART 2 OF 2)
-- =============================================================================

-- [[ 5. DYNAMIC KEY CHECK ]]
local function IsKeyValid(input)
    return string.sub(input, 1, 4) == "THY-" and string.sub(input, -4) == "2026" and #input == 14
end

-- [[ 6. UI CONSTRUCTION ]]
local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = uiName

-- MOBILE DRAG UTILITY
local function MakeDraggable(obj)
    local dragToggle, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragToggle = true; dragStart = input.Position; startPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragToggle = false end
            end)
        end
    end)
    obj.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragToggle then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- AUTH OVERLAY
local AuthFrame = Instance.new("Frame", ScreenGui)
AuthFrame.Size = UDim2.new(0, 300, 0, 160); AuthFrame.Position = UDim2.new(0.5, -150, 0.5, -80); AuthFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
Instance.new("UICorner", AuthFrame).CornerRadius = UDim.new(0, 12)
local KeyInput = Instance.new("TextBox", AuthFrame); KeyInput.Size = UDim2.new(0, 240, 0, 35); KeyInput.Position = UDim2.new(0.5, -120, 0.35, -17); KeyInput.BackgroundColor3 = Color3.fromRGB(20, 20, 22); KeyInput.TextColor3 = Color3.fromRGB(200, 200, 210); KeyInput.PlaceholderText = "Key: THY-XXXXX-2026"; KeyInput.Text = ""; KeyInput.Font = Enum.Font.Code
local SubmitBtn = Instance.new("TextButton", AuthFrame); SubmitBtn.Size = UDim2.new(0, 240, 0, 35); SubmitBtn.Position = UDim2.new(0.5, -120, 0.75, -17); SubmitBtn.BackgroundColor3 = Color3.fromRGB(130, 130, 145); SubmitBtn.Text = "INITIALIZE"; SubmitBtn.TextColor3 = Color3.fromRGB(20, 20, 25); SubmitBtn.Font = Enum.Font.Michroma

-- SEPARATE FLOATING ACTIVATE BUTTON
local ActivateBtn = Instance.new("TextButton", ScreenGui)
ActivateBtn.Size = UDim2.new(0, 140, 0, 50); ActivateBtn.Position = UDim2.new(0.5, -70, 0.8, 0); ActivateBtn.BackgroundColor3 = Color3.fromRGB(130, 130, 145); ActivateBtn.Text = "ACTIVATE"; ActivateBtn.TextColor3 = Color3.fromRGB(20, 20, 25); ActivateBtn.Font = Enum.Font.Michroma; ActivateBtn.Visible = false; ActivateBtn.ZIndex = 5
Instance.new("UICorner", ActivateBtn).CornerRadius = UDim.new(0, 12); MakeDraggable(ActivateBtn)

-- DASHBOARD CANVAS
local MainCanvas = Instance.new("CanvasGroup", ScreenGui); MainCanvas.Size = UDim2.new(1, 0, 1, 0); MainCanvas.GroupTransparency = 1; MainCanvas.BackgroundTransparency = 1; MainCanvas.Visible = false
local MainFrame = Instance.new("Frame", MainCanvas); MainFrame.Size = UDim2.new(0, 420, 0, 320); MainFrame.Position = UDim2.new(0.5, -210, 0.5, -160); MainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 32); MakeDraggable(MainFrame)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

-- iOS STYLE SWITCH
local SwitchFrame = Instance.new("Frame", MainFrame); SwitchFrame.Size = UDim2.new(0, 50, 0, 28); SwitchFrame.Position = UDim2.new(0.8, -25, 0.15, 0); SwitchFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 60); Instance.new("UICorner", SwitchFrame).CornerRadius = UDim.new(1, 0)
local SwitchThumb = Instance.new("Frame", SwitchFrame); SwitchThumb.Size = UDim2.new(0, 24, 0, 24); SwitchThumb.Position = UDim2.new(0, 2, 0.5, -12); SwitchThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Instance.new("UICorner", SwitchThumb).CornerRadius = UDim.new(1, 0)
local SwitchBtn = Instance.new("TextButton", SwitchFrame); SwitchBtn.Size = UDim2.new(1, 0, 1, 0); SwitchBtn.BackgroundTransparency = 1; SwitchBtn.Text = ""

-- 2,500 KPS SLIDER
local SliderFrame = Instance.new("Frame", MainFrame); SliderFrame.Size = UDim2.new(0, 350, 0, 30); SliderFrame.Position = UDim2.new(0.5, -175, 0.45, 0); SliderFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
local SliderFill = Instance.new("Frame", SliderFrame); SliderFill.Size = UDim2.new(0.01, 0, 1, 0); SliderFill.BackgroundColor3 = Color3.fromRGB(130, 130, 145)
local SliderHandle = Instance.new("TextButton", SliderFrame); SliderHandle.Size = UDim2.new(0, 15, 1, 0); SliderHandle.Position = UDim2.new(0.01, -7, 0, 0); SliderHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255); SliderHandle.Text = ""
local SpeedDisplay = Instance.new("TextLabel", MainFrame); SpeedDisplay.Size = UDim2.new(0, 200, 0, 20); SpeedDisplay.Position = UDim2.new(0.5, -100, 0.35, 0); SpeedDisplay.Text = "10 KPS"; SpeedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255); SpeedDisplay.BackgroundTransparency = 1; SpeedDisplay.Font = Enum.Font.Michroma

-- [[ 7. UPDATE UI & SIGNALS ]]
local function UpdateUI()
    SpeedDisplay.Text = EngineState.TargetSpeed .. " KPS"
    ActivateBtn.Text = EngineState.IsRunning and "HALT" or "ACTIVATE"
    local isOn = (EngineState.InputMode == "Click")
    TweenService:Create(SwitchThumb, TweenInfo.new(0.2), {Position = isOn and UDim2.new(1, -26, 0.5, -12) or UDim2.new(0, 2, 0.5, -12)}):Play()
    TweenService:Create(SwitchFrame, TweenInfo.new(0.2), {BackgroundColor3 = isOn and Color3.fromRGB(75, 215, 100) or Color3.fromRGB(55, 55, 60)}):Play()
end

local dragging = false
SliderHandle.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local inputPos = i.Position.X; local frac = math.clamp((inputPos - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
        EngineState.TargetSpeed = math.round(1 + (frac * 2499))
        SliderFill.Size = UDim2.new(frac, 0, 1, 0); SliderHandle.Position = UDim2.new(frac, -7, 0, 0)
        UpdateUI()
    end
end)

SwitchBtn.MouseButton1Click:Connect(function() EngineState.InputMode = (EngineState.InputMode == "Click") and "Button" or "Click"; UpdateUI() end)
ActivateBtn.MouseButton1Click:Connect(function() 
    EngineState.IsRunning = not EngineState.IsRunning; UpdateUI()
    if EngineState.IsRunning then MacroConnection = RunService.PreRender:Connect(ExecuteRawInput) elseif MacroConnection then MacroConnection:Disconnect() end
end)

SubmitBtn.MouseButton1Click:Connect(function()
    if IsKeyValid(KeyInput.Text) then
        TweenService:Create(AuthFrame, TweenInfo.new(0.6), {BackgroundTransparency = 1, GroupTransparency = 1}):Play()
        task.delay(0.6, function() AuthFrame.Visible = false; MainCanvas.Visible = true; ActivateBtn.Visible = true; TweenService:Create(MainCanvas, TweenInfo.new(1), {GroupTransparency = 0}):Play(); StartParryTracking(); UpdateUI() end)
    end
end)
