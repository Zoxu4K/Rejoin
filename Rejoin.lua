
-- Fish It Auto Rejoin Utility + Totem Detector - MOBILE VERSION
-- Compatible with Delta Executor
-- Features: Auto rejoin, Server type detection, Totem detector & teleport

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Konfigurasi
local REJOIN_INTERVAL = 15
local AUTO_EXECUTE = true
local IS_RUNNING = true
local IS_PRIVATE_SERVER = false -- Deteksi otomatis

-- TOTEM CONFIGURATION
local TOTEM_NAMES = {
    ["Luck Totem"] = true,
    ["Shiny Totem"] = true,
    ["Mutation Totem"] = true
}

local DETECTED_TOTEMS = {} -- {name, position, distance, spawnTime, duration}
local TOTEM_CHECK_INTERVAL = 2 -- Check setiap 2 detik

-- LOG STORAGE
local LOG_HISTORY = {}
local MAX_LOGS = 100

-- Logging function dengan penyimpanan
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

-- Fungsi untuk kirim log ke webhook Discord
local function sendLogToWebhook(logText)
    local WEBHOOK_URL = ""
    
    if WEBHOOK_URL ~= "" then
        local success, err = pcall(function()
            local data = {
                ["content"] = "```" .. logText .. "```"
            }
            request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(data)
            })
        end)
        
        if success then
            log("✅ Log sent to Discord webhook", "success")
        else
            log("❌ Failed to send log to webhook: " .. tostring(err), "error")
        end
    end
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

-- DETEKSI SERVER TYPE (Public/Private)
local function detectServerType()
    local isPrivate = false
    
    -- Method 1: Check PrivateServerId
    if game.PrivateServerId ~= "" and game.PrivateServerId ~= nil then
        isPrivate = true
        log("🔐 PRIVATE SERVER detected via PrivateServerId", "info")
    end
    
    -- Method 2: Check PrivateServerOwnerId
    if game.PrivateServerOwnerId ~= 0 then
        isPrivate = true
        log("🔐 PRIVATE SERVER detected via PrivateServerOwnerId", "info")
    end
    
    -- Method 3: Check VIPServerId (alternative)
    local success, result = pcall(function()
        return game.VIPServerId
    end)
    if success and result ~= "" and result ~= nil then
        isPrivate = true
        log("🔐 PRIVATE SERVER detected via VIPServerId", "info")
    end
    
    IS_PRIVATE_SERVER = isPrivate
    
    if isPrivate then
        log("========================================", "info")
        log("🔐 SERVER TYPE: PRIVATE SERVER", "success")
        log("========================================", "info")
        createNotification("🔐 Private Server", "Hopping will stay in private servers", 5)
    else
        log("========================================", "info")
        log("🌐 SERVER TYPE: PUBLIC SERVER", "success")
        log("========================================", "info")
        createNotification("🌐 Public Server", "Hopping will stay in public servers", 5)
    end
    
    return isPrivate
end

-- TOTEM DETECTOR
local function getPlayerPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Position
    end
    return nil
end

local function calculateDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

local function scanForTotems()
    local playerPos = getPlayerPosition()
    if not playerPos then return end
    
    local foundTotems = {}
    local currentTime = tick()
    
    -- Scan Workspace untuk totem
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local objName = obj.Name
            
            -- Check if it's a totem
            if TOTEM_NAMES[objName] then
                local totemPos = nil
                
                if obj:IsA("Model") and obj:FindFirstChild("PrimaryPart") then
                    totemPos = obj.PrimaryPart.Position
                elseif obj:IsA("Model") and obj:FindFirstChildWhichIsA("Part") then
                    totemPos = obj:FindFirstChildWhichIsA("Part").Position
                elseif obj:IsA("Part") then
                    totemPos = obj.Position
                end
                
                if totemPos then
                    local distance = calculateDistance(playerPos, totemPos)
                    
                    -- Check if totem already tracked
                    local existingTotem = nil
                    for i, totem in pairs(DETECTED_TOTEMS) do
                        if totem.name == objName and totem.object == obj then
                            existingTotem = totem
                            break
                        end
                    end
                    
                    if existingTotem then
                        -- Update existing totem
                        existingTotem.position = totemPos
                        existingTotem.distance = distance
                        existingTotem.elapsed = currentTime - existingTotem.spawnTime
                        table.insert(foundTotems, existingTotem)
                    else
                        -- New totem detected
                        local newTotem = {
                            name = objName,
                            position = totemPos,
                            distance = distance,
                            spawnTime = currentTime,
                            elapsed = 0,
                            object = obj
                        }
                        table.insert(DETECTED_TOTEMS, newTotem)
                        table.insert(foundTotems, newTotem)
                        
                        log("🎯 NEW TOTEM DETECTED: " .. objName .. " at " .. math.floor(distance) .. " studs", "success")
                        createNotification("🎯 Totem Found!", objName .. " - " .. math.floor(distance) .. " studs away", 5)
                    end
                end
            end
        end
    end
    
    -- Remove totems yang sudah hilang
    for i = #DETECTED_TOTEMS, 1, -1 do
        local totem = DETECTED_TOTEMS[i]
        if not totem.object or not totem.object.Parent then
            log("⚠️ TOTEM DESPAWNED: " .. totem.name, "warning")
            table.remove(DETECTED_TOTEMS, i)
        end
    end
    
    return foundTotems
