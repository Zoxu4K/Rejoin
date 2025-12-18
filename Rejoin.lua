-- Fish It Totem Detector & Teleporter - MOBILE VERSION
-- Compatible with Delta Executor

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Konfigurasi
local AUTO_REJOIN = false -- Set false sesuai permintaan
local TOTEM_SCAN_INTERVAL = 2 -- Scan totem setiap 2 detik

-- Totem tracking
local ACTIVE_TOTEMS = {}

-- Totem types to detect
local TOTEM_TYPES = {
    "LuckTotem",
    "MutationTotem",
    "ShinyTotem"
}

-- UI Notification function
local function createNotification(title, text, duration)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
            Icon = "rbxassetid://6031302931"
        })
    end)
end

-- Function untuk scan totems
local function scanTotems()
    ACTIVE_TOTEMS = {}
    
    pcall(function()
        local zones = Workspace:FindFirstChild("zones")
        if not zones then return end
        
        local fishing = zones:FindFirstChild("fishing")
        if not fishing then return end
        
        for _, zone in pairs(fishing:GetChildren()) do
            local active = zone:FindFirstChild("active")
            if active then
                for _, totem in pairs(active:GetChildren()) do
                    for _, totemType in pairs(TOTEM_TYPES) do
                        if totem.Name == totemType then
                            local pos = totem:FindFirstChild("HumanoidRootPart") or totem.PrimaryPart or totem:FindFirstChildWhichIsA("BasePart")
                            if pos then
                                local timeLeft = totem:FindFirstChild("time_left")
                                local duration = timeLeft and totem.time_left.Value or "Unknown"
                                
                                table.insert(ACTIVE_TOTEMS, {
                                    name = totemType,
                                    position = pos.Position,
                                    cframe = pos.CFrame,
                                    duration = duration,
                                    object = totem,
                                    zone = zone.Name
                                })
                            end
                        end
                    end
                end
            end
        end
    end)
    
    return #ACTIVE_TOTEMS
end

-- Function untuk teleport ke totem terdekat
local function teleportToNearestTotem()
    if #ACTIVE_TOTEMS == 0 then
        createNotification("⚠️ No Totems", "Tidak ada totem aktif!", 3)
        return false
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        createNotification("❌ Error", "Character not found!", 3)
        return false
    end
    
    local playerPos = char.HumanoidRootPart.Position
    local nearest = nil
    local minDist = math.huge
    
    for _, totem in pairs(ACTIVE_TOTEMS) do
        local dist = (totem.position - playerPos).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = totem
        end
    end
    
    if nearest then
        local success, err = pcall(function()
            char.HumanoidRootPart.CFrame = nearest.cframe + Vector3.new(0, 3, 0)
        end)
        
        if success then
            createNotification("✅ Teleported", "Teleport ke " .. nearest.name .. " (" .. math.floor(minDist) .. " studs)", 3)
            return true
        else
            createNotification("❌ Failed", "Teleport gagal!", 3)
            return false
        end
    end
    
    return false
end

-- Function untuk teleport ke totem spesifik
local function teleportToTotem(index)
    if not ACTIVE_TOTEMS[index] then
        createNotification("❌ Error", "Totem tidak ditemukan!", 3)
        return false
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        createNotification("❌ Error", "Character not found!", 3)
        return false
    end
    
    local totem = ACTIVE_TOTEMS[index]
    local success, err = pcall(function()
        char.HumanoidRootPart.CFrame = totem.cframe + Vector3.new(0, 3, 0)
    end)
    
    if success then
        createNotification("✅ Teleported", "Teleport ke " .. totem.name, 3)
        return true
    else
        createNotification("❌ Failed", "Teleport gagal!", 3)
        return false
    end
end

-- Function untuk format waktu
local function formatTime(seconds)
    if type(seconds) ~= "number" then return "Unknown" end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

