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

-- Tween helper
local function tweenProperty(obj, props, duration, easingStyle)
    local tween = TweenService:Create(obj, TweenInfo.new(duration or 0.3, easingStyle or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

-- Create rounded frame
local function createRoundedFrame(parent, size, position, bgColor)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = bgColor
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    return frame
end

-- Create button
local function createButton(parent, size, position, text, bgColor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = position
    btn.BackgroundColor3 = bgColor
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = COLORS.text
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    -- Hover effect
    btn.MouseEnter:Connect(function()
        tweenProperty(btn, {BackgroundColor3 = Color3.new(
            math.min(bgColor.R + 0.1, 1),
            math.min(bgColor.G + 0.1, 1),
            math.min(bgColor.B + 0.1, 1)
        )}, 0.2)
    end)
    
    btn.MouseLeave:Connect(function()
        tweenProperty(btn, {BackgroundColor3 = bgColor}, 0.2)
    end)
    
    -- Click effect
    btn.MouseButton1Down:Connect(function()
        tweenProperty(btn, {Size = UDim2.new(size.X.Scale * 0.95, 0, size.Y.Scale * 0.95, 0)}, 0.1)
    end)
    
    btn.MouseButton1Up:Connect(function()
        tweenProperty(btn, {Size = size}, 0.1)
    end)
    
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    
    return btn
end

-- CREATE MODERN UI
local function createLogViewer()
    log("Creating modern UI...", "info")
    
    local success, err = pcall(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FishItModernUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Main Frame (Log Window)
        local mainFrame = createRoundedFrame(screenGui, 
            UDim2.new(0, 420, 0, 480), 
            UDim2.new(0.5, -210, 0.5, -240), 
            COLORS.bg
        )
        mainFrame.Active = true
        mainFrame.Draggable = true
        
        -- Gradient overlay
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
        }
        gradient.Rotation = 135
        gradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.95),
            NumberSequenceKeypoint.new(1, 0)
        }
        gradient.Parent = mainFrame
        
        -- Shadow effect
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "Shadow"
        shadow.Size = UDim2.new(1, 40, 1, 40)
        shadow.Position = UDim2.new(0, -20, 0, -20)
        shadow.BackgroundTransparency = 1
        shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.7
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(10, 10, 118, 118)
        shadow.ZIndex = 0
        shadow.Parent = mainFrame
        
        -- Header
        local header = createRoundedFrame(mainFrame, 
            UDim2.new(1, 0, 0, 60), 
            UDim2.new(0, 0, 0, 0), 
            COLORS.bgLight
        )
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -120, 1, 0)
        title.Position = UDim2.new(0, 20, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = "🎣 FARM CANDY"
        title.TextColor3 = COLORS.text
        title.TextSize = 18
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = header
        
        local subtitle = Instance.new("TextLabel")
        subtitle.Size = UDim2.new(1, -120, 0, 20)
        subtitle.Position = UDim2.new(0, 20, 0, 30)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = "by Takaa"
        subtitle.TextColor3 = COLORS.textDim
        subtitle.TextSize = 12
        subtitle.Font = Enum.Font.Gotham
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.Parent = header
        
        -- Minimize button
        local minimizeBtn = createButton(header, 
            UDim2.new(0, 35, 0, 35), 
            UDim2.new(1, -80, 0.5, -17.5), 
            "—", 
            Color3.fromRGB(250, 166, 26),
            function()
                tweenProperty(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)
                wait(0.3)
                mainFrame.Visible = false
                log("📦 Menu minimized", "info")
            end
        )
        
        -- Close button
        local closeBtn = createButton(header, 
            UDim2.new(0, 35, 0, 35), 
            UDim2.new(1, -40, 0.5, -17.5), 
            "✕", 
            COLORS.error,
            function()
                log("🚪 Exiting...", "warning")
                createNotification("👋 Goodbye", "Fish It Utility closed!", 3)
                tweenProperty(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)
                wait(0.4)
                screenGui:Destroy()
            end
        )
        
        -- Status bar
        local statusBar = createRoundedFrame(mainFrame, 
            UDim2.new(1, -20, 0, 40), 
            UDim2.new(0, 10, 0, 70), 
            COLORS.bgLight
        )
        
        local statusText = Instance.new("TextLabel")
        statusText.Size = UDim2.new(1, -20, 1, 0)
        statusText.Position = UDim2.new(0, 10, 0, 0)
        statusText.BackgroundTransparency = 1
        statusText.Text = "● Status: Running"
        statusText.TextColor3 = COLORS.success
        statusText.TextSize = 13
        statusText.Font = Enum.Font.GothamMedium
        statusText.TextXAlignment = Enum.TextXAlignment.Left
        statusText.Parent = statusBar
        
        -- Log container
        local logContainer = createRoundedFrame(mainFrame, 
            UDim2.new(1, -20, 1, -200), 
            UDim2.new(0, 10, 0, 120), 
            COLORS.bgLight
        )
        
        local logLabel = Instance.new("TextLabel")
        logLabel.Size = UDim2.new(1, -20, 0, 25)
        logLabel.Position = UDim2.new(0, 10, 0, 8)
        logLabel.BackgroundTransparency = 1
        logLabel.Text = "📋 Activity Logs"
        logLabel.TextColor3 = COLORS.textDim
        logLabel.TextSize = 12
        logLabel.Font = Enum.Font.GothamBold
        logLabel.TextXAlignment = Enum.TextXAlignment.Left
        logLabel.Parent = logContainer
        
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, -20, 1, -40)
        scrollFrame.Position = UDim2.new(0, 10, 0, 35)
        scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 4
        scrollFrame.ScrollBarImageColor3 = COLORS.accent
        scrollFrame.Parent = logContainer
        
        local scrollCorner = Instance.new("UICorner")
        scrollCorner.CornerRadius = UDim.new(0, 6)
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
        
        -- Control buttons
        local btnContainer = createRoundedFrame(mainFrame, 
            UDim2.new(1, -20, 0, 70), 
            UDim2.new(0, 10, 1, -80), 
            COLORS.bgLight
        )
        
        -- Stop/Start button
        local stopBtn = createButton(btnContainer, 
            UDim2.new(0.32, -5, 0, 50), 
            UDim2.new(0, 10, 0.5, -25), 
            "⏸ PAUSE", 
            COLORS.warning,
            function()
                IS_RUNNING = not IS_RUNNING
                if IS_RUNNING then
                    stopBtn.Text = "⏸ PAUSE"
                    stopBtn.BackgroundColor3 = COLORS.warning
                    statusText.Text = "● Status: Running"
                    statusText.TextColor3 = COLORS.success
                    log("▶️ AUTO HOP RESUMED!", "success")
                else
                    stopBtn.Text = "▶ START"
                    stopBtn.BackgroundColor3 = COLORS.success
                    statusText.Text = "● Status: Paused"
                    statusText.TextColor3 = COLORS.warning
                    log("⏸️ AUTO HOP STOPPED!", "warning")
                end
            end
        )
        
        -- Auto Reel button
        local reelBtn = createButton(btnContainer, 
            UDim2.new(0.32, -5, 0, 50), 
            UDim2.new(0.34, 0, 0.5, -25), 
            "🎣 REEL", 
            COLORS.error,
            function()
                AUTO_REEL = not AUTO_REEL
                if AUTO_REEL then
                    reelBtn.BackgroundColor3 = COLORS.success
                    log("🎣 AUTO REEL ON!", "success")
                else
                    reelBtn.BackgroundColor3 = COLORS.error
                    log("🎣 AUTO REEL OFF!", "warning")
                end
            end
        )
        
        -- Player List button
        local playerBtn = createButton(btnContainer, 
            UDim2.new(0.32, -5, 0, 50), 
            UDim2.new(0.68, 0, 0.5, -25), 
            "👥 PLAYERS", 
            COLORS.accent,
            function()
                log("👥 Player list opened", "info")
                -- Placeholder for player list
            end
        )
        
        -- Floating toggle button
        local floatingBtn = Instance.new("TextButton")
        floatingBtn.Size = UDim2.new(0, 50, 0, 50)
        floatingBtn.Position = UDim2.new(1, -70, 0, 20)
        floatingBtn.AnchorPoint = Vector2.new(0, 0)
        floatingBtn.BackgroundColor3 = COLORS.accent
        floatingBtn.BorderSizePixel = 0
        floatingBtn.Text = "⚙"
        floatingBtn.TextColor3 = COLORS.text
        floatingBtn.TextSize = 24
        floatingBtn.Font = Enum.Font.GothamBold
        floatingBtn.Active = true
        floatingBtn.Draggable = true
        floatingBtn.Parent = screenGui
        
        local floatCorner = Instance.new("UICorner")
        floatCorner.CornerRadius = UDim.new(1, 0)
        floatCorner.Parent = floatingBtn
        
        floatingBtn.MouseButton1Click:Connect(function()
            mainFrame.Visible = not mainFrame.Visible
            if mainFrame.Visible then
                mainFrame.Size = UDim2.new(0, 0, 0, 0)
                mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                tweenProperty(mainFrame, {
                    Size = UDim2.new(0, 420, 0, 480),
                    Position = UDim2.new(0.5, -210, 0.5, -240)
                }, 0.4, Enum.EasingStyle.Back)
            end
        end)
        
        -- Pulse animation for floating button
        spawn(function()
            while true do
                tweenProperty(floatingBtn, {Size = UDim2.new(0, 55, 0, 55)}, 1, Enum.EasingStyle.Sine)
                wait(1)
                tweenProperty(floatingBtn, {Size = UDim2.new(0, 50, 0, 50)}, 1, Enum.EasingStyle.Sine)
                wait(1)
            end
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
        log("✅ Modern UI created!", "success")
        
        -- Entrance animation
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        wait(0.1)
        tweenProperty(mainFrame, {
            Size = UDim2.new(0, 420, 0, 480),
            Position = UDim2.new(0.5, -210, 0.5, -240)
        }, 0.5, Enum.EasingStyle.Back)
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
