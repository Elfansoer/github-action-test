function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

print("test1")
print(script_path())

require('kvparser')

print('hello, world!')

-- load KV data
local stored_data = KVParser:LoadKeyValueFromFile( script_path() .. "../items_game.txt" )
if not stored_data then
  print('... failed. This might occur if "items_game.lua" is missing from the PATH folder.')
  print('Try run update mode first.')
  print('Aborting.')
  return false
else
  print('File loaded')
end
