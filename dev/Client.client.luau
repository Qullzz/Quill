-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)

-- // MAIN // --

local data = Data[Players.LocalPlayer]

data.rank:Connect(function()
    warn("ADDED RANK:", data.rank())
end)

data:Wait()

print("Data loaded:", data)

data:Do(function(data)
    data:Wait()
    warn("Data loaded", data)
end)