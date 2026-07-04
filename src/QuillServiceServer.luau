-- // SERVICES // --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- // MODULES // --
local QuillProfileStore = require("./Dependencies/QuillProfileStore")
local QuillServiceTypes = require("./QuillServiceTypes")
local QuillServiceUtility = require("./QuillServiceUtility")
local QuillServiceNetwork = require("./QuillServiceNetwork")

-- // TYPES // --

type Profile = QuillProfileStore.Profile<{ ID: number, Data: buffer }>

-- // MAIN // --

local Module = {
    Properties = {} :: QuillServiceTypes.Properties,
    PlayersData = {} :: QuillServiceTypes.PlayersData,
    LoadedPlayers = {} :: { Player },
    Store = {} :: QuillProfileStore.ProfileStore<{ ID: number, Data: buffer }>,
    Profiles = {} :: { [Player]: Profile }
}

-- ## PRIVATE ## --

local function GetProfileKeyFromPlayer(player: Player)
    return tostring(player.UserId)
end

local function GetPlayerDataTemplateDeltas(template: QuillServiceTypes.PlayerData, data: QuillServiceTypes.PlayerData)
    local result = {}
    
    for key, quill in data do
        local template_quill = template[key]
        
        if not template_quill then continue end
        
        if quill == template_quill then continue end
        
        result[key] = quill()
    end
    
    return result
end

-- ## PUBLIC ## --

function Module.RegisterPlayer(self: Module, player: Player, profile: Profile)
    self.Profiles[player] = profile
    
    local template = self:GetTemplateFromID(profile.Data.ID)
    
    local data = QuillServiceUtility.DeserializePlayerData(template, profile.Data.Data)
    local deltas = GetPlayerDataTemplateDeltas(template, self.PlayersData[player])
    
    for key, value in deltas do
        local quill = data[key]
        
        if not quill then continue end
        
        quill(value)
    end
    
    self:SetPlayerData(player, data)
end

function Module.UnregisterPlayer(self: Module, player: Player)
    self.Profiles[player] = nil
    
    self:SetPlayerData(player, nil)
end

function Module.PlayerAdded(self: Module, player: Player)
    local key = GetProfileKeyFromPlayer(player)
    
    if self.Properties.reset then
        self.Store:RemoveAsync(key)
    end
    
    local profile = (
        self.Properties.mock and self.Store.Mock or self.Store
    ):StartSessionAsync(key, {
        Cancel = function()
            return player.Parent ~= Players
        end
    })
    
    if not profile then
        player:Kick("Failed to load profile")
        
        return
    end
    
    profile.OnSave:Connect(function()
        profile.Data.ID = self.Properties.id
        profile.Data.Data = QuillServiceUtility.SerializePlayerData(self.PlayersData[player])
    end)
    
    profile.OnSessionEnd:Connect(function()
        self:UnregisterPlayer(player)
        
        player:Kick("Session ended")
    end)
    
    profile:AddUserId(player.UserId)
    
    profile:Reconcile()
    
    self:RegisterPlayer(player, profile)
    
    self:BindPlayerDataReplication(player)
    
    QuillServiceNetwork.ProfileAdded.sendToList({
        userID = player.UserId,
        data = QuillServiceUtility.SerializePlayerData(self.PlayersData[player])
    }, self.LoadedPlayers)
    
    for thisPlayer, thisData in self.PlayersData do
        
        if thisPlayer == player then continue end
        
        QuillServiceNetwork.ProfileAdded.sendTo({
            userID = thisPlayer.UserId,
            data = QuillServiceUtility.SerializePlayerData(thisData)
        }, player)
    end
end

function Module.PlayerRemoving(self: Module, player: Player)
    table.remove(self.LoadedPlayers, table.find(self.LoadedPlayers, player))
    
    QuillServiceNetwork.ProfileRemoved.sendToList(player.UserId, self.LoadedPlayers)
end

function Module.BindPlayerDataReplication(self: Module, player: Player)
    local data = self.PlayersData[player]
    
    local schema = QuillServiceUtility.GetTemplateSchema(data)
    
    for index, value in schema do
        local quill = value.quill
        
        quill:Connect(function(_, _, value, replicate)
            
            if not quill.auto_replicate and not replicate then return end
            
            if quill.authority == "server" then
                QuillServiceNetwork.QuillChangedServer.sendToList({
                    userID = player.UserId,
                    index = index,
                    data = quill:Serialize()
                }, self.LoadedPlayers)
            else
                QuillServiceNetwork.QuillChangedServer.sendFiltered({
                    userID = player.UserId,
                    index = index,
                    data = quill:Serialize()
                }, function(thisPlayer)
                    return thisPlayer ~= player and table.find(self.LoadedPlayers, thisPlayer)
                end)
            end
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

function Module.GetTemplateFromID(self: Module, id: QuillServiceTypes.PlayerDataID): QuillServiceTypes.PlayerData
    local result
    
    if id == self.Properties.id then
        result = self.Properties.templates.current_template
    else
        for _, template in self.Properties.templates.old_templates do
            
            if id ~= template.id then continue end
            
            result = template.template
            
            break
        end
    end
    
    assert(typeof(result) == "table", `Missing template. <ID: {id}>`)
    
    return result
end

function Module.Init(self: Module, properties: QuillServiceTypes.Properties): QuillServiceTypes.PlayersData
    self.Properties = properties
    self.Store = QuillProfileStore.New(
        (typeof(self.Properties.environment) == "string" and self.Properties.environment) or (RunService:IsStudio() and "Dev" or "Live"),
        {
            ID = self.Properties.id,
            Data = QuillServiceUtility.SerializePlayerData(self.Properties.templates.current_template)
        }
    )
    
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
    
    Players.PlayerRemoving:Connect(function(player)
        self:PlayerRemoving(player)
    end)
    
    QuillServiceNetwork.PlayerLoaded.listen(function(_, player)
        
        if not player then return end
        
        table.insert(self.LoadedPlayers, player)
        
        self:PlayerAdded(player)
    end)
    
    QuillServiceNetwork.QuillChangedClient.listen(function(_data, player)
        
        if not player then return end
        
        local data = self.PlayersData[player]
        
        local schema = QuillServiceUtility.GetTemplateSchema(data)
        
        local value = schema[_data.index]
        
        if not value or value.quill.authority ~= "client" then return end
        
        value.quill(value.quill:Deserialize(_data.data))
    end)
    
    return self.PlayersData
end

type Module = typeof(Module)

return Module :: Module