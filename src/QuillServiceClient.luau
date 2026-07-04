-- // SERVICES // --
local Players = game:GetService("Players")

-- // MODULES // --
local QuillServiceTypes = require("./QuillServiceTypes")
local QuillServiceUtility = require("./QuillServiceUtility")
local QuillServiceNetwork = require("./QuillServiceNetwork")

-- // MAIN // --

local Module = {
    Properties = {} :: QuillServiceTypes.Properties,
    PlayersData = {} :: QuillServiceTypes.PlayersData
}

-- ## PRIVATE ## --

-- ## PUBLIC ## --

function Module.BindPlayerDataReplication(self: Module, player: Player)
    local data = self.PlayersData[player]
    
    local schema = QuillServiceUtility.GetTemplateSchema(data)
    
    for index, value in schema do
        local quill = value.quill
        
        quill:Connect(function(_, _, value, replicate)
            
            if quill.authority ~= "client" then return end
            
            QuillServiceNetwork.QuillChangedClient.send({
                index = index,
                data = quill:Serialize()
            })
        end)
    end
end

function Module.SetPlayerData(self: Module, player: Player, data: QuillServiceTypes.PlayerData?)
    if typeof(data) == "table" then
        local current_data = rawget(self.PlayersData, player)
        
        if current_data then
            for key, current_quill in current_data do
                local quill = data[key]
                
                if not quill or not current_quill:TypeEqual(quill) or current_quill == quill then continue end
                
                current_quill(quill())
            end
        else
            self.PlayersData[player] = data
        end
    else
        self.PlayersData[player] = nil
    end
end

function Module.Init(self: Module, properties: QuillServiceTypes.Properties): QuillServiceTypes.PlayersData
    self.Properties = properties
    
    setmetatable(self.PlayersData, {
        __index = function(_, player: Player)
            assert(
                typeof(player) == "Instance" and player:IsA("Player"),
                `[{script.Name}]: Attempted to index PlayersData with a non-player key. <key: {typeof(player)}, trace: {debug.traceback()}>`
            )
            
            local data = QuillServiceUtility.CopyTemplate(self.Properties.templates.current_template)
            
            self:SetPlayerData(player, data)
            
            return data
        end
    })
    
    QuillServiceNetwork.ProfileAdded.listen(function(_data)
        local player = Players:GetPlayerByUserId(_data.userID)
        
        local data = QuillServiceUtility.DeserializePlayerData(self.Properties.templates.current_template, _data.data)
        
        self:BindPlayerDataReplication(player)
        
        self:SetPlayerData(player, data)
    end)
    
    QuillServiceNetwork.ProfileRemoved.listen(function(userID)
        local player = Players:GetPlayerByUserId(userID)
        
        if not player then return end
        
        self:SetPlayerData(player, nil)
    end)
    
    QuillServiceNetwork.QuillChangedServer.listen(function(_data)
        local player = Players:GetPlayerByUserId(_data.userID)
        
        if not player then return end
        
        local data = self.PlayersData[player]
        
        local schema = QuillServiceUtility.GetTemplateSchema(data)
        
        local value = schema[_data.index]
        
        if not value then return end
        
        value.quill(value.quill:Deserialize(_data.data))
    end)
    
    QuillServiceNetwork.PlayerLoaded.send()
    
    return self.PlayersData
end

type Module = typeof(Module)

return Module :: Module