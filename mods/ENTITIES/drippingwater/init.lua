--Dripping Water Mod
--by kddekadenz

-- License of code, textures & sounds: CC0

--Drop entities

--water

local water_tex = "default_water_source_animated.png^[verticalframe:16:0"
minetest.register_entity("drippingwater:drop_water", {
	hp_max = 1,
	physical = true,
	collide_with_objects = false,
	collisionbox = {0,0,0,0,0,0},
	visual = "cube",
	visual_size = {x=0.05, y=0.1},
	textures = {water_tex, water_tex, water_tex, water_tex, water_tex, water_tex},
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},

	on_activate = function(self, staticdata)
		self.object:setsprite({x=0,y=0}, 1, 1, true)
	end,

	on_step = function(self, dtime)
	local k = math.random(1,222)
	local ownpos = self.object:getpos()

	if k==1 then
	self.object:setacceleration({x=0, y=-5, z=0})
	end

	if minetest.get_node({x=ownpos.x, y=ownpos.y +0.5, z=ownpos.z}).name == "air" then
	self.object:setacceleration({x=0, y=-5, z=0})
	end
	
		if minetest.get_node({x=ownpos.x, y=ownpos.y -0.5, z=ownpos.z}).name ~= "air" then
		self.object:remove()
		minetest.sound_play({name="drippingwater_drip"}, {pos = ownpos, gain = 0.5, max_hear_distance = 8})
		end
	end,
})


--lava

local lava_tex = "default_lava_source_animated.png^[verticalframe:16:0"
minetest.register_entity("drippingwater:drop_lava", {
	hp_max = 1,
	physical = true,
	collide_with_objects = false,
	collisionbox = {0,0,0,0,0,0},
	visual = "cube",
	visual_size = {x=0.05, y=0.1},
	textures = {lava_tex, lava_tex, lava_tex, lava_tex, lava_tex, lava_tex},
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},

	on_activate = function(self, staticdata)
		self.object:setsprite({x=0,y=0}, 1, 0, true)
	end,

	on_step = function(self, dtime)
	local k = math.random(1,222)
	local ownpos = self.object:getpos()

	if k==1 then
	self.object:setacceleration({x=0, y=-5, z=0})
	end

	if minetest.get_node({x=ownpos.x, y=ownpos.y +0.5, z=ownpos.z}).name == "air" then
	self.object:setacceleration({x=0, y=-5, z=0})
	end

		
		if minetest.get_node({x=ownpos.x, y=ownpos.y -0.5, z=ownpos.z}).name ~= "air" then
		self.object:remove()
		minetest.sound_play({name="drippingwater_lavadrip"}, {pos = ownpos, gain = 0.5, max_hear_distance = 8})
		end
	end,
})



--Create drop

minetest.register_abm(
        {
	label = "Create water drops",
	nodenames = {"group:solid"},
	neighbors = {"group:water"},
        interval = 2,
        chance = 22,
        action = function(pos)
		if minetest.get_item_group(minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z}).name, "water") ~= 0 and
				minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name == "air" then
			local i = math.random(-45,45) / 100
			minetest.add_entity({x=pos.x + i, y=pos.y - 0.501, z=pos.z + i}, "drippingwater:drop_water")
		end
        end,
})

--Create lava drop

minetest.register_abm(
        {
	label = "Create lava drops",
	nodenames = {"group:solid"},
	neighbors = {"group:lava"},
        interval = 2,
        chance = 22,
        action = function(pos)
		if minetest.get_item_group(minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z}).name, "lava") ~= 0 and
				minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name == "air" then
			local i = math.random(-45,45) / 100
			minetest.add_entity({x=pos.x + i, y=pos.y - 0.501, z=pos.z + i}, "drippingwater:drop_lava")
		end
        end,
})
