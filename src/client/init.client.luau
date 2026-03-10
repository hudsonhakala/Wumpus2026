local Keybinds = require(script:WaitForChild("keybinds"))
local Camera2D = require(script:WaitForChild("camera2d"))
local Movement2D = require(script:WaitForChild("movement2d"))

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local character = nil
local _humanoid = nil
local slideClient = nil
local dJumpClient = nil
local dashClient = nil

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
	-- Set this to your stage depth so camera tracks along an X/Y plane.
	planeZ = 0,
})

Movement2D:start({
	cameraModule = Camera2D,
	fallbackPlaneZ = 0,
})

local UIS = game:GetService("UserInputService")
local promptEvent = ReplicatedStorage:WaitForChild("ChatPromptEvent")
local responseEvent = ReplicatedStorage:WaitForChild("ChatResponseEvent")

TextChatService.MessageReceived:Connect(function(msg)
	if not msg.TextSource then
		return
	end
	if msg.TextSource.UserId ~= game.Players.LocalPlayer.UserId then
		return
	end

	local text = msg.Text
	if not text:match("^/ai%s+") then
		return
	end

	local prompt = text:gsub("^/ai%s+", "")
	promptEvent:FireServer(prompt, msg.TextChannel and msg.TextChannel.Name or nil)
end)

responseEvent.OnClientEvent:Connect(function(reply, channelName)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local channel = nil
	if channels then
		if channelName and channelName ~= "" then
			channel = channels:FindFirstChild(channelName)
		end
		if not channel then
			channel = channels:FindFirstChild("RBXGeneral")
		end
	end

	if channel then
		channel:DisplaySystemMessage(reply)
	else
		print(reply)
	end
end)

local keyDispatch = {
	[Keybinds.SLIDE_KEY] = function()
		-- slideClient.startSlide()
	end,
	[Keybinds.DOUBLE_JUMP_KEY] = function()
		dJumpClient:performDoubleJump()
	end,
	[Keybinds.DASH_KEY] = function(input)
		dashClient.startDash(input)
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
