# QuillComponent

A `Base` is a base that creates Components, serving as a custom data type and should be used for player data (like numbers, strings, enums, vectors, cframes, arrays, dictionaries...). `Bases` are structured like the following:

```lua title="QuillComponent.luau (uses QuillGenericBase)"
local QuillGenericBase = require("../QuillBases/QuillGenericBase")
local QuillServiceTypes = require("../QuillServiceTypes")

export type Type = *Some Type Here*
export type Data = { *Some Data Here*
    
}
export type Base = QuillGenericBase.Base<Component, Type, QuillGenericBase.BaseWriteCall<Type> & { *Some Methods Here*
    
} & Data>
export type Component = QuillServiceTypes.Component<Type, Base & QuillGenericBase.ComponentWriteCall<Type> & Data>

local Module = setmetatable({} :: Base, QuillGenericBase)

function Module.Clone(self, value)
    return New(value or self:SafeGet(), self.autoReplicate, self.authority, self.convert)
end

function Module.TypeEqual(self, component)
    return ( typeof(self) == typeof(component) )
        and ( rawequal(getmetatable(self), getmetatable(component)) )
end

function Module.Size(self, _)
    return 0
end

function Module.Serialize(self, replication)
    local result = buffer.create(self:Size())
    
    *Some Serialization Here*
    
    return result
end

function Module.Deserialize(self, buff, replication)
    local result = self:SafeGet()
    
    *Some Deserialization Here*
    
    return result
end

function Module.SafeWrite(self, value)
    if typeof(self:SafeGet()) == typeof(value) and self:SafeGet() ~= value then
        local prevValue = self:SafeGet()
        
        self.value = value
        
        self:Fire(value, prevValue)
    end
end

function Module.SafeGet(self)
    return self.value
end

function Module.__eq(self, component)
    return ( self:TypeEqual(component) ) and ( self:SafeGet() == component:SafeGet() )
end

function Module.__call(self, value, replicate)
    if value then
        self:SafeWrite(value)
    end
    
    return self:SafeGet()
end

function New(
    value: Type?,
    autoReplicate: QuillServiceTypes.ComponentAutoReplicate?,
    authority: QuillServiceTypes.ComponentAuthority?,
    convert: QuillServiceTypes.ComponentConvert<Type>?
): Component
    local result = setmetatable({
        autoReplicate = autoReplicate,
        authority = authority,
        value = value or 0,
        
        convert = convert,
        
        _callbacks = {}
    }, Module) :: Component
    
    return result
end

Module.__index = Module

return New
```

### `New(..., auto_replicate, authority, convert) -> Component`

Creates and returns a new `Component`.

### `:Clone(self) -> Component`

Clones a `Component`.

### `:Once(self, callback) -> disconnect`

Connects to a `Component` changed event, disconnect immediately after the first one.

### `:Connect(self, callback) -> disconnect`

Connects to a `Component` changed event.

### `:TypeEqual(self, component) -> boolean`

Check if two `Component` are equal in type.

### `:Size(self, buff) -> number`

Returns the size of the `Component` in bytes, optionally takes a buffer to read it's size instead. (mainly for dynamic `Components` like `Arrays`)

### `:Serialize(self, replication) -> buffer`

Serializes a `Component`, return a buffer that describes it.

### `Deserialize(self, buff, replication) -> Compnoent`

Deserializes a `Component`, receives a buffer to deserialize

### `SafeWrite: ( self: T, value: V ) -> ()`

Safely writes a value into the `Component`

### `SafeGet: ( self: T ) -> V`

Safely reads a values of the `Component`

### `__eq: ( self: T, component: T ) -> boolean`

A metamethod that takes two `Component` to check if their equal. (from the equal operator '==')