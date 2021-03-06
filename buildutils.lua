--[[
    BuildUtils
    Version 1.0.0
    Ethan Manzi

    The executable file!

    ARGUMENTS MUST GO IN THIS ORDER! Only thing that can be out of order is options!
    buildutils [output] [entry]
]]

-- Import libraries
local minifylib = require("libraries/minifylib")

-- Define constants
local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

-- Get the arguments
local args = {...}

-- Define some variables
local output = args[1]
local entry = args[2]

-- Helper methods
function readFile(filePath)
    local sourceFile = io.open(filePath, 'r')
    if not sourceFile then
        error("Could not open the input file `" .. filePath .. "`", 0)
    end
    local data = sourceFile:read('*all')
    sourceFile:close()
    return data
end
function writeFile(filePath, data)
    local sourceFile = io.open(filePath, 'w')
    if not sourceFile then
        error("Could not open the input file `" .. filePath .. "`", 0)
    end
    local data = sourceFile:write(data)
    sourceFile:close()
    return data
end

function devisionWhole(a, b)
    if a%b==a then return 0 end
    return (a-(a%b)/b)
end

function intToBundleID(value)
    local l = value % #charset
    local m = devisionWhole(value, #charset)
    local r = "m"
    r = r .. charset:sub(l,l)
    r = r .. m
    return r
end

function splitFilePath(path)
    local segments = {}
    for segment in path:gmatch('([^/]*)/?') do
        if segment == "" then
            if #segments == 0 then
                table.insert(segments, "/")
            end
        else
            table.insert(segments, segment)
        end
    end
    return segments
end

function dropLastPathValue(pathStr)
    local path = splitFilePath(pathStr)
    local result = ""
    for i=1, ((#path) - 1) do
        result = result .. path[i] .. "/"
    end
    local fchar = result:sub(1,1):lower()
    if not ((fchar == "/") or (fchar == "~") or (fchar == ".")) then
        result = "./" .. result
    end
    return result
end

function preprocessCode(code)
    code = code:gsub("%-%-.-\n", "") -- remove single line comments
    code = code:gsub("%-%-%[%[[.\n]-%]%]", "") -- remove multi-line comments
    return code
end

function bundlify(entryPath)
    local moduleLookupTable = {
        -- ["a1"] = "~/path/to/file.lua"
    }
    local humanNameLookupTree = {}
    local modules = {}
    local toImport = {}
    local currentModuleID = 1

    local function sniffProgram(path)
        -- read in the code
        local filepath = path
        if (path:sub(path:len() - 3):lower()) ~= ".lua" then
            filepath = filepath .. ".lua"
        end

        local code = readFile(filepath)

        code = preprocessCode(code)

        -- find any 'require("somepath")' statments
        for requiredModule in code:gmatch('require%("(.-)"%)') do
            print("Found require statement in \"" .. filepath .. "\" => 'require(\"" .. requiredModule .. "\")")
            local targetModulePath
            local replacementID
            local firstchar = requiredModule:sub(1,1):lower()
            if (firstchar == "~") or (firstchar == "/") then
                -- it is an ABSOLUTE path
                targetModulePath = requiredModule:lower()
            else
                -- it is a RELATIVE path
                local newpath = dropLastPathValue(path)
                if newpath:sub(newpath:len()):lower() ~= "/" then
                    newpath = newpath .. "/"
                end
                targetModulePath = (newpath .. requiredModule):lower()
            end

            -- check if this module has already been required (and indexed)
            for ID, path in pairs(moduleLookupTable) do
                if path == targetModulePath then
                    replacementID = ID
                end
            end

            -- check if an entry was found
            if replacementID == nil then
                -- nope!
                replacementID = intToBundleID(currentModuleID)
                currentModuleID = currentModuleID + 1
                moduleLookupTable[replacementID] = targetModulePath
                local pathsegs = splitFilePath(requiredModule)
                print("Added reverse lookup! (HUMAN:\"" .. pathsegs[#pathsegs] .. "\") => (ID:\"" .. replacementID .. "\")")
                humanNameLookupTree[pathsegs[#pathsegs]] = replacementID
                table.insert(toImport, replacementID) 
            end

            -- replace that require statment
            local search = 'require("' .. requiredModule .. '")'
            local replace = 'require("' .. replacementID .. '")'
            local pattrf = 'require%("' .. requiredModule .. '"%)'
            local pattrt = 'require("' .. replacementID .. '")'
            --print("FIND PATTERN: " .. pattrf)
            --print("REPLACE PATTERN: " .. pattrt)
            code = code:gsub(pattrf, pattrt)
            --print("Replaced '" .. search .. "' with '" .. replace .. "' in \"" .. filepath .. "\"!")
            --print("----------[ PATCHED OUTPUT ]----------")
            --print(code)
            --print("----------[ PATCHED OUTPUT ]----------")
        end

        return code
    end

    local fixedEntry = sniffProgram(entryPath)

    local ID = table.remove(toImport)
    while ID ~= nil do
        local modulePath = moduleLookupTable[ID]
        local patchedSource = sniffProgram(modulePath)
        modules[ID] = patchedSource
        ID = table.remove(toImport)
    end

    return fixedEntry, modules, humanNameLookupTree
end

function santiseString(str)
    str = str:gsub("\\", "\\\\")
    str = str:gsub("\"", "\\\"")
    str = str:gsub("\n", " ")
    return str
end

-- WORKSPACE
local _MODULES_ = {["MODULEID"]="LUA CODE AS STRING"}
function bunreq(name) return load(assert(_MODULES_[name], "Bundled module not found!"))() end
-- WORKSPACE

function merge(entrycode, modules, humanTable)
    local bundlescript = ""

    -- build the module table
    local modtable = "local _M={"
    for moduleID, module in pairs(modules) do
        local mout = module
        mout = minifylib.minify(mout)
        mout = santiseString(mout)

        modtable = modtable .. "[\"" .. santiseString(moduleID) .. "\"]=\"" .. mout .. "\","
    end
    modtable = modtable .. "}"
    
    -- build the human name lookup table
    local hnlt = "local _H={"
    for humanName, ID in pairs(humanTable) do
        hnlt = hnlt .. "[\"" .. santiseString(humanName) .. "\"]=\"" .. ID .. "\","
    end
    hnlt = hnlt .. "}"

    -- add the main code
    bundlescript = bundlescript .. "\n" .. entrycode

    return bundlescript, modtable, hnlt
end

--[[
function require(_n)
    return assert(
        load(
            assert(
                (_M[_n] or _H[_n]),
                "Bundled module not found!"
            )
        ),
        "Unable to load module script!"
    )()
end;
]]

function addHeader(script, modtable, humanLookup)
    local header = modtable
    header = header .. " " .. humanLookup
    header = header .. " " .. "function require(_n)return assert(load(assert((_M[_n] or _M[_H[_n]]),\"Bundled module not found!\")),\"Unable to load module script!\")()end;"

    return header .. script
end

-- print("----------[ START ]----------")
-- Start the bundler process
local ec, ml, hlt = bundlify(entry)
local bundle, mt, phlt = merge(ec, ml, hlt)

-- print("------[ PRECOMPRESSED ]------")
-- print(bundle)
-- print("------[ PRECOMPRESSED ]------")

-- Minify the bundle
local bundle_min = minifylib.minify(bundle)
bundle_min = addHeader(bundle_min, mt, phlt)

-- Export the bundle
writeFile(output, bundle_min)