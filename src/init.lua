--!strict

local SoundSystem = require(script:WaitForChild("SoundSystem"))
local AtomicBinding = require(script:WaitForChild("AtomicBinding"))

local module = {}

function module.listen(director: Model, performer: Model?)
	local actor = performer or director
	local terminate: (() -> ())?

	local function clearSound()
		if terminate then
			terminate()
			terminate = nil
		end
	end

	local function onBind(groupManifest: { [string]: { [string]: Instance } })
		clearSound()
		terminate = SoundSystem({
			actor = {
				humanoid = groupManifest.actor.humanoid :: Humanoid,
				rootPart = groupManifest.actor.rootPart :: BasePart,
			},
			director = {
				humanoid = groupManifest.director.humanoid :: Humanoid,
				rootPart = groupManifest.director.rootPart :: BasePart,
			},
		})
	end

	local function onUnbind()
		clearSound()
	end

	local clearBinding = AtomicBinding.multiple({
		groupManifest = {
			actor = {
				root = actor,
				manifest = {
					humanoid = { "Humanoid" },
					rootPart = { "HumanoidRootPart" },
				},
			},
			director = {
				root = director,
				manifest = {
					humanoid = { "Humanoid" },
					rootPart = { "HumanoidRootPart" },
				},
			},
		},

		onBind = onBind,
		onUnbind = onUnbind,
	})

	return function()
		clearBinding()
		clearSound()
	end
end

return module
