
-- Christmas Cave & Lochness Auto Teleport Script
-- Compatible with Delta Executor, Android & PC

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local StartekrGui = game:GetService("StarterGui")

-- Variables
local GUI = nil
local mainFrame = nil
local autoXmasEnabled = false
local autoLochEnabled = false
local isXmasRunning = false
local isLochRunning = false

-- Xmas Variables
local xmasWaitTime = 30 * 60
local xmasHomeCoord = nil
local xmasTujuanCoord = nil
local xmasAutoStartTime = 0
local xmasEventDuration = 30 * 60
local xmasJadwal = {"11:00","13:00","15:00","17:00","19:00","21:00","23:00","01:00","03:00","05:00","07:00","09:00"}

-- Lochness Variables
local lochWaitTime = 10 * 60  -- 10 menit
local lochHomeCoord = nil
local lochTujuanCoord = nil
local lochAutoStartTime = 0
local lochEventDuration = 10 * 60  -- 10 menit event
local lochEventInterval = 4 * 60 * 60  -- 4 jam
local lochLastEventTime = 11 * 3600  -- Default jam 11:00 pagi dalam detik

local copiedCoord = nil
local currentTab = "xmas"

-- Config
local CONFIG = "EventAutoConfig.json"

-- Load Config
local function loadConfig()
    local success = pcall(function()
        if readfile and isfile and isfile(CONFIG) then
            local data = HttpService:JSONDecode(readfile(CONFIG))
            
            -- Xmas Config
            xmasWaitTime = data.xmasWaitTime or (30 * 60)
            xmasEventDuration = data.xmasEventDuration or (30 * 60)
            xmasHomeCoord = data.xmasHome
            xmasTujuanCoord = data.xmasTujuan
            
            -- Lochness Config
            lochWaitTime = data.lochWaitTime or (10 * 60)
            lochEventDuration = data.lochEventDuration or (10 * 60)
            lochHomeCoord = data.lochHome
            lochTujuanCoord = data.lochTujuan
            lochLastEventTime = data.lochLastEventTime or (11 * 3600)
        end
    end)
    return success
end

-- Save Config
local function saveConfig()
    local success = pcall(function()
        if writefile then
            writefile(CONFIG, HttpService:JSONEncode({
                -- Xmas
                xmasWaitTime = xmasWaitTime,
                xmasEventDuration = xmasEventDuration,
                xmasHome = xmasHomeCoord,
                xmasTujuan = xmasTujuanCoord,
                
                -- Lochness
                lochWaitTime = lochWaitTime,
                lochEventDuration = lochEventDuration,
                lochHome = lochHomeCoord,
                lochTujuan = lochTujuanCoord,
                lochLastEventTime = lochLastEventTime
            }))
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
            Title = "🎄 Event Auto",
            Text = msg,
            Duration = 3
        })
    end)
end

-- Format Time
local function fTime(sec)
    local h = math.floor(sec/3600)
    local m = math.floor((sec%3600)/60)
    local s = sec%60
    
    if h > 0 then
        return string.format("%dj %02dm %02ds", h, m, s)
    else
        return string.format("%02d:%02d", m, s)
    end
end

-- Parse Coordinates
local function parseCoords(text)
    local x, y, z = text:match("^%s*(-?%d+)%s*,%s*(-?%d+)%s*,%s*(-?%d+)%s*$")
    if x and y and z then
        return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
    end
    return nil
end

-- Calculate time since event start (Xmas)
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

-- Check if currently in Xmas event window
local function isInXmasEventWindow()
    for _, time in ipairs(xmasJadwal) do
        local elapsed = getTimeSinceEventStart(time)
        if elapsed and elapsed >= 0 and elapsed < xmasEventDuration then
            return true, xmasEventDuration - elapsed
        end
    end
    return false, 0
end

