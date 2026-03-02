local SharedData = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerData"))

local JumpModule = {}

local hasDoubleJump = true
local character = SharedData:getCharacter()
local humanoid = character:WaitForChild("Humanoid")

function JumpModule:canDoubleJump()
    if not hasDoubleJump then
        return false
    end

    local root = humanoid.RootPart
    if not root then
        return false
    end

    local state = humanoid:GetState()

    if state ~= Enum.HumanoidStateType.Jumping
        and state ~= Enum.HumanoidStateType.Freefall
        and state ~= Enum.HumanoidStateType.FallingDown then
        return false
    end

    return true
end

function JumpModule:performDoubleJump()

    if not JumpModule.canDoubleJump() then return end

    local root = humanoid.RootPart
    if not root then
        return
    end

    -- Apply an upward boost
    local _lookVector = root.CFrame.LookVector
    local jumpBoost = Vector3.new(0, 1, 0).Unit * humanoid.JumpPower * SharedData.DOUBLE_JUMP_BOOST
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z) + jumpBoost

    hasDoubleJump = false

    JumpModule:watchForLanding(function()print("Landed, double jump reset.") end)
end

-- Calls `onLanded` when the humanoid returns to ground after a jump/freefall.
function JumpModule:watchForLanding(onLanded)
	local wasAirborne = false

	return humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping
			or newState == Enum.HumanoidStateType.Freefall
			or newState == Enum.HumanoidStateType.FallingDown then
			wasAirborne = true
			
		end

		if wasAirborne and (newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running) then
			wasAirborne = false
            hasDoubleJump = true
            if onLanded then onLanded() end
		end
	end)
end

return JumpModule
