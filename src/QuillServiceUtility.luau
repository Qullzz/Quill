-- // MODULES // --
local QuillServiceTypes = require(script.Parent.QuillServiceTypes)

-- // MAIN // --

local Module = {}

function Module.GetTemplateSchema(template: QuillServiceTypes.PlayerData): {{
    key: QuillServiceTypes.PlayerDataKey,
    component: QuillServiceTypes.PlayerDataValue
}}
    local keys: { QuillServiceTypes.PlayerDataKey } = {}
    
    for key, _ in pairs(template) do
        table.insert(keys, key)
    end
    
    table.sort(keys, function(key1, key2)
        return key1 < key2
    end)
    
    local result = {}
    
    for index, key in ipairs(keys) do
        result[index] = { key = key, component = template[key] }
    end
    
    return result
end

function Module.SerializePlayerData(data: QuillServiceTypes.PlayerData): buffer
    local schema = Module.GetTemplateSchema(data)
    
    local totalSize = 0
    local buffs = {}
    
    for _, value in ipairs(schema) do
        local buff = value.component:Serialize()
        
        totalSize += value.component:Size(buff)
        
        table.insert(buffs, buff)
    end
    
    local result = buffer.create(totalSize)
    
    local offset = 0
    
    for index, buff in ipairs(buffs) do
        local size = schema[index].component:Size(buff)
        
        buffer.copy(result, offset, buff)
        
        offset += size
    end
    
    return result
end

function Module.DeserializePlayerData(template: QuillServiceTypes.PlayerData, dataBuff: buffer): QuillServiceTypes.PlayerData
    local schema = Module.GetTemplateSchema(template)
    
    local result = Module.CopyTemplate(template)
    
    local offset = 0
    
    for _, value in ipairs(schema) do
        local component = result[value.key]
        
        local thisSize = buffer.len(dataBuff) - offset
        local thisBuff = buffer.create(thisSize)
        
        buffer.copy(thisBuff, 0, dataBuff, offset, thisSize)
        
        local size = component:Size(thisBuff)
        local buff = buffer.create(size)
        
        buffer.copy(buff, 0, dataBuff, offset, size)
        
        offset += size
        
        component:SafeWrite(component:Deserialize(buff))
    end
    
    return result
end

function Module.CopyTemplate(template: QuillServiceTypes.PlayerData): QuillServiceTypes.PlayerData
    local result: QuillServiceTypes.PlayerData = {}
    
    for key, component in pairs(template) do
        result[key] = component:Clone()
    end
    
    return result
end

return Module