-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)

-- // MAIN // --

local data = Data[game:GetService("Players").LocalPlayer]

data.rank:Connect(function(_, prev_rank, rank)
    warn(`{prev_rank} -> {rank}`)
end)