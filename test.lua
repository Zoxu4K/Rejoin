-- Auto Teleport Schedule Script
-- Compatible with Delta Executor (Android/PC)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Auto Teleport Schedule", "DarkTheme")

-- Variables
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

local Config = {
    Enabled = false,
    TargetCoords = nil,
    SpawnCoords = nil,
    WaitTime = 35, -- Default 35 menit
    ScheduleEnabled = false,
    CurrentScheduleIndex = 1,
    TeleportToPlayer = false,
    SelectedPlayer = nil
}

-- Schedule times (in 24-hour format)
local ScheduleTimes = {
    {hour = 11, minute = 0},
    {hour = 13, minute = 0},
    {hour = 15, minute = 0},
    {hour = 17, minute = 0},
    {hour = 19, minute = 0},
    {hour = 21, minute = 0},
    {hour = 23, minute = 0},
    {hour = 1, minute = 0},
    {hour = 3, minute = 0},
    {hour = 5, minute = 0},
    {hour = 7, minute = 0},
    {hour = 9, minute = 0}
}

-- Functions
local function SaveConfig()
    local success, err = pcall(function()
        writefile("AutoTeleportConfig.json", game:GetService("HttpService"):JSONEncode(Config))
    end)
    if success then
        Library:Notify("Config", "Config berhasil disimpan!", 3)
    end
end

local function LoadConfig()
    if isfile("AutoTeleportConfig.json") then
        local success, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile("AutoTeleportConfig.json"))
        end)
        if success and data then
            Config = data
            Library:Notify("Config", "Config berhasil dimuat!", 3)
            return true
        end
    end
    return false
end

local function TeleportTo(position)
    if Character and HRP then
        HRP.CFrame = CFrame.new(position)
    end
end

local function GetCurrentTime()
    local time = os.date("*t")
    return {hour = time.hour, minute = time.min}
end

local function ShouldTeleport()
    if not Config.ScheduleEnabled then return false end
    
    local currentTime = GetCurrentTime()
    for _, scheduleTime in ipairs(ScheduleTimes) do
        if currentTime.hour == scheduleTime.hour and currentTime.minute == scheduleTime.minute then
            return true
        end
    end
    return false
end

local function GetPlayerList()
    local players = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= Player then
            table.insert(players, player.Name)
        end
    end
    return players
end

-- Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Koordinat Setup")

MainSection:NewButton("Copy Koordinat Sekarang", "Simpan posisi saat ini", function()
    Config.SpawnCoords = HRP.Position
    Library:Notify("Koordinat", "Posisi spawn disimpan: " .. tostring(Config.SpawnCoords), 3)
    SaveConfig()
end)

MainSection:NewTextBox("Paste Koordinat Target (X,Y,Z)", "Format: 100,50,200", function(txt)
    local coords = string.split(txt, ",")
    if #coords == 3 then
        Config.TargetCoords = Vector3.new(tonumber(coords[1]), tonumber(coords[2]), tonumber(coords[3]))
        Library:Notify("Koordinat", "Target koordinat diset: " .. tostring(Config.TargetCoords), 3)
        SaveConfig()
    else
        Library:Notify("Error", "Format salah! Gunakan: X,Y,Z", 3)
    end
end)

MainSection:NewSlider("Waktu Tunggu (Menit)", "Durasi di lokasi target", 60, 1, function(s)
    Config.WaitTime = s
    SaveConfig()
end)

MainSection:NewToggle("Enable Auto Teleport Schedule", "Aktifkan teleport otomatis", function(state)
    Config.ScheduleEnabled = state
    SaveConfig()
    if state then
        Library:Notify("Schedule", "Auto teleport schedule AKTIF!", 3)
    else
        Library:Notify("Schedule", "Auto teleport schedule NONAKTIF!", 3)
    end
end)

-- Player Teleport Tab
local PlayerTab = Window:NewTab("Player Teleport")
local PlayerSection = PlayerTab:NewSection("Teleport ke Player")

local playerDropdown
local playerList = GetPlayerList()

PlayerSection:NewButton("Refresh Player List", "Update daftar player", function()
    playerList = GetPlayerList()
    Library:Notify("Player List", "Daftar player di-refresh!", 2)
    -- Recreate dropdown with new list
    if playerDropdown then
        playerDropdown:Refresh(playerList)
    end
end)

playerDropdown = PlayerSection:NewDropdown("Pilih Player", "Pilih player target", playerList, function(currentOption)
    Config.SelectedPlayer = currentOption
    SaveConfig()
end)

PlayerSection:NewButton("Teleport ke Player", "Teleport sekarang", function()
    if Config.SelectedPlayer then
        local targetPlayer = game.Players:FindFirstChild(Config.SelectedPlayer)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            TeleportTo(targetPlayer.Character.HumanoidRootPart.Position)
            Library:Notify("Teleport", "Teleport ke " .. Config.SelectedPlayer, 3)
        else
            Library:Notify("Error", "Player tidak ditemukan atau tidak ada character!", 3)
        end
    else
        Library:Notify("Error", "Pilih player terlebih dahulu!", 3)
    end
end)

-- Schedule Tab
local ScheduleTab = Window:NewTab("Schedule")
local ScheduleSection = ScheduleTab:NewSection("Jadwal Teleport")

ScheduleSection:NewLabel("Jadwal Jam Teleport:")
for _, time in ipairs(ScheduleTimes) do
    ScheduleSection:NewLabel(string.format("%02d:%02d", time.hour, time.minute))
end

-- Info Tab
local InfoTab = Window:NewTab("Info")
local InfoSection = InfoTab:NewSection("Status")

InfoSection:NewLabel("Status: Menunggu...")
InfoSection:NewLabel("Spawn Pos: Belum diset")
InfoSection:NewLabel("Target Pos: Belum diset")
InfoSection:NewLabel("Waktu Tunggu: 35 menit")

-- Load saved config
LoadConfig()

-- Main Loop
spawn(function()
    local lastTeleport = 0
    local isAtTarget = false
    
    while wait(1) do
        if Config.ScheduleEnabled and Config.TargetCoords and Config.SpawnCoords then
            local currentTime = os.time()
            
            if ShouldTeleport() and (currentTime - lastTeleport) > 60 then
                if not isAtTarget then
                    -- Teleport to target
                    TeleportTo(Config.TargetCoords)
                    Library:Notify("Teleport", "Teleport ke target lokasi!", 3)
                    isAtTarget = true
                    lastTeleport = currentTime
                    
                    -- Wait and teleport back
                    wait(Config.WaitTime * 60) -- Convert to seconds
                    TeleportTo(Config.SpawnCoords)
                    Library:Notify("Teleport", "Kembali ke spawn lokasi!", 3)
                    isAtTarget = false
                end
            end
        end
    end
end)

-- Update Character reference
Player.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
end)

-- Cleanup on exit
local ScreenGui = Player.PlayerGui:FindFirstChild("Kavo UI Library")
if ScreenGui then
    ScreenGui.Destroying:Connect(function()
        Config.ScheduleEnabled = false
        SaveConfig()
        Library:Notify("Exit", "Script dihentikan dan config disimpan!", 3)
    end)
end

Library:Notify("Loaded", "Auto Teleport Schedule siap digunakan!", 5)
