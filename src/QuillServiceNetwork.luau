-- // MODULES // --
local Callnet = require("./Dependencies/QuillCallnet")

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
        
        QuillChangedServer = Callnet.definePacket({
            reliabilityType = "reliable",
            value = Callnet.struct({
                userID = userID,
                index = Callnet.uint16,
                data = data
            })
        }),
        
        QuillChangedClient = Callnet.definePacket({
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