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
    FishingMode = "None",
    LegitShakeHelp = true,
    InstantCompleteDelay = 0.5,
    BlatantTargetNotif = 6,
    FishDelay = 0.9,
    CatchDelay = 0.2,
    
    -- Webhook
    WebhookEnabled = false,
    WebhookURL = "",
    WebhookRarityFilter = "Mythic",
    
    -- Auto Favorite
    AutoFavorite = false,
    FavoriteMode = "Rarity",
    FavoriteRarity = "Mythic",
    FavoriteFishNames = {},
    
    -- Auto Sell
    AutoSell = false,
    SellThreshold = 50,
    KeepFavorited = true,
    SellDelay = 30,
    
    -- Auto Buy Weather
    AutoBuyWeather = false,
    WeatherWind = false,
    WeatherCloudy = false,
    WeatherStorm = false,
    
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

task.spawn(function()
    while true do
        task.wait(10)
        if Config.AutoFavorite then
            autoFavorite()
        end
    end
end)

-- ====== AUTO SELL SYSTEM ======
local function getInventoryCount()
    local success, count = pcall(function()
        local items = PlayerData:GetExpect("Inventory").Items
        return items and #items or 0
    end)
    return success and count or 0
end

local function getInventoryCapacity()
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
    
    local weatherTypes = {
        {name = "Wind", enabled = Config.WeatherWind},
        {name = "Cloudy", enabled = Config.WeatherCloudy},
        {name = "Storm", enabled = Config.WeatherStorm}
    }
    
    for _, weather in ipairs(weatherTypes) do
        if weather.enabled and not weatherCooldown[weather.name] then
            local success = pcall(function()
                Events.buyWeather:InvokeServer(weather.name)
                print("[Weather] 🌤️ Bought: " .. weather.name)
            end)
            
            if success then
                weatherCooldown[weather.name] = true
                task.delay(300, function()
                    weatherCooldown[weather.name] = false
                end)
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(60)
        autoBuyWeather()
    end
end)

-- ====== FISHING MODES ======

-- 1. LEGIT MODE
local function legitFishing()
    while fishingActive and Config.FishingMode == "Legit" do
        if not isFishing then
            isFishing = true
            
            if Config.LegitShakeHelp then
                task.spawn(function()
                    local attempts = 0
                    while attempts < 20 do
                        pcall(function()
                            Events.fishing:FireServer()
                        end)
                        task.wait(0.1)
                        attempts = attempts + 1
                    end
                end)
            end
            
            task.wait(Config.FishDelay + 1.5)
            isFishing = false
        else
            task.wait(0.1)
        end
    end
end

-- 2. INSTANT FISHING
local function instantFishing()
    while fishingActive and Config.FishingMode == "Instant" do
        if not isFishing then
            isFishing = true
            
            pcall(function()
                Events.equip:FireServer(1)
                task.wait(0.05)
                Events.charge:InvokeServer(1755848498.4834)
                task.wait(0.02)
                Events.minigame:InvokeServer(1.2854545116425, 1)
            end)
            
            task.wait(Config.FishDelay)
            
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

-- 3. BLATANT MODE (Stable)
local function blatantFishing()
    while fishingActive and Config.FishingMode == "Blatant" do
        if not isFishing then
            isFishing = true
            
            pcall(function()
                Events.equip:FireServer(1)
                task.wait(0.01)
                
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
                    task.wait(0.01)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
                
                task.wait(0.05)
                
                task.spawn(function()
                    Events.charge:InvokeServer(1755848498.4834)
                    task.wait(0.01)
                    Events.minigame:InvokeServer(1.2854545116425, 1)
                end)
            end)
            
            task.wait(Config.FishDelay)
            
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
        else
            task.wait(0.01)
        end
    end
end

-- 4. BLATANT MODE BETA (Wild Spam)
local function blatantBetaFishing()
    while fishingActive and Config.FishingMode == "BlatantBeta" do
        if not isFishing then
            isFishing = true
            
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
            
            task.wait(Config.FishDelay * 0.7)
            
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

local function toggleCutscene(disabled)
    pcall(function()
        local cutscenes = LocalPlayer.PlayerGui:FindFirstChild("Cutscenes")
        if cutscenes then
            cutscenes.Enabled = not disabled
        end
    end)
end

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

local function toggleVFX(disabled)
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled = not disabled
            end
        end
    end)
