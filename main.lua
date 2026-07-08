 -- =============================================================================

-- VAPORWAVE DECOUPLED REPOSITORY DASHBOARD (COLLAPSIBLE LOGO MODULE)

-- TARGET: Roblox Executor Environment (Zero-Allocation Micro-Loops)

-- THEME: Vaporwave (Deep Neon Purple & Electric Pink)

-- =============================================================================



local uiName = "VaporwaveUI"

local CoreGui = game:GetService("CoreGui")

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local TweenService = game:GetService("TweenService")

local VirtualInputManager = game:GetService("VirtualInputManager")

local UserInputService = game:GetService("UserInputService")

local RunService = game:GetService("RunService")



-- 1. PURGE PREVIOUS INSTANCES

pcall(function()

    local oldUI = CoreGui:FindFirstChild(uiName)

    if oldUI then oldUI:Destroy() end

end)

pcall(function()

    if LocalPlayer then

        local pGui = LocalPlayer:FindFirstChild("PlayerGui")

        local oldUI = pGui and pGui:FindFirstChild(uiName)

        if oldUI then oldUI:Destroy() end

    end

end)



-- 2. ALLOCATE SECURE STORAGE

local TargetParent = nil

local successCore = pcall(function()

    local test = Instance.new("Folder")

    test.Parent = CoreGui

    test:Destroy()

    TargetParent = CoreGui

end)

if not successCore or not TargetParent then

    TargetParent = LocalPlayer:WaitForChild("PlayerGui")

end



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

    ParryThreshold = 45, 

    SpamKey = Enum.KeyCode.F,

    ParryConnection = nil,

    ConfigVisible = true,

    Collapsed = false -- Track compact view state

}



-- 4. ULTRA-LOW LATENCY UPVALUE LOCALIZATION (ELIMINATES HEAP LOOKUPS)

local sendKeyEvent = VirtualInputManager.SendKeyEvent

local sendMouseButtonEvent = VirtualInputManager.SendMouseButtonEvent

local getMouseLocation = UserInputService.GetMouseLocation

local osClock = os.clock

local clamp = math.clamp

local round = math.round

local ipairs = ipairs



local MacroConnection = nil

local lastFireTime = 0



-- 5. OPTIMIZED STEPPING PIPELINE

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

    if MacroConnection then

        MacroConnection:Disconnect()

        MacroConnection = nil

    end

end



local function ToggleEngine()

    if EngineState.IsRunning then StopLoop() else StartLoop() end

end



-- 6. CACHED TARGETING SCANNER

local function FindActiveBall()

    local BallFolder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")

    if BallFolder then

        local children = BallFolder:GetChildren()

        for i = 1, #children do

            local ball = children[i]

            if ball:IsA("BasePart") or ball:FindFirstChildOfClass("BasePart") then

                local realPart = ball:IsA("BasePart") and ball or ball:FindFirstChildOfClass("BasePart")

                local targetAttr = ball:GetAttribute("target") or ball:GetAttribute("Target")

                if targetAttr == LocalPlayer.Name then

                    return realPart

                end

            end

        end

    end

    

    local workChildren = workspace:GetChildren()

    for i = 1, #workChildren do

        local obj = workChildren[i]

        if obj.Name == "Ball" and obj:IsA("BasePart") then

            if obj:GetAttribute("target") == LocalPlayer.Name then

                return obj

            end

        end

    end

    return nil

end



local function StartParryTracking()

    if EngineState.ParryConnection then EngineState.ParryConnection:Disconnect() end

    

    EngineState.ParryConnection = RunService.PreSimulation:Connect(function()

        if not EngineState.AutoParryActive then return end

        

        local character = LocalPlayer.Character

        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if not rootPart then return end

        

        local ball = FindActiveBall()

        if ball then

            local distance = (ball.Position - rootPart.Position).Magnitude

            local ballVelocity = ball.AssemblyLinearVelocity.Magnitude

            local dynamicTriggerRange = EngineState.ParryThreshold + (ballVelocity * 0.12)

            

            if distance <= dynamicTriggerRange then

                if EngineState.ModeSelection == "KPS" then

                    sendKeyEvent(VirtualInputManager, true, EngineState.SpamKey, false, game)

                    sendKeyEvent(VirtualInputManager, false, EngineState.SpamKey, false, game)

                else

                    local mousePos = getMouseLocation(UserInputService)

                    sendMouseButtonEvent(VirtualInputManager, mousePos.X, mousePos.Y, 0, true, game, 0)

                    sendMouseButtonEvent(VirtualInputManager, mousePos.X, mousePos.Y, 0, false, game, 0)

                end

            end

        end

    end)

