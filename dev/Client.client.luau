-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)

-- // MAIN // --

local data = Data[Players.LocalPlayer]

-- data.rank:Connect(function(rank)
--     warn("SET RANK:", rank)
-- end)

data:Wait()

print("Data loaded:", data)

data:Do(function(data)
    data:Wait() -- This won't yield since it's already loaded
    warn("Data loaded", data)
end)