-- // SERVICES // --
local RunService = game:GetService("RunService")

-- // MODULES // --
local QuillServiceTypes = require(script.QuillServiceTypes)

-- // MAIN // --

return {
    Number = require("@self/QuillComponents/QuillNumber"),
    
    Init = function<T>(properties: QuillServiceTypes.Properties<T>): QuillServiceTypes.PlayersData<T>
        return (RunService:IsServer() and require("@self/QuillServiceServer"):Init(properties) or require("@self/QuillServiceClient"):Init(properties)) :: any
    end
}