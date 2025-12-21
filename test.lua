-- Auto Teleport Script untuk Christmas Cave
-- Support Android & Delta Executor
-- Optimized untuk Mobile

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Auto Teleport", "DarkTheme")

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local ConfigFile = "AutoTeleportConfig.json"

-- Default Config
local Config = {
    enabled = false,
    startCoords = nil,
    targetCoords = nil,
    waitTime = 35 * 60,
    schedule = {
        ["11:00"] = true,
        ["13:00"] = true,
        ["15:00"] = true,
        ["17:00"] = true,
        ["19:00"] = true,
        ["21:00"] = true,
        ["23:00"] = true,
        ["01:00"] = true,
        ["03:00"] = true,
        ["05:00"] = true,
        ["07:00"] = true,
        ["09:00"] = true,
    },
    floatingButtonPos = {X = 0.85, Y = 0.05}
}

-- Create Floating Button (Touch-friendly untuk Android)
local ScreenGui = Instance.new("ScreenGui")
local FloatingButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")

ScreenGui.Name = "FloatingMenu"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999

FloatingButton.Name = "FloatingButton"
FloatingButton.Parent = ScreenGui
FloatingButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
FloatingButton.Position = UDim2.new(Config.floatingButtonPos.X, 0, Config.floatingButtonPos.Y, 0)
FloatingButton.Size = UDim2.new(0, 100, 0, 50) -- Lebih besar untuk Android
FloatingButton.Font = Enum.Font.GothamBold
FloatingButton.Text = "⚙️\nMENU"
FloatingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingButton.TextSize = 14
FloatingButton.AutoButtonColor = false
FloatingButton.ZIndex = 999

UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = FloatingButton

UIStroke.Color = Color3.fromRGB(100, 100, 255)
UIStroke.Thickness = 2.5
UIStroke.Parent = FloatingButton

-- Dragging System untuk Touch (Android)
local dragging = false
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    FloatingButton.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
    
    -- Save position
    Config.floatingButtonPos.X = FloatingButton.Position.X.Scale
    Config.floatingButtonPos.Y = FloatingButton.Position.Y.Scale
    SaveConfig()
end

FloatingButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = FloatingButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

FloatingButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        update(dragInput)
    end
end)

-- GUI Visibility Toggle
local isMinimized = true
local MainUIObject = nil

-- Wait for MainUI to load
task.wait(1)
for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
    if v.Name == "MainUI" or v:FindFirstChild("Main") then
        MainUIObject = v
        break
    end
end

FloatingButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if MainUIObject then
        MainUIObject.Enabled = not isMinimized
        if isMinimized then
            FloatingButton.Text = "⚙️\nMENU"
            FloatingButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            UIStroke.Color = Color3.fromRGB(100, 100, 255)
        else
            FloatingButton.Text = "❌\nCLOSE"
            FloatingButton.BackgroundColor3 = Color3.fromRGB(45, 35, 35)
            UIStroke.Color = Color3.fromRGB(255, 100, 100)
        end
    end
end)

-- Load Config
local function LoadConfig()
    local success, data = pcall(function()
        return readfile(ConfigFile)
    end)
    if success and data then
        local decoded = HttpService:JSONDecode(data)
        for k, v in pairs(decoded) do
            Config[k] = v
        end
        print("✅ Config loaded!")
        return true
    end
    return false
end

-- Save Config
local function SaveConfig()
    pcall(function()
        local encoded = HttpService:JSONEncode(Config)
        writefile(ConfigFile, encoded)
    end)
end

-- Teleport Function (Fixed untuk Android)
local function TeleportTo(position)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Disable collision sementara
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    hrp.CFrame = CFrame.new(position)
    task.wait(0.1)
    
    -- Re-enable collision
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = true
        end
    end
    
    return true
end

-- Smooth Teleport
local function SmoothTeleport(position)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local tweenInfo = TweenInfo.new(
        1.5,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut
    )
    
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(position)})
    tween:Play()
    tween.Completed:Wait()
    
    return true
end

-- Get Current Time
local function GetCurrentTime()
    local time = os.date("*t")
    return string.format("%02d:%02d", time.hour, time.min)