end

local function teleportToTotem(totem)
    if not totem or not totem.object or not totem.object.Parent then
        log("❌ Totem no longer exists!", "error")
        createNotification("❌ Failed", "Totem not found!", 3)
        return false
    end
    
    local success, err = pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(totem.position)
        end
    end)
    
    if success then
        log("✅ Teleported to " .. totem.name, "success")
        createNotification("✅ Teleported", "Teleported to " .. totem.name, 3)
        return true
    else
        log("❌ Teleport failed: " .. tostring(err), "error")
        createNotification("❌ Failed", "Teleport failed!", 3)
        return false
    end
end

local function teleportToNearestTotem()
    if #DETECTED_TOTEMS == 0 then
        log("⚠️ No totems detected!", "warning")
        createNotification("⚠️ No Totems", "No totems found nearby", 3)
        return
    end
    
    local playerPos = getPlayerPosition()
    if not playerPos then return end
    
    -- Find nearest totem
    local nearest = nil
    local minDistance = math.huge
    
    for _, totem in pairs(DETECTED_TOTEMS) do
        if totem.distance < minDistance then
            minDistance = totem.distance
            nearest = totem
        end
    end
    
    if nearest then
        log("🎯 Teleporting to nearest totem: " .. nearest.name .. " (" .. math.floor(nearest.distance) .. " studs)", "info")
        teleportToTotem(nearest)
    end
end

