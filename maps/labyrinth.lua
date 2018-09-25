--labyrinth-- mewmew made this --
require "maps.labyrinth_map_intro"
--local simplex_noise = require 'utils.simplex_noise'
--simplex_noise = simplex_noise.d2
local event = require 'utils.event' 

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function create_cluster(name, pos, size, surface, spread, resource_amount)		
	local p = {x = pos.x, y = pos.y}
	local math_random = math.random
	for z = 1, size, 1 do											
		for x = 1, 8, 1 do
			local y = 1
			if spread then y = math_random(1, spread) end
			local modifier_raffle = {{0,y*-1},{y*-1,0},{y,0},{0,y},{y*-1,y*-1},{y,y},{y,y*-1},{y*-1,y}}
			modifier_raffle = shuffle(modifier_raffle)
			local m = modifier_raffle[x]
			local pos = {x = p.x + m[1], y = p.y + m[2]}
			if resource_amount then
				if surface.can_place_entity({name=name, position=pos, amount=resource_amount}) then
					surface.create_entity {name=name, position=pos, amount=resource_amount}				
					p = {x = pos.x, y = pos.y}
					break
				end
			else
				if surface.can_place_entity({name=name, position=pos}) then
					surface.create_entity {name=name, position=pos}
					p = {x = pos.x, y = pos.y}	
					break
				end
			end
		end		
	end
end

local function get_entity_chunk_position(entity_position)
	local chunk_position = {}
	for x = 0, 31, 1 do
		if (entity_position.x - x) % 32 == 0 then chunk_position.x = (entity_position.x - x)  / 32 end
	end
	for y = 0, 31, 1 do
		if (entity_position.y - y) % 32 == 0 then chunk_position.y = (entity_position.y - y)  / 32 end
	end	
	return chunk_position
end

local function is_chunk_allowed_to_grow(chunk_position, surface)
	local pos_x = chunk_position.x * 32
	local pos_y = chunk_position.y * 32
	local area = {
			left_top = {x = pos_x, y = pos_y},
			right_bottom = {x = pos_x + 31, y = pos_y + 31}
			}
	if surface.count_entities_filtered{area = area, name = {"sand-rock-big", "rock-big", "rock-huge"}, limit = 1} == 0 then
		return true
	else
		return false
	end	
end

local function is_canditate_chunk_valid(chunk, surface)
	local modifiers = {{0,-1},{-1,0},{1,0},{0,1}, {-1,-1},{1,1},{1,-1},{-1,1}}
	local invalid_places = 0
	for _, m in pairs(modifiers) do
		local testing_chunk = {x = chunk.x + m[1], y = chunk.y + m[2]}
		local left_top_x = testing_chunk.x * 32
		local left_top_y = testing_chunk.y * 32
		--game.print("x: " .. left_top_x .. " y: " .. left_top_y)
		local tile = surface.get_tile({left_top_x, left_top_y})
		if tile.name ~= "out-of-map" then invalid_places = invalid_places + 1 end
	end
	if math.random(1,40) == 1 and chunk.y < -3 then return true end
	if invalid_places <= 2 then return true end
	if invalid_places > 2 then return false end
end

