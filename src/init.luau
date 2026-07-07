-- // SERVICES // --
local RunService = game:GetService("RunService")

-- // MODULES // --
local QuillServiceTypes = require(script.QuillServiceTypes)

-- // TYPES // --

type PlayersData<T> = typeof(setmetatable({} :: QuillServiceTypes.PlayersData<T>, {} :: {
    __call: ( self: QuillServiceTypes.PlayersData<T>, player: Player, callback: (( data: QuillServiceTypes.PlayerData<T> ) -> QuillServiceTypes.PlayerData<T>)? ) -> ()
})) & ( player: Player, callback: (( data: QuillServiceTypes.PlayerData<T> ) -> ())? ) -> QuillServiceTypes.PlayerData<T>

-- // MAIN // --

return {
    Number = require("@self/QuillComponents/QuillNumber"),
    
    --[[
    Initializes Quill, returning players data
    ]]
    Init = function<T>(properties: QuillServiceTypes.Properties<T>): PlayersData<T>
        return (RunService:IsServer() and require("@self/QuillServiceServer"):Init(properties) or require("@self/QuillServiceClient"):Init(properties)) :: any
    end
}