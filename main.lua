-- =============================================================================
-- THYREN PRO ELITE (PART 1 OF 2) - KERNEL-LEVEL STEALTH ENGINE V21
-- =============================================================================

local uiName = "Thyren_Pro_Gemini_Final_V21"
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

-- [[ AGGRESSIVE CLEANUP ]]
for _, old in ipairs(CoreGui:GetChildren()) do
    if old.Name:find("Thyren") or old.Name == uiName then old:Destroy() end
end

-- [[ SHARED ENGINE STATE ]]
_G.ThyrenState = { 
    KPS = 10, 
    InputMode = "Button", -- "Button" or "Keybind"
    AutoParryOn = false, 
    MacroActive = false,
    ActionKey = Enum.KeyCode.F,
    ToggleKey = Enum.KeyCode.F9, 
    LastFire = 0
}

local _VIM = VirtualInputManager
local _send = _VIM.SendKeyEvent
local _clock = os.clock

-- [[ ENGINE: STEALTH CLICKER ]]
local function ExecuteStealthMacro()
    if not _G.ThyrenState.MacroActive then return end
    local cur = _clock()
    if (cur - _G.ThyrenState.LastFire) >= (1.0 / _G.ThyrenState.KPS) then
        _G.ThyrenState.LastFire = cur
        _send(_VIM, true, _G.ThyrenState.ActionKey, false, game)
        task.wait(0.0001)
        _send(_VIM, false, _G.ThyrenState.ActionKey, false, game)
    end
end

-- [[ ENGINE: PARRY INTERRUPT ]]
_G.InitializeThyrenEngines = function()
    RunService.PreSimulation:Connect(function()
        if not _G.ThyrenState.AutoParryOn then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local ballFolder = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("TrainingBalls")
        
        if root and ballFolder then
            for _, b in ipairs(ballFolder:GetChildren()) do
                if (b:GetAttribute("target") or b:GetAttribute("Target")) == LocalPlayer.Name then
                    local dist = (b.Position - root.Position).Magnitude
                    local vel = b.AssemblyLinearVelocity.Magnitude
                    if dist <= (45 + (vel * 0.13)) then
                        _send(_VIM, true, _G.ThyrenState.ActionKey, false, game)
                        _send(_VIM, false, _G.ThyrenState.ActionKey, false, game)
                    end
                end
            end
        end
    end)
    RunService.PreRender:Connect(ExecuteStealthMacro)
end
-- =============================================================================
-- THYREN PRO ELITE (PART 2 OF 2) - FULL GEMINI UI FUNCTIONAL WIRING
-- =============================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local uiName = "Thyren_Pro_Gemini_Final_V21"
local function IsKeyValid(k) return k == "kifHpqTzfWd5rM" end

-- [[ SCREEN GUI SETUP ]]
local screenGui = Instance.new("ScreenGui", CoreGui); screenGui.Name = uiName
screenGui.IgnoreGuiInset = true

-- [[ MAIN CONTAINER - STRICT GEMINI REPRODUCTION ]]
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 400, 0, 250); mainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60); mainFrame.BorderSizePixel = 0; mainFrame.Active = true; mainFrame.Visible = false
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- SIDE PANEL (STRICT GEMINI REPRODUCTION)
local sidePanel = Instance.new("Frame", mainFrame)
sidePanel.Size = UDim2.new(0, 100, 1, 0); sidePanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40); sidePanel.BorderSizePixel = 0
Instance.new("UICorner", sidePanel).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", sidePanel); title.Text = "THYREN"; title.Size = UDim2.new(1, 0, 0, 30); title.Font = Enum.Font.Michroma; title.TextSize = 16; title.TextColor3 = Color3.fromRGB(255,255,255); title.BackgroundTransparency = 1
local proStatus = Instance.new("TextLabel", sidePanel); proStatus.Text = "PRO"; proStatus.Size = UDim2.new(1, 0, 0, 20); proStatus.Position = UDim2.new(0, 0, 0, 30); proStatus.Font = Enum.Font.Michroma; proStatus.TextSize = 12; proStatus.TextColor3 = Color3.fromRGB(0, 180, 255); proStatus.BackgroundTransparency = 1

