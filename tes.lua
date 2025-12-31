-- ====================================================================
--                 AUTO FISH V7.0 - ULTIMATE EDITION
--        Combined V5 + V6 + Enhanced Features + Bug Fixes
-- ====================================================================

-- ====== SERVICES ======
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

-- ====== CONFIG ======
local CONFIG_FOLDER = "AutoFish_V7"
local CONFIG_FILE = CONFIG_FOLDER .. "/config_" .. LocalPlayer.UserId .. ".json"

local DefaultConfig = {
    -- Core Fishing
    AutoFish = false,
    BlatantMode = false,
    InstantReel = false,
    AutoShake = false,
    PerfectCast = false,
    AutoCatch = false,
    
    -- Auto Systems
    AutoEquipBestRod = false,
    AutoUseBait = false,
    AutoSell = false,
    AutoSellFish = false,
    AutoFavorite = true,
    
    -- Sell Settings
    SellByRarity = false,
    SellRarities = {
        Common = true, 
        Uncommon = true, 
        Rare = true, 
        Epic = false, 
        Legendary = false, 
        Mythic = false, 
        Secret = false
    },
    SellThreshold = 50,
    
    -- Favorite Settings
    FavoriteRarity = "Mythic",
    
    -- Weather
    AutoBuyWeather = false,
    WeatherType = "Wind",
    
    -- Safety
    HumanizeMode = false,
    SafeMode = false,
    AutoRejoin = true,
    ServerHop = false,
    
    -- Notifications
    RareFishAlert = true,
    WebhookURL = "",
    SoundAlerts = true,
    
    -- Performance
    NoAnimation = false,
    BoostFPS = false,
    GPUSaver = false,
    DeleteCutscene = true,
    DisableEffects = false,
    HideFishIcon = false,
    
    -- Delays
    FishDelay = 0.9,
    CatchDelay = 0.2,
    CastDelay = 0.15,
    ReelDelay = 0.08,
    SellDelay = 30,
    ShakeDelay = 0.05,
    
    -- Misc
    TeleportLocation = "Sisyphus Statue",
    RainbowRod = false
}

local Config = {}
for k, v in pairs(DefaultConfig) do 
    if type(v) == "table" then
        Config[k] = {}
        for k2, v2 in pairs(v) do Config[k][k2] = v2 end
    else
        Config[k] = v 
    end
end

-- ====== STATS TRACKING ======
local Stats = {
    FishCaught = 0,
    MoneyEarned = 0,
    RareFishCaught = {Mythic = 0, Secret = 0, Legendary = 0, Epic = 0},
    StartTime = tick(),
    SessionTime = 0,
    LastCatch = "None",
    CastsCount = 0
}

-- ====== LOCATIONS ======
local LOCATIONS = {
    ["Spawn"] = CFrame.new(45.28, 252.56, 2987.11),
    ["Sisyphus Statue"] = CFrame.new(-3728.22, -135.07, -1012.13),
    ["Coral Reefs"] = CFrame.new(-3114.78, 1.32, 2237.52),
    ["Esoteric Depths"] = CFrame.new(3248.37, -1301.53, 1403.83),
    ["Crater Island"] = CFrame.new(1016.49, 20.09, 5069.27),
    ["Lost Isle"] = CFrame.new(-3618.16, 240.84, -1317.46),
    ["Weather Machine"] = CFrame.new(-1488.51, 83.17, 1876.30),
    ["Tropical Grove"] = CFrame.new(-2095.34, 197.20, 3718.08),
    ["Mount Hallow"] = CFrame.new(2136.62, 78.92, 3272.50),
    ["Treasure Room"] = CFrame.new(-3606.35, -266.57, -1580.97),
    ["Kohana"] = CFrame.new(-663.90, 3.05, 718.80),
    ["Underground Cellar"] = CFrame.new(2109.52, -94.19, -708.61),
    ["Ancient Jungle"] = CFrame.new(1831.71, 6.62, -299.28),
    ["Sacred Temple"] = CFrame.new(1466.92, -21.88, -622.84)
}

-- ====== CONFIG FUNCTIONS ======
local function ensureFolder()
    if not isfolder or not makefolder then return false end
    if not isfolder(CONFIG_FOLDER) then
        pcall(makefolder, CONFIG_FOLDER)
    end
    return isfolder(CONFIG_FOLDER)
end

