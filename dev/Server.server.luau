-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local QuillNumber = require(ReplicatedStorage.Quill.QuillNumber)

-- // MAIN // --

local quill1 = QuillNumber.New(true, "server", "u8", 0)
local quill2 = QuillNumber.New(false, "client", "u8", 50)

quill1(function(disconnect, old_value, value)
    warn(`quill1: {old_value} -> {value}`)
    
    quill2(old_value)
    
    disconnect()
end)

quill2(function(disconnect, old_value, value)
    warn(`quill2: {old_value} -> {value}`)
end)

print(quill1(50))
print(quill1() == quill2(quill1()))