end

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
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Fish It Hub",
    Icon = "rbxassetid://10723434711",
    Author = ".iqfareez",
    Folder = "FishItConfigFolder",
    Size = UDim2.fromOffset(600, 650),
    KeySystem = {
        Key = "FishIt2025",
        Note = "Join Discord for key",
        URL = "https://discord.gg/example",
        SaveKey = false
    },
    Transparent = false,
    Theme = "Dark",
    SideBarWidth = 170
})

-- ====== FISHING TAB ======
local FishTab = Window:Tab({
    Name = "Fishing",
    Icon = "rbxassetid://10723434711",
    Color = Color3.fromRGB(255, 0, 0)
})

local FishSection = FishTab:Section({
    Name = "Auto Fishing"
})

FishSection:Dropdown({
    Name = "Fishing Mode",
    Items = {"None", "Legit", "Instant", "Blatant", "BlatantBeta"},
    Callback = function(Item)
        Config.FishingMode = Item
        fishingActive = (Item ~= "None")
        
        if fishingActive then
            print("[Fishing] 🟢 Started: " .. Item)
            currentCatchCount = 0
            startFishing()
        else
            print("[Fishing] 🔴 Stopped")
            pcall(function() Events.unequip:FireServer() end)
        end
    end
})

FishSection:Toggle({
    Name = "Legit Shake Help",
    Value = Config.LegitShakeHelp,
    Callback = function(Value)
        Config.LegitShakeHelp = Value
    end
})

FishSection:Slider({
    Name = "Instant Complete Delay",
    Min = 0.1,
    Max = 2,
    Value = Config.InstantCompleteDelay,
    Format = function(Value)
        return Value .. "s"
    end,
    Callback = function(Value)
        Config.InstantCompleteDelay = Value
    end
})

FishSection:Slider({
    Name = "Blatant Target Notif",
    Min = 3,
    Max = 10,
    Value = Config.BlatantTargetNotif,
    Format = function(Value)
        return Value .. " notif"
    end,
    Callback = function(Value)
        Config.BlatantTargetNotif = Value
    end
})

local TimingSection = FishTab:Section({
    Name = "Timing Settings"
})

TimingSection:Slider({
    Name = "Fish Delay",
    Min = 0.1,
    Max = 5,
    Value = Config.FishDelay,
    Format = function(Value)
        return Value .. "s"
    end,
    Callback = function(Value)
        Config.FishDelay = Value
    end
})

TimingSection:Slider({
    Name = "Catch Delay",
    Min = 0.1,
    Max = 2,
    Value = Config.CatchDelay,
    Format = function(Value)
        return Value .. "s"
    end,
    Callback = function(Value)
        Config.CatchDelay = Value
    end
})

-- ====== WEBHOOK TAB ======
local WebhookTab = Window:Tab({
    Name = "Webhook",
    Icon = "rbxassetid://10747372992",
    Color = Color3.fromRGB(255, 170, 0)
})

local WebhookSection = WebhookTab:Section({
    Name = "Webhook Settings"
})

WebhookSection:Toggle({
    Name = "Enable Webhook",
    Value = Config.WebhookEnabled,
    Callback = function(Value)
        Config.WebhookEnabled = Value
    end
})

WebhookSection:TextField({
    Name = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(Value)
        Config.WebhookURL = Value
    end
})