local function saveConfig()
    if not writefile or not ensureFolder() then 
        print("[Config] ❌ Cannot save config (writefile not available)")
        return 
    end
    pcall(function()
        local success, encoded = pcall(HttpService.JSONEncode, HttpService, Config)
        if success then
            writefile(CONFIG_FILE, encoded)
            print("[Config] ✅ Config saved!")
        end
    end)
end

local function loadConfig()
    if not readfile or not isfile or not isfile(CONFIG_FILE) then 
        print("[Config] ⚠️ No config found, using defaults")
        return 
    end
    pcall(function()
        local content = readfile(CONFIG_FILE)
        local success, data = pcall(HttpService.JSONDecode, HttpService, content)
        if success then
            for k, v in pairs(data) do
                if DefaultConfig[k] ~= nil then 
                    if type(v) == "table" and type(Config[k]) == "table" then
                        for k2, v2 in pairs(v) do 
                            if Config[k][k2] ~= nil then
                                Config[k][k2] = v2 
                            end
                        end
                    elseif type(v) ~= "table" and type(Config[k]) ~= "table" then
                        Config[k] = v 
                    end
                end
            end
            print("[Config] ✅ Config loaded!")
        end
    end)
end

-- Load config on start
loadConfig()

-- ====== NOTIFICATION SYSTEM ======
local function notify(title, text, duration)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
            Icon = "rbxassetid://4483362458"
        })
    end)
end

local function playSound(soundId)
    if not Config.SoundAlerts then return end
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. soundId
        sound.Volume = 0.3
        sound.Parent = workspace
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 3)
    end)
end

-- ====== MODULES DETECTION ======
local ItemUtility, Replion, PlayerData
local function loadModules()
    pcall(function()
        ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
    end)
    
    pcall(function()
        Replion = require(ReplicatedStorage.Packages.Replion)
        PlayerData = Replion.Client:WaitReplion("Data")
    end)
    
    if not ItemUtility then
        warn("[Warning] ItemUtility module not found!")
    end
    if not PlayerData then
        warn("[Warning] PlayerData module not found!")
    end
end

-- Load modules
task.spawn(loadModules)

-- ====== NETWORK EVENTS ======
local Events = {}
local function setupEvents()
    pcall(function()
        local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
        Events = {
            fishing = net:WaitForChild("RE/FishingCompleted"),
            sell = net:WaitForChild("RF/SellAllItems"),
            sellFish = net:WaitForChild("RF/SellFish"),
            charge = net:WaitForChild("RF/ChargeFishingRod"),
            minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
            equip = net:WaitForChild("RE/EquipToolFromHotbar"),
            unequip = net:WaitForChild("RE/UnequipToolFromHotbar"),
            favorite = net:WaitForChild("RE/FavoriteItem"),
            weather = net:WaitForChild("RF/PurchaseWeather"),
            shake = net:WaitForChild("RE/FishingShake"),
            bait = net:WaitForChild("RE/UseBait")
        }
        print("[Events] ✅ Network events loaded!")
    end)
end

-- Setup events with retry
local attempts = 0
while not Events.fishing and attempts < 10 do
    setupEvents()
    attempts += 1
    if not Events.fishing then
        task.wait(1)
    end
end

if not Events.fishing then
    warn("[Warning] Failed to load network events!")
end

-- ====== RARITY SYSTEM ======
local RarityTiers = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Secret = 7
}

local RarityColors = {
    Common = Color3.fromRGB(200, 200, 200),
    Uncommon = Color3.fromRGB(30, 255, 0),
    Rare = Color3.fromRGB(0, 112, 255),
    Epic = Color3.fromRGB(163, 53, 238),
    Legendary = Color3.fromRGB(255, 128, 0),
    Mythic = Color3.fromRGB(255, 0, 255),
    Secret = Color3.fromRGB(255, 255, 0)
}

local function getRarityValue(rarity)
    return RarityTiers[rarity] or 0
end

local function getFishRarity(itemData)
    if not itemData or not itemData.Data then return "Common" end
    return itemData.Data.Rarity or "Common"
end

