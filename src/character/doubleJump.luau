local SharedData = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerData"))

local character = SharedData:getCharacter()
local humanoid = character:WaitForChild("Humanoid")

local characterState = require(character:WaitForChild("characterState"))

local JumpModule = {}

local hasDoubleJump = true
local landingConnection = nil

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
	local jumpBoost = Vector3.new(0, 1, 0).Unit * humanoid.JumpPower * SharedData.DOUBLE_JUMP_BOOST
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z) + jumpBoost

    hasDoubleJump = false

    characterState:watchForLanding(function()print("Landed, double jump reset."); hasDoubleJump = true end, landingConnection)
end



return JumpModule
