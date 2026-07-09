-- =============================================================================
-- THYREN UI v2.0 - [OPTIMIZED & ALIGNED]
-- =============================================================================

local uiName = "ThyrenUI"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Utility: Modern Draggable
local function MakeDraggable(gui)
    local dragging, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = gui.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- Engine State
local EngineState = { IsRunning = false, TargetSpeed = 10, ModeSelection = "KPS", IsBinding = false, SpamKey = Enum.KeyCode.F, AutoParryActive = false, ParryThreshold = 45 }
local lastFireTime = 0
local MacroConnection = nil

-- Core Loop
local function RunSpamIteration()
    if not EngineState.IsRunning then return end
    local now = os.clock()
    if (now - lastFireTime) >= (1.0 / EngineState.TargetSpeed) then
        lastFireTime = now
        if EngineState.ModeSelection == "KPS" then
            VirtualInputManager:SendKeyEvent(true, EngineState.SpamKey, false, game)
            VirtualInputManager:SendKeyEvent(false, EngineState.SpamKey, false, game)
        else
            local mp = UserInputService:GetMouseLocation()
            VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 0)
        end
    end
end

local function ToggleEngine()
    EngineState.IsRunning = not EngineState.IsRunning
    if EngineState.IsRunning then
        lastFireTime = os.clock()
        MacroConnection = RunService.PreRender:Connect(RunSpamIteration)
    else
        if MacroConnection then MacroConnection:Disconnect() end
    end
end

-- Colors & UI Helpers
local Colors = { Background = Color3.fromRGB(22, 22, 24), Surface = Color3.fromRGB(28, 28, 32), Interactive = Color3.fromRGB(52, 52, 60), Text = Color3.fromRGB(235, 235, 245), Accent = Color3.fromRGB(150, 150, 170) }
local function ApplyRadius(i, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = i; return c end

-- Screen Init
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = uiName
ScreenGui.DisplayOrder = 999
local ConfigCanvas = Instance.new("Frame", ScreenGui); ConfigCanvas.Size = UDim2.new(1,0,1,0); ConfigCanvas.BackgroundTransparency = 1

-- =============================================================================
-- THYREN UI v2.0 - [PART 2: INTERFACE & LOGIC]
-- =============================================================================

-- Main Panel
local MainFrame = Instance.new("Frame", ConfigCanvas)
MainFrame.Size = UDim2.new(0, 480, 0, 320)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
MainFrame.BackgroundColor3 = Colors.Surface
MainFrame.Active = true
ApplyRadius(MainFrame, 10)
MakeDraggable(MainFrame)

-- Title
local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "THYREN DASHBOARD"; Title.Font = Enum.Font.Michroma; Title.TextSize = 16
Title.TextColor3 = Colors.Text; Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1

-- Mode Button (KPS/CPS)
local ModeBtn = Instance.new("TextButton", MainFrame)
ModeBtn.Size = UDim2.new(0, 140, 0, 40); ModeBtn.Position = UDim2.new(0, 20, 0, 50)
ModeBtn.BackgroundColor3 = Colors.Interactive; ModeBtn.Text = "MODE: KPS"
ModeBtn.TextColor3 = Colors.Text; ModeBtn.Font = Enum.Font.Michroma; ApplyRadius(ModeBtn, 6)

-- Keybind Button (Click to Bind)
local BindBtn = Instance.new("TextButton", MainFrame)
BindBtn.Size = UDim2.new(0, 140, 0, 40); BindBtn.Position = UDim2.new(0, 170, 0, 50)
BindBtn.BackgroundColor3 = Colors.Interactive; BindBtn.Text = "BIND: " .. EngineState.SpamKey.Name
BindBtn.TextColor3 = Colors.Text; BindBtn.Font = Enum.Font.Michroma; ApplyRadius(BindBtn, 6)

-- Speed Slider
local SliderTrack = Instance.new("Frame", MainFrame)
SliderTrack.Size = UDim2.new(0, 440, 0, 10); SliderTrack.Position = UDim2.new(0, 20, 0, 120)
SliderTrack.BackgroundColor3 = Colors.Interactive; ApplyRadius(SliderTrack, 5)

local SliderFill = Instance.new("Frame", SliderTrack)
SliderFill.Size = UDim2.new(0.2, 0, 1, 0); SliderFill.BackgroundColor3 = Colors.Accent; ApplyRadius(SliderFill, 5)

local SpeedDisplay = Instance.new("TextLabel", MainFrame)
SpeedDisplay.Size = UDim2.new(0, 100, 0, 30); SpeedDisplay.Position = UDim2.new(0, 360, 0, 100)
SpeedDisplay.BackgroundTransparency = 1; SpeedDisplay.Text = "10 KPS"
SpeedDisplay.TextColor3 = Colors.Accent; SpeedDisplay.Font = Enum.Font.Michroma

-- Logic for Slider/Binding
BindBtn.MouseButton1Click:Connect(function()
    EngineState.IsBinding = true
    BindBtn.Text = "PRESS A KEY..."
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    -- Handle Binding
    if EngineState.IsBinding then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            EngineState.SpamKey = input.KeyCode
            EngineState.IsBinding = false
            BindBtn.Text = "BIND: " .. input.KeyCode.Name
        end
        return
    end
    -- Handle Toggle
    if input.KeyCode == EngineState.SpamKey and not EngineState.IsRunning then
        -- Optional: Add hotkey toggle here
    end
end)

-- Slider Drag
local draggingSlider = false
SliderTrack.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = true end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        local relative = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        EngineState.TargetSpeed = math.floor(relative * 100)
        SliderFill.Size = UDim2.new(relative, 0, 1, 0)
        SpeedDisplay.Text = EngineState.TargetSpeed .. " " .. EngineState.ModeSelection
    end
end)

-- Toggle Mode (KPS/CPS)
ModeBtn.MouseButton1Click:Connect(function()
    EngineState.ModeSelection = (EngineState.ModeSelection == "KPS" and "CPS" or "KPS")
    ModeBtn.Text = "MODE: " .. EngineState.ModeSelection
    SpeedDisplay.Text = EngineState.TargetSpeed .. " " .. EngineState.ModeSelection
end)

-- Finalize
print("Thyren UI Initialized.")