-- CREATE MAIN GUI MENU
local function createMainGUI()
    log("Creating main GUI menu...", "info")
    
    local success, err = pcall(function()
        -- Create ScreenGui
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FishItMainGUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- ========== MAIN MENU FRAME ==========
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0, 380, 0, 500)
        mainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
        mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        mainFrame.BorderSizePixel = 2
        mainFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
        mainFrame.Active = true
        mainFrame.Draggable = true
        mainFrame.Parent = screenGui
        
        -- UI Corner
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = mainFrame
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        title.BorderSizePixel = 0
        title.Text = "🎮 FISH IT UTILITY MENU"
        title.TextColor3 = Color3.fromRGB(100, 200, 255)
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.Parent = mainFrame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 10)
        titleCorner.Parent = title
        
        -- Server Info Label
        local serverInfo = Instance.new("TextLabel")
        serverInfo.Name = "ServerInfo"
        serverInfo.Size = UDim2.new(1, -20, 0, 60)
        serverInfo.Position = UDim2.new(0, 10, 0, 50)
        serverInfo.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        serverInfo.BorderSizePixel = 1
        serverInfo.BorderColor3 = Color3.fromRGB(60, 60, 80)
        serverInfo.Text = "Server: Loading..."
        serverInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
        serverInfo.TextSize = 13
        serverInfo.Font = Enum.Font.Gotham
        serverInfo.TextWrapped = true
        serverInfo.Parent = mainFrame
        
        local serverCorner = Instance.new("UICorner")
        serverCorner.CornerRadius = UDim.new(0, 8)
        serverCorner.Parent = serverInfo
        
        -- Update server info
        spawn(function()
            wait(1)
            local serverType = IS_PRIVATE_SERVER and "🔐 PRIVATE" or "🌐 PUBLIC"
            local playerCount = #Players:GetPlayers()
            serverInfo.Text = "Server: " .. serverType .. "\nPlayers: " .. playerCount .. "\nJobId: " .. game.JobId:sub(1, 20) .. "..."
        end)
        
        -- ========== BUTTONS SECTION ==========
        local buttonY = 120
        local buttonHeight = 45
        local buttonSpacing = 10
        
        -- Function to create button
        local function createButton(name, text, color, yPos, callback)
            local btn = Instance.new("TextButton")
            btn.Name = name
            btn.Size = UDim2.new(1, -20, 0, buttonHeight)
            btn.Position = UDim2.new(0, 10, 0, yPos)
            btn.BackgroundColor3 = color
            btn.BorderSizePixel = 0
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 14
            btn.Font = Enum.Font.GothamBold
            btn.Parent = mainFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 8)
            btnCorner.Parent = btn
            
            btn.MouseButton1Click:Connect(callback)
            
            return btn
        end
        
        -- Button 1: Toggle Auto Hop
        local toggleBtn = createButton("ToggleButton", "⏸️ PAUSE AUTO HOP", Color3.fromRGB(200, 100, 0), buttonY, function()
            IS_RUNNING = not IS_RUNNING
            
            if IS_RUNNING then
                toggleBtn.Text = "⏸️ PAUSE AUTO HOP"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
                log("▶️ AUTO HOP RESUMED!", "success")
                createNotification("▶️ Started", "Auto hop resumed!", 3)
            else
                toggleBtn.Text = "▶️ START AUTO HOP"
                toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                log("⏸️ AUTO HOP STOPPED!", "warning")
                createNotification("⏸️ Stopped", "Auto hop paused", 3)
            end
        end)
        
        buttonY = buttonY + buttonHeight + buttonSpacing
        
        -- Button 2: Totem Detector
        createButton("TotemButton", "🎯 TOTEM DETECTOR", Color3.fromRGB(0, 120, 215), buttonY, function()
            -- Will be handled by totem frame toggle
            local totemFrame = screenGui:FindFirstChild("TotemFrame")
            if totemFrame then
                totemFrame.Visible = not totemFrame.Visible
            end
        end)
        
        buttonY = buttonY + buttonHeight + buttonSpacing
        
        -- Button 3: Player List & Teleport
        createButton("PlayerButton", "👥 PLAYER TELEPORT", Color3.fromRGB(100, 50, 200), buttonY, function()
            local playerFrame = screenGui:FindFirstChild("PlayerFrame")
            if playerFrame then
                playerFrame.Visible = not playerFrame.Visible
                -- Refresh player list when opened
                if playerFrame.Visible then
                    local refreshFunc = getfenv().refreshPlayerList
                    if refreshFunc then refreshFunc() end
                end
            end
        end)
        
        buttonY = buttonY + buttonHeight + buttonSpacing
        
        -- Button 4: Log Viewer
        createButton("LogButton", "📋 VIEW LOGS", Color3.fromRGB(0, 170, 100), buttonY, function()
            local logFrame = screenGui:FindFirstChild("LogFrame")
            if logFrame then
                logFrame.Visible = not logFrame.Visible
            end
        end)
        
        buttonY = buttonY + buttonHeight + buttonSpacing
        
        -- Button 5: Copy Logs
        createButton("CopyButton", "📄 COPY LOGS", Color3.fromRGB(0, 150, 150), buttonY, function()
            saveLogToClipboard()
        end)
        
        buttonY = buttonY + buttonHeight + buttonSpacing
        
        -- Button 6: Rejoin Now
        createButton("RejoinButton", "🔄 REJOIN NOW", Color3.fromRGB(200, 150, 0), buttonY, function()
            log("🚀 Manual rejoin triggered!", "info")
            createNotification("🚀 Rejoining", "Manual server hop...", 3)
            wait(1)
            rejoinGame()
        end)
        
        -- ========== MINIMIZE BUTTON ==========
        local minimizeBtn = Instance.new("TextButton")
        minimizeBtn.Name = "MinimizeButton"
        minimizeBtn.Size = UDim2.new(0, 80, 0, 30)
        minimizeBtn.Position = UDim2.new(1, -90, 0, 5)
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        minimizeBtn.BorderSizePixel = 0
        minimizeBtn.Text = "➖"
        minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minimizeBtn.TextSize = 16
        minimizeBtn.Font = Enum.Font.GothamBold
        minimizeBtn.Parent = mainFrame
        
        local minCorner = Instance.new("UICorner")
        minCorner.CornerRadius = UDim.new(0, 6)
        minCorner.Parent = minimizeBtn
        
        minimizeBtn.MouseButton1Click:Connect(function()
            mainFrame.Visible = false
        end)
        
        -- ========== TOGGLE BUTTON (when minimized) ==========
        local toggleMainBtn = Instance.new("TextButton")
        toggleMainBtn.Name = "ToggleMainButton"
        toggleMainBtn.Size = UDim2.new(0, 70, 0, 30)
        toggleMainBtn.Position = UDim2.new(1, -80, 0, 10)
        toggleMainBtn.AnchorPoint = Vector2.new(0, 0)
        toggleMainBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        toggleMainBtn.BorderSizePixel = 1
        toggleMainBtn.BorderColor3 = Color3.fromRGB(100, 200, 255)
        toggleMainBtn.Text = "⚙️ MENU"
        toggleMainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleMainBtn.TextSize = 12
        toggleMainBtn.Font = Enum.Font.GothamBold
        toggleMainBtn.Parent = screenGui
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 6)
        toggleCorner.Parent = toggleMainBtn
        
        toggleMainBtn.MouseButton1Click:Connect(function()
            mainFrame.Visible = not mainFrame.Visible
        end)
        
        screenGui.Parent = game:GetService("CoreGui")
        log("✅ Main GUI created successfully!", "success")
    end)
    
    if not success then
        log("❌ Failed to create main GUI: " .. tostring(err), "error")
    end
end

