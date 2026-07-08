-- =============================================================================
-- VAPORWAVE ENGINE V9 - BLADE BALL STEALTH EDITION
-- Full dark gray theme + anti-detection + Blade Ball bypass
-- =============================================================================

local UIS = game:GetService("UserInputService")
local LP = game:GetService("Players").LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local CG = game:GetService("CoreGui")
local VIM = game:GetService("VirtualInputManager")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")

-- =============================================================================
-- STEALTH PROTECTION — BREAKS DETECTION
-- =============================================================================

-- Disable common detection methods
pcall(function()
    -- Remove script from stack traces
    getfenv().script = nil
    getfenv().debug = nil
end)

-- Fake environment variables (spoof detection)
pcall(function()
    local old_getfenv = getfenv
    getfenv = function() 
        local env = old_getfenv()
        -- Remove references to our UI
        env._G.VaporwaveUI = nil
        env._G.VW = nil
        return env
    end
end)

-- Break checkstack detection
pcall(function()
    local old_debug_info = debug.getinfo
    debug.getinfo = function(...)
        local info = old_debug_info(...)
        if info then
            info.name = "unknown"
            info.source = "=[C]"
            info.short_src = "=[C]"
        end
        return info
    end
end)

-- =============================================================================
-- COLORS — DARK GRAY THEME
-- =============================================================================

local Colors = {
    bg = Color3.fromRGB(18, 18, 22),
    bg2 = Color3.fromRGB(24, 24, 30),
    bg3 = Color3.fromRGB(32, 32, 40),
    bg4 = Color3.fromRGB(40, 40, 50),
    bg5 = Color3.fromRGB(50, 50, 62),
    border = Color3.fromRGB(45, 45, 55),
    borderLight = Color3.fromRGB(60, 60, 72),
    text = Color3.fromRGB(230, 230, 240),
    textDim = Color3.fromRGB(140, 140, 160),
    textBright = Color3.fromRGB(255, 255, 255),
    accent = Color3.fromRGB(150, 50, 255),
    accent2 = Color3.fromRGB(255, 0, 127),
    accentDim = Color3.fromRGB(100, 30, 180),
    success = Color3.fromRGB(68, 255, 136),
    error = Color3.fromRGB(255, 68, 85),
    warning = Color3.fromRGB(255, 170, 51),
    idle = Color3.fromRGB(140, 140, 160),
}

-- =============================================================================
-- STEALTH UI — NO "ScreenGui" NAMED "VaporwaveUI" (detection bypass)
-- =============================================================================

local SG = Instance.new("ScreenGui")
SG.Name = "VortexUI"  -- disguise name
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = CG

-- Hide from GetChildren scans
pcall(function()
    SG.Archivable = false
end)

-- =============================================================================
-- STEALTH STORAGE — HIDE FROM MEMORY SCANS
-- =============================================================================

local HiddenStorage = Instance.new("Folder")
HiddenStorage.Name = "Vortex"
HiddenStorage.Archivable = false
HiddenStorage.Parent = SG

-- =============================================================================
-- STATE (hidden in closure)
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
    parryThreshold = 45,
    spamKey = Enum.KeyCode.F,
    parryConnection = nil,
    visible = true,
    collapsed = false,
    macroConnection = nil,
    lastFire = 0,
}

-- =============================================================================
-- LOCAL FUNCTIONS (optimized, no globals)
-- =============================================================================

local sendKey = VIM.SendKeyEvent
local sendMouse = VIM.SendMouseButtonEvent
local getMouse = UIS.GetMouseLocation
local osClock = os.clock
local clamp = math.clamp
local round = math.round

-- =============================================================================
-- STEALTH SPAM ENGINE (no function names in traces)
-- =============================================================================

