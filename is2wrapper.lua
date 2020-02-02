-- Interstellar 2 WarpDrive wrapper.
-- Many fucntion names are equal to the original ones, so you can find more info about them here:
-- https://github.com/LemADEC/WarpDrive/wiki/LUA-properties-for-Movement
local component = require("component")

local wrapper = {}

wrapper.demoMode = false -- In demo mode, there are no actual components used. Made for easier main program writing.
wrapper.ship = {}

wrapper.shipApiAvailable = function()
	return component.isAvailable("warpdriveShipController") or wrapper.demoMode
end

wrapper.toggleDemoMode = function()
	wrapper.demoMode = not wrapper.demoMode
end

wrapper.ship.getComponent = function()
	return component.warpdriveShipController
end

wrapper.ship.getDimensionType = function() -- 0 - Space, 1 - Hyperspace, 2 - Unknown (since WarpDrive API returns "?" every time you're tryin' to get a dimension, so no way to know it)
	if wrapper.demoMode then
		return 0
	end

	if wrapper.ship.getComponent().isInSpace() then return 0 elseif ship.getComponent.isInHyperspace() then return 1 else return 2 end
end

wrapper.ship.setCommand = function(command) -- Sets ship command mode. 
	if wrapper.demoMode then
		return
	end

	wrapper.ship.getComponent().command(command)
end

wrapper.ship.getCommand = function() -- Gets ship command mode.
	if wrapper.demoMode then
		return "IDLE"
	end

	return wrapper.ship.getComponent().command()
end

wrapper.ship.getPosition = function() -- X, Y, Z of ship.
	if wrapper.demoMode then
		return 1, 2, 3
	end

	local x, y, z = wrapper.ship.getComponent().position()

	return x, y, z
end

wrapper.ship.getDimPositive = function() -- Gets positive ship dimensions (Front, Right, Up)
	if wrapper.demoMode then
		return 10, 5, 7
	end

	return wrapper.ship.getComponent().dim_positive()
end

wrapper.ship.getDimNegative = function() -- Gets negative ship dimensions (Back, Left, Down)
	if wrapper.demoMode then
		return 4, 3, 6
	end

	return wrapper.ship.getComponent().dim_negative()
end

wrapper.ship.getMaxJumpDistance = function() -- Gets maximum jump distance. Actually a base distance, the real maximum for an axis is this + dim_positive + dim_negative
	if wrapper.demoMode then
		return 250
	end

	_, max = wrapper.ship.getComponent().getMaxJumpDistance()

	return max
end

wrapper.ship.getMovement = function() -- Gets last jump move coordinates.
	if wrapper.demoMode then
		return 40, 30, 20
	end

	return wrapper.ship.getComponent().movement()
end

wrapper.ship.setMovement = function(x, y, z) -- Sets ship movement for jump
	if wrapper.demoMode then
		return
	end

	wrapper.ship.getComponent().movement(x, y, z)
end

wrapper.ship.setRotationSteps = function(rotationSteps) -- Sets ship rotation steps for jump
	if wrapper.demoMode then
		return
	end

	wrapper.ship.getComponent().rotationSteps(rotationSteps)
end

wrapper.ship.enable = function(flag) -- Makes ship do whatever it should, depends on current command. If false, cancels what ship is currently doing.
	if wrapper.demoMode then
		return
	end

	wrapper.ship.getComponent().enable(flag)
end

wrapper.ship.jump = function(rotationSteps, x, y, z, hyper) -- Make the ship jump. If hyper is true, then ship jumps hyper, and all arguments are ignored.
	if wrapper.demoMode then
		return
	end

	if hyper then
		wrapper.ship.setCommand("HYPERDRIVE")
		wrapper.ship.enable(true)
	else
		wrapper.ship.setCommand("MANUAL")
		wrapper.ship.setRotationSteps(rotationSteps)
		wrapper.ship.setMovement(x, y, z)
		wrapper.ship.enable(true)
	end
end

return wrapper