--[[
    BuildUtils
    Version 1.0.0
    Ethan Manzi

    The executable file!

    ARGUMENTS MUST GO IN THIS ORDER! Only thing that can be out of order is options!
    buildutils [output] [entry point] ([module name] [module path])
]]

local minifylib = require("libraries/minifylib")

function parseArguments(args)
    local output = nil
    local entry = nil
    local modules = {}
    local currentModule = {["name"]=nil, ["path"]=nil}
    local options = {}

    for argumentNumber, argument in pairs(args) do
        if string.sub(argument, 1, 2):lower() == "--" then
            -- it's a flag!
            table.insert(options, string.sub(argument, 2))
        elseif string.sub(argument, 1, 1):lower() == "-" then
            -- it's an option!
            local opts = string.sub(argument, 2)
            for char=1, string.len(opts) do
                table.insert(options, string.sub(opts, char, char)) 
            end
        else
            if output == nil then
                -- the output always comes first
                output = argument
            elseif entry == nil then
                entry = argument
            else
                if currentModule["name"] == nil then
                    currentModule["name"] = argument
                elseif currentModule["path"] == nil then
                    currentModule["path"] = argument
                    -- print("NAME: " .. currentModule["name"])
                    -- print("PATH: " .. currentModule["path"])
                    print("[ADDING MODULE] Name \"" .. currentModule["name"] .. "\", Path \"" .. currentModule["path"] .. "\"!")
                    table.insert(modules, currentModule)
                    currentModule = {["name"]=nil, ["path"]=nil}
                end
                -- How did we get here?
            end
        end
    end

    return output, entry, modules, options
end

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

function processSource(source)

end

function convertModule(source)

end

function main(_ARG)
    -- The entry point!
    local output, entry, modules, options = parseArguments(_ARG)
    local entryCode = readFile(entry)
    local bundleOutput = ""
    local bundleModuleArray = "local _MODULES_={"

    print("Compressing entry code")
    entryCode = minifylib.minify(entryCode)

    -- load all the modules in
    print("Processing modules")
    for _, module in pairs(modules) do
        print("Importing module " .. module["name"])
        local script = readFile(module["path"])
        print("-----\n" .. script .. "\n-----")
        local scriptMinified = minifylib.minify(script)
        local scriptStringStripped = string.gsub(scriptMinified, '"', '\\"')
        bundleModuleArray = bundleModuleArray .. "[\"" .. module["name"] .. "\"]=\"" .. scriptStringStripped .. "\","
    end
    bundleModuleArray = bundleModuleArray .. "}"
    bundleOutput = bundleOutput .. "\n" .. bundleModuleArray
    bundleOutput = bundleOutput .. "local _oreq=require function require(_n)if(_MODULES_[_n]~=nil)then return load(_MODULES_[_n])() else return _oreq(_n) end end"
    bundleOutput = bundleOutput .. "\n"
    bundleOutput = bundleOutput .. entryCode

    print("exporting")
    writeFile(output, bundleOutput)
end

main({...}) --  Pass the arguments to the entry-point method