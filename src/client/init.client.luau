local Keybinds = require(script:WaitForChild("keybinds"))
local Camera2D = require(script:WaitForChild("camera2d"))
local Movement2D = require(script:WaitForChild("movement2d"))
local ChatListener = require(script:WaitForChild("chatListener"))

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = nil
local _humanoid = nil
local slideClient = nil
local dJumpClient = nil
local dashClient = nil

local curInputDir = Vector3.zero

RunService.Heartbeat:Connect(function(dt)
	local heldKeys = Movement2D:getHeldMovementKeys()
	curInputDir = Movement2D:inputToVector3(heldKeys)
end)

local function bindCharacter(newCharacter)
	character = newCharacter
	_humanoid = character:WaitForChild("Humanoid")
	slideClient = require(character:WaitForChild("slide"))
	dJumpClient = require(character:WaitForChild("doubleJump"))
	dashClient = require(character:WaitForChild("dash"))
end

if player.Character then
	bindCharacter(player.Character)
else
	bindCharacter(player.CharacterAdded:Wait())
end

player.CharacterAdded:Connect(bindCharacter)

Camera2D:start({
	-- Set this to stage depth so camera tracks along an X/Y plane.
	planeZ = 0,
})

Movement2D:start({
	cameraModule = Camera2D,
	fallbackPlaneZ = 0,
})

ChatListener:start()

local UIS = game:GetService("UserInputService")

local keyDispatch = {
	[Keybinds.SLIDE_KEY] = function()
		-- slideClient.startSlide()
	end,
	[Keybinds.DOUBLE_JUMP_KEY] = function()
		dJumpClient:performDoubleJump()
	end,
	[Keybinds.DASH_KEY] = function()
		dashClient:startDash(curInputDir)
	end,
}

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if not slideClient or not dJumpClient or not dashClient then
		warn("Missing a movement client")
		return
	end

	local handler = keyDispatch[input.KeyCode]
	if handler then
		handler(input)
	end
end)
