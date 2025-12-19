-- Fish It Auto Rejoin Utility - MOBILE VERSION WITH IN-GAME LOG VIEWER
-- Compatible with Delta Executor
-- Auto rejoin ke server publik dengan player banyak

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

-- Konfigurasi
local REJOIN_INTERVAL = 3 -- 3 detik
local AUTO_EXECUTE = true
local IS_RUNNING = true
local AUTO_REEL = false -- Default OFF - Auto narik ikan
local REEL_DELAY = 0.05 -- Delay antar tap (detik)

-- LOG STORAGE
local LOG_HISTORY = {}
local MAX_LOGS = 30

-- Logging function dengan penyimpanan
local function log(message, type)
    local timestamp = os.date("%H:%M:%S")
    local prefix = "[" .. timestamp .. "]"
    local fullMessage = prefix .. " " .. message
    
    -- Simpan ke history
    table.insert(LOG_HISTORY, fullMessage)
    if #LOG_HISTORY > MAX_LOGS then
        table.remove(LOG_HISTORY, 1)
    end
    
    -- Print ke console
    if type == "error" then
        warn(fullMessage)
    else
        print(fullMessage)
    end
end

-- Fungsi untuk kirim log ke webhook Discord (OPTIONAL - ganti URL kalau mau pakai)
local function sendLogToWebhook(logText)
    local WEBHOOK_URL = "" -- ISI DENGAN DISCORD WEBHOOK URL KALAU MAU
    
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

-- AUTO REEL FUNCTION - Otomatis tap tap narik ikan
local function startAutoReel()
    spawn(function()
        while true do
            if AUTO_REEL then
                -- Simulasi tap/click cepat TERUS MENERUS
                pcall(function()
                    -- Kirim mouse click event
                    local screenSize = workspace.CurrentCamera.ViewportSize
                    local centerX = screenSize.X / 2
                    local centerY = screenSize.Y / 2
                    
                    -- Mouse down
                    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
                    task.wait(0.01)
                    -- Mouse up
                    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
                    
                    log("🎣 Tap!", "info")
                end)
            end
            
            task.wait(REEL_DELAY)
        end
    end)
end