-- Check Lochness event (setiap 4 jam dari jam terakhir)
local function isInLochEventWindow()
    local now = os.date("*t")
    local nowSeconds = now.hour * 3600 + now.min * 60 + now.sec
    
    -- Hitung waktu sejak event terakhir
    local timeSinceLastEvent = nowSeconds - lochLastEventTime
    
    -- Handle lewat midnight
    if timeSinceLastEvent < 0 then
        timeSinceLastEvent = timeSinceLastEvent + (24 * 3600)
    end
    
    -- Cek apakah sudah waktunya event baru (4 jam)
    if timeSinceLastEvent >= lochEventInterval then
        -- Update last event time
        lochLastEventTime = nowSeconds
        saveConfig()
        return true, lochEventDuration
    end
    
    -- Cek apakah masih dalam durasi event (10 menit)
    if timeSinceLastEvent < lochEventDuration then
        return true, lochEventDuration - timeSinceLastEvent
    end
    
    return false, 0
end

-- Get next Lochness event time
local function getNextLochEvent()
    local now = os.date("*t")
    local nowSeconds = now.hour * 3600 + now.min * 60 + now.sec
    
    local timeSinceLastEvent = nowSeconds - lochLastEventTime
    
    if timeSinceLastEvent < 0 then
        timeSinceLastEvent = timeSinceLastEvent + (24 * 3600)
    end
    
    -- Jika masih dalam event
    if timeSinceLastEvent < lochEventDuration then
        return lochEventDuration - timeSinceLastEvent
    end
    
    -- Hitung waktu sampai event berikutnya
    local timeUntilNext = lochEventInterval - timeSinceLastEvent
    return timeUntilNext
end

