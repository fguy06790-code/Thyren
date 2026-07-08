-- Vaporwave Engine v3.0 - Roblox
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Main GUI
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 260, 0, 220)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -110)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

-- Seperate Start Button
local StartButton = Instance.new("TextButton", ScreenGui)
StartButton.Size = UDim2.new(0, 120, 0, 50)
StartButton.Position = UDim2.new(0.8, 0, 0.8, 0)
StartButton.Text = "START"
StartButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
StartButton.TextColor3 = Color3.new(1, 1, 1)

-- Switch Button (Mode)
local ModeBtn = Instance.new("TextButton", MainFrame)
ModeBtn.Size = UDim2.new(0, 240, 0, 40)
ModeBtn.Position = UDim2.new(0.5, -120, 0.2, 0)
ModeBtn.Text = "Mode: Hold-to-Start"

-- Bind Button
local BindBtn = Instance.new("TextButton", MainFrame)
BindBtn.Size = UDim2.new(0, 240, 0, 40)
BindBtn.Position = UDim2.new(0.5, -120, 0.6, 0)
BindBtn.Text = "Click to Bind Toggle"

local mode = "hold" -- hold or toggle
local bindKey = Enum.KeyCode.F
local active = false
local binding = false

ModeBtn.MouseButton1Click:Connect(function()
    mode = (mode == "hold" and "toggle" or "hold")
    ModeBtn.Text = "Mode: " .. (mode == "hold" and "Hold-to-Start" or "Toggle-Key-Bind")
end)

BindBtn.MouseButton1Click:Connect(function()
    binding = true
    BindBtn.Text = "Press a key..."
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if binding then
        bindKey = input.KeyCode
        BindBtn.Text = "Bound to: " .. bindKey.Name
        binding = false
        return
    end
    if mode == "toggle" and input.KeyCode == bindKey then
        active = not active
    end
end)

StartButton.MouseButton1Down:Connect(function()
    if mode == "hold" then active = true end
end)

StartButton.MouseButton1Up:Connect(function()
    if mode == "hold" then active = false end
end)

task.spawn(function()
    while true do
        if active then
            -- Execution logic
            print("Action triggered")
        end
        task.wait(0.05)
    end
end)

-- Filler
for i = 1, 200 do local x = 0 end
