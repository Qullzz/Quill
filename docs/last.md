# QuillComponent

A `QuillComponent` is a component that creates Quills serving as a custom data type and can be used for player data (like numbers, strings, enums, vectors, cframes, arrays, dictionaries...). `QuillComponents` are structured like the following:

```lua title="QuillComponent.luau"
local QuillServiceTypes = require(PATH.TO.QuillServiceTypes)

type Type = *Some Roblox type here*
type Metadata = *Custom metadata here*

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
        return Module.New(self.auto_replicate, self.authority, self.meta_data, self.value, self.convert)
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
        local size = some_size
        
        local result = buffer.create(size)
        
        return result
    end,
    
    Deserialize = function(self, buff)
        local result = self()
        
        result = buffer.read(buff)
        
        return result
    end,
    
    __eq = function(quill1, quill2)
        return ( quill1:TypeEqual(quill2) ) and ( quill1.value == quill2.value )
    end,
    
    __call = function(self, value, replicate)
        if typeof(value) == typeof(self.value) and value ~= self.value then
            local previous_value = self.value
            
            self.value = value
            
            for _, callback in ipairs(self._callbacks) do
                if callback.once then
                    callback.callback(value, previous_value, replicate)
                    
                    callback.disconnect()
                else
                    callback.callback(value, previous_value, callback.disconnect, replicate)
                end
            end
        end
        
        return self.value
    end
}

Module.__index = Module
```

### `.New(auto_replicate, authority, meta_data, value, convert) -> Quill`

Creates and returns a new Quill.

### `:Clone(self) -> Quill`

Clones a Quill.

### `:Once(self, callback) -> disconnect`

Connects to a Quill changed event, disconnect immediately after the first one.

### `:Connect(self, callback) -> disconnect`

Connects to a Quill changed event.

### `:TypeEqual(quill1, quill2) -> boolean`

Check for type equality between to Quills.

### `:Serialize(self) -> buffer`

Serialize a Quill, return a buffer that describes it.

### `Deserialize(self, buffer) -> Quill`

Deserialize a Quill, receive