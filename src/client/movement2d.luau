local Players = game:GetService("Players") -- services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local UIS = game:GetService("UserInputService")

local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MovementConfig")) -- settings
local Keybinds = require(script.Parent:WaitForChild("keybinds"))

local Movement2D = {}
Movement2D.__index = Movement2D

local localPlayer = Players.LocalPlayer

local renderConnection = nil
local characterAddedConnection = nil

local character = nil
local humanoid = nil
local rootPart = nil
local previousAutoRotate = nil
local warnedMissingCameraPlane = false
local facingDirection = 1

local inputTable = {
		[Enum.KeyCode.W] = Vector3.new(0, 1, 0),
		[Enum.KeyCode.S] = Vector3.new(0, -1, 0),
		[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
		[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
	}

local function getCurrentPlaneZ()
	local cameraModule = config.cameraModule
	if cameraModule and typeof(cameraModule.getPlaneZ) == "function" then
		local ok, planeZ = pcall(function()
			return cameraModule:getPlaneZ()
		end)
		if ok and typeof(planeZ) == "number" then
			return planeZ
		end
	end

	if not warnedMissingCameraPlane then
		warn("Movement2D: cameraModule.getPlaneZ() missing or invalid; using fallbackPlaneZ.")
		warnedMissingCameraPlane = true
	end

	return config.fallbackPlaneZ
end

local function setAutoRotate(enabled)
	if humanoid then
		humanoid.AutoRotate = enabled
	end
end

local function bindCharacter(newCharacter)
	if humanoid and previousAutoRotate ~= nil then
		humanoid.AutoRotate = previousAutoRotate
	end

	character = newCharacter
	humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")
	rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart")
	previousAutoRotate = humanoid.AutoRotate

	if renderConnection and config.autoFace then
		setAutoRotate(false)
	end
end

local function getFacingDirectionFromMotion()
	if not humanoid or not rootPart then
		return facingDirection
	end

	local deadzone = config.facingDeadzone
	local xMotion = rootPart.AssemblyLinearVelocity.X
	if math.abs(xMotion) <= deadzone then
		xMotion = humanoid.MoveDirection.X
	end

	if xMotion > deadzone then
		facingDirection = 1
	elseif xMotion < -deadzone then
		facingDirection = -1
	end

	return facingDirection
end

local function getRotationOnly(cf)
	return cf - cf.Position
end

local function getMovementInputX()
	if not humanoid then
		return 0
	end

	local inputX = humanoid.MoveDirection.X
	if math.abs(inputX) <= config.inputDeadzone then
		return 0
	end

	return math.sign(inputX)
end

local function isGrounded()
	return humanoid and humanoid.FloorMaterial ~= Enum.Material.Air
end

local function blendRate(currentValue, targetValue, rate, dt)
	-- Convert the tuning rate into a frame-rate independent blend amount.
	local alpha = 1 - math.exp(-rate * dt)
	return currentValue + ((targetValue - currentValue) * alpha)
end

local function updateHorizontalVelocity(dt)
	if not humanoid or not rootPart then
		return
	end

	local inputX = getMovementInputX()
	local currentVelocity = rootPart.AssemblyLinearVelocity
	local currentVelocityX = currentVelocity.X
	local grounded = isGrounded()
	local targetVelocityX = inputX * config.moveSpeed

	local controlRate = grounded and config.groundAcceleration or config.airAcceleration
	local frictionRate = grounded and config.groundFriction or config.airFriction
	local rate = frictionRate

	if inputX ~= 0 then
		-- With input held, accelerate toward the target speed instead of snapping there instantly.
		rate = controlRate
		if currentVelocityX ~= 0 and math.sign(currentVelocityX) ~= inputX then
			-- Changing direction needs extra force so momentum exists without making turns feel sluggish.
			rate = rate * config.reverseAccelerationMultiplier
		end
	end

	-- If there is no input, the target speed is zero, so this same blend behaves like friction.
	local nextVelocityX = blendRate(currentVelocityX, targetVelocityX, rate, dt)
	rootPart.AssemblyLinearVelocity = Vector3.new(nextVelocityX, currentVelocity.Y, 0)
end

function Movement2D:start(overrides)
	if renderConnection then
		return
	end

	if overrides then
		for key, value in pairs(overrides) do
			config[key] = value
		end
	end

	warnedMissingCameraPlane = false

	if localPlayer.Character then
		bindCharacter(localPlayer.Character)
	else
		bindCharacter(localPlayer.CharacterAdded:Wait())
	end

	if characterAddedConnection then
		characterAddedConnection:Disconnect()
		characterAddedConnection = nil
	end
	characterAddedConnection = localPlayer.CharacterAdded:Connect(bindCharacter)

	if config.autoFace then
		setAutoRotate(false)
	end

	renderConnection = RunService.RenderStepped:Connect(function(dt)
		if not character or not humanoid or not rootPart then
			return
		end
		if humanoid.Health <= 0 then
			return
		end
		if not rootPart.Parent then
			return
		end

		local planeZ = getCurrentPlaneZ()
		local currentPos = rootPart.Position
		local zDelta = planeZ - currentPos.Z
		local targetPos = Vector3.new(currentPos.X, currentPos.Y, planeZ)
		local finalPos = targetPos

		if config.smoothClamp and math.abs(zDelta) > config.planeEpsilon then
			local alpha = 1 - math.exp(-config.clampSmoothness * dt)
			finalPos = currentPos:Lerp(targetPos, alpha)
		end

		local finalCFrame
		if config.autoFace then
			local targetDir = getFacingDirectionFromMotion()
			local desiredLook = Vector3.new(targetDir, 0, 0)
			local currentLook = rootPart.CFrame.LookVector
			local flatCurrentLook = Vector3.new(currentLook.X, 0, currentLook.Z)
			if flatCurrentLook.Magnitude < 0.001 then
				flatCurrentLook = desiredLook
			else
				flatCurrentLook = flatCurrentLook.Unit
			end

			local turnAlpha = 1 - math.exp(-config.facingTurnSpeed * dt)
			local blendedLook = flatCurrentLook:Lerp(desiredLook, turnAlpha)
			if blendedLook.Magnitude < 0.001 then
				blendedLook = desiredLook
			else
				blendedLook = blendedLook.Unit
			end

			finalCFrame = CFrame.lookAt(finalPos, finalPos + blendedLook, Vector3.yAxis)
		else
			finalCFrame = CFrame.new(finalPos) * getRotationOnly(rootPart.CFrame)
		end

		rootPart.CFrame = finalCFrame

		updateHorizontalVelocity(dt)
	end)
end

function Movement2D:stop()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if characterAddedConnection then
		characterAddedConnection:Disconnect()
		characterAddedConnection = nil
	end

	if humanoid and previousAutoRotate ~= nil then
		humanoid.AutoRotate = previousAutoRotate
	end
end

function Movement2D:setPlaneZFallback(zValue)
	config.fallbackPlaneZ = zValue
end

local function getHeldMovementKeys()
	local movementKeyMap = {
		UP = Keybinds.UP_KEY,
		LEFT = Keybinds.LEFT_KEY,
		DOWN = Keybinds.DOWN_KEY,
		RIGHT = Keybinds.RIGHT_KEY,
	}

	local heldKeys = {}
	for label, keyCode in pairs(movementKeyMap) do
		if UIS:IsKeyDown(keyCode) then
			table.insert(heldKeys, keyCode)
		end
	end

	--table.sort(heldKeys)
	-- if #heldKeys == 0 then
	-- 	print("Held movement keys: none")
	-- else
	-- 	print("Held movement keys: " .. table.concat(heldKeys, ", "))
	-- end

	return heldKeys
end

function Movement2D:getHeldMovementKeys()
	return getHeldMovementKeys()
end

function Movement2D:inputToVector3(input)
	local inputDirection = Vector3.zero

	local heldKeys = input or self:getHeldMovementKeys()
	for _, key in ipairs(heldKeys) do
		local direction = inputTable[key]
		if direction then
			inputDirection = inputDirection + direction
		end
	end

	if inputDirection.Magnitude > 0 then
		return inputDirection.Unit
	end

	return inputDirection
end

return Movement2D