-- Create GUI
local function createGUI()
    if GUI then 
        pcall(function() GUI:Destroy() end)
    end

    GUI = Instance.new("ScreenGui")
    GUI.Name = "EventAutoGUI"
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
    mainFrame.Size = UDim2.new(0, 420, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
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
    title.Text = "🎄 Event Auto Teleport"
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

    -- Left Menu (Tab Buttons)
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

    local xmasBtn = createTabBtn("Xmas", "🎄", 4, "xmas")
    local lochBtn = createTabBtn("Lochness", "🐉", 46, "loch")
    local playerBtn = createTabBtn("TP Player", "👥", 88, "player")

    -- Right Content Frame
    local rightContent = Instance.new("Frame")
    rightContent.Name = "RightContent"
    rightContent.Size = UDim2.new(1, -102, 1, 0)
    rightContent.Position = UDim2.new(0, 99, 0, 0)
    rightContent.BackgroundTransparency = 1
    rightContent.Parent = contentContainer

    -- Status Labels Container
    local statusContainer = Instance.new("Frame")
    statusContainer.Name = "StatusContainer"
    statusContainer.Size = UDim2.new(1, 0, 0, 76)
    statusContainer.Position = UDim2.new(0, 0, 0, 0)
    statusContainer.BackgroundTransparency = 1
    statusContainer.Parent = rightContent

    -- Xmas Status Label
    local xmasStatus = Instance.new("TextLabel")
    xmasStatus.Name = "XmasStatus"
    xmasStatus.Size = UDim2.new(1, 0, 0, 36)
    xmasStatus.Position = UDim2.new(0, 0, 0, 0)
    xmasStatus.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    xmasStatus.Text = "🎄 XMAS: ⏸️ OFF\n⏰ 00:00:00"
    xmasStatus.TextColor3 = Color3.fromRGB(255, 200, 100)
    xmasStatus.TextSize = 10
    xmasStatus.Font = Enum.Font.GothamBold
    xmasStatus.Parent = statusContainer

    local xsCorner = Instance.new("UICorner")
    xsCorner.CornerRadius = UDim.new(0, 6)
    xsCorner.Parent = xmasStatus

    -- Lochness Status Label
    local lochStatus = Instance.new("TextLabel")
    lochStatus.Name = "LochStatus"
    lochStatus.Size = UDim2.new(1, 0, 0, 36)
    lochStatus.Position = UDim2.new(0, 0, 0, 40)
    lochStatus.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    lochStatus.Text = "🐉 LOCH: ⏸️ OFF\n⏰ Next: 0j 00m"
    lochStatus.TextColor3 = Color3.fromRGB(100, 200, 255)
    lochStatus.TextSize = 10
    lochStatus.Font = Enum.Font.GothamBold
    lochStatus.Parent = statusContainer

    local lsCorner = Instance.new("UICorner")
    lsCorner.CornerRadius = UDim.new(0, 6)
    lsCorner.Parent = lochStatus

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
    -- XMAS TAB CONTENT
    local xmasTab = Instance.new("Frame")
    xmasTab.Name = "XmasTab"
    xmasTab.Size = UDim2.new(1, 0, 1, -80)
    xmasTab.Position = UDim2.new(0, 0, 0, 80)
    xmasTab.BackgroundTransparency = 1
    xmasTab.Visible = true
    xmasTab.Parent = rightContent

    local xYPos = 0

    -- Copy Koordinat Button
    local xmasCopyBtn = createBtn("📋 COPY KOORDINAT", function()
        copiedCoord = getPos()
        if copiedCoord then
            notif("✅ Koordinat di-copy!")
            pcall(function()
                if setclipboard then
                    setclipboard(string.format("%d,%d,%d", copiedCoord.x, copiedCoord.y, copiedCoord.z))
                end
            end)
        else
            notif("❌ Gagal copy posisi")
        end
    end, Color3.fromRGB(70, 150, 230), nil, xmasTab)
    xmasCopyBtn.Position = UDim2.new(0, 0, 0, xYPos)

    xYPos = xYPos + 32

    -- Xmas Home Input
    local xmasHomeInput = Instance.new("TextBox")
    xmasHomeInput.Size = UDim2.new(1, 0, 0, 28)
    xmasHomeInput.Position = UDim2.new(0, 0, 0, xYPos)
    xmasHomeInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    xmasHomeInput.PlaceholderText = "Paste koordinat Home (x,y,z)"
    xmasHomeInput.Text = xmasHomeCoord and string.format("%d,%d,%d", xmasHomeCoord.x, xmasHomeCoord.y, xmasHomeCoord.z) or ""
    xmasHomeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    xmasHomeInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    xmasHomeInput.TextSize = 8
    xmasHomeInput.Font = Enum.Font.Gotham
    xmasHomeInput.ClearTextOnFocus = false
    xmasHomeInput.Parent = xmasTab

    local xhCorner = Instance.new("UICorner")
    xhCorner.CornerRadius = UDim.new(0, 5)
    xhCorner.Parent = xmasHomeInput

    xmasHomeInput.FocusLost:Connect(function()
        local coords = parseCoords(xmasHomeInput.Text)
        if coords then
            xmasHomeCoord = coords
            notif("✅ Xmas Home di-set!")
            saveConfig()
        elseif xmasHomeInput.Text ~= "" then
            notif("❌ Format salah! Gunakan: x,y,z")
            xmasHomeInput.Text = xmasHomeCoord and string.format("%d,%d,%d", xmasHomeCoord.x, xmasHomeCoord.y, xmasHomeCoord.z) or ""
        end
    end)

    xYPos = xYPos + 32

    -- Test Xmas Home Button
    local xmasTestHomeBtn = createBtn("🧪 TEST HOME", function()
        if xmasHomeCoord then
            if tp(xmasHomeCoord.x, xmasHomeCoord.y, xmasHomeCoord.z) then
                notif("✅ TP ke Xmas Home berhasil!")
            else
                notif("❌ Gagal TP ke Xmas Home")
            end
        else
            notif("❌ Set koordinat Xmas Home dulu!")
        end
    end, Color3.fromRGB(100, 150, 200), nil, xmasTab)
    xmasTestHomeBtn.Position = UDim2.new(0, 0, 0, xYPos)

    xYPos = xYPos + 32

    -- Xmas Tujuan Input
    local xmasTujuanInput = Instance.new("TextBox")
    xmasTujuanInput.Size = UDim2.new(1, 0, 0, 28)
    xmasTujuanInput.Position = UDim2.new(0, 0, 0, xYPos)
    xmasTujuanInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    xmasTujuanInput.PlaceholderText = "Paste koordinat Tujuan (x,y,z)"
    xmasTujuanInput.Text = xmasTujuanCoord and string.format("%d,%d,%d", xmasTujuanCoord.x, xmasTujuanCoord.y, xmasTujuanCoord.z) or ""
    xmasTujuanInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    xmasTujuanInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    xmasTujuanInput.TextSize = 8
    xmasTujuanInput.Font = Enum.Font.Gotham
    xmasTujuanInput.ClearTextOnFocus = false
    xmasTujuanInput.Parent = xmasTab

    local xtCorner = Instance.new("UICorner")
    xtCorner.CornerRadius = UDim.new(0, 5)
    xtCorner.Parent = xmasTujuanInput

    xmasTujuanInput.FocusLost:Connect(function()
        local coords = parseCoords(xmasTujuanInput.Text)
        if coords then
            xmasTujuanCoord = coords
            notif("✅ Xmas Tujuan di-set!")
            saveConfig()
        elseif xmasTujuanInput.Text ~= "" then
            notif("❌ Format salah! Gunakan: x,y,z")
            xmasTujuanInput.Text = xmasTujuanCoord and string.format("%d,%d,%d", xmasTujuanCoord.x, xmasTujuanCoord.y, xmasTujuanCoord.z) or ""
        end
    end)

    xYPos = xYPos + 32

    -- Test Xmas Tujuan Button
    local xmasTestTujuanBtn = createBtn("🧪 TEST TUJUAN", function()
        if xmasTujuanCoord then
            if tp(xmasTujuanCoord.x, xmasTujuanCoord.y, xmasTujuanCoord.z) then
                notif("✅ TP ke Xmas Tujuan berhasil!")
            else
                notif("❌ Gagal TP ke Xmas Tujuan")
            end
        else
            notif("❌ Set koordinat Xmas Tujuan dulu!")
        end
    end, Color3.fromRGB(200, 120, 80), nil, xmasTab)
    xmasTestTujuanBtn.Position = UDim2.new(0, 0, 0, xYPos)

    xYPos = xYPos + 36

    -- Xmas Info Label
    local xmasInfo = Instance.new("TextLabel")
    xmasInfo.Size = UDim2.new(1, 0, 0, 72)
    xmasInfo.Position = UDim2.new(0, 0, 0, xYPos)
    xmasInfo.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    xmasInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    xmasInfo.TextSize = 8
    xmasInfo.Font = Enum.Font.Gotham
    xmasInfo.TextXAlignment = Enum.TextXAlignment.Left
    xmasInfo.TextYAlignment = Enum.TextYAlignment.Top
    xmasInfo.Parent = xmasTab

    local xiCorner = Instance.new("UICorner")
    xiCorner.CornerRadius = UDim.new(0, 5)
    xiCorner.Parent = xmasInfo

    local xiPad = Instance.new("UIPadding")
    xiPad.PaddingLeft = UDim.new(0, 6)
    xiPad.PaddingTop = UDim.new(0, 6)
    xiPad.Parent = xmasInfo

    xmasInfo.Text = "⏰ Jadwal:\n11:00, 13:00, 15:00, 17:00, 19:00\n21:00, 23:00, 01:00, 03:00, 05:00\n07:00, 09:00\n\n⏱️ Durasi: 30 menit | 🔄 Home→Tujuan→Home"

    xYPos = xYPos + 76

    -- Xmas Wait Time Label
    local xmasWaitLabel = Instance.new("TextLabel")
    xmasWaitLabel.Size = UDim2.new(1, 0, 0, 18)