-- CREATE TOTEM DETECTOR GUI
local function createTotemGUI()
    log("Creating totem detector GUI...", "info")

    local success, err = pcall(function()
        local screenGui = game:GetService("CoreGui"):FindFirstChild("FishItMainGUI")
        if not screenGui then
            log("❌ Main GUI not found!", "error")
            return
        end
        
        -- ========== TOTEM FRAME ==========
        local totemFrame = Instance.new("Frame")
        totemFrame.Name = "TotemFrame"
        totemFrame.Size = UDim2.new(0, 400, 0, 450)
        totemFrame.Position = UDim2.new(0.5, -200, 0.5, -225)
        totemFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        totemFrame.BorderSizePixel = 2
        totemFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
        totemFrame.Active = true
        totemFrame.Draggable = true
        totemFrame.Visible = false
        totemFrame.Parent = screenGui
        
        local totemCorner = Instance.new("UICorner")
        totemCorner.CornerRadius = UDim.new(0, 10)
        totemCorner.Parent = totemFrame
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        title.BorderSizePixel = 0
        title.Text = "🎯 TOTEM DETECTOR"
        title.TextColor3 = Color3.fromRGB(100, 200, 255)
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.Parent = totemFrame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 10)
        titleCorner.Parent = title
        
        -- Info Label
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Name = "InfoLabel"
        infoLabel.Size = UDim2.new(1, -20, 0, 30)
        infoLabel.Position = UDim2.new(0, 10, 0, 50)
        infoLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        infoLabel.BorderSizePixel = 0
        infoLabel.Text = "🔍 Scanning for totems..."
        infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        infoLabel.TextSize = 12
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.Parent = totemFrame
        
        local infoCorner = Instance.new("UICorner")
        infoCorner.CornerRadius = UDim.new(0, 8)
        infoCorner.Parent = infoLabel
        
        -- ScrollingFrame untuk totem list
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "TotemScroll"
        scrollFrame.Size = UDim2.new(1, -20, 1, -150)
        scrollFrame.Position = UDim2.new(0, 10, 0, 90)
        scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        scrollFrame.BorderSizePixel = 1
        scrollFrame.BorderColor3 = Color3.fromRGB(60, 60, 80)
        scrollFrame.ScrollBarThickness = 8
        scrollFrame.Parent = totemFrame
        
        local scrollCorner = Instance.new("UICorner")
        scrollCorner.CornerRadius = UDim.new(0, 8)
        scrollCorner.Parent = scrollFrame
        
        -- UIListLayout untuk totem buttons
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 8)
        listLayout.Parent = scrollFrame
        
        -- Function to update totem list
        local function updateTotemList()
            -- Clear existing buttons
            for _, child in pairs(scrollFrame:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            local totems = scanForTotems()
            
            if #totems == 0 then
                infoLabel.Text = "⚠️ No totems detected"
                infoLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
            else
                infoLabel.Text = "✅ Found " .. #totems .. " totem(s)"
                infoLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
            end
            
            -- Create totem entry for each detected totem
            for i, totem in pairs(totems) do
                local totemEntry = Instance.new("Frame")
                totemEntry.Name = "TotemEntry" .. i
                totemEntry.Size = UDim2.new(1, -10, 0, 80)
                totemEntry.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                totemEntry.BorderSizePixel = 1
                totemEntry.BorderColor3 = Color3.fromRGB(60, 60, 80)
                totemEntry.Parent = scrollFrame
                
                local entryCorner = Instance.new("UICorner")
                entryCorner.CornerRadius = UDim.new(0, 8)
                entryCorner.Parent = totemEntry
                
                -- Totem icon/emoji based on type
                local icon = "🍀" -- Default
                if totem.name:find("Luck") then
                    icon = "🍀"
                elseif totem.name:find("Shiny") then
                    icon = "✨"
                elseif totem.name:find("Mutation") then
                    icon = "🧬"
                end
                
                -- Totem Name Label
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Name = "NameLabel"
                nameLabel.Size = UDim2.new(1, -10, 0, 25)
                nameLabel.Position = UDim2.new(0, 5, 0, 5)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = icon .. " " .. totem.name
                nameLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
                nameLabel.TextSize = 14
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = totemEntry
                
                -- Distance & Time Label
                local detailLabel = Instance.new("TextLabel")
                detailLabel.Name = "DetailLabel"
                detailLabel.Size = UDim2.new(1, -10, 0, 20)
                detailLabel.Position = UDim2.new(0, 5, 0, 30)
                detailLabel.BackgroundTransparency = 1
                detailLabel.Text = "📏 Distance: " .. math.floor(totem.distance) .. " studs | ⏱️ Time: " .. formatTime(totem.elapsed)
                detailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                detailLabel.TextSize = 11
                detailLabel.Font = Enum.Font.Gotham
                detailLabel.TextXAlignment = Enum.TextXAlignment.Left
                detailLabel.Parent = totemEntry
                
                -- Teleport Button
                local tpBtn = Instance.new("TextButton")
                tpBtn.Name = "TeleportButton"
                tpBtn.Size = UDim2.new(1, -10, 0, 25)
                tpBtn.Position = UDim2.new(0, 5, 0, 52)
                tpBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
                tpBtn.BorderSizePixel = 0
                tpBtn.Text = "🚀 TELEPORT TO THIS TOTEM"
                tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                tpBtn.TextSize = 12
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.Parent = totemEntry
                
                local tpCorner = Instance.new("UICorner")
                tpCorner.CornerRadius = UDim.new(0, 6)
                tpCorner.Parent = tpBtn
                
                tpBtn.MouseButton1Click:Connect(function()
                    teleportToTotem(totem)
                end)
            end
            
            -- Update canvas size
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
        end
        
        -- Button: TP to Nearest
        local nearestBtn = Instance.new("TextButton")
        nearestBtn.Name = "NearestButton"
        nearestBtn.Size = UDim2.new(0.48, -5, 0, 35)
        nearestBtn.Position = UDim2.new(0.01, 0, 1, -45)
        nearestBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        nearestBtn.BorderSizePixel = 0
        nearestBtn.Text = "🎯 TP NEAREST"
        nearestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        nearestBtn.TextSize = 13
        nearestBtn.Font = Enum.Font.GothamBold
        nearestBtn.Parent = totemFrame
        
        local nearestCorner = Instance.new("UICorner")
        nearestCorner.CornerRadius = UDim.new(0, 8)
        nearestCorner.Parent = nearestBtn
        
        nearestBtn.MouseButton1Click:Connect(function()
            teleportToNearestTotem()
        end)
        
        -- Button: Refresh
        local refreshBtn = Instance.new("TextButton")
        refreshBtn.Name = "RefreshButton"
        refreshBtn.Size = UDim2.new(0.23, -5, 0, 35)
        refreshBtn.Position = UDim2.new(0.51, 0, 1, -45)
        refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        refreshBtn.BorderSizePixel = 0
        refreshBtn.Text = "🔄"
        refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        refreshBtn.TextSize = 16
        refreshBtn.Font = Enum.Font.GothamBold
        refreshBtn.Parent = totemFrame
        
        local refreshCorner = Instance.new("UICorner")
        refreshCorner.CornerRadius = UDim.new(0, 8)
        refreshCorner.Parent = refreshBtn
        
        refreshBtn.MouseButton1Click:Connect(function()
            log("🔄 Refreshing totem list...", "info")
            updateTotemList()
        end)
        
        -- Button: Close
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Size = UDim2.new(0.23, -5, 0, 35)
        closeBtn.Position = UDim2.new(0.76, 0, 1, -45)
        closeBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "❌"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 16
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = totemFrame
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = closeBtn
        
        closeBtn.MouseButton1Click:Connect(function()
            totemFrame.Visible = false
        end)
        
        -- Auto-update totem list
        spawn(function()
            while true do
                wait(TOTEM_CHECK_INTERVAL)
                if totemFrame.Visible then
                    updateTotemList()
                end
            end
        end)
        
        -- Initial update
        updateTotemList()
        
        log("✅ Totem detector GUI created!", "success")
    end)
    
    if not success then
        log("❌ Failed to create totem GUI: " .. tostring(err), "error")
    end