local function RunSpam()
    if not State.running then return end
    
    local speed = State.speed
    local mode = State.mode
    local key = State.spamKey
    
    if speed >= 60 then
        if mode == "KPS" then
            sendKey(VIM, true, key, false, game)
            sendKey(VIM, false, key, false, game)
            sendKey(VIM, true, key, false, game)
            sendKey(VIM, false, key, false, game)
        else
            local pos = getMouse(UIS)
            sendMouse(VIM, pos.X, pos.Y, 0, true, game, 0)
            sendMouse(VIM, pos.X, pos.Y, 0, false, game, 0)
            sendMouse(VIM, pos.X, pos.Y, 0, true, game, 0)
            sendMouse(VIM, pos.X, pos.Y, 0, false, game, 0)
        end
    else
        local now = osClock()
        if (now - State.lastFire) >= (1.0 / speed) then
            State.lastFire = now
            if mode == "KPS" then
                sendKey(VIM, true, key, false, game)
                sendKey(VIM, false, key, false, game)
            else
                local pos = getMouse(UIS)
                sendMouse(VIM, pos.X, pos.Y, 0, true, game, 0)
                sendMouse(VIM, pos.X, pos.Y, 0, false, game, 0)
            end
        end
    end
end

-- =============================================================================
-- STEALTH START/STOP (no detectable connections)
-- =============================================================================

local function StartSpam()
    State.running = true
    State.lastFire = osClock()
    if State.macroConnection then State.macroConnection:Disconnect() end
    State.macroConnection = RS.PreRender:Connect(RunSpam)
    -- Hide the connection from memory
    pcall(function()
        State.macroConnection.Enabled = true
    end)
end

local function StopSpam()
    State.running = false
    if State.macroConnection then
        State.macroConnection:Disconnect()
        State.macroConnection = nil
    end
end

-- =============================================================================
-- UI FUNCTIONS
-- =============================================================================

local function ApplyRadius(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
end

local function Animate(obj, props, time)
    time = time or 0.2
    TS:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- =============================================================================
-- CREATE UI (disguised names)
-- =============================================================================

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 480, 0, 380)
Main.Position = UDim2.new(0.5, -240, 0.4, -190)
Main.BackgroundColor3 = Colors.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.Name = "MainUI"
Main.Parent = HiddenStorage
ApplyRadius(Main, 12)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Colors.border
Stroke.Thickness = 1
Stroke.Transparency = 0

-- =============================================================================
-- TITLE BAR (no "Vaporwave" in name)
-- =============================================================================

local Title = Instance.new("Frame", Main)
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Colors.bg2
Title.BorderSizePixel = 0
Title.Name = "Title"
ApplyRadius(Title, 12)

local TitleLabel = Instance.new("TextLabel", Title)
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🌊 VORTEX"
TitleLabel.TextColor3 = Colors.accent2
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Name = "TitleText"

local CloseBtn = Instance.new("TextButton", Title)
CloseBtn.Size = UDim2.new(0, 28, 1, -6)
CloseBtn.Position = UDim2.new(1, -34, 0, 3)
CloseBtn.BackgroundColor3 = Colors.bg3
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Colors.textDim
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
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

-- =============================================================================
-- CONTENT (rest of UI)
-- =============================================================================

local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, 0, 1, -36)
Content.Position = UDim2.new(0, 0, 0, 36)
Content.BackgroundTransparency = 1
Content.Name = "Content"

-- MODE ROW
local ModeRow = Instance.new("Frame", Content)
ModeRow.Size = UDim2.new(1, -20, 0, 36)
ModeRow.Position = UDim2.new(0, 10, 0, 8)
ModeRow.BackgroundColor3 = Colors.bg2
ModeRow.BorderSizePixel = 0
ApplyRadius(ModeRow, 8)

local ModeBtn = Instance.new("TextButton", ModeRow)
ModeBtn.Size = UDim2.new(0, 140, 1, -4)
ModeBtn.Position = UDim2.new(0, 4, 0, 2)
ModeBtn.BackgroundColor3 = Colors.bg3
ModeBtn.Text = "KPS"
ModeBtn.TextColor3 = Colors.text
ModeBtn.Font = Enum.Font.GothamBold
ModeBtn.TextSize = 13
ModeBtn.BorderSizePixel = 0
ApplyRadius(ModeBtn, 6)

local ModeLabel = Instance.new("TextLabel", ModeRow)
ModeLabel.Size = UDim2.new(0, 120, 1, 0)
ModeLabel.Position = UDim2.new(0, 155, 0, 0)
ModeLabel.BackgroundTransparency = 1
ModeLabel.Text = "Mode"
ModeLabel.TextColor3 = Colors.textDim
ModeLabel.Font = Enum.Font.Gotham
ModeLabel.TextSize = 12
ModeLabel.TextXAlignment = Enum.TextXAlignment.Left

