local deepseek = require(script:WaitForChild("deepseek"))
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
		local ok, reply = pcall(function()
			return deepseek:askModel(prompt)
		end)
		if ok and reply then
			responseEvent:FireClient(player, reply, channelName)
		else
			warn("askModel failed:", reply)
		end
	end)
end)



-- task.spawn(function()
-- 	local ok, err = pcall(function()
-- 		deepseek:serveResponse()
-- 	end)
-- 	if not ok then
-- 		warn("serveResponse failed:", err)
-- 	end
-- end)
