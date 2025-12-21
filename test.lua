-- ═══════════════════════════════════════════════════════
--  UNIVERSAL UTILITY HUB - MODULAR VERSION
--  Compatible: Delta Executor | All Games/Maps
-- ═══════════════════════════════════════════════════════

local plr = game:GetService("Players").LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")

-- ═══════════════════════════════════════════════════════
--  MODULE: FEATURES
-- ═══════════════════════════════════════════════════════
local Features = {
    States = {
        speed = false,
        jump = false,
        noclip = false,
        fly = false,
        esp = false,
        fullbright = false,
        inf_jump = false
    },
    
    Values = {
        walkspeed = 16,
        jumppower = 50,
        flyspeed = 50,
        bodysize = {arm = 1, leg = 1, torso = 1}
    }
}

-- Speed Hack
function Features:ToggleSpeed(state)
    self.States.speed = state
    if state then
        hum.WalkSpeed = self.Values.walkspeed
    else
        hum.WalkSpeed = 16
    end
end

function Features:SetSpeed(value)
    self.Values.walkspeed = value
    if self.States.speed then
        hum.WalkSpeed = value
    end
end

-- Jump Power
function Features:ToggleJump(state)
    self.States.jump = state
    if state then
        hum.JumpPower = self.Values.jumppower
        if hum:FindFirstChild("UseJumpPower") then
            hum.UseJumpPower = true
        end
    else
        hum.JumpPower = 50
    end
end

function Features:SetJump(value)
    self.Values.jumppower = value
    if self.States.jump then
        hum.JumpPower = value
    end
end

-- Noclip
function Features:ToggleNoclip(state)
    self.States.noclip = state
end

