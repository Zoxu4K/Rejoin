-- Fish It Auto Rejoin Utility - ENHANCED VERSION
-- Features: Server Type Detection, Totem Detector, Player Teleport
-- Compatible with Delta Executor

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

-- Konfigurasi
local REJOIN_INTERVAL = 20
local AUTO_EXECUTE = true
local IS_RUNNING = true
local CURRENT_SERVER_TYPE = "Unknown" -- "Public" atau "Private"

-- LOG STORAGE
local LOG_HISTORY = {}
local MAX_LOGS = 100

-- TOTEM STORAGE
local DETECTED_TOTEMS = {}
local TOTEM_SCAN_INTERVAL = 5 -- Scan setiap 5 detik

-- Logging function
local function log(message, type)
    local timestamp = os.date("%H:%M:%S")
    local prefix = "[" .. timestamp .. "]"
    local fullMessage = prefix .. " " .. message
    
    table.insert(LOG_HISTORY, fullMessage)
    if #LOG_HISTORY > MAX_LOGS then
        table.remove(LOG_HISTORY, 1)
    end
    
    if type == "error" then
        warn(fullMessage)
    else
        print(fullMessage)
    end
end

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

-- Fungsi untuk save log ke clipboard
local function saveLogToClipboard()
    local fullLog = table.concat(LOG_HISTORY, "\n")
    
    local success, err = pcall(function()
        setclipboard(fullLog)
    end)
    
    if success then
        log("✅ LOG COPIED TO CLIPBOARD!", "success")
        createNotification("✅ Success", "Log copied to clipboard!", 5)
        return true
    else
        log("❌ Failed to copy to clipboard: " .. tostring(err), "error")
        return false
    end
end

-- Fungsi untuk deteksi server type (Public/Private)
local function detectServerType()
    local success, result = pcall(function()
        -- Check jika server ini Private (VIP server atau reserved server)
        if game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 then
            return "Private"
        else
            return "Public"
        end
    end)
    
    if success then
        CURRENT_SERVER_TYPE = result
        log("🔍 Server Type Detected: " .. result, "success")
        return result
    else
        log("⚠️ Failed to detect server type: " .. tostring(result), "warning")
        CURRENT_SERVER_TYPE = "Unknown"
        return "Unknown"
    end
end