end

-- CREATE PLAYER LIST GUI
local function createPlayerListGUI()
    log("Creating player list GUI...", "info")
    
    local success, err = pcall(function()
        local screenGui = game:GetService("CoreGui"):FindFirstChild("FishItMainGUI")
        if not screenGui then
            log("❌ Main GUI not found!", "error")
            return
        end
        
        -- ========== PLAYER FRAME ==========
        local playerFrame = Instance.new("Frame")
        playerFrame.Name = "PlayerFrame"
        playerFrame.Size = UDim2.new(0, 380, 0, 450)
        playerFrame.Position = UDim2.new(0.5, -190, 0.5, -225)
        playerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        playerFrame.BorderSizePixel = 2
        playerFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
        playerFrame.Active = true
        playerFrame.Draggable = true
        playerFrame.Visible = false
        playerFrame.Parent = screenGui
        
        local playerCorner = Instance.new("UICorner")
        playerCorner.CornerRadius = UDim.new(0, 10)
        playerCorner.Parent = playerFrame
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        title.BorderSizePixel = 0
        title.Text = "👥 PLAYER TELEPORT"
        title.TextColor3 = Color3.fromRGB(100, 200, 255)
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.Parent = playerFrame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 10)
        titleCorner.Parent = title
        
        -- Info Label
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Name = "InfoLabel"
        infoLabel.Size = UDim2.new(1, -20, 0, 30)
        infoLabel.Position = UDim2.new(0, 10, 0, 50)
        infoLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        infoLabel.BorderSizePixel = 0
        infoLabel.Text = "👥 Loading players..."
        infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        infoLabel.TextSize = 12
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.Parent = playerFrame
        
        local infoCorner = Instance.new("UICorner")
        infoCorner.CornerRadius = UDim.new(0, 8)
        infoCorner.Parent = infoLabel
        
        -- ScrollingFrame untuk player list
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "PlayerScroll"
        scrollFrame.Size = UDim2.new(1, -20, 1, -150)
        scrollFrame.Position = UDim2.new(0, 10, 0, 90)
        scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        scrollFrame.BorderSizePixel = 1
        scrollFrame.BorderColor3 = Color3.fromRGB(60, 60, 80)
        scrollFrame.ScrollBarThickness = 8
        scrollFrame.Parent = playerFrame
        
        local scrollCorner = Instance.new("UICorner")
        scrollCorner.CornerRadius = UDim.new(0, 8)
        scrollCorner.Parent = scrollFrame
        
        -- UIListLayout
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 5)
        listLayout.Parent = scrollFrame
        
        -- Function to refresh player list
        function refreshPlayerList()
            -- Clear existing buttons
            for _, child in pairs(scrollFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            log("🔄 Refreshing player list...", "info")
            local playerCount = 0
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    playerCount = playerCount + 1
                    
                    local playerBtn = Instance.new("TextButton")
                    playerBtn.Name = player.Name
                    playerBtn.Size = UDim2.new(1, -10, 0, 50)
                    playerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
                    playerBtn.BorderSizePixel = 1
                    playerBtn.BorderColor3 = Color3.fromRGB(80, 80, 100)
                    playerBtn.Text = "📍 " .. player.Name .. "\n(" .. player.DisplayName .. ")"
                    playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    playerBtn.TextSize = 12
                    playerBtn.Font = Enum.Font.Gotham
                    playerBtn.TextXAlignment = Enum.TextXAlignment.Left
                    playerBtn.Parent = scrollFrame
                    
                    local btnCorner = Instance.new("UICorner")
                    btnCorner.CornerRadius = UDim.new(0, 8)
                    btnCorner.Parent = playerBtn
                    
                    playerBtn.MouseButton1Click:Connect(function()
                        local targetPlayer = player
                        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local tpSuccess, tpErr = pcall(function()
                                LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                            end)
                            
                            if tpSuccess then
                                log("✅ Teleported to " .. targetPlayer.Name, "success")
                                createNotification("✅ Teleported", "Teleported to " .. targetPlayer.Name, 3)
                            else
                                log("❌ Teleport failed: " .. tostring(tpErr), "error")
                                createNotification("❌ Failed", "Teleport failed!", 3)
                            end
                        else
                            log("⚠️ Player character not found: " .. targetPlayer.Name, "warning")
                            createNotification("⚠️ Warning", "Player not found!", 3)
                        end
                    end)
                end
            end
            
            infoLabel.Text = "✅ Found " .. playerCount .. " player(s)"
            log("✅ Player list refreshed! Found " .. playerCount .. " players", "success")
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
        end
        
        -- Button: Refresh
        local refreshBtn = Instance.new("TextButton")
        refreshBtn.Name = "RefreshButton"
        refreshBtn.Size = UDim2.new(0.48, -5, 0, 35)
        refreshBtn.Position = UDim2.new(0.01, 0, 1, -45)
        refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        refreshBtn.BorderSizePixel = 0
        refreshBtn.Text = "🔄 REFRESH"
        refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        refreshBtn.TextSize = 13
        refreshBtn.Font = Enum.Font.GothamBold
        refreshBtn.Parent = playerFrame
        
        local refreshCorner = Instance.new("UICorner")
        refreshCorner.CornerRadius = UDim.new(0, 8)
        refreshCorner.Parent = refreshBtn
        
        refreshBtn.MouseButton1Click:Connect(function()
            refreshPlayerList()
        end)
        
        -- Button: Close
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Size = UDim2.new(0.48, -5, 0, 35)
        closeBtn.Position = UDim2.new(0.51, 0, 1, -45)
        closeBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "❌ CLOSE"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 13
        refreshBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = playerFrame
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = closeBtn
        
        closeBtn.MouseButton1Click:Connect(function()
            playerFrame.Visible = false
        end)
        
        -- Initial refresh
        refreshPlayerList()
        
        -- Auto refresh every 10 seconds
        spawn(function()
            while true do
                wait(10)
                if playerFrame.Visible then
                    refreshPlayerList()
                end
            end
        end)
        
        log("✅ Player list GUI created!", "success")
    end)
    
    if not success then
        log("❌ Failed to create player list GUI: " .. tostring(err), "error")
    end
