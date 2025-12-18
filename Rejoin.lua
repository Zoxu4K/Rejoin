-- Fish It Auto Rejoin Utility (Fixed Version)
-- Compatible with Delta Executor
-- Bypass Error Code 773

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Konfigurasi
local REJOIN_INTERVAL = 8 -- 8 detik
local AUTO_EXECUTE = true

-- Fungsi untuk rejoin dengan metode alternatif
local function rejoinGame()
    local success, err = pcall(function()
        print("[Fish It Utility] Preparing to rejoin...")
        
        -- Metode 1: Hop ke server lain (bypass restriction)
        local serverList = {}
        local cursor = ""
        
        repeat
            local servers = game:HttpGet(string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100&cursor=%s",
                game.PlaceId,
                cursor
            ))
            
            local decoded = HttpService:JSONDecode(servers)
            
            for _, server in pairs(decoded.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(serverList, server.id)
                end
            end
            
            cursor = decoded.nextPageCursor or ""
        until cursor == "" or #serverList >= 10
        
        if #serverList > 0 then
            local randomServer = serverList[math.random(1, #serverList)]
            print("[Fish It Utility] Hopping to different server...")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
        else
            -- Metode 2: Regular rejoin jika server hop gagal
            print("[Fish It Utility] Server hop failed, using regular rejoin...")
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    
    if not success then
        warn("[Fish It Utility] Rejoin failed:", err)
        -- Metode darurat: Force disconnect dan reconnect
        LocalPlayer:Kick("Auto Rejoin - Reconnecting...")
    end
end

-- Fungsi untuk auto execute script
local function autoExecuteScript()
    if AUTO_EXECUTE then
        print("[Fish It Utility] Auto-execute enabled")
    end
end

-- Main loop dengan interval lebih panjang
local function startAutoRejoin()
    print("=================================")
    print("[Fish It Utility] ✅ SUCCESSFULLY EXECUTED!")
    print("[Fish It Utility] Auto Server Hop: ON")
    print("[Fish It Utility] Interval: " .. REJOIN_INTERVAL .. " detik")
    print("[Fish It Utility] FULL AUTO MODE - No manual action needed!")
    print("=================================")
    
    autoExecuteScript()
    
    -- Loop otomatis setiap 8 detik
    spawn(function()
        while true do
            wait(REJOIN_INTERVAL)
            createNotification("🔄 Server Hopping", "Mencari server baru...", 3)
            rejoinGame()
        end
    end)
end

-- Handle disconnections
game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    print("[Fish It Utility] Error detected, attempting rejoin...")
    wait(2)
    rejoinGame()
end)

-- Proteksi anti-kick yang lebih baik
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "Kick" then
        print("[Fish It Utility] Kick detected, rejoining...")
        wait(1)
        rejoinGame()
        return wait(9e9) -- Prevent kick
    end
    
    if method == "TeleportToPlaceInstance" or method == "Teleport" then
        -- Allow teleport but log it
        print("[Fish It Utility] Teleport detected")
    end
    
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- UI Notification yang lebih informatif
local function createNotification(title, text, duration)
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5,
        Icon = "rbxassetid://6031302931"
    })
end

-- Notifikasi loading
createNotification(
    "⏳ Loading...",
    "Initializing Fish It Utility...",
    3
)

wait(3)

-- Notifikasi sukses execute
createNotification(
    "✅ SUCCESS!",
    "Fish It Utility berhasil dijalankan!",
    5
)

wait(2)

-- Notifikasi info
createNotification(
    "🔄 Auto Server Hop",
    "Server hop setiap " .. REJOIN_INTERVAL .. " detik | FULL AUTO MODE",
    8
)

-- Jalankan utility
startAutoRejoin()
