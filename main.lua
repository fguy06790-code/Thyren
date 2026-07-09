-- =============================================================================
-- THYREN - UNIVERSAL GRAY EDITION
-- Works in EVERY game | Works with EVERY executor
-- Dark Gray Theme | Auto-detects environment
-- =============================================================================

-- =============================================================================
-- EXECUTOR DETECTION
-- =============================================================================

local function DetectExecutor()
    local executors = {
        {name = "Synapse X", check = function() return syn and syn.request end},
        {name = "Krnl", check = function() return getgenv and getgenv().Krnl end},
        {name = "Script-Ware", check = function() return scriptware and scriptware.loadstring end},
        {name = "Fluxus", check = function() return fluxus and fluxus.import end},
        {name = "Oxygen U", check = function() return oxygen and oxygen.loadstring end},
        {name = "Vega X", check = function() return vega and vega.loadstring end},
        {name = "Calamari", check = function() return calamari and calamari.execute end},
        {name = "Electron", check = function() return electron and electron.loadstring end},
        {name = "ProtoSmasher", check = function() return protosmasher and protosmasher.execute end},
        {name = "Sirius", check = function() return sirius and sirius.loadstring end},
        {name = "Valyse", check = function() return valyse and valyse.loadstring end},
        {name = "Cryptic", check = function() return cryptic and cryptic.execute end},
        {name = "Unknown", check = function() return true end},
    }
    
    for _, exec in ipairs(executors) do
        local success, result = pcall(exec.check)
        if success and result then
            return exec.name
        end
    end
    return "Unknown"
end

local EXECUTOR = DetectExecutor()

-- =============================================================================
-- GAME DETECTION
-- =============================================================================

local function DetectGame()
    local placeId = game.PlaceId
    local gameName = ""
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name
    end)
    
    if gameName ~= "" then return gameName end
    return "Unknown Game"
end

local GAME = DetectGame()

-- =============================================================================
-- SAFE PARENT
-- =============================================================================

local function GetSafeParent()
    local parents = {
        game:GetService("CoreGui"),
        game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
        game:GetService("Workspace"),
        game,
    }
    
    for _, parent in ipairs(parents) do
        if parent then
            local success, result = pcall(function()
                local test = Instance.new("Folder")
                test.Parent = parent
                test:Destroy()
                return parent
            end)
            if success and result then
                return result
            end
        end
    end
    return nil
end

-- =============================================================================
-- UNIVERSAL INPUT
-- =============================================================================

local function SendKey(key, down)
    pcall(function()
        game:GetService("VirtualInputManager"):SendKeyEvent(down, key, false, game)
    end)
end

local function SendMouse(x, y, down)
    pcall(function()
        game:GetService("VirtualInputManager"):SendMouseButtonEvent(x, y, 0, down, game, 0)
    end)
end

-- =============================================================================
-- COLORS — GRAY THEME
-- =============================================================================

local Colors = {
    bg = Color3.fromRGB(18, 18, 22),
    bg2 = Color3.fromRGB(24, 24, 30),
    bg3 = Color3.fromRGB(32, 32, 40),
    bg4 = Color3.fromRGB(40, 40, 50),
    border = Color3.fromRGB(45, 45, 55),
    text = Color3.fromRGB(230, 230, 240),
    textDim = Color3.fromRGB(140, 140, 160),
    textBright = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(100, 100, 120),
    accent2 = Color3.fromRGB(80, 80, 100),
    success = Color3.fromRGB(68, 255, 136),
    error = Color3.fromRGB(255, 68, 85),
    warning = Color3.fromRGB(255, 170, 51),
}

-- =============================================================================
-- STATE
-- =============================================================================

local State = {
    running = false,
    speed = 10,
    mode = "KPS",
    lowEnd = false,
    activation = "Manual",
    hotkey = nil,
    binding = false,
    autoParry = false,
    spamKey = Enum.KeyCode.F,
    macroConnection = nil,
    lastFire = 0,
    visible = true,
    collapsed = false,
}

