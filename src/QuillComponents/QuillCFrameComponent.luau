-- // MODULES // --
local QuillGenericBase = require("../QuillBases/QuillGenericBase")
local QuillServiceTypes = require("../QuillServiceTypes")

-- // TYPES // --

export type Type = CFrame
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
    return 24
end

function Module.Serialize(self, _)
    local cframe = self:SafeGet()
    
    local result = buffer.create(self:Size())
    
    local pitch, yaw, roll = cframe:ToEulerAnglesXYZ()
    
    buffer.writef32(result, 0, cframe.X)
    buffer.writef32(result, 4, cframe.Y)
    buffer.writef32(result, 8, cframe.Z)
    buffer.writef32(result, 12, pitch)
    buffer.writef32(result, 16, yaw)
    buffer.writef32(result, 20, roll)
    
    return result
end

function Module.Deserialize(self, buff, _)
    local x, y, z, pitch, yaw, roll =
        buffer.readf32(buff, 0),
        buffer.readf32(buff, 4),
        buffer.readf32(buff, 8),
        buffer.readf32(buff, 12),
        buffer.readf32(buff, 16),
        buffer.readf32(buff, 20)
    
    return CFrame.fromEulerAnglesXYZ(pitch, yaw, roll) + Vector3.new(x, y, z)
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
        value = value or CFrame.identity,
        
        convert = convert,
        
        _callbacks = {}
    }, Module) :: Component
    
    return result
end

Module.__index = Module

return New