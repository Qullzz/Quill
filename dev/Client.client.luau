-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)

-- // MAIN // --

local data = Data[game:GetService("Players").LocalPlayer]

data.level:Connect(function(_, prev_level, level)
    warn(`{prev_level} -> {level}`)
end)