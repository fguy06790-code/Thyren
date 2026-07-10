-- =============================================================================
-- THYREN PRO ELITE (PART 1 OF 2) - KERNEL-LEVEL STEALTH ENGINE
-- =============================================================================

local uiName = "Thyren_Pro_Replica_V12"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

pcall(function() if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end end)

local EngineState = { 
    TargetSpeed = 10, 
    InputMode = "Button",
    AutoParryActive = true, 
    ParryThreshold = 45, 
    ActionKey = Enum.KeyCode.F,
    ToggleKey = Enum.KeyCode.F9, 
    LastFireTime = 0, 
    MacroToggle = false
}

local _VIM = VirtualInputManager
local _send = _VIM.SendKeyEvent
local _clock = os.clock
local _wait = task.wait

-- [[ PRECISION STEALTH MACRO ENGINE ]]
local function ExecuteStealthInput()
    if not EngineState.MacroToggle then return end
    local targetKPS = EngineState.TargetSpeed
    local currentTime = _clock()
    local baseDelay = (1.0 / targetKPS)
    
    if (currentTime - EngineState.LastFireTime) >= baseDelay then
        EngineState.LastFireTime = currentTime
        _send(_VIM, true, EngineState.ActionKey, false, game)
        local holdTime = math.min(0.0005, (1.0 / targetKPS) * 0.4)
        _wait(holdTime) 
        _send(_VIM, false, EngineState.ActionKey, false, game)
    end
end

-- [[ ZERO-COOLDOWN AUTO-PARRY ]]
_G.StartParry = function()
    RunService.PreSimulation:Connect(function()
        if not EngineState.AutoParryActive then return end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local ball = (function()
            local folder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")
            if folder then 
                for _, b in ipairs(folder:GetChildren()) do
                    local t = b:GetAttribute("target") or b:GetAttribute("Target")
                    if t == LocalPlayer.Name then return b:IsA("BasePart") and b or b:FindFirstChildOfClass("BasePart") end 
                end 
            end
            return nil
        end)()
        
        if root and ball then 
            local dist = (ball.Position - root.Position).Magnitude
            local vel = ball.AssemblyLinearVelocity.Magnitude
            if dist <= (EngineState.ParryThreshold + (vel * 0.13)) then 
                _send(_VIM, true, EngineState.ActionKey, false, game)
                _send(_VIM, false, EngineState.ActionKey, false, game)
            end
        end
    end)
end
-- =============================================================================
-- THYREN PRO ELITE (PART 2 OF 2) - 1:1 TAB REPLICA (3e5266 & 8805c)
-- =============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = uiName
ScreenGui.IgnoreGuiInset = true

local function MakeDraggable(obj)
    local dragToggle, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragToggle = true; dragStart = input.Position; startPos = obj.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end)
        end
    end)
    obj.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragToggle then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- [[ MAIN CONTAINER ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 560, 0, 320); Main.Position = UDim2.new(0.5, -280, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(75, 75, 75); Main.BorderSizePixel = 0; Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 24)
MakeDraggable(Main)

-- [[ SIDEBAR REPLICA ]]
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 165, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(48, 48, 48); Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 24)

-- SIDEBAR HEADERS (1:1 SIZE)
local Header = Instance.new("TextLabel", Sidebar); Header.Size = UDim2.new(1, 0, 0, 40); Header.Text = "THYREN"; Header.TextColor3 = Color3.fromRGB(0, 0, 0); Header.BackgroundTransparency = 1; Header.Font = Enum.Font.Michroma; Header.TextSize = 32; Header.Position = UDim2.new(0,0,0,25)
local SubHeader = Instance.new("TextLabel", Sidebar); SubHeader.Size = UDim2.new(1, 0, 0, 40); SubHeader.Text = "PRO"; SubHeader.TextColor3 = Color3.fromRGB(0, 0, 0); SubHeader.BackgroundTransparency = 1; SubHeader.Font = Enum.Font.Michroma; SubHeader.TextSize = 28; SubHeader.Position = UDim2.new(0,0,0,75)

local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -190, 1, -20); Container.Position = UDim2.new(0, 190, 0, 10); Container.BackgroundTransparency = 1

local function CreateTabBtn(name, pos, page)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(0.85, 0, 0, 65); btn.Position = UDim2.new(0.075, 0, 0, pos); btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38); btn.Text = name:upper(); btn.TextColor3 = Color3.fromRGB(110, 110, 110); btn.Font = Enum.Font.Michroma; btn.TextSize = 16; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 22)
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Container:GetChildren()) do p.Visible = (p == page) end
        for _, b in pairs(Sidebar:GetChildren()) do if b:IsA("TextButton") then b.TextColor3 = (b == btn) and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(110, 110, 110) end end
    end)
    return btn
