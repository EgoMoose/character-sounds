--!strict

local SoundSystem = require(script:WaitForChild("SoundSystem"))

local module = {}

function module.listen(director: Model, performer: Model?)
	local actor = performer or director

	return function() end
end

return module
