
local SharedData = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerData"))

local SlideModule = {}

local sliding = false
local lastSlideTime = -math.huge

SlideModule.canSlide = function(humanoid, root)
	if humanoid.Health <= 0 then return false end
	if humanoid.Sit then return false end
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then return false end
	if tick() - lastSlideTime < SharedData.SLIDE_COOLDOWN then return false end
	if root.AssemblyLinearVelocity.Magnitude < SharedData.MIN_MOVE_SPEED then return false end
	return true
end

SlideModule.startSlide = function ()
	if sliding then return end

	local character = SharedData:getCharacter()
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")

	if not SlideModule.canSlide(humanoid, root) then return end

	sliding = true
	lastSlideTime = tick()

	-- Slightly lower friction feel: temporarily boost WalkSpeed control off
	local oldAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false

	-- Create an attachment + LinearVelocity to push forward
	local att = Instance.new("Attachment")
	att.Name = "SlideAttachment"
	att.Parent = root

	local lv = Instance.new("LinearVelocity")
	lv.Name = "SlideVelocity"
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.RelativeTo = Enum.ActuatorRelativeTo.World

	-- Push in the direction the player is facing
	local dir = root.CFrame.LookVector
	lv.VectorVelocity = Vector3.new(dir.X, 0, dir.Z).Unit * SharedData.SLIDE_SPEED
	lv.Parent = root

	-- Optional: quick “crouch” feel by lowering hip height a bit
	local oldHipHeight = humanoid.HipHeight
	humanoid.HipHeight = math.max(0.5, oldHipHeight - 1)

	-- Maintain push for duration, but allow steering a little
	local t0 = tick()
	local conn
	conn = SharedData.RunService.Heartbeat:Connect(function()
		if not sliding then return end
		if tick() - t0 > SharedData.SLIDE_DURATION then
			conn:Disconnect()
			return
		end

		-- Update direction to current facing each frame (simple steering)
		local d = root.CFrame.LookVector
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude > 0.01 then
			lv.VectorVelocity = flat.Unit * SharedData.SLIDE_SPEED
		end
	end)

	-- End slide after duration
	task.delay(SharedData.SLIDE_DURATION, function()
		if not sliding then return end
		sliding = false

		-- Cleanup
		if conn then conn:Disconnect() end
		if lv then lv:Destroy() end
		if att then att:Destroy() end

		-- Restore
		humanoid.HipHeight = oldHipHeight
		humanoid.AutoRotate = oldAutoRotate
	end)
end


return SlideModule;