end

-- CREATE LOG VIEWER GUI
local function createLogViewerGUI()
    log("Creating log viewer GUI...", "info")
    
    local success, err = pcall(function()
        local screenGui = game:GetService("CoreGui"):FindFirstChild("FishItMainGUI")
        if not screenGui then
            log("❌ Main GUI not found!", "error")
            return
        end
        
        -- ========== LOG FRAME ==========
        local logFrame = Instance.new("Frame")
        logFrame.Name = "LogFrame"
        logFrame.Size = UDim2.new(0, 450, 0, 400)
        logFrame.Position = UDim2.new(0.5, -225, 0.5, -200)
        logFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        logFrame.BorderSizePixel = 2
        logFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
        logFrame.Active = true
        logFrame.Draggable = true
        logFrame.Visible = false
        logFrame.Parent = screenGui
        
        local logCorner = Instance.new("UICorner")
        logCorner.CornerRadius = UDim.new(0, 10)
        logCorner.Parent = logFrame
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        title.BorderSizePixel = 0
        title.Text = "📋 LOG VIEWER"
        title.TextColor3 = Color3.fromRGB(100, 200, 255)
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.Parent = logFrame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 10)
        titleCorner.Parent = title
        
        -- ScrollingFrame untuk logs
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "LogScroll"
        scrollFrame.Size = UDim2.new(1, -20, 1, -95)
        scrollFrame.Position = UDim2.new(0, 10, 0, 50)
        scrollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        scrollFrame.BorderSizePixel = 1
        scrollFrame.BorderColor3 = Color3.fromRGB(60, 60, 80)
        scrollFrame.ScrollBarThickness = 8
        scrollFrame.Parent = logFrame
        
        local scrollCorner = Instance.new("UICorner")
        scrollCorner.CornerRadius = UDim.new(0, 8)
        scrollCorner.Parent = scrollFrame
        
        -- TextLabel untuk log text
        local logText = Instance.new("TextLabel")
        logText.Name = "LogText"
        logText.Size = UDim2.new(1, -10, 1, 0)
        logText.Position = UDim2.new(0, 5, 0, 0)
        logText.BackgroundTransparency = 1
        logText.Text = "Waiting for logs..."
        logText.TextColor3 = Color3.fromRGB(0, 255, 150)
        logText.TextSize = 11
        logText.Font = Enum.Font.Code
        logText.TextXAlignment = Enum.TextXAlignment.Left
        logText.TextYAlignment = Enum.TextYAlignment.Top
        logText.TextWrapped = true
        logText.Parent = scrollFrame
        
        -- Button: Close
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Size = UDim2.new(1, -20, 0, 35)
        closeBtn.Position = UDim2.new(0, 10, 1, -45)
        closeBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "❌ CLOSE"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 13
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = logFrame
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = closeBtn
        
        closeBtn.MouseButton1Click:Connect(function()
            logFrame.Visible = false
        end)
        
        -- Auto-update log text
        spawn(function()
            while true do
                wait(1)
                local displayLog = table.concat(LOG_HISTORY, "\n")
                logText.Text = displayLog
                
                -- Auto scroll to bottom
                scrollFrame.CanvasSize = UDim2.new(0, 0, 0, logText.TextBounds.Y + 10)
                scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
            end
        end)
        
        log("✅ Log viewer GUI created!", "success")
    end)
    
    if not success then
        log("❌ Failed to create log viewer GUI: " .. tostring(err), "error")
    end
