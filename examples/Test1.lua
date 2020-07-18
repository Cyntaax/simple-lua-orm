function CreateTestEntity(entityData)
    local self = {}
    entityData = entityData or {}

    if type(entityData) ~= "table" then
        entityData = {}
    end

    Model("orm_test")(self)
    Column("testval1")(self)
    Column("testval2", {
        default = "foo"
    })(self)
    Column("testval3", {
        json = true
    })(self)

    self.testval1 = ""
    self.testval2 = ""
    self.testval3 = {}

    for k,v in pairs(entityData) do
        self[k] = v
    end
    self.exampleFunc = function(val)
        print('Setting value on instance', val)
        self.testval1 = val
        self.testval3 = { ["foo"] = "bar" }
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
    local tv = CreateTestEntity({ id = 9 })
    tv.findOne(function()
        print("We got the value!", tv.testval1, tv.testval3.foo)
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