WebhookSection:Dropdown({
    Name = "Minimum Rarity",
    Items = {"Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Callback = function(Item)
        Config.WebhookRarityFilter = Item
    end
})

-- ====== AUTO FAVORITE TAB ======
local FavoriteTab = Window:Tab({
    Name = "Auto Favorite",
    Icon = "rbxassetid://10734950309",
    Color = Color3.fromRGB(255, 255, 0)
})

local FavSection = FavoriteTab:Section({
    Name = "Favorite Settings"
})

FavSection:Toggle({
    Name = "Enable Auto Favorite",
    Value = Config.AutoFavorite,
    Callback = function(Value)
        Config.AutoFavorite = Value
    end
})

FavSection:Dropdown({
    Name = "Favorite Mode",
    Items = {"Rarity", "Name"},
    Callback = function(Item)
        Config.FavoriteMode = Item
    end
})

FavSection:Dropdown({
    Name = "Minimum Rarity",
    Items = {"Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Callback = function(Item)
        Config.FavoriteRarity = Item
    end
})

FavSection:Button({
    Name = "Favorite All Now",
    Callback = function()
        autoFavorite()
    end
})

-- ====== AUTO SELL TAB ======
local SellTab = Window:Tab({
    Name = "Auto Sell",
    Icon = "rbxassetid://10747372992",
    Color = Color3.fromRGB(0, 255, 0)
})

local SellSection = SellTab:Section({
    Name = "Sell Settings"
})

SellSection:Toggle({
    Name = "Enable Auto Sell",
    Value = Config.AutoSell,
    Callback = function(Value)
        Config.AutoSell = Value
    end
})

SellSection:Slider({
    Name = "Sell Threshold (%)",
    Min = 10,
    Max = 100,
    Value = Config.SellThreshold,
    Format = function(Value)
        return Value .. "%"
    end,
    Callback = function(Value)
        Config.SellThreshold = Value
    end
})

SellSection:Toggle({
    Name = "Keep Favorited",
    Value = Config.KeepFavorited,
    Callback = function(Value)
        Config.KeepFavorited = Value
    end
})

SellSection:Slider({
    Name = "Sell Check Delay",
    Min = 10,
    Max = 300,
    Value = Config.SellDelay,
    Format = function(Value)
        return Value .. "s"
    end,
    Callback = function(Value)
        Config.SellDelay = Value
    end
})

SellSection:Button({
    Name = "Sell All Now",
    Callback = function()
        local sellSuccess = pcall(function()
            return Events.sell:InvokeServer()
        end)
        if sellSuccess then
            print("[Manual Sell] ✅ Sold!")
        end
    end
})

-- ====== AUTO WEATHER TAB ======
local WeatherTab = Window:Tab({
    Name = "Auto Weather",
    Icon = "rbxassetid://10734950309",
    Color = Color3.fromRGB(0, 170, 255)
})

local WeatherSection = WeatherTab:Section({
    Name = "Weather Settings"
})

WeatherSection:Toggle({
    Name = "Enable Auto Buy Weather",
    Value = Config.AutoBuyWeather,
    Callback = function(Value)
        Config.AutoBuyWeather = Value
    end
})

WeatherSection:Toggle({
    Name = "Wind",
    Value = Config.WeatherWind,
    Callback = function(Value)
        Config.WeatherWind = Value
    end
})

WeatherSection:Toggle({
    Name = "Cloudy",
    Value = Config.WeatherCloudy,
    Callback = function(Value)
        Config.WeatherCloudy = Value
    end
})

WeatherSection:Toggle({
    Name = "Storm",
    Value = Config.WeatherStorm,
    Callback = function(Value)
        Config.WeatherStorm = Value
    end
})

-- ====== MISC TAB ======
local MiscTab = Window:Tab({
    Name = "Misc",
    Icon = "rbxassetid://10734950309",
    Color = Color3.fromRGB(170, 0, 255)
})

local PerfSection = MiscTab:Section({
    Name = "Performance"
})

PerfSection:Toggle({
    Name = "Boost FPS",
    Value = Config.BoostFPS,
    Callback = function(Value)
        Config.BoostFPS = Value
        toggleBoostFPS(Value)
    end
})

local VisualSection = MiscTab:Section({
    Name = "Visual Effects"
})

VisualSection:Toggle({
    Name = "Disable Cutscene",
    Value = Config.DisableCutscene,
    Callback = function(Value)
        Config.DisableCutscene = Value
        toggleCutscene(Value)
    end
})

VisualSection:Toggle({
    Name = "Disable Obtain Notification",
    Value = Config.DisableObtainNotif,
    Callback = function(Value)
        Config.DisableObtainNotif = Value
        toggleObtainNotif(Value)
    end
})

VisualSection:Toggle({
    Name = "Disable VFX",
    Value = Config.DisableVFX,
    Callback = function(Value)
        Config.DisableVFX = Value
        toggleVFX(Value)
    end
})

VisualSection:Toggle({
    Name = "Disable Fishing Effect",
    Value = Config.DisableFishingEffect,
    Callback = function(Value)
        Config.DisableFishingEffect = Value
        toggleFishingEffect(Value)
    end
})

VisualSection:Toggle({
    Name = "Disable Fishing Animation",
    Value = Config.DisableFishingAnimation,
    Callback = function(Value)
        Config.DisableFishingAnimation = Value
        toggleFishingAnimation(Value)
    end
})

VisualSection:Toggle({
    Name = "Disable Char Effect",
    Value = Config.DisableCharEffect,
    Callback = function(Value)
        Config.DisableCharEffect = Value
        toggleCharEffect(Value)
    end
})

-- ====== STARTUP ======
print("╔════════════════════════════════════════╗")
print("║   🎣 Fish It Advanced Hub V1.0        ║")
print("║   WindUI Edition - Ready to Fish!     ║")
print("╚════════════════════════════════════════╝")
