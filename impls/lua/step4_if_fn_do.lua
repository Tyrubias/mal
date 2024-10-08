#!/usr/bin/env lua

local table = require('table')

local readline = require('readline')
local utils = require('utils')
local types = require('types')
local reader = require('reader')
local printer = require('printer')
local Env = require('env')
local core = require('core')
local List, Vector, HashMap = types.List, types.Vector, types.HashMap

-- read
function READ(str)
    return reader.read_str(str)
end

-- eval

function EVAL(ast, env)

    local dbgeval = env:get("DEBUG-EVAL")
    if dbgeval ~= nil and dbgeval ~= types.Nil and dbgeval ~= false then
        print("EVAL: " .. printer._pr_str(ast, true))
        env:debug()
    end

    if types._symbol_Q(ast) then
        local result = env:get(ast.val)
        if result == nil then
            types.throw("'" .. ast.val .. "' not found")
        end
        return result
    elseif types._vector_Q(ast) then
        return Vector:new(utils.map(function(x) return EVAL(x,env) end,ast))
    elseif types._hash_map_Q(ast) then
        local new_hm = {}
        for k,v in pairs(ast) do
            new_hm[k] = EVAL(v, env)
        end
        return HashMap:new(new_hm)
    elseif not types._list_Q(ast) or #ast == 0 then
        return ast
    end

    local a0,a1,a2,a3 = ast[1], ast[2],ast[3],ast[4]
    local a0sym = types._symbol_Q(a0) and a0.val or ""
    if 'def!' == a0sym then
        return env:set(a1.val, EVAL(a2, env))
    elseif 'let*' == a0sym then
        local let_env = Env:new(env)
        for i = 1,#a1,2 do
            let_env:set(a1[i].val, EVAL(a1[i+1], let_env))
        end
        return EVAL(a2, let_env)
    elseif 'do' == a0sym then
        local el = utils.map(function(x) return EVAL(x, env) end, types.slice(ast, 2))
        return el[#el]
    elseif 'if' == a0sym then
        local cond = EVAL(a1, env)
        if cond == types.Nil or cond == false then
            if #ast > 3 then return EVAL(a3, env) else return types.Nil end
        else
            return EVAL(a2, env)
        end
    elseif 'fn*' == a0sym then
        return function(...)
            return EVAL(a2, Env:new(env, a1, table.pack(...)))
        end
    else
        local f = EVAL(a0, env)
        local args = types.slice(ast, 2)
        args = utils.map(function(x) return EVAL(x,env) end, args)
        return f(table.unpack(args))
    end
end

-- print
function PRINT(exp)
    return printer._pr_str(exp, true)
end

-- repl
local repl_env = Env:new()
function rep(str)
    return PRINT(EVAL(READ(str),repl_env))
end

-- core.lua: defined using Lua
for k,v in pairs(core.ns) do
    repl_env:set(k, v)
end

-- core.mal: defined using mal
rep("(def! not (fn* (a) (if a false true)))")

if #arg > 0 and arg[1] == "--raw" then
    readline.raw = true
end

while true do
    line = readline.readline("user> ")
    if not line then break end
    xpcall(function()
        print(rep(line))
    end, function(exc)
        if exc then
            if types._malexception_Q(exc) then
                exc = printer._pr_str(exc.val, true)
            end
            print("Error: " .. exc)
            print(debug.traceback())
        end
    end)
end
