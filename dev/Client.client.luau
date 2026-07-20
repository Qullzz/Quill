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

if not data:Wait() then return end

print("Data loaded:", data)

data:Do(function(data)
    data:Wait() -- Won't yield since it's already loaded
    warn("Data loaded", data)
end)