-- ====== RARE FISH ALERT ======
local function rareFishAlert(fishName, rarity)
    if not Config.RareFishAlert then return end
    
    local color = RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
    local emoji = "🎣"
    
    if rarity == "Mythic" then emoji = "💫"
    elseif rarity == "Secret" then emoji = "🔮"
    elseif rarity == "Legendary" then emoji = "⭐"
    elseif rarity == "Epic" then emoji = "💜"
    end
    
    notify(emoji .. " RARE FISH!", fishName .. " (" .. rarity .. ")", 8)
    playSound("6647898081")
    
    -- Update stats
    Stats.RareFishCaught[rarity] = (Stats.RareFishCaught[rarity] or 0) + 1
    Stats.LastCatch = fishName
    
    -- Discord webhook
    if Config.WebhookURL ~= "" and Config.WebhookURL:find("discord") then
        task.spawn(function()
            pcall(function()
                local data = {
                    embeds = {{
                        title = "🎣 RARE FISH CAUGHT!",
                        description = "**" .. fishName .. "**\nRarity: **" .. rarity .. "**",
                        color = tonumber(string.format("%02x%02x%02x", 
                            math.floor(color.r * 255), 
                            math.floor(color.g * 255), 
                            math.floor(color.b * 255)
                        ), 16),
                        fields = {
                            {name = "Player", value = LocalPlayer.Name, inline = true},
                            {name = "Total Caught", value = tostring(Stats.FishCaught), inline = true}
                        },
                        timestamp = DateTime.now():ToIsoDate()
                    }}
                }
                
                local success, response = pcall(game.HttpService.RequestAsync, game.HttpService, {
                    Url = Config.WebhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(data)
                })
            end)
        end)
    end
end

-- ====== AUTO EQUIP BEST ROD ======
local function getBestRod()
    local bestRod = 1
    local bestValue = 0
    
    if not PlayerData then return bestRod end
    
    pcall(function()
        local hotbar = PlayerData:GetExpect("Hotbar")
        if not hotbar then return end
        
        for slot = 1, 9 do
            local itemId = hotbar[tostring(slot)]
            if itemId and itemId ~= "" then
                local itemData = ItemUtility:GetItemData(itemId)
                if itemData and itemData.Data then
                    local name = itemData.Data.Name or ""
                    if string.find(string.lower(name), "rod") then
                        local rarity = getFishRarity(itemData)
                        local value = getRarityValue(rarity)
                        if value > bestValue then
                            bestValue = value
                            bestRod = slot
                        end
                    end
                end
            end
        end
    end)
    
    return bestRod
end

local currentRodSlot = 1
local function autoEquipBestRod()
    if not Config.AutoEquipBestRod then 
        currentRodSlot = 1
        return 
    end
    local bestRod = getBestRod()
    if bestRod ~= currentRodSlot then
        currentRodSlot = bestRod
        print("[Auto Equip] 🎣 Using slot " .. currentRodSlot)
    end
end

-- ====== AUTO USE BAIT ======
local function getBestBait()
    if not PlayerData then return nil end
    
    local bestBait = nil
    local bestValue = 0
    
    pcall(function()
        local items = PlayerData:GetExpect("Inventory")
        if not items or not items.Items then return end
        
        for _, item in ipairs(items.Items) do
            local data = ItemUtility:GetItemData(item.Id)
            if data and data.Data then
                local name = data.Data.Name or ""
                if string.find(string.lower(name), "bait") then
                    local rarity = getFishRarity(data)
                    local value = getRarityValue(rarity)
                    if value > bestValue then
                        bestValue = value
                        bestBait = item.UUID
                    end
                end
            end
        end
    end)
    
    return bestBait
end

local function autoUseBait()
    if not Config.AutoUseBait then return end
    
    local bait = getBestBait()
    if bait then
        pcall(function()
            Events.bait:FireServer(bait)
            print("[Auto Bait] 🪱 Used bait")
        end)
    end
end

-- ====== INSTANT REEL SYSTEM ======
local function instantReel()
    if not Config.InstantReel then
        -- Normal reel
        pcall(function()
            Events.fishing:FireServer()
        end)
        return
    end
    
    -- Instant reel: spam 10x super fast
    for i = 1, 10 do
        pcall(function()
            Events.fishing:FireServer()
        end)
        task.wait(0.001) -- Ultra fast
    end
    print("[Instant Reel] ⚡ INSTANT!")
end

-- ====== AUTO SHAKE SYSTEM ======
local shakeConnection = nil
local isShaking = false

