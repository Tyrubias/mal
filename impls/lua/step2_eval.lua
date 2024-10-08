#!/usr/bin/env lua

local table = require('table')

local readline = require('readline')
local utils = require('utils')
local types = require('types')
local reader = require('reader')
local printer = require('printer')
local List, Vector, HashMap = types.List, types.Vector, types.HashMap

-- read
function READ(str)
    return reader.read_str(str)
end

-- eval

function EVAL(ast, env)

    -- print("EVAL: " .. printer._pr_str(ast, true))

    if types._symbol_Q(ast) then
        if env[ast.val] == nil then
            types.throw("'"..ast.val.."' not found")
        end
        return env[ast.val]
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

    local f = EVAL(ast[1], env)
    local args = types.slice(ast, 2)
    args = utils.map(function(x) return EVAL(x,env) end, args)
    return f(table.unpack(args))
end

-- print
function PRINT(exp)
    return printer._pr_str(exp, true)
end

-- repl
local repl_env = {['+'] = function(a,b) return a+b end,
                  ['-'] = function(a,b) return a-b end,
                  ['*'] = function(a,b) return a*b end,
                  ['/'] = function(a,b) return math.floor(a/b) end}
function rep(str)
    return PRINT(EVAL(READ(str),repl_env))
end

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
