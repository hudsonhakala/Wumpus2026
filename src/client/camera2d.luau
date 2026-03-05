local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Camera2D = {}

local renderConnection = nil
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local CAMERA_LOCK_ACTION = "Camera2D_LockCameraInput"

local config = {
	planeZ = 0,
	baseDistance = 24,
	minDistance = 18,
	maxDistance = 80,
	minSpanX = 28,
	minSpanY = 16,
	xDistanceFactor = 0.95,
	yDistanceFactor = 1.5,
	heightOffset = 4,
	smoothness = 8,
}

local currentCamPos = nil
local currentLookAt = nil

local function lockCameraInput()
	ContextActionService:BindActionAtPriority(
		CAMERA_LOCK_ACTION,
		function()
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value + 1000,
		Enum.UserInputType.MouseMovement,
		Enum.UserInputType.MouseWheel,
		Enum.UserInputType.Touch,
		Enum.KeyCode.Thumbstick2
	)
end

local function unlockCameraInput()
	ContextActionService:UnbindAction(CAMERA_LOCK_ACTION)
end

local function getTrackedRoots()
	local roots = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and root then
				table.insert(roots, root)
			end
		end
	end

	return roots
end

local function getBounds(roots)
	local minX = math.huge
	local maxX = -math.huge
	local minY = math.huge
	local maxY = -math.huge

	for _, root in ipairs(roots) do
		local p = root.Position
		minX = math.min(minX, p.X)
		maxX = math.max(maxX, p.X)
		minY = math.min(minY, p.Y)
		maxY = math.max(maxY, p.Y)
	end

	return minX, maxX, minY, maxY
end

local function blend(currentValue, targetValue, alpha)
	if not currentValue then
		return targetValue
	end
	return currentValue:Lerp(targetValue, alpha)
end

function Camera2D:start(overrides)
	if renderConnection then
		return
	end

	if overrides then
		for key, value in pairs(overrides) do
			config[key] = value
		end
	end

	camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	lockCameraInput()

	renderConnection = RunService.RenderStepped:Connect(function(dt)
		local activeCamera = Workspace.CurrentCamera
		if not activeCamera then
			return
		end
		if activeCamera ~= camera then
			camera = activeCamera
			camera.CameraType = Enum.CameraType.Scriptable
		end

		local roots = getTrackedRoots()
		if #roots == 0 then
			return
		end

		local minX, maxX, minY, maxY = getBounds(roots)
		local centerX = (minX + maxX) * 0.5
		local centerY = (minY + maxY) * 0.5

		local spanX = math.max(config.minSpanX, maxX - minX)
		local spanY = math.max(config.minSpanY, maxY - minY)
		local targetDistance = math.max(
			config.baseDistance + (spanX * config.xDistanceFactor),
			config.baseDistance + (spanY * config.yDistanceFactor)
		)
		targetDistance = math.clamp(targetDistance, config.minDistance, config.maxDistance)

		local targetLookAt = Vector3.new(centerX, centerY, config.planeZ)
		local targetCamPos = Vector3.new(centerX, centerY + config.heightOffset, config.planeZ + targetDistance)

		local alpha = 1 - math.exp(-config.smoothness * dt)
		currentLookAt = blend(currentLookAt, targetLookAt, alpha)
		currentCamPos = blend(currentCamPos, targetCamPos, alpha)

		camera.CFrame = CFrame.lookAt(currentCamPos, currentLookAt, Vector3.yAxis)
	end)
end

function Camera2D:stop()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	unlockCameraInput()

	currentCamPos = nil
	currentLookAt = nil

	camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = Enum.CameraType.Custom
	local character = localPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

function Camera2D:setPlaneZ(zValue)
	config.planeZ = zValue
end

function Camera2D:getPlaneZ()
	return config.planeZ
end

return Camera2D
