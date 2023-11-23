--!strict

local ROOT_ALIAS = "root"

type ResolvedManifest = { [string]: Instance }

type Node = {
	alias: string?,
	instance: Instance?,
	children: { [string]: Node }?,
	connections: { RBXScriptConnection }?,
}

type AtomicBindingState = {
	root: Instance,
	manifestSizeTarget: number,
	resolvedManifest: ResolvedManifest,

	onBind: (ResolvedManifest) -> (),
	onUnbind: (ResolvedManifest) -> (),
}

local module = {}

-- Private

local function isManifestResolved(state: AtomicBindingState)
	local manifestSize = 0
	for _ in state.resolvedManifest do
		manifestSize = manifestSize + 1
	end

	assert(
		manifestSize <= state.manifestSizeTarget,
		"Manifest size is larger than the target manifest size. This shouldn't be possible."
	)

	return manifestSize == state.manifestSizeTarget
end

local function unbindNodeDescend(state: AtomicBindingState, node: Node)
	if node.instance == nil then
		return
	end

	node.instance = nil

	local connections = node.connections
	if connections then
		for _, conn in connections do
			conn:Disconnect()
		end
		table.clear(connections)
	end

	if node.alias then
		state.resolvedManifest[node.alias] = nil
	end

	local children = node.children
	if children then
		for _, childNode in children do
			unbindNodeDescend(state, childNode)
		end
	end
end

local function processNode(state: AtomicBindingState, node: Node)
	local instance = assert(node.instance, "No instance specified for node")

	local children = node.children
	local alias = node.alias
	local isLeaf = not children

	if alias then
		state.resolvedManifest[alias] = instance
	end

	if not isLeaf and children and node.connections then
		local function processAddChild(childInstance: Instance)
			local childName = childInstance.Name
			local childNode = children[childName]
			if not childNode or childNode.instance ~= nil then
				return
			end

			childNode.instance = childInstance
			processNode(state, childNode)
		end

		local function processDeleteChild(childInstance: Instance)
			local childName = childInstance.Name
			local childNode = children[childName]

			if not childNode then
				return
			end

			if childNode.instance ~= childInstance then
				return
			end

			state.onUnbind(state.resolvedManifest)
			unbindNodeDescend(state, childNode)

			assert(childNode.instance == nil, "unbindNodeDescend failed")

			-- Search for a replacement
			local replacementChild = instance:FindFirstChild(childName)
			if replacementChild then
				processAddChild(replacementChild)
			end
		end

		for _, child in instance:GetChildren() do
			processAddChild(child)
		end

		table.insert(node.connections, instance.ChildAdded:Connect(processAddChild))
		table.insert(node.connections, instance.ChildRemoved:Connect(processDeleteChild))
	end

	if isLeaf and isManifestResolved(state) then
		state.onBind(state.resolvedManifest)
	end
end

-- Public

function module.create(options: {
	root: Instance,
	manifest: { [string]: { string } },
	onBind: (ResolvedManifest) -> (),
	onUnbind: (ResolvedManifest) -> (),
})
	local root = options.root
	local manifest = options.manifest
	local manifestTargetSize = 1

	local rootNode: Node = {
		alias = ROOT_ALIAS,
		instance = root,
	}

	if next(manifest) then
		rootNode.children = {}
		rootNode.connections = {}
	end

	for alias, path in manifest do
		local parentNode = rootNode

		if not parentNode.children then
			continue
		end

		manifestTargetSize = manifestTargetSize + 1

		for i, childName in path do
			local isLeaf = (i == #path)
			local childNode: Node = parentNode.children and parentNode.children[childName] or {}

			if isLeaf then
				if childNode.alias ~= nil then
					error("Multiple aliases assigned to one instance")
				end

				childNode.alias = alias
			else
				childNode.children = childNode.children or {}
				childNode.connections = childNode.connections or {}
			end

			parentNode.children[childName] = childNode
			parentNode = childNode
		end
	end

	local state: AtomicBindingState = {
		root = root,
		resolvedManifest = {},
		manifestSizeTarget = manifestTargetSize,

		onBind = options.onBind,
		onUnbind = options.onUnbind,
	}

	processNode(state, rootNode)

	return function()
		if isManifestResolved(state) then
			state.onUnbind(state.resolvedManifest)
		end

		unbindNodeDescend(state, rootNode)
	end
end

type ResolvedGroupManifest = { [string]: { [string]: Instance } }
type GroupManifest = { [string]: {
	root: Instance,
	manifest: { [string]: { string } },
} }

function module.multiple(options: {
	groupManifest: GroupManifest,
	onBind: (ResolvedGroupManifest) -> (),
	onUnbind: (ResolvedGroupManifest) -> (),
})
	local terminations = {}
	local resolvedManifestsByAlias = {}

	local isReconciled = false
	local prevResolvedGroupManifest: ResolvedGroupManifest
	local function reconcile()
		local groupCount = 0
		local reconciledCount = 0

		local resolvedGroupManifest = {}
		for alias, _ in options.groupManifest do
			groupCount = groupCount + 1

			local resolvedManifest = resolvedManifestsByAlias[alias]
			if resolvedManifest then
				reconciledCount = reconciledCount + 1
				resolvedGroupManifest[alias] = resolvedManifest
			end
		end

		local reconciled = (groupCount == reconciledCount)
		if reconciled ~= isReconciled then
			isReconciled = reconciled

			if reconciled then
				prevResolvedGroupManifest = resolvedGroupManifest
				options.onBind(resolvedGroupManifest)
			else
				options.onUnbind(prevResolvedGroupManifest)
			end
		end
	end

	for alias, group in options.groupManifest do
		table.insert(
			terminations,
			module.create({
				root = group.root,
				manifest = group.manifest,

				onBind = function(resolvedManifest)
					resolvedManifestsByAlias[alias] = resolvedManifest
					reconcile()
				end,
				onUnbind = function()
					resolvedManifestsByAlias[alias] = nil
					reconcile()
				end,
			})
		)
	end

	return function()
		for _, terminate in terminations do
			terminate()
		end
		resolvedManifestsByAlias = {}
		reconcile()
	end
end

--

return module