local macroBtn = Instance.new("TextButton", sidePanel); macroBtn.Text = "MACRO"; macroBtn.Size = UDim2.new(1, -10, 0, 40); macroBtn.Position = UDim2.new(0, 5, 0, 70); macroBtn.BackgroundColor3 = Color3.fromRGB(50,50,50); macroBtn.Font = Enum.Font.Michroma; macroBtn.TextSize = 12; macroBtn.TextColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", macroBtn).CornerRadius = UDim.new(0, 6)
local autoParryBtn = Instance.new("TextButton", sidePanel); autoParryBtn.Text = "AUTO PARRY"; autoParryBtn.Size = UDim2.new(1, -10, 0, 40); autoParryBtn.Position = UDim2.new(0, 5, 0, 120); autoParryBtn.BackgroundColor3 = Color3.fromRGB(50,50,50); autoParryBtn.Font = Enum.Font.Michroma; autoParryBtn.TextSize = 10; autoParryBtn.TextColor3 = Color3.fromRGB(150,150,150); Instance.new("UICorner", autoParryBtn).CornerRadius = UDim.new(0, 6)

-- [[ PAGE SYSTEM CONTAINER ]]
local PageContainer = Instance.new("Frame", mainFrame); PageContainer.Size = UDim2.new(1, -110, 1, -10); PageContainer.Position = UDim2.new(0, 105, 0, 5); PageContainer.BackgroundTransparency = 1
local Page1 = Instance.new("Frame", PageContainer); Page1.Size = UDim2.new(1,0,1,0); Page1.BackgroundTransparency = 1
local Page2 = Instance.new("Frame", PageContainer); Page2.Size = UDim2.new(1,0,1,0); Page2.BackgroundTransparency = 1; Page2.Visible = false

-- [[ PAGE 1: MACRO ELEMENTS (FROM GEMINI) ]]
local kpsLabel = Instance.new("TextLabel", Page1); kpsLabel.Text = "KPS VALUE: 10"; kpsLabel.Size = UDim2.new(0, 120, 0, 30); kpsLabel.Position = UDim2.new(0.5, -60, 0, 10); kpsLabel.Font = Enum.Font.Michroma; kpsLabel.TextSize = 12; kpsLabel.TextColor3 = Color3.fromRGB(255,255,255); kpsLabel.BackgroundTransparency = 1
local Slider = Instance.new("Frame", Page1); Slider.Size = UDim2.new(0.8, 0, 0, 4); Slider.Position = UDim2.new(0.1, 0, 0, 45); Slider.BackgroundColor3 = Color3.fromRGB(80,80,80); Slider.BorderSizePixel = 0
local Dot = Instance.new("TextButton", Slider); Dot.Size = UDim2.new(0, 16, 0, 16); Dot.Position = UDim2.new(0, -8, 0.5, -8); Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255); Dot.Text = ""; Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)

local toggleLabel = Instance.new("TextLabel", Page1); toggleLabel.Text = "MANUAL SPAM / TOGGLE"; toggleLabel.Size = UDim2.new(0.6, 0, 0, 30); toggleLabel.Position = UDim2.new(0.1, 0, 0, 80); toggleLabel.Font = Enum.Font.Michroma; toggleLabel.TextSize = 10; toggleLabel.TextColor3 = Color3.fromRGB(200,200,200); toggleLabel.BackgroundTransparency = 1; toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
local toggleSwitch = Instance.new("Frame", Page1); toggleSwitch.Size = UDim2.new(0, 50, 0, 24); toggleSwitch.Position = UDim2.new(0.7, 0, 0, 83); toggleSwitch.BackgroundColor3 = Color3.fromRGB(45,45,45); Instance.new("UICorner", toggleSwitch).CornerRadius = UDim.new(1,0)
local switchThumb = Instance.new("Frame", toggleSwitch); switchThumb.Size = UDim2.new(0, 20, 0, 20); switchThumb.Position = UDim2.new(0,2,0.5,-10); switchThumb.BackgroundColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", switchThumb).CornerRadius = UDim.new(1,0)
local switchBtn = Instance.new("TextButton", toggleSwitch); switchBtn.Size = UDim2.new(1,0,1,0); switchBtn.BackgroundTransparency = 1; switchBtn.Text = ""