-- CREATE IN-GAME LOG VIEWER GUI
local function createLogViewer()
    log("Creating in-game log viewer GUI...", "info")
    
    local success, err = pcall(function()
        -- Create ScreenGui
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FishItLogViewer"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Create Frame (Log Window)
        local frame = Instance.new("Frame")
        frame.Name = "LogFrame"
        frame.Size = UDim2.new(0, 400, 0, 300)
        frame.Position = UDim2.new(0.5, -200, 0.5, -150)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        frame.Active = true
        frame.Draggable = true
        frame.Parent = screenGui
        
        -- Create Frame (Player List Window)
        local playerFrame = Instance.new("Frame")
        playerFrame.Name = "PlayerFrame"
        playerFrame.Size = UDim2.new(0, 350, 0, 400)
        playerFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
        playerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        playerFrame.BorderSizePixel = 2
        playerFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
        frame.Active = true
        playerFrame.Draggable = true
        playerFrame.Visible = false
        playerFrame.Parent = screenGui
        
        -- Title Player Frame
        local playerTitle = Instance.new("TextLabel")
        playerTitle.Name = "PlayerTitle"
        playerTitle.Size = UDim2.new(1, 0, 0, 30)
        playerTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        playerTitle.BorderSizePixel = 0
        playerTitle.Text = "👥 PLAYER LIST - Teleport"
        playerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        playerTitle.TextSize = 14
        playerTitle.Font = Enum.Font.GothamBold
        playerTitle.Parent = playerFrame
        
        -- ScrollingFrame untuk player list
        local playerScrollFrame = Instance.new("ScrollingFrame")
        playerScrollFrame.Name = "PlayerScroll"
        playerScrollFrame.Size = UDim2.new(1, -10, 1, -80)
        playerScrollFrame.Position = UDim2.new(0, 5, 0, 35)
        playerScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        playerScrollFrame.BorderSizePixel = 1
        playerScrollFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
        playerScrollFrame.ScrollBarThickness = 8
        playerScrollFrame.Parent = playerFrame
        
        -- UIListLayout untuk player buttons
        local playerListLayout = Instance.new("UIListLayout")
        playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        playerListLayout.Padding = UDim.new(0, 5)
        playerListLayout.Parent = playerScrollFrame
        
        -- Function untuk refresh player list
        local function refreshPlayerList()
            -- Clear existing buttons
            for _, child in pairs(playerScrollFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            log("🔄 Refreshing player list...", "info")
            local playerCount = 0
            
            -- Create button untuk setiap player
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    playerCount = playerCount + 1
                    
                    local playerBtn = Instance.new("TextButton")
                    playerBtn.Name = player.Name
                    playerBtn.Size = UDim2.new(1, -10, 0, 40)
                    playerBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    playerBtn.BorderSizePixel = 1
                    playerBtn.BorderColor3 = Color3.fromRGB(100, 100, 100)
                    playerBtn.Text = "📍 " .. player.Name .. " (" .. player.DisplayName .. ")"
                    playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    playerBtn.TextSize = 12
                    playerBtn.Font = Enum.Font.Gotham
                    playerBtn.TextXAlignment = Enum.TextXAlignment.Left
                    playerBtn.TextTruncate = Enum.TextTruncate.AtEnd
                    playerBtn.Parent = playerScrollFrame
                    
                    -- Teleport functionality
                    playerBtn.MouseButton1Click:Connect(function()
                        local targetPlayer = player
                        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local success, err = pcall(function()
                                LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                            end)
                            
                            if success then
                                log("✅ Teleported to " .. targetPlayer.Name, "success")
                                createNotification("✅ Teleported", "Teleported to " .. targetPlayer.Name, 3)
                            else
                                log("❌ Teleport failed: " .. tostring(err), "error")
                                createNotification("❌ Failed", "Teleport failed!", 3)
                            end
                        else
                            log("⚠️ Player character not found: " .. targetPlayer.Name, "warning")
                            createNotification("⚠️ Warning", "Player character not found!", 3)
                        end
                    end)
                end
            end
            
            log("✅ Player list refreshed! Found " .. playerCount .. " players", "success")
            playerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, playerListLayout.AbsoluteContentSize.Y + 10)
        end
        
        -- Button: Refresh Player List
        local refreshBtn = Instance.new("TextButton")
        refreshBtn.Name = "RefreshButton"
        refreshBtn.Size = UDim2.new(0.48, -2, 0, 35)
        refreshBtn.Position = UDim2.new(0.01, 0, 1, -40)
        refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        refreshBtn.BorderSizePixel = 0
        refreshBtn.Text = "🔄 REFRESH"
        refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        refreshBtn.TextSize = 13
        refreshBtn.Font = Enum.Font.GothamBold
        refreshBtn.Parent = playerFrame
        
        refreshBtn.MouseButton1Click:Connect(function()
            refreshPlayerList()
        end)
        
        -- Button: Close Player List
        local closePlayerBtn = Instance.new("TextButton")
        closePlayerBtn.Name = "ClosePlayerButton"
        closePlayerBtn.Size = UDim2.new(0.48, -2, 0, 35)
        closePlayerBtn.Position = UDim2.new(0.51, 0, 1, -40)
        closePlayerBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        closePlayerBtn.BorderSizePixel = 0
        closePlayerBtn.Text = "✖️ CLOSE"
        closePlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closePlayerBtn.TextSize = 13
        closePlayerBtn.Font = Enum.Font.GothamBold
        closePlayerBtn.Parent = playerFrame
        
        closePlayerBtn.MouseButton1Click:Connect(function()
            playerFrame.Visible = false
        end)
        
        -- Initial refresh
        refreshPlayerList()
        
        -- Auto refresh setiap 5 detik
        spawn(function()
            while true do
                wait(5)
                if playerFrame.Visible then
                    refreshPlayerList()
                end
            end
        end)
        
        -- Title Log Frame
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -60, 0, 30)
        title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        title.BorderSizePixel = 0
        title.Text = "FARM CANDY - Takaa"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 14
        title.Font = Enum.Font.GothamBold
        title.Parent = frame
        
        -- Button Minimize (➖) di pojok kanan atas
        local minimizeBtn = Instance.new("TextButton")
        minimizeBtn.Name = "MinimizeButton"
        minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
        minimizeBtn.Position = UDim2.new(1, -60, 0, 0)
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        minimizeBtn.BorderSizePixel = 0
        minimizeBtn.Text = "➖"
        minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minimizeBtn.TextSize = 18
        minimizeBtn.Font = Enum.Font.GothamBold
        minimizeBtn.Parent = frame
        
        minimizeBtn.MouseButton1Click:Connect(function()
            frame.Visible = false
            log("📦 Menu minimized", "info")
        end)
        
        -- Button Exit (✖️) di pojok kanan atas
        local exitBtn = Instance.new("TextButton")
        exitBtn.Name = "ExitButton"
        exitBtn.Size = UDim2.new(0, 30, 0, 30)
        exitBtn.Position = UDim2.new(1, -30, 0, 0)
        exitBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        exitBtn.BorderSizePixel = 0
        exitBtn.Text = "✖️"
        exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        exitBtn.TextSize = 16
        exitBtn.Font = Enum.Font.GothamBold
        exitBtn.Parent = frame
        
        exitBtn.MouseButton1Click:Connect(function()
            log("🚪 Exiting Fish It Utility...", "warning")
            createNotification("👋 Goodbye", "Fish It Utility closed!", 3)
            wait(0.5)
            screenGui:Destroy()
            log("✅ GUI destroyed successfully", "success")
        end)
        
        -- ScrollingFrame untuk log
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "LogScroll"
        scrollFrame.Size = UDim2.new(1, -10, 1, -80)
        scrollFrame.Position = UDim2.new(0, 5, 0, 35)
        scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        scrollFrame.BorderSizePixel = 1
        scrollFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
        scrollFrame.ScrollBarThickness = 8
        scrollFrame.Parent = frame
        
        -- TextLabel untuk log text
        local logText = Instance.new("TextLabel")
        logText.Name = "LogText"
        logText.Size = UDim2.new(1, -10, 1, 0)
        logText.Position = UDim2.new(0, 5, 0, 0)
        logText.BackgroundTransparency = 1
        logText.Text = "Waiting for logs..."
        logText.TextColor3 = Color3.fromRGB(255, 255, 255)
        logText.TextSize = 12
        logText.Font = Enum.Font.Code
        logText.TextXAlignment = Enum.TextXAlignment.Left
        logText.TextYAlignment = Enum.TextYAlignment.Top
        logText.TextWrapped = true
        logText.Parent = scrollFrame
        
        -- Button: Stop/Start
        local stopBtn = Instance.new("TextButton")
        stopBtn.Name = "StopButton"
        stopBtn.Size = UDim2.new(0.24, -2, 0, 35)
        stopBtn.Position = UDim2.new(0.01, 0, 1, -40)
        stopBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
        stopBtn.BorderSizePixel = 0
        stopBtn.Text = "⏸️"
        stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stopBtn.TextSize = 16
        stopBtn.Font = Enum.Font.GothamBold
        stopBtn.Parent = frame
        
        stopBtn.MouseButton1Click:Connect(function()
            IS_RUNNING = not IS_RUNNING
            
            if IS_RUNNING then
                stopBtn.Text = "⏸️"
                stopBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
                log("▶️ AUTO HOP RESUMED!", "success")
                createNotification("▶️ Started", "Auto hop resumed!", 3)
            else
                stopBtn.Text = "▶️"
                stopBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                log("⏸️ AUTO HOP STOPPED!", "warning")
                createNotification("⏸️ Stopped", "Auto hop paused", 3)
            end
        end)
        
        -- Button: Auto Reel (Narik Ikan)
        local reelBtn = Instance.new("TextButton")
        reelBtn.Name = "ReelButton"
        reelBtn.Size = UDim2.new(0.24, -2, 0, 35)
        reelBtn.Position = UDim2.new(0.26, 0, 1, -40)
        reelBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        reelBtn.BorderSizePixel = 0
        reelBtn.Text = "🎣"
        reelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        reelBtn.TextSize = 16
        reelBtn.Font = Enum.Font.GothamBold
        reelBtn.Parent = frame
        
        reelBtn.MouseButton1Click:Connect(function()
            AUTO_REEL = not AUTO_REEL
            
            if AUTO_REEL then
                reelBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
                log("🎣 AUTO REEL ON! (Tap tap narik ikan)", "success")
                createNotification("🎣 Auto Reel", "Auto reel enabled! Tap tap narik ikan otomatis", 3)
            else
                reelBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
                log("🎣 AUTO REEL OFF!", "warning")
                createNotification("🎣 Auto Reel", "Auto reel disabled!", 3)
            end
        end)
        
        -- Button: Player List
        local playerListBtn = Instance.new("TextButton")
        playerListBtn.Name = "PlayerListButton"
        playerListBtn.Size = UDim2.new(0.24, -2, 0, 35)
        playerListBtn.Position = UDim2.new(0.51, 0, 1, -40)
        playerListBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        playerListBtn.BorderSizePixel = 0
        playerListBtn.Text = "👥"
        playerListBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        playerListBtn.TextSize = 16
        playerListBtn.Font = Enum.Font.GothamBold
        playerListBtn.Parent = frame
        
        playerListBtn.MouseButton1Click:Connect(function()
            playerFrame.Visible = not playerFrame.Visible
            if playerFrame.Visible then
                refreshPlayerList()
            end
        end)
        
        -- Button: Close (minimize)
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Size = UDim2.new(0.24, -2, 0, 35)
        closeBtn.Position = UDim2.new(0.76, 0, 1, -40)
        closeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "➖"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 20
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = frame
        
        closeBtn.MouseButton1Click:Connect(function()
            frame.Visible = false
            log("📦 Menu minimized", "info")
        end)
        
        -- Button Toggle yang bisa di-drag
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Name = "ToggleButton"
        toggleBtn.Size = UDim2.new(0, 80, 0, 30)
        toggleBtn.Position = UDim2.new(1, -90, 0, 10)
        toggleBtn.AnchorPoint = Vector2.new(0, 0)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        toggleBtn.BorderSizePixel = 2
        toggleBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.Text = "⚙️ MENU"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 12
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Active = true
        toggleBtn.Draggable = true
        toggleBtn.Parent = screenGui
        
        toggleBtn.MouseButton1Click:Connect(function()
            frame.Visible = not frame.Visible
            if frame.Visible then
                log("📂 Menu opened", "info")
            else
                log("📦 Menu closed", "info")
            end
        end)
        
        -- Update log text setiap detik
        spawn(function()
            while true do
                wait(1)
                local displayLog = table.concat(LOG_HISTORY, "\n")
                logText.Text = displayLog
                
                -- Auto scroll ke bawah
                scrollFrame.CanvasSize = UDim2.new(0, 0, 0, logText.TextBounds.Y + 10)
                scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
            end
        end)
        
        screenGui.Parent = game:GetService("CoreGui")
        log("✅ Log viewer GUI created successfully!", "success")
    end)
    
    if not success then
        log("❌ Failed to create log viewer: " .. tostring(err), "error")
    end
