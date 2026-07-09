-- // SERVICES // --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- // MODULES // --
local QuillProfileStore = require("./Dependencies/QuillProfileStore")
local QuillServiceTypes = require("./QuillServiceTypes")
local QuillServiceUtility = require("./QuillServiceUtility")
local QuillServiceNetwork = require("./QuillServiceNetwork")
local QuillSignal = require("./Dependencies/QuillSignal")

-- // TYPES // --

type ProfileData = { ID: number, Data: buffer }
type Profile = QuillProfileStore.Profile<ProfileData>

-- // MAIN // --

local Module = {
    Properties = {} :: QuillServiceTypes.Properties,
    PlayersData = {} :: QuillServiceTypes.PlayersData,
    LoadedPlayers = {} :: { Player },
    LoadedProfiles = {} :: { Player },
    Store = {} :: QuillProfileStore.ProfileStore<ProfileData>,
    Profiles = {} :: { [Player]: Profile },
    
    ProfileAdded = QuillSignal.new() :: QuillSignal.ScriptSignal<Player>,
    ProfileRemoved = QuillSignal.new() :: QuillSignal.ScriptSignal<Player>
}

local PlayerDataModule = {}
PlayerDataModule.__index = PlayerDataModule

-- ## PRIVATE ## --

function PlayerDataModule.Do(self: QuillServiceTypes.PlayerData, callback: ( QuillServiceTypes.PlayerData ) -> ()): ()
    local player: Player
    
    for thisPlayer, data in pairs(Module.PlayersData) do
        
        if data ~= self then continue end
        
        player = thisPlayer
    end
    
    assert(
        typeof(player) == "Instance" and player:IsA("Player"),
        `Attempted to call :Do() on a non-registered PlayerData`
    )
    
    if table.find(Module.LoadedProfiles, player) then
        callback(Module.PlayersData[player])
    else
        local profileAddedConnection
        local profileRemovedConnection
        
        profileAddedConnection = Module.ProfileAdded:Connect(function(thisPlayer)
            
            if thisPlayer ~= player then return end
            
            if profileAddedConnection then profileAddedConnection:Disconnect() end
            if profileRemovedConnection then profileRemovedConnection:Disconnect() end
            
            callback(Module.PlayersData[player])
        end)
        
        profileRemovedConnection = Module.ProfileRemoved:Connect(function(thisPlayer)
            
            if thisPlayer ~= player then return end
            
            if profileAddedConnection then profileAddedConnection:Disconnect() end
            if profileRemovedConnection then profileRemovedConnection:Disconnect() end
        end)
    end
end

function PlayerDataModule.Wait(self: QuillServiceTypes.PlayerData): QuillServiceTypes.PlayerData
    local player: Player
    
    for thisPlayer, data in pairs(Module.PlayersData) do
        
        if data ~= self then continue end
        
        player = thisPlayer
    end
    
    assert(
        typeof(player) == "Instance" and player:IsA("Player"),
        `Attempted to call :Wait() on a non-registered PlayerData`
    )
    
    if table.find(Module.LoadedProfiles, player) then
        return Module.PlayersData[player]
    else
        local thread = coroutine.running()
        
        local profileAddedConnection
        local profileRemovedConnection
        
        profileAddedConnection = Module.ProfileAdded:Connect(function(thisPlayer)
            
            if thisPlayer ~= player then return end
            
            if profileAddedConnection then profileAddedConnection:Disconnect() end
            if profileRemovedConnection then profileRemovedConnection:Disconnect() end
            
            coroutine.resume(thread, Module.PlayersData[player])
        end)
        
        profileRemovedConnection = Module.ProfileRemoved:Connect(function(thisPlayer)
            
            if thisPlayer ~= player then return end
            
            if profileAddedConnection then profileAddedConnection:Disconnect() end
            if profileRemovedConnection then profileRemovedConnection:Disconnect() end
            
            coroutine.resume(thread, nil)
        end)
        
        return coroutine.yield(thread)
    end
