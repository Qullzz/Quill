-- // MODULES // --
local Quill = require("./Quill")

-- // MAIN // --

return Quill.Init({
    mock = false,
    reset = false,
    
    templates = {
        previousTemplates = {
            
        },
        
        currentTemplate = {
            -- rank = Quill.Number(true, "server", "u16", 1),
            inventory = Quill.Array(false, "server", Quill.Number(true, "server", "u8"), 0)
        }
    }
})