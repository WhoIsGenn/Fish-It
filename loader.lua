-- ====================================================================
--                  FISH IT ADVANCED HUB V1.0
--              Professional Fishing Automation - WindUI
-- ====================================================================

-- ====== SERVICES ======
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- ====== NETWORK EVENTS ======
local function getNetworkEvents()
    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
    return {
        fishing = net:WaitForChild("RE/FishingCompleted"),
        sell = net:WaitForChild("RF/SellAllItems"),
        charge = net:WaitForChild("RF/ChargeFishingRod"),
        minigame = net:WaitForChild("RF/RequestFishingMinigameStarted"),
        cancel = net:WaitForChild("RF/CancelFishingInputs"),
        equip = net:WaitForChild("RE/EquipToolFromHotbar"),
        unequip = net:WaitForChild("RE/UnequipToolFromHotbar"),
        favorite = net:WaitForChild("RE/FavoriteItem"),
        buyWeather = net:WaitForChild("RF/BuyWeather")
    }
end

local Events = getNetworkEvents()

-- ====== MODULES ======
local ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
local Replion = require(ReplicatedStorage.Packages.Replion)
local PlayerData = Replion.Client:WaitReplion("Data")

-- ====== CONFIGURATION ======
local Config = {
    -- Fishing
    FishingMode = "None", -- "Legit", "Instant", "Blatant", "BlatantBeta"
    LegitShakeHelp = true,
    InstantCompleteDelay = 0.5,
    BlatantTargetNotif = 6, -- 5-7 for stable
    BlatantBetaSpam = true,
    FishDelay = 0.9,
    CatchDelay = 0.2,
    
    -- Webhook
    WebhookEnabled = false,
    WebhookURL = "",
    WebhookRarityFilter = "Mythic", -- Send webhook for this rarity+
    
    -- Auto Favorite
    AutoFavorite = false,
    FavoriteMode = "Rarity", -- "Rarity" or "Name"
    FavoriteRarity = "Mythic",
    FavoriteFishNames = {}, -- List of fish names
    
    -- Auto Sell
    AutoSell = false,
    SellThreshold = 50, -- Sell when inventory >= this %
    KeepFavorited = true,
    SellDelay = 30,
    
    -- Auto Buy Weather
    AutoBuyWeather = false,
    WeatherTypes = {
        Wind = false,
        Cloudy = false,
        Storm = false
    },
    
    -- Misc
    BoostFPS = false,
    DisableCutscene = false,
    DisableObtainNotif = false,
    DisableVFX = false,
    DisableFishingEffect = false,
    DisableFishingAnimation = false,
    DisableCharEffect = false
}

-- ====== RARITY SYSTEM ======
local RarityTiers = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
    Mythic = 6,
    Secret = 7
}

local function getRarityValue(rarity)
    return RarityTiers[rarity] or 0
end

local function getFishRarity(itemData)
    if not itemData or not itemData.Data then return "Common" end
    return itemData.Data.Rarity or "Common"
end

local function getFishName(itemData)
    if not itemData or not itemData.Data then return "Unknown" end
    return itemData.Data.Name or "Unknown"
end

-- ====== ANTI-AFK ======
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ====== FISHING VARIABLES ======
local isFishing = false
local fishingActive = false
local currentCatchCount = 0