end

-- Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Teleport")

-- Status Label
local StatusLabel = MainSection:NewLabel("Status: Idle")

-- Info
local InfoSection = MainTab:NewSection("Info")
InfoSection:NewLabel("Tap floating button untuk hide/show")
InfoSection:NewLabel("Hold & drag untuk pindahkan button")

-- Toggle Auto Teleport
MainSection:NewToggle("Enable Auto Teleport", "Aktifkan auto teleport", function(state)
    Config.enabled = state
    SaveConfig()
    StatusLabel:UpdateLabel(state and "Status: Running" or "Status: Stopped")
end)

-- Save Positions
MainSection:NewButton("📍 Save Start Position", "Simpan posisi awal", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        Config.startCoords = {X = pos.X, Y = pos.Y, Z = pos.Z}
        SaveConfig()
        StatusLabel:UpdateLabel("✅ Start Position Saved!")
        task.wait(2)
        StatusLabel:UpdateLabel("Status: " .. (Config.enabled and "Running" or "Idle"))
    else
        StatusLabel:UpdateLabel("❌ Character not found!")
        task.wait(2)
        StatusLabel:UpdateLabel("Status: Idle")
    end
end)

MainSection:NewButton("🎯 Save Target Position", "Simpan posisi tujuan", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        Config.targetCoords = {X = pos.X, Y = pos.Y, Z = pos.Z}
        SaveConfig()
        StatusLabel:UpdateLabel("✅ Target Position Saved!")
        task.wait(2)
        StatusLabel:UpdateLabel("Status: " .. (Config.enabled and "Running" or "Idle"))
    else
        StatusLabel:UpdateLabel("❌ Character not found!")
        task.wait(2)
        StatusLabel:UpdateLabel("Status: Idle")
    end
end)

-- Wait Time Slider
MainSection:NewSlider("Wait Time (Minutes)", "Waktu tunggu", 60, 1, function(value)
    Config.waitTime = value * 60
    SaveConfig()
end)

-- Player Teleport Tab
local PlayerTab = Window:NewTab("Players")
local PlayerSection = PlayerTab:NewSection("Teleport ke Player")

local PlayerList = {}
local SelectedPlayer = nil

-- Refresh Player List
local function RefreshPlayers()
    PlayerList = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(PlayerList, player.Name)
        end
    end
    return PlayerList
end

