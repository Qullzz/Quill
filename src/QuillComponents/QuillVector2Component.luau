-- // MODULES // --
local QuillGenericBase = require("../QuillBases/QuillGenericBase")
local QuillServiceTypes = require("../QuillServiceTypes")

-- // CONSTANTS // --
const AXIS_COUNT = 2
const BUFFER_AXIS_SIZE = 4

-- // TYPES // --

export type Type = Vector2
export type Data = {
    
}
export type Base = QuillGenericBase.Base<Component, Type, QuillGenericBase.BaseWriteCall<Type> & {
    
} & Data>
export type Component = QuillServiceTypes.Component<Type, Base & QuillGenericBase.ComponentWriteCall<Type> & Data>

-- // MAIN // --

-- ## PUBLIC ## --

local Module = setmetatable({} :: Base, QuillGenericBase)

function Module.Clone(self, value)
    return New(value or self:SafeGet(), self.autoReplicate, self.authority, self.convert)
end

function Module.TypeEqual(self, component)
    return ( typeof(self) == typeof(component) )
        and ( rawequal(getmetatable(self), getmetatable(component)) )
end

function Module.Size(self, _)
    return BUFFER_AXIS_SIZE * AXIS_COUNT
end

function Module.Serialize(self, _)
    local vec = self:SafeGet()
    
    local result = buffer.create(self:Size())
    
    buffer.writef32(result, BUFFER_AXIS_SIZE * 0, vec.X)
    buffer.writef32(result, BUFFER_AXIS_SIZE * 1, vec.Y)
    
    return result
end

function Module.Deserialize(self, buff, _)
    local x, y =
        buffer.readf32(buff, BUFFER_AXIS_SIZE * 0),
        buffer.readf32(buff, BUFFER_AXIS_SIZE * 1)
    
    return Vector2.new(x, y)
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
        value = value or Vector2.zero,
        
        convert = convert,
        
        _callbacks = {}
    }, Module) :: Component
    
    return result
end

Module.__index = Module

return New