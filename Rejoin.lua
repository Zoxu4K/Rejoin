-- Fish It Auto Rejoin Utility - MOBILE VERSION WITH IN-GAME LOG VIEWER
-- Compatible with Delta Executor
-- Auto rejoin setiap 3 detik

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Konfigurasi
local REJOIN_INTERVAL = 10 -- 3 detik
local AUTO_EXECUTE = true

-- LOG STORAGE
local LOG_HISTORY = {}
local MAX_LOGS = 100

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

-- Fungsi untuk save log ke clipboard (setclipboard)
local function saveLogToClipboard()
    local fullLog = table.concat(LOG_HISTORY, "\n")
    
    local success, err = pcall(function()
        setclipboard(fullLog)
    end)
    
    if success then
        log("✅ LOG COPIED TO CLIPBOARD!", "success")
        createNotification("✅ Success", "Log copied to clipboard! Paste di notes", 5)
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
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0, 30)
        title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        title.BorderSizePixel = 0
        title.Text = "Fish It Utility - LOG VIEWER"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 14
        title.Font = Enum.Font.GothamBold
        title.Parent = frame
        
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
        
        -- Button: Copy to Clipboard
        local copyBtn = Instance.new("TextButton")
        copyBtn.Name = "CopyButton"
        copyBtn.Size = UDim2.new(0.48, 0, 0, 35)
        copyBtn.Position = UDim2.new(0.01, 0, 1, -40)
        copyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        copyBtn.BorderSizePixel = 0
        copyBtn.Text = "📋 COPY LOG"
        copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyBtn.TextSize = 14
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.Parent = frame
        
        copyBtn.MouseButton1Click:Connect(function()
            saveLogToClipboard()
        end)
        
        -- Button: Close
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Size = UDim2.new(0.48, 0, 0, 35)
        closeBtn.Position = UDim2.new(0.51, 0, 1, -40)
        closeBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "❌ CLOSE"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.TextSize = 14
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = frame
        
        closeBtn.MouseButton1Click:Connect(function()
            frame.Visible = false
        end)
        
        -- Button: Toggle (Minimize/Maximize) di kanan atas
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Name = "ToggleButton"
        toggleBtn.Size = UDim2.new(0, 60, 0, 25)
        toggleBtn.Position = UDim2.new(1, -150, 0, 0)
        toggleBtn.AnchorPoint = Vector2.new(0, 0)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Text = "📊 LOG"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 12
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Parent = screenGui
        
        toggleBtn.MouseButton1Click:Connect(function()
            frame.Visible = not frame.Visible
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

-- Fungsi untuk rejoin dengan server hop method
local function rejoinGame()
    log("========== REJOIN PROCESS STARTED ==========", "info")
    log("Current PlaceId: " .. tostring(game.PlaceId), "info")
    log("Current JobId: " .. tostring(game.JobId), "info")
    log("Player Name: " .. tostring(LocalPlayer.Name), "info")
    
    local success, err = pcall(function()
        log("Step 1: Preparing to fetch server list...", "info")
        
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
        
        log("Step 3: Total valid servers found: " .. #serverList, "info")
        
        if #serverList > 0 then
            local randomServer = serverList[math.random(1, #serverList)]
            log("Step 4: Selected server: " .. randomServer, "success")
            log("Step 5: Calling TeleportToPlaceInstance...", "info")
            
            createNotification("🚀 Hopping", "Pindah server...", 3)
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
            log("⚠️ No servers found, using fallback", "warning")
            createNotification("🔄 Rejoining", "Reconnecting...", 3)
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
            if countdown > 0 then
                log("⏳ Next rejoin in " .. countdown .. " seconds", "info")
                wait(1)
                countdown = countdown - 1
            else
                log("🚀 COUNTDOWN COMPLETE! Starting rejoin...", "success")
                rejoinGame()
                countdown = REJOIN_INTERVAL
            end
        end
    end)
    
    log("✅ Main loop started!", "success")
end

-- Setup everything
log("Initializing Fish It Utility...", "info")

-- Create log viewer GUI
createLogViewer()

-- Notifications
createNotification("⏳ Loading...", "Initializing...", 3)
wait(3)
createNotification("✅ SUCCESS!", "Utility loaded! Check LOG button", 5)
wait(2)
createNotification("📊 LOG VIEWER", "Klik button 'LOG' di pojok kanan atas!", 8)

-- Start
startAutoRejoin()

log("🎮 Script fully running! Click LOG button to view", "success")
log("📋 Use COPY LOG button to copy all logs", "info")