-- =============================================================================
-- UI HELPERS
-- =============================================================================

local function ApplyRadius(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
end

local function Animate(obj, props, time)
    time = time or 0.2
    game:GetService("TweenService"):Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- =============================================================================
-- CREATE UI
-- =============================================================================

local TargetParent = GetSafeParent()
if not TargetParent then
    error("No safe parent found")
end

local SG = Instance.new("ScreenGui")
SG.Name = "ThyrenUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = TargetParent
SG.Archivable = false

-- MAIN FRAME
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 460, 0, 340)
Main.Position = UDim2.new(0.5, -230, 0.4, -170)
Main.BackgroundColor3 = Colors.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.Parent = SG
ApplyRadius(Main, 12)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Colors.border
Stroke.Thickness = 1

-- TITLE BAR
local Title = Instance.new("Frame", Main)
Title.Size = UDim2.new(1, 0, 0, 34)
Title.BackgroundColor3 = Colors.bg2
Title.BorderSizePixel = 0
ApplyRadius(Title, 12)

local TitleLabel = Instance.new("TextLabel", Title)
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "◼ THYREN"
TitleLabel.TextColor3 = Colors.text
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Title)
CloseBtn.Size = UDim2.new(0, 28, 1, -6)
CloseBtn.Position = UDim2.new(1, -34, 0, 3)
CloseBtn.BackgroundColor3 = Colors.bg3
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Colors.textDim
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.BorderSizePixel = 0
ApplyRadius(CloseBtn, 6)

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

CloseBtn.MouseEnter:Connect(function()
    CloseBtn.BackgroundColor3 = Colors.error
    CloseBtn.TextColor3 = Colors.textBright
end)

CloseBtn.MouseLeave:Connect(function()
    CloseBtn.BackgroundColor3 = Colors.bg3
    CloseBtn.TextColor3 = Colors.textDim
end)

-- CONTENT
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, 0, 1, -34)
Content.Position = UDim2.new(0, 0, 0, 34)
Content.BackgroundTransparency = 1

-- STATUS BAR
local StatusFrame = Instance.new("Frame", Content)
StatusFrame.Size = UDim2.new(1, -20, 0, 30)
StatusFrame.Position = UDim2.new(0, 10, 0, 6)
StatusFrame.BackgroundColor3 = Colors.bg2
StatusFrame.BorderSizePixel = 0
ApplyRadius(StatusFrame, 6)

