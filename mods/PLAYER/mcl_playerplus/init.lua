-- Internal player state
local mcl_playerplus_internal = {}

local armor_mod = minetest.get_modpath("3d_armor")
local def = {}
local time = 0

minetest.register_globalstep(function(dtime)

	time = time + dtime

	-- Update jump status immediately since we need this info in real time.
	-- WARNING: This section is HACKY as hell since it is all just based on heuristics.
	for _,player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		if mcl_playerplus_internal[name].jump_cooldown > 0 then
			mcl_playerplus_internal[name].jump_cooldown = mcl_playerplus_internal[name].jump_cooldown - dtime
		end
		if player:get_player_control().jump and mcl_playerplus_internal[name].jump_cooldown <= 0 then

			local pos = player:getpos()

			local node_stand = mcl_playerinfo[name].node_stand
			local node_stand_below = mcl_playerinfo[name].node_stand_below
			local node_head = mcl_playerinfo[name].node_head
			local node_feet = mcl_playerinfo[name].node_feet
			if not node_stand or not node_stand_below or not node_head or not node_feet then
				return
			end

			-- Cause buggy exhaustion for jumping

			--[[ Checklist we check to know the player *actually* jumped:
				* Not on or in liquid
				* Not on or at climbable
				* On walkable
				* Not on disable_jump
			FIXME: This code is pretty hacky and it is possible to miss some jumps or detect false
			jumps because of delays, rounding errors, etc.
			What this code *really* needs is some kind of jumping “callback” which this engine lacks
			as of 0.4.15.
			]]

			if minetest.get_item_group(node_feet, "liquid") == 0 and
					minetest.get_item_group(node_stand, "liquid") == 0 and
					not minetest.registered_nodes[node_feet].climbable and
					not minetest.registered_nodes[node_stand].climbable and
					(minetest.registered_nodes[node_stand].walkable or minetest.registered_nodes[node_stand_below].walkable)
					and minetest.get_item_group(node_stand, "disable_jump") == 0
					and minetest.get_item_group(node_stand_below, "disable_jump") == 0 then
			-- Cause exhaustion for jumping
			if mcl_sprint.is_sprinting(name) then
				mcl_hunger.exhaust(name, mcl_hunger.EXHAUST_SPRINT_JUMP)
			else
				mcl_hunger.exhaust(name, mcl_hunger.EXHAUST_JUMP)
			end

			-- Reset cooldown timer
				mcl_playerplus_internal[name].jump_cooldown = 0.45
			end
		end
	end

	-- Run the rest of the code every 0.5 seconds
	if time < 0.5 then
		return
	end

	-- reset time for next check
	-- FIXME: Make sure a regular check interval applies
	time = 0

	-- check players
	for _,player in pairs(minetest.get_connected_players()) do
		-- who am I?
		local name = player:get_player_name()

		-- where am I?
		local pos = player:getpos()

		-- what is around me?
		local node_stand = mcl_playerinfo[name].node_stand
		local node_stand_below = mcl_playerinfo[name].node_stand_below
		local node_head = mcl_playerinfo[name].node_head
		local node_feet = mcl_playerinfo[name].node_feet
		if not node_stand or not node_stand_below or not node_head or not node_feet then
			return
		end

		-- set defaults
		def.speed = 1
		def.jump = 1
		def.gravity = 1

		-- is 3d_armor mod active? if so make armor physics default
		if armor_mod and armor and armor.def then
			-- get player physics from armor
			def.speed = armor.def[name].speed or 1
			def.jump = armor.def[name].jump or 1
			def.gravity = armor.def[name].gravity or 1
		end

		-- standing on soul sand? if so walk slower
		if node_stand == "mcl_nether:soul_sand" then
			-- TODO: Tweak walk speed
			-- TODO: Also slow down mobs
			-- FIXME: This whole speed thing is a giant hack. We need a proper framefork for cleanly handling player speeds
			if node_stand_below == "mcl_core:ice" or node_stand_below == "mcl_core:packed_ice" or node_stand_below == "mcl_core:slimeblock" then
				def.speed = def.speed - 0.9
			else
				def.speed = def.speed - 0.6
			end
		end

		-- Set player physics if there's no conflict
		if player:get_attribute("mcl_beds:sleeping") ~= "true" then
			player:set_physics_override(def.speed, def.jump, def.gravity)
		end

		-- Is player suffocating inside node? (Only for solid full opaque cube type nodes
		-- without group disable_suffocation=1)
		local ndef = minetest.registered_nodes[node_head]

		if (ndef.walkable == nil or ndef.walkable == true)
		and (ndef.collision_box == nil or ndef.collision_box.type == "regular")
		and (ndef.node_box == nil or ndef.node_box.type == "regular")
		and (ndef.groups.disable_suffocation ~= 1)
		and (ndef.groups.opaque == 1)
		-- Check privilege, too
		and (not minetest.check_player_privs(name, {noclip = true})) then
			if player:get_hp() > 0 then
				mcl_death_messages.player_damage(player, string.format("%s suffocated to death.", player:get_player_name()))
				player:set_hp(player:get_hp() - 1)
			end
		end

		-- Am I near a cactus?
		local near = minetest.find_node_near(pos, 1, "mcl_core:cactus")
		if not near then
			near = minetest.find_node_near({x=pos.x, y=pos.y-1, z=pos.z}, 1, "mcl_core:cactus")
		end
		if near then
			-- Am I touching the cactus? If so, it hurts
			local dist = vector.distance(pos, near)
			local dist_feet = vector.distance({x=pos.x, y=pos.y-1, z=pos.z}, near)
			if dist < 1.1 or dist_feet < 1.1 then
				if player:get_hp() > 0 then
					mcl_death_messages.player_damage(player, string.format("%s was prickled by a cactus.", player:get_player_name()))
					mcl_hunger.exhaust(player:get_player_name(), mcl_hunger.EXHAUST_DAMAGE)
					player:set_hp(player:get_hp() - 1)
				end
			end
		end

		-- Apply black sky in the Void and deal Void damage
		local void, void_deadly = mcl_util.is_in_void(pos)
		local _, dim = mcl_util.y_to_layer(pos.y)
		-- Set dimension skies.
		-- FIXME: Sky handling in MCL2 is held together with lots of duct tape.
		-- This only works beause weather_pack currently does not touch the sky for players below the height used for this check.
		-- There should be a real skybox API.
		if dim == "void" then
			player:set_sky("#000000", "plain", nil, false)
		elseif dim == "end" then
			local t = "mcl_playerplus_end_sky.png"
			player:set_sky("#000000", "skybox", {t,t,t,t,t,t}, false)
		elseif dim == "nether" then
			player:set_sky("#300808", "plain", nil, false)
		else
			skycolor.update_sky_color({player})
		end
		if void_deadly then
			-- Player is deep into the void, deal void damage
			if player:get_hp() > 0 then
				mcl_death_messages.player_damage(player, string.format("%s fell into the endless void.", player:get_player_name()))
				player:set_hp(player:get_hp() - 4)
			end
		end

		--[[ Swimming: Cause exhaustion.
		NOTE: As of 0.4.15, it only counts as swimming when you are with the feet inside the liquid!
		Head alone does not count. We respect that for now. ]]
		if minetest.get_item_group(node_feet, "liquid") ~= 0 or
				minetest.get_item_group(node_stand, "liquid") ~= 0 then
			local lastPos = mcl_playerplus_internal[name].lastPos
			if lastPos then
				local dist = vector.distance(lastPos, pos)
				mcl_playerplus_internal[name].swimDistance = mcl_playerplus_internal[name].swimDistance + dist
				if mcl_playerplus_internal[name].swimDistance >= 1 then
					local superficial = math.floor(mcl_playerplus_internal[name].swimDistance)
					mcl_hunger.exhaust(name, mcl_hunger.EXHAUST_SWIM * superficial)
					mcl_playerplus_internal[name].swimDistance = mcl_playerplus_internal[name].swimDistance - superficial
				end
			end

		end

		-- Underwater: Spawn bubble particles
		if minetest.get_item_group(node_head, "water") ~= 0 then

			minetest.add_particlespawner({
				amount = 10,
				time = 0.15,
				minpos = { x = -0.25, y = 0.3, z = -0.25 },
				maxpos = { x = 0.25, y = 0.7, z = 0.75 },
				attached = player,
				minvel = {x = -0.2, y = 0, z = -0.2},
				maxvel = {x = 0.5, y = 0, z = 0.5},
				minacc = {x = -0.4, y = 4, z = -0.4},
				maxacc = {x = 0.5, y = 1, z = 0.5},
				minexptime = 0.3,
				maxexptime = 0.8,
				minsize = 0.7,
				maxsize = 2.4,
				texture = "mcl_particles_bubble.png"
			})
		end

		-- Show positions of barriers when player is wielding a barrier
		local wi = player:get_wielded_item():get_name()
		if wi == "mcl_core:barrier" or wi == "mcl_core:realm_barrier" then
			local pos = vector.round(player:getpos())
			local r = 8
			local vm = minetest.get_voxel_manip()
			local emin, emax = vm:read_from_map({x=pos.x-r, y=pos.y-r, z=pos.z-r}, {x=pos.x+r, y=pos.y+r, z=pos.z+r})
			local area = VoxelArea:new{
				MinEdge = emin,
				MaxEdge = emax,
			}
			local data = vm:get_data()
			for x=pos.x-r, pos.x+r do
			for y=pos.y-r, pos.y+r do
			for z=pos.z-r, pos.z+r do
				local vi = area:indexp({x=x, y=y, z=z})
				local nodename = minetest.get_name_from_content_id(data[vi])
				local tex
				if nodename == "mcl_core:barrier" then
					tex = "mcl_core_barrier.png"
				elseif nodename == "mcl_core:realm_barrier" then
					tex = "mcl_core_barrier.png^[colorize:#FF00FF:127^[transformFX"
				end
				if tex then
					minetest.add_particle({
						pos = {x=x, y=y, z=z},
						expirationtime = 1,
						size = 8,
						texture = tex,
						playername = name
					})
				end
			end
			end
			end
		end

		-- Update internal values
		mcl_playerplus_internal[name].lastPos = pos

	end

end)

-- set to blank on join (for 3rd party mods)
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()

	mcl_playerplus_internal[name] = {
		lastPos = nil,
		swimDistance = 0,
		jump_cooldown = -1,	-- Cooldown timer for jumping, we need this to prevent the jump exhaustion to increase rapidly
	}
end)

-- clear when player leaves
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()

	mcl_playerplus_internal[name] = nil
end)
