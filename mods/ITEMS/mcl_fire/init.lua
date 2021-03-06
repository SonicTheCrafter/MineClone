-- Global namespace for functions

mcl_fire = {}


--
-- Items
--

-- Flame nodes

local fire_help = "Fire is a damaging and destructive but short-lived kind of block. It will destroy and spread towards near flammable blocks, but fire will disappear when there is nothing to burn left. It will be extinguished by nearby water and rain. Fire can be destroyed safely by punching it, but it is hurtful if you stand directly in it. If a fire is started above netherrack or a magma block, it will immediately turn into an eternal fire."
local eternal_fire_help = "Eternal fire is a damaging and destructive block. It will create fire around it when flammable blocks are nearby. Eternal fire can be extinguished by punches and nearby water blocks. Other than (normal) fire, eternal fire does not get extinguished on its own and also continues to burn under rain. Punching eternal fire is safe, but it hurts if you stand inside."

minetest.register_node("mcl_fire:fire", {
	description = "Fire",
	_doc_items_longdesc = fire_help,
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	-- Real light level: 15 (but Minetest caps at 14)
	light_source = 14,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 1,
	groups = {fire = 1, dig_immediate = 3, not_in_creative_inventory = 1, dig_by_piston=1},
	floodable = true,
	on_flood = function(pos, oldnode, newnode)
		if minetest.get_item_group(newnode.name, "water") ~= 0 then
			minetest.sound_play("fire_extinguish_flame", {pos = pos, gain = 0.25, max_hear_distance = 16})
		end
	end,
	on_timer = function(pos)
		local airs = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y-1, z=pos.z-1}, {x=pos.x+1, y=pos.y+4, z=pos.z+1}, {"air"})
		if #airs == 0 then
			minetest.remove_node(pos)
			return
		end
		local burned = false
		if math.random(1,2) == 1 then
			while #airs > 0 do
				local r = math.random(1, #airs)
				if minetest.find_node_near(airs[r], 1, {"group:flammable"}) then
					minetest.set_node(airs[r], {name="mcl_fire:fire"})
					burned = true
					break
				else
					table.remove(airs, r)
				end
			end
		end
		if not burned then
			if math.random(1,3) == 1 then
				minetest.remove_node(pos)
				return
			end
		end
		-- Restart timer
		minetest.get_node_timer(pos):start(math.random(3, 7))
	end,
	drop = "",
	sounds = {},
	-- Turn into eternal fire on special blocks, light Nether portal (if possible), start burning timer
	on_construct = function(pos)
		local under = minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name

		if under == "mcl_nether:magma" or under == "mcl_nether:netherrack" then
			minetest.swap_node(pos, {name = "mcl_fire:eternal_fire"})
		end

		if minetest.get_modpath("mcl_portals") then
			mcl_portals.light_nether_portal(pos)
		end

		minetest.get_node_timer(pos):start(math.random(3, 7))
	end,
	_mcl_blast_resistance = 0,
})

minetest.register_node("mcl_fire:eternal_fire", {
	description = "Eternal Fire",
	_doc_items_longdesc = eternal_fire_help,
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	-- Real light level: 15 (but Minetest caps at 14)
	light_source = 14,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 1,
	groups = {fire = 1, dig_immediate = 3, not_in_creative_inventory = 1, dig_by_piston = 1},
	floodable = true,
	on_flood = function(pos, oldnode, newnode)
		if minetest.get_item_group(newnode.name, "water") ~= 0 then
			minetest.sound_play("fire_extinguish_flame", {pos = pos, gain = 0.25, max_hear_distance = 16})
		end
	end,
	on_timer = function(pos)
		local airs = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y-1, z=pos.z-1}, {x=pos.x+1, y=pos.y+4, z=pos.z+1}, {"air"})
		while #airs > 0 do
			local r = math.random(1, #airs)
			if minetest.find_node_near(airs[r], 1, {"group:flammable"}) then
				minetest.set_node(airs[r], {name="mcl_fire:fire"})
				break
			else
				table.remove(airs, r)
			end
		end
		-- Restart timer
		minetest.get_node_timer(pos):start(math.random(3, 7))
	end,
	-- Start burning timer and light Nether portal (if possible)
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(3, 7))

		if minetest.get_modpath("mcl_portals") then
			mcl_portals.light_nether_portal(pos)
		end
	end,
	sounds = {},
	drop = "",
	_mcl_blast_resistance = 0,
})