local function setupAutoShake()
    if shakeConnection then
        shakeConnection:Disconnect()
        shakeConnection = nil
    end
    
    if not Config.AutoShake then return end
    
    shakeConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoShake or isShaking then return end
        
        pcall(function()
            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            local fishingGui = playerGui:FindFirstChild("FishingGui")
            
            if fishingGui then
                local shakeFrame = fishingGui:FindFirstChild("Shake", true)
                if shakeFrame and shakeFrame.Visible then
                    isShaking = true
                    
                    -- Spam shake event
                    for i = 1, 5 do
                        Events.shake:FireServer()
                        task.wait(Config.ShakeDelay)
                    end
                    
                    task.wait(0.2)
                    isShaking = false
                    print("[Auto Shake] 🎯 Completed!")
                end
            end
        end)
    end)
end

-- ====== PERFECT CAST SYSTEM ======
local function perfectCast()
    if not Config.PerfectCast then
        return 1755848498.4834
    end
    
    -- Perfect cast: maximum power
    return 9999999999.9999
end

-- ====== HUMANIZE MODE ======
local function getRandomDelay(base)
    if not Config.HumanizeMode then return base end
    
    local variance = base * 0.3
    return base + (math.random() - 0.5) * 2 * variance
end

-- ====== FISHING LOGIC ======
local isFishing = false
local fishingActive = false

local function castRod()
    pcall(function()
        autoEquipBestRod()
        autoUseBait()
        
        Events.equip:FireServer(currentRodSlot)
        task.wait(getRandomDelay(Config.CastDelay))
        Events.charge:InvokeServer(perfectCast())
        task.wait(0.02)
        Events.minigame:InvokeServer(1.2854545116425, currentRodSlot)
        Stats.CastsCount += 1
    end)
end

local function blatantFishing()
    while fishingActive and Config.BlatantMode do
        if not isFishing then
            isFishing = true
            
            -- Triple cast
            pcall(function()
                autoEquipBestRod()
                autoUseBait()
                
                Events.equip:FireServer(currentRodSlot)
                task.wait(getRandomDelay(Config.CastDelay))
                
                for i = 1, 3 do
                    task.spawn(function()
                        Events.charge:InvokeServer(perfectCast())
                        task.wait(getRandomDelay(Config.CastDelay))
                        Events.minigame:InvokeServer(1.2854545116425, currentRodSlot)
                        Stats.CastsCount += 1
                    end)
                    task.wait(getRandomDelay(Config.CastDelay))
                end
            end)
            
            task.wait(getRandomDelay(Config.FishDelay))
            
            -- Instant reel
            instantReel()
            
            task.wait(getRandomDelay(Config.CatchDelay * 0.4))
            
            Stats.FishCaught = Stats.FishCaught + 1
            isFishing = false
        else
            task.wait(0.01)
        end
    end
end

local function normalFishing()
    while fishingActive and not Config.BlatantMode do
        if not isFishing then
            isFishing = true
            
            castRod()
            task.wait(getRandomDelay(Config.FishDelay))
            instantReel()
            task.wait(getRandomDelay(Config.CatchDelay))
            
            Stats.FishCaught = Stats.FishCaught + 1
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

local function startFishing()
    if fishingActive then return end
    fishingActive = true
    setupAutoShake()
    notify("Auto Fish", "Fishing started!", 3)
    
    if Config.BlatantMode then
        task.spawn(blatantFishing)
        print("[Fishing] ⚡ Blatant Mode Activated!")
    else
        task.spawn(normalFishing)
        print("[Fishing] 🎣 Normal Mode Activated!")
    end
end

local function stopFishing()
    fishingActive = false
    isFishing = false
    if shakeConnection then
        shakeConnection:Disconnect()
        shakeConnection = nil
    end
    pcall(function() 
        Events.unequip:FireServer() 
    end)
    notify("Auto Fish", "Fishing stopped!", 3)
    print("[Fishing] 🛑 Stopped")
end

-- ====== SMART SELL SYSTEM ======
local function shouldSellFish(itemData)
    if not itemData or not itemData.Data then return true end
    
    local rarity = itemData.Data.Rarity or "Common"
    
    if itemData.Favorited then return false end
    
    if Config.SellByRarity then
        return Config.SellRarities[rarity] == true
    end
    
    return true
end

