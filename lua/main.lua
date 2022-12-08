require( "kvparser" )

print('hello, world!')

-- load KV data
local stored_data = KVParser:LoadKeyValueFromFile( "items_game.txt" )
if not stored_data then
  print('... failed. This might occur if "items_game.lua" is missing from the PATH folder.')
  print('Try run update mode first.')
  print('Aborting.')
  return false
end
