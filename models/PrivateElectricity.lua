---@class PE : module
local M = {}


local allow_ally_connection = settings.global["PE_allow_ally_connection"].value


--#region Functions of events

local function protect_from_theft_of_electricity(event)
	local entity = event.entity
	local force = entity.force
	local neighbours = entity.get_wire_connectors()[defines.wire_connector_id.pole_copper]
	if allow_ally_connection then
		local friendly_relations = {}
		for _, connection in pairs(neighbours.real_connections) do
			local neighbour_force = connection.target.owner.force
			if force ~= neighbour_force then
				local is_friendly = friendly_relations[neighbour_force]
				if is_friendly == false then
					neighbours.disconnect_all()
				elseif is_friendly == nil then
					if force.get_cease_fire(neighbour_force) and
						neighbour_force.get_cease_fire(force) and
						force.get_friend(neighbour_force) and
						neighbour_force.get_friend(force)
					then
						friendly_relations[neighbour_force] = true
					else
						neighbours.disconnect_all()
						friendly_relations[neighbour_force] = false
					end
				end
			end
		end
	else
		for _, connection in pairs(neighbours.real_connections) do
			if force ~= connection.target.owner.force then
				neighbours.disconnect_all()
			end
		end
	end
end

local MOD_SETTINGS = {
	["PE_allow_ally_connection"] = function(value)
		allow_ally_connection = value
	end,
}
local function on_runtime_mod_setting_changed(event)
	if event.setting_type ~= "runtime-global" then return end

	local setting_name = event.setting

	local f = MOD_SETTINGS[setting_name]
	if f then f(settings.global[setting_name].value) end
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
M.on_mod_enabled = set_filters
M.on_mod_disabled = set_filters
M.add_remote_interface = add_remote_interface

--#endregion


M.events = {
	[defines.events.on_robot_built_entity] = function(event)
		pcall(protect_from_theft_of_electricity, event)
	end,
	[defines.events.on_built_entity] = function(event)
		pcall(protect_from_theft_of_electricity, event)
	end,
	-- [defines.events.on_built_entity] = protect_from_theft_of_electricity,
	[defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed
}
M.events_when_off = {}

return M
