local HttpService = game:GetService("HttpService")
local RELAY_URL = "https://nonsensible-thalia-incipient.ngrok-free.dev/prompt"

local DeepseekModule = {}

local function stripThinking(text)
	if not text then return text end
	-- Remove <think>...</think> across multiple lines
	text = text:gsub("<think>[%s%S]-</think>", "")
	return text:gsub("^%s+", ""):gsub("%s+$", "")
end

function DeepseekModule:loadModel(modelName)

end

function DeepseekModule:askModel(message, duration)
    print("Asking model: "..message)
    local body = HttpService:JSONEncode({
        prompt = message
    })

    local response = HttpService:PostAsync(
        RELAY_URL,
        body,
        Enum.HttpContentType.ApplicationJson,
        false
    )

    local decoded = HttpService:JSONDecode(response)
    return stripThinking(decoded.answer)
end


function DeepseekModule:serveResponse(answer)
    
    print(answer)
end


return DeepseekModule