local worm_raffle = {}
worm_raffle[1] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret"}
worm_raffle[2] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret"}
worm_raffle[3] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret"}
worm_raffle[4] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret"}
worm_raffle[5] = {"small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
worm_raffle[6] = {"small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
worm_raffle[7] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"}
worm_raffle[8] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"}
worm_raffle[9] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
worm_raffle[10] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
local rock_raffle = {"sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local ore_spawn_raffle = {"iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal","stone","stone","uranium-ore","crude-oil"}
local room_layouts = {"quad_rocks", "single_center_rock", "three_horizontal_rocks", "three_vertical_rocks", "tree_and_lake", "forest", "forest_fence"}
local biter_raffle = {
	{"small-biter"},
	{"small-biter","small-biter","small-biter","medium-biter"},
	{"small-biter","small-biter","medium-biter","medium-biter"},
	{"small-biter","medium-biter","medium-biter","medium-biter"},
	{"small-biter","medium-biter","medium-biter","big-biter"},
	{"medium-biter","medium-biter","medium-biter","big-biter"},
	{"medium-biter","medium-biter","big-biter","big-biter"},
	{"medium-biter","big-biter","big-biter","big-biter"},
	{"big-biter","big-biter","big-biter","behemoth-biter"},
	{"big-biter","big-biter","behemoth-biter","behemoth-biter"}	
}
local spitter_raffle = {
	{"small-spitter"},
	{"small-spitter","small-spitter","small-spitter","medium-spitter"},
	{"small-spitter","small-spitter","medium-spitter","medium-spitter"},
	{"small-spitter","medium-spitter","medium-spitter","medium-spitter"},
	{"small-spitter","medium-spitter","medium-spitter","big-spitter"},
	{"medium-spitter","medium-spitter","medium-spitter","big-spitter"},
	{"medium-spitter","medium-spitter","big-spitter","big-spitter"},
	{"medium-spitter","big-spitter","big-spitter","big-spitter"},
	{"big-spitter","big-spitter","big-spitter","behemoth-spitter"},
	{"big-spitter","big-spitter","behemoth-spitter","behemoth-spitter"}	
}
local room_enemies = {}
local room_enemy_weights = {
	{"only_biters", 10},
	{"only_spitters", 10},
	{"biters_and_spitters", 10},
	{"spawners", 7},
	{"only_worms", 5},
	{"worms_and_spawners", 5},
	{"gun_turrets", 5},
	{"allied_entities", 3},
	{"allied_entities_mixed", 1}
}

for _, t in pairs (room_enemy_weights) do
	for x = 1, t[2], 1 do
		table.insert(room_enemies, t[1])
	end			
end

local function grow_cell(chunk_position, surface)
	local math_random = math.random
	local modifier_raffle = {{0,-1},{-1,0},{1,0},{0,1}}
	modifier_raffle = shuffle(modifier_raffle)
	local canditate_chunks = {}
	for _, m in pairs(modifier_raffle) do
		local canditate_chunk = {x = chunk_position.x + m[1], y = chunk_position.y + m[2]}
		local left_top_x = canditate_chunk.x * 32
		local left_top_y = canditate_chunk.y * 32		
		local tile = surface.get_tile({left_top_x, left_top_y})
		if tile.name == "out-of-map" then table.insert(canditate_chunks, canditate_chunk) end
	end
	local valid_chunks = {}
	for _, chunk in pairs(canditate_chunks) do		 
		if is_canditate_chunk_valid(chunk, surface) == true then
			table.insert(valid_chunks, {x = chunk.x, y = chunk.y})
		end
	end	
	if #valid_chunks == 0 then game.print("Dead end reached.") return end
	
	local tree_raffle = {}
	for _, e in pairs(game.entity_prototypes) do
		if e.type == "tree" then
			table.insert(tree_raffle, e.name)
		end			
	end
	
	local allied_entity_raffle = {}
	local types = {"inserter", "transport-belt", "underground-belt", "electric-pole", "pipe", "furnace", "assembling-machine", "splitter"}
	for _, e in pairs(game.entity_prototypes) do
		for _, t in pairs(types) do
			if e.type == t then
				table.insert(allied_entity_raffle, e.name)				
			end
		end
	end
	
	global.labyrinth_size = global.labyrinth_size + 1
	local evolution = global.labyrinth_size / 250
	if evolution > 1 then evolution = 1 end
	game.forces.enemy.evolution_factor = evolution
	
	for x = 1, math_random(1,#valid_chunks), 1 do
		local chunk_position = valid_chunks[x]
		local left_top_x = chunk_position.x * 32
		local left_top_y = chunk_position.y * 32
		local tile_to_insert = false
		local tiles = {}
		local entities_to_place = {
		rocks = {},
		worms = {},
		enemy_buildings = {},
		trees = {},
		fish = {},		
		biters = {},
		spitters = {},
		gun_turrets = {},
		allied_entities = {}
		}
		 
		local tree_name = tree_raffle[math_random(1,#tree_raffle)]
		
		local layout = room_layouts[math_random(1,#room_layouts)]
		local enemies = room_enemies[math_random(1,#room_enemies)]
				
		if layout == "quad_rocks" then
			while not entities_to_place.rocks[1] do
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 8, left_top_y + 8}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 24, left_top_y + 8}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 8, left_top_y + 24}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 24, left_top_y + 24}) end
			end
		end
		
		if layout == "single_center_rock" then
			table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 16})	
		end
		
		if layout == "tree_and_lake" then
			table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 16})	
		end
		
		if layout == "forest_fence" then
			table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 16})
		end

		if layout == "forest" then
			while not entities_to_place.rocks[1] do
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 8}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 8, left_top_y + 24}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 24, left_top_y + 24}) end
			end
		end
		
		if layout == "three_horizontal_rocks" then
			while not entities_to_place.rocks[1] do
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 8, left_top_y + 16}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 16}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 24, left_top_y + 16}) end
			end
		end
		
		if layout == "three_vertical_rocks" then
			while not entities_to_place.rocks[1] do
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 8}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 16}) end
				if math_random(1,2) == 1 then table.insert(entities_to_place.rocks, {left_top_x + 16, left_top_y + 24}) end
			end
		end
		
		local allied_entity
		if enemies == "allied_entities" then
			allied_entity = allied_entity_raffle[math_random(1,#allied_entity_raffle)]
		end
		
		if global.labyrinth_size < 16 then		
			while enemies == "gun_turrets" or enemies == "only_worms" or enemies == "worms_and_spawners" do
				enemies = room_enemies[math_random(1,#room_enemies)]
			end					
		end						
		
		local placed_enemies = 0
		local enemy_counter = global.labyrinth_size
		if enemy_counter > 2000 then enemy_counter = 2000 end
		while placed_enemies < enemy_counter do
			if not enemies then break end
			for x = 0, 31, 1 do
				for y = 0, 31, 1 do
					local pos = {x = left_top_x + x, y = left_top_y + y}
					local random_max = 400
					if enemies == "spawners" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.biters, pos) end
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.spitters, pos) end
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.enemy_buildings, pos) end				
					end
					if enemies == "worms_and_spawners" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.enemy_buildings, pos) end
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.worms, pos) end					
					end
					if enemies == "only_worms" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.worms, pos) end				
					end
					if enemies == "only_biters" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.biters, pos) end				
					end
					if enemies == "only_spitters" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.spitters, pos) end				
					end
					if enemies == "biters_and_spitters" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.biters, pos) end
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.spitters, pos) end							
					end
					if enemies == "gun_turrets" then
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.gun_turrets, pos) end				
					end
					if enemies == "allied_entities" then												
						if math_random(1,random_max) == 1 then table.insert(entities_to_place.allied_entities, {allied_entity, pos}) end				
					end
					if enemies == "allied_entities_mixed" then
						if math_random(1,random_max) == 1 then
							allied_entity = allied_entity_raffle[math_random(1,#allied_entity_raffle)]
							table.insert(entities_to_place.allied_entities, {allied_entity, pos})
						end				
					end					
				end
			end
			placed_enemies = #entities_to_place.biters * 0.5 + #entities_to_place.spitters * 0.5 + #entities_to_place.enemy_buildings * 2 + #entities_to_place.worms * 3 + #entities_to_place.gun_turrets * 2 + #entities_to_place.allied_entities * 2
		end	
		
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do				
				local pos = {x = left_top_x + x, y = left_top_y + y}
				tile_to_insert = "dirt-5"
				
				if layout == "tree_and_lake" then
					if x > 12 and x < 20 and y > 12 and y < 20 then
						tile_to_insert = "water"
					end
					if x > 10 and x < 22 and y > 10 and y < 22 then
						if math_random(1,2) == 1 then table.insert(entities_to_place.trees, pos) end
					end					
				end
				
				if layout == "forest" then
					if math_random(1,8) == 1 then table.insert(entities_to_place.trees, pos) end
				end
				
				if layout == "forest_fence" then
					if x > 29 or x < 3 or y > 29 or y < 3 then				
						if math_random(1,4) == 1 then table.insert(entities_to_place.trees, pos) end
					end
				end
				
				table.insert(tiles, {name = tile_to_insert, position = pos}) 								
			end							
		end		
		surface.set_tiles(tiles, true)
		
		
		for _, p in pairs(entities_to_place.enemy_buildings) do						
			if math_random(1,3) == 1 then
				if surface.can_place_entity({name="spitter-spawner", position=p}) then surface.create_entity {name="spitter-spawner", position=p} end	
			else
				if surface.can_place_entity({name="biter-spawner", position=p}) then surface.create_entity {name="biter-spawner", position=p} end	
			end		
		end
		
		for _, p in pairs(entities_to_place.worms) do
			local i = math.ceil(global.labyrinth_size / 25, 0)
			local raffle = worm_raffle[i]
			local n = raffle[math.random(1,#raffle)]
			if surface.can_place_entity({name = n, position = p}) then surface.create_entity {name = n, position = p} end					
		end
		
		for _, p in pairs(entities_to_place.biters) do
			local evolution = math.ceil(game.forces.enemy.evolution_factor * 10, 0)
			local raffle = biter_raffle[evolution]
			local n = raffle[math.random(1,#raffle)]
			if surface.can_place_entity({name = n, position = p}) then surface.create_entity {name = n, position = p} end				
		end
		
		for _, p in pairs(entities_to_place.spitters) do
			local evolution = math.ceil(game.forces.enemy.evolution_factor * 10, 0)
			local raffle = spitter_raffle[evolution]
			local n = raffle[math.random(1,#raffle)]
			if surface.can_place_entity({name = n, position = p}) then surface.create_entity {name = n, position = p} end				
		end				
		
		
		
		for _, p in pairs(entities_to_place.gun_turrets) do			
			local e = surface.create_entity {name = "gun-turret", position = p, force = "enemy"}
			local ammo = "firearm-magazine"
			if global.labyrinth_size > 100 then ammo = "piercing-rounds-magazine" end
			if global.labyrinth_size > 300 then ammo = "uranium-rounds-magazine" end
			e.insert({name = ammo, count = math.random(50,150)})
		end
		
		for _, p in pairs(entities_to_place.rocks) do			
			local e = rock_raffle[math.random(1,#rock_raffle)]
			surface.create_entity {name = e, position = p} 				
		end
		
		
		for _, p in pairs(entities_to_place.allied_entities) do			
			local directions = {defines.direction.north, defines.direction.east, defines.direction.south, defines.direction.west}
			local d = directions[math_random(1,#directions)]
			if surface.can_place_entity({name = p[1], position = p[2], direction = d, force = "player"}) then surface.create_entity {name = p[1], position = p[2], direction = d, force = "player"} end		
		end
		
		for _, p in pairs(entities_to_place.trees) do			 
			if surface.can_place_entity({name = tree_name, position = p}) then surface.create_entity {name = tree_name, position = p} end				
		end
		
	end		
end

local function treasure_chest(position, surface)		
	treasure_chest_raffle_table = {}
	treasure_chest_loot_weights = {}
	table.insert(treasure_chest_loot_weights, {{name = 'combat-shotgun', count = 1},2})
	table.insert(treasure_chest_loot_weights, {{name = 'piercing-shotgun-shell', count = math.random(8,24)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'flamethrower', count = 1},2})
	table.insert(treasure_chest_loot_weights, {{name = 'rocket-launcher', count = 1},4})
	table.insert(treasure_chest_loot_weights, {{name = 'flamethrower-ammo', count = math.random(8,16)},3})		
	table.insert(treasure_chest_loot_weights, {{name = 'rocket', count = math.random(8,16)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'explosive-rocket', count = math.random(8,16)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'modular-armor', count = 1},1})
	--table.insert(treasure_chest_loot_weights, {{name = 'power-armor', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'uranium-rounds-magazine', count = math.random(16,32)},3})	
	table.insert(treasure_chest_loot_weights, {{name = 'piercing-rounds-magazine', count = math.random(32,64)},3})	
	table.insert(treasure_chest_loot_weights, {{name = 'railgun', count = 1},4})
	table.insert(treasure_chest_loot_weights, {{name = 'railgun-dart', count = math.random(8,16)},4})
	table.insert(treasure_chest_loot_weights, {{name = 'defender-capsule', count = math.random(6,8)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'distractor-capsule', count = math.random(4,6)},4})
	table.insert(treasure_chest_loot_weights, {{name = 'destroyer-capsule', count = math.random(2,4)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'atomic-bomb', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'iron-gear-wheel', count = math.random(16,48)},10})	
	table.insert(treasure_chest_loot_weights, {{name = 'coal', count = math.random(16,48)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'copper-cable', count = math.random(64,128)},10})
	table.insert(treasure_chest_loot_weights, {{name = 'inserter', count = math.random(8,16)},4})		
	table.insert(treasure_chest_loot_weights, {{name = 'fast-inserter', count = math.random(4,8)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'stack-filter-inserter', count = math.random(2,4)},1})
	table.insert(treasure_chest_loot_weights, {{name = 'stack-inserter', count = math.random(2,4)},1})
	table.insert(treasure_chest_loot_weights, {{name = 'burner-inserter', count = math.random(8,16)},6})
	table.insert(treasure_chest_loot_weights, {{name = 'electric-engine-unit', count = math.random(1,16)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'engine-unit', count = math.random(16,48)},3})	
	table.insert(treasure_chest_loot_weights, {{name = 'rocket-fuel', count = math.random(1,5)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'empty-barrel', count = math.random(1,10)},7})
	table.insert(treasure_chest_loot_weights, {{name = 'lubricant-barrel', count = math.random(1,10)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'crude-oil-barrel', count = math.random(1,10)},3})
	table.insert(treasure_chest_loot_weights, {{name = "small-electric-pole", count = math.random(8,32)},9})
	table.insert(treasure_chest_loot_weights, {{name = "firearm-magazine", count = math.random(16,32)},8})
	table.insert(treasure_chest_loot_weights, {{name = 'grenade', count = math.random(8,16)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'land-mine', count = math.random(4,8)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'light-armor', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'heavy-armor', count = 1},2})		
	table.insert(treasure_chest_loot_weights, {{name = 'pipe', count = math.random(10,100)},6})		
	table.insert(treasure_chest_loot_weights, {{name = 'wooden-chest', count = math.random(5,50)},1})
	table.insert(treasure_chest_loot_weights, {{name = 'raw-wood', count = math.random(5,50)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'sulfur', count = math.random(20,50)},7})
	table.insert(treasure_chest_loot_weights, {{name = 'explosives', count = math.random(20,50)},6})
	table.insert(treasure_chest_loot_weights, {{name = 'shotgun', count = 1},2})
	table.insert(treasure_chest_loot_weights, {{name = 'stone-brick', count = math.random(80,100)},6})
	table.insert(treasure_chest_loot_weights, {{name = 'small-lamp', count = math.random(3,10)},4})
	table.insert(treasure_chest_loot_weights, {{name = 'rail', count = math.random(32,100)},4})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-1', count = math.random(1,4)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-2', count = math.random(1,3)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-3', count = math.random(1,2)},1})		
	for _, t in pairs (treasure_chest_loot_weights) do
		for x = 1, t[2], 1 do
			table.insert(treasure_chest_raffle_table, t[1])
		end			
	end
	local chest_type_raffle = {"steel-chest", "iron-chest", "iron-chest", "wooden-chest", "wooden-chest", "wooden-chest"}
	local e = surface.create_entity {name = chest_type_raffle[math.random(1,#chest_type_raffle)], position = position, force = "player"}
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math.random(2,4), 1 do
		local loot = treasure_chest_raffle_table[math.random(1,#treasure_chest_raffle_table)]
		i.insert(loot)
	end		
end

local function spawn_infinity_chest(pos, surface)
	local math_random = math.random
	local infinity_chests = {		
		{"raw-wood", 1},
		{"coal", 1},
		{"stone", 1},
		{"iron-ore", math_random(1,2)},
		{"copper-ore", math_random(1,2)},
		{"crude-oil-barrel", 1},		
		{"iron-plate", 1},
		{"copper-plate", 1},
		{"stone-brick", 1},
		{"iron-gear-wheel", 1},
		{"copper-cable", math_random(1,4)}
	}
	local x = math.floor((global.labyrinth_size * 0.5) + 3, 0)
	if x > #infinity_chests then x = #infinity_chests end
	x = math_random(1, x)
	local e = surface.create_entity {name = "infinity-chest", position = pos, force = "player"}
	e.set_infinity_filter(1, {name = infinity_chests[x][1], count = infinity_chests[x][2]})
	e.minable = false
	e.destructible = false
	e.operable = false
end


local biter_fragmentation = {
	{"medium-biter","small-biter",3,5},
	{"big-biter","medium-biter",2,2},
	{"behemoth-biter","big-biter",2,2}
}

local biter_building_inhabitants = {}
biter_building_inhabitants[1] = {{"small-biter",8,16}}
biter_building_inhabitants[2] = {{"small-biter",12,24}}
biter_building_inhabitants[3] = {{"small-biter",8,16},{"medium-biter",1,2}}
biter_building_inhabitants[4] = {{"small-biter",4,8},{"medium-biter",4,8}}
biter_building_inhabitants[5] = {{"small-biter",3,5},{"medium-biter",8,12}}
biter_building_inhabitants[6] = {{"small-biter",3,5},{"medium-biter",5,7},{"big-biter",1,2}}
biter_building_inhabitants[7] = {{"medium-biter",6,8},{"big-biter",3,5}}
biter_building_inhabitants[8] = {{"medium-biter",2,4},{"big-biter",6,8}}
biter_building_inhabitants[9] = {{"medium-biter",2,3},{"big-biter",7,9}}
biter_building_inhabitants[10] = {{"big-biter",4,8},{"behemoth-biter",3,4}}

local entity_drop_amount = {
    ['small-biter'] = {low = 1, high = 20},
    ['small-spitter'] = {low = 1, high = 20},
    ['medium-biter'] = {low = 10, high = 30},
    ['medium-spitter'] = {low = 10, high = 30},
    ['big-biter'] = {low = 20, high = 40},
    ['big-spitter'] = {low = 20, high = 40},
    ['behemoth-biter'] = {low = 30, high = 50},
    ['behemoth-spitter'] = {low = 30, high = 50},
	['biter-spawner'] = {low = 40, high = 50},
	['spitter-spawner'] = {low = 40, high = 50}
}
local ore_spill_raffle = {"iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal","stone","uranium-ore", "landfill", "landfill", "landfill"}
local ore_spawn_raffle = {"iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal","stone","stone","uranium-ore","crude-oil"}

local function on_entity_died(event)	
	for _, fragment in pairs(biter_fragmentation) do
		if event.entity.name == fragment[1] then
			for x=1,math.random(fragment[3],fragment[4]),1 do
				local p = event.entity.surface.find_non_colliding_position(fragment[2] , event.entity.position, 2, 1)				
				if p then event.entity.surface.create_entity {name=fragment[2], position=p} end
				p = nil				
			end
			return
		end
	end
	
	if event.entity.name == "biter-spawner" or event.entity.name == "spitter-spawner" then
		local e = math.ceil(game.forces.enemy.evolution_factor*10, 0)		
		for _, t in pairs (biter_building_inhabitants[e]) do		
			for x = 1, math.random(t[2],t[3]), 1 do
				local p = event.entity.surface.find_non_colliding_position(t[1] , event.entity.position, 6, 1)			
				if p then event.entity.surface.create_entity {name=t[1], position=p} end
			end
		end
	end
	
	if entity_drop_amount[event.entity.name] then
		event.entity.surface.spill_item_stack(event.entity.position,{name = ore_spill_raffle[math.random(1,#ore_spill_raffle)], count = math.random(entity_drop_amount[event.entity.name].low, entity_drop_amount[event.entity.name].high)},true)
		return
	end

	if event.entity.name == "sand-rock-big" or event.entity.name == "rock-big" or event.entity.name == "rock-huge" then
		local pos = {x = event.entity.position.x, y = event.entity.position.y}
		local surface = event.entity.surface
		if event.entity.name == "rock-huge" then spawn_infinity_chest(pos, surface) end
		if event.entity.name == "rock-big" then treasure_chest(pos, surface) end
		if event.entity.name == "sand-rock-big" then
			local n = ore_spawn_raffle[math.random(1,#ore_spawn_raffle)]
			local amount_modifier = 1 + global.labyrinth_size / 25
			if n == "crude-oil" then
				create_cluster(n, pos, math.random(1,4), surface, 10, math.random(300000 * amount_modifier, 500000 * amount_modifier))
			else				
				create_cluster(n, pos, math.random(30,100), surface, 1, math.random(math.floor(350 * amount_modifier, 0), math.floor(450 * amount_modifier, 0)))
			end
		end
		event.entity.destroy()
		local chunk_position = get_entity_chunk_position(pos)		
		local b = is_chunk_allowed_to_grow(chunk_position, surface)		
		if b == true then
			grow_cell(chunk_position, surface)			
		end		
	end
end

local function on_player_mined_entity(event)
	if event.entity.name == "sand-rock-big" or event.entity.name == "rock-big" or event.entity.name == "rock-huge" then
		event.entity.die()
	end
end

local function on_chunk_generated(event)
	local surface = game.surfaces["labyrinth"] 
	if event.surface.name ~= surface.name then return end
	local math_random = math.random
	local entities_to_place = {
		rocks = {},
		worms = {},
		enemy_buildings = {},
		trees = {},
		fish = {},		
		shipwrecks = {}		
	}	
	local decoratives = {}
	local tiles = {}
	local tile_to_insert = false
	local chunk_position_x = event.area.left_top.x / 32
	local chunk_position_y = event.area.left_top.y / 32
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			tile_to_insert = false
			local pos = {x = event.area.left_top.x + x, y = event.area.left_top.y + y}
			--local tile_distance_to_center = pos_x^2 + pos_y^2			 
			if chunk_position_y >= 0 then
				tile_to_insert = "water"				
			end			
			if chunk_position_x == 0 and chunk_position_y == 0 then
				tile_to_insert = "grass-1"
			end
			if chunk_position_x == 0 and chunk_position_y == -1 then
				tile_to_insert = "dirt-5"
			end			
			if tile_to_insert == false then
				table.insert(tiles, {name = "out-of-map", position = pos})
			else
				if tile_to_insert == "water" and math_random(1,200) == 1 then table.insert(entities_to_place.fish, pos) end
				table.insert(tiles, {name = tile_to_insert, position = pos}) 
			end					
		end							
	end		
	surface.set_tiles(tiles,true)										
	for _, p in pairs(entities_to_place.fish) do					
		surface.create_entity {name="fish",position=p}				
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 50, cliff_elevation_0 = 50}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"},
			["grass"] = {frequency = "none", size = "none", richness = "none"},
			["sand"] = {frequency = "none", size = "none", richness = "none"},
			["desert"] = {frequency = "none", size = "none", richness = "none"},
			["dirt"] = {frequency = "none", size = "none", richness = "none"}
		}
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("labyrinth", map_gen_settings)		
		game.forces["player"].set_spawn_position({16,16},game.surfaces["labyrinth"])
		local surface = game.surfaces["labyrinth"]
		surface.create_entity {name="rock-big",position={16,-16}}
		game.speed = 4
		
		--game.forces["player"].technologies["landfill"].enabled = false
		game.forces["player"].technologies["artillery"].enabled = false
		game.forces["player"].technologies["artillery-shell-range-1"].enabled = false		
		game.forces["player"].technologies["artillery-shell-speed-1"].enabled = false						
		game.forces["player"].technologies["atomic-bomb"].enabled = false	
		
		game.forces["player"].set_ammo_damage_modifier("flamethrower", -0.95)
		game.forces["player"].set_turret_attack_modifier("flamethrower-turret", -0.95)
		game.forces["player"].set_turret_attack_modifier("gun-turret", -0.75)
		game.forces["player"].set_turret_attack_modifier("laser-turret", -0.75)
		
		if not global.labyrinth_size then	global.labyrinth_size = 1 end
		global.map_init_done = true						
	end	
	local surface = game.surfaces["labyrinth"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("player", {16,16}, 2, 1), "labyrinth")
	else
		if player.online_time < 5 then
			player.teleport({16,16}, "labyrinth")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'raw-fish', count = 3}
		player.insert {name = 'iron-axe', count = 1}		
		player.insert {name = 'pistol', count = 1}
		player.insert {name = 'firearm-magazine', count = 32}
	end	
end

local function on_research_finished(event)
	game.forces["player"].set_ammo_damage_modifier("flamethrower", -0.95)
	game.forces["player"].set_turret_attack_modifier("flamethrower-turret", -0.95)
	game.forces["player"].set_turret_attack_modifier("gun-turret", -0.75)
	game.forces["player"].set_turret_attack_modifier("laser-turret", -0.75)
end

local inserters = {"inserter", "long-handed-inserter", "burner-inserter", "fast-inserter", "filter-inserter", "stack-filter-inserter", "stack-inserter"}
local function on_built_entity(event)
	for _, e in pairs(inserters) do
		if e == event.created_entity.name then
			local player = game.players[event.player_index]
			local surface = event.created_entity.surface
			local a = {
			left_top = {x = event.created_entity.position.x - 2, y = event.created_entity.position.y - 2},
			right_bottom = {x = event.created_entity.position.x + 2, y = event.created_entity.position.y + 2}
			}
			local chest = surface.find_entities_filtered{area = a, name = "infinity-chest", limit = 1}
			if not chest[1] then return end
			local a = {
			left_top = {x = chest[1].position.x - 2, y = chest[1].position.y - 2},
			right_bottom = {x = chest[1].position.x + 2, y = chest[1].position.y + 2}
			}
			local i = surface.find_entities_filtered{area = a, name = inserters}
			if #i > 1 then
				if math.random(1,12) == 1 then
					break
				else
					for _, x in pairs (i) do
						x.die("enemy")
					end
					player.print("The mysterious chest noticed your greed and devoured your devices.", { r=0.75, g=0.0, b=0.0})
				end
			end
			break
		end
	end

	local name = event.created_entity.name
	if name == "flamethrower-turret" or name == "laser-turret" or name == "gun-turret" then
		if event.created_entity.position.y < 0 then 		
			event.created_entity.die("enemy")
		end
	end
end
	
function cheat_mode()
	local cheat_mode_enabed = true
	if cheat_mode_enabed == true then
		local surface = game.surfaces["labyrinth"]
		game.player.cheat_mode=true
		game.players[1].insert({name="power-armor-mk2"})
		game.players[1].insert({name="fusion-reactor-equipment", count=4})
		game.players[1].insert({name="personal-laser-defense-equipment", count=8})
		game.players[1].insert({name="rocket-launcher"})		
		game.players[1].insert({name="explosive-rocket", count=200})		
		game.speed = 5
		surface.daytime = 1
		game.player.force.research_all_technologies()
		game.forces["enemy"].evolution_factor = 0.2
		local chart = 300
		local surface = game.surfaces["labyrinth"]	
		game.forces["player"].chart(surface, {lefttop = {x = chart*-1, y = chart*-1}, rightbottom = {x = chart, y = chart}})		
	end
end

event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)