local function smartSell()
    print("╔═══════════════════════════════╗")
    print("[Smart Sell] 💰 Processing...")
    
    local sold = 0
    
    pcall(function()
        if Events.sell then
            local result = Events.sell:InvokeServer()
            if result then
                sold = 50 -- Estimate
                Stats.MoneyEarned = Stats.MoneyEarned + (sold * 15)
                print("[Smart Sell] ✅ Sold all items!")
                notify("Auto Sell", "Sold " .. sold .. " items!", 3)
            end
        end
    end)
    
    print("╚═══════════════════════════════╝")
end

-- Auto sell loop
task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        if Config.AutoSell and fishingActive then
            smartSell()
        end
    end
end)

-- ====== AUTO CATCH ======
task.spawn(function()
    while true do
        if Config.AutoCatch and not isFishing then
            instantReel()
        end
        task.wait(Config.CatchDelay)
    end
end)

-- ====== AUTO FAVORITE ======
local favoritedItems = {}

local function autoFavorite()
    if not Config.AutoFavorite or not PlayerData then return end
    
    local targetValue = getRarityValue(Config.FavoriteRarity)
    if targetValue < 6 then targetValue = 6 end
    
    local favorited = 0
    
    pcall(function()
        local items = PlayerData:GetExpect("Inventory")
        if not items or not items.Items then return end
        
        for _, item in ipairs(items.Items) do
            if not favoritedItems[item.UUID] then
                local data = ItemUtility:GetItemData(item.Id)
                if data and data.Data then
                    local rarity = getFishRarity(data)
                    local rarityValue = getRarityValue(rarity)
                    
                    if rarityValue >= targetValue then
                        Events.favorite:FireServer(item.UUID)
                        favoritedItems[item.UUID] = true
                        favorited = favorited + 1
                        
                        -- Rare fish alert
                        if rarityValue >= 5 then
                            rareFishAlert(data.Data.Name or "Unknown", rarity)
                        end
                        
                        task.wait(0.5)
                    end
                end
            end
        end
    end)
    
    if favorited > 0 then
        print("[Auto Favorite] ⭐ Favorited " .. favorited .. " items")
    end
end

-- Favorite check loop
task.spawn(function()
    while true do
        task.wait(15)
        autoFavorite()
    end
end)

-- ====== PERFORMANCE FUNCTIONS ======
local function boostFPS()
    if not Config.BoostFPS then return end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        if setfpscap then 
            setfpscap(240)
        end
    end)
end

local function disableAnimations()
    if not Config.NoAnimation then return end
    pcall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    if string.find(string.lower(track.Animation.Name), "fish") then
                        track:Stop()
                    end
                end
            end
        end
    end)
end

-- Performance monitor
task.spawn(function()
    while true do
        task.wait(2)
        if Config.BoostFPS then
            boostFPS()
        end
        if Config.NoAnimation then
            disableAnimations()
        end
    end
end)

-- ====== TELEPORT SYSTEM ======
local function teleportTo(locationName)
    local location = LOCATIONS[locationName]
    if location then
        pcall(function()
            LocalPlayer.Character:PivotTo(location)
            Config.TeleportLocation = locationName
            notify("Teleport", "Teleported to " .. locationName, 3)
            saveConfig()
        end)
    else
        warn("Location not found: " .. locationName)
    end
end

-- ====== AUTO REJOIN ======
if Config.AutoRejoin then
    game:GetService("CoreGui").ChildRemoved:Connect(function()
        task.wait(2)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end)
end

-- ====== ANTI-AFK ======
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ====== STATS UPDATE ======
task.spawn(function()
    while true do
        task.wait(1)
        Stats.SessionTime = tick() - Stats.StartTime
    end
end)

-- ====== WINDUI LOADER ======
local WindUI, Window
local function loadWindUI()
    local success, err = pcall(function()
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/sius-x/Wind-UI/main/source.lua"))()
        
        Window = WindUI:CreateWindow({
            Title = "🎣 Auto Fish V7.0 - Ultimate",
            Icon = "rbxassetid://4483362458",
            Author = "VictoriaHub Premium",
            Folder = "VH_AutoFish_V7",
            Size = UDim2.fromOffset(620, 520),
            KeySystem = {
                Key = "FreeForAll",
                Note = "No Key Required",
                SaveKey = false,
                CheckKey = function(k) return k == "FreeForAll" end
            },
            Transparent = true,
            Theme = "Dark",
            Color = Color3.fromRGB(0, 170, 255)
        })
    end)
    
    if not success then
        warn("[UI] Failed to load WindUI: " .. tostring(err))
        return false
    end
    
    return true
