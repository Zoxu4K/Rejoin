-- Fish It Auto Rejoin Utility - MODERN UI VERSION
-- Compatible with Delta Executor
-- Auto rejoin ke server publik dengan player banyak

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Konfigurasi
local REJOIN_INTERVAL = 15
local AUTO_EXECUTE = true
local IS_RUNNING = true
local AUTO_REEL = false
local REEL_DELAY = 0.01

-- LOG STORAGE
local LOG_HISTORY = {}
local MAX_LOGS = 30

-- Colors
local COLORS = {
    bg = Color3.fromRGB(15, 15, 20),
    bgLight = Color3.fromRGB(25, 25, 35),
    accent = Color3.fromRGB(88, 101, 242),
    success = Color3.fromRGB(67, 181, 129),
    error = Color3.fromRGB(240, 71, 71),
    warning = Color3.fromRGB(250, 166, 26),
    text = Color3.fromRGB(255, 255, 255),
    textDim = Color3.fromRGB(150, 150, 160)
}

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

-- UI Notification
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

-- AUTO REEL FUNCTION
local function startAutoReel()
    spawn(function()
        while true do
            if AUTO_REEL then
                pcall(function()
                    local screenSize = workspace.CurrentCamera.ViewportSize
                    local clickX = 50
                    local clickY = 50
                    
                    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
                    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
                    
                    log("🎣 Tap!", "info")
                end)
            end
            
            task.wait(REEL_DELAY)
        end
    end)
end

-- Helper functions removed for simplicity

-- CREATE SIMPLE CLEAN UI
local function createLogViewer()
    log("Creating UI...", "info")
    
    local success, err = pcall(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FishItModernUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Main Frame
        local mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(0, 380, 0, 420)
        mainFrame.Position = UDim2.new(0.5, -190, 0.5, -210)
        mainFrame.BackgroundColor3 = COLORS.bg
        mainFrame.BorderSizePixel = 0
        mainFrame.Active = true
        mainFrame.Draggable = true
        mainFrame.Parent = screenGui
        
        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 10)
        mainCorner.Parent = mainFrame
        
        -- Header
        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 50)
        header.BackgroundColor3 = COLORS.bgLight
        header.BorderSizePixel = 0
        header.Parent = mainFrame
        
        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 10)
        headerCorner.Parent = header
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -100, 1, 0)
        title.Position = UDim2.new(0, 15, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "🎣 FARM CANDY - Takaa"
        title.TextColor3 = COLORS.text
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = header
        
        -- Close button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 35, 0, 35)
        closeBtn.Position = UDim2.new(1, -45, 0.5, -17.5)
        closeBtn.BackgroundColor3 = COLORS.error
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = COLORS.text
        closeBtn.TextSize = 16
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = header
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 8)
        closeCorner.Parent = closeBtn
        
        closeBtn.MouseButton1Click:Connect(function()
            log("🚪 Exiting...", "warning")
            screenGui:Destroy()
        end)
        
        -- Status indicator
        local statusText = Instance.new("TextLabel")
        statusText.Size = UDim2.new(1, -20, 0, 30)
        statusText.Position = UDim2.new(0, 10, 0, 60)
        statusText.BackgroundTransparency = 1
        statusText.Text = "● Running"
        statusText.TextColor3 = COLORS.success
        statusText.TextSize = 13
        statusText.Font = Enum.Font.GothamMedium
        statusText.TextXAlignment = Enum.TextXAlignment.Left
        statusText.Parent = mainFrame
        
        -- Log container
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, -20, 1, -170)
        scrollFrame.Position = UDim2.new(0, 10, 0, 95)
        scrollFrame.BackgroundColor3 = COLORS.bgLight
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 4
        scrollFrame.ScrollBarImageColor3 = COLORS.accent
        scrollFrame.Parent = mainFrame
        
        local scrollCorner = Instance.new("UICorner")
        scrollCorner.CornerRadius = UDim.new(0, 8)
        scrollCorner.Parent = scrollFrame
        
        local logText = Instance.new("TextLabel")
        logText.Size = UDim2.new(1, -10, 1, 0)
        logText.Position = UDim2.new(0, 5, 0, 0)
        logText.BackgroundTransparency = 1
        logText.Text = "Waiting for logs..."
        logText.TextColor3 = COLORS.textDim
        logText.TextSize = 11
        logText.Font = Enum.Font.Code
        logText.TextXAlignment = Enum.TextXAlignment.Left
        logText.TextYAlignment = Enum.TextYAlignment.Top
        logText.TextWrapped = true
        logText.Parent = scrollFrame
        
        -- Control buttons container
        local btnY = -60
        
        -- Stop/Start button
        local stopBtn = Instance.new("TextButton")
        stopBtn.Size = UDim2.new(0.48, 0, 0, 45)
        stopBtn.Position = UDim2.new(0, 10, 1, btnY)
        stopBtn.BackgroundColor3 = COLORS.warning
        stopBtn.BorderSizePixel = 0
        stopBtn.Text = "⏸ PAUSE"
        stopBtn.TextColor3 = COLORS.text
        stopBtn.TextSize = 13
        stopBtn.Font = Enum.Font.GothamBold
        stopBtn.Parent = mainFrame
        
        local stopCorner = Instance.new("UICorner")
        stopCorner.CornerRadius = UDim.new(0, 8)
        stopCorner.Parent = stopBtn
        
        stopBtn.MouseButton1Click:Connect(function()
            IS_RUNNING = not IS_RUNNING
            if IS_RUNNING then
                stopBtn.Text = "⏸ PAUSE"
                stopBtn.BackgroundColor3 = COLORS.warning
                statusText.Text = "● Running"
                statusText.TextColor3 = COLORS.success
                log("▶️ RESUMED!", "success")
            else
                stopBtn.Text = "▶ START"
                stopBtn.BackgroundColor3 = COLORS.success
                statusText.Text = "● Paused"
                statusText.TextColor3 = COLORS.warning
                log("⏸️ PAUSED!", "warning")
            end
        end)
        
        -- Auto Reel button
        local reelBtn = Instance.new("TextButton")
        reelBtn.Size = UDim2.new(0.48, 0, 0, 45)
        reelBtn.Position = UDim2.new(0.52, 0, 1, btnY)
        reelBtn.BackgroundColor3 = COLORS.error
        reelBtn.BorderSizePixel = 0
        reelBtn.Text = "🎣 REEL"
        reelBtn.TextColor3 = COLORS.text
        reelBtn.TextSize = 13
        reelBtn.Font = Enum.Font.GothamBold
        reelBtn.Parent = mainFrame
        
        local reelCorner = Instance.new("UICorner")
        reelCorner.CornerRadius = UDim.new(0, 8)
        reelCorner.Parent = reelBtn
        
        reelBtn.MouseButton1Click:Connect(function()
            AUTO_REEL = not AUTO_REEL
            if AUTO_REEL then
                reelBtn.BackgroundColor3 = COLORS.success
                log("🎣 REEL ON!", "success")
            else
                reelBtn.BackgroundColor3 = COLORS.error
                log("🎣 REEL OFF!", "warning")
            end
        end)
        
        -- Floating toggle button
        local floatingBtn = Instance.new("TextButton")
        floatingBtn.Size = UDim2.new(0, 50, 0, 50)
        floatingBtn.Position = UDim2.new(1, -70, 0, 20)
        floatingBtn.BackgroundColor3 = COLORS.accent
        floatingBtn.BorderSizePixel = 0
        floatingBtn.Text = "⚙"
        floatingBtn.TextColor3 = COLORS.text
        floatingBtn.TextSize = 22
        floatingBtn.Font = Enum.Font.GothamBold
        floatingBtn.Active = true
        floatingBtn.Draggable = true
        floatingBtn.Parent = screenGui
        
        local floatCorner = Instance.new("UICorner")
        floatCorner.CornerRadius = UDim.new(1, 0)
        floatCorner.Parent = floatingBtn
        
        floatingBtn.MouseButton1Click:Connect(function()
            mainFrame.Visible = not mainFrame.Visible
        end)
        
        -- Update logs
        spawn(function()
            while true do
                wait(1)
                local displayLog = table.concat(LOG_HISTORY, "\n")
                logText.Text = displayLog
                scrollFrame.CanvasSize = UDim2.new(0, 0, 0, logText.TextBounds.Y + 10)
                scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
            end
        end)
        
        screenGui.Parent = game:GetService("CoreGui")
        log("✅ UI created!", "success")
    end)
    
    if not success then
        log("❌ Failed to create UI: " .. tostring(err), "error")
    end
