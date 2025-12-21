
-- Christmas Cave Auto Teleport Script
-- Compatible with Delta Executor, Android & PC

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

-- Config
local CONFIG = "XmasConfig.json"

-- Load Config
local function loadConfig()
    local success = pcall(function()
        if readfile and isfile and isfile(CONFIG) then
            local data = HttpService:JSONDecode(readfile(CONFIG))
            waitTime = data.waitTime or (30 * 60)
            homeCoord = data.home
            tujuanCoord = data.tujuan
        end
    end)
    return success
end

-- Save Config
local function saveConfig()
    local success = pcall(function()
        if writefile then
            writefile(CONFIG, HttpService:JSONEncode({
                waitTime = waitTime,
                home = homeCoord,
                tujuan = tujuanCoord
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
    mainFrame.Size = UDim2.new(0, 450, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -260)
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
    titleBar.Size = UDim2.new(1, 0, 0, 35)
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
    title.Size = UDim2.new(1, -75, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎄 Xmas Cave Auto"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 15
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinimizeBtn"
    minBtn.Size = UDim2.new(0, 30, 0, 28)
    minBtn.Position = UDim2.new(1, -65, 0, 3.5)
    minBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    minBtn.TextSize = 18
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Parent = titleBar

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 5)
    mCorner.Parent = minBtn

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 3.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 5)
    cCorner.Parent = closeBtn

    -- Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 1, -45)
    contentContainer.Position = UDim2.new(0, 10, 0, 40)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame

    -- Left Menu (Tab Buttons)
    local leftMenu = Instance.new("Frame")
    leftMenu.Name = "LeftMenu"
    leftMenu.Size = UDim2.new(0, 110, 1, 0)
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
        btn.Size = UDim2.new(1, -10, 0, 45)
        btn.Position = UDim2.new(0, 5, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.Text = icon .. "\n" .. text
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamSemibold
        btn.Parent = leftMenu

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        return btn
    end

    local teleportBtn = createTabBtn("Teleport", "🚀", 5, "teleport")
    local playerBtn = createTabBtn("TP Player", "👥", 55, "player")

    -- Right Content Frame
    local rightContent = Instance.new("Frame")
    rightContent.Name = "RightContent"
    rightContent.Size = UDim2.new(1, -120, 1, 0)
    rightContent.Position = UDim2.new(0, 115, 0, 0)
    rightContent.BackgroundTransparency = 1
    rightContent.Parent = contentContainer

    -- Status Label (Always visible)
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, 0, 0, 45)
    status.Position = UDim2.new(0, 0, 0, 0)
    status.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    status.Text = "⏸️ TIDAK AKTIF\n⏰ 00:00:00"
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.TextSize = 12
    status.Font = Enum.Font.GothamBold
    status.Parent = rightContent

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 6)
    sCorner.Parent = status

    -- Teleport Tab Content
    local teleportTab = Instance.new("Frame")
    teleportTab.Name = "TeleportTab"
    teleportTab.Size = UDim2.new(1, 0, 1, -55)
    teleportTab.Position = UDim2.new(0, 0, 0, 50)
    teleportTab.BackgroundTransparency = 1
    teleportTab.Visible = true
    teleportTab.Parent = rightContent

    local yPos = 0

    -- Helper function to create buttons
    local function createBtn(text, callback, color, size, parent)
        local b = Instance.new("TextButton")
        b.Size = size or UDim2.new(1, 0, 0, 35)
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 11
        b.Font = Enum.Font.GothamSemibold
        b.Parent = parent
        
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = b
        
        b.MouseButton1Click:Connect(callback)
        return b
    end

    -- Copy Koordinat Button
    local copyBtn = createBtn("📋 COPY KOORDINAT", function()
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
    end, Color3.fromRGB(70, 150, 230), nil, teleportTab)
    copyBtn.Position = UDim2.new(0, 0, 0, yPos)

    yPos = yPos + 40

    -- Home Input
    local homeInput = Instance.new("TextBox")
    homeInput.Size = UDim2.new(1, 0, 0, 35)
    homeInput.Position = UDim2.new(0, 0, 0, yPos)
    homeInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    homeInput.PlaceholderText = "Paste koordinat Home (x,y,z)"
    homeInput.Text = homeCoord and string.format("%d,%d,%d", homeCoord.x, homeCoord.y, homeCoord.z) or ""
    homeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    homeInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    homeInput.TextSize = 9
    homeInput.Font = Enum.Font.Gotham
    homeInput.ClearTextOnFocus = false
    homeInput.Parent = teleportTab

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0, 6)
    hCorner.Parent = homeInput

    homeInput.FocusLost:Connect(function()
        local coords = parseCoords(homeInput.Text)
        if coords then
            homeCoord = coords
            notif("✅ Home di-set!")
            saveConfig()
        elseif homeInput.Text ~= "" then
            notif("❌ Format salah! Gunakan: x,y,z")
            homeInput.Text = homeCoord and string.format("%d,%d,%d", homeCoord.x, homeCoord.y, homeCoord.z) or ""
        end
    end)

    yPos = yPos + 40

    -- Test Home Button
    local testHomeBtn = createBtn("🧪 TEST HOME", function()
        if homeCoord then
            if tp(homeCoord.x, homeCoord.y, homeCoord.z) then
                notif("✅ TP ke Home berhasil!")
            else
                notif("❌ Gagal TP ke Home")
            end
        else
            notif("❌ Set koordinat Home dulu!")
        end
    end, Color3.fromRGB(100, 150, 200), nil, teleportTab)
    testHomeBtn.Position = UDim2.new(0, 0, 0, yPos)

    yPos = yPos + 40

    -- Tujuan Input
    local tujuanInput = Instance.new("TextBox")
    tujuanInput.Size = UDim2.new(1, 0, 0, 35)
    tujuanInput.Position = UDim2.new(0, 0, 0, yPos)
    tujuanInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    tujuanInput.PlaceholderText = "Paste koordinat Tujuan (x,y,z)"
    tujuanInput.Text = tujuanCoord and string.format("%d,%d,%d", tujuanCoord.x, tujuanCoord.y, tujuanCoord.z) or ""
    tujuanInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    tujuanInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    tujuanInput.TextSize = 9
    tujuanInput.Font = Enum.Font.Gotham
    tujuanInput.ClearTextOnFocus = false
    tujuanInput.Parent = teleportTab

    local tCorner2 = Instance.new("UICorner")
    tCorner2.CornerRadius = UDim.new(0, 6)
    tCorner2.Parent = tujuanInput

    tujuanInput.FocusLost:Connect(function()
        local coords = parseCoords(tujuanInput.Text)
        if coords then
            tujuanCoord = coords
            notif("✅ Tujuan di-set!")
            saveConfig()
        elseif tujuanInput.Text ~= "" then
            notif("❌ Format salah! Gunakan: x,y,z")
            tujuanInput.Text = tujuanCoord and string.format("%d,%d,%d", tujuanCoord.x, tujuanCoord.y, tujuanCoord.z) or ""
        end
    end)

    yPos = yPos + 40

    -- Test Tujuan Button
    local testTujuanBtn = createBtn("🧪 TEST TUJUAN", function()
        if tujuanCoord then
            if tp(tujuanCoord.x, tujuanCoord.y, tujuanCoord.z) then
                notif("✅ TP ke Tujuan berhasil!")
            else
                notif("❌ Gagal TP ke Tujuan")
            end
        else
            notif("❌ Set koordinat Tujuan dulu!")
        end
    end, Color3.fromRGB(200, 120, 80), nil, teleportTab)
    testTujuanBtn.Position = UDim2.new(0, 0, 0, yPos)

    yPos = yPos + 45
    -- Info Label
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 85)
    info.Position = UDim2.new(0, 0, 0, yPos)
    info.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    info.TextColor3 = Color3.fromRGB(200, 200, 200)
    info.TextSize = 10
    info.Font = Enum.Font.Gotham
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Parent = teleportTab

    local iCorner = Instance.new("UICorner")
    iCorner.CornerRadius = UDim.new(0, 6)
    iCorner.Parent = info

    local iPad = Instance.new("UIPadding")
    iPad.PaddingLeft = UDim.new(0, 8)
    iPad.PaddingTop = UDim.new(0, 8)
    iPad.Parent = info

    info.Text = "⏰ Jadwal:\n11:00, 13:00, 15:00, 17:00, 19:00\n21:00, 23:00, 01:00, 03:00, 05:00\n07:00, 09:00\n\n⏱️ Durasi: 30 menit | 🔄 Home→Tujuan→Home"

    yPos = yPos + 95

    -- Wait Time Label
    local waitLabel = Instance.new("TextLabel")
    waitLabel.Size = UDim2.new(1, 0, 0, 22)
    waitLabel.Position = UDim2.new(0, 0, 0, yPos)
    waitLabel.BackgroundTransparency = 1
    waitLabel.Text = "⏱️ Waktu Tunggu: " .. fTime(waitTime)
    waitLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitLabel.TextSize = 11
    waitLabel.Font = Enum.Font.GothamBold
    waitLabel.TextXAlignment = Enum.TextXAlignment.Left
    waitLabel.Parent = teleportTab

    yPos = yPos + 27

    -- Wait Time Input (Menit)
    local waitInputMin = Instance.new("TextBox")
    waitInputMin.Size = UDim2.new(0.3, 0, 0, 35)
    waitInputMin.Position = UDim2.new(0, 0, 0, yPos)
    waitInputMin.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    waitInputMin.PlaceholderText = "Menit"
    waitInputMin.Text = tostring(math.floor(waitTime/60))
    waitInputMin.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitInputMin.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    waitInputMin.TextSize = 11
    waitInputMin.Font = Enum.Font.Gotham
    waitInputMin.ClearTextOnFocus = false
    waitInputMin.Parent = teleportTab

    local wCornerMin = Instance.new("UICorner")
    wCornerMin.CornerRadius = UDim.new(0, 6)
    wCornerMin.Parent = waitInputMin

    -- Wait Time Input (Detik)
    local waitInputSec = Instance.new("TextBox")
    waitInputSec.Size = UDim2.new(0.3, 0, 0, 35)
    waitInputSec.Position = UDim2.new(0.32, 0, 0, yPos)
    waitInputSec.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    waitInputSec.PlaceholderText = "Detik"
    waitInputSec.Text = tostring(waitTime%60)
    waitInputSec.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitInputSec.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    waitInputSec.TextSize = 11
    waitInputSec.Font = Enum.Font.Gotham
    waitInputSec.ClearTextOnFocus = false
    waitInputSec.Parent = teleportTab

    local wCornerSec = Instance.new("UICorner")
    wCornerSec.CornerRadius = UDim.new(0, 6)
    wCornerSec.Parent = waitInputSec

    -- Set Wait Button
    local setWaitBtn = createBtn("✅ SET", function()
        local m = tonumber(waitInputMin.Text) or 0
        local s = tonumber(waitInputSec.Text) or 0
        
        if m >= 0 and s >= 0 and s < 60 and (m > 0 or s > 0) then
            waitTime = (m * 60) + s
            waitLabel.Text = "⏱️ Waktu Tunggu: " .. fTime(waitTime)
            notif("✅ Diset: " .. m .. "m " .. s .. "s")
            saveConfig()
        else
            notif("❌ Angka tidak valid!")
        end
    end, Color3.fromRGB(70, 180, 100), UDim2.new(0.36, 0, 0, 35), teleportTab)
    setWaitBtn.Position = UDim2.new(0.64, 0, 0, yPos)

    yPos = yPos + 45

    -- Start/Stop Button
    local startBtn = createBtn("▶️ START AUTO", function()
        if not homeCoord or not tujuanCoord then
            notif("❌ Set Home & Tujuan dulu!")
            return
        end

        if isRunning then
            notif("⏸️ Waktu belum selesai!")
            return
        end

        autoEnabled = not autoEnabled
        
        if autoEnabled then
            startBtn.Text = "⏸️ STOP AUTO"
            startBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
            notif("✅ Auto AKTIF!")
        else
            startBtn.Text = "▶️ START AUTO"
            startBtn.BackgroundColor3 = Color3.fromRGB(70, 180, 100)
            notif("⏸️ Auto BERHENTI")
        end
    end, Color3.fromRGB(70, 180, 100), UDim2.new(1, 0, 0, 42), teleportTab)
    startBtn.Position = UDim2.new(0, 0, 0, yPos)

    -- Player Tab Content
    local playerTab = Instance.new("Frame")
    playerTab.Name = "PlayerTab"
    playerTab.Size = UDim2.new(1, 0, 1, -55)
    playerTab.Position = UDim2.new(0, 0, 0, 50)
    playerTab.BackgroundTransparency = 1
    playerTab.Visible = false
    playerTab.Parent = rightContent

    -- Player List Frame
    local playerFrame = Instance.new("ScrollingFrame")
    playerFrame.Size = UDim2.new(1, 0, 1, -45)
    playerFrame.Position = UDim2.new(0, 0, 0, 0)
    playerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    playerFrame.BorderSizePixel = 0
    playerFrame.ScrollBarThickness = 4
    playerFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 50)
    playerFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerFrame.Parent = playerTab

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 6)
    pCorner.Parent = playerFrame

    -- Update Player List Function
    local function updatePlayers()
        for _, c in ipairs(playerFrame:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") then 
                c:Destroy() 
            end
        end

        local players = getPlayers()
        local py = 5

        if #players == 0 then
            local none = Instance.new("TextLabel")
            none.Size = UDim2.new(1, -10, 0, 30)
            none.Position = UDim2.new(0, 5, 0, 5)
            none.BackgroundTransparency = 1
            none.Text = "Tidak ada player lain"
            none.TextColor3 = Color3.fromRGB(150, 150, 150)
            none.TextSize = 11
            none.Font = Enum.Font.Gotham
            none.Parent = playerFrame
        else
            for _, name in ipairs(players) do
                local pb = Instance.new("TextButton")
                pb.Size = UDim2.new(1, -10, 0, 32)
                pb.Position = UDim2.new(0, 5, 0, py)
                pb.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
                pb.Text = "👤 " .. name
                pb.TextColor3 = Color3.fromRGB(255, 255, 255)
                pb.TextSize = 11
                pb.Font = Enum.Font.Gotham
                pb.Parent = playerFrame

                local pbCorner = Instance.new("UICorner")
                pbCorner.CornerRadius = UDim.new(0, 5)
                pbCorner.Parent = pb

                pb.MouseButton1Click:Connect(function()
                    if tpPlayer(name) then
                        notif("✅ TP ke " .. name)
                    else
                        notif("❌ Gagal TP")
                    end
                end)

                py = py + 37
            end
        end

        playerFrame.CanvasSize = UDim2.new(0, 0, 0, py + 5)
    end

    -- Refresh Player Button
    local refreshBtn = createBtn("🔄 REFRESH PLAYER LIST", function()
        updatePlayers()
        notif("✅ List di-refresh")
    end, Color3.fromRGB(150, 100, 220), UDim2.new(1, 0, 0, 38), playerTab)
    refreshBtn.Position = UDim2.new(0, 0, 1, -38)

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
    menuBtn.Size = UDim2.new(0, 100, 0, 40)
    menuBtn.Position = UDim2.new(0.5, -50, 0, 10)
    menuBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    menuBtn.Text = "⚙️ MENU"
    menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    menuBtn.TextSize = 14
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
        notif("📦 Diminimize")
    end)

    menuBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        menuBtn.Visible = false
    end)

    closeBtn.MouseButton1Click:Connect(function()
        autoEnabled = false
        isRunning = false
        notif("👋 Script ditutup")
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
                    statusLabel.Text = "▶️ AKTIF - Menunggu jadwal\n⏰ " .. timeStr
                end
            else
                statusLabel.Text = "⏸️ TIDAK AKTIF\n⏰ " .. timeStr
            end
        end
    end
end)

