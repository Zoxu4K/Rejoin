-- Fish It Auto Rejoin Utility - MOBILE VERSION WITH TOTEM DETECTION
-- Compatible with Delta Executor

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

-- Konfigurasi
local REJOIN_INTERVAL = 15
local IS_RUNNING = true

-- Totem detection
local ACTIVE_TOTEMS = {}
local TOTEM_TYPES = {
    ["Luck Totem"] = {icon = "🍀", color = Color3.fromRGB(0, 255, 0)},
    ["Mutation Totem"] = {icon = "🧬", color = Color3.fromRGB(255, 0, 255)},
    ["Shiny Totem"] = {icon = "✨", color = Color3.fromRGB(255, 215, 0)}
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

-- Function untuk detect totems
local function detectTotems()
    ACTIVE_TOTEMS = {}
    
    for totemName, _ in pairs(TOTEM_TYPES) do
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == totemName or (obj:IsA("Model") and obj.Name:find(totemName)) then
                local position = nil
                
                if obj:IsA("Model") and obj.PrimaryPart then
                    position = obj.PrimaryPart.Position
                elseif obj:IsA("BasePart") then
                    position = obj.Position
                end
                
                if position then
                    table.insert(ACTIVE_TOTEMS, {
                        name = totemName,
                        object = obj,
                        position = position
                    })
                end
            end
        end
    end
    
    return ACTIVE_TOTEMS
end

-- Function untuk get totem duration
local function getTotemDuration(totem)
    if totem.object:FindFirstChild("Duration") then
        return totem.object.Duration.Value
    end
    return "Unknown"
end

-- Function untuk teleport ke totem
local function teleportToTotem(totem)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local success, err = pcall(function()
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(totem.position)
        end)
        
        if success then
            createNotification("✅ Teleported", "Teleported to " .. totem.name, 3)
            return true
        else
            createNotification("❌ Failed", "Teleport failed!", 3)
            return false
        end
    end
    return false
end

-- Function untuk cari totem terdekat
local function findNearestTotem()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
    local nearest = nil
    local minDistance = math.huge
    
    for _, totem in pairs(ACTIVE_TOTEMS) do
        local distance = (playerPos - totem.position).Magnitude
        if distance < minDistance then
            minDistance = distance
            nearest = totem
        end
    end
    
    return nearest, minDistance
end

-- CREATE TOTEM GUI
local function createTotemGUI()
    local success, err = pcall(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FishItTotemGUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Totem List Frame
        local totemFrame = Instance.new("Frame")
        totemFrame.Name = "TotemFrame"
        totemFrame.Size = UDim2.new(0, 400, 0, 450)
        totemFrame.Position = UDim2.new(0.5, -200, 0.5, -225)
        totemFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        totemFrame.BorderSizePixel = 2
        totemFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        totemFrame.Active = true
        totemFrame.Draggable = true
        totemFrame.Visible = false
        totemFrame.Parent = screenGui
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        title.BorderSizePixel = 0
        title.Text = "🎯 ACTIVE TOTEMS - Teleport"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.Parent = totemFrame
        
        -- ScrollingFrame
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "TotemScroll"
        scrollFrame.Size = UDim2.new(1, -10, 1, -130)
        scrollFrame.Position = UDim2.new(0, 5, 0, 45)
        scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        scrollFrame.BorderSizePixel = 1
        scrollFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
        scrollFrame.ScrollBarThickness = 8
        scrollFrame.Parent = totemFrame
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 5)
        listLayout.Parent = scrollFrame
        
        -- Function refresh totem list
        local function refreshTotemList()
            for _, child in pairs(scrollFrame:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            detectTotems()
            
            if #ACTIVE_TOTEMS == 0 then
                local noTotem = Instance.new("TextLabel")
                noTotem.Size = UDim2.new(1, -10, 0, 50)
                noTotem.BackgroundTransparency = 1
                noTotem.Text = "❌ No active totems found"
                noTotem.TextColor3 = Color3.fromRGB(255, 100, 100)
                noTotem.TextSize = 14
                noTotem.Font = Enum.Font.Gotham
                noTotem.Parent = scrollFrame
                return
            end
            
            for i, totem in pairs(ACTIVE_TOTEMS) do
                local totemInfo = TOTEM_TYPES[totem.name] or {icon = "📍", color = Color3.fromRGB(255, 255, 255)}
                
                local container = Instance.new("Frame")
                container.Name = "Totem_" .. i
                container.Size = UDim2.new(1, -10, 0, 80)
                container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                container.BorderSizePixel = 1
                container.BorderColor3 = totemInfo.color
                container.Parent = scrollFrame
                
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -10, 0, 25)
                nameLabel.Position = UDim2.new(0, 5, 0, 5)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = totemInfo.icon .. " " .. totem.name
                nameLabel.TextColor3 = totemInfo.color
                nameLabel.TextSize = 14
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = container
                
                -- Duration label (updates real-time)
                local durationLabel = Instance.new("TextLabel")
                durationLabel.Name = "DurationLabel"
                durationLabel.Size = UDim2.new(1, -10, 0, 20)
                durationLabel.Position = UDim2.new(0, 5, 0, 28)
                durationLabel.BackgroundTransparency = 1
                durationLabel.Text = "⏱️ Duration: Checking..."
                durationLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                durationLabel.TextSize = 11
                durationLabel.Font = Enum.Font.Gotham
                durationLabel.TextXAlignment = Enum.TextXAlignment.Left
                durationLabel.Parent = container
                
                local teleportBtn = Instance.new("TextButton")
                teleportBtn.Size = UDim2.new(1, -10, 0, 25)
                teleportBtn.Position = UDim2.new(0, 5, 1, -30)
                teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                teleportBtn.BorderSizePixel = 0
                teleportBtn.Text = "📍 TELEPORT HERE"
                teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                teleportBtn.TextSize = 12
                teleportBtn.Font = Enum.Font.GothamBold
                teleportBtn.Parent = container
                
                teleportBtn.MouseButton1Click:Connect(function()
                    teleportToTotem(totem)
                end)
            end
            
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
        end
        
        -- Update duration real-time
        spawn(function()
            while true do
                wait(1)
                if totemFrame.Visible then
                    for i, totem in pairs(ACTIVE_TOTEMS) do
                        local container = scrollFrame:FindFirstChild("Totem_" .. i)
                        if container then
                            local durationLabel = container:FindFirstChild("DurationLabel")
                            if durationLabel then
                                local duration = getTotemDuration(totem)
                                durationLabel.Text = "⏱️ Duration: " .. tostring(duration)
                            end
                        end
                    end
                end
            end
        end)
        
        -- Buttons
        local refreshBtn = Instance.new("TextButton")
        refreshBtn.Size = UDim2.new(0.32, -3, 0, 35)
        refreshBtn.Position = UDim2.new(0.01, 0, 1, -80)
        refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        refreshBtn.BorderSizePixel = 0
        refreshBtn.Text = "🔄 REFRESH"
        refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        refreshBtn.TextSize = 12
        refreshBtn.Font = Enum.Font.GothamBold
        refreshBtn.Parent = totemFrame
        
        refreshBtn.MouseButton1Click:Connect(function()
            refreshTotemList()
            createNotification("🔄 Refreshed", "Totem list updated", 2)
        end)
        
        local nearestBtn = Instance.new("TextButton")
        nearestBtn.Size = UDim2.new(0.32, -3, 0, 35)
        nearestBtn.Position = UDim2.new(0.34, 0, 1, -80)
        nearestBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        nearestBtn.BorderSizePixel = 0
        nearestBtn.Text = "📍 NEAREST"
        nearestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        nearestBtn.TextSize = 12
        nearestBtn.Font = Enum.Font.GothamBold
        nearestBtn.Parent = totemFrame
        
        nearestBtn.MouseButton1Click:Connect(function()
            detectTotems()
            local nearest, distance = findNearestTotem()
            if nearest then
                teleportToTotem(nearest)
                createNotification("✅ Nearest", string.format("%.1fm away", distance), 3)
            else
                createNotification("❌ No Totems", "No totems found", 3)
            end
        end)
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0.32, -3, 0, 35)
        closeBtn.Position = UDim2.new(0.67, 0, 1, -80)
        closeBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "❌ CLOSE"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 12
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = totemFrame
        
        closeBtn.MouseButton1Click:Connect(function()
            totemFrame.Visible = false
        end)
        
        -- Stop/Start button
        local stopBtn = Instance.new("TextButton")
        stopBtn.Size = UDim2.new(0.48, -2, 0, 35)
        stopBtn.Position = UDim2.new(0.01, 0, 1, -40)
        stopBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        stopBtn.BorderSizePixel = 0
        stopBtn.Text = "⏸️ PAUSE REJOIN"
        stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stopBtn.TextSize = 11
        stopBtn.Font = Enum.Font.GothamBold
        stopBtn.Parent = totemFrame
        
        stopBtn.MouseButton1Click:Connect(function()
            IS_RUNNING = not IS_RUNNING
            if IS_RUNNING then
                stopBtn.Text = "⏸️ PAUSE REJOIN"
                stopBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
                createNotification("▶️ Started", "Auto rejoin resumed", 3)
            else
                stopBtn.Text = "▶️ START REJOIN"
                stopBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                createNotification("⏸️ Stopped", "Auto rejoin paused", 3)
            end
        end)
        
        -- Toggle button (top right)
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 80, 0, 30)
        toggleBtn.Position = UDim2.new(1, -90, 0, 10)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Text = "🎯 TOTEMS"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 12
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Parent = screenGui
        
        toggleBtn.MouseButton1Click:Connect(function()
            totemFrame.Visible = not totemFrame.Visible
            if totemFrame.Visible then
                refreshTotemList()
            end
        end)
        
        -- Auto refresh every 5 seconds
        spawn(function()
            while true do
                wait(5)
                if totemFrame.Visible then
                    refreshTotemList()
                end
            end
        end)
        
        screenGui.Parent = game:GetService("CoreGui")
        refreshTotemList()
    end)
