-- Function that get the input/output rules of the delayer
local delayer_get_output_rules = function(node)
	local rules = {{x = -1, y = 0, z = 0}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local delayer_get_input_rules = function(node)
	local rules = {{x = 1, y = 0, z = 0}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

-- Functions that are called after the delay time

local delayer_turnon = function(params)
	local rules = delayer_get_output_rules(params.node)
	mesecon.receptor_on(params.pos, rules)
end

local delayer_turnoff = function(params)
	local rules = delayer_get_output_rules(params.node)
	mesecon.receptor_off(params.pos, rules)
end

local delayer_activate = function(pos, node)
	local def = minetest.registered_nodes[node.name]
	local time = def.delayer_time
	minetest.swap_node(pos, {name=def.delayer_onstate, param2=node.param2})
	minetest.after(time, delayer_turnon , {pos = pos, node = node})
end

local delayer_deactivate = function(pos, node)
	local def = minetest.registered_nodes[node.name]
	local time = def.delayer_time
	minetest.swap_node(pos, {name=def.delayer_offstate, param2=node.param2})
	minetest.after(time, delayer_turnoff, {pos = pos, node = node})
end

-- Register the 2 (states) x 4 (delay times) delayers

for i = 1, 4 do
local groups = {}
if i == 1 then 
	groups = {dig_immediate=3,dig_by_water=1,destroy_by_lava_flow=1,dig_by_piston=1,attached_node=1}
else
	groups = {dig_immediate=3,dig_by_water=1,destroy_by_lava_flow=1,dig_by_piston=1,attached_node=1, not_in_creative_inventory=1}
end

local delaytime
if i == 1 then delaytime = 0.1
elseif	i == 2 then delaytime = 0.2
elseif	i == 3 then delaytime = 0.3
elseif	i == 4 then delaytime = 0.4
end

local boxes
if i == 1 then
boxes = {
	{ -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },		-- the main slab
	{ -1/16, -6/16, 6/16, 1/16, -1/16, 4/16},     -- still torch
	{ -1/16, -6/16, 0/16, 1/16, -1/16, 2/16},     -- moved torch 
}
elseif i == 2 then
boxes = {
	{ -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },		-- the main slab
	{ -1/16, -6/16, 6/16, 1/16, -1/16, 4/16},     -- still torch
	{ -1/16, -6/16, -2/16, 1/16, -1/16, 0/16},     -- moved torch 
}
elseif i == 3 then
boxes = {
	{ -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },		-- the main slab
	{ -1/16, -6/16, 6/16, 1/16, -1/16, 4/16},     -- still torch
	{ -1/16, -6/16, -4/16, 1/16, -1/16, -2/16},     -- moved torch 
}
elseif i == 4 then
boxes = {
	{ -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },		-- the main slab
	{ -1/16, -6/16, 6/16, 1/16, -1/16, 4/16},     -- still torch
	{ -1/16, -6/16, -6/16, 1/16, -1/16, -4/16},     -- moved torch 
}
end

local help, longdesc, usagehelp, icon
if i == 1 then
	help = true
	longdesc = "Redstone repeaters are versatile redstone components which delay redstone signals and only allow redstone signals to travel through one direction. The delay of the signal is indicated by the redstone torches and is between 0.1 and 0.4 seconds long."
	usagehelp = "To power a redstone repeater, send a signal in “arrow” direction. To change the delay, rightclick the redstone repeater. The delay is changed in steps of 0.1 seconds."
	icon = "mesecons_delayer_item.png"
else
	help = false
end

minetest.register_node("mesecons_delayer:delayer_off_"..tostring(i), {
	description = "Redstone Repeater",
	inventory_image = icon,
	wield_image = icon,
	_doc_items_create_entry = help,
	_doc_items_longdesc = longdesc,
	_doc_items_usagehelp = usagehelp,
	drawtype = "nodebox",
	tiles = {
		"mesecons_delayer_off.png",
		"mcl_stairs_stone_slab_top.png",
		"mesecons_delayer_sides_off.png",
		"mesecons_delayer_sides_off.png",
		"mesecons_delayer_ends_off.png",
		"mesecons_delayer_ends_off.png",
		},
	wield_image = "mesecons_delayer_off.png",
	walkable = true,
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },
	},
	collision_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },
	},
	node_box = {
		type = "fixed",
		fixed = boxes
	},
	groups = groups,
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = false,
	is_ground_content = false,
	drop = 'mesecons_delayer:delayer_off_1',
	on_rightclick = function (pos, node)
		if node.name=="mesecons_delayer:delayer_off_1" then
			minetest.swap_node(pos, {name="mesecons_delayer:delayer_off_2", param2=node.param2})
		elseif node.name=="mesecons_delayer:delayer_off_2" then
			minetest.swap_node(pos, {name="mesecons_delayer:delayer_off_3", param2=node.param2})
		elseif node.name=="mesecons_delayer:delayer_off_3" then
			minetest.swap_node(pos, {name="mesecons_delayer:delayer_off_4", param2=node.param2})
		elseif node.name=="mesecons_delayer:delayer_off_4" then
			minetest.swap_node(pos, {name="mesecons_delayer:delayer_off_1", param2=node.param2})
		end
	end,
	delayer_time = delaytime,
	delayer_onstate = "mesecons_delayer:delayer_on_"..tostring(i),
	sounds = mcl_sounds.node_sound_stone_defaults(),
	mesecons = {
		receptor =
		{
			state = mesecon.state.off,
			rules = delayer_get_output_rules
		},
		effector =
		{
			rules = delayer_get_input_rules,
			action_on = delayer_activate
		}
	}
})


