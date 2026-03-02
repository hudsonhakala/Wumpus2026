
SharedData = {}

SharedData.Players = game:GetService("Players")
SharedData.UIS = game:GetService("UserInputService")
SharedData.RunService = game:GetService("RunService")

SharedData.player = SharedData.Players.LocalPlayer
SharedData.humanoid = nil

-- GAME SETTINGS _________________________

-- Slide
SharedData.SLIDE_SPEED = 60          -- forward push strength
SharedData.SLIDE_DURATION = 0.6      -- seconds
SharedData.SLIDE_COOLDOWN = 0.8      -- seconds
SharedData.MIN_MOVE_SPEED = 6        -- must be moving at least this fast to slide

-- Dash
SharedData.DASH_SPEED = 100          -- forward dash speed
SharedData.DASH_DURATION = 0.2       -- seconds
SharedData.DASH_COOLDOWN = 1.0       -- seconds

-- Double Jump
SharedData.DOUBLE_JUMP_BOOST = 1   -- speed multiplier when double jumping


-- ___________________________________

function SharedData.getCharacter()
	return SharedData.player.Character or SharedData.player.CharacterAdded:Wait()
end

function SharedData.getHumanoid()
	local character = SharedData.getCharacter()
	return character:WaitForChild("Humanoid")
end

SharedData.loadAnim = function (anim)
	if not anim or not anim:IsA("Animation") then
		warn("Slide animation is missing or not an Animation.")
		return nil
	end

	local humanoid = SharedData.getHumanoid()
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok then
		warn("Slide animation failed to load.")
		return nil
	end

	return track
end

SharedData.playAnim = function (animTrack)
	if not animTrack then
		return false
	end

	local ok = pcall(function()
		animTrack:Play()
	end)
	if ok and animTrack.Animation then
		print(animTrack.Animation.AnimationId .. " played.")
	end
	return ok
end

function SharedData:watchForLanding(humanoid)
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
            return true
        else
            return false
		end
	end)
end

return SharedData
