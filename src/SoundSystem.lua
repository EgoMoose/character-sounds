--!strict

type SoundSystemInstances = {
	director: {
		humanoid: Humanoid,
		rootPart: BasePart,
	},
	actor: {
		humanoid: Humanoid,
		rootPart: BasePart,
	},
}

type SoundProperties = {
	SoundId: string,
	Looped: boolean?,
	Pitch: number?,
}

local RunService = game:GetService("RunService")

local SERIALIZED_SOUNDS: { [string]: SoundProperties } = {
	Climbing = {
		SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3",
		Looped = true,
	},
	Died = {
		SoundId = "rbxasset://sounds/uuhhh.mp3",
	},
	FreeFalling = {
		SoundId = "rbxasset://sounds/action_falling.mp3",
		Looped = true,
	},
	GettingUp = {
		SoundId = "rbxasset://sounds/action_get_up.mp3",
	},
	Jumping = {
		SoundId = "rbxasset://sounds/action_jump.mp3",
	},
	Landing = {
		SoundId = "rbxasset://sounds/action_jump_land.mp3",
	},
	Running = {
		SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3",
		Looped = true,
		Pitch = 1.85,
	},
	Splash = {
		SoundId = "rbxasset://sounds/impact_water.mp3",
	},
	Swimming = {
		SoundId = "rbxasset://sounds/action_swim.mp3",
		Looped = true,
		Pitch = 1.6,
	},
}

local STATE_REMAP = {
	[Enum.HumanoidStateType.RunningNoPhysics] = Enum.HumanoidStateType.Running,
}

local module = {}

-- Private

local function mapNumber(x: number, inMin: number, inMax: number, outMin: number, outMax: number): number
	local normalized = (x - inMin) / (inMax - inMin)
	return normalized * (outMax - outMin) + outMin
end

local function playSound(sound: Sound)
	sound.TimePosition = 0
	sound.Playing = true
end

-- Public

function module.initialize(instances: SoundSystemInstances)
	local _actorHumanoid = instances.actor.humanoid
	local actorRootPart = instances.actor.rootPart
	local directorHumanoid = instances.director.humanoid
	local directorRootPart = instances.director.rootPart

	local sounds = {}
	local playingLoopedSounds = {}

	for name, properties in SERIALIZED_SOUNDS do
		local sound: Sound = Instance.new("Sound")
		sound.Name = name

		sound.Archivable = false
		sound.RollOffMinDistance = 5
		sound.RollOffMaxDistance = 150
		sound.Volume = 0.65

		for key, value in properties :: { [string]: any } do
			(sound :: any)[key] = value
		end

		sound.Parent = actorRootPart
		sounds[name] = sound
	end

	local function stopPlayingLoopedSounds(except: Sound?)
		for sound, _ in playingLoopedSounds do
			if sound ~= except then
				sound.Playing = false
				playingLoopedSounds[sound] = nil
			end
		end
	end

	local stateTransitions = {
		[Enum.HumanoidStateType.FallingDown] = function()
			stopPlayingLoopedSounds()
		end,

		[Enum.HumanoidStateType.GettingUp] = function()
			stopPlayingLoopedSounds()
			playSound(sounds.GettingUp)
		end,

		[Enum.HumanoidStateType.Jumping] = function()
			stopPlayingLoopedSounds()
			playSound(sounds.Jumping)
		end,

		[Enum.HumanoidStateType.Swimming] = function()
			local verticalSpeed = math.abs(directorRootPart.AssemblyLinearVelocity.Y)
			if verticalSpeed > 0.1 then
				sounds.Splash.Volume = math.clamp(mapNumber(verticalSpeed, 100, 350, 0.28, 1), 0, 1)
				playSound(sounds.Splash)
			end
			stopPlayingLoopedSounds(sounds.Swimming)
			sounds.Swimming.Playing = true
			playingLoopedSounds[sounds.Swimming] = true
		end,

		[Enum.HumanoidStateType.Freefall] = function()
			sounds.FreeFalling.Volume = 0
			sounds.FreeFalling.Playing = true
			stopPlayingLoopedSounds(sounds.FreeFalling)
			playingLoopedSounds[sounds.FreeFalling] = true
		end,

		[Enum.HumanoidStateType.Landed] = function()
			stopPlayingLoopedSounds()
			local verticalSpeed = math.abs(directorRootPart.AssemblyLinearVelocity.Y)
			if verticalSpeed > 75 then
				sounds.Landing.Volume = math.clamp(mapNumber(verticalSpeed, 50, 100, 0, 1), 0, 1)
				playSound(sounds.Landing)
			end
		end,

		[Enum.HumanoidStateType.Running] = function()
			stopPlayingLoopedSounds(sounds.Running)
			sounds.Running.Playing = true
			playingLoopedSounds[sounds.Running] = true
		end,

		[Enum.HumanoidStateType.Climbing] = function()
			local sound = sounds.Climbing
			if math.abs(directorRootPart.AssemblyLinearVelocity.Y) > 0.1 then
				sound.Playing = true
				stopPlayingLoopedSounds(sound)
			else
				stopPlayingLoopedSounds()
			end
			playingLoopedSounds[sound] = true
		end,

		[Enum.HumanoidStateType.Seated] = function()
			stopPlayingLoopedSounds()
		end,

		[Enum.HumanoidStateType.Dead] = function()
			stopPlayingLoopedSounds()
			playSound(sounds.Died)
		end,
	}

	local loopedSoundUpdaters = {
		[sounds.Climbing] = function(_dt: number, sound: Sound, vel: Vector3)
			sound.Playing = vel.Magnitude > 0.1
		end,

		[sounds.FreeFalling] = function(dt: number, sound: Sound, vel: Vector3)
			if vel.Magnitude > 75 then
				sound.Volume = math.clamp(sound.Volume + 0.9 * dt, 0, 1)
			else
				sound.Volume = 0
			end
		end,

		[sounds.Running] = function(_dt: number, sound: Sound, vel: Vector3)
			sound.Playing = vel.Magnitude > 0.5 and directorHumanoid.MoveDirection.Magnitude > 0.5
		end,
	}

	local activeState = STATE_REMAP[directorHumanoid:GetState()] or directorHumanoid:GetState()

	local function transitionTo(state: Enum.HumanoidStateType)
		local transitionFunc: () -> () = stateTransitions[state]

		if transitionFunc then
			transitionFunc()
		end

		activeState = state
	end

	transitionTo(activeState)

	local stateChangedConn = directorHumanoid.StateChanged:Connect(function(_, state)
		state = STATE_REMAP[state] or state

		if state ~= activeState then
			transitionTo(state)
		end
	end)

	local steppedConn = RunService.Stepped:Connect(function(_, worldDt: number)
		for sound, _ in playingLoopedSounds do
			local updater = loopedSoundUpdaters[sound]

			if updater then
				updater(worldDt, sound, directorRootPart.AssemblyLinearVelocity)
			end
		end
	end)

	local function terminate()
		stateChangedConn:Disconnect()
		steppedConn:Disconnect()

		for _name, sound in sounds do
			sound:Destroy()
		end

		table.clear(sounds)
	end

	return terminate
end

--

return module
