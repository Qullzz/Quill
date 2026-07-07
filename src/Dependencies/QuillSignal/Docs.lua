--[[
	Meant to hold docs. Makes it easier to mess with them individually.
]]

if true then
	error("This is not supposed to run!")
end

export type ScriptSignal<T...> = {
	IsActive: (self: ScriptSignal<T...>) -> boolean,
	Fire: (self: ScriptSignal<T...>, T...) -> (),
	Connect: (self: ScriptSignal<T...>, callback: (T...) -> ()) -> ScriptConnection,
	Once: (self: ScriptSignal<T...>, callback: (T...) -> ()) -> ScriptConnection,
	DisconnectAll: (self: ScriptSignal<T...>) -> (),
	Destroy: (self: ScriptSignal<T...>) -> (),
	Wait: (self: ScriptSignal<T...>) -> T...,
}
export type ScriptConnection = {
	Disconnect: (self: ScriptConnection) -> (),
	Connected: boolean,
}

-- Legacy type. Do not use in newer work.
export type Class = ScriptSignal<...any>

-- Methods:

local ScriptSignal = {}
ScriptSignal.__index = ScriptSignal

local ScriptConnection = {}
ScriptConnection.__index = ScriptConnection

function ScriptSignal.new()
	return {}
end

function ScriptSignal.Is(object)
	return true
end

function ScriptSignal:IsActive()
	return true
end

function ScriptSignal:Connect(handler)

end

function ScriptSignal:Once(handler)

end

function ScriptSignal:Wait()
	
end

function ScriptSignal:Fire(...)
	
end

function ScriptSignal:DisconnectAll()
	
end

function ScriptSignal:Destroy()
	
end

function ScriptConnection:Disconnect()
	
end

local returnType = {}

function returnType.new<T...>(): ScriptSignal<T...>
	return ScriptSignal.new()
end

function returnType.Is(any): boolean
	return true
end

return returnType