-- // MODULES // --
local QuillServiceTypes = require("../QuillServiceTypes")

-- // TYPES // --

type component<T> = QuillServiceTypes.Component<T, QuillServiceTypes.Base<component<T>, T>>

export type BaseReadCall<T> = { __call: ( self: component<T> ) -> T }
export type ComponentReadCall<T> = () -> T
export type BaseWriteCall<T> = { __call: ( self: component<T>, value: T?, replicate: boolean? ) -> T }
export type ComponentWriteCall<T> = ( value: T?, replicate: boolean? ) -> T

export type Base<T, V, M = {}> = QuillServiceTypes.Base<T, V> & M & {
    Fire: ( self: QuillServiceTypes.Component, value: V, prevValue: V, replicate: boolean? ) -> ()
}
export type Component<T, B, M = {}> = QuillServiceTypes.Component<T, B> & M

-- // MAIN // --

local Module = {} :: Base<QuillServiceTypes.Component, any>
Module.__index = Module

Module.autoReplicate = true
Module.authority = "server"

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
    
    return ( typeof(self) == typeof(component) )
        and ( rawequal(getmetatable(self), getmetatable(component)) )
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

function Module.Size(self, buff)
    warn("Unimplemented Size method!", debug.traceback())
    
    return if buff then buffer.len(buff) else buffer.len(self:Serialize())
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
    for i = #self._callbacks, 1, -1 do
        local callback = self._callbacks[i]
        
        if callback.once then
            callback.callback(value, prevValue, replicate)
            
            callback.disconnect()
        else
            callback.callback(value, prevValue, callback.disconnect, replicate)
        end
    end
end

return table.freeze(Module)