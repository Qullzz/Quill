-- // MODULES // --
local QuillServiceTypes = require("../QuillServiceTypes")

-- // TYPES // --

type component<T> = QuillServiceTypes.Component<T, QuillServiceTypes.Base<component<T>, T>>

export type BaseReadCall<T> = { __call: ( self: component<T> ) -> T }
export type ComponentReadCall<T> = () -> T
export type BaseWriteCall<T> = { __call: ( self: component<T>, value: T?, replicate: boolean? ) -> T }
export type ComponentWriteCall<T> = ( value: T?, replicate: boolean? ) -> T

export type Base<T, V, M = {}> = QuillServiceTypes.Base<T, V> & M & {
    Fire: ( self: QuillServiceTypes.Component, value: any, prevValue: any, replicate: boolean? ) -> ()
}

-- // MAIN // --

local Module = {} :: Base<QuillServiceTypes.Component, any>
Module.__index = Module

function Module.Clone(self, _)
    warn("Unimplemented Clone method!", debug.traceback())
    
    return typeof(self) == "table" and table.clone(self) or self
end

function Module.Once(self, callback)
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
end

function Module.Connect(self, callback)
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
end

function Module.TypeEqual(self, component)
    warn("Unimplemented TypeEqual method!", debug.traceback())
    
    return typeof(self.value) == typeof(component.value)
end

function Module.Serialize(self, replication)
    warn("Unimplemented Serialize method!", debug.traceback())
    
    return buffer.create(0)
end

function Module.Deserialize(self, _, replication)
    warn("Unimplemented Deserialize method!", debug.traceback())
    
    return self.value
end

function Module.SafeWrite(self, value)
    warn("Unimplemented SafeWrite method!", debug.traceback())
    
    self.value = value
end

function Module.SafeGet(self)
    warn("Unimplemented SafeGet method!", debug.traceback())
    
    return self.value
end

function Module.__eq(self, component)
    warn("Unimplemented __eq meta-method!", debug.traceback())
    
    return ( self:TypeEqual(component) ) and ( self.value == component.value )
end

function Module.__call(self)
    warn("Unimplemented __call meta-method!", debug.traceback())
    
    return self.value
end

function Module.Fire(self, value, prevValue, replicate)
    for _, callback in ipairs(self._callbacks) do
        if callback.once then
            callback.callback(value, prevValue, replicate)
            
            callback.disconnect()
        else
            callback.callback(value, prevValue, callback.disconnect, replicate)
        end
    end
end

return table.freeze(Module)