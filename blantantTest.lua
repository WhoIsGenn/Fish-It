local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

-- ============================
-- UI
-- ============================

local Window = WindUI:CreateWindow({
    Title = "Victoria Hub",
    Icon = "rbxassetid://71947103252559",
    Author = "Premium | Fish It",
    Folder = "VICTORIA_HUB",
    Size = UDim2.fromOffset(260, 290),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,                                                             
})

Window:EditOpenButton({
    Title = "Victoria Hub",
    Icon = "rbxassetid://71947103252559",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("#00fbff"), 
        Color3.fromHex("#ffffff")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

Window:Tag({
    Title = "VBLANTANT",
    Color = Color3.fromRGB(255, 255, 255),
    Radius = 17,
})

local executorName = "Unknown"
if identifyexecutor then
    executorName = identifyexecutor()
elseif getexecutorname then
    executorName = getexecutorname()
elseif executor then
    executorName = executor
end

-- Pilih warna berdasarkan executor
local executorColor = Color3.fromRGB(200, 200, 200) -- Default (abu-abu)

if executorName:lower():find("flux") then
    executorColor = Color3.fromHex("#30ff6a")     -- Fluxus
elseif executorName:lower():find("delta") then
    executorColor = Color3.fromHex("#38b6ff")     -- Delta
elseif executorName:lower():find("arceus") then
    executorColor = Color3.fromHex("#a03cff")     -- Arceus X
elseif executorName:lower():find("krampus") or executorName:lower():find("oxygen") then
    executorColor = Color3.fromHex("#ff3838")     -- Krampus / Oxygen
elseif executorName:lower():find("volcano") then
    executorColor = Color3.fromHex("#ff8c00")     -- Volcano
elseif executorName:lower():find("synapse") or executorName:lower():find("script") or executorName:lower():find("krypton") then
    executorColor = Color3.fromHex("#ffd700")     -- Synapse / Script-Ware / Krypton
elseif executorName:lower():find("wave") then
    executorColor = Color3.fromHex("#00e5ff")     -- Wave
elseif executorName:lower():find("zenith") then
    executorColor = Color3.fromHex("#ff00ff")     -- Zenith
elseif executorName:lower():find("seliware") then
    executorColor = Color3.fromHex("#00ffa2")     -- Seliware
elseif executorName:lower():find("krnl") then
    executorColor = Color3.fromHex("#1e90ff")     -- KRNL
elseif executorName:lower():find("trigon") then
    executorColor = Color3.fromHex("#ff007f")     -- Trigon
elseif executorName:lower():find("nihon") then
    executorColor = Color3.fromHex("#8a2be2")     -- Nihon
elseif executorName:lower():find("celery") then
    executorColor = Color3.fromHex("#4caf50")     -- Celery
elseif executorName:lower():find("lunar") then
    executorColor = Color3.fromHex("#8080ff")     -- Lunar
elseif executorName:lower():find("valyse") then
    executorColor = Color3.fromHex("#ff1493")     -- Valyse
elseif executorName:lower():find("vega") then
    executorColor = Color3.fromHex("#4682b4")     -- Vega X
elseif executorName:lower():find("electron") then
    executorColor = Color3.fromHex("#7fffd4")     -- Electron
elseif executorName:lower():find("awp") then
    executorColor = Color3.fromHex("#ff005e") -- AWP (merah neon ke pink)
elseif executorName:lower():find("bunni") or executorName:lower():find("bunni.lol") then
    executorColor = Color3.fromHex("#ff69b4") -- Bunni.lol (Hot Pink / Neon Pink)
end

-- Buat Tag UI
local TagUI = Window:Tag({
    Title = "EXECUTOR | " .. tostring(executorName),
    Icon = "github",
    Color = executorColor,
    Radius = 0
})

local Dialog = Window:Dialog({
    Icon = "circle-plus",
    Title = "Join Discord",
    Content = "For Update",
    Buttons = {
        {
            Title = "Copy Discord",
            Callback = function()
                if setclipboard then
                    setclipboard("https://discord.gg/fjafFyYKj")
                    
                    -- Notify jika berhasil
                    WindUI:Notify({
                        Title = "Copied Successfully!",
                        Content = "The Discord link has been copied to the clipboard.",
                        Duration = 3,
                        Icon = "check"
                    })
                else
                    -- Notify jika executor tidak support
                    WindUI:Notify({
                        Title = "Fail!",
                        Content = "Your executor does not support the auto-copy command.",
                        Duration = 3,
                        Icon = "x"
                    })
                end
            end,
        },
        {
            Title = "No",
            Callback = function()
                WindUI:Notify({
                    Title = "Canceled",
                    Content = "You cancel the action.",
                    Duration = 3,
                    Icon = "x"
                })
            end,
        },
    },
})

WindUI:Notify({
    Title = "Victoria Hub Loaded",
    Content = "UI loaded successfully!",
    Duration = 3,
    Icon = "bell",
})

local Tab0 = Window:Tab({
    Title = "Blantant Featured BETA",
    Icon = "star",
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local c={d=false,e=1.6,f=0.37}

local g=ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local h,i,j,k,l
pcall(function()
    h=g:WaitForChild("RF/ChargeFishingRod")
    i=g:WaitForChild("RF/RequestFishingMinigameStarted")
    j=g:WaitForChild("RE/FishingCompleted")
    k=g:WaitForChild("RE/EquipToolFromHotbar")
    l=g:WaitForChild("RF/CancelFishingInputs")
end)

local m=nil
local n=nil
local o=nil

local function p()
    task.spawn(function()
        pcall(function()
            local q,r=l:InvokeServer()
            if not q then
                while not q do
                    local s=l:InvokeServer()
                    if s then break end
                    task.wait(0.05)
                end
            end

            local t,u=h:InvokeServer(math.huge)
            if not t then
                while not t do
                    local v=h:InvokeServer(math.huge)
                    if v then break end
                    task.wait(0.05)
                end
            end

            i:InvokeServer(-139.63,0.996)
        end)
    end)

    task.spawn(function()
        task.wait(c.f)
        if c.d then
            pcall(j.FireServer,j)
        end
    end)
end

local function w()
    n=task.spawn(function()
        while c.d do
            pcall(k.FireServer,k,1)
            task.wait(1.5)
        end
    end)

    while c.d do
        p()
        task.wait(c.e)
        if not c.d then break end
        task.wait(0.1)
    end
end

local function x(y)
    c.d=y
    if y then
        if m then task.cancel(m) end
        if n then task.cancel(n) end
        m=task.spawn(w)
    else
        if m then task.cancel(m) end
        if n then task.cancel(n) end
        m=nil
        n=nil
        pcall(l.InvokeServer,l)
    end
end

netFolder = ReplicatedStorage:WaitForChild('Packages')
    :WaitForChild('_Index')
    :WaitForChild('sleitnick_net@0.2.0')
    :WaitForChild('net')
Remotes = {}
Remotes.RF_RequestFishingMinigameStarted = netFolder:WaitForChild("RF/RequestFishingMinigameStarted")
Remotes.RF_ChargeFishingRod = netFolder:WaitForChild("RF/ChargeFishingRod")
Remotes.RF_CancelFising = netFolder:WaitForChild('RF/CancelFishingInputs')
Remotes.RF_CancelFishing = netFolder:WaitForChild("RF/CancelFishingInputs")
Remotes.chargeRod = netFolder:WaitForChild('RF/ChargeFishingRod')
Remotes.RE_FishingCompleted = netFolder:WaitForChild("RE/FishingCompleted")
Remotes.RF_AutoFish = netFolder:WaitForChild("RF/UpdateAutoFishingState")

toggleState = {
    autoFishing = false,
    blatantRunning = false,
}

FishingController = require(
    ReplicatedStorage:WaitForChild('Controllers')
        :WaitForChild('FishingController')
)

local oldCharge = FishingController.RequestChargeFishingRod
FishingController.RequestChargeFishingRod = function(...)
    if toggleState.blatantRunning or toggleState.autoFishing then
        return
    end
	return oldCharge(...)
end

local isAutoRunning = false

local isSuperInstantRunning = false
_G.ReelSuper = 1.15
     toggleState.completeDelays = 0.30
     toggleState.delayStart = 0.2
    local function autoEquipSuper()
        local success, err = pcall(function()
            Remotes.RE_EquipTool:FireServer(1)
        end)
        if success then
        end
    end

    local function superInstantFishingCycle()
        task.spawn(function()
            Remotes.RF_CancelFishing:InvokeServer()
            Remotes.RF_ChargeFishingRod:InvokeServer(tick())
            Remotes.RF_RequestFishingMinigameStarted:InvokeServer(-139.63796997070312, 0.9964792798079721)
            task.wait(toggleState.completeDelays)
            Remotes.RE_FishingCompleted:FireServer()
        end)
    end

    local function doSuperFishingFlow()
        superInstantFishingCycle()
    end

local function startSuperInstantFishing()
    if isSuperInstantRunning then return end
    isSuperInstantRunning = true

    task.spawn(function()
        while isSuperInstantRunning do
            superInstantFishingCycle()
            task.wait(math.max(_G.ReelSuper, 0.1))
        end
    end)
end

    local function stopSuperInstantFishing()
        isSuperInstantRunning = false
        print('Super Instant Fishing stopped')
    end
  
blantant = Tab0:Section({ 
    Title = "Blantant X8 | Recomended",
    Icon = "fish",
    TextTransparency = 0.05,
    TextXAlignment = "Left",
    TextSize = 17,
})

blantant:Toggle({
    Title = "Blatant Mode",
    Value = toggleState.blatantRunning,
    Callback = function(value)
        toggleState.blatantRunning = value
        Remotes.RF_AutoFish:InvokeServer(value)

        if value then
            startSuperInstantFishing()
        else
            stopSuperInstantFishing()
        end
    end
})

blantant:Input({
    Title = "Reel Delay",
    Placeholder = "Delay (seconds)",
    Default = tostring(_G.ReelSuper),
    Callback = function(input)
        local num = tonumber(input)
        if num and num >= 0 then
            _G.ReelSuper = num
            print("ReelSuper updated to:", num)
        end
    end
})

blantant:Input({
    Title = "Custom Complete Delay",
    Placeholder = "Delay (seconds)",
    Default = tostring(toggleState.completeDelays),
    Callback = function(input)
        local num = tonumber(input)
        if num and num > 0 then
            toggleState.completeDelays = num
        end
    end
})
