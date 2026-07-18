-- // MODULES // --
local QuillServiceUtility = require("../QuillServiceUtility")
local QuillGenericBase = require("../QuillBases/QuillGenericBase")
local QuillServiceTypes = require("../QuillServiceTypes")

-- // CONSTANTS // --
const BUFFER_COUNT_SIZE = 2

-- // TYPES // --

type Type<T> = { QuillServiceTypes.Component<T> }
type Base<T> = QuillGenericBase.Base<Component<T>, Type<T>, QuillGenericBase.BaseReadCall<Type<T>> & {
    At: ( self: Component<T>, index: number ) -> T?,
    Insert: ( self: Component<T>, index: number, value: T, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T>,
    Append: ( self: Component<T>, value: T, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T>,
    Remove: ( self: Component<T>, index: number, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T>,
    Pop: ( self: Component<T>, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T>,
    Sort: ( self: Component<T>, callback: ( component1: T, component2: T ) -> boolean, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T>,
    Filter: ( self: Component<T>, predicate: ( component: T ) -> boolean ) -> { T },
    Map: ( self: Component<T>, callback: ( component: T ) -> T ) -> Component<T>,
    Match: ( self: Component<T>, callback: ( component: T ) -> boolean ) -> T?,
    Chunks: ( self: Component<T>, size: number ) -> { { T } }
}>
type Component<T> = QuillServiceTypes.Component<T, Base<T>> & QuillGenericBase.ComponentReadCall<Type<T>> & {
    component: T
}

-- // MAIN // --

-- ## PUBLIC ## --

local Module = setmetatable({} :: Base<QuillServiceTypes.Component>, QuillGenericBase)

function Module.Clone(self, _)
    return New(self.autoReplicate, self.authority, self.component, self.convert)
end

function Module.TypeEqual(self, component)
    return ( typeof(self) == typeof(component) )
        and ( getmetatable(self) == getmetatable(component) )
        and ( typeof(self()) == typeof(component:SafeGet()) )
        and ( rawequal(self(), component:SafeGet()) )
end

function Module.Serialize(self, replication)
    local buffs = {}
    local size = BUFFER_COUNT_SIZE
    
    for index, value in ipairs(self()) do
        
        if not value.autoReplicate then continue end
        
        local buff = value:Serialize(replication)
        
        size += buffer.len(buff)
        
        buffs[index] = buff
    end
    
    local result = buffer.create(size)
    
    buffer.writeu16(result, 0, #buffs)
    
    local offset = BUFFER_COUNT_SIZE
    
    for _, buff in buffs do
        buffer.copy(result, offset, buff)
        
        offset += buffer.len(buff)
    end
    
    return result
end

function Module.Deserialize(self, buff, replication)
    local result = self()
    
    local count = buffer.readu16(buff, 0)
    local size = ( buffer.len(buff) - BUFFER_COUNT_SIZE ) // math.max(count, 1)
    
    local offset = BUFFER_COUNT_SIZE
    
    for index = 1, count do
        local componentBuff = buffer.create(size)
        
        buffer.copy(componentBuff, 0, buff, offset, size)
        
        local component = self.component:Clone(self.component:Deserialize(buff, replication))
        
        table.insert(result, component)
        
        offset += size
    end
    
    return result
end

function Module.SafeWrite(self, value)
    
end

function Module.SafeGet(self)
    return self.value
end

function Module.__eq(self, component)
    return ( self:TypeEqual(component) ) and ( #self() == #component:SafeGet() )
end

function Module.__call(self)
    return self:SafeGet()
end

function Module.At(self, index)
    local array = self()
    local length = #array
    local x = length + 1
    
    return table.find(array,
        math.clamp(if index < 0 then x + ( math.fmod(index, x) ) else index, 1, length)
    )
end

function Module.Insert(self, index, value, replicate)
    local array = self()
    
    local prevValue = QuillServiceUtility.CopyTemplate(array)
    
    rawset(array, index, value)
    
    self:Fire(array, prevValue, replicate)
    
    return self
end

function Module.Append(self, value, replicate)
    local array = self()
    
    local prevValue = QuillServiceUtility.CopyTemplate(array)
    
    rawset(array, #array + 1, value)
    
    self:Fire(array, prevValue, replicate)
    
    return self
end

function Module.Remove(self, index, replicate)
    local array = self()
    
    local prevValue = QuillServiceUtility.CopyTemplate(array)
    
    rawset(array, index, nil)
    
    self:Fire(array, prevValue, replicate)
    
    return self
end

function Module.Pop(self, replicate)
    local array = self()
    
    local prevValue = QuillServiceUtility.CopyTemplate(array)
    
    rawset(array, #array, nil)
    
    self:Fire(array, prevValue, replicate)
    
    return self
end

function Module.Sort(self, callback, replicate)
    local array = self()
    
    local prevValue = QuillServiceUtility.CopyTemplate(array)
    
    table.sort(array, callback)
    
    self:Fire(array, prevValue, replicate)
end

function Module.Filter(self, predicate)
    local result = {}
    
    for _, value in ipairs(self()) do
        
        if not predicate(value) then continue end
        
        table.insert(result, value)
    end
    
    return result
end

function Module.Map(self, callback)
    local array = self()
    
    for index = #array, 1, -1 do
        local value = array[index]
        local result = callback(value)
        
        if value:TypeEqual(result) then
            value:SafeWrite(result:SafeGet())
        else
            array[index] = result
        end
    end
end

function Module.Match(self, callback)
    local array = self()
    
    for _, component in array do
        
        if not callback(component) then continue end
        
        return component
    end
    
    return
end

function Module.Chunks(self, size)
    local array = self()
    
    if #array == 0 then return {} end
    
    local result = {}
    local chunk = {}
    local chunkSize = 0
    
    for _, component in array do
        
        table.insert(chunk, component)
        
        chunkSize += 1
        
        if chunkSize < size then continue end
        
        table.insert(result, chunk)
        
        chunk = {}
        chunkSize = 0
    end
    
    if not table.find(result, chunk) then
        table.insert(result, chunk)
    end
    
    return result
end

-- ## PRIVATE ## --

function New<T>(
    autoReplicate: QuillServiceTypes.ComponentAutoReplicate,
    authority: QuillServiceTypes.ComponentAuthority,
    component: T,
    convert: QuillServiceTypes.ComponentConvert<Type<T>>?
): Component<T>
    local result = setmetatable({
        autoReplicate = autoReplicate,
        authority = authority,
        value = setmetatable({}, { __newindex = function()  end }),
        
        convert = convert,
        
        _callbacks = {}
    }, Module) :: Component<T>
    
    result.component = component
    
    return result
end

Module.__index = Module

return New