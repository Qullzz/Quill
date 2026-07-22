-- // MODULES // --
local QuillGenericBase = require("../QuillBases/QuillGenericBase")
local QuillServiceTypes = require("../QuillServiceTypes")

-- // CONSTANTS // --
const HASH_COUNT = 2
const BUFFER_HASH_SIZE = 8
const BUFFER_ITEM_SIZE = 2

-- // TYPES // --

export type Type = EnumItem
export type Data = {
    
}
export type Base = QuillGenericBase.Base<Component, Type, QuillGenericBase.BaseWriteCall<Type> & {
    
} & Data>
export type Component = QuillServiceTypes.Component<Type, Base & QuillGenericBase.ComponentWriteCall<Type> & Data>

-- // MAIN // --

-- ## PRIVATE ## --

local function HashEnumName(str: string): (number, number)
    local hi = 0
    local lo = 5381
    
    for i = 1, #str do
        local byte = string.byte(str, i)
        
        local temp = lo * 33 + byte
        local carry = math.floor(temp / 2^32)
        lo = temp % 2^32
        
        local tempHi = hi * 33 + carry
        hi = tempHi % 2^32
    end
    
    return hi, lo
end

local function StringifyHash(hash1: number, hash2: number)
    return `{hash1}{hash2}`
end

-- ## PUBLIC ## --

const ENUMS_HASH = (function()
    local result = {}
    
    for _, enum in Enum:GetEnums() do
        local name = tostring(enum)
        local hash = StringifyHash(HashEnumName(name))
        
        result[hash] = enum
    end
    
    return table.freeze(result)
end)()

local Module = setmetatable({} :: Base, QuillGenericBase)

function Module.Clone(self, value)
    return New(value or self:SafeGet(), self.autoReplicate, self.authority, self.convert)
end

function Module.TypeEqual(self, component)
    return ( typeof(self) == typeof(component) )
        and ( rawequal(getmetatable(self), getmetatable(component)) )
        and ( self:SafeGet().EnumType == component:SafeGet().EnumType )
end

function Module.Size(self, buff)
    return BUFFER_HASH_SIZE + BUFFER_ITEM_SIZE
end

function Module.Serialize(self, _)
    local enum = self:SafeGet()
    
    local hash1, hash2 = HashEnumName(tostring(enum.EnumType))
    
    local result = buffer.create(self:Size())
    
    buffer.writeu32(result, BUFFER_HASH_SIZE / HASH_COUNT * 0, hash1)
    buffer.writeu32(result, BUFFER_HASH_SIZE / HASH_COUNT * 1, hash2)
    buffer.writeu16(result, BUFFER_HASH_SIZE / HASH_COUNT * 2, enum.Value)
    
    return result
end

function Module.Deserialize(self, buff, _)
    local hash1, hash2, enumValue =
        buffer.readu32(buff, BUFFER_HASH_SIZE / HASH_COUNT * 0),
        buffer.readu32(buff, BUFFER_HASH_SIZE / HASH_COUNT * 1),
        buffer.readu16(buff, BUFFER_HASH_SIZE / HASH_COUNT * 2)
    
    local hash = StringifyHash(hash1, hash2)
    local enum = ENUMS_HASH[hash]
    
    assert(enum, `Couldn't find Enum for hash. <hash: {hash}>`)
    
    return enum:FromValue(enumValue)
end

function Module.SafeWrite(self, value)
    if typeof(self:SafeGet()) == typeof(value) and self:SafeGet().EnumType == value.EnumType and self:SafeGet() ~= value then
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

function New<T>(
    value: Type,
    autoReplicate: QuillServiceTypes.ComponentAutoReplicate?,
    authority: QuillServiceTypes.ComponentAuthority?,
    convert: QuillServiceTypes.ComponentConvert<Type>?
): Component
    local result = setmetatable({
        autoReplicate = autoReplicate,
        authority = authority,
        value = value,
        
        convert = convert,
        
        _callbacks = {}
    }, Module) :: Component
    
    return result
end

Module.__index = Module

return New