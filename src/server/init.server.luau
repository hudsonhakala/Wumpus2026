print("Initializing server scripts...")

chatHandle = require(script:WaitForChild("ChatHandle"))
relay = require(script:WaitForChild("PromptRelayGate"))

chatHandle:start(relay)


