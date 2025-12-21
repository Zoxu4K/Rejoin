
-- Advanced Teleport Script - Christmas Cave Edition
-- Compatible with Delta Executor, Android & PC

local TeleportScript = {}

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Variables
local GUI = nil
local mainFrame = nil
local isMinimized = false
local autoTeleportEnabled = false
local isAutoRunning = false
local scheduledTimes = {
    "11:00", "13:00", "15:00", "17:00", "19:00", 
    "21:00", "23:00", "01:00", "03:00", "05:00", 
    "07:00", "09:00"
}
local currentWaitTime = 30 * 60 -- 30 menit dalam detik
local savedCoordinates = {
    home = nil,
    destination = nil
}

-- Config
local CONFIG_FILE = "ChristmasCaveConfig.json"

-- Function: Load Config
local function loadConfig()
    local success, result = pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            scheduledTimes = data.scheduledTimes or scheduledTimes
            currentWaitTime = data.waitTime or (30 * 60)
            savedCoordinates = data.coordinates or {home = nil, destination = nil}
            return true
        end
        return false
    end)
    return success and result
end

-- Function: Save Config
local function saveConfig()
    local success = pcall(function()
        if writefile then
            local data = {
                scheduledTimes = scheduledTimes,
                waitTime = currentWaitTime,
                coordinates = savedCoordinates
            }
            writefile(CONFIG_FILE, HttpService:JSONEncode(data))
        end
    end)
    return success
end

-- Function: Get Current Position
local function getCurrentPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        return {x = math.floor(pos.X), y = math.floor(pos.Y), z = math.floor(pos.Z)}
    end
    return nil
end

-- Function: Teleport to Position
local function teleportToPosition(x, y, z)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
        return true
    end
    return false
end

-- Function: Teleport to Player
local function teleportToPlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = targetPlayer.Character.HumanoidRootPart.Position
        teleportToPosition(pos.X, pos.Y, pos.Z)
        return true
    end
    return false
end

-- Function: Get All Players
local function getAllPlayers()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    return playerList
end

-- Function: Create Notification
local function notify(message, duration)
    duration = duration or 3
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "🎄 Christmas Cave",
        Text = message,
        Duration = duration
    })
end

-- Function: Copy to Clipboard
local function copyToClipboard(text)
    if setclipboard then
        setclipboard(text)
        return true
    end
    return false
end

-- Function: Format Time
local function formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

