-- // MODULES // --
local Quill = require("./Quill")

-- // MAIN // --

return Quill.Init({
    mock = true,
    reset = true,
    
    templates = {
        previous_templates = {
            
        },
        
        current_template = {
            rank = Quill.Number.New(true, "server", "u8", 100)
        }
    }
})