end



local function StopParryTracking()

    if EngineState.ParryConnection then

        EngineState.ParryConnection:Disconnect()

        EngineState.ParryConnection = nil

    end

end



-- 7. INTERFACE ENVIRONMENT ARCHITECTURE (VAPORWAVE PURPLE/PINK RE-THEME)

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = uiName

ScreenGui.ResetOnSpawn = false

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ScreenGui.Parent = TargetParent



local ConfigCanvas = Instance.new("Frame")

ConfigCanvas.Name = "ConfigCanvas"

ConfigCanvas.Size = UDim2.new(1, 0, 1, 0)

ConfigCanvas.BackgroundTransparency = 1

ConfigCanvas.Visible = true

ConfigCanvas.Parent = ScreenGui



local function ApplyRadius(instance, radius)

    local corner = Instance.new("UICorner")

    corner.CornerRadius = UDim.new(0, radius)

    corner.Parent = instance

    return corner

end



local MainFrame = Instance.new("Frame")

MainFrame.Name = "MainFrame"

MainFrame.Size = UDim2.new(0, 500, 0, 360)

MainFrame.Position = UDim2.new(0.5, -250, 0.5, -210)

MainFrame.BackgroundColor3 = Color3.fromRGB(24, 12, 36) 

MainFrame.BorderSizePixel = 0

MainFrame.Active = true

MainFrame.Draggable = true

MainFrame.Parent = ConfigCanvas

ApplyRadius(MainFrame, 8)



local UIStroke = Instance.new("UIStroke")

UIStroke.Color = Color3.fromRGB(255, 0, 127) 

UIStroke.Thickness = 1

UIStroke.Transparency = 0.3

UIStroke.Parent = MainFrame



-- CONVERTED TO CLICKABLE TEXTBUTTON LOGO

local TitleLabel = Instance.new("TextButton")

TitleLabel.Name = "LogoButton"

TitleLabel.Size = UDim2.new(0, 160, 0, 40)

TitleLabel.Position = UDim2.new(0.5, -230, 0.5, -200)

TitleLabel.BackgroundTransparency = 1

TitleLabel.Text = "VAPORWAVE"

TitleLabel.TextColor3 = Color3.fromRGB(255, 100, 200) 

TitleLabel.Font = Enum.Font.Michroma

TitleLabel.TextSize = 16

TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

TitleLabel.ZIndex = 5

TitleLabel.Parent = ConfigCanvas



local ModeBtn = Instance.new("TextButton")

ModeBtn.Size = UDim2.new(0, 215, 0, 42)

ModeBtn.Position = UDim2.new(0.5, -230, 0.5, -150)

ModeBtn.BackgroundColor3 = Color3.fromRGB(44, 22, 64) 

ModeBtn.BorderSizePixel = 0

ModeBtn.Text = "MODE: KPS"

ModeBtn.TextColor3 = Color3.fromRGB(255, 200, 240)

ModeBtn.Font = Enum.Font.Michroma

ModeBtn.TextSize = 13

ModeBtn.ZIndex = 5

ModeBtn.Parent = ConfigCanvas

ApplyRadius(ModeBtn, 4)



local ModeStroke = Instance.new("UIStroke")

ModeStroke.Color = Color3.fromRGB(180, 0, 180)

ModeStroke.Thickness = 1

ModeStroke.Parent = ModeBtn



local SwitchContainer = Instance.new("Frame")

SwitchContainer.Size = UDim2.new(0, 215, 0, 42)

SwitchContainer.Position = UDim2.new(0.5, 15, 0.5, -150)

SwitchContainer.BackgroundColor3 = Color3.fromRGB(44, 22, 64)

