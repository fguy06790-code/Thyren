-- =============================================================================
-- THYREN PRO ELITE (PART 1 OF 2) - KERNEL-LEVEL STEALTH ENGINE V16
-- =============================================================================

local uiName = "Thyren_Pro_PDF_Exact_V16"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

-- [[ CLEANUP ]]
for _, old in ipairs(CoreGui:GetChildren()) do
    if old.Name:find("Thyren_Pro") then old:Destroy() end
end

local EngineState = { 
    TargetSpeed = 10, 
    InputMode = "Button",
    AutoParryActive = false, 
    ActionKey = Enum.KeyCode.F,
    ToggleKey = Enum.KeyCode.F9, 
    LastFireTime = 0, 
    MacroToggle = false
}

local _VIM = VirtualInputManager
local _send = _VIM.SendKeyEvent
local _clock = os.clock
local _wait = task.wait

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
            if dist <= (45 + (vel * 0.13)) then 
                _send(_VIM, true, EngineState.ActionKey, false, game)
                _send(_VIM, false, EngineState.ActionKey, false, game)
            end
        end
    end)
end
-- =============================================================================
-- THYREN PRO ELITE (PART 2 OF 2) - ABSOLUTE PIXEL-PERFECT PDF REPRODUCTION
-- =============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local function IsKeyValid(input) return input == "kifHpqTzfWd5rM" end

local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = "Thyren_Pro_PDF_Exact_V16"
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

-- [[ THE MAIN CONTAINER - PIXEL-PERFECT PDF COLORS ]]
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 560, 0, 320); Main.Position = UDim2.new(0.5, -280, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(75, 75, 75); Main.BorderSizePixel = 0; Main.Active = true; Main.Visible = false
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 32)
MakeDraggable(Main)

-- [[ SIDEBAR REPLICA ]]
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 160, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(50, 50, 50); Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 32)

-- SIDEBAR HEADERS (1:1 PDF SCALE)
local Header = Instance.new("TextLabel", Sidebar); Header.Size = UDim2.new(1, 0, 0, 50); Header.Text = "THYREN"; Header.TextColor3 = Color3.fromRGB(0, 0, 0); Header.BackgroundTransparency = 1; Header.Font = Enum.Font.Michroma; Header.TextSize = 34; Header.Position = UDim2.new(0,0,0,25)
local SubHeader = Instance.new("TextLabel", Sidebar); SubHeader.Size = UDim2.new(1, 0, 0, 40); SubHeader.Text = "PRO"; SubHeader.TextColor3 = Color3.fromRGB(0, 0, 0); SubHeader.BackgroundTransparency = 1; SubHeader.Font = Enum.Font.Michroma; SubHeader.TextSize = 30; SubHeader.Position = UDim2.new(0,0,0,70)

local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -180, 1, -20); Container.Position = UDim2.new(0, 180, 0, 10); Container.BackgroundTransparency = 1

local function CreateTabBtn(name, pos, page)
    local btn = Instance.new("TextButton", Sidebar); btn.Size = UDim2.new(0.85, 0, 0, 65); btn.Position = UDim2.new(0.075, 0, 0, pos); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.Text = name:upper(); btn.TextColor3 = Color3.fromRGB(110, 110, 110); btn.Font = Enum.Font.Michroma; btn.TextSize = 16; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 22)
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Container:GetChildren()) do p.Visible = (p == page) end
        for _, b in pairs(Sidebar:GetChildren()) do if b:IsA("TextButton") then b.TextColor3 = (b == btn) and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(110, 110, 110) end end
    end)
    return btn
end

local MacroP = Instance.new("Frame", Container); MacroP.Size = UDim2.new(1, 0, 1, 0); MacroP.BackgroundTransparency = 1
local ParryP = Instance.new("Frame", Container); ParryP.Size = UDim2.new(1, 0, 1, 0); ParryP.BackgroundTransparency = 1; ParryP.Visible = false
CreateTabBtn("Macro", 140, MacroP); CreateTabBtn("Auto Parry", 220, ParryP)