end

function GetProfileKeyFromPlayer(player: Player)
    return tostring(player.UserId)
end

function GetPlayerDataTemplateDeltas(template: QuillServiceTypes.PlayerData, data: QuillServiceTypes.PlayerData)
    local result = {}
    
    for key, quill in pairs(data) do
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
    
    table.insert(self.LoadedProfiles, player)
    
    local template = self:GetTemplateFromID(profile.Data.ID)
    
    local data = QuillServiceUtility.DeserializePlayerData(template, profile.Data.Data)
    local deltas = GetPlayerDataTemplateDeltas(template, self.PlayersData[player])
    
    for key, value in pairs(deltas) do
        local quill = data[key]
        
        if not quill then continue end
        
        quill(value)
    end
    
    self:SetPlayerData(player, data)
    
    self.ProfileAdded:Fire(player)
end

function Module.UnregisterPlayer(self: Module, player: Player)
    self.Profiles[player] = nil
    
    table.remove(self.LoadedProfiles, table.find(self.LoadedProfiles, player))
    
    self:SetPlayerData(player, nil)
    
    self.ProfileRemoved:Fire(player)
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
        profile.Data.ID = self:GetTemplateID(self.Properties.templates.current_template)
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
    
    for thisPlayer, thisData in pairs(self.PlayersData) do
        
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
    
    for index, value in ipairs(schema) do
        local quill = value.quill
        
        quill:Connect(function(_, _, value, replicate)
            
            if not (
                if typeof(replicate) == "boolean" then replicate
                else quill.auto_replicate
            ) then return end
            
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
            for key, current_quill in pairs(current_data) do
                local quill = data[key]
                
                if not quill or not current_quill:TypeEqual(quill) or current_quill == quill then continue end
                
                current_quill(quill())
            end
        else
            self.PlayersData[player] = setmetatable(data, PlayerDataModule) :: any
        end
    else
        self.PlayersData[player] = nil
    end
end

function Module.GetTemplateID(self: Module, template: QuillServiceTypes.PlayerData): QuillServiceTypes.PlayerDataID
    local result: number?
    
    if template == self.Properties.templates.current_template then
        result = #self.Properties.templates.previous_templates
    else
        for index, thisTempalte in self.Properties.templates.previous_templates do
            
            if template ~= thisTempalte then continue end
            
            result = ( index - 1 )
            
            break
        end
    end
    
    assert(typeof(result) == "number", `No ID was found for a template. <template: {template}>`)
    
    result = math.clamp(-(2^53 - 1) + result, -(2^53 - 1), 2^53 - 1)
    
    return result
end

function Module.GetTemplateFromID(self: Module, id: QuillServiceTypes.PlayerDataID): QuillServiceTypes.PlayerData
    local result
    
    if id == self:GetTemplateID(self.Properties.templates.current_template) then
        result = self.Properties.templates.current_template
    else
        for _, template in ipairs(self.Properties.templates.previous_templates) do
            
            if id ~= self:GetTemplateID(template) then continue end
            
            result = template
            
            break
        end
    end
    
    assert(typeof(result) == "table", `Missing template. <ID: {id}>`)
    
    return result
end

function Module.Init(self: Module, properties: QuillServiceTypes.Properties): QuillServiceTypes.PlayersData
    self.Properties = properties
    print(self:GetTemplateID(self.Properties.templates.current_template))
    self.Store = QuillProfileStore.New(
        (typeof(self.Properties.environment) == "string" and self.Properties.environment) or (RunService:IsStudio() and "Dev" or "Live"),
        {
            ID = self:GetTemplateID(self.Properties.templates.current_template),
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
        
        value.quill(value.quill:Deserialize(_data.data), _data.replicate)
    end)
    
    return self.PlayersData
end

type Module = typeof(Module)

return Module :: Module