-- ====== WEBHOOK SYSTEM ======
local function sendWebhook(fishName, rarity, value)
    if not Config.WebhookEnabled or Config.WebhookURL == "" then return end
    
    local rarityValue = getRarityValue(rarity)
    local minRarity = getRarityValue(Config.WebhookRarityFilter)
    
    if rarityValue < minRarity then return end
    
    local embed = {
        ["embeds"] = {{
            ["title"] = "🎣 Rare Fish Caught!",
            ["description"] = string.format("**%s** (%s)", fishName, rarity),
            ["color"] = rarityValue == 7 and 16711680 or (rarityValue == 6 and 16776960 or 65280),
            ["fields"] = {
                {["name"] = "Value", ["value"] = tostring(value or "Unknown"), ["inline"] = true},
                {["name"] = "Player", ["value"] = LocalPlayer.Name, ["inline"] = true}
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
        }}
    }
    
    pcall(function()
        syn.request({
            Url = Config.WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(embed)
        })
    end)
end

-- ====== AUTO FAVORITE SYSTEM ======
local favoritedItems = {}

local function isItemFavorited(uuid)
    local success, result = pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        for _, item in ipairs(items) do
            if item.UUID == uuid then
                return item.Favorited == true
            end
        end
        return false
    end)
    return success and result or false
end

local function autoFavorite()
    if not Config.AutoFavorite then return end
    
    local favorited = 0
    
    pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        if not items or #items == 0 then return end
        
        for _, item in ipairs(items) do
            local data = ItemUtility:GetItemData(item.Id)
            if data and data.Data then
                local fishName = getFishName(data)
                local rarity = getFishRarity(data)
                local shouldFavorite = false
                
                if Config.FavoriteMode == "Rarity" then
                    local rarityValue = getRarityValue(rarity)
                    local targetValue = getRarityValue(Config.FavoriteRarity)
                    shouldFavorite = rarityValue >= targetValue
                elseif Config.FavoriteMode == "Name" then
                    for _, name in ipairs(Config.FavoriteFishNames) do
                        if string.find(string.lower(fishName), string.lower(name)) then
                            shouldFavorite = true
                            break
                        end
                    end
                end
                
                if shouldFavorite and not isItemFavorited(item.UUID) and not favoritedItems[item.UUID] then
                    Events.favorite:FireServer(item.UUID)
                    favoritedItems[item.UUID] = true
                    favorited = favorited + 1
                    print("[Auto Favorite] ⭐ " .. fishName .. " (" .. rarity .. ")")
                    task.wait(0.3)
                end
            end
        end
    end)
    
    if favorited > 0 then
        print("[Auto Favorite] ✅ Favorited: " .. favorited .. " fish")
    end
end

-- Auto favorite loop
task.spawn(function()
    while true do
        task.wait(10)
        if Config.AutoFavorite then
            autoFavorite()
        end
    end
end)

-- ====== AUTO SELL SYSTEM (THRESHOLD) ======
local function getInventoryCount()
    local success, count = pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        return items and #items or 0
    end)
    return success and count or 0
end

local function getInventoryCapacity()
    -- Default capacity, adjust based on game data
    return 100
end

local function getInventoryPercent()
    local count = getInventoryCount()
    local capacity = getInventoryCapacity()
    return (count / capacity) * 100
end

local function autoSell()
    if not Config.AutoSell then return end
    
    local percent = getInventoryPercent()
    
    if percent >= Config.SellThreshold then
        print("╔═══════════════════════════════════╗")
        print("[Auto Sell] 💰 Threshold reached: " .. math.floor(percent) .. "%")
        
        local sellSuccess = pcall(function()
            return Events.sell:InvokeServer()
        end)
        
        if sellSuccess then
            print("[Auto Sell] ✅ SOLD! " .. (Config.KeepFavorited and "(Favorited kept)" or ""))
            print("╚═══════════════════════════════════╝")
        else
            warn("[Auto Sell] ❌ Sell failed")
        end
    end
end

-- Auto sell loop
task.spawn(function()
    while true do
        task.wait(Config.SellDelay)
        autoSell()
    end
end)

-- ====== AUTO BUY WEATHER ======
local weatherCooldown = {}

local function autoBuyWeather()
    if not Config.AutoBuyWeather then return end
    
    for weatherType, enabled in pairs(Config.WeatherTypes) do
        if enabled and not weatherCooldown[weatherType] then
            local success = pcall(function()
                Events.buyWeather:InvokeServer(weatherType)
                print("[Weather] 🌤️ Bought: " .. weatherType)
            end)
            
            if success then
                weatherCooldown[weatherType] = true
                task.delay(300, function() -- 5 min cooldown
                    weatherCooldown[weatherType] = false
                end)
            end
        end
    end