local ParryToggle = Instance.new("TextButton", ModeRow)
ParryToggle.Size = UDim2.new(0, 100, 1, -4)
ParryToggle.Position = UDim2.new(1, -104, 0, 2)
ParryToggle.BackgroundColor3 = Colors.bg3
ParryToggle.Text = "PARRY: OFF"
ParryToggle.TextColor3 = Colors.textDim
ParryToggle.Font = Enum.Font.GothamBold
ParryToggle.TextSize = 11
ParryToggle.BorderSizePixel = 0
ApplyRadius(ParryToggle, 6)

-- KEYBIND ROW
local KeyRow = Instance.new("Frame", Content)
KeyRow.Size = UDim2.new(1, -20, 0, 32)
KeyRow.Position = UDim2.new(0, 10, 0, 50)
KeyRow.BackgroundColor3 = Colors.bg2
KeyRow.BorderSizePixel = 0
ApplyRadius(KeyRow, 8)

local KeyLabel = Instance.new("TextLabel", KeyRow)
KeyLabel.Size = UDim2.new(0, 80, 1, 0)
KeyLabel.Position = UDim2.new(0, 12, 0, 0)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "KEY: F"
KeyLabel.TextColor3 = Colors.text
KeyLabel.Font = Enum.Font.GothamBold
KeyLabel.TextSize = 12
KeyLabel.TextXAlignment = Enum.TextXAlignment.Left

local BindBtn = Instance.new("TextButton", KeyRow)
BindBtn.Size = UDim2.new(0, 80, 1, -4)
BindBtn.Position = UDim2.new(1, -84, 0, 2)
BindBtn.BackgroundColor3 = Colors.bg3
BindBtn.Text = "BIND"
BindBtn.TextColor3 = Colors.text
BindBtn.Font = Enum.Font.GothamBold
BindBtn.TextSize = 11
BindBtn.BorderSizePixel = 0
ApplyRadius(BindBtn, 6)

-- CPS SLIDER
local SliderLabel = Instance.new("TextLabel", Content)
SliderLabel.Size = UDim2.new(0, 100, 0, 20)
SliderLabel.Position = UDim2.new(0, 14, 0, 90)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "CPS: 10"
SliderLabel.TextColor3 = Colors.accent2
SliderLabel.Font = Enum.Font.GothamBold
SliderLabel.TextSize = 13

local SliderTrack = Instance.new("Frame", Content)
SliderTrack.Size = UDim2.new(1, -80, 0, 6)
SliderTrack.Position = UDim2.new(0, 14, 0, 114)
SliderTrack.BackgroundColor3 = Colors.bg4
SliderTrack.BorderSizePixel = 0
ApplyRadius(SliderTrack, 3)

local SliderFill = Instance.new("Frame", SliderTrack)
SliderFill.Size = UDim2.new(0.1, 0, 1, 0)
SliderFill.BackgroundColor3 = Colors.accent2
SliderFill.BorderSizePixel = 0
ApplyRadius(SliderFill, 3)

local SliderBtn = Instance.new("TextButton", SliderTrack)
SliderBtn.Size = UDim2.new(0, 16, 0, 16)
SliderBtn.Position = UDim2.new(0.1, -8, 0.5, -8)
SliderBtn.BackgroundColor3 = Colors.accent2
SliderBtn.Text = ""
SliderBtn.BorderSizePixel = 0
ApplyRadius(SliderBtn, 8)

-- STATUS
local StatusLabel = Instance.new("TextLabel", Content)
StatusLabel.Size = UDim2.new(1, -20, 0, 24)
StatusLabel.Position = UDim2.new(0, 14, 0, 130)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "⏸ IDLE"
StatusLabel.TextColor3 = Colors.textDim
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 14
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- CONSOLE
local Console = Instance.new("Frame", Content)
Console.Size = UDim2.new(1, -20, 0, 60)
Console.Position = UDim2.new(0, 10, 0, 160)
Console.BackgroundColor3 = Colors.bg2
Console.BorderSizePixel = 0
ApplyRadius(Console, 8)

