-- =============================================================================
-- VAPORWAVE DECOUPLED REPOSITORY DASHBOARD (FINALIZED BUILD)
-- ASSET ID INTEGRATED: 138152502921929
-- =============================================================================

local uiName = "VaporwaveUI"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- 1. CLEANUP & SETUP
pcall(function() CoreGui:FindFirstChild(uiName):Destroy() end)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = uiName
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 500, 0, 360)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 12, 36)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- 2. COLLAPSIBLE LOGO (INTEGRATED ASSET ID)
local LogoIcon = Instance.new("ImageButton")
LogoIcon.Name = "LogoIcon"
LogoIcon.Size = UDim2.new(0, 40, 0, 40)
LogoIcon.Position = UDim2.new(0, 10, 0, 2)
LogoIcon.BackgroundTransparency = 1
LogoIcon.Image = "rbxassetid://138152502921929" 
LogoIcon.Parent = MainFrame

-- 3. UI WIDGET INITIALIZATION
local function CreateWidget(class, parent, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

-- Define major containers to toggle visibility
local UIWidgets = {
    ModeBtn = CreateWidget("TextButton", MainFrame, {Size = UDim2.new(0, 215, 0, 42), Position = UDim2.new(0.5, -107, 0.2, 0), Text = "MODE: KPS"}),
    SwitchContainer = CreateWidget("Frame", MainFrame, {Size = UDim2.new(0, 215, 0, 42), Position = UDim2.new(0.5, -107, 0.4, 0)}),
    SliderTrack = CreateWidget("Frame", MainFrame, {Size = UDim2.new(0, 340, 0, 6), Position = UDim2.new(0.5, -170, 0.6, 0)}),
    ParryBtn = CreateWidget("TextButton", MainFrame, {Size = UDim2.new(0, 460, 0, 40), Position = UDim2.new(0.5, -230, 0.75, 0), Text = "AUTO PARRY: DISABLED"}),
    DiagPanel = CreateWidget("Frame", MainFrame, {Size = UDim2.new(0, 460, 0, 80), Position = UDim2.new(0.5, -230, 0.85, 0)})
}

-- 4. COLLAPSE LOGIC (SMOOTH TWEENING)
local Collapsed = false
LogoIcon.MouseButton1Click:Connect(function()
    Collapsed = not Collapsed
    
    local targetSize = Collapsed and UDim2.new(0, 60, 0, 45) or UDim2.new(0, 500, 0, 360)
    TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = targetSize}):Play()
    
    -- Toggle visibility for all widgets
    for _, widget in pairs(UIWidgets) do
        widget.Visible = not Collapsed
    end
end)

-- [Insert your execution loop here to complete the script]
