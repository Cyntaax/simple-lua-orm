Column = function(name, options)
    return function(obj)
        options = options or {}
        options = options or {}
        obj.__schema[name] = {
            column_name = name,
            type = options.type or "string",
            primaryKey = options.primaryKey,
            compositeKey = options.compositeKey,
            json = options.json
        }

        if options.default then
            log("Setting " .. name .. " default value " .. tostring(options.default))
            obj[name] = options.default
        end

    end
end