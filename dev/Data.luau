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
            rank = Quill.Number("u16", 1),
            groupName = Quill.String("lw4"),
            inventory = Quill.Array(Quill.Number(), 0),
            config = Quill.Map({
                graphics = Quill.Map({
                    level = Quill.Number()
                }),
                keybinds = Quill.Map({
                    openMenu = Quill.Enum(Enum.KeyCode.M)
                }),
                volume = Quill.Map({
                    global = Quill.Number(),
                    sfx = Quill.Number(),
                    music = Quill.Number()
                })
            })
        }
    }
})