end

-- Weather loop
task.spawn(function()
    while true do
        task.wait(60)
        autoBuyWeather()
    end
end)

-- ====== FISHING MODES ======

-- 1. LEGIT MODE (with shake help)
local function legitFishing()
    while fishingActive and Config.FishingMode == "Legit" do
        if not isFishing then
            isFishing = true
            
            -- Let player cast normally, we just help with shake/tap
            if Config.LegitShakeHelp then
                -- Monitor for shake prompt and help
                task.spawn(function()
                    local attempts = 0
                    while attempts < 20 do -- Max 20 attempts (2 seconds)
                        pcall(function()
                            Events.fishing:FireServer() -- Gentle tap help
                        end)
                        task.wait(0.1)
                        attempts = attempts + 1
                    end
                end)
            end
            
            task.wait(Config.FishDelay + 1.5) -- Longer wait for legit mode
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

-- 2. INSTANT FISHING MODE
local function instantFishing()
    while fishingActive and Config.FishingMode == "Instant" do
        if not isFishing then
            isFishing = true
            
            -- Cast
            pcall(function()
                Events.equip:FireServer(1)
                task.wait(0.05)
                Events.charge:InvokeServer(1755848498.4834)
                task.wait(0.02)
                Events.minigame:InvokeServer(1.2854545116425, 1)
            end)
            
            -- Wait for bite
            task.wait(Config.FishDelay)
            
            -- Instant complete with delay
            pcall(function()
                Events.fishing:FireServer()
            end)
            
            task.wait(Config.InstantCompleteDelay)
            
            isFishing = false
            currentCatchCount = currentCatchCount + 1
        else
            task.wait(0.1)
        end
    end
end

-- 3. BLATANT MODE (Stable 5-7 notif)
local function blatantFishing()
    while fishingActive and Config.FishingMode == "Blatant" do
        if not isFishing then
            isFishing = true
            
            -- Cast with double overlap
            pcall(function()
                Events.equip:FireServer(1)
                task.wait(0.01)
                
                -- Cast 1
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
                    task.wait(0.01)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
                
                task.wait(0.05)
                
                -- Cast 2
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
                    task.wait(0.01)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
            end)
            
            -- Wait for bite
            task.wait(Config.FishDelay)
            
            -- Controlled reel (5-7 times)
            local reelCount = Config.BlatantTargetNotif or 6
            for i = 1, reelCount do
                pcall(function() 
                    Events.fishing:FireServer() 
                end)
                task.wait(0.01)
            end
            
            task.wait(Config.CatchDelay * 0.5)
            
            isFishing = false
            currentCatchCount = currentCatchCount + 1
            
            if currentCatchCount % 10 == 0 then
                print("[Blatant] ⚡ Catches: " .. currentCatchCount)
            end
        else
            task.wait(0.01)
        end
    end
end

-- 4. BLATANT MODE [BETA] (Wild spam like other hubs)
local function blatantBetaFishing()
    while fishingActive and Config.FishingMode == "BlatantBeta" do
        if not isFishing then
            isFishing = true
            
            -- Triple cast spam
            pcall(function()
                Events.equip:FireServer(1)
                
                for i = 1, 3 do
                    task.spawn(function()
                        Events.charge:InvokeServer(1755848498.4834)
                        Events.minigame:InvokeServer(1.2854545116425, 1)
                    end)
                    task.wait(0.01)
                end
            end)
            
            -- Shorter wait
            task.wait(Config.FishDelay * 0.7)
            
            -- SPAM REEL (10-15 times)
            for i = 1, math.random(10, 15) do
                pcall(function() 
                    Events.fishing:FireServer() 
                end)
                task.wait(0.005)
            end
            
            task.wait(Config.CatchDelay * 0.3)
            
            isFishing = false
            currentCatchCount = currentCatchCount + 1
        else
            task.wait(0.005)
        end
    end
