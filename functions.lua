table.count = function(tb)
    local ct = 0
    for k,v in pairs(tb) do
        ct = ct + 1
    end

    return ct
end

GenerateQuery = function(tb, kind, queryInfo, data)
    local copy = {}
    if not data.__schema then
        print('Invalid model')

        return
    end
    for k,v in pairs(data.__schema) do
        if type(data[k]) == "table" then
            copy[k] = json.encode(data[k])
        else
            copy[k] = data[k]
        end
    end
    if kind == "insert" then
        print("inserting!")
        local tmp = {}
        local fields = ""
        local valfields = ""
        for k,v in pairs(copy) do
            fields = fields .. k .. ","
            valfields = valfields .. "@" .. k .. ","
            tmp["@" .. k] = v
        end
        fields = fields:sub(1, -2)
        valfields = valfields:sub(1, -2)

        local tmpStr = "INSERT INTO " .. tb .. "(" .. fields .. ") VALUES(" .. valfields .. ")"
        log(tmpStr, "Green")
        return function(cb)
            MySQL.Async.execute(tmpStr, tmp, function(rowsAffected)
                cb()
            end)
        end
    elseif kind == "update" then
        local tmpVals = {}
        local tmpstr = "UPDATE " .. tb .. " SET "
        queryInfo.updates = queryInfo.updates or {}
        if #queryInfo.updates == 0 then
            for b,z in pairs(copy) do
                if b ~= "id" then
                    table.insert(queryInfo.updates, b)
                end
            end
        end
        for b,z in pairs(queryInfo.updates) do
            tmpstr = tmpstr .. z .. " = @" .. z .. ","
            tmpVals["@" .. z] = copy[z]
        end

        tmpstr = tmpstr:sub(1, -2)

        if queryInfo.where then
            if table.count(queryInfo.where) > 0 then
                tmpstr = tmpstr .. " WHERE "
                local wheres = 0
                for b, z in pairs(queryInfo.where) do
                    wheres = wheres + 1
                    tmpstr = tmpstr .. b .. " = @" .. b .. " "
                    tmpVals["@" .. b] = copy[b]
                    if wheres < table.count(queryInfo.where) then
                        tmpstr = tmpstr .. " AND "
                    end
                end
            end
        end
        log(tmpstr, "Green")
        log(tmpVals)
        return function(cb)
            MySQL.Async.execute(tmpstr, tmpVals, function(affected)
                cb(affected)
            end)
        end
    elseif kind == "select" then
        local tmpValMap = {}
        local toGet = queryInfo.gets or {}
        local getStr = "SELECT "
        if #toGet == 0 then
            getStr = getStr .. "*"
        else
            local getsDone = 0
            for k,v in pairs(queryInfo.gets) do
                if type(v) == "string" then
                    getStr = getStr .. v
                    if getsDone < #queryInfo.gets then
                        getStr = getStr .. ","
                    end
                end
            end
        end

        getStr = getStr .. " FROM `" .. tb .. "` "


        local wheres = 0
        if table.count(queryInfo.where) > 0 then
            getStr = getStr .. " WHERE "
            for b,z in pairs(queryInfo.where) do
                wheres = wheres + 1
                tmpValMap["@" .. b] = z
                getStr = getStr .. b .. " = @" .. b .. " "
                if wheres < table.count(queryInfo.where) then
                    getStr = getStr .. " AND "
                end
            end

        end
        if queryInfo.limit then
            getStr = getStr .. "LIMIT " .. queryInfo.limit
        end
        log(getStr, "Green")
        return function(cb)
            MySQL.Async.fetchAll(getStr, tmpValMap, function(vals)
                if type(vals) ~= "table" then cb({}) return end
                if vals then
                    cb(vals)
                else
                    cb({})
                end
            end)
        end
    end
end

DumpTable = function(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == 'table' then
        local s = ''
        for i = 1, nb + 1, 1 do
            s = s .. "    "
        end

        s = '{\n'
        for k,v in pairs(table) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            for i = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. '['..k..'] = ' .. DumpTable(v, nb + 1) .. ',\n'
        end

        for i = 1, nb, 1 do
            s = s .. "    "
        end

        return s .. '}'
    else
        return tostring(table)
    end
end

local Colors = {
    Red = "^1",
    Green = "^2",
    Blue = "^3",
    White = "^0"
}

function log(value, color)
    color = color or "White"
    local logEnabled = GetConvar("orm_debug", "false")
    logEnabled = logEnabled == "true" and true or false
    if not logEnabled then return end
    if type(value) == "table" then value = DumpTable(value) end
    print(Colors[color] .. tostring(value) .. Colors.White)
end


print('Loaded', Model, Column)