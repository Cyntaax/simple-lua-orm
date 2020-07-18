Model = function(name, options)
    options = options or {}
    return function(obj)
        local self = {}
        self.__tablename = name
        self.__schema = {
            id = {
                column_name = "id"
            }
        }

        if not options.noId then
            obj.id = 0
        end

        self.findOne =  function(cb, options)
            options = options or {}
            options.limit = 1
            options.where = options.where or {}
            local primaryKey
            local compositeKeys = {}
            for k,v in pairs(obj.__schema) do
                if v.primaryKey == true then
                    primaryKey = v.column_name
                elseif v.compositeKey == true then
                    table.insert(compositeKeys, k)
                end
            end

            if primaryKey then
                options.where[primaryKey] = obj[primaryKey]
            else
                options.where["id"] = obj.id
            end

            for k,v in pairs(compositeKeys) do
                options.where[v] = obj[v]
            end

            GenerateQuery(obj.__tablename, "select", options, obj)(function(vals)
                if vals[1] then
                    for k,v in pairs(vals[1]) do
                        if not options.readOnly then
                            local colCfg = obj.__schema[k] or {}
                            if colCfg.json == true then
                                obj[k] = json.decode(v) or v
                            else
                                obj[k] = v
                            end
                        end
                    end
                    cb(obj)
                else
                    cb(nil)
                end
            end)
        end

        self.findAll = function(cb, options)
            options = options or {}
            options.where = options.where or {}

            GenerateQuery(obj.__tablename, "select", options, obj)(function(vals)
                local tmp = {}
                for k,v in pairs(vals) do
                    local copy = {}
                    for b,z in pairs(obj) do
                        copy[b] = z
                    end
                    copy[k] = v
                    table.insert(tmp, copy)
                end
                cb(tmp)
            end)
        end

        self.save = function(cb, options)
            local primaryKey
            local compositeKeys = {}
            options = options or {}
            options.where = options.where or {}
            for k,v in pairs(obj.__schema) do
                if v.primaryKey == true then
                    primaryKey = v.column_name
                elseif v.compositeKey == true then
                    table.insert(compositeKeys, k)
                end
            end

            if primaryKey then
                options.where[primaryKey] = obj[primaryKey]
            end

            for k,v in pairs(compositeKeys) do
                options.where[v] = obj[v]
            end

            if obj.id ~= nil then
                options.where["id"] = obj.id
            end
            obj.findOne(function(cObj)
                if cObj then
                    GenerateQuery(obj.__tablename, "update", options, obj)(function(af)
                        if type(cb) == "function" then
                            cb(af)
                        end
                    end)
                else
                    options.readOnly = true
                    GenerateQuery(obj.__tablename, "insert", {}, obj)(function(cObj)
                        if type(cb) == "function" then
                            cb(cObj)
                        end
                    end)
                end
            end, { readOnly = true })
        end

        for k,v in pairs(self) do
            obj[k] = v
        end
    end
end