end

-- Main fishing controller
local function startFishing()
    if Config.FishingMode == "Legit" then
        task.spawn(legitFishing)
    elseif Config.FishingMode == "Instant" then
        task.spawn(instantFishing)
    elseif Config.FishingMode == "Blatant" then
        task.spawn(blatantFishing)
    elseif Config.FishingMode == "BlatantBeta" then
        task.spawn(blatantBetaFishing)
    end
end

-- ====== MISC FEATURES ======

-- 1. Boost FPS
local function toggleBoostFPS(enabled)
    pcall(function()
        if enabled then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1
            setfpscap(60)
        else
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 100000
            setfpscap(0)
        end
    end)
end

-- 2. Disable Cutscene
local function toggleCutscene(disabled)
    pcall(function()
        local cutscenes = LocalPlayer.PlayerGui:FindFirstChild("Cutscenes")
        if cutscenes then
            cutscenes.Enabled = not disabled
        end
    end)
end

-- 3. Disable Obtain Notification (Icon only)
local function toggleObtainNotif(disabled)
    pcall(function()
        local obtainNotif = LocalPlayer.PlayerGui:FindFirstChild("ObtainNotification")
        if obtainNotif then
            for _, v in pairs(obtainNotif:GetDescendants()) do
                if v:IsA("ImageLabel") or v:IsA("ImageButton") then
                    v.Visible = not disabled
                end
            end
        end
    end)
end

-- 4. Disable VFX
local function toggleVFX(disabled)
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled = not disabled
            end
        end
    end)
end

-- 5. Disable Fishing Effect
local function toggleFishingEffect(disabled)
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local rod = character:FindFirstChild("Rod")
        if rod then
            for _, v in pairs(rod:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Enabled = not disabled
                end
            end
        end
    end)
end

-- 6. Disable Fishing Animation
local function toggleFishingAnimation(disabled)
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                if string.find(track.Name:lower(), "fish") then
                    track:Stop()
                end
            end
        end
    end)
end

-- 7. Disable Char Effect
local function toggleCharEffect(disabled)
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        
        for _, v in pairs(character:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") then
                v.Enabled = not disabled
            end
        end
    end)
end

-- ====== WINDUI SETUP ======
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/WhoIsGenn/WindUI/main/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "🎣 Fish It Hub",
    Icon = "rbxassetid://10723434711",
    Author = "Advanced Fishing",
    Folder = "FishItHub",
    Size = UDim2.fromOffset(580, 480),
    KeySystem = {
        Key = "FishIt2025",
        Note = "Join Discord for key",
        URL = "https://discord.gg/example",
        SaveKey = true
    },
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
})

-- ====== FISHING TAB ======
local FishingTab = Window:CreateTab({
    Title = "🎣 Fishing",
    Icon = "rbxassetid://10723434711"
})

local FishingSection = FishingTab:CreateSection("Fishing Modes")

local FishingDropdown = FishingTab:CreateDropdown({
    Title = "Fishing Mode",
    List = {"None", "Legit", "Instant", "Blatant", "BlatantBeta"},
    Default = Config.FishingMode,
    Callback = function(value)
        Config.FishingMode = value
        fishingActive = (value ~= "None")
        
        if fishingActive then
            print("[Fishing] 🟢 Started: " .. value)
            currentCatchCount = 0
            startFishing()
        else
            print("[Fishing] 🔴 Stopped")
            pcall(function() Events.unequip:FireServer() end)
        end
    end
})

FishingTab:CreateToggle({
    Title = "🤝 Legit Shake Help",
    Description = "Help with shake/tap in legit mode",
    Default = Config.LegitShakeHelp,
    Callback = function(value)
        Config.LegitShakeHelp = value
    end
})

