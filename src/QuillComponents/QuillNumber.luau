-- // MODULES // --
local QuillTypes = require("../QuillTypes")

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
    
    Once = function(self, callback)
        local tab
        
        local function disconnect()
            table.remove(self._callbacks, table.find(self._callbacks, tab))
        end
        
        tab = {
            callback = callback,
            disconnect = disconnect,
            once = true
        }
        
        table.insert(self._callbacks, tab)
        
        return disconnect
    end,
    
    Connect = function(self, callback)
        local tab
        
        local function disconnect()
            table.remove(self._callbacks, table.find(self._callbacks, tab))
        end
        
        tab = {
            callback = callback,
            disconnect = disconnect,
            once = false
        }
        
        table.insert(self._callbacks, tab)
        
        return disconnect
    end,
    
    __eq = function(quill1, quill2)
        return ( quill1:TypeEqual(quill2) ) and ( quill1.value == quill2.value )
    end,
    
    __call = function(self, value)
        if typeof(value) == typeof(self.value) then
            local old_value = self.value
            
            self.value = value
            
            for _, callback in self._callbacks do
                if callback.once then
                    callback.callback(old_value, value)
                    
                    callback.disconnect()
                else
                    callback.callback(callback.disconnect, old_value, value)
                end
            end
        end
        
        return self.value
    end
}

Module.__index = Module

return Module