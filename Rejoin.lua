-- Fish It Auto Rejoin Utility (Fixed Version)
-- Compatible with Delta Executor
-- Bypass Error Code 773

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Konfigurasi
local REJOIN_INTERVAL = 3 -- 3 detik
local AUTO_EXECUTE = true

-- Fungsi untuk rejoin dengan metode alternatif (SIMPLIFIED & FASTER)
local function rejoinGame()
    print("[Fish It Utility] ⏰ Starting rejoin process...")
    
    local success, err = pcall(function()
        -- Metode Simple: Langsung teleport ke game tanpa server list
        print("[Fish It Utility] 🔄 Teleporting to new server...")
        
        -- Gunakan TeleportService langsung
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
    
    if not success then
        warn("[Fish It Utility] ❌ Rejoin failed:", err)
        -- Backup method: Kick and auto-reconnect
        print("[Fish It Utility] 🔁 Using backup method...")
        wait(1)
        game:GetService("TeleportService"):Teleport(game.PlaceId)
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
    print("[Fish It Utility] Next rejoin in " .. REJOIN_INTERVAL .. " seconds...")
    print("=================================")
    
    autoExecuteScript()
    
    -- Countdown timer untuk debug
    spawn(function()
        local countdown = REJOIN_INTERVAL
        while true do
            wait(1)
            countdown = countdown - 1
            
            if countdown <= 0 then
                print("[Fish It Utility] 🚀 REJOINING NOW!")
                createNotification("🔄 Server Hopping", "Mencari server baru...", 3)
                wait(0.5)
                rejoinGame()
                countdown = REJOIN_INTERVAL -- Reset countdown
            else
                -- Print countdown setiap detik untuk debug
                print("[Fish It Utility] ⏳ Rejoin in " .. countdown .. " seconds...")
            end
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
