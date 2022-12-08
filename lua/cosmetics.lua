--[[
Copyright (c) Elfansoer
]]

require( "kvparser" )

function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end

local PATH = script_path() .. "../"

--------------------------------------------------------------------------------
-- Class Definition
-- check if there is already another cosmetics library
if Cosmetics and Cosmetics.AUTHOR~="Elfansoer" then return end
Cosmetics = {}

Cosmetics.PATH = PATH
Cosmetics.VERSION = VERSION
Cosmetics.AUTHOR = "Elfansoer"

Cosmetics.initialized = false
Cosmetics.wearables = {}
Cosmetics.hero_wearables = {}
Cosmetics.default_wearables = {}
Cosmetics.slots = {}

Cosmetics.particle_replacement = {}
Cosmetics.sound_replacement = {}
Cosmetics.icon_replacement = {}
Cosmetics.model_replacement = {}

--------------------------------------------------------------------------------
-- Internal
--------------------------------------------------------------------------------
-- Update Cosmetics
function Cosmetics:Update()
  -- load KV into table
  print( 'Loading "items_game.txt"...' )
  local items_game = KVParser:LoadKeyValueFromFile( PATH .. "items_game.txt", KVParser.MODE_UNIQUE )

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
  file:write( "-- Generated on " .. os.date() .. ".\n" )
  file:write( "\n" )
  KVParser:PrintToFile( newtable, file )
  file:write( "\n" )
  file:close()

  print('Finished.')
end

-- reduce original items_game kv into compacted version
function Cosmetics:CreateWearablesTable( items_game )
	-- get only relevant KV (others such as Item price and stuff are not included)
	local items = items_game.items_game.items
	local attachments = items_game.items_game.attribute_controlled_attached_particles
	local attachIndex = self:BuildAttachmentsIndex( attachments )

	-- init table
	local wearables = {}
	local name_index = {}
	local bundles = {}

	for id,item in pairs(items) do
		-- only type wearable and default_item
		local filter1 = false
		if item.prefab=="wearable" or item.prefab=="default_item" then
			filter1 = true
		end

		-- only obtain those who have hero name
		local filter2 = false
		if type(item.used_by_heroes)=="table" then
			filter2 = true
		end

		if filter1 and filter2 then
			-- check hero
			local item_hero = nil
			local temp = item.used_by_heroes
			for k,v in pairs(temp) do
				item_hero = k
			end

			-- collect relevant data
			local data = {}
			data.index = id
			data.name = item.name or "#DOTA_Wearable_Sven_DefaultSword"
			data.hero = item_hero or "no_hero"
			data.type = item.prefab or "no_prefab"
			data.slot = item.item_slot or "weapon"
			data.model = item.model_player or ""
			data.visuals = item.visuals

			-- connect visuals and attachments
			self:ConnectVisualsAttachment( data, attachments, attachIndex )

			-- determine styles
			data.styles = self:CalculateStyles( data )

			-- register
			if tonumber( id ) then
				wearables[tonumber( id )] = data
			else
				wearables[ id ] = data
			end

			-- build name index
			name_index[ item.name ] = data

		elseif item.prefab=="bundle" and filter2 then
			-- check hero
			local item_hero = nil
			local temp = item.used_by_heroes
			for k,v in pairs(temp) do
				item_hero = k
			end

			-- collect relevant data
			local data = {}
			data.index = id
			data.name = item.name or "#DOTA_Wearable_Sven_DefaultSword"
			data.hero = item_hero or "no_hero"
			data.type = item.prefab or "no_prefab"
			data.slot = "bundle"
			data.bundle = item.bundle

			-- register
			if tonumber( id ) then
				wearables[tonumber( id )] = data
			else
				wearables[ id ] = data
			end

			-- build bundle index
			if tonumber( id ) then
				bundles[tonumber( id )] = data
			else
				bundles[ id ] = data
			end
		end
	end

	-- connect bundles index
	self:ConnectBundlesIndex( bundles, name_index )

	return wearables
end

function Cosmetics:BuildAttachmentsIndex( attachments )
	local ret = {}
	for id,valuetable in pairs(attachments) do
		local particle = valuetable.system
		if particle then
			ret[particle] = id
		end
	end

	return ret
end

function Cosmetics:ConnectVisualsAttachment( data, attachTable, attachIndex )
	if not data.visuals then return end

	-- traverse through visuals
	for asset,assetTable in pairs(data.visuals) do

		-- get asset type
		local asset_type
		if type(assetTable)=="table" then
			asset_type = assetTable.type
		end

		-- check if type particle/particle_create
		if asset_type=="particle" or asset_type=="particle_create" then
			-- get particle name
			local particle = assetTable.modifier
			-- check attachment
			local attachID = attachIndex[particle]
			if attachID then
				-- connect attachment to visual
				assetTable.attachments = attachTable[attachID]
				assetTable.attachments.system = nil
			end
		end
	end
end

function Cosmetics:CalculateStyles( data )
	local styles = 1

	if data.visuals and data.visuals.styles then
		styles = 0
		for k,v in pairs(data.visuals.styles) do
			styles = styles + 1
		end
	end

	return styles
end

function Cosmetics:ConnectBundlesIndex( bundles, name_index )
	for id,item in pairs(bundles) do
		local data = {}
		local styles = 1
		for name,_ in pairs(item.bundle) do
			local set_item = name_index[ name ]
			
			if set_item then
				-- get itemID
				data[ set_item.index ] = 1

				-- add data to wearable
				set_item.bundle = id

				if set_item.styles>styles then
					styles = set_item.styles
				end
			end
		end

		-- replace name with itemIDs
		item.bundle = data
		item.styles = styles
	end
end

function Cosmetics:BuildSlots()
	-- load 'npc_heroes.txt'
	local npc_heroes = KVParser:LoadKeyValueFromFile( PATH .. "npc_heroes.txt" )
	npc_heroes = npc_heroes["DOTAHeroes"]
	npc_heroes["Version"] = nil

	local heroes_data = {}
    	print("TestBuildSlots")
	for name,valuetable in pairs(npc_heroes) do
        print(name,valuetable)
		-- only those who has item slots
		if type(valuetable)=='table' and valuetable.ItemSlots then

			local data = {}

			-- get slots
			local slot_data = {}
			for _,slottable in pairs(valuetable.ItemSlots) do
				local temp = {}
				temp.index = tonumber(slottable.SlotIndex)
				temp.name = slottable.SlotName
				temp.text = slottable.SlotText
				temp.visible = tonumber(slottable.DisplayInLoadout) or 1

				-- register
				slot_data[ temp.name ] = temp
			end
			data.slots = slot_data

			-- get model scale
			data.model_scale = tonumber(valuetable.ModelScale) or 1

			-- store
			heroes_data[ name ] = data
		end
	end

	return heroes_data
end