-- BIND BUTTON (DARK MATTE REPLICA - NOT PURE WHITE)
local bindBtn = Instance.new("TextButton", Page1); bindBtn.Text = "CLICK TO BIND"; bindBtn.Size = UDim2.new(0, 250, 0, 45); bindBtn.Position = UDim2.new(0.5, -125, 0, 160); bindBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); bindBtn.Font = Enum.Font.Michroma; bindBtn.TextSize = 14; bindBtn.TextColor3 = Color3.fromRGB(200,200,200); Instance.new("UICorner", bindBtn).CornerRadius = UDim.new(0, 8)

-- [[ PAGE 2: AUTO PARRY ELEMENTS (FROM GEMINI) ]]
local apTitle = Instance.new("TextLabel", Page2); apTitle.Text = "THYREN AUTO PARRY"; apTitle.Size = UDim2.new(1, 0, 0, 30); apTitle.Position = UDim2.new(0, 0, 0, 10); apTitle.Font = Enum.Font.Michroma; apTitle.TextSize = 14; apTitle.TextColor3 = Color3.fromRGB(255,255,255); apTitle.BackgroundTransparency = 1
local apToggleLabel = Instance.new("TextLabel", Page2); apToggleLabel.Text = "AUTO PARRY ON/OFF"; apToggleLabel.Size = UDim2.new(0.6, 0, 0, 30); apToggleLabel.Position = UDim2.new(0.1, 0, 0, 70); apToggleLabel.Font = Enum.Font.Michroma; apToggleLabel.TextSize = 12; apToggleLabel.TextColor3 = Color3.fromRGB(200,200,200); apToggleLabel.BackgroundTransparency = 1; apToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
local apSwitch = Instance.new("Frame", Page2); apSwitch.Size = UDim2.new(0, 60, 0, 28); apSwitch.Position = UDim2.new(0.7, 0, 0, 71); apSwitch.BackgroundColor3 = Color3.fromRGB(45,45,45); Instance.new("UICorner", apSwitch).CornerRadius = UDim.new(1,0)
local apThumb = Instance.new("Frame", apSwitch); apThumb.Size = UDim2.new(0, 24, 0, 24); apThumb.Position = UDim2.new(0,2,0.5,-12); apThumb.BackgroundColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", apThumb).CornerRadius = UDim.new(1,0)
local apBtn = Instance.new("TextButton", apSwitch); apBtn.Size = UDim2.new(1,0,1,0); apBtn.BackgroundTransparency = 1; apBtn.Text = ""

-- [[ KEY SYSTEM & INITIALIZE ]]
local Auth = Instance.new("Frame", screenGui); Auth.Size = UDim2.new(0, 400, 0, 250); Auth.Position = UDim2.new(0.5, -200, 0.5, -125); Auth.BackgroundColor3 = Color3.fromRGB(60, 60, 60); Auth.ZIndex = 100; Instance.new("UICorner", Auth).CornerRadius = UDim.new(0, 12)
local KeyIn = Instance.new("TextBox", Auth); KeyIn.Size = UDim2.new(0, 280, 0, 40); KeyIn.Position = UDim2.new(0.5, -140, 0.3, 0); KeyIn.BackgroundColor3 = Color3.fromRGB(45,45,45); KeyIn.TextColor3 = Color3.fromRGB(255,255,255); KeyIn.PlaceholderText = "MASTER KEY"; KeyIn.Font = Enum.Font.Michroma; KeyIn.TextSize = 12; Instance.new("UICorner", KeyIn).CornerRadius = UDim.new(0, 6)
local Submit = Instance.new("TextButton", Auth); Submit.Size = UDim2.new(0, 280, 0, 40); Submit.Position = UDim2.new(0.5, -140, 0.65, 0); Submit.BackgroundColor3 = Color3.fromRGB(0, 160, 255); Submit.Text = "AUTHENTICATE"; Submit.TextColor3 = Color3.fromRGB(255,255,255); Submit.Font = Enum.Font.Michroma; Submit.TextSize = 12; Instance.new("UICorner", Submit).CornerRadius = UDim.new(0, 6)

