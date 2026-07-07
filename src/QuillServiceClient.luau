-- // SERVICES // --
local Players = game:GetService("Players")

-- // MODULES // --
local QuillServiceTypes = require("./QuillServiceTypes")
local QuillServiceUtility = require("./QuillServiceUtility")
local QuillServiceNetwork = require("./QuillServiceNetwork")
local QuillSignal = require("./Dependencies/QuillSignal")

-- // MAIN // --

local Module = {
    Properties = {} :: QuillServiceTypes.Properties,
    PlayersData = {} :: QuillServiceTypes.PlayersData,
    LoadedProfiles = {} :: { Player },
    
    ProfileAdded = QuillSignal.new() :: QuillSignal.ScriptSignal<Player>,
    ProfileRemoved = QuillSignal.new() :: QuillSignal.ScriptSignal<Player>
}

-- ## PRIVATE ## --

-- ## PUBLIC ## --

function Module.BindPlayerDataReplication(self: Module, player: Player)
    local data = self.PlayersData[player]
    
    local schema = QuillServiceUtility.GetTemplateSchema(data)
    
    for index, value in ipairs(schema) do
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
            for key, current_quill in pairs(current_data) do
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
        __call = function(_, player: Player, callback: ( data: QuillServiceTypes.PlayerData ) -> ())
            if table.find(self.LoadedProfiles, player) then
                callback(self.PlayersData[player])
            else
                local connection
                
                connection = self.ProfileAdded:Connect(function(thisPlayer: Player)
                    
                    if thisPlayer ~= player then return end
                    
                    callback(self.PlayersData[player])
                    
                    connection:Disconnect()
                end)
            end
        end,
        
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
        
        if not player then return end
        
        local data = QuillServiceUtility.DeserializePlayerData(self.Properties.templates.current_template, _data.data)
        
        self:SetPlayerData(player, data)
        
        table.insert(self.LoadedProfiles, player)
        
        self.ProfileAdded:Fire(player)
        
        self:BindPlayerDataReplication(player)
    end)
    
    QuillServiceNetwork.ProfileRemoved.listen(function(userID)
        local player = Players:GetPlayerByUserId(userID)
        
        if not player then return end
        
        self:SetPlayerData(player, nil)
        
        table.remove(self.LoadedProfiles, table.find(self.LoadedProfiles, player))
        
        self.ProfileRemoved:Fire(player)
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