end

local MacroP = Instance.new("Frame", Container); MacroP.Size = UDim2.new(1, 0, 1, 0); MacroP.BackgroundTransparency = 1
local ParryP = Instance.new("Frame", Container); ParryP.Size = UDim2.new(1, 0, 1, 0); ParryP.BackgroundTransparency = 1; ParryP.Visible = false
CreateTabBtn("Macro", 140, MacroP); CreateTabBtn("Auto Parry", 220, ParryP)

-- [[ TAB 1: 3e5266 (MACRO ENGINE) ]]
local MTitle = Instance.new("TextLabel", MacroP); MTitle.Size = UDim2.new(1, 0, 0, 40); MTitle.Text = "MACRO ENGINE"; MTitle.TextColor3 = Color3.fromRGB(0,0,0); MTitle.BackgroundTransparency = 1; MTitle.Font = Enum.Font.Michroma; MTitle.TextSize = 24; MTitle.TextXAlignment = Enum.TextXAlignment.Left; MTitle.Position = UDim2.new(0,5,0,5)
local MLine = Instance.new("Frame", MacroP); MLine.Size = UDim2.new(1, 0, 0, 2); MLine.Position = UDim2.new(0,0,0,55); MLine.BackgroundColor3 = Color3.fromRGB(45,45,45); MLine.BorderSizePixel = 0

local Slider = Instance.new("Frame", MacroP); Slider.Size = UDim2.new(0.65, 0, 0, 2); Slider.Position = UDim2.new(0,5,0.35,0); Slider.BackgroundColor3 = Color3.fromRGB(220,220,220); Slider.BorderSizePixel = 0
local Dot = Instance.new("TextButton", Slider); Dot.Size = UDim2.new(0, 20, 0, 20); Dot.Position = UDim2.new(0, -10, 0.5, -10); Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Dot.Text = ""; Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)
local KPSLbl = Instance.new("TextLabel", MacroP); KPSLbl.Size = UDim2.new(0, 120, 0, 30); KPSLbl.Position = UDim2.new(0.7, 0, 0.3, 0); KPSLbl.Text = "KPS VALUE"; KPSLbl.TextColor3 = Color3.fromRGB(0,0,0); KPSLbl.BackgroundTransparency = 1; KPSLbl.Font = Enum.Font.Michroma; KPSLbl.TextSize = 14

local SpamLbl = Instance.new("TextLabel", MacroP); SpamLbl.Size = UDim2.new(0.7, 0, 0, 30); SpamLbl.Position = UDim2.new(0,10,0.58,0); SpamLbl.Text = "MANUAL SPAM / TOGGLE"; SpamLbl.TextColor3 = Color3.fromRGB(0,0,0); SpamLbl.BackgroundTransparency = 1; SpamLbl.Font = Enum.Font.Michroma; SpamLbl.TextSize = 14; SpamLbl.TextXAlignment = Enum.TextXAlignment.Left
local SwFrame = Instance.new("Frame", MacroP); SwFrame.Size = UDim2.new(0, 65, 0, 32); SwFrame.Position = UDim2.new(0.8, 0, 0.58, 0); SwFrame.BackgroundColor3 = Color3.fromRGB(150,150,150); Instance.new("UICorner", SwFrame).CornerRadius = UDim.new(1,0)
local SwThumb = Instance.new("Frame", SwFrame); SwThumb.Size = UDim2.new(0, 28, 0, 28); SwThumb.Position = UDim2.new(0,2,0.5,-14); SwThumb.BackgroundColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", SwThumb).CornerRadius = UDim.new(1,0)
local SwBtn = Instance.new("TextButton", SwFrame); SwBtn.Size = UDim2.new(1,0,1,0); SwBtn.BackgroundTransparency = 1; SwBtn.Text = ""

local ManualBtn = Instance.new("TextButton", MacroP); ManualBtn.Size = UDim2.new(0.98, 0, 0, 75); ManualBtn.Position = UDim2.new(0, 0, 0.75, 0); ManualBtn.BackgroundColor3 = Color3.fromRGB(52, 52, 52); ManualBtn.Text = "CLICK TO BIND"; ManualBtn.TextColor3 = Color3.fromRGB(110, 110, 110); ManualBtn.Font = Enum.Font.Michroma; ManualBtn.TextSize = 20; Instance.new("UICorner", ManualBtn).CornerRadius = UDim.new(0, 32)

