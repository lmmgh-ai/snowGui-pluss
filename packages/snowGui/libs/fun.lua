--普通的打印函数
function dump(a_obj)
    --
    local seen = {}
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            if seen[val] then
                return tostring(val) --.. "__" .. seen[val]
            end
            if not seen[val] then
                seen[val] = 0
            end
            seen[val] = seen[val] + 1
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            if not tostring(k):find("__") then
                tokens[#tokens + 1] =
                    getIndent(level) ..
                    wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
            end
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(a_obj, 0)
end

--可以将函数表打印出来的
function dumpf(a_obj)
    --
    local seen = {}
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            if seen[val] then
                return tostring(val) --.. "__" .. seen[val]
            end
            if not seen[val] then
                seen[val] = 0
            end
            seen[val] = seen[val] + 1
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            if type(v) == "function" then
                tokens[#tokens + 1] =
                    getIndent(level) ..
                    wrapKey(k) .. " = " .. "function() end" .. ","
            else
                if not tostring(k):find("__") then
                    tokens[#tokens + 1] =
                        getIndent(level) ..
                        wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
                end
            end
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(a_obj, 0)
end
