local mod1 = {}

function mod1.getRandomName()
    local names = {
        "Anthony",
        "Beth",
        "Charile",
        "David",
        "Ethan"
    }
    return names[math.random(1, #names)]
end

return mod1