-- Fungsi untuk scan totem di workspace
local function scanTotems()
    DETECTED_TOTEMS = {}
    
    local success, err = pcall(function()
        -- Scan untuk model bernama "Totem" atau yang mengandung kata "Totem"
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("Part") then
                local objName = obj.Name:lower()
                
                -- Deteksi totem (sesuaikan dengan nama totem di game Fish It)
                if objName:find("totem") or objName:find("rod") or obj:FindFirstChild("Totem") then
                    local position = nil
                    
                    if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
                        position = obj.HumanoidRootPart.Position
                    elseif obj:IsA("Model") and obj.PrimaryPart then
                        position = obj.PrimaryPart.Position
                    elseif obj:IsA("Part") then
                        position = obj.Position
                    end
                    
                    if position then
                        local distance = (LocalPlayer.Character.HumanoidRootPart.Position - position).Magnitude
                        
                        table.insert(DETECTED_TOTEMS, {
                            name = obj.Name,
                            object = obj,
                            position = position,
                            distance = distance,
                            timestamp = tick()
                        })
                    end
                end
            end
        end
        
        -- Sort by distance (terdekat dulu)
        table.sort(DETECTED_TOTEMS, function(a, b)
            return a.distance < b.distance
        end)
    end)
    
    if success then
        log("🔍 Totem Scan Complete: Found " .. #DETECTED_TOTEMS .. " totems", "success")
    else
        log("❌ Totem Scan Failed: " .. tostring(err), "error")
    end
    
    return #DETECTED_TOTEMS
end

-- CREATE IN-GAME GUI
local function createGUI()
    log("Creating enhanced GUI...", "info")
    
    local success, err = pcall(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FishItEnhancedGUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- ==================== LOG FRAME ====================
        local logFrame = Instance.new("Frame")
        logFrame.Name = "LogFrame"
        logFrame.Size = UDim2.new(0, 400, 0, 300)
        logFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
        logFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        logFrame.BorderSizePixel = 2
        logFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        logFrame.Active = true
        logFrame.Draggable = true
        logFrame.Parent = screenGui
        
        local logTitle = Instance.new("TextLabel")
        logTitle.Size = UDim2.new(1, 0, 0, 30)
        logTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        logTitle.Text = "📊 LOG VIEWER - Server: " .. CURRENT_SERVER_TYPE
        logTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        logTitle.TextSize = 13
        logTitle.Font = Enum.Font.GothamBold
        logTitle.Parent = logFrame
        
        local logScroll = Instance.new("ScrollingFrame")
        logScroll.Size = UDim2.new(1, -10, 1, -80)
        logScroll.Position = UDim2.new(0, 5, 0, 35)
        logScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        logScroll.ScrollBarThickness = 8
        logScroll.Parent = logFrame
        
        local logText = Instance.new("TextLabel")
        logText.Size = UDim2.new(1, -10, 1, 0)
        logText.Position = UDim2.new(0, 5, 0, 0)
        logText.BackgroundTransparency = 1
        logText.Text = "Waiting for logs..."
        logText.TextColor3 = Color3.fromRGB(255, 255, 255)
        logText.TextSize = 11
        logText.Font = Enum.Font.Code
        logText.TextXAlignment = Enum.TextXAlignment.Left
        logText.TextYAlignment = Enum.TextYAlignment.Top
        logText.TextWrapped = true
        logText.Parent = logScroll
        
        -- ==================== TOTEM FRAME ====================
        local totemFrame = Instance.new("Frame")
        totemFrame.Name = "TotemFrame"
        totemFrame.Size = UDim2.new(0, 350, 0, 400)
        totemFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
        totemFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        totemFrame.BorderSizePixel = 2
        totemFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
        totemFrame.Active = true
        totemFrame.Draggable = true
        totemFrame.Visible = false
        totemFrame.Parent = screenGui
        
        local totemTitle = Instance.new("TextLabel")
        totemTitle.Size = UDim2.new(1, 0, 0, 30)
        totemTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        totemTitle.Text = "🗿 TOTEM DETECTOR"
        totemTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
        totemTitle.TextSize = 14
        totemTitle.Font = Enum.Font.GothamBold
        totemTitle.Parent = totemFrame
        
        local totemScroll = Instance.new("ScrollingFrame")
        totemScroll.Size = UDim2.new(1, -10, 1, -80)
        totemScroll.Position = UDim2.new(0, 5, 0, 35)
        totemScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        totemScroll.ScrollBarThickness = 8
        totemScroll.Parent = totemFrame
        
        local totemListLayout = Instance.new("UIListLayout")
        totemListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        totemListLayout.Padding = UDim.new(0, 5)
        totemListLayout.Parent = totemScroll
        
        -- Function refresh totem list
        local function refreshTotemList()
            for _, child in pairs(totemScroll:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            scanTotems()
            
            if #DETECTED_TOTEMS == 0 then
                local noTotemLabel = Instance.new("TextLabel")
                noTotemLabel.Size = UDim2.new(1, 0, 0, 50)
                noTotemLabel.BackgroundTransparency = 1
                noTotemLabel.Text = "⚠️ No totems detected nearby"
                noTotemLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                noTotemLabel.TextSize = 12
                noTotemLabel.Font = Enum.Font.Gotham
                noTotemLabel.Parent = totemScroll
                return
            end
            
            for i, totem in ipairs(DETECTED_TOTEMS) do
                local totemContainer = Instance.new("Frame")
                totemContainer.Size = UDim2.new(1, -10, 0, 60)
                totemContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                totemContainer.BorderSizePixel = 1
                totemContainer.BorderColor3 = Color3.fromRGB(100, 100, 100)
                totemContainer.Parent = totemScroll
                
                local totemInfo = Instance.new("TextLabel")
                totemInfo.Size = UDim2.new(1, -10, 0, 35)
                totemInfo.Position = UDim2.new(0, 5, 0, 5)
                totemInfo.BackgroundTransparency = 1
                totemInfo.Text = string.format("🗿 %s\n📏 Distance: %.1f studs", totem.name, totem.distance)
                totemInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
                totemInfo.TextSize = 11
                totemInfo.Font = Enum.Font.Gotham
                totemInfo.TextXAlignment = Enum.TextXAlignment.Left
                totemInfo.Parent = totemContainer
                
                local tpBtn = Instance.new("TextButton")
                tpBtn.Size = UDim2.new(1, -10, 0, 20)
                tpBtn.Position = UDim2.new(0, 5, 1, -25)
                tpBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                tpBtn.Text = "⚡ TELEPORT"
                tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                tpBtn.TextSize = 11
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.Parent = totemContainer
                
                tpBtn.MouseButton1Click:Connect(function()
                    if totem.object and totem.position then
                        pcall(function()
                            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(totem.position)
                            log("✅ Teleported to totem: " .. totem.name, "success")
                            createNotification("✅ Teleported", "Moved to " .. totem.name, 3)
                        end)
                    end
                end)
            end
            
            totemScroll.CanvasSize = UDim2.new(0, 0, 0, totemListLayout.AbsoluteContentSize.Y + 10)
        end
        
        -- ==================== PLAYER FRAME ====================
        local playerFrame = Instance.new("Frame")
        playerFrame.Name = "PlayerFrame"
        playerFrame.Size = UDim2.new(0, 350, 0, 400)
        playerFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
        playerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        playerFrame.BorderSizePixel = 2
        playerFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        playerFrame.Active = true
        playerFrame.Draggable = true
        playerFrame.Visible = false
        playerFrame.Parent = screenGui
        
        local playerTitle = Instance.new("TextLabel")
        playerTitle.Size = UDim2.new(1, 0, 0, 30)
        playerTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        playerTitle.Text = "👥 PLAYER LIST"
        playerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        playerTitle.TextSize = 14
        playerTitle.Font = Enum.Font.GothamBold
        playerTitle.Parent = playerFrame
        
        local playerScroll = Instance.new("ScrollingFrame")
        playerScroll.Size = UDim2.new(1, -10, 1, -80)
        playerScroll.Position = UDim2.new(0, 5, 0, 35)
        playerScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        playerScroll.ScrollBarThickness = 8
        playerScroll.Parent = playerFrame
        
        local playerListLayout = Instance.new("UIListLayout")
        playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        playerListLayout.Padding = UDim.new(0, 5)
        playerListLayout.Parent = playerScroll
        
        local function refreshPlayerList()
            for _, child in pairs(playerScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local playerBtn = Instance.new("TextButton")
                    playerBtn.Size = UDim2.new(1, -10, 0, 40)
                    playerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    playerBtn.Text = "📍 " .. player.Name
                    playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    playerBtn.TextSize = 12
                    playerBtn.Font = Enum.Font.Gotham
                    playerBtn.TextXAlignment = Enum.TextXAlignment.Left
                    playerBtn.Parent = playerScroll
                    
                    playerBtn.MouseButton1Click:Connect(function()
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            pcall(function()
                                LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                                log("✅ Teleported to " .. player.Name, "success")
                                createNotification("✅ Teleported", "Moved to " .. player.Name, 3)
                            end)
                        end
                    end)
                end
            end
            
            playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerListLayout.AbsoluteContentSize.Y + 10)
        end
        
        -- ==================== BUTTONS ====================
        local btnY = -40
        
        -- Copy Button
        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(0.19, 0, 0, 35)
        copyBtn.Position = UDim2.new(0.01, 0, 1, btnY)
        copyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        copyBtn.Text = "📋"
        copyBtn.TextSize = 16
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.Parent = logFrame
        copyBtn.MouseButton1Click:Connect(saveLogToClipboard)
        
        -- Stop/Start Button
        local stopBtn = Instance.new("TextButton")
        stopBtn.Size = UDim2.new(0.19, 0, 0, 35)
        stopBtn.Position = UDim2.new(0.21, 0, 1, btnY)
        stopBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        stopBtn.Text = "⏸️"
        stopBtn.TextSize = 16
        stopBtn.Font = Enum.Font.GothamBold
        stopBtn.Parent = logFrame
        
        stopBtn.MouseButton1Click:Connect(function()
            IS_RUNNING = not IS_RUNNING
            stopBtn.Text = IS_RUNNING and "⏸️" or "▶️"
            stopBtn.BackgroundColor3 = IS_RUNNING and Color3.fromRGB(200, 100, 0) or Color3.fromRGB(0, 150, 0)
            log(IS_RUNNING and "▶️ AUTO HOP RESUMED!" or "⏸️ AUTO HOP STOPPED!", IS_RUNNING and "success" or "warning")
        end)
        
        -- Totem Button
        local totemBtn = Instance.new("TextButton")
        totemBtn.Size = UDim2.new(0.19, 0, 0, 35)
        totemBtn.Position = UDim2.new(0.41, 0, 1, btnY)
        totemBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        totemBtn.Text = "🗿"
        totemBtn.TextSize = 16
        totemBtn.Font = Enum.Font.GothamBold
        totemBtn.Parent = logFrame
        
        totemBtn.MouseButton1Click:Connect(function()
            totemFrame.Visible = not totemFrame.Visible
            if totemFrame.Visible then
                refreshTotemList()
            end
        end)
        
        -- Player Button
        local playerBtn = Instance.new("TextButton")
        playerBtn.Size = UDim2.new(0.19, 0, 0, 35)
        playerBtn.Position = UDim2.new(0.61, 0, 1, btnY)
        playerBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        playerBtn.Text = "👥"
        playerBtn.TextSize = 16
        playerBtn.Font = Enum.Font.GothamBold
        playerBtn.Parent = logFrame
        
        playerBtn.MouseButton1Click:Connect(function()
            playerFrame.Visible = not playerFrame.Visible
            if playerFrame.Visible then
                refreshPlayerList()
            end
        end)
        
        -- Close Button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0.19, 0, 0, 35)
        closeBtn.Position = UDim2.new(0.81, 0, 1, btnY)
        closeBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        closeBtn.Text = "❌"
        closeBtn.TextSize = 16
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = logFrame
        closeBtn.MouseButton1Click:Connect(function() logFrame.Visible = false end)
        
        -- Totem Frame Buttons
        local refreshTotemBtn = Instance.new("TextButton")
        refreshTotemBtn.Size = UDim2.new(0.48, -2, 0, 35)
        refreshTotemBtn.Position = UDim2.new(0.01, 0, 1, -40)
        refreshTotemBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        refreshTotemBtn.Text = "🔄 SCAN"
        refreshTotemBtn.TextSize = 13
        refreshTotemBtn.Font = Enum.Font.GothamBold
        refreshTotemBtn.Parent = totemFrame
        refreshTotemBtn.MouseButton1Click:Connect(refreshTotemList)
        
        local closeTotemBtn = Instance.new("TextButton")
        closeTotemBtn.Size = UDim2.new(0.48, -2, 0, 35)
        closeTotemBtn.Position = UDim2.new(0.51, 0, 1, -40)
        closeTotemBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        closeTotemBtn.Text = "❌ CLOSE"
        closeTotemBtn.TextSize = 13
        closeTotemBtn.Font = Enum.Font.GothamBold
        closeTotemBtn.Parent = totemFrame
        closeTotemBtn.MouseButton1Click:Connect(function() totemFrame.Visible = false end)
        
        -- Player Frame Buttons
        local refreshPlayerBtn = Instance.new("TextButton")
        refreshPlayerBtn.Size = UDim2.new(0.48, -2, 0, 35)
        refreshPlayerBtn.Position = UDim2.new(0.01, 0, 1, -40)
        refreshPlayerBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        refreshPlayerBtn.Text = "🔄 REFRESH"
        refreshPlayerBtn.TextSize = 13
        refreshPlayerBtn.Font = Enum.Font.GothamBold
        refreshPlayerBtn.Parent = playerFrame
        refreshPlayerBtn.MouseButton1Click:Connect(refreshPlayerList)
        
        local closePlayerBtn = Instance.new("TextButton")
        closePlayerBtn.Size = UDim2.new(0.48, -2, 0, 35)
        closePlayerBtn.Position = UDim2.new(0.51, 0, 1, -40)
        closePlayerBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        closePlayerBtn.Text = "❌ CLOSE"
        closePlayerBtn.TextSize = 13
        closePlayerBtn.Font = Enum.Font.GothamBold
        closePlayerBtn.Parent = playerFrame
        closePlayerBtn.MouseButton1Click:Connect(function() playerFrame.Visible = false end)
        
        -- Toggle Button
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 80, 0, 30)
        toggleBtn.Position = UDim2.new(1, -85, 0, 5)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        toggleBtn.Text = "⚙ MENU"
        toggleBtn.TextSize = 12
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Parent = screenGui
        toggleBtn.MouseButton1Click:Connect(function() logFrame.Visible = not logFrame.Visible end)
        
        -- Update log text
        spawn(function()
            while true do
                wait(1)
                logText.Text = table.concat(LOG_HISTORY, "\n")
                logScroll.CanvasSize = UDim2.new(0, 0, 0, logText.TextBounds.Y + 10)
                logScroll.CanvasPosition = Vector2.new(0, logScroll.CanvasSize.Y.Offset)
                
                -- Update server type display
                logTitle.Text = "📊 LOG VIEWER - Server: " .. CURRENT_SERVER_TYPE
            end
        end)
        
        -- Auto scan totem
        spawn(function()
            while true do
                wait(TOTEM_SCAN_INTERVAL)
                if totemFrame.Visible then
                    refreshTotemList()
                end
            end
        end)
        
        screenGui.Parent = game:GetService("CoreGui")
        log("✅ Enhanced GUI created!", "success")
    end)
    
    if not success then
        log("❌ Failed to create GUI: " .. tostring(err), "error")
    end
