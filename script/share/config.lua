require 'filesystem'
local lni = require 'lni'
local lang = require 'share.lang'
local input_path = require 'share.input_path'
local command = require 'share.command'
local builder = require 'map-builder'
local config_loader = require 'share.config_loader'
local root = fs.current_path()
local default_config
local global_config

local function save()
    local lines = {}
    for name, t in pairs(global_config) do
        lines[#lines+1] = ('[%s]'):format(name)
        for k, _, v in pairs(t) do
            lines[#lines+1] = ('%s = %s'):format(k, v)
        end
        lines[#lines+1] = ''
    end
    local buf = table.concat(lines, '\r\n')
    io.save(root:parent_path() / 'config.ini', buf)
end

local function load_config(buf, fill)
    local config = config_loader()
    local lni = lni(buf or '', 'config.ini')
    for name, t in pairs(config) do
        if type(lni[name]) == 'table' then
            for k in pairs(t) do
                if fill or lni[name][k] ~= nil then
                    t[k] = lni[name][k]
                end
            end
        end
    end
    return config
end

local function proxy(default, global, map, merge)
    local table = {}
    local funcs = {}
    local comments = {}
    for k, v, _, func, comment in pairs(default) do
        if type(v) == 'table' then
            table[k] = proxy(v, global[k] or {}, map[k] or {}, merge)
        else
            funcs[k] = func
            comments[k] = comment
        end
    end
    table._default = default
    table._global  = global
    table._map     = map
    setmetatable(table, {
        __index = function (_, k)
            if merge then
                if map[k] ~= nil then
                    return map[k]
                elseif global[k] ~= nil then
                    return global[k]
                else
                    return default[k]
                end
            else
                if funcs[k] ~= nil then
                    return { default[k], global[k], map[k], funcs[k], comments[k] }
                else
                    return nil
                end
            end
        end,
        __newindex = function (_, k, v)
            global[k] = v
            save()
        end,
        __pairs = function ()
            local next = pairs(default)
            return function ()
                local k = next()
                return k, table[k]
            end
        end,
    })
    return table
end

return function (path, ext)
    if not default_config then
        default_config = load_config(io.load(root / 'share' / 'config.ini'), true)
    end
    if not global_config then
        global_config = load_config(io.load(root:parent_path() / 'config.ini'), false)
    end
    local map_config
    if path then
        local map = builder.load(input_path(path))
        if map then
            map_config = load_config(map:get 'w3x2lni\\config.ini', false)
            map:close()
        end
        if not map_config then
            map_config = load_config()
        end
    else
        map_config = {}
    end
    if ext then
        local t1 = proxy(default_config, global_config, map_config, true)
        local t2 = proxy(default_config, global_config, map_config, false)
        return t1, t2
    else
        local t1 = proxy(default_config, global_config, map_config, true)
        return t1
    end
end
