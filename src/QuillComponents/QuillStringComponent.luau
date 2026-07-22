-- // MODULES // --
local QuillGenericBase = require("../QuillBases/QuillGenericBase")
local QuillServiceTypes = require("../QuillServiceTypes")

-- // TYPES // --

export type Type = string
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

function Module.Size(self, buff)
    return #self:SafeGet()
end

function Module.Serialize(self, _)
    local str = self:SafeGet()
    
    local result = buffer.create(self:Size())
    
    buffer.writestring(result, 0, str)
    
    return result
end

function Module.Deserialize(self, buff, _)
    return buffer.readstring(buff, 0, buffer.len(buff))
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
        value = value or "",
        
        convert = convert,
        
        _callbacks = {}
    }, Module) :: Component
    
    return result
end

Module.__index = Module

return New