SwitchContainer.BorderSizePixel = 0

SwitchContainer.ZIndex = 5

SwitchContainer.Parent = ConfigCanvas

ApplyRadius(SwitchContainer, 4)



local SwitchStroke = Instance.new("UIStroke")

SwitchStroke.Color = Color3.fromRGB(180, 0, 180)

SwitchStroke.Thickness = 1

SwitchStroke.Parent = SwitchContainer



local SwitchLabel = Instance.new("TextLabel")

SwitchLabel.Size = UDim2.new(0, 140, 1, 0)

SwitchLabel.Position = UDim2.new(0, 12, 0, 0)

SwitchLabel.BackgroundTransparency = 1

SwitchLabel.Text = "KEYBIND"

SwitchLabel.TextColor3 = Color3.fromRGB(255, 200, 240)

SwitchLabel.Font = Enum.Font.Michroma

SwitchLabel.TextSize = 12

SwitchLabel.TextXAlignment = Enum.TextXAlignment.Left

SwitchLabel.ZIndex = 6

SwitchLabel.Parent = SwitchContainer



local ToggleTrack = Instance.new("TextButton")

ToggleTrack.Size = UDim2.new(0, 46, 0, 26)

ToggleTrack.Position = UDim2.new(1, -56, 0.5, -13)

ToggleTrack.BackgroundColor3 = Color3.fromRGB(55, 45, 65) 

ToggleTrack.BorderSizePixel = 0

ToggleTrack.Text = ""

ToggleTrack.AutoButtonColor = false

ToggleTrack.ZIndex = 6

ToggleTrack.Parent = SwitchContainer

ApplyRadius(ToggleTrack, 13)



local ToggleThumb = Instance.new("Frame")

ToggleThumb.Size = UDim2.new(0, 22, 0, 22)

ToggleThumb.Position = UDim2.new(0, 2, 0.5, -11)

ToggleThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

ToggleThumb.BorderSizePixel = 0

ToggleThumb.ZIndex = 7

ToggleThumb.Parent = ToggleTrack

ApplyRadius(ToggleThumb, 11)



local SliderTrack = Instance.new("Frame")

SliderTrack.Size = UDim2.new(0, 340, 0, 6)

SliderTrack.Position = UDim2.new(0.5, -230, 0.5, -85)

SliderTrack.BackgroundColor3 = Color3.fromRGB(60, 30, 90) 

SliderTrack.BorderSizePixel = 0

SliderTrack.ZIndex = 5

SliderTrack.Parent = ConfigCanvas

ApplyRadius(SliderTrack, 3)



local SliderFill = Instance.new("Frame")

SliderFill.Size = UDim2.new(0.01, 0, 1, 0)

SliderFill.BackgroundColor3 = Color3.fromRGB(255, 0, 127) 

SliderFill.BorderSizePixel = 0

SliderFill.ZIndex = 6

SliderFill.Parent = SliderTrack

ApplyRadius(SliderFill, 3)



local SliderButton = Instance.new("TextButton")

SliderButton.Size = UDim2.new(0, 14, 0, 14)

SliderButton.Position = UDim2.new(0.01, -7, 0.5, -7)

SliderButton.BackgroundColor3 = Color3.fromRGB(255, 150, 220)

SliderButton.BorderSizePixel = 0

SliderButton.Text = ""

SliderButton.ZIndex = 7

SliderButton.Parent = SliderTrack

ApplyRadius(SliderButton, 7)



local SpeedDisplay = Instance.new("TextLabel")

SpeedDisplay.Size = UDim2.new(0, 120, 0, 30)

SpeedDisplay.Position = UDim2.new(0.5, 110, 0.5, -97)

SpeedDisplay.BackgroundTransparency = 1

SpeedDisplay.Text = "10 KPS"

SpeedDisplay.TextColor3 = Color3.fromRGB(255, 0, 127)

SpeedDisplay.Font = Enum.Font.Michroma

SpeedDisplay.TextSize = 14

SpeedDisplay.TextXAlignment = Enum.TextXAlignment.Right

SpeedDisplay.ZIndex = 5

SpeedDisplay.Parent = ConfigCanvas



