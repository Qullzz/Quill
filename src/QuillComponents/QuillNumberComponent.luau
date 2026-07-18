-- // MODULES // --
local QuillGenericBase = require("../QuillBases/QuillGenericBase")
local QuillServiceTypes = require("../QuillServiceTypes")

-- // TYPES // --

export type numberType = "u8" | "u16" | "u32" | "i8" | "i16" | "i32" | "f32" | "f64"

export type Type = number
export type Base = QuillGenericBase.Base<Component, Type, QuillGenericBase.BaseWriteCall<Type> & {
    
}>
export type Component = QuillServiceTypes.Component<Type, Base> & QuillGenericBase.ComponentWriteCall<Type> & {
    numberType: numberType
}

-- // MAIN // --

-- ## PUBLIC ## --

local Module = setmetatable({} :: Base, QuillGenericBase)

function Module.Clone(self, value)
    return New(self.autoReplicate, self.authority, self.numberType, value or self(), self.convert)
end

function Module.TypeEqual(self, component)
    return ( typeof(self) == typeof(component) )
        and ( self.numberType == component.numberType )
        and ( typeof(self()) == typeof(component:SafeGet()) )
end

function Module.Serialize(self, _)
    local size =
        ( ( self.numberType == "u8" or self.numberType == "i8" ) and 1 )
        or ( ( self.numberType == "u16" or self.numberType == "i16" ) and 2 )
        or ( ( self.numberType == "u32" or self.numberType == "i32" or self.numberType == "f32" ) and 4 )
        or 8
    
    local result = buffer.create(size)
    
    if self.numberType == "u8" then
        buffer.writeu8(result, 0, self())
    elseif self.numberType == "u16" then
        buffer.writeu16(result, 0, self())
    elseif self.numberType == "u32" then
        buffer.writeu32(result, 0, self())
    elseif self.numberType == "i8" then
        buffer.writei8(result, 0, self())
    elseif self.numberType == "i16" then
        buffer.writei16(result, 0, self())
    elseif self.numberType == "i32" then
        buffer.writei32(result, 0, self())
    elseif self.numberType == "f32" then
        buffer.writef32(result, 0, self())
    else
        buffer.writef64(result, 0, self())
    end
    
    return result
end

function Module.Deserialize(self, buff, _)
    local result = self()
    
    if self.numberType == "u8" then
        result = buffer.readu8(buff, 0)
    elseif self.numberType == "u16" then
        result = buffer.readu16(buff, 0)
    elseif self.numberType == "u32" then
        result = buffer.readu32(buff, 0)
    elseif self.numberType == "i8" then
        result = buffer.readi8(buff, 0)
    elseif self.numberType == "i16" then
        result = buffer.readi16(buff, 0)
    elseif self.numberType == "i32" then
        result = buffer.readi32(buff, 0)
    elseif self.numberType == "f32" then
        result = buffer.readf32(buff, 0)
    else
        result = buffer.readf64(buff, 0)
    end
    
    return result
end

function Module.SafeWrite(self, value)
    self.value = value
end

function Module.SafeGet(self)
    return self.value
end

function Module.__eq(self, component)
    return ( self:TypeEqual(component) ) and ( self() == component:SafeGet() )
end

function Module.__call(self, value, replicate)
    if value and typeof(self()) == typeof(value) and self:SafeGet() ~= value then
        local previousValue = self()
        
        self:SafeWrite(value)
        
        for _, callback in ipairs(self._callbacks) do
            if callback.once then
                callback.callback(value, previousValue, replicate)
                
                callback.disconnect()
            else
                callback.callback(value, previousValue, callback.disconnect, replicate)
            end
        end
    end
    
    return self:SafeGet()
end

-- ## PRIVATE ## --

function New(
    autoReplicate: QuillServiceTypes.ComponentAutoReplicate,
    authority: QuillServiceTypes.ComponentAuthority,
    numberType: numberType,
    value: Type,
    convert: QuillServiceTypes.ComponentConvert<Type>?
): Component
    local result = setmetatable({
        autoReplicate = autoReplicate,
        authority = authority,
        value = value,
        
        convert = convert,
        
        _callbacks = {}
    }, Module) :: Component
    
    result.numberType = numberType
    
    return result
end

Module.__index = Module

return New