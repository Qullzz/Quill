-- // MODULES // --
local QuillServiceTypes = require(script.Parent.QuillServiceTypes)

-- // MAIN // --

local Module = {}

function Module.GetTemplateSchema(template: QuillServiceTypes.PlayerData): { { key: QuillServiceTypes.PlayerDataKey, quill: QuillServiceTypes.Quill } }
    local keys: { QuillServiceTypes.PlayerDataKey } = {}
    
    for key, _ in pairs(template) do
        table.insert(keys, key)
    end
    
    table.sort(keys, function(key1, key2)
        return key1 < key2
    end)
    
    local result = {}
    
    for index, key in ipairs(keys) do
        result[index] = { key = key, quill = template[key] }
    end
    
    return result
end

function Module.SerializePlayerData(data: QuillServiceTypes.PlayerData): buffer
    local schema = Module.GetTemplateSchema(data)
    
    local total_size = 0
    local buffs = {}
    
    for _, value in ipairs(schema) do
        local buff = value.quill:Serialize()
        
        total_size += buffer.len(buff)
        
        table.insert(buffs, buff)
    end
    
    local result = buffer.create(total_size)
    
    local offset = 0
    
    for _, buff in ipairs(buffs) do
        local size = buffer.len(buff)
        
        buffer.copy(result, offset, buff)
        
        offset += size
    end
    
    return result
end

function Module.DeserializePlayerData(template: QuillServiceTypes.PlayerData, data_buff: buffer): QuillServiceTypes.PlayerData
    local schema = Module.GetTemplateSchema(template)
    
    local result = Module.CopyTemplate(template)
    
    local offset = 0
    
    for _, value in ipairs(schema) do
        local quill = result[value.key]
        
        local size = buffer.len(quill:Serialize())
        local buff = buffer.create(size)
        
        buffer.copy(buff, 0, data_buff, offset, size)
        
        offset += size
        
        quill(quill:Deserialize(buff))
    end
    
    return result
end

function Module.CopyTemplate(template: QuillServiceTypes.PlayerData): QuillServiceTypes.PlayerData
    local result: QuillServiceTypes.PlayerData = {}
    
    for key, quill in pairs(template) do
        result[key] = quill:Clone()
    end
    
    return result
end

return Module