-- [[ TAB 1: MACRO ENGINE (PDF REPRODUCTION) ]]
local MTitle = Instance.new("TextLabel", MacroP); MTitle.Size = UDim2.new(1, 0, 0, 40); MTitle.Text = "MACRO ENGINE"; MTitle.TextColor3 = Color3.fromRGB(0,0,0); MTitle.BackgroundTransparency = 1; MTitle.Font = Enum.Font.Michroma; MTitle.TextSize = 26; MTitle.TextXAlignment = Enum.TextXAlignment.Left; MTitle.Position = UDim2.new(0,5,0,10)
local MLine = Instance.new("Frame", MacroP); MLine.Size = UDim2.new(1.05, 0, 0, 2); MLine.Position = UDim2.new(-0.05,0,0,65); MLine.BackgroundColor3 = Color3.fromRGB(45,45,45); MLine.BorderSizePixel = 0

-- PDF SLIDER & LABEL REPLICA
local Slider = Instance.new("Frame", MacroP); Slider.Size = UDim2.new(0.6, 0, 0, 2); Slider.Position = UDim2.new(0,5,0,110); Slider.BackgroundColor3 = Color3.fromRGB(220,220,220); Slider.BorderSizePixel = 0
local Dot = Instance.new("TextButton", Slider); Dot.Size = UDim2.new(0, 22, 0, 22); Dot.Position = UDim2.new(0, -11, 0.5, -11); Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Dot.Text = ""; Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)
local KPSLbl = Instance.new("TextLabel", MacroP); KPSLbl.Size = UDim2.new(0, 120, 0, 30); KPSLbl.Position = UDim2.new(0.65, 0, 0, 95); KPSLbl.Text = "KPS VALUE"; KPSLbl.TextColor3 = Color3.fromRGB(0,0,0); KPSLbl.BackgroundTransparency = 1; KPSLbl.Font = Enum.Font.Michroma; KPSLbl.TextSize = 14

-- "MANUAL SPAM / TOGGLE" & PILL SWITCH
local SpamLbl = Instance.new("TextLabel", MacroP); SpamLbl.Size = UDim2.new(0.7, 0, 0, 30); SpamLbl.Position = UDim2.new(0,10,0,165); SpamLbl.Text = "MANUAL SPAM / TOGGLE"; SpamLbl.TextColor3 = Color3.fromRGB(0,0,0); SpamLbl.BackgroundTransparency = 1; SpamLbl.Font = Enum.Font.Michroma; SpamLbl.TextSize = 14; SpamLbl.TextXAlignment = Enum.TextXAlignment.Left
local SwFrame = Instance.new("Frame", MacroP); SwFrame.Size = UDim2.new(0, 70, 0, 34); SwFrame.Position = UDim2.new(0.78, 0, 0, 165); SwFrame.BackgroundColor3 = Color3.fromRGB(150,150,150); Instance.new("UICorner", SwFrame).CornerRadius = UDim.new(1,0)
local SwThumb = Instance.new("Frame", SwFrame); SwThumb.Size = UDim2.new(0, 30, 0, 30); SwThumb.Position = UDim2.new(0,2,0.5,-15); SwThumb.BackgroundColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", SwThumb).CornerRadius = UDim.new(1,0)
local SwBtn = Instance.new("TextButton", SwFrame); SwBtn.Size = UDim2.new(1,0,1,0); SwBtn.BackgroundTransparency = 1; SwBtn.Text = ""

-- DARK MATTE TRIGGER BUTTON (CENTERED)
local Bind = Instance.new("TextButton", MacroP); Bind.Size = UDim2.new(0.95, 0, 0, 75); Bind.Position = UDim2.new(0.025, 0, 0, 215); Bind.BackgroundColor3 = Color3.fromRGB(52, 52, 52); Bind.Text = "CLICK TO BIND"; Bind.TextColor3 = Color3.fromRGB(110, 110, 110); Bind.Font = Enum.Font.Michroma; Bind.TextSize = 20; Instance.new("UICorner", Bind).CornerRadius = UDim.new(0, 35)

