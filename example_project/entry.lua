print("[Test 1] Starting test")
do
    local m1 = require("module1")
    local m2 = require("module2")
    print("[Test 1] modules imported")
    local name = m1.getRandomName()
    print("[Test 1] module1's method called")
    m2.sayHelloTo(name)
    print("[Test 1] module2's method called")
end
print("[Test 1] Test OK")

print("[Test 2] Starting test")
do
    local mods = {"module1", "module2"}
    local objs = {}
    for _, mod in pairs(mods) do
        print("Attempting to load \"" .. mod .. "\"")
        objs[mod] = require(mod)
    end
    print("[Test 2] imported modules")
    local name = objs["module1"].getRandomName()
    print("[Test 2] method 1 OK")
    objs["module2"].sayHelloTo(name)
    print("[Test 2] module 2 OK")
end
print("[Test 2] test 2 okay")