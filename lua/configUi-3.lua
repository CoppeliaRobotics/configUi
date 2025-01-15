ConfigUI = {}

function ConfigUI:validateElemSchema(elemName, elemSchema)
    -- try to fix what is possible to fix:
    --   - infer missing information
    --   - migrate deprecated notations to current
    -- anything else -> error()

    elemSchema.key = elemSchema.key or elemName

    elemSchema.name = elemSchema.name or elemName

    elemSchema.ui = elemSchema.ui or {}

    if elemSchema.choices and #elemSchema.choices == 0 then
        error('field "choices" cannot be empty')
    end

    -- auto-guess type if missing:
    if not elemSchema.type then
        if elemSchema.choices then
            elemSchema.type = 'choices'
        elseif elemSchema.callback then
            elemSchema.type = 'callback'
        else
            error('missing type')
        end
    end

    -- standard default value if not given:
    if elemSchema.default == nil then
        if elemSchema.type == 'string' then
            elemSchema.default = ''
        elseif elemSchema.type == 'int' or elemSchema.type == 'float' then
            elemSchema.default = 0
        elseif elemSchema.type == 'color' then
            elemSchema.default = {0.85, 0.85, 1.0}
        elseif elemSchema.type == 'bool' then
            elemSchema.default = false
        elseif elemSchema.choices then
            elemSchema.default = elemSchema.choices[1]
        elseif elemSchema.type == 'callback' then
            elemSchema.default = ''
        end
    end

    if elemSchema.default == nil then
        error('missing "default" for key "' .. elemName .. '"')
    end

    if elemSchema.choices and not table.find(elemSchema.choices, elemSchema.default) then
        error('the given default for key "' .. elemName .. '" is not contained in "choices"')
    end

    -- auto-guess control if missing:
    if not elemSchema.ui.control then
        if elemSchema.type == 'string' then
            elemSchema.ui.control = 'edit'
        elseif elemSchema.type == 'float' and elemSchema.minimum and elemSchema.maximum then
            elemSchema.ui.control = 'slider'
        elseif elemSchema.type == 'int' or elemSchema.type == 'float' then
            elemSchema.ui.control = 'spinbox'
        elseif elemSchema.type == 'bool' then
            elemSchema.ui.control = 'checkbox'
        elseif elemSchema.type == 'color' then
            elemSchema.ui.control = 'color'
        elseif elemSchema.type == 'choices' then
            elemSchema.ui.control = 'radio'
        elseif elemSchema.type == 'callback' then
            elemSchema.ui.control = 'button'
        else
            error('missing "ui.control" and cannot infer it from type')
        end
    end
end

function ConfigUI:validateSchema()
    for elemName, elemSchema in pairs(self.schema) do
        local success, errorMessage = pcall(function()
            self:validateElemSchema(elemName, elemSchema)
        end)
        if not success then
            error('element "' .. elemName .. '": ' .. errorMessage)
        end
    end
end

function ConfigUI:getObject()
    if self.getObjectCallback then
        return self:getObjectCallback()
    end
    return self.targetObject or sim.getObject '.'
end

function ConfigUI:getObjectName()
    if self.getObjectNameCallback then
        return self:getObjectNameCallback()
    end
    return sim.getObjectAlias(self:getObject(), 1)
end

function ConfigUI:readSchema()
    local schema = sim.getTableProperty(self:getObject(), 'customData.' .. self.propertyName.schema, {noError=true}) or {}
    if next(schema) ~= nil then
        self.schema = {}
        for k, v in pairs(schema) do self.schema[k] = v end
    elseif self.schema == nil then
        error('schema not provided, and not found in the custom data block ' ..  self.propertyName.schema)
    end
end

function ConfigUI:defaultConfig()
    local ret = {}
    for k, v in pairs(self.schema) do ret[k] = v.default end
    return ret
end

function ConfigUI:getConfigProperty(k)
    local nsConfig = self.propertyNamespace.config or ''
    if nsConfig ~= '' then nsConfig = nsConfig .. '.' end
    return 'customData.' .. nsConfig .. k
end

function ConfigUI:readConfigConst()
    if self.schema == nil then error('readConfig() requires schema') end
    local config = self:defaultConfig()
    for k, v in pairs(self.schema) do
        local pv = sim.getProperty(self:getObject(), self:getConfigProperty(k), {noError=true})
        if pv ~= nil then config[k] = pv end
    end
    return config
end

function ConfigUI:readConfig()
    self.config = self:readConfigConst()
end

function ConfigUI:writeConfig()
    for k, v in pairs(self.schema) do
        if self.config[k] ~= nil then
            -- because of the JSON serialization between CoppeliaSim and QML,
            -- 0.0 becomes 0; so use explicit float setter:
            if self.schema[k] and self.schema[k].type == 'float' then
                sim.setFloatProperty(self:getObject(), self:getConfigProperty(k), self.config[k])
            else
                sim.setProperty(self:getObject(), self:getConfigProperty(k), self.config[k])
            end
        end
    end
end

function ConfigUI:showUi()
    if not self.uiHandle then
        self:readConfig()
        self:createUi()
    end
end

function ConfigUI:createUi()
    if self.uiHandle then return end
    self.uiHandle = simQML.createEngine()
    simQML.setEventHandler(self.uiHandle, 'dispatchEventsToFunctions')
    local qmlFile = sim.getStringParam(sim.stringparam_resourcesdir) .. '/qml/ConfigUI/ConfigUIWindow.qml'
    simQML.load(self.uiHandle, qmlFile)
    simQML.sendEvent(self.uiHandle, 'setConfigAndSchema', {
        config = self.config,
        schema = self.schema,
        objectName = sim.getObjectAlias(self:getObject(), 1),
    })
    simQML.sendEvent(self.uiHandle, 'setUiState', self.uiState)