local Act = Instance.new("TextButton", screenGui); Act.Size = UDim2.new(0, 160, 0, 60); Act.Position = UDim2.new(0.5, -80, 0.85, 0); Act.BackgroundColor3 = Color3.fromRGB(255,255,255); Act.BackgroundTransparency = 0.94; Act.Text = "INITIALIZE"; Act.TextColor3 = Color3.fromRGB(255,255,255); Act.Font = Enum.Font.Michroma; Act.TextSize = 18; Act.Visible = false; Instance.new("UICorner", Act).CornerRadius = UDim.new(0, 12)

-- [[ LOGIC INTEGRATION ]]
local function UpdateUI()
    local isK = (_G.ThyrenState.InputMode == "Keybind")
    TweenService:Create(switchThumb, TweenInfo.new(0.2), {Position = isK and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)}):Play()
    TweenService:Create(toggleSwitch, TweenInfo.new(0.2), {BackgroundColor3 = isK and Color3.fromRGB(0,180,255) or Color3.fromRGB(45,45,45)}):Play()
    local p = _G.ThyrenState.AutoParryOn
    TweenService:Create(apThumb, TweenInfo.new(0.2), {Position = p and UDim2.new(1,-26,0.5,-12) or UDim2.new(0,2,0.5,-12)}):Play()
    TweenService:Create(apSwitch, TweenInfo.new(0.2), {BackgroundColor3 = p and Color3.fromRGB(0,180,255) or Color3.fromRGB(45,45,45)}):Play()
    Act.Text = _G.ThyrenState.MacroActive and "HALT ENGINE" or "INITIALIZE"
    bindBtn.Text = isK and "BIND: " .. _G.ThyrenState.ToggleKey.Name or "MANUAL SPAM"
    kpsLabel.Text = "KPS VALUE: " .. _G.ThyrenState.KPS
    macroBtn.TextColor3 = Page1.Visible and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150)
    autoParryBtn.TextColor3 = Page2.Visible and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150)
end

macroBtn.MouseButton1Click:Connect(function() Page1.Visible = true; Page2.Visible = false; UpdateUI() end)
autoParryBtn.MouseButton1Click:Connect(function() Page1.Visible = false; Page2.Visible = true; UpdateUI() end)
switchBtn.MouseButton1Click:Connect(function() _G.ThyrenState.InputMode = (_G.ThyrenState.InputMode == "Keybind") and "Button" or "Keybind"; UpdateUI() end)
apBtn.MouseButton1Click:Connect(function() _G.ThyrenState.AutoParryOn = not _G.ThyrenState.AutoParryOn; UpdateUI() end)
Act.MouseButton1Click:Connect(function() _G.ThyrenState.MacroActive = not _G.ThyrenState.MacroActive; UpdateUI() end)

local listen = false
bindBtn.MouseButton1Click:Connect(function() if _G.ThyrenState.InputMode == "Button" then _G.ThyrenState.MacroActive = not _G.ThyrenState.MacroActive; UpdateUI() else listen = true; bindBtn.Text = "WAITING..." end end)
UserInputService.InputBegan:Connect(function(i, g) if listen and i.UserInputType == Enum.UserInputType.Keyboard then _G.ThyrenState.ToggleKey = i.KeyCode; listen = false; UpdateUI() elseif not g and _G.ThyrenState.InputMode == "Keybind" and i.KeyCode == _G.ThyrenState.ToggleKey then _G.ThyrenState.MacroActive = not _G.ThyrenState.MacroActive; UpdateUI() end end)

local drag = false
Dot.MouseButton1Down:Connect(function() drag = true end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local frac = math.clamp((i.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1); _G.ThyrenState.KPS = math.round(1 + (frac * 2499)); Dot.Position = UDim2.new(frac, -11, 0.5, -11); UpdateUI() end end)

Submit.MouseButton1Click:Connect(function() if IsKeyValid(KeyIn.Text) then Auth:Destroy(); mainFrame.Visible = true; Act.Visible = true; UpdateUI(); if _G.InitializeThyrenEngines then _G.InitializeThyrenEngines() end end end)
UpdateUI()
