
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
    return string.format("%02d:%02d", math.floor(sec/60), sec%60)
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
    mainFrame.Size = UDim2.new(0, 380, 0, 460)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -230)
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

    -- Content Frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -45)
    content.Position = UDim2.new(0, 10, 0, 40)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    local yPos = 0

    -- Status Label
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, 0, 0, 40)
    status.Position = UDim2.new(0, 0, 0, yPos)
    status.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    status.Text = "⏸️ TIDAK AKTIF"
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.TextSize = 13
    status.Font = Enum.Font.GothamBold
    status.Parent = content

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 6)
    sCorner.Parent = status

    yPos = yPos + 50

    -- Helper function to create buttons
    local function createBtn(text, callback, color, size)
        local b = Instance.new("TextButton")
        b.Size = size or UDim2.new(1, 0, 0, 35)
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 12
        b.Font = Enum.Font.GothamSemibold
        b.Parent = content
        
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = b
        
        b.MouseButton1Click:Connect(callback)
        return b
    end

    -- Copy Koordinat Button
    local copyBtn = createBtn("📋 COPY KOORDINAT SEKARANG", function()
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
    end, Color3.fromRGB(70, 150, 230))
    copyBtn.Position = UDim2.new(0, 0, 0, yPos)

    yPos = yPos + 45

    -- Set Home Button
    local setHomeBtn = createBtn("🏠 SET HOME", function()
        if copiedCoord then
            homeCoord = copiedCoord
            notif("✅ Home di-set!")
            saveConfig()
        else
            notif("❌ Copy koordinat dulu")
        end
    end, Color3.fromRGB(70, 180, 100), UDim2.new(0.48, 0, 0, 35))
    setHomeBtn.Position = UDim2.new(0, 0, 0, yPos)

    -- Set Tujuan Button
    local setTujuanBtn = createBtn("🎯 SET TUJUAN", function()
        if copiedCoord then
            tujuanCoord = copiedCoord
            notif("✅ Tujuan di-set!")
            saveConfig()
        else
            notif("❌ Copy koordinat dulu")
        end
    end, Color3.fromRGB(220, 100, 60), UDim2.new(0.48, 0, 0, 35))
    setTujuanBtn.Position = UDim2.new(0.52, 0, 0, yPos)

    yPos = yPos + 45

    -- Info Label
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 90)
    info.Position = UDim2.new(0, 0, 0, yPos)
    info.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    info.TextColor3 = Color3.fromRGB(200, 200, 200)
    info.TextSize = 11
    info.Font = Enum.Font.Gotham
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Parent = content

    local iCorner = Instance.new("UICorner")
    iCorner.CornerRadius = UDim.new(0, 6)
    iCorner.Parent = info

    local iPad = Instance.new("UIPadding")
    iPad.PaddingLeft = UDim.new(0, 8)
    iPad.PaddingTop = UDim.new(0, 8)
    iPad.Parent = info

    info.Text = "⏰ Jadwal: 11:00, 13:00, 15:00, 17:00\n19:00, 21:00, 23:00, 01:00, 03:00\n05:00, 07:00, 09:00\n\n⏱️ Durasi: 30 menit\n🔄 Home → Tujuan → Home"

    yPos = yPos + 100

    -- Wait Time Label
    local waitLabel = Instance.new("TextLabel")
    waitLabel.Size = UDim2.new(1, 0, 0, 25)
    waitLabel.Position = UDim2.new(0, 0, 0, yPos)
    waitLabel.BackgroundTransparency = 1
    waitLabel.Text = "⏱️ Waktu Tunggu: " .. fTime(waitTime)
    waitLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitLabel.TextSize = 12
    waitLabel.Font = Enum.Font.GothamBold
    waitLabel.TextXAlignment = Enum.TextXAlignment.Left
    waitLabel.Parent = content

    yPos = yPos + 30

    -- Wait Time Input
    local waitInput = Instance.new("TextBox")
    waitInput.Size = UDim2.new(0.65, 0, 0, 35)
    waitInput.Position = UDim2.new(0, 0, 0, yPos)
    waitInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    waitInput.PlaceholderText = "Menit"
    waitInput.Text = tostring(math.floor(waitTime/60))
    waitInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    waitInput.TextSize = 12
    waitInput.Font = Enum.Font.Gotham
    waitInput.ClearTextOnFocus = false
    waitInput.Parent = content

    local wCorner = Instance.new("UICorner")
    wCorner.CornerRadius = UDim.new(0, 6)
    wCorner.Parent = waitInput

    -- Set Wait Button
    local setWaitBtn = createBtn("✅ SET", function()
        local m = tonumber(waitInput.Text)
        if m and m > 0 then
            waitTime = m * 60
            waitLabel.Text = "⏱️ Waktu Tunggu: " .. fTime(waitTime)
            notif("✅ Diset: " .. m .. " menit")
            saveConfig()
        else
            notif("❌ Angka tidak valid")
        end
    end, Color3.fromRGB(70, 180, 100), UDim2.new(0.33, 0, 0, 35))
    setWaitBtn.Position = UDim2.new(0.67, 0, 0, yPos)

    yPos = yPos + 45

    -- Start/Stop Button
    local startBtn = createBtn("▶️ START AUTO", function()
        if not homeCoord or not tujuanCoord then
            notif("❌ Set Home & Tujuan dulu!")
            return
        end

        autoEnabled = not autoEnabled
        
        if autoEnabled then
            startBtn.Text = "⏸️ STOP AUTO"
            startBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
            status.Text = "▶️ AKTIF - Menunggu jadwal..."
            notif("✅ Auto AKTIF!")
        else
            startBtn.Text = "▶️ START AUTO"
            startBtn.BackgroundColor3 = Color3.fromRGB(70, 180, 100)
            status.Text = "⏸️ TIDAK AKTIF"
            notif("⏸️ Auto BERHENTI")
        end
    end, Color3.fromRGB(70, 180, 100))
    startBtn.Position = UDim2.new(0, 0, 0, yPos)

    yPos = yPos + 45

    -- Player List Frame
    local playerFrame = Instance.new("ScrollingFrame")
    playerFrame.Size = UDim2.new(1, 0, 0, 80)
    playerFrame.Position = UDim2.new(0, 0, 0, yPos)
    playerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    playerFrame.BorderSizePixel = 0
    playerFrame.ScrollBarThickness = 4
    playerFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 50)
    playerFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerFrame.Parent = content

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
            none.Text = "Tidak ada player"
            none.TextColor3 = Color3.fromRGB(150, 150, 150)
            none.TextSize = 11
            none.Font = Enum.Font.Gotham
            none.Parent = playerFrame
        else
            for _, name in ipairs(players) do
                local pb = Instance.new("TextButton")
                pb.Size = UDim2.new(1, -10, 0, 28)
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

                py = py + 33
            end
        end

        playerFrame.CanvasSize = UDim2.new(0, 0, 0, py + 5)
    end

    yPos = yPos + 90

    -- Refresh Player Button
    local refreshBtn = createBtn("🔄 REFRESH PLAYER", function()
        updatePlayers()
        notif("✅ List di-refresh")
    end, Color3.fromRGB(150, 100, 220))
    refreshBtn.Position = UDim2.new(0, 0, 0, yPos)

    updatePlayers()

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

    return status
