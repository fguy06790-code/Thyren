-- Vaporwave Engine V6 - 1000 KPS Slider Update
local UIS = game:GetService("UserInputService")
local LP = game:GetService("Players").LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local SG = Instance.new("ScreenGui", PG)
SG.Name = "VaporwaveUI"

-- Main Frame
local MF = Instance.new("Frame", SG)
MF.Size = UDim2.new(0, 260, 0, 320)
MF.Position = UDim2.new(0.5, -130, 0.4, -160)
MF.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MF.BorderSizePixel = 0
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 12)

-- Start Button
local SB = Instance.new("TextButton", SG)
SB.Size = UDim2.new(0, 140, 0, 50)
SB.Position = UDim2.new(0.5, -70, 0.85, 0)
SB.Text = "START"
SB.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SB.TextColor3 = Color3.new(1, 1, 1)
SB.Font = Enum.Font.Code
Instance.new("UICorner", SB).CornerRadius = UDim.new(0, 8)

-- Slider UI (1-1000)
local SliderBg = Instance.new("Frame", MF)
SliderBg.Size = UDim2.new(0, 220, 0, 10)
SliderBg.Position = UDim2.new(0.5, -110, 0.7, 0)
SliderBg.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)

local SliderFill = Instance.new("Frame", SliderBg)
SliderFill.Size = UDim2.new(0.1, 0, 1, 0) -- Default
SliderFill.BackgroundColor3 = Color3.fromRGB(150, 50, 255)
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

local RateLabel = Instance.new("TextLabel", MF)
RateLabel.Size = UDim2.new(1, 0, 0, 30)
RateLabel.Position = UDim2.new(0, 0, 0.6, 0)
RateLabel.Text = "Rate: 100 KPS"
RateLabel.TextColor3 = Color3.new(1, 1, 1)
RateLabel.BackgroundTransparency = 1

local KPS = 100
SliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = (input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X
        KPS = math.floor(math.clamp(pos * 1000, 1, 1000))
        SliderFill.Size = UDim2.new(pos, 0, 1, 0)
        RateLabel.Text = "Rate: " .. KPS .. " KPS"
    end
end)

-- Placeholder logic
local state = { active = false }
SB.MouseButton1Down:Connect(function() state.active = true end)
SB.MouseButton1Up:Connect(function() state.active = false end)

task.spawn(function()
    while true do
        if state.active then
            -- Execution at KPS rate
            task.wait(1 / KPS)
        else
            task.wait(0.1)
        end
    end
end)
