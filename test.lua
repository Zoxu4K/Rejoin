
-- Christmas Cave Auto Teleport Script
-- Enhanced version with better config loading and English UI

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Variables
local GUI = nil
local mainFrame = nil
local autoEnabled = false
local isRunning = false
local jadwal = {"11:00","13:00","15:00","17:00","19:00","21:00","23:00","01:00","03:00","05:00","07:00","09:00"}
local waitTime = 30 * 60
local copiedCoord = nil
local homeCoord = nil
local tujuanCoord = nil
local currentTab = "teleport"
local autoStartTime = 0
local eventDuration = 30 * 60
local configLoaded = false

-- Config
local CONFIG = "XmasConfig.json"

-- Load Config with retry and validation
local function loadConfig()
    local maxRetries = 3
    local retryDelay = 0.5
    
    for attempt = 1, maxRetries do
        local success, result = pcall(function()
            if readfile and isfile and isfile(CONFIG) then
                local rawData = readfile(CONFIG)
                if rawData and rawData ~= "" then
                    local data = HttpService:JSONDecode(rawData)
                    
                    -- Validate and load data
                    if data.waitTime and type(data.waitTime) == "number" then
                        waitTime = data.waitTime
                    end
                    
                    if data.eventDuration and type(data.eventDuration) == "number" then
                        eventDuration = data.eventDuration
                    end
                    
                    if data.home and type(data.home) == "table" and data.home.x and data.home.y and data.home.z then
                        homeCoord = {
                            x = tonumber(data.home.x),
                            y = tonumber(data.home.y),
                            z = tonumber(data.home.z)
                        }
                    end
                    
                    if data.tujuan and type(data.tujuan) == "table" and data.tujuan.x and data.tujuan.y and data.tujuan.z then
                        tujuanCoord = {
                            x = tonumber(data.tujuan.x),
                            y = tonumber(data.tujuan.y),
                            z = tonumber(data.tujuan.z)
                        }
                    end
                    
                    return true
                end
            end
            return false
        end)
        
        if success and result then
            configLoaded = true
            return true
        end
        
        if attempt < maxRetries then
            task.wait(retryDelay)
        end
    end
    
    return false
end

-- Save Config with validation
local function saveConfig()
    local success = pcall(function()
        if writefile then
            local data = {
                waitTime = waitTime,
                eventDuration = eventDuration,
                home = homeCoord,
                tujuan = tujuanCoord
            }
            writefile(CONFIG, HttpService:JSONEncode(data))
        end
    end)
    return success
end

-- Get Position
local function getPos()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local p = LocalPlayer.Character.HumanoidRootPart.Position
        return {x = math.floor(p.X), y = math.floor(p.Y), z = math.floor(p.Z)}
    end
    return nil
end

-- Teleport
local function tp(x, y, z)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
        return true
    end
    return false
end

-- Teleport to Player
local function tpPlayer(name)
    local p = Players:FindFirstChild(name)
    if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        local pos = p.Character.HumanoidRootPart.Position
        return tp(pos.X, pos.Y, pos.Z)
    end
    return false
end

-- Get Players
local function getPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

-- Notify
local function notif(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "🎄 Xmas Auto",
            Text = msg,
            Duration = 3
        })
    end)
end

-- Format Time
local function fTime(sec)
    local m = math.floor(sec/60)
    local s = sec%60
    return string.format("%02d:%02d", m, s)
end

-- Parse Coordinates
local function parseCoords(text)
    local x, y, z = text:match("^%s*(-?%d+)%s*,%s*(-?%d+)%s*,%s*(-?%d+)%s*$")
    if x and y and z then
        return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
    end
    return nil
end

-- Calculate time since event start
local function getTimeSinceEventStart(eventTime)
    local hour, minute = eventTime:match("(%d+):(%d+)")
    if not hour or not minute then return nil end
    
    hour = tonumber(hour)
    minute = tonumber(minute)
    
    local now = os.date("*t")
    local nowSeconds = now.hour * 3600 + now.min * 60 + now.sec
    local eventSeconds = hour * 3600 + minute * 60
    
    local elapsed = nowSeconds - eventSeconds
    
    if elapsed < 0 then
        elapsed = elapsed + (24 * 3600)
    end
    
    return elapsed
end

