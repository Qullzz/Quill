-- // MODULES // --
local Callnet = require("./QuillDependencies/QuillCallnet")

-- // MAIN // --

return Callnet.defineNamespace("__QuillService", function()
    local userID = Callnet.float64
    local data = Callnet.buff
    
    return {
        ProfileAdded = Callnet.definePacket({
            reliabilityType = "reliable",
            value = Callnet.struct({
                userID = userID,
                data = data
            })
        }),
        
        ProfileRemoved = Callnet.definePacket({
            reliabilityType = "reliable",
            value = userID
        }),
        
        ComponentChangedServer = Callnet.definePacket({
            reliabilityType = "reliable",
            value = Callnet.struct({
                userID = userID,
                index = Callnet.uint16,
                data = data
            })
        }),
        
        ComponentChangedClient = Callnet.definePacket({
            reliabilityType = "reliable",
            value = Callnet.struct({
                index = Callnet.uint16,
                replicate = Callnet.optional(Callnet.bool),
                data = data
            })
        }),
        
        PlayerLoaded = Callnet.definePacket({
            reliabilityType = "reliable",
            value = Callnet.nothing
        })
    }
end)