-- Refresh Button
PlayerSection:NewButton("🔄 Refresh List", "Update daftar player", function()
    local players = RefreshPlayers()
    StatusLabel:UpdateLabel("Found " .. #players .. " players")
    task.wait(1.5)
    StatusLabel:UpdateLabel("Status: " .. (Config.enabled and "Running" or "Idle"))
end)

-- Player Dropdown
PlayerSection:NewDropdown("Select Player", "Pilih player", RefreshPlayers(), function(selected)
    SelectedPlayer = selected
end)

-- Teleport to Player
PlayerSection:NewButton("🚀 Teleport", "TP ke player", function()
    if not SelectedPlayer then
        StatusLabel:UpdateLabel("❌ Pilih player dulu!")
        task.wait(2)
        StatusLabel:UpdateLabel("Status: " .. (Config.enabled and "Running" or "Idle"))
        return
    end
    
    local player = Players:FindFirstChild(SelectedPlayer)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local pos = player.Character.HumanoidRootPart.Position
        if TeleportTo(pos) then
            StatusLabel:UpdateLabel("✅ TP to " .. SelectedPlayer)
        else
            StatusLabel:UpdateLabel("❌ TP Failed!")
        end
        task.wait(2)
        StatusLabel:UpdateLabel("Status: " .. (Config.enabled and "Running" or "Idle"))
    else
        StatusLabel:UpdateLabel("❌ Player not found!")
        task.wait(2)
        StatusLabel:UpdateLabel("Status: " .. (Config.enabled and "Running" or "Idle"))
    end
end)

-- Schedule Tab
local ScheduleTab = Window:NewTab("Schedule")
local ScheduleSection = ScheduleTab:NewSection("Jadwal Teleport")

local times = {"11:00", "13:00", "15:00", "17:00", "19:00", "21:00", "23:00", "01:00", "03:00", "05:00", "07:00", "09:00"}

for _, time in ipairs(times) do
    ScheduleSection:NewToggle(time, "Aktifkan jam " .. time, function(state)
        Config.schedule[time] = state
        SaveConfig()
    end)
end

-- Info Tab
local InfoTab = Window:NewTab("Info")
local InfoTabSection = InfoTab:NewSection("Cara Pakai")
InfoTabSection:NewLabel("1. Pergi ke posisi awal (Fish Island)")
InfoTabSection:NewLabel("2. Klik 'Save Start Position'")
InfoTabSection:NewLabel("3. Pergi ke posisi tujuan (Store)")
InfoTabSection:NewLabel("4. Klik 'Save Target Position'")
InfoTabSection:NewLabel("5. Atur jadwal di tab Schedule")
InfoTabSection:NewLabel("6. Enable Auto Teleport")
InfoTabSection:NewLabel("")
InfoTabSection:NewLabel("Script akan auto TP sesuai jadwal!")

-- Load Config on Start
LoadConfig()

-- Restore floating button position
if Config.floatingButtonPos then
    FloatingButton.Position = UDim2.new(Config.floatingButtonPos.X, 0, Config.floatingButtonPos.Y, 0)
end

-- Main Loop (Optimized)
local lastTeleportTime = 0
local isAtTarget = false
local hasExecutedThisHour = false
local lastCheckedHour = ""

task.spawn(function()
    while task.wait(1) do
        if not Config.enabled or not Config.startCoords or not Config.targetCoords then
            continue
        end
        
        local currentTime = tick()
        local currentHour = GetCurrentTime()
        
        -- Reset execution flag saat jam berganti
        if currentHour ~= lastCheckedHour then
            hasExecutedThisHour = false
            lastCheckedHour = currentHour
        end
        
        local shouldTeleport = Config.schedule[currentHour:sub(1, 5)] == true
        
        -- Teleport ke target (hanya sekali per jam)
        if shouldTeleport and not isAtTarget and not hasExecutedThisHour then
            StatusLabel:UpdateLabel("🚀 Teleporting to target...")
            local targetPos = Vector3.new(Config.targetCoords.X, Config.targetCoords.Y, Config.targetCoords.Z)
            
            if SmoothTeleport(targetPos) then
                isAtTarget = true
                hasExecutedThisHour = true
                lastTeleportTime = currentTime
                StatusLabel:UpdateLabel("✅ At target. Waiting " .. math.floor(Config.waitTime/60) .. " min")
            else
                StatusLabel:UpdateLabel("❌ Teleport failed!")
            end
        end
        
        -- Teleport kembali ke start
        if isAtTarget and (currentTime - lastTeleportTime) >= Config.waitTime then
            StatusLabel:UpdateLabel("🏠 Returning to start...")
            local startPos = Vector3.new(Config.startCoords.X, Config.startCoords.Y, Config.startCoords.Z)
            
            if SmoothTeleport(startPos) then
                isAtTarget = false
                lastTeleportTime = currentTime
                StatusLabel:UpdateLabel("✅ Back at start!")
                task.wait(2)
                StatusLabel:UpdateLabel("Status: Waiting for schedule...")
            else
                StatusLabel:UpdateLabel("❌ Return failed!")
            end
        end
        
        -- Update countdown
        if isAtTarget then
            local timeLeft = Config.waitTime - (currentTime - lastTeleportTime)
            if timeLeft > 0 then
                local minutes = math.floor(timeLeft / 60)
                local seconds = math.floor(timeLeft % 60)
                StatusLabel:UpdateLabel(string.format("⏱️ %02d:%02d", minutes, seconds))
            end
        end
    end
end)

-- Start minimized
task.wait(1.5)
if MainUIObject then
    MainUIObject.Enabled = false
    isMinimized = true
end

print("✅ Auto Teleport Script Loaded!")
print("📱 Optimized untuk Android")
print("⚙️ Tap floating button untuk buka menu")
print("👆 Hold & drag untuk pindahkan button")
