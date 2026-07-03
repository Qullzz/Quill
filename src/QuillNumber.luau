-- // MODULES // --
local QuillTypes = require("./QuillTypes")

-- // TYPES // --

type Metadata = "u8" | "u16" | "u32" | "i8" | "i16" | "i32" | "f32" | "f64"

-- // MAIN // --

local Module: QuillTypes.QuillBase<number, Metadata>

Module = {
    New = function(auto_replicate, authority, meta_data, value)
        return setmetatable({
            auto_replicate = auto_replicate,
            authority = authority,
            meta_data = meta_data,
            value = value,
            
            _callbacks = {}
        }, Module)
    end,
    
    TypeEqual = function(quill1, quill2)
        return ( quill1.meta_data == quill2.meta_data ) and ( typeof(quill1.value) == typeof(quill2.value) )
    end,
    
    __eq = function(quill1, quill2)
        return ( quill1:TypeEqual(quill2) ) and ( quill1.value == quill2.value )
    end,
    
    __call = function(...)
        local self, value = ...
        
        if typeof(value) == "function" then
            table.insert(self._callbacks, value)
        elseif select("#", ...) > 1 and typeof(value) == typeof(self.value) then
            local old_value = self.value
            
            self.value = value
            
            for _, callback in self._callbacks do
                callback(function()
                    table.remove(self._callbacks, table.find(self._callbacks, callback))
                end, old_value, value)
            end
        end
        
        return self.value
    end
}

Module.__index = Module

return Module