end

-- Fungsi rejoin
local function rejoinGame()
    local success, err = pcall(function()
        local serverList = {}
        local cursor = ""
        
        repeat
            local url = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100&cursor=%s",
                game.PlaceId, cursor
            )
            
            local httpSuccess, servers = pcall(function()
                return game:HttpGet(url)
            end)
            
            if httpSuccess then
                local decoded = HttpService:JSONDecode(servers)
                if decoded.data then
                    for _, server in pairs(decoded.data) do
                        if server.playing < server.maxPlayers and server.id ~= game.JobId then
                            table.insert(serverList, server.id)
                        end
                    end
                end
                cursor = decoded.nextPageCursor or ""
            else
                break
            end
        until cursor == "" or #serverList >= 10
        
        if #serverList > 0 then
            local randomServer = serverList[math.random(1, #serverList)]
            createNotification("🚀 Hopping", "Changing server...", 3)
            wait(1)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
        else
            createNotification("🔄 Rejoining", "Reconnecting...", 3)
            wait(1)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    
    if not success then
        createNotification("❌ Error", "Rejoin failed!", 5)
    end
end

-- Main loop
local function startAutoRejoin()
    spawn(function()
        local countdown = REJOIN_INTERVAL
        while true do
            if IS_RUNNING then
                if countdown > 0 then
                    wait(1)
                    countdown = countdown - 1
                else
                    rejoinGame()
                    countdown = REJOIN_INTERVAL
                end
            else
                countdown = REJOIN_INTERVAL
                wait(2)
            end
        end
    end)
end

-- Initialize
createTotemGUI()
createNotification("✅ SUCCESS!", "Fish It Utility loaded!", 5)
wait(2)
createNotification("🎯 Totems", "Click TOTEMS button to detect & teleport!", 5)
startAutoRejoin()
