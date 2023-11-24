--!strict

local SoundSystem = require(script:WaitForChild("SoundSystem"))
local AtomicBinding = require(script:WaitForChild("AtomicBinding"))
local ManualDirector = require(script:WaitForChild("ManualDirector"))

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
		terminate = SoundSystem.initialize({
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

	local controller = {
		cleanup = function()
			clearBinding()
			clearSound()
		end,
	}

	return controller
end

function module.manual(performer: Model)
	local manualDirector = ManualDirector.create()
	local terminate: (() -> ())?

	local function clearSound()
		if terminate then
			terminate()
			terminate = nil
		end
	end

	local function onBind(manifest: { [string]: Instance })
		clearSound()
		terminate = SoundSystem.initialize({
			actor = {
				humanoid = manifest.humanoid :: Humanoid,
				rootPart = manifest.rootPart :: BasePart,
			},
			director = {
				humanoid = manualDirector.humanoid :: any,
				rootPart = manualDirector.rootPart :: any,
			},
		})
	end

	local function onUnbind()
		clearSound()
	end

	local clearBinding = AtomicBinding.create({
		root = performer,
		manifest = {
			humanoid = { "Humanoid" },
			rootPart = { "HumanoidRootPart" },
		},

		onBind = onBind,
		onUnbind = onUnbind,
	})

	local controller = {
		fireState = manualDirector.fireState,
		setVelocity = function(velocity: Vector3)
			manualDirector.rootPart.AssemblyLinearVelocity = velocity
		end,
		cleanup = function()
			clearBinding()
			clearSound()
		end,
	}

	return controller
end

return module