-- Also make lava set fire to air blocks above
minetest.override_item("mcl_core:lava_source", {
	on_timer = function(pos)
		local function try_ignite(airs)
			while #airs > 0 do
				local r = math.random(1, #airs)
				if minetest.find_node_near(airs[r], 1, {"group:flammable", "group:flammable_lava"}) then
					minetest.set_node(airs[r], {name="mcl_fire:fire"})
					return true
				else
					table.remove(airs, r)
				end
			end
			return false
		end
		local airs1 = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y+1, z=pos.z-1}, {x=pos.x+1, y=pos.y+1, z=pos.z+1}, {"air"})
		local ok = try_ignite(airs1)
		if not ok then
			local airs2 = minetest.find_nodes_in_area({x=pos.x-2, y=pos.y+2, z=pos.z-2}, {x=pos.x+2, y=pos.y+2, z=pos.z+2}, {"air"})
			try_ignite(airs2)
		end

		-- Restart timer
		minetest.get_node_timer(pos):start(math.random(5, 10))
	end,
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(5, 10))
	end
})

--
-- Sound
--

local flame_sound = minetest.settings:get_bool("flame_sound")
if flame_sound == nil then
	-- Enable if no setting present
	flame_sound = true
end

if flame_sound then

	local handles = {}
	local timer = 0

	-- Parameters

	local radius = 8 -- Flame node search radius around player
	local cycle = 3 -- Cycle time for sound updates

	-- Update sound for player

	function mcl_fire.update_player_sound(player)
		local player_name = player:get_player_name()
		-- Search for flame nodes in radius around player
		local ppos = player:getpos()
		local areamin = vector.subtract(ppos, radius)
		local areamax = vector.add(ppos, radius)
		local fpos, num = minetest.find_nodes_in_area(
			areamin,
			areamax,
			{"mcl_fire:fire", "mcl_fire:eternal_fire"}
		)
		-- Total number of flames in radius
		local flames = (num["mcl_fire:fire"] or 0) +
			(num["mcl_fire:eternal_fire"] or 0)
		-- Stop previous sound
		if handles[player_name] then
			minetest.sound_stop(handles[player_name])
			handles[player_name] = nil
		end
		-- If flames
		if flames > 0 then
			-- Find centre of flame positions
			local fposmid = fpos[1]
			-- If more than 1 flame
			if #fpos > 1 then
				local fposmin = areamax
				local fposmax = areamin
				for i = 1, #fpos do
					local fposi = fpos[i]
					if fposi.x > fposmax.x then
						fposmax.x = fposi.x
					end
					if fposi.y > fposmax.y then
						fposmax.y = fposi.y
					end
					if fposi.z > fposmax.z then
						fposmax.z = fposi.z
					end
					if fposi.x < fposmin.x then
						fposmin.x = fposi.x
					end
					if fposi.y < fposmin.y then
						fposmin.y = fposi.y
					end
					if fposi.z < fposmin.z then
						fposmin.z = fposi.z
					end
				end
				fposmid = vector.divide(vector.add(fposmin, fposmax), 2)
			end
			-- Play sound
			local handle = minetest.sound_play(
				"fire_fire",
				{
					pos = fposmid,
					to_player = player_name,
					gain = math.min(0.06 * (1 + flames * 0.125), 0.18),
					max_hear_distance = 32,
					loop = true, -- In case of lag
				}
			)
			-- Store sound handle for this player
			if handle then
				handles[player_name] = handle
			end
		end
	end

	-- Cycle for updating players sounds

	minetest.register_globalstep(function(dtime)
		timer = timer + dtime
		if timer < cycle then
			return
		end

		timer = 0
		local players = minetest.get_connected_players()
		for n = 1, #players do
			mcl_fire.update_player_sound(players[n])
		end
	end)

	-- Stop sound and clear handle on player leave

	minetest.register_on_leaveplayer(function(player)
		local player_name = player:get_player_name()
		if handles[player_name] then
			minetest.sound_stop(handles[player_name])
			handles[player_name] = nil
		end
	end)
end


--
-- ABMs
--

-- Extinguish all flames quickly with water and such

minetest.register_abm({
	label = "Extinguish flame",
	nodenames = {"mcl_fire:fire", "mcl_fire:eternal_fire"},
	neighbors = {"group:puts_out_fire"},
	interval = 3,
	chance = 1,
	catch_up = false,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.remove_node(pos)
		minetest.sound_play("fire_extinguish_flame",
			{pos = pos, max_hear_distance = 16, gain = 0.15})
	end,
})


-- Enable the following ABMs according to 'enable fire' setting

local fire_enabled = minetest.settings:get_bool("enable_fire")
if fire_enabled == nil then
	-- New setting not specified, check for old setting.
	-- If old setting is also not specified, 'not nil' is true.
	fire_enabled = not minetest.settings:get_bool("disable_fire")
