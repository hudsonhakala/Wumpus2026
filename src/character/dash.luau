local characterState = require(script.Parent.characterState)
local SharedData = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerData"))
local character = SharedData:getCharacter()
local humanoid = character:WaitForChild("Humanoid")

local DashModule = {}

local dashCount = 2
local dashing = false
local landingConnection = nil

function DashModule:startDash(input)
    if dashing then
        return
    end

    if not DashModule:checkCanDash() then
        return
    end

    local root = humanoid.RootPart
    if not root then
        return
    end

    dashCount = dashCount - 1
    dashing = true

    -- Apply a forward boost and keep vertical velocity at 0 to counter gravity.
    local lookVector = root.CFrame.LookVector
    local inputVector = Vector3.new(lookVector.X, 0, lookVector.Z)
    
    local jumpBoost = Vector3.new(lookVector.X, 0, lookVector.Z).Unit * SharedData.DASH_SPEED
    humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)

    local att = Instance.new("Attachment")
    att.Name = "DashAttachment"
    att.Parent = root

    local lv = Instance.new("LinearVelocity")
    lv.Name = "DashVelocity"
    lv.Attachment0 = att
    lv.MaxForce = math.huge
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.VectorVelocity = jumpBoost
    lv.Parent = root

    task.delay(SharedData.DASH_DURATION, function()
        if lv then lv:Destroy() end
        if att then att:Destroy() end

        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        dashing = false
    end)

    characterState:watchForLanding(function()print("Landed, dashes reset."); dashCount = 2 end, landingConnection)
end

function DashModule:checkCanDash()
    if dashCount <= 0 then
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
