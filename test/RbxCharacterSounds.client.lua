--!strict

local Players = game:GetService("Players")

local CharacterSounds = require(game.ReplicatedStorage.Packages.CharacterSounds)

local function doNothing() end

local function onPlayerAdded(player: Player)
	local cleanup = doNothing

	local function onCharacterAdded(character: Model)
		cleanup()
		cleanup = CharacterSounds.listen(character)
	end

	if player.Character then
		onCharacterAdded(player.Character)
	end

	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(function()
		cleanup()
		cleanup = doNothing
	end)
end

onPlayerAdded(Players.LocalPlayer)
Players.PlayerAdded:Connect(onPlayerAdded)