end

-- Fungsi rejoin untuk cari server dengan PLAYER PALING BANYAK
local function rejoinGame()
    log("========== REJOIN PROCESS STARTED ==========", "info")
    log("Current PlaceId: " .. tostring(game.PlaceId), "info")
    log("Current JobId: " .. tostring(game.JobId), "info")
    log("Player Name: " .. tostring(LocalPlayer.Name), "info")
    
    local success, err = pcall(function()
        log("Step 1: Fetching PUBLIC servers with MOST players...", "info")
        
        local bestServer = nil
        local maxPlayers = 0
        local cursor = ""
        local attempts = 0
        local maxAttempts = 5
        
        repeat
            attempts = attempts + 1
            log("Scanning page " .. attempts .. "/" .. maxAttempts .. "...", "info")
            
            local url = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100&cursor=%s",
                game.PlaceId,
                cursor
            )
            
            local httpSuccess, servers = pcall(function()
                return game:HttpGet(url)
            end)
            
            if not httpSuccess then
                log("❌ HTTP Request FAILED: " .. tostring(servers), "error")
                break
            end
            
            log("✅ HTTP Request SUCCESS!", "success")
            
            local decoded = HttpService:JSONDecode(servers)
            
            if decoded.data then
                log("Processing " .. #decoded.data .. " servers...", "info")
                
                for i, server in pairs(decoded.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        if server.playing > maxPlayers then
                            maxPlayers = server.playing
                            bestServer = server.id
                            log("✅ Found better server: " .. server.playing .. "/" .. server.maxPlayers .. " players", "success")
                        end
                    end
                end
            end
            
            cursor = decoded.nextPageCursor or ""
            
        until cursor == "" or attempts >= maxAttempts
        
        if bestServer then
            log("🎯 BEST SERVER FOUND: " .. maxPlayers .. " players online!", "success")
            log("Server ID: " .. bestServer, "info")
            log("Step 2: Teleporting to best server...", "info")
            
            createNotification("🚀 Server Hop", "Pindah ke server dengan " .. maxPlayers .. " players!", 4)
            wait(1)
            
            TeleportService:TeleportToPlaceInstance(game.PlaceId, bestServer, LocalPlayer)
            log("✅ Teleport command sent!", "success")
        else
            log("⚠️ No suitable servers found, using fallback rejoin", "warning")
            createNotification("🔄 Rejoin", "Reconnecting to any server...", 3)
            wait(1)
            
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    
    if not success then
        log("❌ CRITICAL ERROR: " .. tostring(err), "error")
        createNotification("❌ Error", "Rejoin failed!", 5)
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
    log("⚡ AUTO HOP: ON (Running)", "success")
    log("🎣 AUTO REEL: OFF (Default) - Tap tap narik ikan", "info")
    log("Rejoin Interval: " .. REJOIN_INTERVAL .. " seconds", "info")
    log("PlaceId: " .. tostring(game.PlaceId), "info")
    log("JobId: " .. tostring(game.JobId), "info")
    log("Player: " .. tostring(LocalPlayer.Name), "info")
    log("=================================================", "info")
    
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
                log("⏸️ Auto hop is PAUSED (Press ▶️ to START)", "warning")
                countdown = REJOIN_INTERVAL
                wait(2)
            end
        end
    end)
    
    log("✅ Main loop started!", "success")
end

-- Setup everything
log("Initializing Fish It Utility...", "info")

-- Create log viewer GUI
createLogViewer()

-- Start auto reel loop
startAutoReel()

-- Notifications
createNotification("⏳ Loading...", "Initializing...", 3)
wait(3)
createNotification("✅ SUCCESS!", "Utility loaded! Auto hop is ON", 5)
wait(2)
createNotification("📊 INFO", "Drag ⚙️ MENU button anywhere you want!", 8)

-- Start
startAutoRejoin()

log("🎮 Script running! Auto hop is ACTIVE", "success")
log("🎯 Will find servers with MOST players!", "info")
log("🎣 Auto Reel: Press 🎣 button to toggle (tap tap narik ikan)", "info")
log("✋ You can DRAG the ⚙️ MENU button!", "info")
