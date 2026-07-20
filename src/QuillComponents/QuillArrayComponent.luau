-- // MODULES // --
local QuillServiceUtility = require("../QuillServiceUtility")
local QuillGenericBase = require("../QuillBases/QuillGenericBase")
local QuillServiceTypes = require("../QuillServiceTypes")

-- // CONSTANTS // --
const BUFFER_COUNT_SIZE = 2

-- // TYPES // --

type Type<T> = { T }
type Base<T, V> = QuillGenericBase.Base<Component<T, V>, Type<T>, QuillGenericBase.BaseReadCall<Type<T>> & {
    --[[
    Returns the Component at the specified index.
    ]]
    At: ( self: Component<T, V>, index: number ) -> T?,
    --[[
    Writes a value to the Component at the specified index, appending it if the index is past the end.
    ]]
    Set: ( self: Component<T, V>, index: number, value: V, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T, V>,
    --[[
    Inserts a value at the specified index, shifting later Components forward.
    ]]
    Insert: ( self: Component<T, V>, index: number, value: V, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T, V>,
    --[[
    Appends a value to the end of the Array.
    ]]
    Append: ( self: Component<T, V>, value: V, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T, V>,
    --[[
    Removes the Component at the specified index, shifting later Components backward.
    ]]
    Remove: ( self: Component<T, V>, index: number, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T, V>,
    --[[
    Removes the last Component from the Array.
    ]]
    Pop: ( self: Component<T, V>, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T, V>,
    --[[
    Sorts the Array using the provided comparison callback.
    ]]
    Sort: ( self: Component<T, V>, callback: ( self: T, component: T ) -> boolean, replicate: QuillServiceTypes.BaseReplicate? ) -> Component<T, V>,
    --[[
    Returns every Component that passes the provided predicate.
    ]]
    Filter: ( self: Component<T, V>, predicate: ( component: T ) -> boolean ) -> { T },
    --[[
    Calls the callback for each Component and updates or removes Components based on the result.
    If the same Component is returned, it won't apply any direct changes.
    ]]
    Map: ( self: Component<T, V>, callback: ( component: T ) -> T ) -> Component<T, V>,
    --[[
    Returns the first Component that passes the provided callback.
    ]]
    Match: ( self: Component<T, V>, callback: ( component: T ) -> boolean ) -> T?,
    --[[
    Returns whether every Component passes the provided callback.
    ]]
    Every: ( self: Component<T, V>, callback: ( component: T ) -> boolean ) -> boolean,
    --[[
    Splits the Array into groups of the specified size.
    ]]
    Chunks: ( self: Component<T, V>, size: number ) -> { { T } }
}>
type Component<T, V> = QuillGenericBase.Component<Type<T>, Base<T, V> & QuillGenericBase.ComponentReadCall<Type<T>> & {
    component: T
}>


-- // MAIN // --

-- ## PRIVATE ## --

local function NormalizeIndex(index: number, length: number, allowAppend: boolean?): number?
    
    if length == 0 and not allowAppend then return end
    
    local max = if allowAppend then length + 1 else length
    local x = length + 1
    local result = if index < 0 then x + math.fmod(index, x) else math.max(index, 1)
    
    if result > max then
        return if allowAppend then max else nil
    end
    
    return result
end

-- ## PUBLIC ## --

local Module = setmetatable({} :: Base<QuillServiceTypes.Component<any, QuillServiceTypes.Base<any, any>>, any>, QuillGenericBase)

function Module.Clone(self, value)
    local component = self.component:Clone()
    
    local result = New(self.autoReplicate, self.authority, component, component:SafeGet(), self.convert)
    
    if value then
        result:SafeWrite(value)
    end
    
    return result
end

function Module.TypeEqual(self, component)
    return ( typeof(self) == typeof(component) )
        and ( rawequal(getmetatable(self), getmetatable(component)) )
        and ( typeof(self.component) == typeof(component.component) )
        and ( self.component:TypeEqual(component.component) )
end

function Module.Size(self, buff)
    if buff then
        if buffer.len(buff) < BUFFER_COUNT_SIZE then
            return buffer.len(buff)
        end
        
        local count = buffer.readu16(buff, 0)
        local offset = BUFFER_COUNT_SIZE
        
        for _ = 1, count do
            local thisSize = buffer.len(buff) - offset
            local thisBuff = buffer.create(thisSize)
            
            buffer.copy(thisBuff, 0, buff, offset, thisSize)
            
            offset += self.component:Size(thisBuff)
        end
        
        return offset
    end
    
    local size = BUFFER_COUNT_SIZE
    
    for _, component in ipairs(self:SafeGet()) do
        size += component:Size()
    end
    
    return size
end

function Module.Serialize(self, replication)
    local array = self:SafeGet()
    local buffs = {}
    local size = self:Size()
    
    for _, value in ipairs(array) do
        local buff = value:Serialize(replication)
        
        table.insert(buffs, buff)
    end
    
    local result = buffer.create(size)
    
    buffer.writeu16(result, 0, #buffs)
    
    local offset = BUFFER_COUNT_SIZE
    
    for _, buff in buffs do
        buffer.copy(result, offset, buff)
        
        offset += self.component:Size(buff)
    end
    
    return result
end

function Module.Deserialize(self, buff, replication)
    local totalSize = self:Size(buff)
    
    if totalSize <= BUFFER_COUNT_SIZE then return {} end
    
    local result = {}
    
    local count = buffer.readu16(buff, 0)
    
    local offset = BUFFER_COUNT_SIZE
    
    for _ = 1, count do
        local thisSize = totalSize - offset
        local thisBuff = buffer.create(thisSize)
        
        buffer.copy(thisBuff, 0, buff, offset, thisSize)
        
        local size = self.component:Size(thisBuff)
        local componentBuff = buffer.create(size)
        
        buffer.copy(componentBuff, 0, buff, offset, size)
        
        offset += size
        
        local component = self.component:Clone(self.component:Deserialize(componentBuff, replication))
        
        table.insert(result, component)
    end
    
    return result
end

function Module.SafeWrite(self, value)
    table.clear(self.value)
    
    for _, component in value do
        table.insert(self.value, component)
    end
end

function Module.SafeGet(self)
    return self.value
end

function Module.__eq(self, component)
    return ( self:TypeEqual(component) )
end

function Module.__call(self)
    return self:SafeGet()
end

function Module.At(self, index)
    local array = self:SafeGet()
    local normalizedIndex = NormalizeIndex(index, #array)
    
    return if normalizedIndex then array[normalizedIndex] else nil
end

function Module.Set(self, index, value, replicate)
    local array = self:SafeGet()
    local normalizedIndex = NormalizeIndex(index, #array, true)
    
    local prevArray = QuillServiceUtility.CopyTemplate(array)
    
    local component = if normalizedIndex then array[normalizedIndex] else nil
    
    if component then
        component:SafeWrite(value)
    else
        rawset(array, normalizedIndex, self.component:Clone(value))
    end
    
    self:Fire(array, prevArray, replicate)
    
    return self
end

function Module.Insert(self, index, value, replicate)
    local array = self:SafeGet()
    local normalizedIndex = NormalizeIndex(index, #array, true)
    
    local prevArray = QuillServiceUtility.CopyTemplate(array)
    
    table.insert(array, normalizedIndex, self.component:Clone(value))
    
    self:Fire(array, prevArray, replicate)
    
    return self
end

function Module.Append(self, value, replicate)
    local array = self:SafeGet()
    
    local prevArray = QuillServiceUtility.CopyTemplate(array)
    
    rawset(array, #array + 1, self.component:Clone(value))
    
    self:Fire(array, prevArray, replicate)
    
    return self
end

function Module.Remove(self, index, replicate)
    local array = self:SafeGet()
    local normalizedIndex = NormalizeIndex(index, #array)
    
    if not normalizedIndex then return self end
    
    local prevArray = QuillServiceUtility.CopyTemplate(array)
    
    table.remove(array, normalizedIndex)
    
    self:Fire(array, prevArray, replicate)
    
    return self
end

function Module.Pop(self, replicate)
    local array = self:SafeGet()
    
    local prevArray = QuillServiceUtility.CopyTemplate(array)
    
    table.remove(array, #array)
    
    self:Fire(array, prevArray, replicate)
    
    return self
end

function Module.Sort(self, callback, replicate)
    local array = self()
    
    local prevArray = QuillServiceUtility.CopyTemplate(array)
    
    table.sort(array, callback)
    
    self:Fire(array, prevArray, replicate)
    
    return self
end

function Module.Filter(self, predicate)
    local result = {}
    
    for _, value in ipairs(self:SafeGet()) do
        
        if not predicate(value) then continue end
        
        table.insert(result, value)
    end
    
    return result
end

function Module.Map(self, callback)
    local array = self:SafeGet()
    
    local prevArray = QuillServiceUtility.CopyTemplate(array)
    
    for index = #array, 1, -1 do
        local value = self:At(index)
        
        if not value then continue end
        
        local result = callback(value)
        
        if rawequal(value, result) then continue end
        
        if value:TypeEqual(result) then
            value:SafeWrite(result:SafeGet())
        else
            self:Remove(index)
        end
    end
    
    local changed = false
    
    for index, value in ipairs(array) do
        local prevValue = prevArray[index]
        
        if prevArray and value == prevValue then continue end
        
        changed = true
    end
    
    if changed then
        self:Fire(array, prevArray)
    end
    
    return self
end

function Module.Match(self, callback)
    for _, component in self:SafeGet() do
        
        if not callback(component) then continue end
        
        return component
    end
    
    return
end

function Module.Every(self, callback)
    local array = self:SafeGet()
    
    for _, component in ipairs(array) do
        
        if callback(component) then continue end
        
        return false
    end
    
    return true
end

function Module.Chunks(self, size)
    local array = self:SafeGet()
    
    if #array == 0 then return {} end
    
    local result = {}
    local chunk = {}
    local chunkSize = 0
    
    for _, value in array do
        
        table.insert(chunk, value)
        
        chunkSize += 1
        
        if chunkSize < size then continue end
        
        table.insert(result, chunk)
        
        chunk = {}
        chunkSize = 0
    end
    
    if not table.find(result, chunk) and #chunk > 0 then
        table.insert(result, chunk)
    end
    
    return result
end

-- ## PRIVATE ## --

function New<T, V>(
    autoReplicate: QuillServiceTypes.ComponentAutoReplicate,
    authority: QuillServiceTypes.ComponentAuthority,
    component: T,
    value: V?,
    convert: QuillServiceTypes.ComponentConvert<Type<T>>?
): Component<T, V>
    local result = setmetatable({
        autoReplicate = autoReplicate,
        authority = authority,
        value = setmetatable({}, { __newindex = function()  end }),
        
        convert = convert,
        
        _callbacks = {}
    }, Module) :: Component<T, V>
    
    if value then
        ((component :: any).component :: any):SafeWrite(value)
    end
    
    result.component = component
    
    return result
end

Module.__index = Module

return New