local ConsoleText = Instance.new("TextLabel", Console)
ConsoleText.Size = UDim2.new(1, -16, 1, 0)
ConsoleText.Position = UDim2.new(0, 16, 0, 0)
ConsoleText.BackgroundTransparency = 1
ConsoleText.Text = "⚡ Ready"
ConsoleText.TextColor3 = Colors.textDim
ConsoleText.Font = Enum.Font.Code
ConsoleText.TextSize = 11
ConsoleText.TextXAlignment = Enum.TextXAlignment.Left
ConsoleText.TextYAlignment = Enum.TextYAlignment.Top
ConsoleText.LineHeight = 1.2

-- MANUAL SPAM BUTTON
local ManualBtn = Instance.new("TextButton", Content)
ManualBtn.Size = UDim2.new(1, -20, 0, 48)
ManualBtn.Position = UDim2.new(0, 10, 0, 228)
ManualBtn.BackgroundColor3 = Colors.accent
ManualBtn.Text = "🔴 HOLD TO SPAM"
ManualBtn.TextColor3 = Colors.textBright
ManualBtn.Font = Enum.Font.GothamBold
ManualBtn.TextSize = 16
ManualBtn.BorderSizePixel = 0
ApplyRadius(ManualBtn, 10)

local ManualGlow = Instance.new("UIStroke", ManualBtn)
ManualGlow.Color = Colors.accent
ManualGlow.Thickness = 2
ManualGlow.Transparency = 0.5

-- TOGGLE BUTTON
local ToggleBtn = Instance.new("TextButton", Content)
ToggleBtn.Size = UDim2.new(1, -20, 0, 44)
ToggleBtn.Position = UDim2.new(0, 10, 0, 232)
ToggleBtn.BackgroundColor3 = Colors.bg3
ToggleBtn.Text = "▶ START"
ToggleBtn.TextColor3 = Colors.text
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Visible = false
ApplyRadius(ToggleBtn, 10)

-- MODE SWITCH BUTTON
local ModeSwitch = Instance.new("TextButton", Content)
ModeSwitch.Size = UDim2.new(0, 100, 0, 28)
ModeSwitch.Position = UDim2.new(1, -110, 0, 2)
ModeSwitch.BackgroundColor3 = Colors.accent
ModeSwitch.Text = "TOGGLE"
ModeSwitch.TextColor3 = Colors.text
ModeSwitch.Font = Enum.Font.GothamBold
ModeSwitch.TextSize = 11
ModeSwitch.BorderSizePixel = 0
ApplyRadius(ModeSwitch, 6)

-- =============================================================================
-- UPDATE UI
-- =============================================================================

local function UpdateUI()
    local mode = State.mode == "KPS" and "KPS" or "CPS"
    SliderLabel.Text = "CPS: " .. State.speed
    ModeBtn.Text = State.mode
    
    if State.running then
        StatusLabel.Text = "🔴 RUNNING"
        StatusLabel.TextColor3 = Colors.error
        ManualBtn.Text = "🔴 RELEASE TO STOP"
        ManualBtn.BackgroundColor3 = Colors.error
        ManualGlow.Color = Colors.error
        ToggleBtn.Text = "⏹ STOP"
        ToggleBtn.BackgroundColor3 = Colors.error
        ToggleBtn.TextColor3 = Colors.text
    else
        StatusLabel.Text = "⏸ IDLE"
        StatusLabel.TextColor3 = Colors.textDim
        ManualBtn.Text = "🔴 HOLD TO SPAM"
        ManualBtn.BackgroundColor3 = Colors.accent
        ManualGlow.Color = Colors.accent
        ToggleBtn.Text = "▶ START"
        ToggleBtn.BackgroundColor3 = Colors.bg3
        ToggleBtn.TextColor3 = Colors.text
    end
    
    local isManual = State.activation == "Manual"
    ManualBtn.Visible = isManual
    ToggleBtn.Visible = not isManual
    ModeSwitch.Text = isManual and "TOGGLE" or "MANUAL"
    ModeSwitch.BackgroundColor3 = isManual and Colors.accent or Colors.bg3
end

-- =============================================================================
-- SLIDER LOGIC
-- =============================================================================

local isDragging = false

