-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)

-- // MAIN // --

Data(game:GetService("Players").PlayerAdded:Wait(), function(data)
    print("Data loaded:", data)
end)

-- local data = Data(game:GetService("Players").PlayerAdded:Wait())

-- data.rank:Connect(function(_, prev_rank, rank)
--     warn(`{prev_rank} -> {rank}`)
-- end)

-- while task.wait(math.random(2, 3)) do
--     data.rank(math.random(0, 100))
-- end