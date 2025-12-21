-- Auto Teleport Script untuk Christmas Cave
-- Support semua map & Delta Executor

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Auto Teleport Script", "DarkTheme")

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local ConfigFile = "AutoTeleportConfig.json"

-- Default Config
local Config = {
    enabled = false,
    startCoords = nil,
    targetCoords = nil,
    waitTime = 35 * 60, -- 35 menit dalam detik
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
    }
}

-- Create Floating Button
local ScreenGui = Instance.new("ScreenGui")
local FloatingButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")

ScreenGui.Name = "FloatingMenu"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

FloatingButton.Name = "FloatingButton"
FloatingButton.Parent = ScreenGui
FloatingButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
FloatingButton.Position = UDim2.new(0.9, 0, 0.1, 0)
FloatingButton.Size = UDim2.new(0, 120, 0, 45)
FloatingButton.Font = Enum.Font.GothamBold
FloatingButton.Text = "⚙️ MENU"
FloatingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingButton.TextSize = 16
FloatingButton.Active = true
FloatingButton.Draggable = true

UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = FloatingButton

UIStroke.Color = Color3.fromRGB(100, 100, 255)
UIStroke.Thickness = 2
UIStroke.Parent = FloatingButton

-- GUI Visibility Toggle
local isMinimized = false
local MainUIObject = nil

-- Wait for MainUI to load
spawn(function()
    wait(0.5)
    MainUIObject = game:GetService("CoreGui"):FindFirstChild("MainUI")
end)

FloatingButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if MainUIObject then
        MainUIObject.Enabled = not isMinimized
        if isMinimized then
            FloatingButton.Text = "⚙️ MENU"
            FloatingButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        else
            FloatingButton.Text = "❌ CLOSE"
            FloatingButton.BackgroundColor3 = Color3.fromRGB(45, 35, 35)
        end
    end
end)

-- Hover Effect
FloatingButton.MouseEnter:Connect(function()
    FloatingButton.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
end)

FloatingButton.MouseLeave:Connect(function()
    if isMinimized then
        FloatingButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    else
        FloatingButton.BackgroundColor3 = Color3.fromRGB(45, 35, 35)
    end
end)

-- Load Config
local function LoadConfig()
    local success, data = pcall(function()
        return readfile(ConfigFile)
    end)
    if success then
        local decoded = HttpService:JSONDecode(data)
        for k, v in pairs(decoded) do
            Config[k] = v
        end
        print("Config loaded successfully!")
    end
end

-- Save Config
local function SaveConfig()
    local encoded = HttpService:JSONEncode(Config)
    writefile(ConfigFile, encoded)
    print("Config saved successfully!")
end

-- Teleport Function
local function TeleportTo(position)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
        return true
    end
    return false
end

-- Smooth Teleport dengan Tween
local function SmoothTeleport(position)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(position)})
        tween:Play()
        tween.Completed:Wait()
        return true
    end
    return false
end

-- Get Current Time
local function GetCurrentTime()
    local time = os.date("*t")
    return string.format("%02d:%02d", time.hour, time.min)
end

-- Check if should teleport
local function ShouldTeleportNow()
    local currentTime = GetCurrentTime()
    local hour = currentTime:sub(1, 5) -- HH:MM
    return Config.schedule[hour] == true
end

-- Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Teleport Settings")

-- Status Label
local StatusLabel = MainSection:NewLabel("Status: Idle")

-- GUI Controls Info
local ControlSection = MainTab:NewSection("GUI Controls")
ControlSection:NewLabel("Klik floating button ⚙️ MENU untuk hide/show")
ControlSection:NewLabel("Floating button bisa di-drag ke mana saja")

-- Toggle Auto Teleport
MainSection:NewToggle("Enable Auto Teleport", "Aktifkan auto teleport", function(state)
    Config.enabled = state
    SaveConfig()
    if state then
        StatusLabel:UpdateLabel("Status: Running")
    else
        StatusLabel:UpdateLabel("Status: Stopped")
    end
end)

-- Save Start Position
MainSection:NewButton("Copy Start Position", "Simpan posisi awal", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        Config.startCoords = {X = pos.X, Y = pos.Y, Z = pos.Z}
        SaveConfig()
        StatusLabel:UpdateLabel("Start Position Saved!")
        wait(2)
        StatusLabel:UpdateLabel("Status: " .. (Config.enabled and "Running" or "Idle"))
    end
end)