-- [[ PAGE 2: AUTO PARRY REPLICA ]]
local POnOff = Instance.new("TextLabel", ParryP); POnOff.Size = UDim2.new(0.7, 0, 0, 30); POnOff.Position = UDim2.new(0,10,0,110); POnOff.Text = "AUTO PARRY ON/OFF"; POnOff.TextColor3 = Color3.fromRGB(0,0,0); POnOff.BackgroundTransparency = 1; POnOff.Font = Enum.Font.Michroma; POnOff.TextSize = 18; POnOff.TextXAlignment = Enum.TextXAlignment.Left
local PSwFrame = Instance.new("Frame", ParryP); PSwFrame.Size = UDim2.new(0, 75, 0, 38); PSwFrame.Position = UDim2.new(0.78, 0, 0, 110); PSwFrame.BackgroundColor3 = Color3.fromRGB(150,150,150); Instance.new("UICorner", PSwFrame).CornerRadius = UDim.new(1,0)
local PSwThumb = Instance.new("Frame", PSwFrame); PSwThumb.Size = UDim2.new(0, 34, 0, 34); PSwThumb.Position = UDim2.new(0,2,0.5,-17); PSwThumb.BackgroundColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", PSwThumb).CornerRadius = UDim.new(1,0)
local PSwBtn = Instance.new("TextButton", PSwFrame); PSwBtn.Size = UDim2.new(1,0,1,0); PSwBtn.BackgroundTransparency = 1; PSwBtn.Text = ""

-- [[ KEY SYSTEM OVERLAY ]]
local Auth = Instance.new("Frame", ScreenGui); Auth.Size = UDim2.new(0, 560, 0, 320); Auth.Position = UDim2.new(0.5, -280, 0.5, -160); Auth.BackgroundColor3 = Color3.fromRGB(75, 75, 75); Auth.BorderSizePixel = 0; Auth.ZIndex = 100
Instance.new("UICorner", Auth).CornerRadius = UDim.new(0, 32); MakeDraggable(Auth)
local KeyInput = Instance.new("TextBox", Auth); KeyInput.Size = UDim2.new(0, 320, 0, 50); KeyInput.Position = UDim2.new(0.5, -160, 0.35, -25); KeyInput.BackgroundColor3 = Color3.fromRGB(55, 55, 55); KeyInput.TextColor3 = Color3.fromRGB(220, 220, 230); KeyInput.PlaceholderText = "MASTER ACCESS KEY"; KeyInput.Text = ""; KeyInput.Font = Enum.Font.Michroma; KeyInput.TextSize = 16; KeyInput.ZIndex = 101; Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 12)
local Submit = Instance.new("TextButton", Auth); Submit.Size = UDim2.new(0, 320, 0, 50); Submit.Position = UDim2.new(0.5, -160, 0.7, -25); Submit.BackgroundColor3 = Color3.fromRGB(0, 160, 255); Submit.Text = "AUTHENTICATE SYSTEM"; Submit.TextColor3 = Color3.fromRGB(255, 255, 255); Submit.Font = Enum.Font.Michroma; Submit.TextSize = 16; Submit.ZIndex = 101; Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 12)

-- [[ SEPARATE FLOATING ACTIVATE BUTTON ]]
local Act = Instance.new("TextButton", ScreenGui); Act.Size = UDim2.new(0, 220, 0, 85); Act.Position = UDim2.new(0.5, -110, 0.8, 0); Act.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Act.BackgroundTransparency = 0.93; Act.Text = "INITIALIZE"; Act.TextColor3 = Color3.fromRGB(255, 255, 255); Act.Font = Enum.Font.Michroma; Act.TextSize = 24; Act.Visible = false; Instance.new("UICorner", Act).CornerRadius = UDim.new(0, 26); MakeDraggable(Act)
local ActGlow = Instance.new("Frame", Act); ActGlow.Size = UDim2.new(1, 10, 1, 10); ActGlow.Position = UDim2.new(0,-5,0,-5); ActGlow.BackgroundColor3 = Color3.fromRGB(0, 180, 255); ActGlow.BackgroundTransparency = 0.8; ActGlow.ZIndex = -1; Instance.new("UICorner", ActGlow).CornerRadius = UDim.new(0, 30)