local StatusLabel = Instance.new("TextLabel", StatusFrame)
StatusLabel.Size = UDim2.new(0, 120, 1, 0)
StatusLabel.Position = UDim2.new(0, 10, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "● IDLE"
StatusLabel.TextColor3 = Colors.textDim
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local InfoLabel = Instance.new("TextLabel", StatusFrame)
InfoLabel.Size = UDim2.new(0, 200, 1, 0)
InfoLabel.Position = UDim2.new(1, -210, 0, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "EXEC: " .. EXECUTOR .. " | " .. GAME
InfoLabel.TextColor3 = Colors.textDim
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 9
InfoLabel.TextXAlignment = Enum.TextXAlignment.Right

-- MODE ROW
local ModeRow = Instance.new("Frame", Content)
ModeRow.Size = UDim2.new(1, -20, 0, 28)
ModeRow.Position = UDim2.new(0, 10, 0, 42)
ModeRow.BackgroundColor3 = Colors.bg2
ModeRow.BorderSizePixel = 0
ApplyRadius(ModeRow, 6)

local ModeBtn = Instance.new("TextButton", ModeRow)
ModeBtn.Size = UDim2.new(0, 100, 1, -4)
ModeBtn.Position = UDim2.new(0, 4, 0, 2)
ModeBtn.BackgroundColor3 = Colors.bg3
ModeBtn.Text = "KPS"
ModeBtn.TextColor3 = Colors.text
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.TextSize = 12
ModeBtn.BorderSizePixel = 0
ApplyRadius(ModeBtn, 5)

local KeyLabel = Instance.new("TextLabel", ModeRow)
KeyLabel.Size = UDim2.new(0, 100, 1, 0)
KeyLabel.Position = UDim2.new(0, 115, 0, 0)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "KEY: F"
KeyLabel.TextColor3 = Colors.text
KeyLabel.Font = Enum.Font.GothamBold
KeyLabel.TextSize = 12
KeyLabel.TextXAlignment = Enum.TextXAlignment.Left

local BindBtn = Instance.new("TextButton", ModeRow)
BindBtn.Size = UDim2.new(0, 60, 1, -4)
BindBtn.Position = UDim2.new(1, -64, 0, 2)
BindBtn.BackgroundColor3 = Colors.bg3
BindBtn.Text = "BIND"
BindBtn.TextColor3 = Colors.text
BindBtn.Font = Enum.Font.GothamBold
BindBtn.TextSize = 10
BindBtn.BorderSizePixel = 0
ApplyRadius(BindBtn, 5)

-- CPS SLIDER
local SliderLabel = Instance.new("TextLabel", Content)
SliderLabel.Size = UDim2.new(0, 100, 0, 20)
SliderLabel.Position = UDim2.new(0, 14, 0, 78)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "CPS: 10"
SliderLabel.TextColor3 = Colors.text
SliderLabel.Font = Enum.Font.GothamBold
SliderLabel.TextSize = 12

local SliderTrack = Instance.new("Frame", Content)
SliderTrack.Size = UDim2.new(1, -80, 0, 5)
SliderTrack.Position = UDim2.new(0, 14, 0, 100)
SliderTrack.BackgroundColor3 = Colors.bg4
SliderTrack.BorderSizePixel = 0
ApplyRadius(SliderTrack, 3)

local SliderFill = Instance.new("Frame", SliderTrack)
SliderFill.Size = UDim2.new(0.1, 0, 1, 0)
SliderFill.BackgroundColor3 = Colors.accent
SliderFill.BorderSizePixel = 0
ApplyRadius(SliderFill, 3)

local SliderBtn = Instance.new("TextButton", SliderTrack)
SliderBtn.Size = UDim2.new(0, 14, 0, 14)
SliderBtn.Position = UDim2.new(0.1, -7, 0.5, -7)
SliderBtn.BackgroundColor3 = Colors.text
SliderBtn.Text = ""
SliderBtn.BorderSizePixel = 0
ApplyRadius(SliderBtn, 7)

-- MODE SWITCH
local ModeSwitch = Instance.new("TextButton", Content)
ModeSwitch.Size = UDim2.new(0, 90, 0, 26)
ModeSwitch.Position = UDim2.new(1, -100, 0, 44)
ModeSwitch.BackgroundColor3 = Colors.bg3
ModeSwitch.Text = "TOGGLE"
ModeSwitch.TextColor3 = Colors.text
ModeSwitch.Font = Enum.Font.GothamBold
ModeSwitch.TextSize = 10
ModeSwitch.BorderSizePixel = 0
ApplyRadius(ModeSwitch, 5)

-- PARRY TOGGLE
local ParryToggle = Instance.new("TextButton", Content)
ParryToggle.Size = UDim2.new(0, 90, 0, 26)
ParryToggle.Position = UDim2.new(1, -100, 0, 74)
ParryToggle.BackgroundColor3 = Colors.bg3
ParryToggle.Text = "PARRY: OFF"
ParryToggle.TextColor3 = Colors.textDim
ParryToggle.Font = Enum.Font.GothamBold
ParryToggle.TextSize = 10
ParryToggle.BorderSizePixel = 0
ApplyRadius(ParryToggle, 5)

-- ACTION BUTTON (Manual)
local ActionBtn = Instance.new("TextButton", Content)
ActionBtn.Size = UDim2.new(1, -20, 0, 44)
ActionBtn.Position = UDim2.new(0, 10, 0, 115)
ActionBtn.BackgroundColor3 = Colors.bg3
ActionBtn.Text = "🔴 HOLD TO SPAM"
ActionBtn.TextColor3 = Colors.text
ActionBtn.Font = Enum.Font.GothamBold
ActionBtn.TextSize = 14
ActionBtn.BorderSizePixel = 0
ApplyRadius(ActionBtn, 8)

-- TOGGLE BUTTON (hidden in manual mode)
local ToggleBtn = Instance.new("TextButton", Content)
ToggleBtn.Size = UDim2.new(1, -20, 0, 40)
ToggleBtn.Position = UDim2.new(0, 10, 0, 118)
ToggleBtn.BackgroundColor3 = Colors.bg3
ToggleBtn.Text = "▶ START"
ToggleBtn.TextColor3 = Colors.text
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 13
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Visible = false
ApplyRadius(ToggleBtn, 8)

-- CONSOLE
local Console = Instance.new("Frame", Content)
Console.Size = UDim2.new(1, -20, 0, 50)
Console.Position = UDim2.new(0, 10, 0, 170)
Console.BackgroundColor3 = Colors.bg2
Console.BorderSizePixel = 0
ApplyRadius(Console, 6)

local ConsoleText = Instance.new("TextLabel", Console)
ConsoleText.Size = UDim2.new(1, -16, 1, 0)
ConsoleText.Position = UDim2.new(0, 16, 0, 0)
ConsoleText.BackgroundTransparency = 1
ConsoleText.Text = "⚡ Thyren loaded | " .. EXECUTOR .. " | " .. GAME
ConsoleText.TextColor3 = Colors.textDim
ConsoleText.Font = Enum.Font.Code
ConsoleText.TextSize = 10
ConsoleText.TextXAlignment = Enum.TextXAlignment.Left
ConsoleText.TextYAlignment = Enum.TextYAlignment.Top
ConsoleText.LineHeight = 1.2

-- =============================================================================
-- SPAM ENGINE
-- =============================================================================

local function RunSpam()
    if not State.running then return end
    
    local speed = State.speed
    local key = State.spamKey
    
    if speed >= 60 then
        SendKey(key, true)
        SendKey(key, false)
        SendKey(key, true)
        SendKey(key, false)
    else
        local now = os.clock()
        if (now - State.lastFire) >= (1.0 / speed) then
            State.lastFire = now
            SendKey(key, true)
            SendKey(key, false)
        end
    end
end

local function StartSpam()
    State.running = true
    State.lastFire = os.clock()
    if State.macroConnection then State.macroConnection:Disconnect() end
    State.macroConnection = game:GetService("RunService").PreRender:Connect(RunSpam)
end

local function StopSpam()
    State.running = false
    if State.macroConnection then
        State.macroConnection:Disconnect()
        State.macroConnection = nil
    end
end

local function ToggleSpam()
    if State.running then StopSpam() else StartSpam() end
    UpdateUI()
end

-- =============================================================================
-- UI UPDATE
-- =============================================================================

local function UpdateUI()
    SliderLabel.Text = "CPS: " .. State.speed
    ModeBtn.Text = State.mode
    
    if State.running then
        StatusLabel.Text = "● RUNNING"
        StatusLabel.TextColor3 = Colors.error
        ActionBtn.Text = "🔴 RELEASE TO STOP"
        ActionBtn.BackgroundColor3 = Colors.error
        ToggleBtn.Text = "⏹ STOP"
        ToggleBtn.BackgroundColor3 = Colors.error
        ToggleBtn.TextColor3 = Colors.textBright
    else
        StatusLabel.Text = "● IDLE"
        StatusLabel.TextColor3 = Colors.textDim
        ActionBtn.Text = "🔴 HOLD TO SPAM"
        ActionBtn.BackgroundColor3 = Colors.bg3
        ToggleBtn.Text = "▶ START"
        ToggleBtn.BackgroundColor3 = Colors.bg3
        ToggleBtn.TextColor3 = Colors.text
    end
    
    local isManual = State.activation == "Manual"
    ActionBtn.Visible = isManual
    ToggleBtn.Visible = not isManual
    ModeSwitch.Text = isManual and "TOGGLE" or "MANUAL"
    ModeSwitch.BackgroundColor3 = isManual and Colors.bg3 or Colors.accent
end

-- =============================================================================
-- SLIDER LOGIC
-- =============================================================================

local isDragging = false

local function UpdateSlider(pos)
    local frac = math.clamp((pos.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
    local max = State.lowEnd and 200 or 2500
    local val = math.floor(1 + (frac * (max - 1)))
    State.speed = val
    SliderFill.Size = UDim2.new(frac, 0, 1, 0)
    SliderBtn.Position = UDim2.new(frac, -7, 0.5, -7)
    UpdateUI()
end

SliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateSlider(input)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        UpdateSlider(input)
    end
end)

-- =============================================================================
-- BUTTON EVENTS
-- =============================================================================

ModeBtn.MouseButton1Click:Connect(function()
    State.mode = State.mode == "KPS" and "CPS" or "KPS"
    UpdateUI()
end)

ActionBtn.MouseButton1Down:Connect(function()
    if State.activation == "Manual" then
        StartSpam()
        UpdateUI()
    end
end)

ActionBtn.MouseButton1Up:Connect(function()
    if State.activation == "Manual" then
        StopSpam()
        UpdateUI()
    end
end)

ActionBtn.MouseLeave:Connect(function()
    if State.activation == "Manual" and State.running then
        StopSpam()
        UpdateUI()
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if State.activation == "Toggle" then
        ToggleSpam()
    end
end)

ModeSwitch.MouseButton1Click:Connect(function()
    if State.running then StopSpam() end
    State.activation = State.activation == "Manual" and "Toggle" or "Manual"
    UpdateUI()
end)

ParryToggle.MouseButton1Click:Connect(function()
    State.autoParry = not State.autoParry
    ParryToggle.Text = State.autoParry and "PARRY: ON" or "PARRY: OFF"
    ParryToggle.TextColor3 = State.autoParry and Colors.success or Colors.textDim
    ConsoleText.Text = State.autoParry and "⚡ Parry enabled" or "⚡ Parry disabled"
end)

BindBtn.MouseButton1Click:Connect(function()
    State.binding = true
    BindBtn.Text = "..."
    BindBtn.BackgroundColor3 = Colors.warning
    ConsoleText.Text = "⚡ Press any key..."
end)

TitleLabel.MouseButton1Click:Connect(function()
    State.collapsed = not State.collapsed
    local size = State.collapsed and UDim2.new(0, 180, 0, 34) or UDim2.new(0, 460, 0, 340)
    Animate(Main, {Size = size})
    Content.Visible = not State.collapsed
end)

-- =============================================================================
-- KEYBIND
-- =============================================================================

game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if State.binding and input.KeyCode ~= Enum.KeyCode.Unknown then
        State.spamKey = input.KeyCode
        State.binding = false
        BindBtn.Text = "BIND"
        BindBtn.BackgroundColor3 = Colors.bg3
        KeyLabel.Text = "KEY: " .. input.KeyCode.Name
        ConsoleText.Text = "⚡ Bound to " .. input.KeyCode.Name
        return
    end
    
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        State.visible = not State.visible
        Main.Visible = State.visible
    end
    
    if State.activation == "Toggle" and input.KeyCode == State.spamKey then
        ToggleSpam()
    end
end)

-- =============================================================================
-- INIT
-- =============================================================================

UpdateUI()
ConsoleText.Text = "⚡ Thyren loaded | " .. EXECUTOR .. " | " .. GAME
print("◼ Thyren loaded!")
print("📌 Executor: " .. EXECUTOR)
print("📌 Game: " .. GAME)
print("📌 Mode: " .. State.mode)
print("📌 CPS: " .. State.speed)
print("📌 Key: " .. State.spamKey.Name)
print("📌 RightShift to toggle UI")