-- [[ TAB 2: 8805c (AUTO PARRY) ]]
local PTitle = Instance.new("TextLabel", ParryP); PTitle.Size = UDim2.new(1, 0, 0, 40); PTitle.Text = "AUTO PARRY"; PTitle.TextColor3 = Color3.fromRGB(0,0,0); PTitle.BackgroundTransparency = 1; PTitle.Font = Enum.Font.Michroma; PTitle.TextSize = 24; PTitle.TextXAlignment = Enum.TextXAlignment.Left; PTitle.Position = UDim2.new(0,5,0,5)
local PLine = Instance.new("Frame", ParryP); PLine.Size = UDim2.new(1, 0, 0, 2); PLine.Position = UDim2.new(0,0,0,55); PLine.BackgroundColor3 = Color3.fromRGB(45,45,45); PLine.BorderSizePixel = 0

local POnOff = Instance.new("TextLabel", ParryP); POnOff.Size = UDim2.new(0.7, 0, 0, 30); POnOff.Position = UDim2.new(0,10,0.38,0); POnOff.Text = "AUTO PARRY ON/OFF"; POnOff.TextColor3 = Color3.fromRGB(0,0,0); POnOff.BackgroundTransparency = 1; POnOff.Font = Enum.Font.Michroma; POnOff.TextSize = 16; POnOff.TextXAlignment = Enum.TextXAlignment.Left
local PSwFrame = Instance.new("Frame", ParryP); PSwFrame.Size = UDim2.new(0, 65, 0, 34); PSwFrame.Position = UDim2.new(0.8, 0, 0.38, 0); PSwFrame.BackgroundColor3 = Color3.fromRGB(150,150,150); Instance.new("UICorner", PSwFrame).CornerRadius = UDim.new(1,0)
local PSwThumb = Instance.new("Frame", PSwFrame); PSwThumb.Size = UDim2.new(0, 30, 0, 30); PSwThumb.Position = UDim2.new(0,2,0.5,-15); PSwThumb.BackgroundColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", PSwThumb).CornerRadius = UDim.new(1,0)
local PSwBtn = Instance.new("TextButton", PSwFrame); PSwBtn.Size = UDim2.new(1,0,1,0); PSwBtn.BackgroundTransparency = 1; PSwBtn.Text = ""

-- [[ SYSTEM SYNC ]]
local function UpdateUI()
    local isKey = (EngineState.InputMode == "Keybind")
    TweenService:Create(SwThumb, TweenInfo.new(0.25), {Position = isKey and UDim2.new(1, -30, 0.5, -14) or UDim2.new(0, 2, 0.5, -14)}):Play()
    TweenService:Create(SwFrame, TweenInfo.new(0.25), {BackgroundColor3 = isKey and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(150,150,150)}):Play()
    local p = EngineState.AutoParryActive
    TweenService:Create(PSwThumb, TweenInfo.new(0.25), {Position = p and UDim2.new(1, -32, 0.5, -15) or UDim2.new(0, 2, 0.5, -15)}):Play()
    TweenService:Create(PSwFrame, TweenInfo.new(0.25), {BackgroundColor3 = p and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(150,150,150)}):Play()
    ManualBtn.Text = isKey and "BIND: " .. EngineState.ToggleKey.Name or "CLICK TO SPAM"
    KPSLbl.Text = EngineState.TargetSpeed .. " KPS VALUE"
end

local function Toggle()
    EngineState.MacroToggle = not EngineState.MacroToggle
    if EngineState.MacroToggle then MacroConn = game:GetService("RunService").PreRender:Connect(ExecuteStealthInput)
    elseif MacroConn then MacroConn:Disconnect() end
end

SwBtn.MouseButton1Click:Connect(function() EngineState.InputMode = (EngineState.InputMode == "Keybind") and "Button" or "Keybind"; UpdateUI() end)
PSwBtn.MouseButton1Click:Connect(function() EngineState.AutoParryActive = not EngineState.AutoParryActive; UpdateUI() end)

local listening = false
ManualBtn.MouseButton1Click:Connect(function()
    if EngineState.InputMode == "Button" then Toggle() else listening = true; ManualBtn.Text = "WAITING..." end
end)

UserInputService.InputBegan:Connect(function(i, g)
    if listening and i.UserInputType == Enum.UserInputType.Keyboard then 
        EngineState.ToggleKey = i.KeyCode; listening = false; UpdateUI()
    elseif not g and EngineState.InputMode == "Keybind" and i.KeyCode == EngineState.ToggleKey then Toggle() end
end)

local dragging = false
Dot.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local frac = math.clamp((i.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1)
        EngineState.TargetSpeed = math.round(1 + (frac * 2499)); Dot.Position = UDim2.new(frac, -10, 0.5, -10); UpdateUI()
    end
end)

UpdateUI()
if _G.StartParry then _G.StartParry() end