end

function ConfigUI_uiChanged(c)
    if ConfigUI.instance then
        ConfigUI.instance:uiChanged(c)
    end
end

function ConfigUI_uiState(info)
    if ConfigUI.instance then
        ConfigUI.instance:uiStateChanged(info)
    end
end

function ConfigUI:uiChanged(c)
    for elemName, elemSchema in pairs(self.schema) do
        local v = c[elemName]
        if v ~= nil and elemSchema.type == 'int' then
            v = math.floor(v)
        end
        if v ~= nil then
            self.config[elemName] = v
        end
    end

    self:writeConfig()
end

function ConfigUI:uiStateChanged(uiState)
    for k, v in pairs(uiState) do
        self.uiState[k] = v
    end

    if self.uiHandle and not uiState.opened then
        -- UI is closing
        simQML.destroyEngine(self.uiHandle)
        self.uiHandle = nil
    end
end

function ConfigUI:sysCall_init()
    self:readSchema()
    self:validateSchema()
    self:readConfig() -- reads existing or creates default
    self:writeConfig()

    self.uiState = self.uiState or {}
    local uiState = sim.getTableProperty(self:getObject(), 'signal.configUi.uistate', {noError=true})
    if uiState then
        sim.removeProperty(self:getObject(), 'signal.configUi.uistate')
        for k, v in pairs(uiState) do
            self.uiState[k] = v
        end
    end
    if self.uiState.opened then
        self:showUi()
    end
end

function ConfigUI:sysCall_cleanup()
    -- save uistate here so it can persist a script restart:
    sim.setTableProperty(self:getObject(), 'signal.configUi.uistate', self.uiState)

    if self.uiHandle then
        simQML.destroyEngine(self.uiHandle)
        self.uiHandle = nil
    end
end

function ConfigUI:sysCall_userConfig()
    if sim.getSimulationState() == sim.simulation_stopped then
        self:showUi()
    end
end

function ConfigUI:sysCall_data(changedNames, ns)
    for changedName, g in pairs(changedNames) do
        local typ, name = changedName:match("&(.-)&%.(.*)")
        if name and string.startswith(name, self.propertyNamespace.config .. '.') then
            name = name:sub(1 + #self.propertyNamespace.config + 1)
        end
        if ns == 'customData' and self.schema[name] and g then
            self:readConfig()
            if self.uiHandle then
                simQML.sendEvent(self.uiHandle, 'setConfig', self.config)
            end
            self:generateNow()
        end
    end
end

function ConfigUI:sysCall_nonSimulation()
    if self.generatePending then --and (self.generatePending + self.generationTime)<sim.getSystemTime() then
        self.generatePending = false
        self:generateNow()
    end
end

function ConfigUI:sysCall_beforeSimulation()
    if not self.uiHandle then return end
    simQML.sendEvent(self.uiHandle, 'beforeSimulation', self.config)
end

function ConfigUI:sysCall_sensing()
    self:sysCall_nonSimulation()
end

function ConfigUI:sysCall_afterSimulation()
    if not self.uiHandle then return end
    simQML.sendEvent(self.uiHandle, 'afterSimulation', self.config)
end

function ConfigUI:setGenerateCallback(f)
    self.generateCallback = f
end

function ConfigUI:generate()
    if self.generateCallback then
        self.generatePending = true
    end
end

function ConfigUI:generateNow()
    self.generateCallback(self.config)
    -- sim.announceSceneContentChange() leave this out for now
end

function ConfigUI:__index(k)
    return ConfigUI[k]
end

setmetatable(ConfigUI, {__call = function(meta, targetObject, schema, genCb)
    sim = require 'sim'
    simQML = require 'simQML'
    if table.compare(simQML.qtVersion(), {5, 15}) < 0 then
        error('Qt version 5.15 or greater is required (have ' .. table.join(simQML.qtVersion(), '.') .. ')')
    end
    if ConfigUI.instance then
        error('multiple instances of ConfigUI not supported')
    end
    if type(targetObject) == 'string' then
        targetObject = sim.getObject(targetObject)
    end
    if targetObject ~= nil then
        assert(math.type(targetObject) == 'integer' and sim.isHandle(targetObject), 'first arg must be nil or the handle of the target object')
    end
    local self = setmetatable({
        propertyNamespace = {
            config = '',
        },
        propertyName = {
            schema = '__schema__',
        },
        targetObject = targetObject,
        schema = schema,
        generatePending = false,
        allowDuringSimulation = false,
    }, meta)
    self:setGenerateCallback(genCb)
    sim.registerScriptFuncHook('sysCall_init', function() self:sysCall_init() end)
    sim.registerScriptFuncHook('sysCall_cleanup', function() self:sysCall_cleanup() end)
    sim.registerScriptFuncHook('sysCall_userConfig', function() self:sysCall_userConfig() end, true)
    sim.registerScriptFuncHook('sysCall_data', function(...) self:sysCall_data(...) end)
    sim.registerScriptFuncHook('sysCall_nonSimulation', function() self:sysCall_nonSimulation() end)
    sim.registerScriptFuncHook('sysCall_beforeSimulation', function() self:sysCall_beforeSimulation() end, true)
    sim.registerScriptFuncHook('sysCall_sensing', function() self:sysCall_sensing() end)
    sim.registerScriptFuncHook('sysCall_afterSimulation', function() self:sysCall_afterSimulation() end, true)
    ConfigUI.instance = self
    return self
end})
