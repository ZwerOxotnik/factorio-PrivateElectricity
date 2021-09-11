---@class PE : module
local M = {}


--#region Functions of events

local function protect_from_theft_of_electricity(event)
	local entity = event.created_entity
	local disconnect_neighbour = entity.disconnect_neighbour
	local force = entity.force
	local get_cease_fire = force.get_cease_fire
	for _, neighbour in pairs(entity.neighbours["copper"]) do
		local neighbour_force = neighbour.force
		if force ~= neighbour_force then
			if not get_cease_fire(neighbour_force) then
				disconnect_neighbour(neighbour)
			end
		end
	end
end

--#endregion


--#region Pre-game stage

local function set_filters()
	local filters = {{filter = "type", type = "electric-pole"}}
	script.set_event_filter(defines.events.on_robot_built_entity, filters)
	script.set_event_filter(defines.events.on_built_entity, filters)
end

local function add_remote_interface()
	-- https://lua-api.factorio.com/latest/LuaRemote.html
	remote.remove_interface("PrivateElectricity") -- For safety
	remote.add_interface("PrivateElectricity", {})
end

M.on_init = set_filters
M.on_load = set_filters
M.add_remote_interface = add_remote_interface

--#endregion


M.events = {
	[defines.events.on_robot_built_entity] = function(event)
		pcall(protect_from_theft_of_electricity, event)
	end,
	[defines.events.on_built_entity] = function(event)
		pcall(protect_from_theft_of_electricity, event)
	end
}

return M
