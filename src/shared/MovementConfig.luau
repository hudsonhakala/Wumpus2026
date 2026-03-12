

local DEFAULT_MOVE_SPEED = 30
local DEFAULT_GROUND_ACCELERATION = 22
local DEFAULT_AIR_ACCELERATION = 10
local DEFAULT_GROUND_FRICTION = 7
local DEFAULT_AIR_FRICTION = 1.5
local DEFAULT_REVERSE_ACCELERATION_MULTIPLIER = 1.2
local DEFAULT_INPUT_DEADZONE = 0.05

local config = {
	planeEpsilon = 0.01,
	smoothClamp = false,
	clampSmoothness = 14,
	facingDeadzone = 0.05,
	facingTurnSpeed = 35,
	fallbackPlaneZ = 0,
	cameraModule = nil,
	autoFace = true,
	moveSpeed = DEFAULT_MOVE_SPEED,
	groundAcceleration = DEFAULT_GROUND_ACCELERATION,
	airAcceleration = DEFAULT_AIR_ACCELERATION,
	groundFriction = DEFAULT_GROUND_FRICTION,
	airFriction = DEFAULT_AIR_FRICTION,
	reverseAccelerationMultiplier = DEFAULT_REVERSE_ACCELERATION_MULTIPLIER,
	inputDeadzone = DEFAULT_INPUT_DEADZONE,
}

return config