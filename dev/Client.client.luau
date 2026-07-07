-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)

-- // MAIN // --

Data(game:GetService("Players").LocalPlayer, function(data)
    print("Data loaded:", data)
end)

-- local data = Data[game:GetService("Players").LocalPlayer]

-- data.rank:Connect(function(_, prev_rank, rank)
--     warn(`{prev_rank} -> {rank}`)
-- end)