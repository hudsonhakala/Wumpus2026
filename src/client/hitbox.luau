local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Hitbox = {}
Hitbox.__index = Hitbox

local DEFAULT_SIZE = Vector3.new(4, 4, 4)
local DEFAULT_OFFSET = CFrame.new(0, 0, -3)
local DEFAULT_DURATION = 0.12

local function createDebugPart(size)
	local part = Instance.new("Part")
	part.Name = "HitboxDebug"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 0.65
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 80, 80)
	part.Size = size
	part.Parent = Workspace
	return part
end

local function resolveCharacter(part)
	if not part then
		return nil, nil
	end

	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil, nil
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil, nil
	end

	return model, humanoid
end

function Hitbox.new(config)
	local self = setmetatable({}, Hitbox)

	self.size = config and config.size or DEFAULT_SIZE
	self.offset = config and config.offset or DEFAULT_OFFSET
	self.duration = config and config.duration or DEFAULT_DURATION
	self.debug = config and config.debug or false
	self.owner = config and config.owner or nil
	self.onHit = config and config.onHit or nil
	self.maxParts = config and config.maxParts or 32
	self.hitCharacters = {}
	self.connection = nil
	self.debugPart = nil

	self.overlapParams = OverlapParams.new()
	self.overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	self.overlapParams.MaxParts = self.maxParts
	self.overlapParams.FilterDescendantsInstances = {}

	if self.owner then
		table.insert(self.overlapParams.FilterDescendantsInstances, self.owner)
	end

	return self
end

function Hitbox:getCFrame(originCFrame)
	return originCFrame * self.offset
end

function Hitbox:getParts(originCFrame)
	return Workspace:GetPartBoundsInBox(self:getCFrame(originCFrame), self.size, self.overlapParams)
end

function Hitbox:scan(originCFrame)
	local hitResults = {}

	for _, part in ipairs(self:getParts(originCFrame)) do
		local character, humanoid = resolveCharacter(part)
		if character and humanoid and character ~= self.owner and not self.hitCharacters[character] then
			self.hitCharacters[character] = true
			table.insert(hitResults, {
				character = character,
				humanoid = humanoid,
				part = part,
			})

			if self.onHit then
				self.onHit(character, humanoid, part)
			end
		end
	end

	return hitResults
end

function Hitbox:start(rootPart)
	if not rootPart then
		return nil
	end

	self.hitCharacters = {}

	if self.debug and not self.debugPart then
		self.debugPart = createDebugPart(self.size)
	end

	local startedAt = os.clock()
	self.connection = RunService.Heartbeat:Connect(function()
		if not rootPart.Parent then
			self:destroy()
			return
		end

		local hitboxCFrame = self:getCFrame(rootPart.CFrame)
		if self.debugPart then
			self.debugPart.CFrame = hitboxCFrame
		end

		self:scan(rootPart.CFrame)

		if os.clock() - startedAt >= self.duration then
			self:destroy()
		end
	end)

	return self
end

function Hitbox:destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	if self.debugPart then
		self.debugPart:Destroy()
		self.debugPart = nil
	end
end

return Hitbox
