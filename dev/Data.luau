-- // MODULES // --
local Quill = require("./Quill")

-- // MAIN // --

return Quill.Init({
    mock = false,
    reset = true,
    
    templates = {
        previousTemplates = {
            
        },
        
        currentTemplate = {
            -- rank = Quill.Number(true, "server", "u16", 1),
            inventory = Quill.Array(true, "server", Quill.Number(true, "server", "u8", 0))
        }
    }
})