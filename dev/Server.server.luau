-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES // --
local Data = require(ReplicatedStorage.Data)
local Quill = require(ReplicatedStorage.Quill)

-- // MAIN // --

Data[Players.PlayerAdded:Wait()]:Do(function(data)
    data.inventory:Connect(function(value, prevValue)
        warn(value, prevValue)
    end)
    
    while task.wait(2) do
        data.inventory:Append(data.inventory.component:Clone())
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