local ParryBtn = Instance.new("TextButton")

ParryBtn.Size = UDim2.new(0, 460, 0, 40)

ParryBtn.Position = UDim2.new(0.5, -230, 0.5, -55)

ParryBtn.BackgroundColor3 = Color3.fromRGB(44, 22, 64)

ParryBtn.BorderSizePixel = 0

ParryBtn.Text = "AUTO PARRY: DISABLED"

ParryBtn.TextColor3 = Color3.fromRGB(180, 0, 180)

ParryBtn.Font = Enum.Font.Michroma

ParryBtn.TextSize = 14

ParryBtn.ZIndex = 5

ParryBtn.Parent = ConfigCanvas

ApplyRadius(ParryBtn, 4)



local ParryStroke = Instance.new("UIStroke")

ParryStroke.Color = Color3.fromRGB(180, 0, 180)

ParryStroke.Thickness = 1

ParryStroke.Parent = ParryBtn



local DiagPanel = Instance.new("Frame")

DiagPanel.Name = "DiagPanel"

DiagPanel.Size = UDim2.new(0, 460, 0, 110)

DiagPanel.Position = UDim2.new(0.5, -230, 0.5, 5)

DiagPanel.BackgroundColor3 = Color3.fromRGB(34, 17, 51)

DiagPanel.BorderSizePixel = 0

DiagPanel.ZIndex = 4

DiagPanel.Parent = ConfigCanvas

ApplyRadius(DiagPanel, 4)



local DiagStroke = Instance.new("UIStroke")

DiagStroke.Color = Color3.fromRGB(130, 0, 130)

DiagStroke.Thickness = 1

DiagStroke.Parent = DiagPanel



local DiagHeader = Instance.new("TextLabel")

DiagHeader.Size = UDim2.new(1, -20, 0, 25)

DiagHeader.Position = UDim2.new(0, 15, 0, 8)

DiagHeader.BackgroundTransparency = 1

DiagHeader.Text = "SYSTEM LOGS"

DiagHeader.TextColor3 = Color3.fromRGB(240, 180, 255)

DiagHeader.Font = Enum.Font.Michroma

DiagHeader.TextSize = 12

DiagHeader.TextXAlignment = Enum.TextXAlignment.Left

DiagHeader.ZIndex = 5

DiagHeader.Parent = DiagPanel



local DiagMacroLabel = Instance.new("TextLabel")

DiagMacroLabel.Size = UDim2.new(1, -30, 0, 20)

DiagMacroLabel.Position = UDim2.new(0, 15, 0, 35)

DiagMacroLabel.BackgroundTransparency = 1

DiagMacroLabel.Text = "STATUS: STANDBY"

DiagMacroLabel.TextColor3 = Color3.fromRGB(160, 120, 180)

DiagMacroLabel.Font = Enum.Font.Michroma

DiagMacroLabel.TextSize = 11

DiagMacroLabel.TextXAlignment = Enum.TextXAlignment.Left

DiagMacroLabel.ZIndex = 5

DiagMacroLabel.Parent = DiagPanel



local DiagKeyLabel = Instance.new("TextLabel")

DiagKeyLabel.Size = UDim2.new(1, -30, 0, 20)

DiagKeyLabel.Position = UDim2.new(0, 15, 0, 55)

DiagKeyLabel.BackgroundTransparency = 1

DiagKeyLabel.Text = "BIND REGISTER: NONE"

DiagKeyLabel.TextColor3 = Color3.fromRGB(160, 120, 180)

DiagKeyLabel.Font = Enum.Font.Michroma

DiagKeyLabel.TextSize = 11

DiagKeyLabel.TextXAlignment = Enum.TextXAlignment.Left

DiagKeyLabel.ZIndex = 5

DiagKeyLabel.Parent = DiagPanel



local DiagParryLabel = Instance.new("TextLabel")

DiagParryLabel.Size = UDim2.new(1, -30, 0, 20)

DiagParryLabel.Position = UDim2.new(0, 15, 0, 75)

DiagParryLabel.BackgroundTransparency = 1

DiagParryLabel.Text = "DEFENSE MATRIX: DISENGAGED"

