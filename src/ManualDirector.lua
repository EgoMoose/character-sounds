--!strict

local Packages = script.Parent.Parent
local Signal = require(Packages:WaitForChild("Signal"))

type ScriptSignal = RBXScriptSignal & {
	Fire: (...any) -> (),
}

export type ManualDirector = {
	rootPart: ManualRootPart,
	humanoid: ManualHumanoid,
	fireState: (Enum.HumanoidStateType) -> (),
}

export type ManualHumanoid = {
	StateChanged: ScriptSignal,
	GetState: () -> Enum.HumanoidStateType,
}

export type ManualRootPart = {
	AssemblyLinearVelocity: Vector3,
}

local module = {}

function module.create(): ManualDirector
	local currentState = Enum.HumanoidStateType.Running
	local humanoid: ManualHumanoid = {
		StateChanged = Signal.new(),

		GetState = function()
			return currentState
		end,
	}

	local rootPart: ManualRootPart = {
		AssemblyLinearVelocity = Vector3.zero,
	}

	local function fireState(state: Enum.HumanoidStateType)
		if state ~= currentState then
			local prevState = currentState
			currentState = state
			humanoid.StateChanged:Fire(prevState, currentState)
		end
	end

	return {
		rootPart = rootPart,
		humanoid = humanoid,
		fireState = fireState,
	}
end

return module
