-- Fish It FULL AUTO EXECUTE & REJOIN
-- Taruh file ini di folder autoexec Delta Executor
-- Nama file: fishit_auto.lua

print("[AUTO-EXEC] Waiting for game to load...")
wait(8) -- Tunggu game load sempurna

-- Function untuk load script utama
local function loadMainScript()
    local success, err = pcall(function()
        print("[AUTO-EXEC] Loading Fish It Utility from GitHub...")
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Zoxu4K/Rejoin/refs/heads/main/Rejoin.lua"))()
        print("[AUTO-EXEC] ✅ Script loaded successfully!")
    end)
    
    if not success then
        warn("[AUTO-EXEC] Failed to load script:", err)
        wait(5)
        loadMainScript() -- Retry kalau gagal
    end
end

-- Notifikasi startup
game.StarterGui:SetCore("SendNotification", {
    Title = "🚀 Auto-Execute",
    Text = "Fish It Utility sedang loading...",
    Duration = 5
})

-- Load script
loadMainScript()

print("[AUTO-EXEC] ========================================")
print("[AUTO-EXEC] Fish It Full Auto System ACTIVE!")
print("[AUTO-EXEC] Script akan auto-execute setiap rejoin")
print("[AUTO-EXEC] Tidak perlu execute manual lagi!")
print("[AUTO-EXEC] ========================================")