DiagParryLabel.TextColor3 = Color3.fromRGB(160, 120, 180)

DiagParryLabel.Font = Enum.Font.Michroma

DiagParryLabel.TextSize = 11

DiagParryLabel.TextXAlignment = Enum.TextXAlignment.Left

DiagParryLabel.ZIndex = 5

DiagParryLabel.Parent = DiagPanel



local ControlPod = Instance.new("Frame")

ControlPod.Name = "ControlPod"

ControlPod.Size = UDim2.new(0, 260, 0, 75)

ControlPod.Position = UDim2.new(0.5, -130, 0.5, 160)

ControlPod.BackgroundColor3 = Color3.fromRGB(24, 12, 36)

ControlPod.BorderSizePixel = 0

ControlPod.Active = true

ControlPod.Draggable = true

ControlPod.Parent = ScreenGui 

ApplyRadius(ControlPod, 6)



local PodStroke = Instance.new("UIStroke")

PodStroke.Color = Color3.fromRGB(255, 0, 127)

PodStroke.Thickness = 1

PodStroke.Transparency = 0.3

PodStroke.Parent = ControlPod



local ActionButton = Instance.new("TextButton")

ActionButton.Name = "ActionButton"

ActionButton.Size = UDim2.new(0, 230, 0, 36)

ActionButton.Position = UDim2.new(0.5, -115, 0.5, 175)

ActionButton.BackgroundColor3 = Color3.fromRGB(180, 0, 180)

ActionButton.BorderSizePixel = 0

ActionButton.Text = "ACTIVATE"

ActionButton.TextColor3 = Color3.fromRGB(255, 255, 255)

ActionButton.Font = Enum.Font.Michroma

ActionButton.TextSize = 15

ActionButton.AutoButtonColor = false

ActionButton.ZIndex = 5

ActionButton.Parent = ScreenGui 

ApplyRadius(ActionButton, 4)



local StatusBar = Instance.new("TextLabel")

StatusBar.Size = UDim2.new(0, 230, 0, 18)

StatusBar.Position = UDim2.new(0.5, -115, 0.5, 213)

StatusBar.BackgroundTransparency = 1

StatusBar.Text = "WORKFLOW IDLE"

StatusBar.TextColor3 = Color3.fromRGB(160, 120, 180)

StatusBar.Font = Enum.Font.Michroma

StatusBar.TextSize = 10

StatusBar.ZIndex = 5

StatusBar.Parent = ScreenGui



-- 8. SIGNAL HANDLING ENVIRONMENT

local function UpdateUI()

    local labelMode = EngineState.ModeSelection == "KPS" and "KPS" or "CPS"

    SpeedDisplay.Text = string.format("%d %s", EngineState.TargetSpeed, labelMode)

    

    local manualMode = EngineState.ActivationMode == "Manual Spam"

    ControlPod.Visible = manualMode

    ActionButton.Visible = manualMode

    StatusBar.Visible = manualMode

    

    if EngineState.IsRunning then

        StatusBar.Text = "MACRO FIRING"

        StatusBar.TextColor3 = Color3.fromRGB(255, 0, 127)

        ActionButton.Text = "HALT CORE"

        ActionButton.BackgroundColor3 = Color3.fromRGB(120, 10, 80) 

        DiagMacroLabel.Text = "STATUS: RUNNING CORE"

        DiagMacroLabel.TextColor3 = Color3.fromRGB(255, 0, 127)

    else

        StatusBar.Text = "WORKFLOW IDLE"

        StatusBar.TextColor3 = Color3.fromRGB(160, 120, 180)

        ActionButton.Text = "ACTIVATE"

        ActionButton.BackgroundColor3 = Color3.fromRGB(180, 0, 180)

        DiagMacroLabel.Text = "STATUS: STANDBY"

        DiagMacroLabel.TextColor3 = Color3.fromRGB(160, 120, 180)

    end

end



-- LOGO CLICKS DEPLOYMENT (COLLAPSIBLE ENGINE LOGIC)

