-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)

-- // MAIN // --

local data = Data[Players.PlayerAdded:Wait()]

data.rank:Once(function()
    warn("ADDED RANK:", data.rank())
end)

data:Wait()

print("Data loaded:", data)

data:Do(function(data)
    data:Wait()
    warn("Data loaded", data)
    
    while task.wait(math.random(2, 3)) do
        print(data.rank(math.random(0, 100), false))
    end
end)