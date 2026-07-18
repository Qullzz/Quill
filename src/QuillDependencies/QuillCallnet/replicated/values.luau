local RunService = game:GetService("RunService")

local replicatedValue = require(script.Parent.replicatedValue)

local runContext: "server" | "client" = if RunService:IsServer() then "server" else "client"
local valueFolder: Folder
local valueDictionary: {
	[string]: replicatedValue.replicatedValueType,
} = {}

local values = {}

function values.start()
	if runContext == "server" then
		local storage = Instance.new("Folder")
		storage.Name = "CallNetStorage"
		storage.Parent = script.Parent.Parent

		valueFolder = storage
	elseif runContext == "client" then
		valueFolder = script.Parent.Parent:WaitForChild("CallNetStorage")
	end
end

function values.access(name: string): replicatedValue.replicatedValueType
	-- caching
	if valueDictionary[name] then
		return valueDictionary[name]
	end

	if runContext == "client" then
		local potentialValueInstance = valueFolder:FindFirstChild(name)
		if potentialValueInstance and potentialValueInstance:IsA("StringValue") then
			-- set up the value and return it
			local value = replicatedValue(potentialValueInstance)

			valueDictionary[name] = value

			return value
		end
	elseif runContext == "server" then
		-- create the value and return it
		local newValueInstance = Instance.new("StringValue")
		newValueInstance.Name = name
		newValueInstance.Parent = valueFolder

		local value = replicatedValue(newValueInstance)

		valueDictionary[name] = value

		return value
	end

	return valueDictionary[name]
end

return values
