-- // MODULES // --
local Quill = require("./Quill")

-- // MAIN // --

return Quill.Init({
    mock = false,
    reset = false,
    
    templates = {
        previous_templates = {
            
        },
        
        current_template = {
            -- rank = Quill.Number.New(true, "server", "u8", 100),
            inventory = Quill.Array.New(false, "server", {
                clone = {},
                quill = Quill.Number.New(false, "server", "u8", 0)
            }, {})
        }
    }
})