-- Main Auto Logic
task.spawn(function()
    local lastCheck = ""
    
    while task.wait(1) do
        if autoEnabled and not isRunning then
            local now = os.date("%H:%M")
            
            for _, time in ipairs(jadwal) do
                if now == time and now ~= lastCheck then
                    lastCheck = now
                    isRunning = true
                    autoStartTime = tick()
                    
                    if homeCoord and tujuanCoord then
                        statusLabel.Text = "▶️ TP ke TUJUAN...\n⏰ " .. os.date("%H:%M:%S")
                        notif("🎄 TP ke Christmas Cave!")
                        
                        if tp(tujuanCoord.x, tujuanCoord.y, tujuanCoord.z) then
                            notif("✅ Sampai tujuan!")
                            
                            local endTime = tick() + waitTime
                            while tick() < endTime and autoEnabled do
                                local left = math.floor(endTime - tick())
                                statusLabel.Text = "⏸️ MENUNGGU\n⏰ Sisa: " .. fTime(left)
                                task.wait(1)
                            end
                            
                            if autoEnabled then
                                statusLabel.Text = "▶️ KEMBALI ke HOME...\n⏰ " .. os.date("%H:%M:%S")
                                notif("🏠 Kembali ke Home!")
                                
                                tp(homeCoord.x, homeCoord.y, homeCoord.z)
                                notif("✅ Sampai Home!")
                            end
                        else
                            notif("❌ Gagal TP")
                        end
                    end
                    
                    isRunning = false
                    autoStartTime = 0
                    task.wait(61)
                end
            end
        elseif not autoEnabled and isRunning then
            -- Jika auto dicancel saat masih running, load sisa waktu
            local elapsed = tick() - autoStartTime
            local remaining = waitTime - elapsed
            
            if remaining > 0 then
                statusLabel.Text = "⏸️ WAKTU BELUM SELESAI\n⏰ Sisa: " .. fTime(math.floor(remaining))
            end
        end
    end
end)

-- Initialize
loadConfig()
notif("🎄 Xmas Script Loaded!")
print("🎄 Christmas Cave Script Successfully Loaded!")