-- Function: Create GUI
local function createGUI()
    -- Destroy existing GUI
    if GUI then
        GUI:Destroy()
    end

    -- Create ScreenGui
    GUI = Instance.new("ScreenGui")
    GUI.Name = "ChristmasCaveGUI"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Protection
    if gethui then
        GUI.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(GUI)
        GUI.Parent = game.CoreGui
    else
        GUI.Parent = game.CoreGui
    end

    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 460, 0, 580)
    mainFrame.Position = UDim2.new(0.5, -230, 0.5, -290)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = GUI

    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(180, 50, 70)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = Color3.fromRGB(180, 50, 70)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎄 Christmas Cave Auto"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 17
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeButton"
    minimizeBtn.Size = UDim2.new(0, 35, 0, 32)
    minimizeBtn.Position = UDim2.new(1, -74, 0, 4)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
    minimizeBtn.Text = "−"
    minimizeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    minimizeBtn.TextSize = 22
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = titleBar

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = minimizeBtn

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 35, 0, 32)
    closeBtn.Position = UDim2.new(1, -36, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 24
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    -- Content Frame
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -24, 1, -52)
    contentFrame.Position = UDim2.new(0, 12, 0, 46)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 6
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 50, 70)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 1050)
    contentFrame.Parent = mainFrame

    -- Section Builder
    local yPos = 0
    
    local function createSection(sectionTitle, icon)
        local section = Instance.new("Frame")
        section.Size = UDim2.new(1, 0, 0, 28)
        section.Position = UDim2.new(0, 0, 0, yPos)
        section.BackgroundColor3 = Color3.fromRGB(180, 50, 70)
        section.BorderSizePixel = 0
        section.Parent = contentFrame

        local sectionCorner = Instance.new("UICorner")
        sectionCorner.CornerRadius = UDim.new(0, 7)
        sectionCorner.Parent = section

        local sectionLabel = Instance.new("TextLabel")
        sectionLabel.Size = UDim2.new(1, -12, 1, 0)
        sectionLabel.Position = UDim2.new(0, 12, 0, 0)
        sectionLabel.BackgroundTransparency = 1
        sectionLabel.Text = icon .. " " .. sectionTitle
        sectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        sectionLabel.TextSize = 14
        sectionLabel.Font = Enum.Font.GothamBold
        sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
        sectionLabel.Parent = section

        yPos = yPos + 38
        return section
    end

    local function createButton(text, callback, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.48, 0, 0, 38)
        btn.BackgroundColor3 = color or Color3.fromRGB(70, 130, 220)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamSemibold
        btn.Parent = contentFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 7)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Status Display
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 50)
    statusLabel.Position = UDim2.new(0, 0, 0, yPos)
    statusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    statusLabel.Text = "⏸️ Status: Tidak Aktif\n⏰ Waktu: --:--"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 13
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.Parent = contentFrame

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 7)
    statusCorner.Parent = statusLabel

    yPos = yPos + 60

    -- Copy & Paste Section
    createSection("Copy & Paste Koordinat", "📍")

    local copyHomeBtn = createButton("🏠 Copy Home", function()
        local pos = getCurrentPosition()
        if pos then
            savedCoordinates.home = pos
            local coordText = string.format("%d, %d, %d", pos.x, pos.y, pos.z)
            if copyToClipboard(coordText) then
                notify("✅ Home position saved: " .. coordText)
            else
                notify("✅ Home position saved!")
            end
            saveConfig()
        else
            notify("❌ Gagal mendapatkan posisi")
        end
    end, Color3.fromRGB(70, 180, 130))
    copyHomeBtn.Position = UDim2.new(0, 0, 0, yPos)

    local copyDestBtn = createButton("🎯 Copy Destination", function()
        local pos = getCurrentPosition()
        if pos then
            savedCoordinates.destination = pos
            local coordText = string.format("%d, %d, %d", pos.x, pos.y, pos.z)
            if copyToClipboard(coordText) then
                notify("✅ Destination saved: " .. coordText)
            else
                notify("✅ Destination saved!")
            end
            saveConfig()
        else
            notify("❌ Gagal mendapatkan posisi")
        end
    end, Color3.fromRGB(220, 100, 70))
    copyDestBtn.Position = UDim2.new(0.52, 0, 0, yPos)

    yPos = yPos + 48

    local tpHomeBtn = createButton("🏠 TP Home", function()
        if savedCoordinates.home then
            local pos = savedCoordinates.home
            if teleportToPosition(pos.x, pos.y, pos.z) then
                notify("✅ Teleported to Home!")
            else
                notify("❌ Gagal teleport")
            end
        else
            notify("❌ Set Home position dulu")
        end
    end, Color3.fromRGB(100, 150, 250))
    tpHomeBtn.Position = UDim2.new(0, 0, 0, yPos)
    local tpDestBtn = createButton("🎯 TP Destination", function()
        if savedCoordinates.destination then
            local pos = savedCoordinates.destination
            if teleportToPosition(pos.x, pos.y, pos.z) then
                notify("✅ Teleported to Destination!")
            else
                notify("❌ Gagal teleport")
            end
        else
            notify("❌ Set Destination dulu")
        end
    end, Color3.fromRGB(200, 80, 150))
    tpDestBtn.Position = UDim2.new(0.52, 0, 0, yPos)

    yPos = yPos + 48

    -- Auto Teleport Section
    createSection("Auto Teleport - Christmas Cave", "🎄")

    local scheduleInfo = Instance.new("TextLabel")
    scheduleInfo.Size = UDim2.new(1, 0, 0, 180)
    scheduleInfo.Position = UDim2.new(0, 0, 0, yPos)
    scheduleInfo.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    scheduleInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    scheduleInfo.TextSize = 12
    scheduleInfo.Font = Enum.Font.Gotham
    scheduleInfo.TextXAlignment = Enum.TextXAlignment.Left
    scheduleInfo.TextYAlignment = Enum.TextYAlignment.Top
    scheduleInfo.Parent = contentFrame

    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 7)
    infoCorner.Parent = scheduleInfo

    local infoPadding = Instance.new("UIPadding")
    infoPadding.PaddingLeft = UDim.new(0, 10)
    infoPadding.PaddingTop = UDim.new(0, 10)
    infoPadding.Parent = scheduleInfo

    local scheduleText = "⏰ Jadwal Mancing:\n\n"
    scheduleText = scheduleText .. "11:00  13:00  15:00  17:00\n"
    scheduleText = scheduleText .. "19:00  21:00  23:00  01:00\n"
    scheduleText = scheduleText .. "03:00  05:00  07:00  09:00\n\n"
    scheduleText = scheduleText .. "⏱️ Durasi: 30 menit per lokasi\n"
    scheduleText = scheduleText .. "🔄 Cycle: Home → Destination → Home\n\n"
    scheduleText = scheduleText .. "Pastikan sudah set Home & Destination!"
    
    scheduleInfo.Text = scheduleText

    yPos = yPos + 190

    -- Wait Time Section
    createSection("Set Waktu Tunggu", "⏱️")

    local waitTimeLabel = Instance.new("TextLabel")
    waitTimeLabel.Size = UDim2.new(1, 0, 0, 28)
    waitTimeLabel.Position = UDim2.new(0, 0, 0, yPos)
    waitTimeLabel.BackgroundTransparency = 1
    waitTimeLabel.Text = "⏱️ Waktu Tunggu: " .. formatTime(currentWaitTime)
    waitTimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitTimeLabel.TextSize = 14
    waitTimeLabel.Font = Enum.Font.GothamSemibold
    waitTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    waitTimeLabel.Parent = contentFrame

    yPos = yPos + 32

    local waitInput = Instance.new("TextBox")
    waitInput.Size = UDim2.new(0.65, 0, 0, 38)
    waitInput.Position = UDim2.new(0, 0, 0, yPos)
    waitInput.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    waitInput.PlaceholderText = "Menit (default: 30)"
    waitInput.Text = tostring(math.floor(currentWaitTime / 60))
    waitInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    waitInput.TextSize = 14
    waitInput.Font = Enum.Font.Gotham
    waitInput.Parent = contentFrame

    local waitCorner = Instance.new("UICorner")
    waitCorner.CornerRadius = UDim.new(0, 7)
    waitCorner.Parent = waitInput

    local setWaitBtn = createButton("✅ Set", function()
        local minutes = tonumber(waitInput.Text)
        if minutes and minutes > 0 then
            currentWaitTime = minutes * 60
            waitTimeLabel.Text = "⏱️ Waktu Tunggu: " .. formatTime(currentWaitTime)
            notify("✅ Waktu tunggu: " .. minutes .. " menit")
            saveConfig()
        else
            notify("❌ Masukkan angka yang valid")
        end
    end, Color3.fromRGB(70, 180, 130))
    setWaitBtn.Size = UDim2.new(0.33, 0, 0, 38)
    setWaitBtn.Position = UDim2.new(0.67, 0, 0, yPos)

    yPos = yPos + 48

    -- Start/Stop Button
    local startAutoBtn = Instance.new("TextButton")
    startAutoBtn.Size = UDim2.new(1, 0, 0, 45)
    startAutoBtn.Position = UDim2.new(0, 0, 0, yPos)
    startAutoBtn.BackgroundColor3 = Color3.fromRGB(70, 180, 130)
    startAutoBtn.Text = "▶️ START AUTO TELEPORT"
    startAutoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startAutoBtn.TextSize = 15
    startAutoBtn.Font = Enum.Font.GothamBold
    startAutoBtn.Parent = contentFrame

    local startCorner = Instance.new("UICorner")
    startCorner.CornerRadius = UDim.new(0, 8)
    startCorner.Parent = startAutoBtn

    yPos = yPos + 55

    -- Player Teleport Section
    createSection("Teleport ke Player", "👥")

    local playerListFrame = Instance.new("ScrollingFrame")
    playerListFrame.Size = UDim2.new(1, 0, 0, 160)
    playerListFrame.Position = UDim2.new(0, 0, 0, yPos)
    playerListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    playerListFrame.BorderSizePixel = 0
    playerListFrame.ScrollBarThickness = 5
    playerListFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 50, 70)
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerListFrame.Parent = contentFrame

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 7)
    listCorner.Parent = playerListFrame

    local function updatePlayerList()
        for _, child in ipairs(playerListFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local players = getAllPlayers()
        local btnY = 5

        if #players == 0 then
            local noPlayer = Instance.new("TextLabel")
            noPlayer.Size = UDim2.new(1, -10, 0, 30)
            noPlayer.Position = UDim2.new(0, 5, 0, 5)
            noPlayer.BackgroundTransparency = 1
            noPlayer.Text = "Tidak ada player lain"
            noPlayer.TextColor3 = Color3.fromRGB(150, 150, 150)
            noPlayer.TextSize = 12
            noPlayer.Font = Enum.Font.Gotham
            noPlayer.Parent = playerListFrame
        else
            for _, playerName in ipairs(players) do
                local playerBtn = Instance.new("TextButton")
                playerBtn.Size = UDim2.new(1, -10, 0, 32)
                playerBtn.Position = UDim2.new(0, 5, 0, btnY)
                playerBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
                playerBtn.Text = "👤 " .. playerName
                playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                playerBtn.TextSize = 12
                playerBtn.Font = Enum.Font.Gotham
                playerBtn.Parent = playerListFrame

                local pCorner = Instance.new("UICorner")
                pCorner.CornerRadius = UDim.new(0, 6)
                pCorner.Parent = playerBtn

                playerBtn.MouseButton1Click:Connect(function()
                    if teleportToPlayer(playerName) then
                        notify("✅ Teleported ke " .. playerName)
                    else
                        notify("❌ Gagal teleport ke " .. playerName)
                    end
                end)

                btnY = btnY + 37
            end
        end

        playerListFrame.CanvasSize = UDim2.new(0, 0, 0, btnY + 5)
    end

    yPos = yPos + 170

    local refreshBtn = createButton("🔄 Refresh List", function()
        updatePlayerList()
        notify("✅ Player list di-refresh")
    end, Color3.fromRGB(150, 100, 220))
    refreshBtn.Size = UDim2.new(1, 0, 0, 38)
    refreshBtn.Position = UDim2.new(0, 0, 0, yPos)

    updatePlayerList()

    -- Menu Button (Hidden initially)
    local menuBtn = Instance.new("TextButton")
    menuBtn.Name = "MenuButton"
    menuBtn.Size = UDim2.new(0, 110, 0, 45)
    menuBtn.Position = UDim2.new(0.5, -55, 0, 15)
    menuBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 70)
    menuBtn.Text = "⚙️ MENU"
    menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    menuBtn.TextSize = 16
    menuBtn.Font = Enum.Font.GothamBold
    menuBtn.Visible = false
    menuBtn.Parent = GUI

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 10)
    menuCorner.Parent = menuBtn

    -- Button Functions
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = true
        mainFrame.Visible = false
        menuBtn.Visible = true
        notify("📦 Menu diminimize")
    end)

    menuBtn.MouseButton1Click:Connect(function()
        isMinimized = false
        mainFrame.Visible = true
        menuBtn.Visible = false
    end)

    closeBtn.MouseButton1Click:Connect(function()
        autoTeleportEnabled = false
        isAutoRunning = false
        notify("👋 Script ditutup")
        wait(0.5)
        GUI:Destroy()
    end)

    -- Start/Stop Auto
    startAutoBtn.MouseButton1Click:Connect(function()
        if not savedCoordinates.home or not savedCoordinates.destination then
            notify("❌ Set Home & Destination terlebih dahulu!")
            return
        end

        autoTeleportEnabled = not autoTeleportEnabled
        
        if autoTeleportEnabled then
            startAutoBtn.Text = "⏸️ STOP AUTO TELEPORT"
            startAutoBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
            statusLabel.Text = "▶️ Status: AKTIF\n⏰ Menunggu jadwal..."
            notify("✅ Auto Teleport AKTIF!")
        else
            startAutoBtn.Text = "▶️ START AUTO TELEPORT"
            startAutoBtn.BackgroundColor3 = Color3.fromRGB(70, 180, 130)
            statusLabel.Text = "⏸️ Status: Tidak Aktif\n⏰ Waktu: --:--"
            notify("⏸️ Auto Teleport BERHENTI")
        end
    end)

    -- Make draggable
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    return statusLabel
end

