-- // MODULES // --
local QuillServiceTypes = require("../QuillServiceTypes")

-- // TYPES // --

type Metadata = "u8" | "u16" | "u32" | "i8" | "i16" | "i32" | "f32" | "f64"

-- // MAIN // --

local Module: QuillServiceTypes.QuillBase<number, Metadata>

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
    
    Clone = function(self)
        return Module.New(self.auto_replicate, self.authority, self.meta_data, self.value)
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
    
    TypeEqual = function(quill1, quill2)
        return ( typeof(quill1) == typeof(quill2) )
            and ( quill1.meta_data == quill2.meta_data )
            and ( typeof(quill1.value) == typeof(quill2.value) )
    end,
    
    Serialize = function(self)
        local size =
            ( ( self.meta_data == "u8" or self.meta_data == "i8" ) and 1 )
            or ( ( self.meta_data == "u16" or self.meta_data == "i16" ) and 2 )
            or ( ( self.meta_data == "u32" or self.meta_data == "i32" or self.meta_data == "f32" ) and 4 )
            or 8
        
        local result = buffer.create(size)
        
        if self.meta_data == "u8" then
            buffer.writeu8(result, 0, self())
        elseif self.meta_data == "u16" then
            buffer.writeu16(result, 0, self())
        elseif self.meta_data == "u32" then
            buffer.writeu32(result, 0, self())
        elseif self.meta_data == "i8" then
            buffer.writei8(result, 0, self())
        elseif self.meta_data == "i16" then
            buffer.writei16(result, 0, self())
        elseif self.meta_data == "i32" then
            buffer.writei32(result, 0, self())
        elseif self.meta_data == "f32" then
            buffer.writef32(result, 0, self())
        else
            buffer.writef64(result, 0, self())
        end
        
        return result
    end,
    
    Deserialize = function(self, buff)
        local result = self()
        
        if self.meta_data == "u8" then
            result = buffer.readu8(buff, 0)
        elseif self.meta_data == "u16" then
            result = buffer.readu16(buff, 0)
        elseif self.meta_data == "u32" then
            result = buffer.readu32(buff, 0)
        elseif self.meta_data == "i8" then
            result = buffer.readi8(buff, 0)
        elseif self.meta_data == "i16" then
            result = buffer.readi16(buff, 0)
        elseif self.meta_data == "i32" then
            result = buffer.readi32(buff, 0)
        elseif self.meta_data == "f32" then
            result = buffer.readf32(buff, 0)
        else
            result = buffer.readf64(buff, 0)
        end
        
        return result
    end,
    
    __eq = function(quill1, quill2)
        return ( quill1:TypeEqual(quill2) ) and ( quill1.value == quill2.value )
    end,
    
    __call = function(self, value, replicate)
        if typeof(value) == typeof(self.value) and value ~= self.value then
            local old_value = self.value
            
            self.value = value
            
            for _, callback in ipairs(self._callbacks) do
                if callback.once then
                    callback.callback(old_value, value)
                    
                    callback.disconnect()
                else
                    callback.callback(callback.disconnect, old_value, value, replicate)
                end
            end
        end
        
        return self.value
    end
}

Module.__index = Module

return Module