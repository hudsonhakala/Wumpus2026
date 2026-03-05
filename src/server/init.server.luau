local deepseek = require(script:WaitForChild("chatbot"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

print("ChatVersion:", TextChatService.ChatVersion)

local promptEvent = ReplicatedStorage:FindFirstChild("ChatPromptEvent")
if not promptEvent then
	promptEvent = Instance.new("RemoteEvent")
	promptEvent.Name = "ChatPromptEvent"
	promptEvent.Parent = ReplicatedStorage
end

local responseEvent = ReplicatedStorage:FindFirstChild("ChatResponseEvent")
if not responseEvent then
	responseEvent = Instance.new("RemoteEvent")
	responseEvent.Name = "ChatResponseEvent"
	responseEvent.Parent = ReplicatedStorage
end

promptEvent.OnServerEvent:Connect(function(player, prompt, channelName)
	if typeof(prompt) ~= "string" or prompt == "" then
		return
	end

	print("Received message from " .. player.Name .. ": " .. prompt)

	task.spawn(function()
		local ok, replyOrErr = pcall(function()
			local modelReply, modelErr = deepseek:askModel(prompt)
			if not modelReply then
				error(modelErr or "unknown model error")
			end
			return modelReply
		end)
		if not ok or not replyOrErr then
			warn("askModel failed:", replyOrErr)
			responseEvent:FireClient(player, "[AI] AI backend error. Try again in a moment.", channelName)
			return
		end

		local posted, postErr = pcall(function()
			local sent, messageOrErr = deepseek:serveResponse(replyOrErr, channelName)
			if not sent then
				error(messageOrErr)
			end
			responseEvent:FireClient(player, messageOrErr, channelName)
		end)
		if not posted then
			warn("serveResponse failed:", postErr)
		end
	end)
end)