-- CREATE TOTEM DETECTOR GUI
local function createTotemGUI()
    pcall(function()
        -- Create ScreenGui
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FishItTotemDetector"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Main Frame (Totem List)
        local frame = Instance.new("Frame")
        frame.Name = "TotemFrame"
        frame.Size = UDim2.new(0, 400, 0, 450)
        frame.Position = UDim2.new(0.5, -200, 0.5, -225)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        frame.Active = true
        frame.Draggable = true
        frame.Parent = screenGui
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0, 35)
        title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        title.BorderSizePixel = 0
        title.Text = "🔮 TOTEM DETECTOR"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.Parent = frame
        
        -- Status Label
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "Status"
        statusLabel.Size = UDim2.new(1, -10, 0, 25)
        statusLabel.Position = UDim2.new(0, 5, 0, 40)
        statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        statusLabel.BorderSizePixel = 1
        statusLabel.BorderColor3 = Color3.fromRGB(100, 100, 100)
        statusLabel.Text = "🔍 Scanning..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        statusLabel.TextSize = 13
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.Parent = frame
        
        -- ScrollingFrame untuk totem list
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "TotemScroll"
        scrollFrame.Size = UDim2.new(1, -10, 1, -155)
        scrollFrame.Position = UDim2.new(0, 5, 0, 70)
        scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        scrollFrame.BorderSizePixel = 1
        scrollFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
        scrollFrame.ScrollBarThickness = 8
        scrollFrame.Parent = frame
        
        -- UIListLayout
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 5)
        listLayout.Parent = scrollFrame
        
        -- Button: Quick Teleport (Nearest)
        local quickTpBtn = Instance.new("TextButton")
        quickTpBtn.Name = "QuickTP"
        quickTpBtn.Size = UDim2.new(0.48, -2, 0, 35)
        quickTpBtn.Position = UDim2.new(0.01, 0, 1, -75)
        quickTpBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        quickTpBtn.BorderSizePixel = 0
        quickTpBtn.Text = "⚡ TP TERDEKAT"
        quickTpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        quickTpBtn.TextSize = 13
        quickTpBtn.Font = Enum.Font.GothamBold
        quickTpBtn.Parent = frame
        
        quickTpBtn.MouseButton1Click:Connect(function()
            teleportToNearestTotem()
        end)
        
        -- Button: Refresh
        local refreshBtn = Instance.new("TextButton")
        refreshBtn.Name = "Refresh"
        refreshBtn.Size = UDim2.new(0.48, -2, 0, 35)
        refreshBtn.Position = UDim2.new(0.51, 0, 1, -75)
        refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        refreshBtn.BorderSizePixel = 0
        refreshBtn.Text = "🔄 REFRESH"
        refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        refreshBtn.TextSize = 13
        refreshBtn.Font = Enum.Font.GothamBold
        refreshBtn.Parent = frame
        
        -- Button: Close
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "Close"
        closeBtn.Size = UDim2.new(1, -10, 0, 35)
        closeBtn.Position = UDim2.new(0, 5, 1, -35)
        closeBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "❌ CLOSE"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 13
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = frame
        
        closeBtn.MouseButton1Click:Connect(function()
            frame.Visible = false
        end)
        
        -- Toggle Button (kanan atas)
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Name = "Toggle"
        toggleBtn.Size = UDim2.new(0, 80, 0, 30)
        toggleBtn.Position = UDim2.new(1, -90, 0, 10)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Text = "🔮 TOTEM"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 12
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Parent = screenGui
        
        toggleBtn.MouseButton1Click:Connect(function()
            frame.Visible = not frame.Visible
        end)
        
        -- Function untuk update totem list
        local function updateTotemList()
            -- Clear existing buttons
            for _, child in pairs(scrollFrame:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            local count = scanTotems()
            statusLabel.Text = "🔮 Active Totems: " .. count
            
            if count == 0 then
                local noTotem = Instance.new("TextLabel")
                noTotem.Size = UDim2.new(1, -10, 0, 40)
                noTotem.BackgroundTransparency = 1
                noTotem.Text = "⚠️ Tidak ada totem aktif"
                noTotem.TextColor3 = Color3.fromRGB(200, 200, 200)
                noTotem.TextSize = 14
                noTotem.Font = Enum.Font.Gotham
                noTotem.Parent = scrollFrame
            else
                for i, totem in pairs(ACTIVE_TOTEMS) do
                    local totemFrame = Instance.new("Frame")
                    totemFrame.Name = "Totem" .. i
                    totemFrame.Size = UDim2.new(1, -10, 0, 80)
                    totemFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                    totemFrame.BorderSizePixel = 1
                    totemFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
                    totemFrame.Parent = scrollFrame
                    
                    -- Totem Icon/Type
                    local icon = Instance.new("TextLabel")
                    icon.Size = UDim2.new(0, 60, 1, 0)
                    icon.BackgroundTransparency = 1
                    icon.Text = "🔮"
                    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
                    icon.TextSize = 32
                    icon.Parent = totemFrame
                    
                    -- Totem Info
                    local info = Instance.new("TextLabel")
                    info.Size = UDim2.new(1, -130, 0, 25)
                    info.Position = UDim2.new(0, 65, 0, 5)
                    info.BackgroundTransparency = 1
                    info.Text = totem.name
                    info.TextColor3 = Color3.fromRGB(255, 255, 100)
                    info.TextSize = 14
                    info.Font = Enum.Font.GothamBold
                    info.TextXAlignment = Enum.TextXAlignment.Left
                    info.Parent = totemFrame
                    
                    -- Zone Info
                    local zoneInfo = Instance.new("TextLabel")
                    zoneInfo.Size = UDim2.new(1, -130, 0, 20)
                    zoneInfo.Position = UDim2.new(0, 65, 0, 28)
                    zoneInfo.BackgroundTransparency = 1
                    zoneInfo.Text = "📍 " .. totem.zone
                    zoneInfo.TextColor3 = Color3.fromRGB(180, 180, 180)
                    zoneInfo.TextSize = 11
                    zoneInfo.Font = Enum.Font.Gotham
                    zoneInfo.TextXAlignment = Enum.TextXAlignment.Left
                    zoneInfo.Parent = totemFrame
                    
                    -- Duration Label (Real-time update)
                    local durationLabel = Instance.new("TextLabel")
                    durationLabel.Name = "Duration"
                    durationLabel.Size = UDim2.new(1, -130, 0, 20)
                    durationLabel.Position = UDim2.new(0, 65, 0, 50)
                    durationLabel.BackgroundTransparency = 1
                    durationLabel.Text = "⏱️ " .. formatTime(totem.duration)
                    durationLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                    durationLabel.TextSize = 12
                    durationLabel.Font = Enum.Font.GothamBold
                    durationLabel.TextXAlignment = Enum.TextXAlignment.Left
                    durationLabel.Parent = totemFrame
                    
                    -- TP Button
                    local tpBtn = Instance.new("TextButton")
                    tpBtn.Size = UDim2.new(0, 60, 0, 70)
                    tpBtn.Position = UDim2.new(1, -65, 0, 5)
                    tpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                    tpBtn.BorderSizePixel = 0
                    tpBtn.Text = "📍\nTP"
                    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    tpBtn.TextSize = 14
                    tpBtn.Font = Enum.Font.GothamBold
                    tpBtn.Parent = totemFrame
                    
                    tpBtn.MouseButton1Click:Connect(function()
                        teleportToTotem(i)
                    end)
                end
            end
            
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
        end
        
        refreshBtn.MouseButton1Click:Connect(function()
            updateTotemList()
        end)
        
        -- Real-time duration update
        spawn(function()
            while true do
                wait(1)
                if frame.Visible then
                    for i, totem in pairs(ACTIVE_TOTEMS) do
                        local totemFrame = scrollFrame:FindFirstChild("Totem" .. i)
                        if totemFrame then
                            local durationLabel = totemFrame:FindFirstChild("Duration")
                            if durationLabel and totem.object then
                                local timeLeft = totem.object:FindFirstChild("time_left")
                                if timeLeft then
                                    local newTime = timeLeft.Value
                                    durationLabel.Text = "⏱️ " .. formatTime(newTime)
                                    
                                    -- Color coding based on time
                                    if newTime < 60 then
                                        durationLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                                    elseif newTime < 180 then
                                        durationLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
                                    else
                                        durationLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        
        -- Auto refresh every interval
        spawn(function()
            while true do
                wait(TOTEM_SCAN_INTERVAL)
                if frame.Visible then
                    updateTotemList()
                end
            end
        end)
        
        -- Initial update
        updateTotemList()
        
        screenGui.Parent = game:GetService("CoreGui")
    end)
end

-- Initialize
createNotification("⏳ Loading...", "Initializing Totem Detector...", 3)
wait(1)
createTotemGUI()
wait(1)
createNotification("✅ SUCCESS!", "Totem Detector loaded!", 3)
wait(2)
createNotification("🔮 TOTEM", "Klik button 'TOTEM' di pojok kanan atas!", 5)
