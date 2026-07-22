-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)

-- // MAIN // --

local data = Data[Players.LocalPlayer]

if not data:Wait() then return end -- Waits until data loads, returns nil if the Player leaves before it does so.

print("Data loaded:", data)

data:Do(function(data)
    data:Wait() -- Won't yield since it's already loaded
    warn("Data loaded:", data)
end)