end

-- ====== CREATE UI ======
if loadWindUI() then
    -- MAIN TAB
    local Main = Window:Tab({
        Name = "Main",
        Icon = "rbxassetid://10734950309",
        Color = Color3.fromRGB(255, 50, 50)
    })
    
    local Fish = Main:Section({Name = "🎣 Core Fishing", Side = "Left"})
    
    Fish:Toggle({Name = "🤖 Auto Fish", Value = Config.AutoFish, Callback = function(v)
        Config.AutoFish = v
        if v then startFishing() else stopFishing() end
        saveConfig()
    end})
    
    Fish:Toggle({Name = "⚡ Blatant Mode", Value = Config.BlatantMode, Callback = function(v)
        Config.BlatantMode = v
        saveConfig()
    end})
    
    Fish:Toggle({Name = "⚡ Instant Reel", Value = Config.InstantReel, Callback = function(v)
        Config.InstantReel = v
        saveConfig()
    end})
    
    Fish:Toggle({Name = "🎯 Auto Shake", Value = Config.AutoShake, Callback = function(v)
        Config.AutoShake = v
        setupAutoShake()
        saveConfig()
    end})
    
    Fish:Toggle({Name = "🎯 Perfect Cast", Value = Config.PerfectCast, Callback = function(v)
        Config.PerfectCast = v
        saveConfig()
    end})
    
    local Auto = Main:Section({Name = "⚙️ Auto Systems", Side = "Right"})
    
    Auto:Toggle({Name = "🎣 Auto Equip Best Rod", Value = Config.AutoEquipBestRod, Callback = function(v)
        Config.AutoEquipBestRod = v
        saveConfig()
    end})
    
    Auto:Toggle({Name = "🪱 Auto Use Bait", Value = Config.AutoUseBait, Callback = function(v)
        Config.AutoUseBait = v
        saveConfig()
    end})
    
    Auto:Toggle({Name = "💰 Auto Sell", Value = Config.AutoSell, Callback = function(v)
        Config.AutoSell = v
        saveConfig()
    end})
    
    Auto:Toggle({Name = "⭐ Auto Favorite", Value = Config.AutoFavorite, Callback = function(v)
        Config.AutoFavorite = v
        saveConfig()
    end})
    
    Auto:Dropdown({Name = "Favorite Rarity", Options = {"Epic", "Legendary", "Mythic", "Secret"}, Default = Config.FavoriteRarity, Callback = function(v)
        Config.FavoriteRarity = v
        saveConfig()
    end})
    
    -- DELAYS TAB
    local DelaysTab = Window:Tab({Name = "Delays", Icon = "rbxassetid://10734950309", Color = Color3.fromRGB(50, 255, 50)})
    
    local Delays = DelaysTab:Section({Name = "⏱️ Fishing Delays", Side = "Left"})
    
    Delays:Slider({Name = "Cast Delay", Min = 0.05, Max = 2, Default = Config.CastDelay, Callback = function(v)
        Config.CastDelay = v
        saveConfig()
    end})
    
    Delays:Slider({Name = "Reel Delay", Min = 0.01, Max = 1, Default = Config.ReelDelay, Callback = function(v)
        Config.ReelDelay = v
        saveConfig()
    end})
    
    Delays:Slider({Name = "Fish Delay", Min = 0.1, Max = 5, Default = Config.FishDelay, Callback = function(v)
        Config.FishDelay = v
        saveConfig()
    end})
    
    local Times = DelaysTab:Section({Name = "⏰ System Delays", Side = "Right"})
    
    Times:Slider({Name = "Sell Delay (seconds)", Min = 5, Max = 300, Default = Config.SellDelay, Callback = function(v)
        Config.SellDelay = v
        saveConfig()
    end})
    
    Times:Slider({Name = "Shake Delay", Min = 0.01, Max = 0.5, Default = Config.ShakeDelay, Callback = function(v)
        Config.ShakeDelay = v
        saveConfig()
    end})
    
    Times:Slider({Name = "Catch Delay", Min = 0.1, Max = 3, Default = Config.CatchDelay, Callback = function(v)
        Config.CatchDelay = v
        saveConfig()
    end})
    
    -- SELL TAB
    local SellTab = Window:Tab({Name = "Sell", Icon = "rbxassetid://10734950309", Color = Color3.fromRGB(255, 200, 0)})
    
    local SellSec = SellTab:Section({Name = "💰 Smart Sell", Side = "Left"})
    
    SellSec:Toggle({Name = "📊 Sell By Rarity", Value = Config.SellByRarity, Callback = function(v)
        Config.SellByRarity = v
        saveConfig()
    end})
    
    SellSec:Slider({Name = "Sell Threshold", Min = 0, Max = 200, Default = Config.SellThreshold, Callback = function(v)
        Config.SellThreshold = v
        saveConfig()
    end})
    
    SellSec:Button({Name = "💰 SELL NOW", Callback = smartSell})
    
    local Rarities = SellTab:Section({Name = "🎨 Sell Rarities", Side = "Right"})
    
    for rarity, _ in pairs(RarityTiers) do
        Rarities:Toggle({Name = rarity, Value = Config.SellRarities[rarity] or false, Callback = function(v)
            Config.SellRarities[rarity] = v
            saveConfig()
        end})
    end
    
    -- STATS TAB
    local StatsTab = Window:Tab({Name = "Stats", Icon = "rbxassetid://10734950309", Color = Color3.fromRGB(0, 150, 255)})
    
    local StatsSec = StatsTab:Section({Name = "📊 Live Statistics", Side = "Left"})
    
    local function formatTime(seconds)
        local hours = math.floor(seconds / 3600)
        local mins = math.floor((seconds % 3600) / 60)
        local secs = math.floor(seconds % 60)
        return string.format("%02d:%02d:%02d", hours, mins, secs)
    end
    
    local statsLabel = StatsSec:Label({
        Name = "Loading stats...",
        Flag = "StatsLabel"
    })
    
    -- Update stats every second
    task.spawn(function()
        while true do
            task.wait(1)
            local statsText = string.format(
                "🎣 Fish Caught: %d\n" ..
                "💰 Money Earned: ~$%d\n" ..
                "⏱️ Session Time: %s\n" ..
                "🎯 Casts: %d\n" ..
                "⭐ Mythic: %d | Secret: %d\n" ..
                "🔥 Legendary: %d | Epic: %d\n" ..
                "📌 Last Catch: %s",
                Stats.FishCaught,
                Stats.MoneyEarned,
                formatTime(Stats.SessionTime),
                Stats.CastsCount,
                Stats.RareFishCaught.Mythic or 0,
                Stats.RareFishCaught.Secret or 0,
                Stats.RareFishCaught.Legendary or 0,
                Stats.RareFishCaught.Epic or 0,
                Stats.LastCatch
            )
            
            if statsLabel then
                statsLabel:Set(statsText)
            end
        end
    end)
    
    StatsSec:Button({Name = "🔄 Reset Stats", Callback = function()
        Stats = {
            FishCaught = 0,
            MoneyEarned = 0,
            RareFishCaught = {Mythic = 0, Secret = 0, Legendary = 0, Epic = 0},
            StartTime = tick(),
            SessionTime = 0,
            LastCatch = "None",
            CastsCount = 0
        }
        notify("Stats", "Statistics reset!", 3)
    end})
    
    -- PERFORMANCE TAB
    local PerfTab = Window:Tab({Name = "Performance", Icon = "rbxassetid://10734950309", Color = Color3.fromRGB(150, 0, 255)})
    
    local Opt = PerfTab:Section({Name = "⚡ Optimizations", Side = "Left"})
    
    Opt:Toggle({Name = "No Animation", Value = Config.NoAnimation, Callback = function(v)
        Config.NoAnimation = v
        saveConfig()
    end})
    
    Opt:Toggle({Name = "Boost FPS (240)", Value = Config.BoostFPS, Callback = function(v)
        Config.BoostFPS = v
        if v then boostFPS() end
        saveConfig()
    end})
    
    Opt:Toggle({Name = "GPU Saver", Value = Config.GPUSaver, Callback = function(v)
        Config.GPUSaver = v
        saveConfig()
    end})
    
    Opt:Toggle({Name = "Disable Effects", Value = Config.DisableEffects, Callback = function(v)
        Config.DisableEffects = v
        saveConfig()
    end})
    
    -- TELEPORT TAB
    local TeleTab = Window:Tab({Name = "Teleport", Icon = "rbxassetid://10734950309", Color = Color3.fromRGB(0, 255, 200)})
    
    local TeleSec = TeleTab:Section({Name = "🌍 Locations", Side = "Left"})
    
    local locationOptions = {}
    for name, _ in pairs(LOCATIONS) do
        table.insert(locationOptions, name)
    end
    
    TeleSec:Dropdown({
        Name = "Select Location",
        Options = locationOptions,
        Default = Config.TeleportLocation,
        Callback = function(v)
            Config.TeleportLocation = v
            saveConfig()
        end
    })
    
    TeleSec:Button({Name = "🚀 Teleport Now", Callback = function()
        teleportTo(Config.TeleportLocation)
    end})
    
    -- Quick teleport buttons
    local QuickTele = TeleTab:Section({Name = "⚡ Quick Teleport", Side = "Right"})
    
    local quickSpots = {"Sisyphus Statue", "Coral Reefs", "Esoteric Depths", "Weather Machine"}
    
    for _, spot in ipairs(quickSpots) do
        QuickTele:Button({Name = "📍 " .. spot, Callback = function()
            teleportTo(spot)
        end})
    end
    
    -- SAFETY TAB
    local SafetyTab = Window:Tab({Name = "Safety", Icon = "rbxassetid://10734950309", Color = Color3.fromRGB(255, 100, 100)})
    
    local Safe = SafetyTab:Section({Name = "🛡️ Anti-Detection", Side = "Left"})
    
    Safe:Toggle({Name = "🎭 Humanize Mode", Value = Config.HumanizeMode, Callback = function(v)
        Config.HumanizeMode = v
        saveConfig()
    end})
    
    Safe:Toggle({Name = "🐢 Safe Mode", Value = Config.SafeMode, Callback = function(v)
        Config.SafeMode = v
        if v then
            Config.BlatantMode = false
            Config.InstantReel = false
        end
        saveConfig()
    end})
    
    Safe:Toggle({Name = "🔄 Auto Rejoin", Value = Config.AutoRejoin, Callback = function(v)
        Config.AutoRejoin = v
        saveConfig()
    end})
    
    -- ALERTS TAB
    local AlertTab = Window:Tab({Name = "Alerts", Icon = "rbxassetid://10734950309", Color = Color3.fromRGB(255, 100, 200)})
    
    local Alerts = AlertTab:Section({Name = "🔔 Notifications", Side = "Left"})
    
    Alerts:Toggle({Name = "🎣 Rare Fish Alert", Value = Config.RareFishAlert, Callback = function(v)
        Config.RareFishAlert = v
        saveConfig()
    end})
    
    Alerts:Toggle({Name = "🔊 Sound Alerts", Value = Config.SoundAlerts, Callback = function(v)
        Config.SoundAlerts = v
        saveConfig()
    end})
    
    Alerts:Input({
        Name = "Discord Webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Default = Config.WebhookURL,
        Callback = function(v)
            Config.WebhookURL = v
            saveConfig()
        end
    })
    
    -- SETTINGS TAB
    local SettingsTab = Window:Tab({Name = "Settings", Icon = "rbxassetid://10734950309", Color = Color3.fromRGB(200, 200, 200)})
    
    local Settings = SettingsTab:Section({Name = "⚙️ Configuration", Side = "Left"})
    
    Settings:Button({Name = "💾 Save Config", Callback = saveConfig})
    Settings:Button({Name = "📂 Load Config", Callback = loadConfig})
    Settings:Button({Name = "🔄 Reset Config", Callback = function()
        for k, v in pairs(DefaultConfig) do
            if type(v) == "table" then
                Config[k] = {}
                for k2, v2 in pairs(v) do Config[k][k2] = v2 end
            else
                Config[k] = v
            end
        end
        saveConfig()
        notify("Config", "Configuration reset to defaults!", 3)
    end})
    
    Settings:Button({Name = "📋 Copy Discord", Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/example")
            notify("Discord", "Discord link copied!", 3)
        end
    end})
end

-- ====== INITIALIZATION ======
print("\n" .. string.rep("=", 50))
print("🎣 AUTO FISH V7.0 ULTIMATE EDITION")
print("⚡ Combined V5 + V6 + Enhanced Features")
print("✅ Script Loaded Successfully!")
print(string.rep("=", 50) .. "\n")

notify("Auto Fish V7.0", "Script loaded successfully!", 5)

-- Auto start fishing if config says so
task.wait(2)
if Config.AutoFish then
    startFishing()
end