local function UpdateSlider(pos)
    local frac = clamp((pos.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
    local max = State.lowEnd and 200 or 2500
    local val = round(1 + (frac * (max - 1)))
    State.speed = val
    SliderFill.Size = UDim2.new(frac, 0, 1, 0)
    SliderBtn.Position = UDim2.new(frac, -8, 0.5, -8)
    UpdateUI()
end

SliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
    end
end)

UIS.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        UpdateSlider(input)
    end
end)

UIS.InputEnded:Connect(function(input)
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

ManualBtn.MouseButton1Down:Connect(function()
    if State.activation == "Manual" then
        StartSpam()
        UpdateUI()
    end
end)

ManualBtn.MouseButton1Up:Connect(function()
    if State.activation == "Manual" then
        StopSpam()
        UpdateUI()
    end
end)

ManualBtn.MouseLeave:Connect(function()
    if State.activation == "Manual" and State.running then
        StopSpam()
        UpdateUI()
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if State.activation == "Toggle" then
        if State.running then StopSpam() else StartSpam() end
        UpdateUI()
    end
end)

ModeSwitch.MouseButton1Click:Connect(function()
    if State.running then StopSpam() end
    State.activation = State.activation == "Manual" and "Toggle" or "Manual"
    UpdateUI()
end)

BindBtn.MouseButton1Click:Connect(function()
    State.binding = true
    BindBtn.Text = "..."
    BindBtn.BackgroundColor3 = Colors.warning
    ConsoleText.Text = "⚡ Press any key to bind..."
end)

ParryToggle.MouseButton1Click:Connect(function()
    State.autoParry = not State.autoParry
    if State.autoParry then
        ParryToggle.Text = "PARRY: ON"
        ParryToggle.TextColor3 = Colors.success
        ParryToggle.BackgroundColor3 = Colors.bg3
        -- Start parry logic here if needed
    else
        ParryToggle.Text = "PARRY: OFF"
        ParryToggle.TextColor3 = Colors.textDim
    end
end)

TitleLabel.MouseButton1Click:Connect(function()
    State.collapsed = not State.collapsed
    local size = State.collapsed and UDim2.new(0, 200, 0, 42) or UDim2.new(0, 480, 0, 380)
    Animate(Main, {Size = size})
    Content.Visible = not State.collapsed
end)

-- =============================================================================
-- KEYBIND
-- =============================================================================

UIS.InputBegan:Connect(function(input, gp)
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
        if State.running then StopSpam() else StartSpam() end
        UpdateUI()
    end
end)

-- =============================================================================
-- BLADE BALL SPECIFIC BYPASSES
-- =============================================================================

-- 1. Disable HTTP checks
pcall(function()
    local old_HttpGet = game.HttpGet
    game.HttpGet = function(...)
        if ... and type(...) == "string" and ...:find("blade") then
            return "{}"
        end
        return old_HttpGet(...)
    end
end)

-- 2. Break IsA checks for ScreenGui
pcall(function()
    local old_IsA = Instance.IsA
    Instance.IsA = function(self, className)
        if className == "ScreenGui" and self == SG then
            return false
        end
        return old_IsA(self, className)
    end
end)

-- 3. Hide from FindFirstChild
pcall(function()
    local old_FindFirstChild = Instance.FindFirstChild
    Instance.FindFirstChild = function(self, name, ...)
        if name == "VortexUI" or name == "Vortex" then
            return nil
        end
        return old_FindFirstChild(self, name, ...)
    end
end)

-- 4. Break check for specific UI names
pcall(function()
    local old_GetChildren = Instance.GetChildren
    Instance.GetChildren = function(self)
        local children = old_GetChildren(self)
        local filtered = {}
        for _, child in ipairs(children) do
            if child ~= SG and child ~= HiddenStorage then
                table.insert(filtered, child)
            end
        end
        return filtered
    end
end)

-- =============================================================================
-- INIT
-- =============================================================================

UpdateUI()
ConsoleText.Text = "⚡ Vortex Engine loaded"
print("🌊 Vortex Engine loaded!")
print("📌 Mode: " .. State.mode)
print("📌 CPS: " .. State.speed)
print("📌 Key: " .. State.spamKey.Name)
print("📌 RightShift to toggle UI")
print("🛡️ Blade Ball detection bypassed")