end

-- Rejoin function
local function rejoinGame()
    log("========== REJOIN STARTED ==========", "info")
    log("PlaceId: " .. tostring(game.PlaceId), "info")
    
    local success, err = pcall(function()
        local bestServer = nil
        local maxPlayers = 0
        
        local url = string.format(
            "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100",
            game.PlaceId
        )
        
        local servers = game:HttpGet(url)
        local decoded = HttpService:JSONDecode(servers)
        
        if decoded.data then
            for i, server in pairs(decoded.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    if server.playing > maxPlayers then
                        maxPlayers = server.playing
                        bestServer = server.id
                    end
                end
            end
        end
        
        if bestServer then
            log("🎯 Best server: " .. maxPlayers .. " players!", "success")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, bestServer, LocalPlayer)
        else
            log("🔄 Fallback rejoin", "warning")
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    
    if not success then
        log("❌ ERROR: " .. tostring(err), "error")
    end
end

-- Main loop
local function startAutoRejoin()
    log("✅ FISH IT UTILITY STARTED!", "success")
    
    spawn(function()
        local countdown = REJOIN_INTERVAL
        while true do
            if IS_RUNNING then
                if countdown > 0 then
                    log("⏳ Next rejoin: " .. countdown .. "s", "info")
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
log("Initializing Fish It Utility...", "info")
createLogViewer()
startAutoReel()
createNotification("✅ SUCCESS!", "Modern UI loaded!", 5)
wait(2)
startAutoRejoin()
log("🎮 Script running!", "success")