-- Check if currently in event window
local function isInEventWindow()
    for _, time in ipairs(jadwal) do
        local elapsed = getTimeSinceEventStart(time)
        if elapsed and elapsed >= 0 and elapsed < eventDuration then
            return true, eventDuration - elapsed
        end
    end
    return false, 0
end

-- Update UI with loaded config
local function updateUIWithConfig(homeInput, tujuanInput, waitInputMin, waitInputSec, waitLabel)
    task.wait(0.1) -- Small delay to ensure UI is ready
    
    if homeCoord then
        homeInput.Text = string.format("%d,%d,%d", homeCoord.x, homeCoord.y, homeCoord.z)
    end
    
    if tujuanCoord then
        tujuanInput.Text = string.format("%d,%d,%d", tujuanCoord.x, tujuanCoord.y, tujuanCoord.z)
    end
    
    waitInputMin.Text = tostring(math.floor(waitTime/60))
    waitInputSec.Text = tostring(waitTime%60)
    waitLabel.Text = "⏱️ Wait Time: " .. fTime(waitTime)
end

-- Create GUI
local function createGUI()
    if GUI then 
        pcall(function() GUI:Destroy() end)
    end

    GUI = Instance.new("ScreenGui")
    GUI.Name = "XmasGUI"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    if gethui then
        GUI.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(GUI)
        GUI.Parent = game:GetService("CoreGui")
    else
        GUI.Parent = game:GetService("CoreGui")
    end

    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 420, 0, 485)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -242)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = GUI

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = mainFrame

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 10)
    tCorner.Parent = titleBar

    local tFix = Instance.new("Frame")
    tFix.Size = UDim2.new(1, 0, 0, 10)
    tFix.Position = UDim2.new(0, 0, 1, -10)
    tFix.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    tFix.BorderSizePixel = 0
    tFix.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -65, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎄 XMAS AUTO | v1.1"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinimizeBtn"
    minBtn.Size = UDim2.new(0, 26, 0, 24)
    minBtn.Position = UDim2.new(1, -57, 0, 4)
    minBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    minBtn.TextSize = 16
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Parent = titleBar

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 5)
    mCorner.Parent = minBtn

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 26, 0, 24)
    closeBtn.Position = UDim2.new(1, -28, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 5)
    cCorner.Parent = closeBtn

    -- Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -16, 1, -40)
    contentContainer.Position = UDim2.new(0, 8, 0, 36)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame

    -- Left Menu
    local leftMenu = Instance.new("Frame")
    leftMenu.Name = "LeftMenu"
    leftMenu.Size = UDim2.new(0, 95, 1, 0)
    leftMenu.Position = UDim2.new(0, 0, 0, 0)
    leftMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    leftMenu.BorderSizePixel = 0
    leftMenu.Parent = contentContainer

    local lmCorner = Instance.new("UICorner")
    lmCorner.CornerRadius = UDim.new(0, 8)
    lmCorner.Parent = leftMenu

    -- Tab Buttons
    local function createTabBtn(text, icon, yPos, tabName)
        local btn = Instance.new("TextButton")
        btn.Name = tabName .. "Btn"
        btn.Size = UDim2.new(1, -8, 0, 38)
        btn.Position = UDim2.new(0, 4, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.Text = icon .. "\n" .. text
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 9
        btn.Font = Enum.Font.GothamSemibold
        btn.Parent = leftMenu

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        return btn
    end

    local teleportBtn = createTabBtn("Teleport", "🎯", 4, "teleport")
    local playerBtn = createTabBtn("TP Player", "👥", 46, "player")

    -- Right Content Frame
    local rightContent = Instance.new("Frame")
    rightContent.Name = "RightContent"
    rightContent.Size = UDim2.new(1, -102, 1, 0)
    rightContent.Position = UDim2.new(0, 99, 0, 0)
    rightContent.BackgroundTransparency = 1
    rightContent.Parent = contentContainer

    -- Status Label
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, 0, 0, 38)
    status.Position = UDim2.new(0, 0, 0, 0)
    status.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    status.Text = "⏸️ INACTIVE\n⏰ 00:00:00"
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.TextSize = 11
    status.Font = Enum.Font.GothamBold
    status.Parent = rightContent

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 6)
    sCorner.Parent = status

    -- Teleport Tab Content
    local teleportTab = Instance.new("Frame")
    teleportTab.Name = "TeleportTab"
    teleportTab.Size = UDim2.new(1, 0, 1, -44)
    teleportTab.Position = UDim2.new(0, 0, 0, 42)
    teleportTab.BackgroundTransparency = 1
    teleportTab.Visible = true
    teleportTab.Parent = rightContent

    local yPos = 0

    -- Helper function to create buttons
    local function createBtn(text, callback, color, size, parent)
        local b = Instance.new("TextButton")
        b.Size = size or UDim2.new(1, 0, 0, 28)
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 9
        b.Font = Enum.Font.GothamSemibold
        b.Parent = parent
        
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 5)
        bc.Parent = b
        
        b.MouseButton1Click:Connect(callback)
        return b
    end

    -- Copy Button
    local copyBtn = createBtn("📋 COPY CURRENT POSITION", function()
        copiedCoord = getPos()
        if copiedCoord then
            notif("✅ Position copied!")
            pcall(function()
                if setclipboard then
                    setclipboard(string.format("%d,%d,%d", copiedCoord.x, copiedCoord.y, copiedCoord.z))
                end
            end)
        else
            notif("❌ Failed to copy position")
        end
    end, Color3.fromRGB(70, 150, 230), nil, teleportTab)
    copyBtn.Position = UDim2.new(0, 0, 0, yPos)

    yPos = yPos + 32

    -- Home Input
    local homeInput = Instance.new("TextBox")
    homeInput.Size = UDim2.new(1, 0, 0, 28)
    homeInput.Position = UDim2.new(0, 0, 0, yPos)
    homeInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    homeInput.PlaceholderText = "🏠 Paste Home coordinates (x,y,z)"
    homeInput.Text = ""
    homeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    homeInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    homeInput.TextSize = 8
    homeInput.Font = Enum.Font.Gotham
    homeInput.ClearTextOnFocus = false
    homeInput.Parent = teleportTab

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0, 5)
    hCorner.Parent = homeInput

    homeInput.FocusLost:Connect(function()
        local coords = parseCoords(homeInput.Text)
        if coords then
            homeCoord = coords
            notif("✅ Home position set!")
            saveConfig()
        elseif homeInput.Text ~= "" then
            notif("❌ Invalid format! Use: x,y,z")
            homeInput.Text = homeCoord and string.format("%d,%d,%d", homeCoord.x, homeCoord.y, homeCoord.z) or ""
        end
    end)

    yPos = yPos + 32

    -- Test Home Button
    local testHomeBtn = createBtn("🏠 TEST HOME POSITION", function()
        if homeCoord then
            if tp(homeCoord.x, homeCoord.y, homeCoord.z) then
                notif("✅ Teleported to Home!")
            else
                notif("❌ Failed to teleport")
            end
        else
            notif("❌ Set Home position first!")
        end
    end, Color3.fromRGB(100, 150, 200), nil, teleportTab)
    testHomeBtn.Position = UDim2.new(0, 0, 0, yPos)

    yPos = yPos + 32

    -- Tujuan Input
    local tujuanInput = Instance.new("TextBox")
    tujuanInput.Size = UDim2.new(1, 0, 0, 28)
    tujuanInput.Position = UDim2.new(0, 0, 0, yPos)
    tujuanInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    tujuanInput.PlaceholderText = "🎯 Paste Destination coordinates (x,y,z)"
    tujuanInput.Text = ""
    tujuanInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    tujuanInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    tujuanInput.TextSize = 8
    tujuanInput.Font = Enum.Font.Gotham
    tujuanInput.ClearTextOnFocus = false
    tujuanInput.Parent = teleportTab

    local tCorner2 = Instance.new("UICorner")
    tCorner2.CornerRadius = UDim.new(0, 5)
    tCorner2.Parent = tujuanInput

    tujuanInput.FocusLost:Connect(function()
        local coords = parseCoords(tujuanInput.Text)
        if coords then
            tujuanCoord = coords
            notif("✅ Destination set!")
            saveConfig()
        elseif tujuanInput.Text ~= "" then
            notif("❌ Invalid format! Use: x,y,z")
            tujuanInput.Text = tujuanCoord and string.format("%d,%d,%d", tujuanCoord.x, tujuanCoord.y, tujuanCoord.z) or ""
        end
    end)

    yPos = yPos + 32

    -- Test Tujuan Button
    local testTujuanBtn = createBtn("🎯 TEST DESTINATION", function()
        if tujuanCoord then
            if tp(tujuanCoord.x, tujuanCoord.y, tujuanCoord.z) then
                notif("✅ Teleported to Destination!")
            else
                notif("❌ Failed to teleport")
            end
        else
            notif("❌ Set Destination first!")
        end
    end, Color3.fromRGB(200, 120, 80), nil, teleportTab)
    testTujuanBtn.Position = UDim2.new(0, 0, 0, yPos)

    yPos = yPos + 36

    -- Info Label
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 72)
    info.Position = UDim2.new(0, 0, 0, yPos)
    info.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    info.TextColor3 = Color3.fromRGB(200, 200, 200)
    info.TextSize = 8
    info.Font = Enum.Font.Gotham
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Parent = teleportTab

    local iCorner = Instance.new("UICorner")
    iCorner.CornerRadius = UDim.new(0, 5)
    iCorner.Parent = info

    local iPad = Instance.new("UIPadding")
    iPad.PaddingLeft = UDim.new(0, 6)
    iPad.PaddingTop = UDim.new(0, 6)
    iPad.Parent = info

    info.Text = "📅 Schedule:\n11:00, 13:00, 15:00, 17:00, 19:00\n21:00, 23:00, 01:00, 03:00, 05:00\n07:00, 09:00\n\n⏱️ Duration: 30 min | 🔄 Home→Dest→Home"

    yPos = yPos + 76

    -- Wait Time Label
    local waitLabel = Instance.new("TextLabel")
    waitLabel.Size = UDim2.new(1, 0, 0, 18)
    waitLabel.Position = UDim2.new(0, 0, 0, yPos)
    waitLabel.BackgroundTransparency = 1
    waitLabel.Text = "⏱️ Wait Time: " .. fTime(waitTime)
    waitLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitLabel.TextSize = 9
    waitLabel.Font = Enum.Font.GothamBold
    waitLabel.TextXAlignment = Enum.TextXAlignment.Left
    waitLabel.Parent = teleportTab

    yPos = yPos + 20

    -- Wait Time Input (Minutes)
    local waitInputMin = Instance.new("TextBox")
    waitInputMin.Size = UDim2.new(0.3, 0, 0, 28)
    waitInputMin.Position = UDim2.new(0, 0, 0, yPos)
    waitInputMin.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    waitInputMin.PlaceholderText = "Minutes"
    waitInputMin.Text = tostring(math.floor(waitTime/60))
    waitInputMin.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitInputMin.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    waitInputMin.TextSize = 9
    waitInputMin.Font = Enum.Font.Gotham
    waitInputMin.ClearTextOnFocus = false
    waitInputMin.Parent = teleportTab

    local wCornerMin = Instance.new("UICorner")
    wCornerMin.CornerRadius = UDim.new(0, 5)
    wCornerMin.Parent = waitInputMin

    -- Wait Time Input (Seconds)
    local waitInputSec = Instance.new("TextBox")
    waitInputSec.Size = UDim2.new(0.3, 0, 0, 28)
    waitInputSec.Position = UDim2.new(0.32, 0, 0, yPos)
    waitInputSec.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    waitInputSec.PlaceholderText = "Seconds"
    waitInputSec.Text = tostring(waitTime%60)
    waitInputSec.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitInputSec.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    waitInputSec.TextSize = 9
    waitInputSec.Font = Enum.Font.Gotham
    waitInputSec.ClearTextOnFocus = false
    waitInputSec.Parent = teleportTab

    local wCornerSec = Instance.new("UICorner")
    wCornerSec.CornerRadius = UDim.new(0, 5)
    wCornerSec.Parent = waitInputSec

    -- Set Wait Button
    local setWaitBtn = createBtn("✅ SET", function()
        local m = tonumber(waitInputMin.Text) or 0
        local s = tonumber(waitInputSec.Text) or 0
        
        if m >= 0 and s >= 0 and s < 60 and (m > 0 or s > 0) then
            waitTime = (m * 60) + s
            waitLabel.Text = "⏱️ Wait Time: " .. fTime(waitTime)
            notif("✅ Set: " .. m .. "m " .. s .. "s")
            saveConfig()
        else
            notif("❌ Invalid numbers!")
        end
    end, Color3.fromRGB(70, 180, 100), UDim2.new(0.36, 0, 0, 28), teleportTab)
    setWaitBtn.Position = UDim2.new(0.64, 0, 0, yPos)

    yPos = yPos + 32

    -- Start/Stop Button
    local startBtn = createBtn("▶️ START AUTO", function()
        if not homeCoord or not tujuanCoord then
            notif("❌ Set Home & Destination first!")
            return
        end

        if isRunning then
            notif("⏸️ Wait time not finished!")
            return
        end

        autoEnabled = not autoEnabled
        
        if autoEnabled then
            startBtn.Text = "⏹️ STOP AUTO"
            startBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
            notif("✅ Auto ENABLED!")
        else
            startBtn.Text = "▶️ START AUTO"
            startBtn.BackgroundColor3 = Color3.fromRGB(70, 180, 100)
            notif("⏸️ Auto STOPPED")
        end
    end, Color3.fromRGB(70, 180, 100), UDim2.new(1, 0, 0, 34), teleportTab)
    startBtn.Position = UDim2.new(0, 0, 0, yPos)

    -- Player Tab Content
    local playerTab = Instance.new("Frame")
    playerTab.Name = "PlayerTab"
    playerTab.Size = UDim2.new(1, 0, 1, -44)
    playerTab.Position = UDim2.new(0, 0, 0, 42)
    playerTab.BackgroundTransparency = 1
    playerTab.Visible = false
    playerTab.Parent = rightContent

    -- Player List Frame
    local playerFrame = Instance.new("ScrollingFrame")
    playerFrame.Size = UDim2.new(1, 0, 1, -36)
    playerFrame.Position = UDim2.new(0, 0, 0, 0)
    playerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    playerFrame.BorderSizePixel = 0
    playerFrame.ScrollBarThickness = 4
    playerFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 50)
    playerFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerFrame.Parent = playerTab

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 5)
    pCorner.Parent = playerFrame
    -- Update Player List
    local function updatePlayers()
        for _, c in ipairs(playerFrame:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") then 
                c:Destroy() 
            end
        end

        local players = getPlayers()
        local py = 4

        if #players == 0 then
            local none = Instance.new("TextLabel")
            none.Size = UDim2.new(1, -8, 0, 26)
            none.Position = UDim2.new(0, 4, 0, 4)
            none.BackgroundTransparency = 1
            none.Text = "No other players found"
            none.TextColor3 = Color3.fromRGB(150, 150, 150)
            none.TextSize = 9
            none.Font = Enum.Font.Gotham
            none.Parent = playerFrame
        else
            for _, name in ipairs(players) do
                local pb = Instance.new("TextButton")
                pb.Size = UDim2.new(1, -8, 0, 28)
                pb.Position = UDim2.new(0, 4, 0, py)
                pb.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
                pb.Text = "👤 " .. name
                pb.TextColor3 = Color3.fromRGB(255, 255, 255)
                pb.TextSize = 9
                pb.Font = Enum.Font.Gotham
                pb.Parent = playerFrame

                local pbCorner = Instance.new("UICorner")
                pbCorner.CornerRadius = UDim.new(0, 5)
                pbCorner.Parent = pb

                pb.MouseButton1Click:Connect(function()
                    if tpPlayer(name) then
                        notif("✅ Teleported to " .. name)
                    else
                        notif("❌ Failed to teleport")
                    end
                end)

                py = py + 32
            end
        end

        playerFrame.CanvasSize = UDim2.new(0, 0, 0, py + 4)
    end

    -- Refresh Player Button
    local refreshBtn = createBtn("🔄 REFRESH PLAYER LIST", function()
        updatePlayers()
        notif("✅ List refreshed")
    end, Color3.fromRGB(150, 100, 220), UDim2.new(1, 0, 0, 32), playerTab)
    refreshBtn.Position = UDim2.new(0, 0, 1, -32)

    updatePlayers()

    -- Tab Switching Logic
    local function switchTab(tabName)
        currentTab = tabName
        
        -- Hide all tabs
        teleportTab.Visible = false
        playerTab.Visible = false
        
        -- Reset button colors
        teleportBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        playerBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        teleportBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        playerBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        
        -- Show selected tab
        if tabName == "teleport" then
            teleportTab.Visible = true
            teleportBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        elseif tabName == "player" then
            playerTab.Visible = true
            playerBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            updatePlayers()
        end
    end

    teleportBtn.MouseButton1Click:Connect(function()
        switchTab("teleport")
    end)

    playerBtn.MouseButton1Click:Connect(function()
        switchTab("player")
    end)

    -- Initialize first tab
    switchTab("teleport")

    -- Menu Button (for minimize)
    local menuBtn = Instance.new("TextButton")
    menuBtn.Name = "MenuBtn"
    menuBtn.Size = UDim2.new(0, 85, 0, 34)
    menuBtn.Position = UDim2.new(0.5, -42, 0, 10)
    menuBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    menuBtn.Text = "⚙️ MENU"
    menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    menuBtn.TextSize = 12
    menuBtn.Font = Enum.Font.GothamBold
    menuBtn.Visible = false
    menuBtn.Parent = GUI

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 8)
    menuCorner.Parent = menuBtn

    -- Button Click Events
    minBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        menuBtn.Visible = true
        notif("📦 Minimized")
    end)

    menuBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        menuBtn.Visible = false
    end)

    closeBtn.MouseButton1Click:Connect(function()
        autoEnabled = false
        isRunning = false
        notif("👋 Script closed")
        task.wait(0.5)
        pcall(function() GUI:Destroy() end)
    end)

    -- Make Draggable
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)

    -- Load config after UI is created and update UI
    task.spawn(function()
        task.wait(0.2) -- Wait for UI to fully render
        if loadConfig() then
            updateUIWithConfig(homeInput, tujuanInput, waitInputMin, waitInputSec, waitLabel)
            if configLoaded then
                notif("✅ Config loaded successfully!")
            end
        end
    end)

    return status, startBtn
