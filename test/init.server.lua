local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local RbxCharacterSounds = script:WaitForChild("RbxCharacterSounds")

local found = StarterPlayerScripts:FindFirstChild(RbxCharacterSounds.Name)
if found then
	found:Destroy()
end

RbxCharacterSounds:Clone().Parent = StarterPlayerScripts
