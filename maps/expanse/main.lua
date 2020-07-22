require 'modules.satellite_score'

local Event = require 'utils.event'
local Functions = require 'maps.expanse.functions'
local Global = require 'utils.global'
local Map_info = require "modules.map_info"

local math_round = math.round

local expanse = {}
Global.register(
    expanse,
    function(tbl)
        expanse = tbl
    end
)

local function reset()
	expanse.containers = {}
	if not expanse.source_surface then expanse.source_surface = "nauvis" end
	expanse.square_size = 15
	
	local map_gen_settings = {
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = false,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = false},
			["decorative"] = {treat_missing_as_default = false},
		},
		autoplace_controls = {
			["coal"] = {frequency = 0, size = 0, richness = 0},
			["stone"] = {frequency = 0, size = 0, richness = 0},
			["copper-ore"] = {frequency = 0, size = 0, richness = 0},
			["iron-ore"] = {frequency = 0, size = 0, richness = 0},
			["uranium-ore"] = {frequency = 0, size = 0, richness = 0},
			["crude-oil"] = {frequency = 0, size = 0, richness = 0},
			["trees"] = {frequency = 0, size = 0, richness = 0},
			["enemy-base"] = {frequency = 0, size = 0, richness = 0}
		},
	}
	game.create_surface("expanse", map_gen_settings)
	
	if expanse.source_surface == "nauvis" then
		local surface = game.surfaces[1]
		local map_gen_settings = surface.map_gen_settings
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = 10, size = 0.7, richness = 0.5,},
			["stone"] = {frequency = 10, size = 0.7, richness = 0.5,},
			["copper-ore"] = {frequency = 10, size = 0.7, richness = 0.75,},
			["iron-ore"] = {frequency = 10, size = 0.7, richness = 1,},
			["uranium-ore"] = {frequency = 10, size = 0.5, richness = 1,},
			["crude-oil"] = {frequency = 25, size = 1.5, richness = 1.5,},
			["trees"] = {frequency = 1.5, size = 1, richness = 1},
			["enemy-base"] = {frequency = 10, size = 2, richness = 1},	
		}
		map_gen_settings.starting_area = 0.25
		surface.map_gen_settings = map_gen_settings
		for chunk in surface.get_chunks() do		
			surface.delete_chunk({chunk.x, chunk.y})		
		end
	end
	
	local source_surface = game.surfaces[expanse.source_surface]
	source_surface.request_to_generate_chunks({x = 0, y = 0}, 4)
	source_surface.force_generate_chunk_requests()
	
	local surface = game.surfaces.expanse
	surface.request_to_generate_chunks({x = 0, y = 0}, 4)
	surface.force_generate_chunk_requests()
	
	for _, player in pairs(game.players) do
		player.teleport({-4, -4}, source_surface)
	end
	
	Functions.expand(expanse, {x = 0, y = 0})			
	
	for _, player in pairs(game.players) do
		player.teleport(surface.find_non_colliding_position("character", {expanse.square_size * 0.5, expanse.square_size * 0.5}, 8, 0.5), surface)
	end
end

local function on_chunk_generated(event)
	if event.surface.name ~= "expanse" then return end
	local left_top = event.area.left_top
	local tiles = {}
	local i = 1
	
	if left_top.x == 0 and left_top.y == 0 then
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				if x >= expanse.square_size or y >= expanse.square_size then
					tiles[i] = {name = "out-of-map", position = {left_top.x + x, left_top.y + y}}
					i = i + 1
				end
			end
		end
	else
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				tiles[i] = {name = "out-of-map", position = {left_top.x + x, left_top.y + y}}
				i = i + 1
			end
		end
	end		
	event.surface.set_tiles(tiles, true)
end

local function on_gui_opened(event)
	local entity = event.entity 
	if not entity then return end
	if not entity.valid then return end
	if not entity.unit_number then return end
	if entity.force.index ~= 3 then return end	
	Functions.set_container(expanse, entity)
end

local function on_gui_closed(event)
	local entity = event.entity 
	if not entity then return end
	if not entity.valid then return end
	if not entity.unit_number then return end
	if entity.force.index ~= 3 then return end	
	Functions.set_container(expanse, entity)
end

local ores = {"iron-ore", "iron-ore", "copper-ore", "coal"}
local function infini_rock(entity)
	if entity.type ~= "simple-entity" then return end
	local a = math.floor(expanse.square_size * 0.5)		
	if entity.position.x == a and entity.position.y == a then
		entity.surface.create_entity({name = "rock-big", position = {a, a}})
		entity.surface.spill_item_stack(entity.position, {name = ores[math.random(1,4)], count = math.random(100, 200)}, true, nil, true)
	end
end

local function infini_tree(entity)
	if entity.type ~= "tree" then return end
	local a = math.floor(expanse.square_size * 0.5)		
	if entity.position.x == a and entity.position.y == a - 1 then
		entity.surface.create_entity({name = "tree-0" .. math.random(1,9), position = {a, a - 1}})
	end
end

local function infini_resource(event)
	local entity = event.entity
	if not entity.valid then return end
	infini_rock(entity)
	infini_tree(entity)
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		local surface = game.surfaces.expanse
		player.teleport(surface.find_non_colliding_position("character", {expanse.square_size * 0.5, expanse.square_size * 0.5}, 32, 0.5), surface)
	end	
end

local function on_init(event)
	local T = Map_info.Pop_info()
	T.localised_category = "expanse"
	T.main_caption_color = {r = 170, g = 170, b = 0}
	T.sub_caption_color = {r = 120, g = 120, b = 0}
	reset()
end

Event.on_init(on_init)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_gui_closed, on_gui_closed)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_died, infini_resource)
Event.add(defines.events.on_robot_mined_entity, infini_resource)
Event.add(defines.events.on_player_mined_entity, infini_resource)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)