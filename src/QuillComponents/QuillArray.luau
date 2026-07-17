-- // MODULES // --
local QuillServiceUtility = require("../QuillServiceUtility")
local QuillServiceTypes = require("../QuillServiceTypes")

-- // CONSTANTS // --
const BUFFER_COUNT_SIZE = 2

-- // TYPES // --

type Type = { QuillServiceTypes.Quill<Type, Metadata> }
type Metadata = {
    clone: Type,
    quill: QuillServiceTypes.Quill<Type, Metadata>
}

-- // MAIN // --

local Module: QuillServiceTypes.QuillBase<Type, Metadata>

Module = {
    New = function(auto_replicate, authority, meta_data, value, convert)
        return setmetatable({
            auto_replicate = auto_replicate,
            authority = authority,
            meta_data = meta_data,
            value = value,
            
            convert = convert,
            
            _callbacks = {}
        }, Module)
    end,
    
    Clone = function(self)
        return Module.New(self.auto_replicate, self.authority, {
            clone = {},
            quill = self.meta_data.quill:Clone()
        }, self.value, self.convert)
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
            and ( rawequal(quill1.meta_data, quill2.meta_data) )
            and ( typeof(quill1.value) == typeof(quill2.value) )
    end,
    
    Serialize = function(self)
        local buffs = {}
        local size = BUFFER_COUNT_SIZE
        
        for index, quill in ipairs(self()) do
            local buff = quill:Serialize()
            
            size += buffer.len(buff)
            
            buffs[index] = buff
        end
        
        local result = buffer.create(size)
        
        buffer.writeu16(result, 0, #buffs)
        
        local offset = BUFFER_COUNT_SIZE
        
        for _, buff in buffs do
            buffer.copy(result, offset, buff)
            
            offset += buffer.len(buff)
        end
        
        return result
    end,
    
    Deserialize = function(self, buff)
        local result = self()
        
        local count = buffer.readu16(buff, 0)
        local size = ( buffer.len(buff) - BUFFER_COUNT_SIZE ) // math.max(count, 1)
        
        local offset = BUFFER_COUNT_SIZE
        
        for index = 1, count do
            local quill_buff = buffer.create(size)
            
            buffer.copy(quill_buff, 0, buff, offset, size)
            
            local quill = self.meta_data.quill:Clone(self.meta_data.quill:Deserialize(buff))
            
            table.insert(result, quill)
            
            offset += size
        end
        
        return result
    end,
    
    __eq = function(quill1, quill2)
        return ( quill1:TypeEqual(quill2) ) and ( #quill1.value == #quill2.value )
    end,
    
    __call = function(self, value, replicate)
        if value and typeof(value) == typeof(self.value) and value == self.value then
            
            for index = #value, 1, -1 do
                local quill = value[index]
                
                if not quill then continue end
                
                if self.meta_data.quill:TypeEqual(quill) then continue end
                
                value[index] = nil
            end
            
            local changed = false
            
            for index, quill in value do
                local thisQuill = self.meta_data.clone[index]
                
                if thisQuill == quill then continue end
                
                changed = true
            end
            
            if changed then
                if changed then
                    for _, callback in ipairs(self._callbacks) do
                        if callback.once then
                            callback.callback(value, self.meta_data.clone, replicate)
                            
                            callback.disconnect()
                        else
                            callback.callback(value, self.meta_data.clone, callback.disconnect, replicate)
                        end
                    end
                end
                
                self.meta_data.clone = QuillServiceUtility.CopyTemplate(self.value)
            end
        end
        
        return self.value
    end
}

Module.__index = Module

return Module