-- // SERVICES // --
local RunService = game:GetService("RunService")

-- // MODULES // --
local QuillServiceTypes = require(script.QuillServiceTypes)

-- // TYPES // --

type PlayersData<T> = QuillServiceTypes.PlayersData<T & {
    --[[
    Calls the callback the moment the player's data is loaded, passing it as an argument
    ]]
    Do: ( self: QuillServiceTypes.PlayerData<T>, callback: ( data: QuillServiceTypes.PlayerData<T> ) -> () ) -> (),
    --[[
    Yields the current thread until the player's data is loaded
    ]]
    Wait: ( self: QuillServiceTypes.PlayerData<T> ) -> QuillServiceTypes.PlayerData<T>?
}>

-- // MAIN // --

return {
    Number = require("@self/QuillComponents/QuillNumber"),
    
    Init = function<T>(properties: QuillServiceTypes.Properties<T>): PlayersData<T>
        return (RunService:IsServer() and require("@self/QuillServiceServer"):Init(properties) or require("@self/QuillServiceClient"):Init(properties)) :: any
    end
}