-- Auto Teleport Logic
local statusLabel = createGUI()

spawn(function()
    local lastCheckedTime = ""
    
    while wait(1) do
        if autoTeleportEnabled and not isAutoRunning then
            local currentTime = os.date("%H:%M")
            
            -- Check if current time matches any scheduled time
            for _, scheduledTime in ipairs(scheduledTimes) do
                if currentTime == scheduledTime and currentTime ~= lastCheckedTime then
                    lastCheckedTime = currentTime
                    isAutoRunning = true
                    
                    -- Save original position (should be home)
                    local homePos = savedCoordinates.home
                    local destPos = savedCoordinates.destination
                    
                    if homePos and destPos then
                        -- Teleport to destination (Christmas Cave)
                        statusLabel.Text = "▶️ Status: TP ke Destination\n⏰ Waktu: " .. currentTime
                        notify("🎄 Teleporting ke Christmas Cave!")
                        
                        if teleportToPosition(destPos.x, destPos.y, destPos.z) then
                            notify("✅ Arrived at destination!")
                            
                            -- Wait for specified duration
                            local waitEnd = tick() + currentWaitTime
                            while tick() < waitEnd and autoTeleportEnabled do
                                local remaining = math.floor(waitEnd - tick())
                                statusLabel.Text = "⏸️ Status: Menunggu\n⏰ Sisa: " .. formatTime(remaining)
                                wait(1)
                            end
                            
                            -- Return to home
                            if autoTeleportEnabled then
                                statusLabel.Text = "▶️ Status: TP ke Home\n⏰ Waktu: " .. os.date("%H:%M")
                                notify("🏠 Kembali ke Home!")
                                
                                teleportToPosition(homePos.x, homePos.y, homePos.z)
                                notify("✅ Kembali ke posisi awal!")
                            end
                        else
                            notify("❌ Gagal teleport ke destination")
                        end
                    else
                        notify("❌ Koordinat tidak lengkap!")
                    end
                    
                    -- Reset status
                    isAutoRunning = false
                    if autoTeleportEnabled then
                        statusLabel.Text = "▶️ Status: AKTIF\n⏰ Menunggu jadwal..."
                    end
                    
                    -- Wait 61 seconds to prevent multiple triggers
                    wait(61)
                end
            end
        end
        
        -- Update status if not running
        if autoTeleportEnabled and not isAutoRunning then
            statusLabel.Text = "▶️ Status: AKTIF\n⏰ Waktu: " .. os.date("%H:%M")
        end
    end
end)

-- Initialize
loadConfig()
notify("🎄 Christmas Cave Script Loaded!")
notify("📍 Set Home & Destination dulu!")

return TeleportScript
