
local SharedData = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerData"))
local character = SharedData:getCharacter()
local humanoid = character:WaitForChild("Humanoid")

local CharacterState = {}

function CharacterState:isGrounded()
	return humanoid.FloorMaterial ~= Enum.Material.Air
end

-- Calls `onLanded` when the humanoid returns to ground after a jump/freefall.
function CharacterState:watchForLanding(onLanded, landingConnection)
	if landingConnection then
		landingConnection:Disconnect()
		landingConnection = nil
	end

	local wasAirborne = false

	landingConnection = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping
			or newState == Enum.HumanoidStateType.Freefall
			or newState == Enum.HumanoidStateType.FallingDown then
			wasAirborne = true
			
		end

		local enteredGroundState = (newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running)
		if wasAirborne and enteredGroundState and CharacterState.isGrounded() then
			wasAirborne = false
            
            if onLanded then onLanded() end
			if landingConnection then
				landingConnection:Disconnect()
				landingConnection = nil
			end
		end
	end)

	return landingConnection
end








return CharacterState