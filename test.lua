
-- Christmas Cave Auto Teleport Script
-- Compact version with dropdown player selector

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
local autoStartTime = 0
local eventDuration = 30 * 60
local configLoaded = false
local selectedPlayer = nil
local dropdownOpen = false

-- Config
local CONFIG = "XmasConfig.json"

-- Load Config
local function loadConfig()
    local maxRetries = 3
    local retryDelay = 0.5
    
    for attempt = 1, maxRetries do
        local success, result = pcall(function()
            if readfile and isfile and isfile(CONFIG) then
                local rawData = readfile(CONFIG)
                if rawData and rawData ~= "" then
                    local data = HttpService:JSONDecode(rawData)
                    
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

-- Save Config
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

-- Get Players with formatted names
local function getPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local displayName = p.DisplayName
            local userName = p.Name
            local formattedName = displayName .. " (@" .. userName .. ")"
            table.insert(list, {display = formattedName, actualName = userName})
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
    task.wait(0.1)
    
    if homeCoord then
        homeInput.Text = string.format("%d,%d,%d", homeCoord.x, homeCoord.y, homeCoord.z)
    end
    
    if tujuanCoord then
        tujuanInput.Text = string.format("%d,%d,%d", tujuanCoord.x, tujuanCoord.y, tujuanCoord.z)
    end
    
    waitInputMin.Text = tostring(math.floor(waitTime/60))
    waitInputSec.Text = tostring(waitTime%60)
    waitLabel.Text = "⏱️ " .. fTime(waitTime)
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

    -- Main Frame (Compact Size)
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = GUI

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 28)
    titleBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = mainFrame

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 8)
    tCorner.Parent = titleBar

    local tFix = Instance.new("Frame")
    tFix.Size = UDim2.new(1, 0, 0, 8)
    tFix.Position = UDim2.new(0, 0, 1, -8)
    tFix.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    tFix.BorderSizePixel = 0
    tFix.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -55, 1, 0)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎄 XMAS AUTO"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 12
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "MinimizeBtn"
    minBtn.Size = UDim2.new(0, 22, 0, 20)
    minBtn.Position = UDim2.new(1, -50, 0, 4)
    minBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    minBtn.TextSize = 14
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Parent = titleBar

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 4)
    mCorner.Parent = minBtn

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 22, 0, 20)
    closeBtn.Position = UDim2.new(1, -25, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 4)
    cCorner.Parent = closeBtn

    -- Content Container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 1, -36)
    content.Position = UDim2.new(0, 8, 0, 32)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    local yPos = 0

    -- Status Label
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, 0, 0, 32)
    status.Position = UDim2.new(0, 0, 0, yPos)
    status.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    status.Text = "⏸️ INACTIVE | ⏰ 00:00:00"
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.TextSize = 10
    status.Font = Enum.Font.GothamBold
    status.Parent = content

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 5)
    sCorner.Parent = status

    yPos = yPos + 36

    -- Helper function to create buttons
    local function createBtn(text, callback, color, size, parent, pos)
        local b = Instance.new("TextButton")
        b.Size = size or UDim2.new(1, 0, 0, 26)
        b.Position = pos or UDim2.new(0, 0, 0, yPos)
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 9
        b.Font = Enum.Font.GothamSemibold
        b.Parent = parent
        
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 4)
        bc.Parent = b
        
        b.MouseButton1Click:Connect(callback)
        return b
    end

    -- Copy Button
    local copyBtn = createBtn("📋 COPY POSITION", function()
        copiedCoord = getPos()
        if copiedCoord then
            notif("✅ Position copied!")
            pcall(function()
                if setclipboard then
                    setclipboard(string.format("%d,%d,%d", copiedCoord.x, copiedCoord.y, copiedCoord.z))
                end
            end)
        else
            notif("❌ Failed to copy")
        end
    end, Color3.fromRGB(70, 150, 230), nil, content)
    copyBtn.Position = UDim2.new(0, 0, 0, yPos)

    yPos = yPos + 30

    -- Home Section
    local testHomeBtn = createBtn("🏠", function()
        if homeCoord then
            if tp(homeCoord.x, homeCoord.y, homeCoord.z) then
                notif("✅ TP to Home!")
            else
                notif("❌ Failed")
            end
        else
            notif("❌ Set Home first!")
        end
    end, Color3.fromRGB(100, 150, 200), UDim2.new(0.18, 0, 0, 26), content, UDim2.new(0, 0, 0, yPos))

    local homeInput = Instance.new("TextBox")
    homeInput.Size = UDim2.new(0.80, 0, 0, 26)
    homeInput.Position = UDim2.new(0.20, 0, 0, yPos)
    homeInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    homeInput.PlaceholderText = "Home (x,y,z)"
    homeInput.Text = ""
    homeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    homeInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    homeInput.TextSize = 8
    homeInput.Font = Enum.Font.Gotham
    homeInput.ClearTextOnFocus = false
    homeInput.Parent = content

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0, 4)
    hCorner.Parent = homeInput

    homeInput.FocusLost:Connect(function()
        local coords = parseCoords(homeInput.Text)
        if coords then
            homeCoord = coords
            notif("✅ Home set!")
            saveConfig()
        elseif homeInput.Text ~= "" then
            notif("❌ Invalid! Use: x,y,z")
            homeInput.Text = homeCoord and string.format("%d,%d,%d", homeCoord.x, homeCoord.y, homeCoord.z) or ""
        end
    end)

    yPos = yPos + 30

    -- Destination Section
    local testDestBtn = createBtn("🎯", function()
        if tujuanCoord then
            if tp(tujuanCoord.x, tujuanCoord.y, tujuanCoord.z) then
                notif("✅ TP to Dest!")
            else
                notif("❌ Failed")
            end
        else
            notif("❌ Set Dest first!")
        end
    end, Color3.fromRGB(200, 120, 80), UDim2.new(0.18, 0, 0, 26), content, UDim2.new(0, 0, 0, yPos))

    local tujuanInput = Instance.new("TextBox")
    tujuanInput.Size = UDim2.new(0.80, 0, 0, 26)
    tujuanInput.Position = UDim2.new(0.20, 0, 0, yPos)
    tujuanInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    tujuanInput.PlaceholderText = "Destination (x,y,z)"
    tujuanInput.Text = ""
    tujuanInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    tujuanInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    tujuanInput.TextSize = 8
    tujuanInput.Font = Enum.Font.Gotham
    tujuanInput.ClearTextOnFocus = false
    tujuanInput.Parent = content

    local tCorner2 = Instance.new("UICorner")
    tCorner2.CornerRadius = UDim.new(0, 4)
    tCorner2.Parent = tujuanInput

    tujuanInput.FocusLost:Connect(function()
        local coords = parseCoords(tujuanInput.Text)
        if coords then
            tujuanCoord = coords
            notif("✅ Dest set!")
            saveConfig()
        elseif tujuanInput.Text ~= "" then
            notif("❌ Invalid! Use: x,y,z")
            tujuanInput.Text = tujuanCoord and string.format("%d,%d,%d", tujuanCoord.x, tujuanCoord.y, tujuanCoord.z) or ""
        end
    end)

    yPos = yPos + 34

    -- TP to Player Section
    -- Dropdown Button
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0.60, 0, 0, 26)
    dropdownBtn.Position = UDim2.new(0, 0, 0, yPos)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    dropdownBtn.Text = "👥 Select Player ▼"
    dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownBtn.TextSize = 8
    dropdownBtn.Font = Enum.Font.GothamSemibold
    dropdownBtn.Parent = content

    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(0, 4)
    dCorner.Parent = dropdownBtn

    -- Refresh Button
    local refreshBtn = createBtn("🔄", function()
        notif("🔄 Refreshing...")
    end, Color3.fromRGB(150, 100, 220), UDim2.new(0.18, 0, 0, 26), content, UDim2.new(0.62, 0, 0, yPos))

    -- Target Indicator
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(0.18, 0, 0, 26)
    targetLabel.Position = UDim2.new(0.82, 0, 0, yPos)
    targetLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    targetLabel.Text = "🎯"
    targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetLabel.TextSize = 14
    targetLabel.Font = Enum.Font.GothamBold
    targetLabel.Parent = content

    local tLabelCorner = Instance.new("UICorner")
    tLabelCorner.CornerRadius = UDim.new(0, 4)
    tLabelCorner.Parent = targetLabel

    yPos = yPos + 30

    -- Dropdown List Container
    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.Size = UDim2.new(0.60, 0, 0, 0)
    dropdownList.Position = UDim2.new(0, 0, 0, yPos)
    dropdownList.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    dropdownList.BorderSizePixel = 0
    dropdownList.ScrollBarThickness = 3
    dropdownList.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 50)
    dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
    dropdownList.Visible = false
    dropdownList.ClipsDescendants = true
    dropdownList.Parent = content

    local dlCorner = Instance.new("UICorner")
    dlCorner.CornerRadius = UDim.new(0, 4)
    dlCorner.Parent = dropdownList

    -- TP to Player Button
    local tpToPlayerBtn = createBtn("▶️ TELEPORT", function()
        if selectedPlayer then
            if tpPlayer(selectedPlayer.actualName) then
                notif("✅ TP to " .. selectedPlayer.display)
            else
                notif("❌ Player not found!")
            end
        else
            notif("❌ Select player first!")
        end
    end, Color3.fromRGB(70, 180, 100), UDim2.new(1, 0, 0, 28), content, UDim2.new(0, 0, 0, yPos))
    tpToPlayerBtn.Visible = true

    local tpBtnYPos = yPos
    yPos = yPos + 32

    -- Update Player Dropdown
    local function updateDropdown()
        for _, c in ipairs(dropdownList:GetChildren()) do
            if c:IsA("TextButton") then 
                c:Destroy() 
            end
        end

        local players = getPlayers()
        local py = 2

        if #players == 0 then
            dropdownBtn.Text = "👥 No Players"
        else
            dropdownBtn.Text = selectedPlayer and "👥 " .. selectedPlayer.display or "👥 Select Player ▼"
            
            for _, playerData in ipairs(players) do
                local pb = Instance.new("TextButton")
                pb.Size = UDim2.new(1, -4, 0, 24)
                pb.Position = UDim2.new(0, 2, 0, py)
                pb.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                pb.Text = playerData.display
                pb.TextColor3 = Color3.fromRGB(255, 255, 255)
                pb.TextSize = 7
                pb.Font = Enum.Font.Gotham
                pb.TextXAlignment = Enum.TextXAlignment.Left
                pb.Parent = dropdownList

                local pbPad = Instance.new("UIPadding")
                pbPad.PaddingLeft = UDim.new(0, 4)
                pbPad.Parent = pb

                local pbCorner = Instance.new("UICorner")
                pbCorner.CornerRadius = UDim.new(0, 3)
                pbCorner.Parent = pb

                pb.MouseButton1Click:Connect(function()
                    selectedPlayer = playerData
                    dropdownBtn.Text = "👥 " .. playerData.display
                    dropdownList.Visible = false
                    dropdownOpen = false
                    tpToPlayerBtn.Visible = true
                    notif("✅ Selected: " .. playerData.display)
                end)

                py = py + 26
            end
        end

        dropdownList.CanvasSize = UDim2.new(0, 0, 0, py + 2)
    end

    -- Dropdown Toggle
    dropdownBtn.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        if dropdownOpen then
            updateDropdown()
            dropdownList.Size = UDim2.new(0.60, 0, 0, math.min(120, dropdownList.CanvasSize.Y.Offset))
            dropdownList.Visible = true
            tpToPlayerBtn.Visible = false
        else
            dropdownList.Visible = false
            tpToPlayerBtn.Visible = true
        end
    end)

    -- Refresh Button Action
    refreshBtn.MouseButton1Click:Connect(function()
        updateDropdown()
        notif("🔄 List refreshed!")
    end)

    -- Wait Time Label
    local waitLabel = Instance.new("TextLabel")
    waitLabel.Size = UDim2.new(1, 0, 0, 16)
    waitLabel.Position = UDim2.new(0, 0, 0, yPos)
    waitLabel.BackgroundTransparency = 1
    waitLabel.Text = "⏱️ " .. fTime(waitTime)
    waitLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitLabel.TextSize = 9
    waitLabel.Font = Enum.Font.GothamBold
    waitLabel.TextXAlignment = Enum.TextXAlignment.Left
    waitLabel.Parent = content

    yPos = yPos + 18

    -- Wait Time Inputs
    local waitInputMin = Instance.new("TextBox")
    waitInputMin.Size = UDim2.new(0.28, 0, 0, 26)
    waitInputMin.Position = UDim2.new(0, 0, 0, yPos)
    waitInputMin.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    waitInputMin.PlaceholderText = "Min"
    waitInputMin.Text = tostring(math.floor(waitTime/60))
    waitInputMin.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitInputMin.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    waitInputMin.TextSize = 9
    waitInputMin.Font = Enum.Font.Gotham
    waitInputMin.ClearTextOnFocus = false
    waitInputMin.Parent = content

    local wCornerMin = Instance.new("UICorner")
    wCornerMin.CornerRadius = UDim.new(0, 4)
    wCornerMin.Parent = waitInputMin

    local waitInputSec = Instance.new("TextBox")
    waitInputSec.Size = UDim2.new(0.28, 0, 0, 26)
    waitInputSec.Position = UDim2.new(0.30, 0, 0, yPos)
    waitInputSec.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    waitInputSec.PlaceholderText = "Sec"
    waitInputSec.Text = tostring(waitTime%60)
    waitInputSec.TextColor3 = Color3.fromRGB(255, 255, 255)
    waitInputSec.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    waitInputSec.TextSize = 9
    waitInputSec.Font = Enum.Font.Gotham
    waitInputSec.ClearTextOnFocus = false
    waitInputSec.Parent = content

    local wCornerSec = Instance.new("UICorner")
    wCornerSec.CornerRadius = UDim.new(0, 4)
    wCornerSec.Parent = waitInputSec

    local setWaitBtn = createBtn("✅ SET", function()
        local m = tonumber(waitInputMin.Text) or 0
        local s = tonumber(waitInputSec.Text) or 0
        
        if m >= 0 and s >= 0 and s < 60 and (m > 0 or s > 0) then
            waitTime = (m * 60) + s
            waitLabel.Text = "⏱️ " .. fTime(waitTime)
            notif("✅ Set: " .. m .. "m " .. s .. "s")
            saveConfig()
        else
            notif("❌ Invalid!")
        end
    end, Color3.fromRGB(70, 180, 100), UDim2.new(0.40, 0, 0, 26), content, UDim2.new(0.60, 0, 0, yPos))

    yPos = yPos + 34

    -- Info Label
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 50)
    info.Position = UDim2.new(0, 0, 0, yPos)
    info.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    info.TextColor3 = Color3.fromRGB(180, 180, 180)
    info.TextSize = 7
    info.Font = Enum.Font.Gotham
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Parent = content

    ```lua
    local iCorner = Instance.new("UICorner")
    iCorner.CornerRadius = UDim.new(0, 4)
    iCorner.Parent = info

    local iPad = Instance.new("UIPadding")
    iPad.PaddingLeft = UDim.new(0, 5)
    iPad.PaddingTop = UDim.new(0, 5)
    iPad.Parent = info

    info.Text = "📅 11:00, 13:00, 15:00, 17:00, 19:00\n21:00, 23:00, 01:00, 03:00, 05:00, 07:00, 09:00\n⏱️ 30min | 🔄 Home→Dest→Home"

    yPos = yPos + 54

    -- Start/Stop Button
    local startBtn = createBtn("▶️ START AUTO", function()
        if not homeCoord or not tujuanCoord then
            notif("❌ Set Home & Dest first!")
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
    end, Color3.fromRGB(70, 180, 100), UDim2.new(1, 0, 0, 32), content)
    startBtn.Position = UDim2.new(0, 0, 0, yPos)

    -- Menu Button (for minimize)
    local menuBtn = Instance.new("TextButton")
    menuBtn.Name = "MenuBtn"
    menuBtn.Size = UDim2.new(0, 70, 0, 30)
    menuBtn.Position = UDim2.new(0.5, -35, 0, 10)
    menuBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    menuBtn.Text = "⚙️ MENU"
    menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    menuBtn.TextSize = 11
    menuBtn.Font = Enum.Font.GothamBold
    menuBtn.Visible = false
    menuBtn.Parent = GUI

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 6)
    menuCorner.Parent = menuBtn

    -- Button Events
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
        notif("👋 Closed")
        task.wait(0.5)
        pcall(function() GUI:Destroy() end)
    end)

    -- Close dropdown when clicking outside
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dropdownOpen then
                local mousePos = UserInputService:GetMouseLocation()
                local dropdownPos = dropdownBtn.AbsolutePosition
                local dropdownSize = dropdownBtn.AbsoluteSize
                local listPos = dropdownList.AbsolutePosition
                local listSize = dropdownList.AbsoluteSize
                
                local inDropdownBtn = mousePos.X >= dropdownPos.X and mousePos.X <= dropdownPos.X + dropdownSize.X and
                                      mousePos.Y >= dropdownPos.Y and mousePos.Y <= dropdownPos.Y + dropdownSize.Y
                
                local inDropdownList = mousePos.X >= listPos.X and mousePos.X <= listPos.X + listSize.X and
                                       mousePos.Y >= listPos.Y and mousePos.Y <= listPos.Y + listSize.Y
                
                if not inDropdownBtn and not inDropdownList then
                    dropdownList.Visible = false
                    dropdownOpen = false
                    tpToPlayerBtn.Visible = true
                end
            end
        end
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
        task.wait(0.2)
        if loadConfig() then
            updateUIWithConfig(homeInput, tujuanInput, waitInputMin, waitInputSec, waitLabel)
            if configLoaded then
                notif("✅ Config loaded!")
            end
        end
    end)

    -- Initialize dropdown
    updateDropdown()

    return status, startBtn
end

-- Auto Teleport Logic
local statusLabel, startBtn = createGUI()

-- Update Time
task.spawn(function()
    while task.wait(1) do
        if statusLabel then
            local timeStr = os.date("%H:%M:%S")
            if autoEnabled then
                if isRunning then
                    -- Status updated by main logic
                else
                    statusLabel.Text = "▶️ ACTIVE | ⏰ " .. timeStr
                end
            else
                statusLabel.Text = "⏸️ INACTIVE | ⏰ " .. timeStr
            end
        end
    end
end)

-- Main Auto Logic
task.spawn(function()
    while task.wait(1) do
        if autoEnabled and not isRunning then
            local inEvent, remainingTime = isInEventWindow()
            
            if inEvent and remainingTime > 0 then
                isRunning = true
                autoStartTime = tick()
                
                if homeCoord and tujuanCoord then
                    statusLabel.Text = "▶️ TP DEST | ⏰ " .. os.date("%H:%M:%S")
                    notif("🎄 TP to Cave! " .. fTime(math.floor(remainingTime)) .. " left")
                    
                    if tp(tujuanCoord.x, tujuanCoord.y, tujuanCoord.z) then
                        notif("✅ Arrived!")
                        
                        local actualWaitTime = math.min(waitTime, remainingTime)
                        local endTime = tick() + actualWaitTime
                        
                        while tick() < endTime and autoEnabled do
                            local left = math.floor(endTime - tick())
                            statusLabel.Text = "⏳ WAIT | ⏰ " .. fTime(left)
                            task.wait(1)
                        end
                        
                        if autoEnabled then
                            statusLabel.Text = "▶️ HOME | ⏰ " .. os.date("%H:%M:%S")
                            notif("🏠 Returning!")
                            
                            tp(homeCoord.x, homeCoord.y, homeCoord.z)
                            notif("✅ At Home!")
                        end
                    else
                        notif("❌ TP Failed")
                    end
                end
                
                isRunning = false
                autoStartTime = 0
                task.wait(5)
            end
        elseif not autoEnabled and isRunning then
            local elapsed = tick() - autoStartTime
            local remaining = waitTime - elapsed
            
            if remaining > 0 then
                statusLabel.Text = "⏸️ WAIT | ⏰ " .. fTime(math.floor(remaining))
            end
        end
    end
end)

-- Initialize
notif("🎄 Xmas Script Loaded!")
print("🎄 Christmas Cave Script Successfully Loaded!")