FishingTab:CreateSlider({
    Title = "⏱️ Instant Complete Delay",
    Description = "Delay after instant catch (seconds)",
    Min = 0.1,
    Max = 2,
    Default = Config.InstantCompleteDelay,
    Callback = function(value)
        Config.InstantCompleteDelay = value
    end
})

FishingTab:CreateSlider({
    Title = "🎯 Blatant Target Notif",
    Description = "Target notification count (5-7 stable)",
    Min = 3,
    Max = 10,
    Default = Config.BlatantTargetNotif,
    Callback = function(value)
        Config.BlatantTargetNotif = value
    end
})

local TimingSection = FishingTab:CreateSection("Timing Settings")

FishingTab:CreateSlider({
    Title = "Fish Delay",
    Description = "Wait time for fish to bite",
    Min = 0.1,
    Max = 5,
    Default = Config.FishDelay,
    Callback = function(value)
        Config.FishDelay = value
    end
})

FishingTab:CreateSlider({
    Title = "Catch Delay",
    Description = "Wait time between catches",
    Min = 0.1,
    Max = 2,
    Default = Config.CatchDelay,
    Callback = function(value)
        Config.CatchDelay = value
    end
})

-- ====== WEBHOOK TAB ======
local WebhookTab = Window:CreateTab({
    Title = "🔔 Webhook",
    Icon = "rbxassetid://10747372992"
})

WebhookTab:CreateToggle({
    Title = "Enable Webhook",
    Description = "Send rare fish notifications",
    Default = Config.WebhookEnabled,
    Callback = function(value)
        Config.WebhookEnabled = value
    end
})

WebhookTab:CreateTextBox({
    Title = "Webhook URL",
    Description = "Discord webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(value)
        Config.WebhookURL = value
    end
})

