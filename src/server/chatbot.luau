local HttpService = game:GetService("HttpService")
local RELAY_URL = "https://nonsensible-thalia-incipient.ngrok-free.dev/prompt"

local ChatbotModule = {}

function ChatbotModule:askModel(message, duration)
	print("Asking model: " .. message)
	local body = HttpService:JSONEncode({
		prompt = message
	})

	local response = HttpService:RequestAsync({
		Url = RELAY_URL,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = body,
	})

	if not response.Success then
		return nil, string.format("relay returned HTTP %d", response.StatusCode)
	end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not ok then
		return nil, "relay returned invalid JSON"
	end

	if typeof(decoded) ~= "table" or typeof(decoded.answer) ~= "string" then
		return nil, "relay response missing 'answer'"
	end

	local answer = decoded.answer

	-- Some relays return answer as a JSON string like: { "answer": "..." }.
	-- If that happens, unwrap it so callers always get plain text.
	if string.sub(answer, 1, 1) == "{" then
		local innerOk, innerDecoded = pcall(function()
			return HttpService:JSONDecode(answer)
		end)
		if innerOk and typeof(innerDecoded) == "table" and typeof(innerDecoded.answer) == "string" then
			answer = innerDecoded.answer
		end
	end

	return answer, nil
end

function ChatbotModule:serveResponse(answer, channelName)
	if typeof(answer) ~= "string" or answer == "" then
		return false, "empty answer"
	end

	print(answer)

	return true, "[AI] " .. answer
end

return ChatbotModule
