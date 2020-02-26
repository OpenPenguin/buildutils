function tokenify(str)
    local segments = {}
    local buffer = ""
    local inStringEnclosure = {["state"]=false, ["character"]=""}

    local function pushBuffer(upperBound, lowerBound)
        if (buffer == "") or (buffer == " ") then
            return
        end

        if upperBound == nil then
            upperBound = 1
        end
        if lowerBound == nil then
            lowerBound = string.len(buffer) - 1
        end

        table.insert(segments, string.sub(buffer, upperBound, lowerBound))
        buffer = ""
    end

    for characterIndex = 1, string.len(str) do
        local char = string.sub(str, characterIndex, characterIndex)
        buffer = buffer .. char
        if (char == " ") and (not inStringEnclosure["state"]) then
            pushBuffer()
        elseif (char == "'") or (char == '"') then
            if (inStringEnclosure["state"]) and (inStringEnclosure["character"] == char) then
                pushBuffer()
            elseif not inStringEnclosure["state"] then
                inStringEnclosure = {["state"]=true, ["character"]=char}
                buffer = string.sub(buffer, 1, string.len(buffer) - 1)
            end
        end
    end

    pushBuffer()
    return segments
end

return tokenify