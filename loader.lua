-- Tunggu game load dulu
if not game:IsLoaded() then 
    game.Loaded:Wait() 
end
task.wait(1.2)

-- Load WindUI dulu
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"
))()

-- Load Fish-it dan PASS WindUI sebagai parameter
local FishIt = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/WhoIsGenn/Fish-it/main/main.lua"
))()

-- Panggil FishIt dengan memberikan WindUI
FishIt(WindUI)
