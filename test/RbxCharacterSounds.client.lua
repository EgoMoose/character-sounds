--!strict

local Players = game:GetService("Players")

local CharacterSounds = require(game.ReplicatedStorage.Packages.CharacterSounds)

local playerStates = {}

local function terminateSound(player: Player)
	local state = playerStates[player] or {}
	if state.terminateSound then
		state.terminateSound()
		state.terminateSound = nil
	end
end

local function characterRemoving(player: Player, _character: Model)
	terminateSound(player)
end

local function characterAdded(player: Player, character: Model)
	characterRemoving(player, character)

	local state = playerStates[player]
	if state then
		local controller = CharacterSounds.listen(character)

		--controller.fireState(Enum.HumanoidStateType.Climbing)
		--controller.setVelocity(Vector3.new(0, 100, 0))

		state.terminateSound = function()
			controller.cleanup()
		end
	end
end

local function playerRemoving(player: Player)
	terminateSound(player)

	local state = playerStates[player] or {}
	for _, connection in state.connections or {} do
		connection:Disconnect()
	end

	playerStates[player] = nil
end

local function playerAdded(player: Player)
	playerRemoving(player)

	local state = {
		connections = {},
		terminateSound = nil,
	}

	if player.Character then
		characterAdded(player, player.Character)
	end

	table.insert(
		state.connections,
		player.CharacterAdded:Connect(function(character)
			characterAdded(player, character)
		end)
	)

	table.insert(
		state.connections,
		player.CharacterRemoving:Connect(function(character)
			characterRemoving(player, character)
		end)
	)

	playerStates[player] = state
end

----

for _, player in Players:GetPlayers() do
	task.spawn(playerAdded, player)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)
