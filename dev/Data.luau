-- // MODULES // --
local Quill = require("./Quill")

-- // MAIN // --

return Quill.Init({
    id = 2,
    mock = false,
    reset = false,
    
    templates = {
        old_templates = {
            {
                id = 0,
                
                template = {
                    level = Quill.Number.New(false, "server", "u8", 0)
                }
            },
            
            {
                id = 1,
                
                template = {
                    level = Quill.Number.New(false, "server", "u16", 0)
                }
            }
        },
        
        current_template = {
            rank = Quill.Number.New(true, "server", "u8", 0)
        }
    }
})