end

if not fire_enabled then

	-- Remove fire only if fire disabled
	minetest.register_abm({
		label = "Remove disabled fire",
		nodenames = {"mcl_fire:fire"},
		interval = 7,
		chance = 1,
		catch_up = false,
		action = minetest.remove_node,
	})

	-- Set fire to air nodes (inverse pyramid pattern) above lava source
	minetest.register_abm({
		label = "Ignite fire by lava",
		nodenames = {"mcl_core:lava_source"},
		interval = 7,
		chance = 2,
		catch_up = false,
		action = function(pos)
			function try_ignite(airs)
				while #airs > 0 do
					local r = math.random(1, #airs)
					if minetest.find_node_near(airs[r], 1, {"group:flammable", "group:flammable_lava"}) then
						minetest.set_node(airs[r], {name="mcl_fire:fire"})
						return true
					else
						table.remove(airs, r)
					end
				end
				return false
			end
			local airs1 = minetest.find_nodes_in_area({x=pos.x-1, y=pos.y+1, z=pos.z-1}, {x=pos.x+1, y=pos.y+1, z=pos.z+1}, {"air"})
			local ok = try_ignite(airs1)
			if not ok then
				local airs2 = minetest.find_nodes_in_area({x=pos.x-2, y=pos.y+2, z=pos.z-2}, {x=pos.x+2, y=pos.y+2, z=pos.z+2}, {"air"})
				try_ignite(airs2)
			end
		end,
	})

else -- Fire enabled

	-- Turn flammable nodes around fire into fire
	minetest.register_abm({
		label = "Remove flammable nodes",
		nodenames = {"group:fire"},
		neighbors = {"group:flammable"},
		interval = 5,
		chance = 18,
		catch_up = false,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local p = minetest.find_node_near(pos, 1, {"group:flammable"})
			if p then
				local flammable_node = minetest.get_node(p)
				local def = minetest.registered_nodes[flammable_node.name]
				if def.on_burn then
					def.on_burn(p)
				else
					minetest.set_node(p, {name="mcl_fire:fire"})
					minetest.check_for_falling(p)
				end
			end
		end,
	})

end

-- Spawn eternal fire when fire starts on netherrack or magma block.
-- Also on bedrock when it's in the end.

local eternal_override = {
	after_destruct = function(pos, oldnode)
		pos.y = pos.y + 1
		if minetest.get_node(pos).name == "mcl_fire:eternal_fire" then
			minetest.remove_node(pos)
		end
	end,
	_on_ignite = function(player, pointed_thing)
		local pos = pointed_thing.under
		local flame_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
		local fn = minetest.get_node(flame_pos)
		if fn.name == "air" and not minetest.is_protected(flame_pos, "fire") and pointed_thing.under.y < pointed_thing.above.y then
			minetest.set_node(flame_pos, {name = "mcl_fire:eternal_fire"})
			return true
		else
			return false
		end
	end,
}
local eternal_override_end = {
	after_destruct = eternal_override.after_destruct,
	_on_ignite = function(player, pointed_thing)
		local pos = pointed_thing.under
		local _, dim = mcl_util.y_to_layer(pos.y)
		local flame_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
		local fn = minetest.get_node(flame_pos)
		if dim == "end" and fn.name == "air" and not minetest.is_protected(flame_pos, "fire") and pointed_thing.under.y < pointed_thing.above.y then
			minetest.set_node(flame_pos, {name = "mcl_fire:eternal_fire"})
			return true
		else
			return false
		end
	end,
}

minetest.override_item("mcl_core:bedrock", eternal_override_end)
if minetest.get_modpath("mcl_nether") then
	minetest.override_item("mcl_nether:netherrack", eternal_override)
	minetest.override_item("mcl_nether:magma", eternal_override)
end

-- Set pointed_thing on (normal) fire
mcl_fire.set_fire = function(pointed_thing)
	local n = minetest.get_node(pointed_thing.above)
	if n.name == "air" and not minetest.is_protected(pointed_thing.above, "fire") then
		minetest.add_node(pointed_thing.above, {name="mcl_fire:fire"})
	end
end

minetest.register_alias("mcl_fire:basic_flame", "mcl_fire:fire")
minetest.register_alias("fire:basic_flame", "mcl_fire:fire")
minetest.register_alias("fire:permanent_flame", "mcl_fire:eternal_flame")

dofile(minetest.get_modpath(minetest.get_current_modname()).."/flint_and_steel.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()).."/fire_charge.lua")
