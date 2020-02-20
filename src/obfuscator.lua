local cjson = require "cjson"

local _M = {}

--[[local function get_content_type(content_type)
    if content_type == nil then
        return
    end
    if string.find(content_type:lower(), "application/json", nil, true) then
        return JSON
    elseif string.find(content_type:lower(), "multipart/form-data", nil, true) then
        return MULTI
    elseif string.find(content_type:lower(), "application/x-www-form-urlencoded", nil, true) then
        return ENCODED
    end
end
]]

local function set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

local function obfuscate_entry(key, value, keys_to_obfuscate, mask)

    if not keys_to_obfuscate then 
        return
    end

    local type = type(value)
    if type ~= 'table' then
--        io.write(key, '=', value, '\n')
        return keys_to_obfuscate[key] ~= nil
    else
--       io.write(key == nil and 'root' or key, ' content:\n')
    end

    for k, v in pairs(value) do
        local should_be_obfuscated = obfuscate_entry(k, v, keys_to_obfuscate, mask)
        if should_be_obfuscated then
            value[k] = mask
        end
    end
end

function _M.obfuscate(json_string, keys_to_obfuscate, mask)
    local response = _M.obfuscate_return_table(json_string, keys_to_obfuscate, mask)
    return cjson.encode(response)
end

function _M.obfuscate_return_table(json_string, keys_to_obfuscate, mask)
    local json_object = cjson.decode(json_string)
    if keys_to_obfuscate == nil or #keys_to_obfuscate == 0 then
        return json_object
    end
    obfuscate_entry(nil, json_object, set(keys_to_obfuscate), mask)
    return json_object
end

return _M