-- Save Target Position
MainSection:NewButton("Copy Target Position", "Simpan posisi tujuan", function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        Config.targetCoords = {X = pos.X, Y = pos.Y, Z = pos.Z}
        SaveConfig()
        StatusLabel:UpdateLabel("Target Position Saved!")
        wait(2)
        StatusLabel:UpdateLabel("Status: " .. (Config.enabled and "Running" or "Idle"))
    end
end)

-- Wait Time Slider
MainSection:NewSlider("Wait Time (Minutes)", "Waktu tunggu setelah teleport", 60, 1, function(value)
    Config.waitTime = value * 60
    SaveConfig()
end)

-- Player Teleport Tab
local PlayerTab = Window:NewTab("Player Teleport")
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
end

-- Refresh Button
PlayerSection:NewButton("Refresh Player List", "Refresh daftar player", function()
    RefreshPlayers()
    StatusLabel:UpdateLabel("Player list refreshed!")
    wait(1)
    StatusLabel:UpdateLabel("Status: " .. (Config.enabled and "Running" or "Idle"))
end)

-- Player Dropdown
PlayerSection:NewDropdown("Select Player", "Pilih player", PlayerList, function(selected)
    SelectedPlayer = selected
end)

-- Teleport to Player Button
PlayerSection:NewButton("Teleport to Player", "Teleport ke player yang dipilih", function()
    if SelectedPlayer then
        local player = Players:FindFirstChild(SelectedPlayer)
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos = player.Character.HumanoidRootPart.Position
            TeleportTo(pos)
            StatusLabel:UpdateLabel("Teleported to " .. SelectedPlayer)
            wait(2)
            StatusLabel:UpdateLabel("Status: " .. (Config.enabled and "Running" or "Idle"))
        end
    end
end)

-- Schedule Tab
local ScheduleTab = Window:NewTab("Schedule")
local ScheduleSection = ScheduleTab:NewSection("Atur Jadwal Teleport")

local times = {"11:00", "13:00", "15:00", "17:00", "19:00", "21:00", "23:00", "01:00", "03:00", "05:00", "07:00", "09:00"}

for _, time in ipairs(times) do
    ScheduleSection:NewToggle(time, "Toggle waktu " .. time, function(state)
        Config.schedule[time] = state
        SaveConfig()
    end)
end

-- Load Config on Start
LoadConfig()
RefreshPlayers()

-- Main Loop
local lastTeleportTime = 0
local isAtTarget = false
local nextScheduledTeleport = nil

spawn(function()
    while true do
        wait(1)
        
        if Config.enabled and Config.startCoords and Config.targetCoords then
            local currentTime = tick()
            
            -- Check if it's time for scheduled teleport
            local currentHour = GetCurrentTime()
            local shouldTeleport = Config.schedule[currentHour:sub(1, 5)]
            
            if shouldTeleport and not isAtTarget and (currentTime - lastTeleportTime) >= Config.waitTime then
                -- Teleport to target
                StatusLabel:UpdateLabel("Teleporting to target...")
                local targetPos = Vector3.new(Config.targetCoords.X, Config.targetCoords.Y, Config.targetCoords.Z)
                if SmoothTeleport(targetPos) then
                    isAtTarget = true
                    lastTeleportTime = currentTime
                    StatusLabel:UpdateLabel("At target. Waiting " .. (Config.waitTime/60) .. " minutes...")
                end
            elseif isAtTarget and (currentTime - lastTeleportTime) >= Config.waitTime then
                -- Teleport back to start
                StatusLabel:UpdateLabel("Teleporting back to start...")
                local startPos = Vector3.new(Config.startCoords.X, Config.startCoords.Y, Config.startCoords.Z)
                if SmoothTeleport(startPos) then
                    isAtTarget = false
                    lastTeleportTime = currentTime
                    StatusLabel:UpdateLabel("Back at start. Waiting for next schedule...")
                end
            end
            
            -- Update countdown
            if isAtTarget or not shouldTeleport then
                local timeLeft = Config.waitTime - (currentTime - lastTeleportTime)
                if timeLeft > 0 and isAtTarget then
                    local minutes = math.floor(timeLeft / 60)
                    local seconds = math.floor(timeLeft % 60)
                    StatusLabel:UpdateLabel(string.format("Waiting: %02d:%02d", minutes, seconds))
                end
            end
        end
    end
end)

-- Start with GUI minimized
wait(1)
if MainUIObject then
    MainUIObject.Enabled = false
    isMinimized = true
end

print("Auto Teleport Script Loaded!")
print("Klik floating button ⚙️ MENU untuk buka GUI")
print("Floating button bisa di-drag kemana aja!")