end

-- Fungsi untuk rejoin dengan server hop method (PUBLIC/PRIVATE aware)
function rejoinGame()
    log("========== REJOIN PROCESS STARTED ==========", "info")
    log("Current PlaceId: " .. tostring(game.PlaceId), "info")
    log("Current JobId: " .. tostring(game.JobId), "info")
    log("Player Name: " .. tostring(LocalPlayer.Name), "info")
    log("Server Type: " .. (IS_PRIVATE_SERVER and "PRIVATE" or "PUBLIC"), "info")
    
    local success, err = pcall(function()
        if IS_PRIVATE_SERVER then
            -- PRIVATE SERVER REJOIN
            log("🔐 Private server detected - rejoining to private server", "info")
            log("PrivateServerId: " .. tostring(game.PrivateServerId), "info")
            
            createNotification("🔐 Private Server", "Rejoining to private server...", 3)
            wait(1)
            
            -- Rejoin ke private server yang sama
            local teleportSuccess, teleportErr = pcall(function()
                if game.PrivateServerId and game.PrivateServerId ~= "" then
                    -- Gunakan PrivateServerId untuk rejoin
                    TeleportService:TeleportToPrivateServer(
                        game.PlaceId,
                        game.PrivateServerId,
                        {LocalPlayer}
                    )
                else
                    -- Fallback: kick untuk auto-rejoin
                    LocalPlayer:Kick("🔐 Private Server Rejoin - Reconnecting...")
                end
            end)
            
            if teleportSuccess then
                log("✅ Private server rejoin initiated!", "success")
            else
                log("❌ Private server rejoin failed: " .. tostring(teleportErr), "error")
                log("Attempting emergency kick...", "warning")
                wait(1)
                LocalPlayer:Kick("🔐 Reconnecting to private server...")
            end
            
        else
            -- PUBLIC SERVER HOP
            log("🌐 Public server detected - hopping to another public server", "info")
            log("Step 1: Preparing to fetch public server list...", "info")
            
            local serverList = {}
            local cursor = ""
            local attempts = 0
            local maxAttempts = 3
            
            log("Step 2: Starting HTTP request to Roblox API...", "info")
            
            repeat
                attempts = attempts + 1
                log("Attempt " .. attempts .. "/" .. maxAttempts, "info")
                
                local url = string.format(
                    "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100&cursor=%s",
                    game.PlaceId,
                    cursor
                )
                log("Request URL: " .. url, "info")
                
                local httpSuccess, servers = pcall(function()
                    return game:HttpGet(url)
                end)
                
                if not httpSuccess then
                    log("❌ HTTP Request FAILED: " .. tostring(servers), "error")
                    break
                end
                
                log("✅ HTTP Request SUCCESS! Response length: " .. #servers, "success")
                
                local decodeSuccess, decoded = pcall(function()
                    return HttpService:JSONDecode(servers)
                end)
                
                if not decodeSuccess then
                    log("❌ JSON Decode FAILED: " .. tostring(decoded), "error")
                    break
                end
                
                log("✅ JSON Decode SUCCESS!", "success")
                
                if decoded.data then
                    log("Processing " .. #decoded.data .. " servers...", "info")
                    
                    for i, server in pairs(decoded.data) do
                        if server.playing < server.maxPlayers and server.id ~= game.JobId then
                            table.insert(serverList, server.id)
                            log("✅ Valid server #" .. i .. " added to list", "info")
                        end
                    end
                else
                    log("⚠️ No server data in response!", "warning")
                end
                
                cursor = decoded.nextPageCursor or ""
                
            until cursor == "" or #serverList >= 10 or attempts >= maxAttempts
            
            log("Step 3: Total valid PUBLIC servers found: " .. #serverList, "info")
            
            if #serverList > 0 then
                local randomServer = serverList[math.random(1, #serverList)]
                log("Step 4: Selected PUBLIC server: " .. randomServer, "success")
                log("Step 5: Calling TeleportToPlaceInstance...", "info")
                
                createNotification("🚀 Hopping", "Jumping to another PUBLIC server...", 3)
                wait(1)
                
                local teleportSuccess, teleportErr = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
                end)
                
                if teleportSuccess then
                    log("✅ TeleportToPlaceInstance SUCCESS!", "success")
                else
                    log("❌ TeleportToPlaceInstance FAILED: " .. tostring(teleportErr), "error")
                end
            else
                log("⚠️ No PUBLIC servers found, using fallback", "warning")
                createNotification("🔄 Rejoining", "Reconnecting to PUBLIC server...", 3)
                wait(1)
                
                local teleportSuccess, teleportErr = pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
                
                if teleportSuccess then
                    log("✅ Teleport SUCCESS!", "success")
                else
                    log("❌ Teleport FAILED: " .. tostring(teleportErr), "error")
                end
            end
        end
    end)
    
    if not success then
        log("❌ CRITICAL ERROR: " .. tostring(err), "error")
        createNotification("❌ Error", "Rejoin failed!", 5)
        
        -- Send log ke webhook jika ada
        sendLogToWebhook(table.concat(LOG_HISTORY, "\n"))
        
        log("Attempting emergency kick...", "warning")
        wait(2)
        pcall(function()
            LocalPlayer:Kick("Auto Rejoin - Reconnecting...")
        end)
    end
    
    log("========== REJOIN PROCESS ENDED ==========", "info")
end

-- Main loop
local function startAutoRejoin()
    log("=================================================", "info")
    log("✅ FISH IT UTILITY STARTED!", "success")
    log("=================================================", "info")
    log("Rejoin Interval: " .. REJOIN_INTERVAL .. " seconds", "info")
    log("PlaceId: " .. tostring(game.PlaceId), "info")
    log("JobId: " .. tostring(game.JobId), "info")
    log("Player: " .. tostring(LocalPlayer.Name), "info")
    log("=================================================", "info")
    
    -- Detect server type
    detectServerType()
    
    -- Test HTTP
    log("Testing HTTP capability...", "info")
    local httpTest, httpResult = pcall(function()
        return game:HttpGet("https://httpbin.org/get")
    end)
    log("HTTP Test: " .. tostring(httpTest), httpTest and "success" or "error")
    if not httpTest then
        log("❌ HTTP ERROR: " .. tostring(httpResult), "error")
        log("⚠️ WARNING: Rejoin might not work!", "warning")
    end
    
    log("Starting countdown loop...", "info")
    
    -- Countdown loop
    spawn(function()
        local countdown = REJOIN_INTERVAL
        
        while true do
            if IS_RUNNING then
                if countdown > 0 then
                    log("⏳ Next rejoin in " .. countdown .. " seconds", "info")
                    wait(1)
                    countdown = countdown - 1
                else
                    log("🚀 COUNTDOWN COMPLETE! Starting rejoin...", "success")
                    rejoinGame()
                    countdown = REJOIN_INTERVAL
                end
            else
                log("⏸️ Auto hop is PAUSED (waiting for START)", "warning")
                countdown = REJOIN_INTERVAL
                wait(2)
            end
        end
    end)
    
    log("✅ Main loop started!", "success")
end

-- Totem Scanner Background Loop
local function startTotemScanner()
    log("🎯 Starting totem scanner background service...", "info")
    
    spawn(function()
        while true do
            wait(TOTEM_CHECK_INTERVAL)
            
            -- Silent background scan
            pcall(function()
                scanForTotems()
            end)
        end
    end)
    
    log("✅ Totem scanner service started!", "success")
end

-- Setup everything
log("Initializing Fish It Utility...", "info")

-- Create all GUIs
createMainGUI()
wait(0.5)
createTotemGUI()
wait(0.5)
createPlayerListGUI()
wait(0.5)
createLogViewerGUI()

-- Notifications
createNotification("⏳ Loading...", "Initializing utility...", 3)
wait(3)
createNotification("✅ SUCCESS!", "All systems loaded!", 5)
wait(2)
createNotification("📊 MENU", "Click '⚙️ MENU' button in top-right corner!", 8)

-- Start services
startAutoRejoin()
startTotemScanner()

log("🎮 Script fully running! All features active!", "success")
log("📋 Features: Auto Hop, Totem Detector, Player TP, Logs", "info")
log("🔐 Server Type Detection: " .. (IS_PRIVATE_SERVER and "PRIVATE" or "PUBLIC"), "info")
log("=================================================", "info")
