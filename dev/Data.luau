-- // MODULES // --
local Quill = require("./Quill")

-- // MAIN // --

return Quill.Init({
    id = 0,
    mock = false,
    reset = false,
    
    templates = {
        old_templates = {
            
        },
        
        current_template = {
            level = Quill.Number.New(true, "client", "u8", 0)
        }
    }
})