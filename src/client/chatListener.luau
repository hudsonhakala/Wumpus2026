local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local promptEvent = ReplicatedStorage:WaitForChild("ChatPromptEvent")
local responseEvent = ReplicatedStorage:WaitForChild("ChatResponseEvent")

listener = {}

function listener:start()
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
end

function listener:stop()
    TextChatService.MessageReceived:DisconnectAll()
    responseEvent.OnClientEvent:DisconnectAll()
end

return listener