rs.Stepped:Connect(function()
    if Features.States.noclip and char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

-- Fly
local flyBV, flyBG
function Features:ToggleFly(state)
    self.States.fly = state
    
    if state then
        local torso = char:FindFirstChild("HumanoidRootPart")
        if not torso then return end
        
        flyBV = Instance.new("BodyVelocity")
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Parent = torso
        
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.CFrame = torso.CFrame
        flyBG.Parent = torso
    else
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
    end
end

uis.InputBegan:Connect(function(input)
    if Features.States.fly then
        local torso = char:FindFirstChild("HumanoidRootPart")
        if not torso or not flyBV then return end
        
        local speed = Features.Values.flyspeed
        local cam = workspace.CurrentCamera
        
        if input.KeyCode == Enum.KeyCode.W then
            flyBV.Velocity = cam.CFrame.LookVector * speed
        elseif input.KeyCode == Enum.KeyCode.S then
            flyBV.Velocity = cam.CFrame.LookVector * -speed
        elseif input.KeyCode == Enum.KeyCode.A then
            flyBV.Velocity = cam.CFrame.RightVector * -speed
        elseif input.KeyCode == Enum.KeyCode.D then
            flyBV.Velocity = cam.CFrame.RightVector * speed
        elseif input.KeyCode == Enum.KeyCode.Space then
            flyBV.Velocity = Vector3.new(0, speed, 0)
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            flyBV.Velocity = Vector3.new(0, -speed, 0)
        end
    end
end)

uis.InputEnded:Connect(function()
    if Features.States.fly and flyBV then
        flyBV.Velocity = Vector3.new(0, 0, 0)
    end
end)

-- ESP (Player Highlight)
function Features:ToggleESP(state)
    self.States.esp = state
    
    if state then
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= plr and p.Character then
                local hl = Instance.new("Highlight")
                hl.Name = "ESP_Highlight"
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.Parent = p.Character
            end
        end
    else
        for _, p in pairs(game.Players:GetPlayers()) do
            if p.Character then
                local hl = p.Character:FindFirstChild("ESP_Highlight")
                if hl then hl:Destroy() end
            end
        end
    end
end

-- Fullbright
function Features:ToggleFullbright(state)
    self.States.fullbright = state
    local lighting = game:GetService("Lighting")
    
    if state then
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.FogEnd = 100000
        lighting.GlobalShadows = false
        lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        lighting.Brightness = 1
        lighting.ClockTime = 12
        lighting.FogEnd = 100000
        lighting.GlobalShadows = true
    end
end

-- Infinite Jump
function Features:ToggleInfJump(state)
    self.States.inf_jump = state
end

uis.JumpRequest:Connect(function()
    if Features.States.inf_jump and hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Body Size Glitch
function Features:ApplyBodyGlitch()
    local vals = self.Values.bodysize
    
    local leftArm = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftUpperArm")
    local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
    local leftLeg = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftUpperLeg")
    local rightLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightUpperLeg")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    
    if leftArm then leftArm.Size = Vector3.new(leftArm.Size.X, leftArm.Size.Y * vals.arm, leftArm.Size.Z) end
    if rightArm then rightArm.Size = Vector3.new(rightArm.Size.X, rightArm.Size.Y * vals.arm, rightArm.Size.Z) end
    if leftLeg then leftLeg.Size = Vector3.new(leftLeg.Size.X, leftLeg.Size.Y * vals.leg, leftLeg.Size.Z) end
    if rightLeg then rightLeg.Size = Vector3.new(rightLeg.Size.X, rightLeg.Size.Y * vals.leg, rightLeg.Size.Z) end
    if torso then torso.Size = torso.Size * vals.torso end
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("SpecialMesh") or part:IsA("CharacterMesh") then
            part:Destroy()
        end
    end
end

-- ═══════════════════════════════════════════════════════
--  MODULE: GUI
-- ═══════════════════════════════════════════════════════
local GUI = {}

function GUI:Create()
    local sg = Instance.new("ScreenGui")
    sg.Name = "UtilityHub"
    sg.Parent = game.CoreGui
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Parent = sg
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    main.BorderSizePixel = 0
    main.Position = UDim2.new(0.02, 0, 0.3, 0)
    main.Size = UDim2.new(0, 280, 0, 450)
    main.Active = true
    main.Draggable = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = main
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Parent = main
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Font = Enum.Font.GothamBold
    title.Text = "⚡ UTILITY HUB"
    title.TextColor3 = Color3.fromRGB(100, 200, 255)
    title.TextSize = 16
    
    -- Scroll Frame
    local scroll = Instance.new("ScrollingFrame")
    scroll.Parent = main
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.new(0, 10, 0, 40)
    scroll.Size = UDim2.new(1, -20, 1, -50)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
    scroll.ScrollBarThickness = 4
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = scroll
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    return sg, main, scroll
end

function GUI:CreateToggle(parent, text, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.Size = UDim2.new(1, 0, 0, 40)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton")
    btn.Parent = frame
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btn.Position = UDim2.new(1, -45, 0.5, -12)
    btn.Size = UDim2.new(0, 35, 0, 24)
    btn.Font = Enum.Font.GothamBold
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        btn.Text = state and "ON" or "OFF"
        callback(state)
    end)
    
    return frame
end

function GUI:CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.Size = UDim2.new(1, 0, 0, 55)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 10, 0, 5)
    label.Size = UDim2.new(1, -20, 0, 15)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local value = Instance.new("TextLabel")
    value.Parent = frame
    value.BackgroundTransparency = 1
    value.Position = UDim2.new(0, 10, 0, 25)
    value.Size = UDim2.new(1, -20, 0, 20)
    value.Font = Enum.Font.GothamBold
    value.Text = tostring(default)
    value.TextColor3 = Color3.fromRGB(100, 200, 255)
    value.TextSize = 14
    
    local minus = Instance.new("TextButton")
    minus.Parent = frame
    minus.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    minus.Position = UDim2.new(0, 10, 1, -22)
    minus.Size = UDim2.new(0, 30, 0, 20)
    minus.Font = Enum.Font.GothamBold
    minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(255, 255, 255)
    minus.TextSize = 16
    
    local minusCorner = Instance.new("UICorner")
    minusCorner.CornerRadius = UDim.new(0, 5)
    minusCorner.Parent = minus
    
    local plus = Instance.new("TextButton")
    plus.Parent = frame
    plus.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    plus.Position = UDim2.new(1, -40, 1, -22)
    plus.Size = UDim2.new(0, 30, 0, 20)
    plus.Font = Enum.Font.GothamBold
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(255, 255, 255)
    plus.TextSize = 16
    
    local plusCorner = Instance.new("UICorner")
    plusCorner.CornerRadius = UDim.new(0, 5)
    plusCorner.Parent = plus
    
    local current = default
    local step = (max - min) / 20
    
    minus.MouseButton1Click:Connect(function()
        current = math.max(min, current - step)
        value.Text = string.format("%.0f", current)
        callback(current)
    end)
    
    plus.MouseButton1Click:Connect(function()
        current = math.min(max, current + step)
        value.Text = string.format("%.0f", current)
        callback(current)
    end)
    
    return frame
end

function GUI:CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    
    return btn
end

-- ═══════════════════════════════════════════════════════
--  INITIALIZATION
-- ═══════════════════════════════════════════════════════
local sg, main, scroll = GUI:Create()

-- Movement Section
GUI:CreateToggle(scroll, "🏃 Speed Hack", function(s) Features:ToggleSpeed(s) end)
GUI:CreateSlider(scroll, "Speed Value", 16, 200, 16, function(v) Features:SetSpeed(v) end)

GUI:CreateToggle(scroll, "🦘 Jump Boost", function(s) Features:ToggleJump(s) end)
GUI:CreateSlider(scroll, "Jump Value", 50, 300, 50, function(v) Features:SetJump(v) end)

GUI:CreateToggle(scroll, "👻 Noclip", function(s) Features:ToggleNoclip(s) end)

GUI:CreateToggle(scroll, "✈️ Fly Mode", function(s) Features:ToggleFly(s) end)
GUI:CreateSlider(scroll, "Fly Speed", 10, 200, 50, function(v) Features.Values.flyspeed = v end)

GUI:CreateToggle(scroll, "♾️ Infinite Jump", function(s) Features:ToggleInfJump(s) end)

-- Visual Section
GUI:CreateToggle(scroll, "👁️ ESP (Highlight)", function(s) Features:ToggleESP(s) end)

GUI:CreateToggle(scroll, "💡 Fullbright", function(s) Features:ToggleFullbright(s) end)

-- Body Glitch Section
GUI:CreateSlider(scroll, "🦾 Arm Size", 0.5, 5, 1, function(v) Features.Values.bodysize.arm = v end)
GUI:CreateSlider(scroll, "🦵 Leg Size", 0.5, 5, 1, function(v) Features.Values.bodysize.leg = v end)
GUI:CreateSlider(scroll, "🫁 Torso Size", 0.5, 5, 1, function(v) Features.Values.bodysize.torso = v end)

GUI:CreateButton(scroll, "✨ Apply Body Glitch", function() Features:ApplyBodyGlitch() end)

-- Utility Section
GUI:CreateButton(scroll, "🔄 Reset Character", function()
    if hum then hum.Health = 0 end
end)

-- Close Button
local close = Instance.new("TextButton")
close.Parent = main
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Position = UDim2.new(1, -30, 0, 5)
close.Size = UDim2.new(0, 25, 0, 25)
close.Font = Enum.Font.GothamBold
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.TextSize = 14

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = close

close.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

-- Character Respawn Handler
plr.CharacterAdded:Connect(function(newChar)
    char = newChar
    hum = newChar:WaitForChild("Humanoid")
end)

print("✅ Universal Utility Hub Loaded!")
print("📌 Fitur: Speed, Jump, Noclip, Fly, ESP, Fullbright, Body Glitch")
print("🎮 Drag GUI untuk pindahkan posisi")
