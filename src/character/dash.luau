local characterState = require(script.Parent.characterState)
local SharedData = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerData"))
local character = SharedData:getCharacter()
local humanoid = character:WaitForChild("Humanoid")

local DashModule = {}

local DEFAULT_DASH_SPEED = SharedData.DASH_SPEED
local DEFAULT_DASH_DURATION = SharedData.DASH_DURATION
local dashCount = 2
local dashing = false
local landingConnection = nil

local function flattenVector(vector)
	return Vector3.new(vector.X, vector.Y, 0)
end

local function normalizeOrNil(vector)
	if vector.Magnitude <= 0.05 then
		return nil
	end

	return vector.Unit
end

local function getDashDirection(root, intendedDirection)
	local explicitDirection = intendedDirection and normalizeOrNil(flattenVector(intendedDirection))
	if explicitDirection then
		return explicitDirection
	end

	local moveDirection = normalizeOrNil(flattenVector(humanoid.MoveDirection))
	if moveDirection then
		return moveDirection
	end

	local velocityDirection = normalizeOrNil(flattenVector(root.AssemblyLinearVelocity))
	if velocityDirection then
		return velocityDirection
	end

	return flattenVector(root.CFrame.LookVector).Unit
end

function DashModule:startDash(intendedDirection)
    if dashing then
        return
    end

    if not DashModule:checkCanDash(intendedDirection) then
        return
    end

    local root = humanoid.RootPart
    if not root then
        return
    end

    dashCount = dashCount - 1
    dashing = true

	-- Full x/y input is normalized, so diagonal dashes keep the same total speed.
    local dashDirection = getDashDirection(root, intendedDirection)
    local boost = dashDirection * DEFAULT_DASH_SPEED
    humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)

    local att = Instance.new("Attachment")
    att.Name = "DashAttachment"
    att.Parent = root

    local lv = Instance.new("LinearVelocity")
    lv.Name = "DashVelocity"
    lv.Attachment0 = att
    lv.MaxForce = math.huge
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.VectorVelocity = boost
    lv.Parent = root

    task.delay(DEFAULT_DASH_DURATION, function()
        if lv then lv:Destroy() end
        if att then att:Destroy() end

        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        dashing = false
    end)

    characterState:watchForLanding(function()print("Landed, dashes reset."); dashCount = 2 end, landingConnection)
end

function DashModule:checkCanDash(direction)
    if dashCount <= 0 then
        return false
    end

    local root = humanoid.RootPart
    if not root then
        return false
    end

    if direction then
        if direction == Vector3.zero then
            return false
        elseif direction == Vector3.new(0, 1, 0) or direction == Vector3.new(0, -1, 0) then
            return false
        end
    end

    local state = humanoid:GetState()

    if state ~= Enum.HumanoidStateType.Jumping
        and state ~= Enum.HumanoidStateType.Freefall
        and state ~= Enum.HumanoidStateType.FallingDown then
        return false
    end

    return true
end

function DashModule:watchForLanding()
	local wasAirborne = false

	return humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping
			or newState == Enum.HumanoidStateType.Freefall
			or newState == Enum.HumanoidStateType.FallingDown then
			wasAirborne = true
			return
		end

		if wasAirborne and (newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running) then
			wasAirborne = false
            dashCount = 2
		end
	end)
end






return DashModule