end

-- Fungsi rejoin dengan server type detection
local function rejoinGame()
    log("========== REJOIN PROCESS STARTED ==========", "info")
    log("Current Server Type: " .. CURRENT_SERVER_TYPE, "info")
    
    local success, err = pcall(function()
        local serverList = {}
        local cursor = ""
        
        -- Jika server Private, langsung rejoin tanpa server hopping
        if CURRENT_SERVER_TYPE == "Private" then
            log("🔒 Private Server detected - Direct rejoin", "info")
            createNotification("🔄 Rejoining", "Reconnecting to private server...", 3)
            wait(1)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
            return
        end
        
        -- Public server - lakukan server hopping
        log("🌐 Public Server - Finding another public server...", "info")
        
        repeat
            local url = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100&cursor=%s",
                game.PlaceId,
                cursor
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
            log("✅ Found public server: " .. randomServer, "success")
            createNotification("🚀 Hopping", "Moving to another public server...", 3)
            wait(1)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
        else
            log("⚠️ No servers found, fallback rejoin", "warning")
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    
    if not success then
        log("❌ CRITICAL ERROR: " .. tostring(err), "error")
        createNotification("❌ Error", "Rejoin failed!", 5)
        wait(2)
        pcall(function()
            LocalPlayer:Kick("Auto Rejoin - Reconnecting...")
        end)
    end
end

-- Main loop
local function startAutoRejoin()
    log("=================================================", "info")
    log("✅ FISH IT ENHANCED UTILITY STARTED!", "success")
    log("=================================================", "info")
    
    -- Detect server type
    detectServerType()
    
    log("Rejoin Interval: " .. REJOIN_INTERVAL .. " seconds", "info")
    log("PlaceId: " .. tostring(game.PlaceId), "info")
    log("Player: " .. tostring(LocalPlayer.Name), "info")
    log("=================================================", "info")
    
    -- Initial totem scan
    scanTotems()
    
    spawn(function()
        local countdown = REJOIN_INTERVAL
        
        while true do
            if IS_RUNNING then
                if countdown > 0 then
                    log("⏳ Next rejoin in " .. countdown .. "s | Totems: " .. #DETECTED_TOTEMS, "info")
                    wait(1)
                    countdown = countdown - 1
                else
                    log("🚀 COUNTDOWN COMPLETE! Starting rejoin...", "success")
                    rejoinGame()
                    countdown = REJOIN_INTERVAL
                end
            else
                log("⏸️ Auto hop PAUSED", "warning")
                countdown = REJOIN_INTERVAL
                wait(2)
            end
        end
    end)
end

-- Initialize
log("Initializing Fish It Enhanced Utility...", "info")
createGUI()
createNotification("✅ LOADED!", "Enhanced utility ready!", 5)
wait(2)
startAutoRejoin()
log("🎮 Script fully running!", "success")
