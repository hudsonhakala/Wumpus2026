local SharedData = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerData"))
local Keybinds = require(script:WaitForChild("keybinds"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local character = SharedData:getCharacter()
local _humanoid = character:WaitForChild("Humanoid")
    local slideClient = require(character:WaitForChild("slide"))
    local dJumpClient = require(character:WaitForChild("doubleJump"))
    local dashClient = require(character:WaitForChild("dash"))

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
	local sent = false
	local channels = TextChatService:FindFirstChild("TextChannels")
	if channelName and channels then
		local channel = channels:FindFirstChild(channelName)
		if channel then
			local ok = pcall(function()
				channel:SendAsync(reply)
			end)
			sent = ok
		end
	end

	if not sent then
		print("AI reply:", reply)
	end
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Keybinds.SLIDE_KEY then
        
        slideClient.startSlide()
    end
    if input.KeyCode == Keybinds.DOUBLE_JUMP_KEY then
        dJumpClient:performDoubleJump()
    end
    if input.KeyCode == Keybinds.DASH_KEY then
        
        dashClient.startDash()
    end
end)
