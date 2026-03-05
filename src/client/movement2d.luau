local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Movement2D = {}
Movement2D.__index = Movement2D

local localPlayer = Players.LocalPlayer

local renderConnection = nil
local characterAddedConnection = nil

local config = {
	planeEpsilon = 0.01,
	smoothClamp = false,
	clampSmoothness = 14,
	facingDeadzone = 0.05,
	facingTurnSpeed = 35,
	fallbackPlaneZ = 0,
	cameraModule = nil,
	autoFace = true,
}

local character = nil
local humanoid = nil
local rootPart = nil
local previousAutoRotate = nil
local warnedMissingCameraPlane = false
local facingDirection = 1

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

		local linearVelocity = rootPart.AssemblyLinearVelocity
		if math.abs(linearVelocity.Z) > config.planeEpsilon then
			rootPart.AssemblyLinearVelocity = Vector3.new(linearVelocity.X, linearVelocity.Y, 0)
		end
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

return Movement2D