minetest.register_node("mesecons_delayer:delayer_on_"..tostring(i), {
	description = "Redstone Repeater (Powered)",
	_doc_items_create_entry = false,
	drawtype = "nodebox",
	tiles = {
		"mesecons_delayer_on.png",
		"mcl_stairs_stone_slab_top.png",
		"mesecons_delayer_sides_on.png",
		"mesecons_delayer_sides_on.png",
		"mesecons_delayer_ends_on.png",
		"mesecons_delayer_ends_on.png",
		},
	walkable = true,
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },
	},
	collision_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },
	},
	node_box = {
		type = "fixed",
		fixed = boxes
	},
	groups = {dig_immediate = 3, dig_by_water=1,destroy_by_lava_flow=1, dig_by_piston=1, attached_node=1, not_in_creative_inventory = 1},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = false,
	is_ground_content = false,
	drop = 'mesecons_delayer:delayer_off_1',
	on_rightclick = function (pos, node)
		if node.name=="mesecons_delayer:delayer_on_1" then
			minetest.swap_node(pos, {name="mesecons_delayer:delayer_on_2",param2=node.param2})
		elseif node.name=="mesecons_delayer:delayer_on_2" then
			minetest.swap_node(pos, {name="mesecons_delayer:delayer_on_3",param2=node.param2})
		elseif node.name=="mesecons_delayer:delayer_on_3" then
			minetest.swap_node(pos, {name="mesecons_delayer:delayer_on_4",param2=node.param2})
		elseif node.name=="mesecons_delayer:delayer_on_4" then
			minetest.swap_node(pos, {name="mesecons_delayer:delayer_on_1",param2=node.param2})
		end
	end,
	delayer_time = delaytime,
	delayer_offstate = "mesecons_delayer:delayer_off_"..tostring(i),
	mesecons = {
		receptor =
		{
			state = mesecon.state.on,
			rules = delayer_get_output_rules
		},
		effector =
		{
			rules = delayer_get_input_rules,
			action_off = delayer_deactivate
		}
	}
})
end

minetest.register_craft({
	output = "mesecons_delayer:delayer_off_1",
	recipe = {
		{"mesecons_torch:mesecon_torch_on", "mesecons:redstone", "mesecons_torch:mesecon_torch_on"},
		{"mcl_core:stone","mcl_core:stone", "mcl_core:stone"},
	}
})

-- Add entry aliases for the Help
if minetest.get_modpath("doc") then
	doc.add_entry_alias("nodes", "mesecons_delayer:delayer_off_1", "nodes", "mesecons_delayer:delayer_off_2")
	doc.add_entry_alias("nodes", "mesecons_delayer:delayer_off_1", "nodes", "mesecons_delayer:delayer_off_3")
	doc.add_entry_alias("nodes", "mesecons_delayer:delayer_off_1", "nodes", "mesecons_delayer:delayer_off_4")
	doc.add_entry_alias("nodes", "mesecons_delayer:delayer_off_1", "nodes", "mesecons_delayer:delayer_on_1")
	doc.add_entry_alias("nodes", "mesecons_delayer:delayer_off_1", "nodes", "mesecons_delayer:delayer_on_2")
	doc.add_entry_alias("nodes", "mesecons_delayer:delayer_off_1", "nodes", "mesecons_delayer:delayer_on_3")
	doc.add_entry_alias("nodes", "mesecons_delayer:delayer_off_1", "nodes", "mesecons_delayer:delayer_on_4")
end