WebhookTab:CreateDropdown({
    Title = "Minimum Rarity",
    Description = "Send webhook for this rarity and above",
    List = {"Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Default = Config.WebhookRarityFilter,
    Callback = function(value)
        Config.WebhookRarityFilter = value
    end
})

-- ====== AUTO FAVORITE TAB ======
local FavoriteTab = Window:CreateTab({
    Title = "⭐ Auto Favorite",
    Icon = "rbxassetid://10734950309"
})

FavoriteTab:CreateToggle({
    Title = "Enable Auto Favorite",
    Default = Config.AutoFavorite,
    Callback = function(value)
        Config.AutoFavorite = value
    end
})

FavoriteTab:CreateDropdown({
    Title = "Favorite Mode",
    List = {"Rarity", "Name"},
    Default = Config.FavoriteMode,
    Callback = function(value)
        Config.FavoriteMode = value
    end
})

FavoriteTab:CreateDropdown({
    Title = "Minimum Rarity",
    Description = "Favorite this rarity and above",
    List = {"Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Default = Config.FavoriteRarity,
    Callback = function(value)
        Config.FavoriteRarity = value
    end
})

FavoriteTab:CreateButton({
    Title = "⭐ Favorite All Now",
    Description = "Run favorite scan immediately",
    Callback = function()
        autoFavorite()
    end
})

-- ====== AUTO SELL TAB ======
local SellTab = Window:CreateTab({
    Title = "💰 Auto Sell",
    Icon = "rbxassetid://10747372992"
})

SellTab:CreateToggle({
    Title = "Enable Auto Sell",
    Default = Config.AutoSell,
    Callback = function(value)
        Config.AutoSell = value
    end
})

SellTab:CreateSlider({
    Title = "📦 Sell Threshold (%)",
    Description = "Sell when inventory reaches this percentage",
    Min = 10,
    Max = 100,
    Default = Config.SellThreshold,
    Callback = function(value)
        Config.SellThreshold = value
    end
})

SellTab:CreateToggle({
    Title = "Keep Favorited",
    Description = "Don't sell favorited fish",
    Default = Config.KeepFavorited,
    Callback = function(value)
        Config.KeepFavorited = value
    end
})

SellTab:CreateSlider({
    Title = "⏱️ Sell Check Delay",
    Description = "Check interval in seconds",
    Min = 10,
    Max = 300,
    Default = Config.SellDelay,
    Callback = function(value)
        Config.SellDelay = value
    end
})

SellTab:CreateButton({
    Title = "💰 Sell All Now",
    Description = "Sell immediately",
    Callback = function()
        local sellSuccess = pcall(function()
            return Events.sell:InvokeServer()
        end)
        if sellSuccess then
            print("[Manual Sell] ✅ Sold!")
        end
    end
})

-- ====== AUTO BUY WEATHER TAB ======
local WeatherTab = Window:CreateTab({
    Title = "🌤️ Auto Weather",
    Icon = "rbxassetid://10734950309"
})

WeatherTab:CreateToggle({
    Title = "Enable Auto Buy Weather",
    Default = Config.AutoBuyWeather,
    Callback = function(value)
        Config.AutoBuyWeather = value
    end
})

WeatherTab:CreateToggle({
    Title = "💨 Wind",
    Default = Config.WeatherTypes.Wind,
    Callback = function(value)
        Config.WeatherTypes.Wind = value
    end
})

WeatherTab:CreateToggle({
    Title = "☁️ Cloudy",
    Default = Config.WeatherTypes.Cloudy,
    Callback = function(value)
        Config.WeatherTypes.Cloudy = value
    end
})

WeatherTab:CreateToggle({
    Title = "⛈️ Storm",
    Default = Config.WeatherTypes.Storm,
    Callback = function(value)
        Config.WeatherTypes.Storm = value
    end
})

-- ====== MISC TAB ======
local MiscTab = Window:CreateTab({
    Title = "⚙️ Misc",
    Icon = "rbxassetid://10734950309"
})

local PerformanceSection = MiscTab:CreateSection("Performance")

MiscTab:CreateToggle({
    Title = "🚀 Boost FPS",
    Default = Config.BoostFPS,
    Callback = function(value)
        Config.BoostFPS = value
        toggleBoostFPS(value)
    end
})

local VisualSection = MiscTab:CreateSection("Visual Effects")

MiscTab:CreateToggle({
    Title = "🎬 Disable Cutscene",
    Default = Config.DisableCutscene,
    Callback = function(value)
        Config.DisableCutscene = value
        toggleCutscene(value)
    end
})

MiscTab:CreateToggle({
    Title = "🔔 Disable Obtain Notification",
    Description = "Hide fish icon only, keep text",
    Default = Config.DisableObtainNotif,
    Callback = function(value)
        Config.DisableObtainNotif = value
        toggleObtainNotif(value)
    end
})

MiscTab:CreateToggle({
    Title = "✨ Disable VFX",
    Default = Config.DisableVFX,
    Callback = function(value)
        Config.DisableVFX = value
        toggleVFX(value)
    end
})

MiscTab:CreateToggle({
    Title = "🎣 Disable Fishing Effect",
    Description = "Hide rod particles/effects",
    Default = Config.DisableFishingEffect,
    Callback = function(value)
        Config.DisableFishingEffect = value
        toggleFishingEffect(value)
    end
})

MiscTab:CreateToggle({
    Title = "🎭 Disable Fishing Animation",
    Default = Config.DisableFishingAnimation,
    Callback = function(value)
        Config.DisableFishingAnimation = value
        toggleFishingAnimation(value)
    end
})

MiscTab:CreateToggle({
    Title = "👤 Disable Char Effect",
    Description = "Hide character particles",
    Default = Config.DisableCharEffect,
    Callback = function(value)
        Config.DisableCharEffect = value
        toggleCharEffect(value)
    end
})

-- ====== STARTUP ======
print("╔════════════════════════════════════════╗")
print("║   🎣 Fish It Advanced Hub V1.0        ║")
print("