-- [[ ANIMATION & SYNC ]]
local function ApplyFade(frame)
    frame.BackgroundTransparency = 1
    for _, c in pairs(frame:GetDescendants()) do if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then c.TextTransparency = 1 elseif c:IsA("Frame") then c.BackgroundTransparency = 1 end end
    TweenService:Create(frame, TweenInfo.new(0.6), {BackgroundTransparency = 0}):Play()
    for _, c in pairs(frame:GetDescendants()) do if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox") then TweenService:Create(c, TweenInfo.new(0.6), {TextTransparency = 0}):Play() elseif c:IsA("Frame") and c ~= frame then TweenService:Create(c, TweenInfo.new(0.6), {BackgroundTransparency = c.BackgroundTransparency}):Play() end end
end

local function UpdateUI()
    local isKey = (EngineState.InputMode == "Keybind")
    TweenService:Create(SwThumb, TweenInfo.new(0.2), {Position = isKey and UDim2.new(1, -32, 0.5, -15) or UDim2.new(0, 2, 0.5, -15)}):Play()
    TweenService:Create(SwFrame, TweenInfo.new(0.2), {BackgroundColor3 = isKey and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(150,150,150)}):Play()
    local p = EngineState.AutoParryActive
    TweenService:Create(PSwThumb, TweenInfo.new(0.2), {Position = p and UDim2.new(1, -36, 0.5, -17) or UDim2.new(0, 2, 0.5, -17)}):Play()
    TweenService:Create(PSwFrame, TweenInfo.new(0.2), {BackgroundColor3 = p and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(150,150,150)}):Play()
    Act.Text = EngineState.MacroToggle and "HALT CORE" or "INITIALIZE"
    Bind.Text = isKey and "BIND: " .. EngineState.ToggleKey.Name or "MANUAL SPAM / TOGGLE"
    KPSLbl.Text = EngineState.TargetSpeed .. " KPS VALUE"
end

local function ToggleLogic()
    EngineState.MacroToggle = not EngineState.MacroToggle
    if EngineState.MacroToggle then MacroConn = game:GetService("RunService").PreRender:Connect(ExecuteStealthInput)
    elseif MacroConn then MacroConn:Disconnect() end
    UpdateUI()
end

SwBtn.MouseButton1Click:Connect(function() EngineState.InputMode = (EngineState.InputMode == "Keybind") and "Button" or "Keybind"; UpdateUI() end)
PSwBtn.MouseButton1Click:Connect(function() EngineState.AutoParryActive = not EngineState.AutoParryActive; UpdateUI() end)
Act.MouseButton1Click:Connect(ToggleLogic)

local listen = false
Bind.MouseButton1Click:Connect(function()
    if EngineState.InputMode == "Button" then ToggleLogic() else listen = true; Bind.Text = "WAITING..." end
end)

UserInputService.InputBegan:Connect(function(i, g)
    if listen and i.UserInputType == Enum.UserInputType.Keyboard then EngineState.ToggleKey = i.KeyCode; listen = false; UpdateUI()
    elseif not g and EngineState.InputMode == "Keybind" and i.KeyCode == EngineState.ToggleKey then ToggleLogic() end
end)

local dragging = false
Dot.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local frac = math.clamp((i.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1)
        EngineState.TargetSpeed = math.round(1 + (frac * 2499)); Dot.Position = UDim2.new(frac, -11, 0.5, -11); UpdateUI()
    end
end)

Submit.MouseButton1Click:Connect(function()
    if IsKeyValid(KeyInput.Text) then
        Auth:Destroy()
        Main.Visible = true; Act.Visible = true; UpdateUI()
        ApplyFade(Main); ApplyFade(Act)
        if _G.StartParry then _G.StartParry() end
    end
end)

UpdateUI()
