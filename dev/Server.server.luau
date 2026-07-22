-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)

-- // MAIN // --

local data = Data[Players.PlayerAdded:Wait()]

data.rank:Connect(function(rank, prevRank)
    warn(`Changed rank: {prevRank} -> {rank}`)
end)

data:Do(function(data)
    print("Current Data:", data)
    
    print(`Current rank: {data.rank()}`)
    
    data.rank(data.rank() + 1)
end)