end

-- Auto Teleport Logic
local statusLabel, startBtn = createGUI()

-- Update Time with Seconds
task.spawn(function()
    while task.wait(1) do
        if statusLabel then
            local timeStr = os.date("%H:%M:%S")
            if autoEnabled then
                if isRunning then
                    -- Status will be updated by main logic
                else
                    statusLabel.Text = "▶️ ACTIVE - Waiting for schedule\n⏰ " .. timeStr
                end
            else
                statusLabel.Text = "⏸️ INACTIVE\n⏰ " .. timeStr
            end
        end
    end
end)

-- Main Auto Logic
task.spawn(function()
    while task.wait(1) do
        if autoEnabled and not isRunning then
            -- Check if currently in event window
            local inEvent, remainingTime = isInEventWindow()
            
            if inEvent and remainingTime > 0 then
                isRunning = true
                autoStartTime = tick()
                
                if homeCoord and tujuanCoord then
                    statusLabel.Text = "▶️ TP to DESTINATION...\n⏰ " .. os.date("%H:%M:%S")
                    notif("🎄 TP to Christmas Cave! Remaining: " .. fTime(math.floor(remainingTime)))
                    
                    if tp(tujuanCoord.x, tujuanCoord.y, tujuanCoord.z) then
                        notif("✅ Arrived at destination!")
                        
                        -- Use the smaller time between waitTime and remainingTime
                        local actualWaitTime = math.min(waitTime, remainingTime)
                        local endTime = tick() + actualWaitTime
                        
                        while tick() < endTime and autoEnabled do
                            local left = math.floor(endTime - tick())
                            statusLabel.Text = "⏳ WAITING\n⏰ Time left: " .. fTime(left)
                            task.wait(1)
                        end
                        
                        if autoEnabled then
                            statusLabel.Text = "▶️ RETURNING to HOME...\n⏰ " .. os.date("%H:%M:%S")
                            notif("🏠 Returning to Home!")
                            
                            tp(homeCoord.x, homeCoord.y, homeCoord.z)
                            notif("✅ Arrived at Home!")
                        end
                    else
                        notif("❌ Failed to teleport")
                    end
                end
                
                isRunning = false
                autoStartTime = 0
                task.wait(5)
            end
        elseif not autoEnabled and isRunning then
            -- If auto is canceled while still running, show remaining time
            local elapsed = tick() - autoStartTime
            local remaining = waitTime - elapsed
            
            if remaining > 0 then
                statusLabel.Text = "⏸️ WAIT TIME NOT FINISHED\n⏰ Remaining: " .. fTime(math.floor(remaining))
            end
        end
    end
end)

-- Initialize
notif("🎄 Xmas Script Loaded!")
print("🎄 Christmas Cave Script Successfully Loaded!")
