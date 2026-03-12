local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local ChatHandle = {
	ChatVersion = TextChatService.ChatVersion,
}

local function getOrCreateRemoteEvent(name)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

promptEvent = getOrCreateRemoteEvent("ChatPromptEvent")
responseEvent = getOrCreateRemoteEvent("ChatResponseEvent")

function ChatHandle:start(relayModule)
    promptEvent.OnServerEvent:Connect(function(player, prompt, channelName)
	    if typeof(prompt) ~= "string" or prompt == "" then
		    return
	    end

	    print("Received message from " .. player.Name .. ": " .. prompt)
	    relayModule:handlePrompt(player, prompt, channelName, responseEvent)
    end)
end

function ChatHandle:stop()
    promptEvent.OnServerEvent:DisconnectAll()
end

return ChatHandle