TitleLabel.MouseButton1Click:Connect(function()

    EngineState.Collapsed = not EngineState.Collapsed

    

    if EngineState.Collapsed then

        -- Collapse window chassis boundary to title segment only

        MainFrame.Size = UDim2.new(0, 180, 0, 42)

        ModeBtn.Visible = false

        SwitchContainer.Visible = false

        SliderTrack.Visible = false

        SpeedDisplay.Visible = false

        ParryBtn.Visible = false

        DiagPanel.Visible = false

    else

        -- Expand chassis configuration space back to full dashboard size

        MainFrame.Size = UDim2.new(0, 500, 0, 360)

        ModeBtn.Visible = true

        SwitchContainer.Visible = true

        SliderTrack.Visible = true

        SpeedDisplay.Visible = true

        ParryBtn.Visible = true

        DiagPanel.Visible = true

    end

    UpdateUI() -- Recalculate pod dynamics based on target state

end)



local function AnimateSwitch(isOn)

    local targetPos = isOn and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)

    local targetColor = isOn and Color3.fromRGB(255, 0, 127) or Color3.fromRGB(55, 45, 65)

    

    TweenService:Create(ToggleThumb, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()

    TweenService:Create(ToggleTrack, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()

end



local IsDragging = false



local function UpdateSlider(inputObj)

    local fraction = clamp((inputObj.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)

    local maxLimit = EngineState.LowEndMode and 200 or 2500

    local calculated = round(1 + (fraction * (maxLimit - 1)))

    

    EngineState.TargetSpeed = calculated

    SliderFill.Size = UDim2.new(fraction, 0, 1, 0)

    SliderButton.Position = UDim2.new(fraction, -7, 0.5, -7)

    UpdateUI()

end



SliderButton.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then

        IsDragging = true

    end

end)



UserInputService.InputChanged:Connect(function(input)

    if IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then

        UpdateSlider(input)

    end

end)



UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then

        IsDragging = false

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



BindChassisPosition(MainFrame, {TitleLabel, ModeBtn, SwitchContainer, SliderTrack, SpeedDisplay, ParryBtn, DiagPanel})

BindChassisPosition(ControlPod, {ActionButton, StatusBar})



UserInputService.InputBegan:Connect(function(input, gameProcessed)

    if EngineState.IsBinding then

        if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.RightShift then

            EngineState.RuntimeHotkey = input.KeyCode

            EngineState.ActivationMode = "Hotkey"

            EngineState.IsBinding = false

            SwitchLabel.Text = "[" .. input.KeyCode.Name .. "]"

            DiagKeyLabel.Text = "BIND REGISTER: [" .. input.KeyCode.Name .. "]"

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

        AnimateSwitch(false)

        UpdateUI()

    end

end)



getgenv().ThyrenLowEndMode = function()

    EngineState.LowEndMode = not EngineState.LowEndMode

    if EngineState.LowEndMode and EngineState.TargetSpeed > 200 then 

        EngineState.TargetSpeed = 200 

    end

    local maxLimit = EngineState.LowEndMode and 200 or 2500

    local scale = clamp((EngineState.TargetSpeed - 1) / (maxLimit - 1), 0, 1)

    SliderFill.Size = UDim2.new(scale, 0, 1, 0)

    SliderButton.Position = UDim2.new(scale, -7, 0.5, -7)

    UpdateUI()

end



ParryBtn.MouseButton1Click:Connect(function()

    EngineState.AutoParryActive = not EngineState.AutoParryActive

    if EngineState.AutoParryActive then

        ParryBtn.Text = "AUTO PARRY: ACTIVE"

        ParryBtn.TextColor3 = Color3.fromRGB(255, 0, 127)

        DiagParryLabel.Text = "DEFENSE MATRIX: ACTIVE"

        DiagParryLabel.TextColor3 = Color3.fromRGB(255, 0, 127)

        StartParryTracking()

    else

        ParryBtn.Text = "AUTO PARRY: DISABLED"

        ParryBtn.TextColor3 = Color3.fromRGB(180, 0, 180)

        DiagParryLabel.Text = "DEFENSE MATRIX: DISENGAGED"

        DiagParryLabel.TextColor3 = Color3.fromRGB(160, 120, 180)

        StopParryTracking()

    end

end)



UpdateUI() 
