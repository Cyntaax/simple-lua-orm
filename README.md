## Simple ORM for FiveM/RedM Lua

This is a simple, and I mean **simple** orm put together for FiveM/RedM.
It will prevent writing the same queries several times.

This seemed to work well with MessagePack for me, so you'll be able to send the objects over TriggerEvent/Exports 

More advanced things will be added as time goes on like auto migration and such, but this works for now!

#### Usage

```
.
+--- fxmanifest.lua
+--- server
|     +--- lib/
|           +--- simple-orm/ 
|     +--- server.lua
```

```lua
--- include with your resource
server_scripts {
    'server/lib/**/*.lua',
    'server/server.lua'
}

```

#### Decorators

#### Model
```lua
--- name string Name of the table
Model(name, {
    --- Whether the table has the field `id`. This is recommended.
    noId = boolean
})
```

#### Column

```lua
Column(name, {
    --- Flags this column as primary key. There can only be one
    --- @type boolean
    primaryKey = true or false,
    --- Flags this column as a composite key. There can be multiple
    --- @type boolean
    compositeKey = true or false,
    --- The default value of this field. Every instance will be initialized with this.
    --- @type any
    default = T,
    --- Whether or not this field is json. Will be automatically deserialized if so.
    --- @type boolean
    json = true or false
})
```

#### Methods

```lua
--- Grabs a single entity that matches the given conditions. Requires at least 1 unique property to be set. See example
--- @param callback func(entity): void calls back with an instance of the entity if found, otherwise nil
--- The options for this find operation
--- @param options? QueryOptions
entity.findOne(function(entity) end, {
    --- The same as WHERE column = value AND column2 = value2
    where = {
        column = value,
        column2 = value
    },
    readOnly = true or false
}))

--- Grabs an array of entities that match the given conditions or just all if no condition given
--- @param callback func(entities): void calls back with an array of instances of the entity
--- @param options? - same options as above
entity.findAll(function(entities) end, options))

--- Will save or update the entity (Insert or Update)
--- @param callback func(entity): void calls back with the same entity
entity.save(function(entity) end)
```

## Example

```lua
--- server.lua
function CreateTestEntity(entityData)
    local self = {}
    entityData = entityData or {}
    
    if type(entityData) ~= "table" then
        entityData = {}
    end
    
    Model("orm_test")(self)
    self.testval1 = ""
    self.testval2 = ""
    self.testval3 = ""

    --- You will need to run this if you want to easily create entities
    for k,v in pairs(entityData) do
        self[k] = v
    end
    
    Column("testval1")(self)
    Column("testval2", {
    default = "foo"
    })(self)
    Column("testval3")(self)
    
    self.exampleFunc = function(val)
        print('Setting value on instance', val)
        self.testval1 = val
    end
    
    return self
end

RegisterCommand('tval1', function(source, args, raw)
    local tv = CreateTestEntity({})
    local inputVal = args[1] or GetGameTimer()
    tv.exampleFunc(inputVal)
    
    tv.save(function(e)
        print('saved!', e)
    end)
end, true)

RegisterCommand('gval3', function(source, args, raw)
    local tv = CreateTestEntity({ id = 3 })
    tv.findOne(function()
        print("We got the value!", tv.testval1)
    end)
end, true)

RegisterCommand('getallval', function(source, args, raw)
    local tv = CreateTestEntity({})
    tv.findAll(function(tvs)
        for k, instance in pairs(tvs) do
            instance.exampleFunc(GetGameTimer())
        end
    end)
end, false)
```