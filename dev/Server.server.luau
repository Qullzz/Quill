-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Quill = require(ReplicatedStorage.Quill)

-- // MAIN // --

local quill1 = Quill.Number.New(true, "server", "u8", 0)
local quill2 = Quill.Number.New(false, "client", "u8", 50)

quill1:Once(function(old_value, value)
    warn(`quill1: {old_value} -> {value}`)
    
    quill2(old_value)
end)

quill2:Once(function(old_value, value)
    warn(`quill2: {old_value} -> {value}`)
end)

print(quill1(50))
print(quill1() == quill2(quill1()))