end

-- Auto Teleport Logic
local statusLabel = createGUI()

task.spawn(function()
    local lastCheck = ""
    
    while task.wait(1) do
        if autoEnabled and not isRunning then
            local now = os.date("%H:%M")
            
            for _, time in ipairs(jadwal) do
                if now == time and now ~= lastCheck then
                    lastCheck = now
                    isRunning = true
                    
                    if homeCoord and tujuanCoord then
                        statusLabel.Text = "▶️ TP ke TUJUAN..."
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
                                statusLabel.Text = "▶️ KEMBALI ke HOME..."
                                notif("🏠 Kembali ke Home!")
                                
                                tp(homeCoord.x, homeCoord.y, homeCoord.z)
                                notif("✅ Sampai Home!")
                            end
                        else
                            notif("❌ Gagal TP")
                        end
                    end
                    
                    isRunning = false
                    if autoEnabled then
                        statusLabel.Text = "▶️ AKTIF - Menunggu jadwal..."
                    end
                    
                    task.wait(61)
                end
            end
        end
        
        if autoEnabled and not isRunning then
            statusLabel.Text = "▶️ AKTIF\n⏰ " .. os.date("%H:%M")
        end
    end
end)

-- Initialize
loadConfig()
notif("🎄 Xmas Script Loaded!")
print("🎄 Christmas Cave Script Successfully Loaded!")
