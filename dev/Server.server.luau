-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)

-- // MAIN // --

local data = Data[Players.PlayerAdded:Wait()]

data.inventory:Connect(function(value, prevValue)
    print(`Changed inventory:`, prevValue, "->", value)
end)

data:Do(function(data)
    -- print(data.inventory())
    
    -- data.inventory:Map(function(component)
    --     component(math.random(1, 2))
        
    --     return component
    -- end)
    
    -- warn(data.inventory())
    
    while task.wait(2) do
        data.inventory:Append(math.random(0, 255))
    end
end)

-- data.inventory:Connect(function(value, prev_value)
--     print(`Changed inventory`, prev_value, value)
-- end)

-- data:Do(function(data)
--     while task.wait(2) do
--         table.insert(data.inventory(), Quill.Number.New(true, "server", "u8", 0))
        
--         data.inventory(data.inventory())
--     end
-- end)

-- data.rank:Once(function(rank)
--     warn("SET RANK:", rank)
-- end)

-- if not data:Wait() then return end

-- print("Data loaded:", data)

-- data:Do(function(data)
--     data:Wait() -- This won't yield since it's already loaded
--     warn("Data loaded", data)
    
--     while task.wait(math.random(2, 3)) do
--         local inventory = data.inventory()
        
--         table.insert(inventory, Quill.Number.New(true, "server", "u8", 0))
        
--         data.inventory(inventory)
--     end
-- end)