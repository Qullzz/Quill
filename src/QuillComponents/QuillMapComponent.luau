-- // MODULES // --
local QuillServiceUtility = require("../QuillServiceUtility")
local QuillGenericBase = require("../QuillBases/QuillGenericBase")
local QuillServiceTypes = require("../QuillServiceTypes")

-- // TYPES // --

type Type<T = {}> = T
export type Data = {
    
}
type Base<T> = QuillGenericBase.Base<Component<T>, Type<T>, QuillGenericBase.BaseReadCall<Type<T>> & {
    prevMap: Type<T>
} & Data>
type Component<T> = QuillGenericBase.Component<Type<T>, Base<T> & QuillGenericBase.ComponentReadCall<Type<T>> & Data>

-- // MAIN // --

-- ## PUBLIC ## --

local Module = setmetatable({} :: Base<{ [string]: QuillServiceTypes.Component<any, QuillServiceTypes.Base> }>, QuillGenericBase)

function Module.Clone(self, value)
    return New(value or QuillServiceUtility.CopyTemplate(self:SafeGet()), self.autoReplicate, self.authority, self.convert)
end

function Module.TypeEqual(self, component)
    return ( typeof(self) == typeof(component) )
        and ( rawequal(getmetatable(self), getmetatable(component)) )
end

function Module.Size(self, buff)
    return buffer.len(self:Serialize())
end

function Module.Serialize(self, replication)
    local map = self:SafeGet()
    
    return QuillServiceUtility.SerializePlayerData(map)
end

function Module.Deserialize(self, buff, replication)
    local map = self:SafeGet()
    
    return QuillServiceUtility.DeserializePlayerData(map, buff)
end

function Module.SafeWrite(self, value)
    local map = self:SafeGet()
    
    for key, component in pairs(value) do
        local thisComponent = map[key]
        
        if not thisComponent then continue end
        
        thisComponent:SafeWrite(component:SafeGet())
    end
end

function Module.SafeGet(self)
    return self.value
end

function Module.__eq(self, component)
    
    if not self:TypeEqual(component) then return false end
    
    local map = self:SafeGet()
    local thisMap = component:SafeGet()
    
    for key, value in pairs(map) do
        local thisValue = thisMap[key]
        
        if thisValue and value == thisValue then continue end
        
        return false
    end
    
    return true
end

function Module.__call(self)
    return self:SafeGet()
end

function New<T>(
    value: T,
    autoReplicate: QuillServiceTypes.ComponentAutoReplicate?,
    authority: QuillServiceTypes.ComponentAuthority?,
    convert: QuillServiceTypes.ComponentConvert<Type<T>>?
): Component<T>
    local result = setmetatable({
        autoReplicate = autoReplicate,
        authority = authority,
        value = value,
        
        convert = convert,
        
        _callbacks = {}
    }, Module) :: Component<T>
    
    result.prevMap = QuillServiceUtility.CopyTemplate(result:SafeGet())
    
    local Changed: QuillServiceTypes.BaseConnectCallback = function(value, prevValue, _, replicate)
        local map = result:SafeGet()
        
        result:Fire(map, result.prevMap, replicate)
        
        result.prevMap = QuillServiceUtility.CopyTemplate(map)
    end
    
    for key, component in pairs(( (value) :: any ) :: { [string]: QuillServiceTypes.Component<any, QuillServiceTypes.Base> }) do
        component:Connect(Changed)
    end
    
    return result
end

Module.__index = Module

return New