function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

print("test1")
print(script_path())

require('kvparser')
require('cosmetics')
print('hello, world!')
print(Cosmetics)
