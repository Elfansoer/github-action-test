function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

print("test1")
print(script_path())

require('kvparser')

print('hello, world!')

local PATH = script_path() .. "../"

-- load KV data
local stored_data = KVParser:LoadKeyValueFromFile( PATH .. "items_game.txt" )
if not stored_data then
  print('... failed. This might occur if "items_game.lua" is missing from the PATH folder.')
  print('Try run update mode first.')
  print('Aborting.')
  return false
else
  print('File loaded')
end

-- load KV into table
print( 'Loading "items_game.txt"...' )
local items_game = KVParser:LoadKeyValueFromFile( script_path() .. "../items_game.txt", KVParser.MODE_UNIQUE )

-- Create wearable list from original KV (which full of irrelevant stuff)
print( "Indexing..." )
local wearables = self:CreateWearablesTable( items_game )

-- prepare printing to file
local newtable = {}
newtable["wearables"] = wearables
newtable["slots"] = self:BuildSlots()

-- open file to write
print( 'Opening "items_game_compact.txt" for write...' )
file, err = io.open( PATH .. "items_game_compact.txt", "w" )
if not file then
   print('Error opening "items_game_compact.txt": ' .. err )
   return false
end

-- writing file
print('writing to "items_game_compact.txt"...')
file:write( "-- Elfansoer's Cosmetics Library, Simplified Item References.\n" )
file:write( "-- Generated on " .. GetSystemDate() .. ".\n" )
file:write( "\n" )
KVParser:PrintToFile( newtable, file )
file:write( "\n" )
file:close()

print('Finished.')

-- -- writing file
-- print('writing to "items_game.lua"...')
-- print( "-- Elfansoer's Cosmetics Library, Simplified Item References." )
-- print( "-- Generated on " .. GetSystemDate() .. "." )
-- print( "return [[" )
-- KVParser:PrintToConsole( newtable )
-- print( "]]" )
